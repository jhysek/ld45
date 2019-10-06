# Player's controller
# Controls also behaviour of other birds which is something I really regret in the hindsight.. should be in
# different script but now is not a time for this

extends KinematicBody2D

const STATE_SITTING = 0
const STATE_FLYING = 1
const STATE_ATTACKING = 2
const STATE_PATROLLING = 3
const STATE_DEAD = 4
const STATE_RETURNING = 5

const EGG_PRICE = 10

const GRAVITY = 2000
const FLAP_FORCE = -1000
const FLY_SPEED = 40000
const WALK_SPEED = 10000

var hit_force = 50

var state = STATE_SITTING
var food_amount = 0
var energy = 100
var nests_owned = 0
var nested = false
var current_nest = null
var home_nest
var warn_cooldown = 0

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
var waiting_for_new_path = false
var previous_position
var start_position

var current_path = null

export var controlled = false 
export var route_code = ""
export var energy_duration = 60

onready var claw_ray = $Visuals/Claw/ClawRay
onready var visual   = $Visuals
onready var anim     = $AnimationPlayer
onready var energy_bar = get_node("/root/Game/UI/Control/EnergyProgress")
onready var game = get_node("/root/Game")

var Egg = preload("res://Components/Egg/Egg.tscn")
var Info = preload("res://Components/InfoText/Info.tscn")

func _ready():
	start_position = position
	if !controlled:
		load_routes()		
		patrol(0)
	else:
		$Visuals/FieldOfView.monitorable = false
		$Visuals/FieldOfView.monitoring = false
		$Visuals/FieldOfView.hide()
	set_physics_process(true)
	
func restart():
	energy = 100
	
func info(text, color = null, forcepos = null, time = 1):
	var msg = Info.instance()
	game.add_child(msg)
	if forcepos:
		msg.position = forcepos  
	else:
		msg.position = global_position
	msg.position.y - 50
	if color:
		msg.set_color(color)
	msg.fire(text, time)
	
func _physics_process(delta):
	if state != STATE_PATROLLING and state != STATE_RETURNING:
		if state != STATE_DEAD:
			grounded = claw_ray.is_colliding()
			if grounded:
				if state != STATE_SITTING:
					print("GROUNDED, sitting...") 
					change_state(STATE_SITTING)
			else:
				if state != STATE_ATTACKING and state != STATE_FLYING:
					if controlled:
						print("IN AIR, flying...")
						change_state(STATE_FLYING)
					else:
						change_state(STATE_PATROLLING)
	
		motion.y += GRAVITY * delta
	
	if state != STATE_DEAD:
		if controlled:
			controlled_process(delta)	
		
			if state != STATE_SITTING:
				energy -= delta
				energy_bar.value = round(energy)
				if energy <= 10:
					if warn_cooldown <= 0:
						info("critical energy level, eat!", "#aa0000", null, 3)
						warn_cooldown = 5
					else:
						warn_cooldown -= delta
					
				if energy <= 0:
					change_state(STATE_DEAD)
		else:
			ai_process(delta)
	else:
		motion.x = lerp(motion.x, 0, 0.2)

	if state != STATE_PATROLLING and state != STATE_RETURNING:
		motion = move_and_slide(motion, Vector2(0,0), true)
		
func ai_process(delta):
	if state == STATE_PATROLLING:
		if !waiting_for_new_path:
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
	
func patrol(delta):
	if current_path and current_path.unit_offset < 1:
		current_path.offset += delta * 300
		
		if global_position.x > previous_position.x and $Visuals.scale.x < 0:
			$Visuals.scale.x = 1
			
		if global_position.x < previous_position.x and $Visuals.scale.x > 0:
			$Visuals.scale.x = -1
		
		previous_position = global_position
		
		if current_path.unit_offset >= 1:
			current_path.remove_child(self)
			game.add_child(self)
			global_position = start_position
	else:
		change_state(STATE_SITTING)
		current_path = null
		waiting_for_new_path = true
		$PathPickTimer.stop()
		$PathPickTimer.wait_time = randi() % 10 + 3
		print("Waiting " + str($PathPickTimer.wait_time) + " seconds..")
		$PathPickTimer.start()
		
