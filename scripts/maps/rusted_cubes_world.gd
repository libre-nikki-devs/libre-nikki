extends YumeWorld


@onready var player: YumePlayer = $Sakutsuki


func _ready() -> void:
	match Game.persistent_data.get("entered_from", false):
		"res://scenes/maps/amber_corridors.tscn":
			player.facing = YumeCharacter.Direction.DOWN
			player.position = Vector2(-936.0, -728.0)

		"res://scenes/maps/nexus.tscn":
			match player.facing:
				YumeCharacter.Direction.LEFT:
					player.position = Vector2(-248.0, -328.0)

				YumeCharacter.Direction.DOWN:
					player.position = Vector2(-264.0, -344.0)

				YumeCharacter.Direction.UP:
					player.position = Vector2(-264.0, -312.0)

				YumeCharacter.Direction.RIGHT:
					player.position = Vector2(-280.0, -328.0)

			TransitionHandler.play(&"blend_in")
			await TransitionHandler.animation_finished
			process_mode = PROCESS_MODE_PAUSABLE
			return

	TransitionHandler.play(&"fade_in")
	await TransitionHandler.animation_finished
	process_mode = PROCESS_MODE_PAUSABLE


func _on_nexus_teleport_body_interacted(body: Node2D) -> void:
	process_mode = PROCESS_MODE_DISABLED
	await TransitionHandler.prepare_texture()
	await RenderingServer.frame_post_draw
	Game.save_current_scene()
	Game.change_scene("res://scenes/maps/nexus.tscn")


func _on_amber_corridors_door_opened() -> void:
	TransitionHandler.play(&"fade_out")
	process_mode = PROCESS_MODE_DISABLED
	await TransitionHandler.animation_finished
	await RenderingServer.frame_post_draw
	Game.save_current_scene()
	Game.change_scene("res://scenes/maps/amber_corridors.tscn")
