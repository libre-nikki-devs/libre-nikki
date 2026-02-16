# Copyright (C) 2026 Libre Nikki Developers.
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

class_name YumeCamera
extends Camera2D

var cameraman: YumeCharacter = null

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			if cameraman:
				if cameraman.wrapped.is_connected(_on_cameraman_wrapped):
					cameraman.wrapped.disconnect(_on_cameraman_wrapped)

			cameraman = null
			var node: Node = self

			while true:
				var parent: Node = node.get_parent()
				node = parent

				if not parent:
					return

				if parent is YumeCharacter:
					cameraman = parent
					cameraman.wrapped.connect(_on_cameraman_wrapped)
					return

func _on_cameraman_wrapped(previous_position: Vector2) -> void:
	if not is_current():
		return

	for parallax: Parallax2D in cameraman.current_world.parallaxes:
		parallax.scroll_offset -= previous_position - cameraman.global_position
