extends Area2D

export var speed = 500
export var food_value = 10

var dead = false
var direction = 1

func _ready():
	set_random_direction()
	set_process(true)

func set_random_direction():
	if randi() % 2 == 1:
		direction = 1
		$Sprite.scale.x = 1
	else:
		direction = -1
		$Sprite.scale.x = -1
		
func die():
	dead = true
	set_process(false)
	$Sprite.hide()
	$SpriteHanging.show()
	
func _process(delta):
	if not dead:
		position.x = position.x + (direction * speed * delta)
		
		if randi() % 100 > 97:
			set_random_direction()
	