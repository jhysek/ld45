extends Node2D

var Mouse = preload("res://Components/Mouse/Mouse.tscn")
var Worm  = preload("res://Components/Worm/Worm.tscn")

export var worms_only = false
export var local = false

var source

func _ready():
	$Timer.start()

func _on_Timer_timeout():
	var prey 
	if !worms_only and randi() % 4 == 0:
		prey = Mouse.instance()
	else:
		prey = Worm.instance()
		
	print("SPAWNED..")
	get_node("/root/Game/Prey").add_child(prey)
	prey.position = global_position + Vector2(randi() % 100 - 50, 0)
	
	$Timer.wait_time = randi() % 10 + get_node("/root/Game/Prey").get_children().size() / 2
	$Timer.start()	
