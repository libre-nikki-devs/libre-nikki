extends YumeWorld

@onready var menu_container: Container = get_node("CanvasLayer/Control/MenuContainer")
@onready var play_button: Button = get_node("CanvasLayer/Control/MenuContainer/ButtonContainer/PlayButton")
@onready var continue_button: Button = get_node("CanvasLayer/Control/MenuContainer/ButtonContainer/ContinueButton")
@onready var continue_label: Label = get_node("CanvasLayer/Control/MenuContainer/ButtonContainer/ContinueButton/ContinueLabel")
@onready var settings_button: Button = get_node("CanvasLayer/Control/MenuContainer/ButtonContainer/SettingsButton")
@onready var quit_button: Button = get_node("CanvasLayer/Control/MenuContainer/ButtonContainer/QuitButton")
@onready var version_label: Label = get_node("CanvasLayer/Control/VersionLabel")

signal button_finished

func _ready() -> void:
	super()

	menu_container.visible = false
	play_button.visible = false
	continue_button.visible = false
	settings_button.visible = false
	quit_button.visible = false
	version_label.text = ProjectSettings.get_setting("application/config/version")

	Game.persistent_data.clear()
	Game.transition_handler.play("fade_in", -1, 2.0)
	await Game.transition_handler.animation_finished
	menu_container.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(menu_container, "size", Vector2(72, 72), 0.15)
	tween.parallel()
	tween.tween_property(menu_container, "position", menu_container.position - Vector2(0, 36), 0.15)
	await tween.finished
	play_button.visible = true
	continue_button.visible = true
	settings_button.visible = true
	quit_button.visible = true

	if FileAccess.file_exists("user://save01.libki"):
		continue_button.disabled = false
		continue_label.modulate.a = 1.0
		continue_button.grab_focus()
	else:
		continue_button.disabled = true
		continue_label.modulate.a = 0.5
		play_button.grab_focus()

func _on_button_pressed(button: Button) -> void:
	for child: Control in button.get_parent().get_children():
		if child != button:
			child.focus_mode = Control.FOCUS_NONE
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if button != quit_button:
		Game.transition_handler.play("fade_out", -1, 10.0)
	else:
		Game.transition_handler.play("fade_out", -1, 2.0)

	await Game.transition_handler.animation_finished

	for child: Control in button.get_parent().get_children():
		if child != button:
			child.focus_mode = Control.FOCUS_ALL
			child.mouse_filter = Control.MOUSE_FILTER_STOP

	button_finished.emit()

func _on_play_button_pressed() -> void:
	_on_button_pressed(play_button)
	await button_finished
	change_world("Sakutsuki's Room", false, [])

func _on_continue_button_pressed() -> void:
	_on_button_pressed(continue_button)
	await button_finished
	load_game("user://save01.libki")
	change_world("Sakutsuki's Room", false, [])

func _on_settings_button_pressed() -> void:
	_on_button_pressed(settings_button)
	await button_finished
	Game.open_settings(settings_button)

func _on_quit_button_pressed() -> void:
	_on_button_pressed(quit_button)
	await button_finished
	get_tree().quit()

func load_game(save_path: String):
	var file = FileAccess.open(save_path, FileAccess.READ)
	Game.persistent_data = file.get_var()
