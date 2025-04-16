# Copyright (C) 2025 boot <bootovy@proton.me> and contributors.

# This file is part of Libre Nikki.

# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

extends Control

@onready var effects_button = get_node("SidePanelContainer/VBoxContainer/EffectsButton")
@onready var effects_label = get_node("SidePanelContainer/VBoxContainer/EffectsButton/EffectsLabel")
@onready var actions_button = get_node("SidePanelContainer/VBoxContainer/ActionsButton")
@onready var settings_button = get_node("SidePanelContainer/VBoxContainer/SettingsButton")
@onready var quit_button = get_node("SidePanelContainer/VBoxContainer/QuitButton")
@onready var money_label = get_node("MoneyPanelContainer/MoneyLabel")
@onready var players_margin_container = get_node("MainPanelContainer/VBoxContainer")
@onready var effects_grid_container = get_node("MainPanelContainer/EffectsGridContainer")
@onready var world_label = get_node("WorldHFlowContainer/PanelContainer2/WorldLabel")
@onready var depth_label = get_node("WorldHFlowContainer/PanelContainer4/DepthLabel")
@onready var player_avatar = get_node("MainPanelContainer/VBoxContainer/HBoxContainer/TextureRect/AnimatedSprite2D")
@onready var player_label = get_node("MainPanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/PlayerLabel")
@onready var player_effects_label = get_node("MainPanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/PlayerEffectsLabel")
@onready var health_label = get_node("MainPanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/HealthLabel")
@onready var actions_grid_container = get_node("MainPanelContainer/ActionsGridContainer")

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

	world_label.text = Game.world.name

	if Game.persistent_data.has("money"):
		money_label.text = str(Game.persistent_data["money"])
	else:
		money_label.text = "0"

	depth_label.text = Game.world.depth

	if Game.world.player.effect == 0:
		player_avatar.animation = "down"
	else:
		player_avatar.animation = "down" + Game.EFFECT.find_key(Game.world.player.effect).capitalize()

	player_label.text = Game.world.player.name

	if Game.persistent_data.has("acquired_effects"):
		player_effects_label.text = "FX: " + str(Game.persistent_data["acquired_effects"] & 1) + "/" + str(Game.EFFECT.size() - 1)
	else:
		player_effects_label.text = "FX: 0/" + str(Game.EFFECT.size() - 1)

	if Game.persistent_data.has("health"):
		health_label.text = "HP: " + str(Game.persistent_data["health"])
	else:
		health_label.text = "HP: 0"

	if Game.persistent_data.has("acquired_effects"):
		for effect: Game.EFFECT in Game.EFFECT.values():
			if Game.persistent_data["acquired_effects"] & effect:
				var button = Button.new()
				# button.text = Game.EFFECT.find_key(effect).capitalize()
				button.text = " "
				button.size_flags_horizontal = 3
				var label = Label.new()
				label.text = Game.EFFECT.find_key(effect).capitalize()
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.set_anchors_preset(Control.PRESET_FULL_RECT)
				button.add_child(label)
				button.pressed.connect(_on_effect_button_pressed.bind(effect))
				if not Game.world.dreaming:
					button.disabled = true
					label.modulate.a = 0.5
				effects_grid_container.add_child(button)

@export var side_menu: Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		var focus_owner: Control = get_viewport().gui_get_focus_owner()

		if focus_owner:
			match focus_owner.get_parent():
				actions_grid_container:
					players_margin_container.show()
					effects_grid_container.hide()
					actions_grid_container.hide()
					actions_button.grab_focus()
				effects_grid_container:
					players_margin_container.show()
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

	Game.transition(Game.TRANSITION.FADE_OUT, 0.1)

	await Game.transition_finished

	for child: Control in button.get_parent().get_children():
		if child != button:
			child.focus_mode = Control.FOCUS_ALL
			child.mouse_filter = Control.MOUSE_FILTER_STOP

	button_finished.emit()

func _on_actions_button_pressed() -> void:
	players_margin_container.hide()
	effects_grid_container.hide()
	actions_grid_container.show()
	if actions_grid_container.get_child_count() > 0:
		actions_grid_container.get_children()[0].grab_focus()

func _on_quit_button_pressed() -> void:
	_on_button_pressed(quit_button)
	await button_finished
	get_tree().paused = false
	Game.world.change_world("Main Menu", false, [])
	queue_free()

func _on_effects_button_pressed() -> void:
	players_margin_container.hide()
	effects_grid_container.show()
	actions_grid_container.hide()
	effects_grid_container.get_children()[0].grab_focus()

func _on_effect_button_pressed(effect: Game.EFFECT) -> void:
	close_menu()

	if Game.world.player.effect == effect:
		Game.world.player.equip()
	else:
		Game.world.player.equip(effect)

func _on_settings_button_pressed() -> void:
	_on_button_pressed(settings_button)
	await button_finished
	Game.open_settings(settings_button)

func close_menu():
	Game.transition(Game.TRANSITION.FADE_OUT, 0.1)
	await Game.transition_finished
	Game.transition(Game.TRANSITION.FADE_IN, 0.1)
	get_tree().paused = false
	queue_free()

func _on_pinch_cheek_button_pressed() -> void:
	close_menu()
	Game.world.player.pinch_cheek()
