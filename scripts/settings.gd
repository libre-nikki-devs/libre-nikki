# Copyright (C) 2025 boot <bootovy@proton.me> and contributors.

# This file is part of Libre Nikki.

# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

extends Control

# WIP

@onready var licenses_button: Button = get_node("SidePanelContainer/SideVBoxContainer/LicensesButton")
@onready var licenses_menu: Control = get_node("MainPanelContainer/LicensesVBoxContainer")
@onready var side_menu: Control = get_node("SidePanelContainer/SideVBoxContainer")
@onready var license_thingy = get_node("LicensePanelContainer")
@onready var license_label = get_node("ScrollContainer/LicenseLabel")
@onready var scroll = get_node("ScrollContainer")

var focus

#func _on_h_slider_value_changed(value: float) -> void:
	#get_node("Control3/Panel/Label3").text = str(get_node("Control3/Panel/HSlider").value) + "%"
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value / 100.0))

func _ready() -> void:
	var license_directory = DirAccess.open("res://LICENSES")

	if license_directory:
		license_directory.list_dir_begin()
		var license = license_directory.get_next()

		while license != "":
			if not license_directory.current_is_dir():
				var button = Button.new()
				# button.text = license
				button.text = " "
				button.size_flags_horizontal = 3
				var label = Label.new()
				label.text = license
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.set_anchors_preset(Control.PRESET_FULL_RECT)
				button.add_child(label)
				button.pressed.connect(_on_license_pressed.bind(license))
				licenses_menu.add_child(button)
			license = license_directory.get_next()

	licenses_menu.show()
	licenses_button.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		var focus_owner: Control = get_viewport().gui_get_focus_owner()

		if focus_owner:
			match focus_owner.get_parent():
				scroll:
					Game.transition(Game.TRANSITION.FADE_OUT, 0.1)
					await Game.transition_finished
					license_thingy.hide()
					scroll.hide()
					licenses_button.grab_focus()
					Game.transition(Game.TRANSITION.FADE_IN, 0.1)
				licenses_menu:
					licenses_button.grab_focus()
				side_menu:
					close_menu()

func close_menu():
	Game.transition(Game.TRANSITION.FADE_OUT, 0.1)
	await Game.transition_finished
	Game.transition(Game.TRANSITION.FADE_IN, 0.1)
	focus.grab_focus()
	queue_free()

func _on_licenses_button_pressed() -> void:
	licenses_menu.show()

	if licenses_menu.get_child_count() > 0:
		licenses_menu.get_child(0).grab_focus()

func _on_license_pressed(license: String) -> void:
	Game.transition(Game.TRANSITION.FADE_OUT, 0.1)
	await Game.transition_finished
	var file = FileAccess.open("res://LICENSES/" + license, FileAccess.READ)
	license_thingy.show()
	scroll.show()
	license_label.text = file.get_as_text()
	license_label.grab_focus()
	Game.transition(Game.TRANSITION.FADE_IN, 0.1)
