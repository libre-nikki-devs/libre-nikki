extends YumeWorld

@onready var player: YumePlayer = get_node("Sakutsuki")

func _ready() -> void:
	await Game.scene_changed

	if Game.current_scene_state != Game.SCENE_STATES.FROM_FILE:
		match Game.persistent_data.get("entered_from", false):
			"res://scenes/maps/amber_corridors.tscn":
				player.facing = YumeCharacter.DIRECTION.DOWN
				player.position = Vector2(104.0, -72.0)

			"res://scenes/maps/sakutsukis_dream_bedroom.tscn":
				player.facing = YumeCharacter.DIRECTION.DOWN
				player.position = Vector2(8.0, 24.0)

	process_mode = Node.PROCESS_MODE_DISABLED
	Game.transition_handler.play("fade_in")
	await Game.transition_handler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_door_opened() -> void:
	Game.transition_handler.play("fade_out")
	process_mode = Node.PROCESS_MODE_DISABLED
	await Game.transition_handler.animation_finished
	Game.save_current_scene()
	Game.save_player_data(player)
	Game.change_scene("res://scenes/maps/sakutsukis_dream_bedroom.tscn")

func _on_amber_corridors_door_opened() -> void:
	Game.transition_handler.play("fade_out")
	process_mode = Node.PROCESS_MODE_DISABLED
	await Game.transition_handler.animation_finished
	Game.save_current_scene()
	Game.save_player_data(player)
	Game.change_scene("res://scenes/maps/amber_corridors.tscn")

func _on_bike_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		body.grant_effect(YumePlayer.EFFECT.BIKE)
		body.equip(YumePlayer.EFFECT.BIKE)
