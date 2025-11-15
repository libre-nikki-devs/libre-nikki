class_name TransitionableTween

static func create_tween(caller):
	var tween = caller.create_tween()

	Game.transition_handler.current_animation_changed.connect(func(_animation):
		tween.custom_step(99)
		, CONNECT_ONE_SHOT)
	
	return tween
