extends Node2D

var speed = 1

func set_color(color_code):
	$Label.set("custom_colors/font_color", Color(color_code))
	
func fire(text, speed):
	$Label.text = text
	$AnimationPlayer.playback_speed = speed
	$AnimationPlayer.play("Show")
	
func destroy():
	queue_free()