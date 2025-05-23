extends YumeWorld

func _ready() -> void:
	super()

	if Game.persistent_data.has("entered_from"):
		if Game.persistent_data["entered_from"] == "Sakutsuki's Dream Bedroom":
			player.face(Game.DIRECTION.DOWN)

	get_tree().paused = true
	Game.transition_handler.play("fade_in")
	await Game.transition_handler.animation_finished
	get_tree().paused = false

func _on_door_opened() -> void:
	Game.transition_handler.play("fade_out")
	get_tree().paused = true
	await Game.transition_handler.animation_finished
	change_world("Sakutsuki's Dream Bedroom")

func _on_bike_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		Game.grant_effect(Game.EFFECT.BIKE)
		body.equip(Game.EFFECT.BIKE)
