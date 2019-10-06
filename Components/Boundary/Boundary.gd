extends Area2D


func _on_Boundary_body_entered(body):
	if body.is_in_group("Player") and body.controlled:
		body.info("The world ends here... go back!", null, null, 0.2)