extends YumeWorld

@onready var player: YumePlayer = get_node("Sakutsuki")

func _init() -> void:
	super()
	process_mode = Node.PROCESS_MODE_DISABLED

func _ready() -> void:
	if Game.current_scene_load_state != Game.SceneLoadState.FROM_SAVE_FILE:
		if Game.persistent_data.previous_scene == "res://scenes/maps/nexus.tscn":
			player.position = Vector2(48.0, -48.0)
			player.facing = YumeCharacter.Direction.DOWN

	TransitionHandler.play(&"pixelate_in")
	await TransitionHandler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_door_opened() -> void:
	TransitionHandler.play(&"fade_out")
	process_mode = Node.PROCESS_MODE_DISABLED
	await TransitionHandler.animation_finished
	await RenderingServer.frame_post_draw
	Game.change_scene("res://scenes/maps/nexus.tscn")
