extends KinematicBody2D

const STATE_SITTING = 0
const STATE_FLYING = 1

const GRAVITY = 2000
const FLAP_FORCE = -1000
const FLY_SPEED = 40000
const WALK_SPEED = 10000

var state = STATE_SITTING
var motion = Vector2(0,0)
var grounded = true
var speed = WALK_SPEED

onready var claw_ray = $Visuals/ClawRay
onready var visual   = $Visuals
onready var anim     = $AnimationPlayer

func _ready():
	set_physics_process(true)
	
func _physics_process(delta):
	grounded = claw_ray.is_colliding()
	if grounded:
		if state != STATE_SITTING:
			change_state(STATE_SITTING)
	
	else:
		speed = FLY_SPEED
		if state != STATE_FLYING:
			change_state(STATE_FLYING)
	
	motion.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_attack"):
		anim.stop(true)
		if visual.scale.x > 0:
			anim.play("AttackRight")
		else:
			anim.play("AttackLeft")
	
	if Input.is_action_just_pressed("ui_select"):
		motion.y = FLAP_FORCE
		anim.stop(true)
		anim.play("Flap")
		
	if Input.is_action_pressed("ui_left"):
		if visual.scale.x > 0:
			visual.scale.x = -1
		motion.x = max(motion.x - speed * delta, -speed * delta)
		
	if Input.is_action_pressed("ui_right"):
		if visual.scale.x < 0:
			visual.scale.x = 1
		motion.x = min(motion.x + speed * delta, speed * delta)
		
	elif !Input.is_action_pressed("ui_left") and grounded:
		motion.x = 0
		#motion.y = 0
		
	motion = move_and_slide(motion, Vector2(0,0), true)
	
	
func change_state(target):
	print(str(state) + " -> " + str(target));
	if target == state:
		return
		
	if target == STATE_SITTING:
		state = STATE_SITTING
		speed = WALK_SPEED
		anim.play("Idle")
		
	if target == STATE_FLYING:
		state = STATE_FLYING
		speed = FLY_SPEED
		anim.play("Flap")
		