extends YumeWorld

func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func _ready() -> void:
	Game.transition_handler.play("pixelate_in")
	await Game.transition_handler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE

func save_game(save_path: String):
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(Game.persistent_data)

func _on_bed_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		process_mode = Node.PROCESS_MODE_DISABLED
		Game.transition_handler.play("pixelate_out")
		await Game.transition_handler.animation_finished
		process_mode = Node.PROCESS_MODE_PAUSABLE
		Game.sleep()

func _on_desk_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		Game.open_menu("res://scenes/ui/save_manager.tscn")
