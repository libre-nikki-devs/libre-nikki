extends YumeWorld


func _ready() -> void:
	TransitionHandler.play(&"fade_in")
	await TransitionHandler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _on_nexus_teleport_body_interacted(body: Node2D) -> void:
	TransitionHandler.play(&"fade_out")
	process_mode = Node.PROCESS_MODE_DISABLED
	await TransitionHandler.animation_finished
	await RenderingServer.frame_post_draw
	Game.save_current_scene()
	Game.change_scene("res://scenes/maps/nexus.tscn")


func _on_amber_corridors_door_opened() -> void:
	TransitionHandler.play(&"fade_out")
	process_mode = Node.PROCESS_MODE_DISABLED
	await TransitionHandler.animation_finished
	await RenderingServer.frame_post_draw
	Game.save_current_scene()
	Game.change_scene("res://scenes/maps/amber_corridors.tscn")
