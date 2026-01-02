extends Area2D
# Humans can trip on this stone if certain conditions are met

func _on_body_entered(body: Node2D) -> void:
	if body is Human:
		var human: Human = body as Human
		if human.movement.is_sprinting() || human.movement.is_moving_backwards():
			Chatbox.important_message("[color=danger][b][i]%s over a rock![/i][/b][/color]" % [TextManager.parse("You trip",body)], Chatbox.ColorLib["danger"])
			SoundManager.play_sound_2d(SoundLib.trip_sound, global_position, -15.0)
			human.actions.fall(true if human.movement.is_moving_backwards() else false)
