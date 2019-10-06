extends KinematicBody2D

const STATE_SITTING = 0
const STATE_FLYING = 1
const STATE_ATTACKING = 2

const GRAVITY = 2000
const FLAP_FORCE = -1000
const FLY_SPEED = 40000
const WALK_SPEED = 10000

var state = STATE_SITTING
var food_amount = 0
var energy = 100
var nests_owned = 0
var nested = false
var current_nest = null

var motion = Vector2(0,0)
var grounded = true
var speed = WALK_SPEED
var claw_payload = null
var parent

var routes = []
var current_route = null
var current_route_idx = 0
var route_target = Vector2(0,0)
var idle_time = 0

var current_path = null

export var controlled = false 
export var route_code = ""
export var energy_duration = 60

onready var claw_ray = $Visuals/Claw/ClawRay
onready var visual   = $Visuals
onready var anim     = $AnimationPlayer
onready var beak_ray = $Visuals/BodyFlying/BeakRay
onready var energy_bar = get_node("/root/Game/UI/Control/EnergyProgress")

var Egg = preload("res://Components/Egg/Egg.tscn")

func _ready():
	if !controlled:
		load_routes()		
	set_physics_process(true)
	
func restart():
	energy = 100
	

func _physics_process(delta):
	grounded = claw_ray.is_colliding()
	if grounded:
		if state != STATE_SITTING:
			change_state(STATE_SITTING)
	else:
		if state != STATE_ATTACKING and state != STATE_FLYING:
			change_state(STATE_FLYING)
	
	motion.y += GRAVITY * delta
	
	if controlled:
		controlled_process(delta)	
		
		if state != STATE_SITTING:
			energy -= delta
			energy_bar.value = round(energy)
				
	else:
		ai_process(delta)

	motion = move_and_slide(motion, Vector2(0,0), true)
		
func ai_process(delta):
		patrol(delta)
		
func controlled_process(delta):
	if Input.is_action_just_pressed("ui_action1"):
		if state == STATE_FLYING:
			change_state(STATE_ATTACKING)
			
		if state == STATE_SITTING and nested and current_nest.my_nest:
			lay_egg()
			
	if Input.is_action_just_pressed("ui_action2"):
		if nested and current_nest.my_nest:
			eat()
		
	if Input.is_action_just_pressed("ui_select"):
		motion.y = FLAP_FORCE
		anim.stop(true)
		anim.play("Flap")
		if state != STATE_FLYING:
			change_state(STATE_FLYING)
			
	if Input.is_action_pressed("ui_left") and state != STATE_ATTACKING:
		if visual.scale.x > 0:
			visual.scale.x = -1
		if grounded:
			motion.x = max(motion.x - speed * delta, -speed * delta)
		else:
			motion.x = lerp(motion.x, max(motion.x - speed * delta, -speed * delta), 10 * delta)
			
	if Input.is_action_pressed("ui_right") and state != STATE_ATTACKING:
		if visual.scale.x < 0:
			visual.scale.x = 1
		if grounded:
			motion.x = min(motion.x + speed * delta, speed * delta)
		else:
			motion.x = lerp(motion.x, min(motion.x + speed * delta, speed * delta), 10 * delta)
		
	elif !Input.is_action_pressed("ui_left") and grounded:
		motion.x = 0
		
	if state == STATE_ATTACKING and beak_ray.is_colliding():
		var hit = beak_ray.get_collider()
		if hit.is_in_group("Prey"):
			hit.die()
		
	
func patrol(delta):
	if current_path and current_path.unit_offset < 1:
		current_path.unit_offset += delta
	else:
		current_path = null
		$PathPickTimer.stop()
		$PathPickTimer.wait_time = randi() % 10 + 3
		$PathPickTimer.start()
		
func pick_path():
	if routes.size() > 0:
		current_path = routes[randi() % routes.size]
		var follow = current_path.get_node("PathFollow")
		get_parent().remove_child(self)
		follow.add_child(self)
		
	
func xpatrol(delta):
	if !current_route:
		current_route = routes[randi() % routes.size()]  # pick random route
		current_route_idx = 0
	
	if abs(route_target.x - global_position.x) < 10 and abs(route_target.y - global_position.y) < 10:
		
		current_route_idx += 1
	
		if current_route_idx < current_route.size():
			route_target = current_route[current_route_idx]
		else:
			current_route = null
			idle_time = randi() % 20 + 3
			change_state(STATE_SITTING)
	else:
		if idle_time <= 0:
			change_state(STATE_FLYING)
		else:
			idle_time -= delta
		
	
func load_routes():
	routes = []
	if has_node("Routes") and route_code != "" and get_tree().get_root().has_node("Game/Routes/" + route_code):
		print("Got routes...");
		for path in get_node("/root/Game/Routes/" + route_code).get_children():
			routes.append(path)
	else:
		print("NO ROUTES")
	#for route in $Routes.get_children():
	#	var new_route = []
	#	for point in route.get_children():
	#		new_route.append(point.global_position)
	#	routes.append(new_route)
			
func change_state(target):
	if target == state:
		return
		
	beak_ray.enabled = false
		
	if target == STATE_SITTING:
		state = STATE_SITTING
		speed = WALK_SPEED
		anim.play("Idle")
		
	if target == STATE_FLYING:
		state = STATE_FLYING
		speed = FLY_SPEED
		anim.play("Flap")
		
	if state == STATE_FLYING and target == STATE_ATTACKING:
		beak_ray.enabled = true
		print("ATTACKING")
		
		state = STATE_ATTACKING
		anim.stop(true)
		if visual.scale.x > 0:
			anim.play("AttackRight")
		else:
			anim.play("AttackLeft")
	
func on_nest_landed(nest):
	nested = true
	current_nest = nest
	if nest.my_nest and claw_payload:
		store_food()
		
func on_nest_leaved():
	nested = false
	current_nest = null

func on_nest_owned():
	nests_owned = 0
	var total_nests   = 0
	
	for nest in get_node("/root/Game/Environment/Nests").get_children():
		total_nests += 1
		if nest.my_nest:
			nests_owned += 1
			
	get_node("/root/Game/UI/Control/Nests").text = "CONTROLLED NESTS: " + str(nests_owned) + "/" + str(total_nests)
	
func initiate_as_offspring():
	scale = Vector2(0.3, 0.3)
		
func store_food():
	food_amount += claw_payload.food_value;
	claw_payload.queue_free()
	claw_payload = null
	get_node("/root/Game/UI/Control/Food").text = "FOOD: " + str(food_amount)
	
func eat():
	if food_amount > 0:
		food_amount -= 1
		energy += 5
		if energy > 100:
			energy = 100
		energy_bar.value = round(energy)
		get_node("/root/Game/UI/Control/Food").text = "FOOD: " + str(food_amount)
	else:
		print("NOT ENOUGH FOOD!")
	
func lay_egg():
	if nested and current_nest.my_nest:
		var egg = Egg.instance()
		egg.my_egg = true
		egg.parent = self
		egg.home_nest = current_nest
		egg.position = Vector2(randi() % 50 - 25, 0)
		egg.rotation_degrees = randi() % 20 - 10
		current_nest.add_egg(egg)
	
func grab(body):
	if nests_owned == 0:
		food_amount += body.food_value
		body.queue_free()
		for i in range(body.food_value):
			eat()
	else:
		claw_payload = body
		get_node("/root/Game/Prey").remove_child(body)
		$Visuals/Claw.add_child(body)
		body.die()
		body.position = Vector2(0,0)


func _on_ClawArea_area_entered(area):
	if !claw_payload and area.is_in_group("Prey"):
		grab(area)

