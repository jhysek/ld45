extends Node2D


func _on_StartBtn_pressed():
	$Sfx/Click.play()
	get_tree().change_scene("res://Scenes/Game.tscn")

func _on_StartBtn_mouse_entered():
	$Sfx/Hover.play()

func _on_StartBtn_mouse_exited():
	$Sfx/Hover.play()


func _on_QuitBrn_pressed():
	get_tree().quit()