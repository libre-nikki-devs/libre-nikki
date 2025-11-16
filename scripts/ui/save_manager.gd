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

extends VBoxContainer

enum MODES { SAVE = 0, LOAD = 1 }

const SAVE_SLOTS: int = 16

const SAVE_DIRECTORY: String = "user://saves"

@onready var save_container: VBoxContainer = get_node("SaveContainer/ScrollContainer/VBoxContainer")

@onready var label: Label = get_node("LabelContainer/Label")

var mode: MODES = MODES.SAVE

var focus

func _ready() -> void:
	if mode == MODES.SAVE:
		label.text = "Save to which slot?"
	else:
		label.text = "Load from which slot?"

	for slot: int in range(1, SAVE_SLOTS + 1):
		var save_slot: PanelContainer = preload("res://scenes/ui/save_slot.tscn").instantiate()
		save_container.add_child(save_slot)
		save_slot.label.text = "Save %02d" % slot

		if mode == MODES.SAVE:
			save_slot.button.connect("pressed", _on_save_button_pressed.bind(slot))
		else:
			save_slot.button.connect("pressed", _on_load_button_pressed.bind(slot))

		var file: FileAccess = FileAccess.open(SAVE_DIRECTORY.path_join("save%02d.libki" % slot), FileAccess.READ)

		if file:
			var data: Variant = file.get_var()
			file.close()

			if data is Dictionary:
				var player_panel: HBoxContainer = preload("res://scenes/ui/player_panel.tscn").instantiate()
				player_panel.data = data
				save_slot.v_box_container.add_child(player_panel)

	for child: Control in save_container.get_children():
		child.button.focus_neighbor_left = child.button.get_path()
		child.button.focus_neighbor_bottom = save_container.get_child((child.get_index() + 1) % save_container.get_child_count()).button.get_path()
		child.button.focus_neighbor_top = save_container.get_child((child.get_index() - 1) % save_container.get_child_count()).button.get_path()
		child.button.focus_neighbor_right = child.button.focus_neighbor_left
		child.button.focus_previous = child.button.focus_neighbor_top
		child.button.focus_next = child.button.focus_neighbor_bottom

	save_container.get_child(0).button.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_go_back"):
		var focus_owner: Control = get_viewport().gui_get_focus_owner()

		if focus_owner:
			close_menu()

func save_game(slot: int):
	if not DirAccess.dir_exists_absolute(SAVE_DIRECTORY):
		DirAccess.make_dir_absolute(SAVE_DIRECTORY)

	var file: FileAccess = FileAccess.open(SAVE_DIRECTORY.path_join("save%02d.libki" % (slot)), FileAccess.WRITE)

	if file:
		var player: YumePlayer = get_tree().get_first_node_in_group("Players")

		if player:
			Game.save_player_data(player, ["accept_events", "cancel_events", "equipped_effect", "facing", "global_position", "last_step", "name", "speed"])
			file.store_var(Game.persistent_data)

		file.close()

func load_game(slot: int):
	var file: FileAccess = FileAccess.open(SAVE_DIRECTORY.path_join("save%02d.libki" % (slot)), FileAccess.READ)

	if file:
		var data: Variant = file.get_var()
		file.close()

		if data is Dictionary:
			Game.persistent_data = data
			Game.transition_handler.play("fade_out", -1, 10.0)
			await Game.transition_handler.animation_finished

			if Game.persistent_data.has("current_scene"):
				Game.change_scene(Game.persistent_data["current_scene"])
			else:
				Game.persistent_data["player_data"] = {
					"facing": YumeCharacter.DIRECTION.LEFT,
					"global_position": Vector2(-56.0, 8.0)
				}

				Game.change_scene("res://scenes/maps/sakutsukis_bedroom.tscn")

			queue_free()

func close_menu():
	Game.transition_handler.play("fade_out", -1, 10.0)
	await Game.transition_handler.animation_finished
	Game.transition_handler.play("fade_in", -1, 10.0)
	get_tree().paused = false

	if focus:
		focus.grab_focus()

	queue_free()

func _on_save_button_pressed(slot):
	save_game(slot)
	close_menu()

func _on_load_button_pressed(slot):
	load_game(slot)
