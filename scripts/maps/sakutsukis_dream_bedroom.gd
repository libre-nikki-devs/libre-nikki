extends YumeWorld

@onready var player: YumePlayer = get_node("Sakutsuki")

func _ready() -> void:
	await Game.scene_changed

	if Game.current_scene_state != Game.SCENE_STATES.FROM_FILE:
		if Game.persistent_data.get("entered_from", "") == "res://scenes/maps/nexus.tscn":
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
	Game.change_scene("res://scenes/maps/nexus.tscn")
