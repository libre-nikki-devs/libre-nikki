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

class_name YumeMenu
extends Control

@export var initially_focused: Control = null

var previously_focused: Control = null

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			var viewport: Viewport = get_viewport()

			if viewport:
				var focus_owner: Control = viewport.gui_get_focus_owner()

				if focus_owner:
					previously_focused = focus_owner

			if initially_focused:
				initially_focused.call_deferred("grab_focus")

			_post_open()

func _pre_open() -> void:
	Game.transition_handler.play("fade_out", -1, 10.0)
	await Game.transition_handler.animation_finished

func _post_open() -> void:
	Game.transition_handler.play("fade_in", -1, 10.0)

func _pre_close() -> void:
	Game.transition_handler.play("fade_out", -1, 10.0)
	await Game.transition_handler.animation_finished
	Game.transition_handler.play("fade_in", -1, 10.0)

func open(menu_path: String) -> void:
	await _pre_open()
	var menu: PackedScene = load(menu_path)
	add_child(menu.instantiate())

func close() -> void:
	await _pre_close()

	if previously_focused:
		previously_focused.call_deferred("grab_focus")

	queue_free()

func close_all() -> void:
	var menu: YumeMenu = self

	while true:
		var parent: Node = menu.get_parent()

		if not parent or parent is not YumeMenu:
			break

		menu = parent

	menu.close()
