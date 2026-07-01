extends YumeWorld


@onready var player: YumePlayer = $Sakutsuki

@onready var coin: YumeInteractable = get_node_or_null(^"Coin")


func _init() -> void:
	super()
	process_mode = Node.PROCESS_MODE_DISABLED

func _ready() -> void:
	if Game.current_scene_load_state != Game.SceneLoadState.FROM_SAVE_FILE:
		match Game.persistent_data.previous_scene:
			"res://scenes/maps/rusted_cubes_world.tscn":
				match player.facing:
					YumeCharacter.Direction.LEFT:
						player.position = Vector2(120.0, -88.0)

					YumeCharacter.Direction.DOWN:
						player.position = Vector2(104.0, -104.0)

					YumeCharacter.Direction.UP:
						player.position = Vector2(104.0, -72.0)

					YumeCharacter.Direction.RIGHT:
						player.position = Vector2(88.0, -88.0)

				TransitionHandler.play(&"blend_in")
				await TransitionHandler.animation_finished
				process_mode = PROCESS_MODE_PAUSABLE
				return

			"res://scenes/maps/sakutsukis_dream_bedroom.tscn":
				player.facing = YumeCharacter.Direction.DOWN
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
		body.grant_effect(YumePlayer.Effect.BIKE)
		body.equip(YumePlayer.Effect.BIKE)


func _on_coin_body_interacted(body: Node2D) -> void:
	Game.money_panel.raise(100)
	Game.persistent_data.money += 100
	coin.queue_free()


func _on_rusted_cubes_teleport_body_interacted(body: Node2D) -> void:
	process_mode = PROCESS_MODE_DISABLED
	await TransitionHandler.prepare_texture()
	await RenderingServer.frame_post_draw
	Game.save_current_scene()
	Game.change_scene("res://scenes/maps/rusted_cubes_world.tscn")


func _on_vending_machine_body_interacted(body: Node2D) -> void:
	Game.money_panel.raise(-100)

	if Game.persistent_data.money >= 100:
		Game.persistent_data.health += 1
		Game.persistent_data.money -= 100
