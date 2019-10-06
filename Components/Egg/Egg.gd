extends Area2D

export var my_egg = false
export var hatch_time = 10

var Bird = load("res://Components/Bird/Bird.tscn")
var parent 
var home_nest
var hatch_timeout = 60

onready var progress = $ProgressBar

func _ready():
	hatch_timeout = hatch_time
	set_process(true)
	
func _process(delta):
	if hatch_timeout > 0:
		hatch_timeout -= delta
		progress.value = round((hatch_time - hatch_timeout) / hatch_time * 100)
	else:
		set_process(false)
		_on_HatchTimer_timeout()
		
	
func _on_HatchTimer_timeout():
	var bird = Bird.instance()
	bird.initiate_as_offspring()
	bird.parent = parent
	get_parent().add_child(bird)
	bird.position = Vector2(randi() % 40 - 20, -20)
	
	
	# create birdie
	queue_free()	
