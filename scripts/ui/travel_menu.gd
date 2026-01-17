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

const MAP_DIRECTORY: String = "res://scenes/maps"

@onready var filter_bar: LineEdit = get_node("FilterBar")

@onready var map_container: VBoxContainer = get_node("PanelContainer/MapContainer")

func _ready() -> void:
	var maps: PackedStringArray = ResourceLoader.list_directory(MAP_DIRECTORY)

	for map_name: String in maps:
		map_name = MAP_DIRECTORY + "/" + map_name
		var map: Resource = load(map_name)

		if map is PackedScene:
			var map_state: SceneState = map.get_state()
			var pretty_name: String
			var property_id: int = 0

			while property_id < map_state.get_node_property_count(0) and pretty_name.is_empty():
				if map_state.get_node_property_name(0, property_id) == "pretty_name":
					pretty_name = map_state.get_node_property_value(0, property_id)

				property_id += 1

			if pretty_name.is_empty():
				pretty_name =  map_state.get_node_name(0)

			var button: Button = Button.new()
			button.text = " "
			button.size_flags_horizontal = 3
			var label: Label = Label.new()
			label.text = pretty_name
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.set_anchors_preset(Control.PRESET_FULL_RECT)
			button.add_child(label)
			button.pressed.connect(_on_map_button_pressed.bind(map_name))
			map_container.add_child(button)

	for child: Node in map_container.get_children():
		child.focus_neighbor_left = child.get_path()
		child.focus_neighbor_bottom = map_container.get_child((child.get_index() + 1) % map_container.get_child_count()).get_path()
		child.focus_neighbor_top = map_container.get_child((child.get_index() - 1) % map_container.get_child_count()).get_path()
		child.focus_neighbor_right = child.focus_neighbor_left
		child.focus_previous = child.focus_neighbor_top
		child.focus_next = child.focus_neighbor_bottom

func _input(event: InputEvent) -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()

	if focus_owner:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_text_submit"):
			match focus_owner:
				filter_bar:
					_get_focus_grabber().call_deferred("grab_focus")

		if event.is_action_pressed("ui_go_back"):
			match focus_owner:
				map_container:
					close()

			match focus_owner.get_parent():
				map_container:
					close()

	if Input.is_key_pressed(KEY_SLASH):
		filter_bar.call_deferred("edit")

func _get_focus_grabber() -> Control:
	for child_id in map_container.get_child_count():
		var current_child: Node = map_container.get_child(child_id)

		if current_child is Control and current_child.visible:
			return current_child

	return map_container

func _on_map_button_pressed(scene: String) -> void:
	Game.save_player_data(get_tree().get_first_node_in_group("Players"))
	Game.transition_handler.play("fade_out", -1, 10.0)
	await Game.transition_handler.animation_finished
	Game.transition_handler.seek(0.0, true)
	Game.transition_handler.stop()
	Game.change_scene(scene)
	get_root_menu().queue_free()

func _on_filter_bar_focus_entered() -> void:
	filter_bar.placeholder_text = "Filter..."

func _on_filter_bar_focus_exited() -> void:
	filter_bar.placeholder_text = "Type '/' to filter..."

func _on_filter_bar_text_changed(new_text: String) -> void:
	for child in map_container.get_children():
		if new_text.is_empty():
			child.show()
		else:
			if child.get_child(0).text.containsn(new_text):
				child.show()
			else:
				child.hide()
