extends YumeWorld

func _ready() -> void:
	super()

	if Game.persistent_data.has("entered_from"):
		if Game.persistent_data["entered_from"] == "Sakutsuki's Dream Room":
			player.face(Game.DIRECTION.DOWN)

	get_tree().paused = true
	Game.transition(Game.TRANSITION.FADE_IN, 1.0)
	await Game.transition_finished
	get_tree().paused = false

func _physics_process(delta: float) -> void:
	parallax_layers[0].motion_offset += Vector2(8, 8) * delta

func _on_door_opened() -> void:
	Game.transition(Game.TRANSITION.FADE_OUT, 1.0)
	get_tree().paused = true
	await Game.transition_finished
	change_world("Sakutsuki's Dream Room")

func _on_bike_body_interacted(body: Node2D) -> void:
	if body is YumePlayer:
		Game.grant_effect(Game.EFFECT.BIKE)
		body.equip(Game.EFFECT.BIKE)
