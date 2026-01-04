# Copyright (C) 2025-2026 Libre Nikki Developers.
#
# This file is part of Libre Nikki.
#
# Libre Nikki is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

extends YumeMenu

@onready var menu_container: Container = get_node("MenuContainer")
@onready var play_button: Button = get_node("MenuContainer/ButtonContainer/PlayButton")
@onready var continue_button: Button = get_node("MenuContainer/ButtonContainer/ContinueButton")
@onready var continue_label: Label = get_node("MenuContainer/ButtonContainer/ContinueButton/ContinueLabel")
@onready var settings_button: Button = get_node("MenuContainer/ButtonContainer/SettingsButton")
@onready var quit_button: Button = get_node("MenuContainer/ButtonContainer/QuitButton")
@onready var version_label: Label = get_node("VersionLabel")
@onready var greeting: Control = get_node("Greeting")
@onready var greeting_label: RichTextLabel = get_node("Greeting/GreetingLabel")

var url_hovered: bool = false

func _ready() -> void:
	menu_container.visible = false
	play_button.visible = false
	continue_button.visible = false
	settings_button.visible = false
	quit_button.visible = false
	version_label.text = ProjectSettings.get_setting("application/config/version")

	var save_directory: String = (preload("res://scenes/ui/save_manager.tscn").instantiate().SAVE_DIRECTORY)

	if DirAccess.dir_exists_absolute(save_directory):
		if not DirAccess.get_files_at(save_directory).is_empty():
			continue_button.disabled = false
			continue_label.modulate.a = 1.0
			continue_button.grab_focus()
			return

	continue_button.disabled = true
	continue_label.modulate.a = 0.5
	play_button.grab_focus()

func _post_open() -> void:
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

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")) and not get_tree().paused:
		var focus_owner: Control = get_viewport().gui_get_focus_owner()

		if focus_owner:
			match focus_owner.get_parent():
				greeting:
					if not event.is_action_pressed("ui_accept") or not url_hovered or not event is InputEventMouseButton:
						get_tree().paused = true
						Game.transition_handler.play("fade_out")
						await Game.transition_handler.animation_finished
						greeting.visible = false
						get_tree().paused = false
						Game.change_scene("res://scenes/maps/sakutsukis_bedroom.tscn")
						Game.persistent_data.clear()
						Game.scene_data.clear()

func _on_play_button_pressed() -> void:
	Game.transition_handler.play("fade_out", -1, 10.0)
	await Game.transition_handler.animation_finished
	get_tree().paused = true
	greeting.visible = true
	greeting_label.grab_focus()
	Game.transition_handler.play("fade_in")
	await Game.transition_handler.animation_finished
	get_tree().paused = false

func _on_continue_button_pressed() -> void:
	open("res://scenes/ui/save_manager.tscn", { "mode": preload("res://scenes/ui/save_manager.tscn").instantiate().MODES.LOAD })

func _on_settings_button_pressed() -> void:
	open("res://scenes/ui/settings_menu.tscn")

func _on_quit_button_pressed() -> void:
	Game.transition_handler.play("fade_out", -1, 2.0)
	await Game.transition_handler.animation_finished
	get_tree().quit()

func _on_greeting_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)

func _on_greeting_label_meta_hover_started(meta: Variant) -> void:
	url_hovered = true

func _on_greeting_label_meta_hover_ended(meta: Variant) -> void:
	url_hovered = false
