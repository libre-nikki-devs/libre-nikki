extends YumeWorld

@onready var greeting: CanvasLayer = get_node("GreetingCanvasLayer")
@onready var greeting_label: Label = get_node("GreetingCanvasLayer/GreetingLabel")

func _ready() -> void:
	super()

	if Game.persistent_data.has("world_visits"):
		if Game.persistent_data["world_visits"].has(self.name):
			if Game.persistent_data["world_visits"][self.name] > 1:
				greeting.visible = false
				Game.transition_handler.play("fade_in")
				await Game.transition_handler.animation_finished
				get_tree().paused = false
				return

	get_tree().paused = true
	greeting.visible = true
	greeting_label.grab_focus()
	player.is_busy = true
	Game.transition_handler.play("fade_in")
	await Game.transition_handler.animation_finished
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("accept") or event.is_action_pressed("cancel"):
		var focus_owner: Control = get_viewport().gui_get_focus_owner()

		if focus_owner:
			match focus_owner.get_parent():
				greeting:
					get_tree().paused = true
					Game.transition_handler.play("fade_out", -1, 2.0)
					await Game.transition_handler.animation_finished
					greeting.visible = false
					Game.transition_handler.play("fade_in", -1, 2.0)
					await Game.transition_handler.animation_finished
					get_tree().paused = false
					player.is_busy = false

func save_game(save_path: String):
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(Game.persistent_data)

func _on_bed_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		get_tree().paused = true
		Game.transition_handler.play("fade_out")
		await Game.transition_handler.animation_finished
		get_tree().paused = false

		if Game.persistent_data.has("player_data"):
			Game.persistent_data["player_data"] = {}

		Game.sleep()

func _on_desk_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		Game.save_player_data(player, ["facing", "position"])
		save_game("user://save01.libki")
