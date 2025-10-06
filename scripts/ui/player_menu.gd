# Copyright (C) 2025 Libre Nikki Developers.
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

extends Control

@onready var effects_button = get_node("SidePanelContainer/VBoxContainer/EffectsButton")
@onready var effects_label = get_node("SidePanelContainer/VBoxContainer/EffectsButton/EffectsLabel")
@onready var actions_button = get_node("SidePanelContainer/VBoxContainer/ActionsButton")
@onready var travel_button = get_node("SidePanelContainer/VBoxContainer/TravelButton")
@onready var settings_button = get_node("SidePanelContainer/VBoxContainer/SettingsButton")
@onready var quit_button = get_node("SidePanelContainer/VBoxContainer/QuitButton")
@onready var money_panel = get_node("MoneyPanel")
@onready var player_container = get_node("MainPanelContainer/VBoxContainer")
@onready var effects_grid_container = get_node("MainPanelContainer/EffectsGridContainer")
@onready var world_panel = get_node("WorldPanel")
@onready var actions_grid_container = get_node("MainPanelContainer/ActionsGridContainer")
@onready var player: YumePlayer = get_tree().get_first_node_in_group("Players")

signal button_finished

func _ready() -> void:
	if Game.persistent_data.has("acquired_effects"):
		effects_button.disabled = false
		effects_label.modulate.a = 1.0
		effects_button.grab_focus()
	else:
		effects_button.disabled = true
		effects_label.modulate.a = 0.5
		actions_button.grab_focus()

	var current_scene: Node = get_tree().current_scene

	if current_scene is YumeWorld:
		world_panel.show()
		money_panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	else:
		world_panel.hide()
		money_panel.anchors_preset = Control.PRESET_BOTTOM_LEFT

	if Game.persistent_data.has("acquired_effects"):
		for effect: YumePlayer.EFFECT in YumePlayer.EFFECT.values():
			if Game.persistent_data["acquired_effects"] & effect:
				var button: Button = Button.new()
				#button.text = YumePlayer.EFFECT.find_key(effect).capitalize()
				button.text = " "
				button.size_flags_horizontal = 3
				var label: Label = Label.new()
				label.text = YumePlayer.EFFECT.find_key(effect).capitalize()
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.set_anchors_preset(Control.PRESET_FULL_RECT)
				button.add_child(label)
				button.pressed.connect(_on_effect_button_pressed.bind(effect))

				if current_scene is YumeWorld:
					if not current_scene.dreaming:
						button.disabled = true
						label.modulate.a = 0.5

				effects_grid_container.add_child(button)

	for child: Node in effects_grid_container.get_children():
		child.focus_neighbor_left = effects_grid_container.get_child((child.get_index() - 1) % effects_grid_container.get_child_count()).get_path()
		child.focus_neighbor_bottom = effects_grid_container.get_child((child.get_index() + effects_grid_container.columns) % effects_grid_container.get_child_count()).get_path()
		child.focus_neighbor_top = effects_grid_container.get_child((child.get_index() - effects_grid_container.columns) % effects_grid_container.get_child_count()).get_path()
		child.focus_neighbor_right = effects_grid_container.get_child((child.get_index() + 1) % effects_grid_container.get_child_count()).get_path()
		child.focus_previous = child.focus_neighbor_top
		child.focus_next = child.focus_neighbor_bottom

	if OS.is_debug_build():
		travel_button.show()
	else:
		travel_button.hide()

@export var side_menu: Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_go_back"):
		var focus_owner: Control = get_viewport().gui_get_focus_owner()

		if focus_owner:
			match focus_owner.get_parent():
				actions_grid_container:
					player_container.show()
					effects_grid_container.hide()
					actions_grid_container.hide()
					actions_button.grab_focus()

				effects_grid_container:
					player_container.show()
					effects_grid_container.hide()
					actions_grid_container.hide()
					effects_button.grab_focus()

				side_menu:
					close_menu()

func _on_button_pressed(button: Button) -> void:
	for child: Control in button.get_parent().get_children():
		if child != button:
			child.focus_mode = Control.FOCUS_NONE
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	Game.transition_handler.play("fade_out", -1, 10.0)
	await Game.transition_handler.animation_finished

	for child: Control in button.get_parent().get_children():
		if child != button:
			child.focus_mode = Control.FOCUS_ALL
			child.mouse_filter = Control.MOUSE_FILTER_STOP

	button_finished.emit()

func _on_actions_button_pressed() -> void:
	player_container.hide()
	effects_grid_container.hide()
	actions_grid_container.show()

	if actions_grid_container.get_child_count() > 0:
		actions_grid_container.get_children()[0].grab_focus()

func _on_quit_button_pressed() -> void:
	_on_button_pressed(quit_button)
	await button_finished
	get_tree().paused = false
	Game.change_scene("res://scenes/ui/main_menu.tscn")
	queue_free()

func _on_effects_button_pressed() -> void:
	player_container.hide()
	effects_grid_container.show()
	actions_grid_container.hide()
	effects_grid_container.get_children()[0].grab_focus()

func _on_effect_button_pressed(effect: YumePlayer.EFFECT) -> void:
	close_menu()

	if player.equipped_effect == effect:
		player.equip()
	else:
		player.equip(effect)

func _on_settings_button_pressed() -> void:
	_on_button_pressed(settings_button)
	await button_finished
	Game.open_settings(settings_button)

func close_menu():
	Game.transition_handler.play("fade_out", -1, 10.0)
	await Game.transition_handler.animation_finished
	Game.transition_handler.play("fade_in", -1, 10.0)
	get_tree().paused = false
	queue_free()

func _on_pinch_cheek_button_pressed() -> void:
	close_menu()
	player.pinch_cheek()

func _on_travel_button_pressed() -> void:
	_on_button_pressed(travel_button)
	await button_finished
	var travel_menu: Node = preload("res://scenes/ui/travel_menu.tscn").instantiate()
	travel_menu.focus = travel_button
	add_child(travel_menu)
	Game.transition_handler.play("fade_in", -1, 10.0)
