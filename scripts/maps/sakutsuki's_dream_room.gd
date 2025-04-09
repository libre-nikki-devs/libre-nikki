extends YumeWorld

func _ready() -> void:
	super()

	if Game.persistent_data.has("entered_from"):
		if Game.persistent_data["entered_from"] == "Nexus":
			player.position = Vector2(56, -56)
			player.face(Game.DIRECTION.DOWN)

	get_tree().paused = true
	Game.transition(Game.TRANSITION.FADE_IN, 1.0)
	await Game.transition_finished
	get_tree().paused = false

func _on_door_opened() -> void:
	Game.transition(Game.TRANSITION.FADE_OUT, 1.0)
	get_tree().paused = true
	await Game.transition_finished
	change_world("Nexus")
