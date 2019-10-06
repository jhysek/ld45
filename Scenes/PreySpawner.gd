extends Timer

var Mouse = preload("res://Components/Mouse/Mouse.tscn")
var Worm  = preload("res://Components/Worm/Worm.tscn")

export var worms_only = false
export var local = false

var source

func _on_PreySpawner_timeout():
	var prey 
	if !worms_only and randi() % 4 == 0:
		prey = Mouse.instance()
	else:
		prey = Worm.instance()
		
	get_node("/root/Game/Prey").add_child(prey)
	if local and source:
		prey.position.x = source.global_position.x
		prey.position.y = 250
	else:
		prey.position = Vector2(randi() % 2000 - 1000, 250 )
	
	wait_time = randi() % 20 + get_node("/root/Game/Prey").get_children().size() / 2
	start()	
