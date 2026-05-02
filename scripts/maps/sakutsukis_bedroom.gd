extends YumeWorld

func _init() -> void:
	super()
	process_mode = Node.PROCESS_MODE_DISABLED

func _ready() -> void:
	TransitionHandler.play(&"pixelate_in")
	await TransitionHandler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE

func save_game(save_path: String):
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(Game.persistent_data)

func _on_bed_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		process_mode = Node.PROCESS_MODE_DISABLED
		TransitionHandler.play(&"pixelate_out")
		await TransitionHandler.animation_finished
		await RenderingServer.frame_post_draw
		process_mode = Node.PROCESS_MODE_PAUSABLE
		Game.sleep()

func _on_desk_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		Game.open_menu("res://scenes/ui/save_manager.tscn")
