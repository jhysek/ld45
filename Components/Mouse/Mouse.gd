extends Area2D

export var speed = 400
export var food_value = 2

var dead = false
var direction = 1

func _ready():
	direction = randi() % 2 
	set_process(true)

func die():
	dead = true
	set_process(false)
	
func _process(delta):
	if not dead:
		position.x = position.x + (direction * speed * delta)
		
		if randi() % 100 > 90:
			direction = randi() % 2