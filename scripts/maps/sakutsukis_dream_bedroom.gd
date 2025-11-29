extends YumeWorld

@onready var player: YumePlayer = get_node("Sakutsuki")

func _ready() -> void:
	if Game.persistent_data.has("entered_from"):
		if Game.persistent_data["entered_from"] == "res://scenes/maps/nexus.tscn":
			player.position = Vector2(48, -48)
			player.facing = YumeCharacter.DIRECTION.DOWN

	process_mode = Node.PROCESS_MODE_DISABLED
	Game.transition_handler.play("pixelate_in")
	await Game.transition_handler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_door_opened() -> void:
	Game.transition_handler.play("fade_out")
	process_mode = Node.PROCESS_MODE_DISABLED
	await Game.transition_handler.animation_finished
	Game.save_player_data(player)
	Game.change_scene("res://scenes/maps/nexus.tscn")