func pick_path():
	if state == STATE_DEAD:
		return
	
	if current_nest:
		print("IN NEST")
		if randi() % 3 == 0:
			lay_egg()
			$PathPickTimer.wait_time = randi() % 10 + 3
			print("Waiting " + str($PathPickTimer.wait_time) + " seconds..")
			$PathPickTimer.start()
			return
		
	print("Picking path...")
	if routes.size() > 0:
		current_path = routes[randi() % routes.size()].get_node("PathFollow")
		get_parent().remove_child(self)
		current_path.add_child(self)
		current_path.offset = 0
		position = Vector2(0,0)
		waiting_for_new_path = false
		previous_position = global_position
		start_position = global_position
		change_state(STATE_PATROLLING)
		
		
func load_routes():
	var routes_node = get_node("/root/Game/Routes")
	routes = []
	if route_code != "" and routes_node.has_node(route_code):
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
	if target == state or state == STATE_DEAD:
		return
		
	print("Changing state " + str(state) + " => " + str(target))
		
	if target == STATE_SITTING:
		state = STATE_SITTING
		speed = WALK_SPEED
		anim.play("Idle")
		
	if target == STATE_FLYING:
		state = STATE_FLYING
		speed = FLY_SPEED
		anim.play("Flap")
		
	if target == STATE_PATROLLING:
		state = STATE_PATROLLING
		speed = FLY_SPEED
		anim.play("Patrol")
		
	if target == STATE_RETURNING:
		print("Returning...");
		state = STATE_RETURNING
		anim.play("Patrol")
		
	if target == STATE_ATTACKING:
		print("ATTACKING")
		
		state = STATE_ATTACKING
		anim.stop(true)
		if visual.scale.x > 0:
			anim.play("AttackRight")
		else:
			anim.play("AttackLeft")
	
	if target == STATE_DEAD:
		state = STATE_DEAD
		$PathPickTimer.stop()
		anim.play("Die")
		if !controlled:
			var Spawner = load("res://Components/PreySpawner/PreySpawner.tscn")
			var spawner = Spawner.instance()
			spawner.source = self
			spawner.local = true
			spawner.worms_only = true
			game.add_child(spawner)
	
func is_alive():
	return state != STATE_DEAD
	
func on_nest_landed(nest):
	nested = true
	current_nest = nest
	if nest.my_nest and claw_payload:
		store_food()
		
func on_nest_leaved():
	nested = false
	current_nest = null
	
func on_nest_losed():
	#info("Nest losed...")
	on_nest_owned()

func on_nest_owned():
	nests_owned = 0
	var total_nests = 0
	
	for nest in get_node("/root/Game/Environment/Nests").get_children():
		total_nests += 1
		if nest.my_nest:
			nests_owned += 1
			
	get_node("/root/Game/UI/Control/Nests").text = "CONTROLLED NESTS: " + str(nests_owned) + "/" + str(total_nests)
	
func initiate_as_offspring():
	scale = Vector2(0.5, 0.5)
	energy = 50
	hit_force = 25
		
func hit(hp):
	if state != STATE_DEAD:
		energy -= hp
		energy_bar.value = round(energy)
		
		if controlled:
			info("- " + str(hp) + " energy", "#aa0000")
		else:
			info("- " + str(hp) + " energy")
							
		
		print("HIT: .. hp remaining: " + str(energy))
		if energy <= 0:
			print("DEAD....")
			if controlled:
				info("You are dead..", "#aa0000", position + Vector2(0, 30))
			else:
				info("Enemy defeated", "#00aa00", position + Vector2(0, 30))
			change_state(STATE_DEAD)
	
func store_food():
	if state != STATE_DEAD:
		food_amount += claw_payload.food_value
		info("+ " + str(claw_payload.food_value) + " food")
		claw_payload.queue_free()
		claw_payload = null
		get_node("/root/Game/UI/Control/Food").text = "FOOD: " + str(food_amount)
	
