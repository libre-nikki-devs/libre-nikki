extends YumeWorld

func _ready() -> void:
	if Game.persistent_data.has("entered_from"):
		if Game.persistent_data["entered_from"] == "res://scenes/maps/nexus.tscn":
			player.position = Vector2(48, -48)
			player.facing = YumeCharacter.DIRECTION.DOWN

	get_tree().paused = true
	Game.transition_handler.play("pixelate_in")
	await Game.transition_handler.animation_finished
	get_tree().paused = false

func _on_door_opened() -> void:
	Game.transition_handler.play("fade_out")
	get_tree().paused = true
	await Game.transition_handler.animation_finished
	Game.save_player_data(player)
	Game.change_scene("res://scenes/maps/nexus.tscn")
