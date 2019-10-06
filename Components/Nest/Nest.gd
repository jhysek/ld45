extends Area2D

export var my_nest = false
export var eggs = 0

onready var player = get_node("/root/Game/Player")
onready var title = $Panel/Title

func _ready():
	if my_nest:
		own()
	else:
		lose()

func add_egg(egg):
	eggs += 1
	add_child(egg)

func _on_Nest_body_entered(body):
	if body.is_in_group("Enemy"):
		for overlappng in get_overlapping_bodies():
			if overlappng.is_in_group("Player"):
				return
		lose()
		player.on_nest_losed()
		
	if body.is_in_group("Player"):
		for overlapping in get_overlapping_bodies():
			if overlapping.is_in_group("Enemy") and overlapping.is_alive():
				return
				
		if not my_nest and eggs == 0:
			own()
			player.on_nest_owned()
			
		$AnimationPlayer.play("ShowMenu")
		if my_nest:
			title.text = "MY    NEST" 
			title.set("custom_colors/font_color", Color("#dddddd"))
			#title.set("custom_colors/font_color", Color("#00c5c5"))
			$Panel/InfoEat.show()
		else:
			title.text = "ENEMY'S    NEST"
			title.set("custom_colors/font_color", Color(1, 0, 0))
			$Panel/InfoEat.hide()
		body.on_nest_landed(self)

func _on_Nest_body_exited(body):
	if body.is_in_group("Player"):
		body.on_nest_leaved()
		$AnimationPlayer.play_backwards("ShowMenu")
	
func own():
	if not my_nest:
		$CPUParticles2D.emitting = true
		$Sprite.self_modulate = Color("#F3F3F3")
		my_nest = true
		
func lose():
	if my_nest:
		$Sprite.self_modulate = Color("#454545")
		my_nest = false	