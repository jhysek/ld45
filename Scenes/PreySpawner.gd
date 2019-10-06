extends Timer

var Mouse = preload("res://Components/Mouse/Mouse.tscn")
var Worm  = preload("res://Components/Worm/Worm.tscn")



func _on_PreySpawner_timeout():
	var prey 
	if randi() % 4 == 0:
		prey = Mouse.instance()
	else:
		prey = Worm.instance()
		
	get_node("/root/Game/Prey").add_child(prey)
	prey.position = Vector2(randi() % 2000 - 1000, 250 )
	
	wait_time = randi() % 5 + get_node("/root/Game/Prey").get_children().size() / 2
	start()	
