extends YumeWorld

@onready var player: YumePlayer = get_node("Sakutsuki")

func _init() -> void:
	super()
	process_mode = Node.PROCESS_MODE_DISABLED

func _ready() -> void:
	await Game.scene_changed

	if Game.current_scene_state != Game.SCENE_STATES.FROM_FILE:
		match Game.persistent_data.get("entered_from", false):
			"res://scenes/maps/rusted_cubes_world.tscn":
				match player.facing:
					YumeCharacter.DIRECTION.LEFT:
						player.position = Vector2(120.0, -88.0)

					YumeCharacter.DIRECTION.DOWN:
						player.position = Vector2(104.0, -104.0)

					YumeCharacter.DIRECTION.UP:
						player.position = Vector2(104.0, -72.0)

					YumeCharacter.DIRECTION.RIGHT:
						player.position = Vector2(88.0, -88.0)

				TransitionHandler.play(&"blend_in")
				await TransitionHandler.animation_finished
				process_mode = PROCESS_MODE_PAUSABLE
				return

			"res://scenes/maps/sakutsukis_dream_bedroom.tscn":
				player.facing = YumeCharacter.DIRECTION.DOWN
				player.position = Vector2(8.0, 24.0)

	TransitionHandler.play(&"fade_in")
	await TransitionHandler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_door_opened() -> void:
	TransitionHandler.play(&"fade_out")
	process_mode = Node.PROCESS_MODE_DISABLED
	await TransitionHandler.animation_finished
	await RenderingServer.frame_post_draw
	Game.save_current_scene()
	Game.change_scene("res://scenes/maps/sakutsukis_dream_bedroom.tscn")


func _on_bike_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		body.grant_effect(YumePlayer.EFFECT.BIKE)
		body.equip(YumePlayer.EFFECT.BIKE)


func _on_rusted_cubes_teleport_body_interacted(body: Node2D) -> void:
	process_mode = PROCESS_MODE_DISABLED
	await TransitionHandler.prepare_texture()
	await RenderingServer.frame_post_draw
	Game.save_current_scene()
	Game.change_scene("res://scenes/maps/rusted_cubes_world.tscn")
