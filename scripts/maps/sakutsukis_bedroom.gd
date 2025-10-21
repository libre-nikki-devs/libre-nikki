extends YumeWorld

@onready var player: YumePlayer = get_node("Sakutsuki")

func _ready() -> void:
	get_tree().paused = true
	Game.transition_handler.play("pixelate_in")
	await Game.transition_handler.animation_finished
	get_tree().paused = false

func save_game(save_path: String):
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(Game.persistent_data)

func _on_bed_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		get_tree().paused = true
		Game.transition_handler.play("pixelate_out")
		await Game.transition_handler.animation_finished
		get_tree().paused = false

		if Game.persistent_data.has("player_data"):
			Game.persistent_data["player_data"] = {}

		Game.sleep()

func _on_desk_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		get_tree().paused = true
		Game.transition_handler.play("fade_out", -1, 10.0)
		await Game.transition_handler.animation_finished
		var save_manager: VBoxContainer = preload("res://scenes/ui/save_manager.tscn").instantiate()
		save_manager.mode = save_manager.MODES.SAVE
		Game.add_child(save_manager)
		Game.transition_handler.play("fade_in", -1, 10.0)