func eat():
	if food_amount > 0:
		food_amount -= 1
		energy += 5
		
		info("-1 food,  +5 energy")
		
		if energy > 100:
			energy = 100
		energy_bar.value = round(energy)
		get_node("/root/Game/UI/Control/Food").text = "FOOD: " + str(food_amount)
	else:
		info("Not enough food")
			
func lay_egg():
	if !controlled and nested:
		var egg = Egg.instance()
		egg.my_egg = false
		egg.parent = self
		egg.home_nest = current_nest
		egg.hostile = true
		egg.position = Vector2(randi() % 50 - 25, 0)
		egg.rotation_degrees = randi() % 20 - 10
		current_nest.add_egg(egg)
		
	if controlled and nested and current_nest.my_nest:
		if food_amount >= EGG_PRICE:
			food_amount -= EGG_PRICE
			get_node("/root/Game/UI/Control/Food").text = "FOOD: " + str(food_amount)
			var egg = Egg.instance()
			egg.my_egg = true
			egg.parent = self
			egg.home_nest = current_nest
			egg.hostile = !controlled
			egg.position = Vector2(randi() % 50 - 25, 0)
			egg.rotation_degrees = randi() % 20 - 10
			current_nest.add_egg(egg)
		else:
			info("Not enough food")
			
func grab(body):
	if state != STATE_DEAD:
		claw_payload = body
		get_node("/root/Game/Prey").remove_child(body)
		$Visuals/Claw.add_child(body)
		body.die()
		body.position = Vector2(0,0)


func _on_ClawArea_area_entered(area):
	if !claw_payload and area.is_in_group("Prey"):
		grab(area)


func _on_Beak_area_entered(area):
	if state != STATE_SITTING and state != STATE_DEAD and state != STATE_PATROLLING:
		if area.is_in_group("HitArea"):
			var bird = area.get_parent()
			if bird != self:
				area.get_parent().hit(hit_force)
			
		if area.is_in_group("Prey"):
			area.die()

func _on_Field_of_vision_body_entered(body):
	if state != STATE_DEAD and !controlled and parent != self and body.is_in_group("Player"):
		attack(body)
		
	if state != STATE_DEAD and !controlled and parent == self and body.is_in_group("Enemy"):
		attack(body)

func tween_to(object, time):
	print("=> Tweening to...")
	var tween = $Tween
	tween.stop_all()
	var target
	if typeof(object) == TYPE_VECTOR2:
		target = object
	else:
		target = object.global_position
		
	if target.x > global_position.x:
		$Visuals.scale.x = 1
	else:
		$Visuals.scale.x = -1
	tween.interpolate_property(self, "global_position", global_position, target, time, Tween.TRANS_LINEAR, Tween.EASE_IN, 0)
	tween.start()
			
func return_to_nest():
	if home_nest:
		anim.play("Patrol")
		print("tweening to start position")
		tween_to(start_position, 2)
	else:
		print("NEMAM HOME NEST, kam se vratit?")
		
func attack(player):
	print("Oh yea!")
	#var gpos = global_position
	#get_parent().remove_child(self)
	#game.add_child(self)
	#position = gpos
	change_state(STATE_ATTACKING)
	print("ATTACK! " + str(global_position) + " => " + str(player.global_position))
	tween_to(player, 1)

func _on_Tween_tween_completed(object, key):
	$Tween.stop_all()
	print("tween completed... " + str(state))
	if state == STATE_ATTACKING:
		$PathPickTimer.stop()
		print("returning....")
		change_state(STATE_RETURNING)
		return_to_nest()
		
	if state == STATE_RETURNING:
		change_state(STATE_SITTING)
		print("returned, resting....")
		current_path = null
		waiting_for_new_path = true
		$PathPickTimer.stop()
		$PathPickTimer.wait_time = randi() % 10 + 3
		print("Waiting " + str($PathPickTimer.wait_time) + " seconds..")
		$PathPickTimer.start()
		
	