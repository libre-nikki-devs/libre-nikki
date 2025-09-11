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

extends Node2D

## A node that follows the properties of the other node.

var mimic_properties: Array[String] = []

var mimic_position_offset: Vector2 = Vector2.ZERO

var mimic_collision_mask_bit_offset: int = 0

var to_mimic: Node2D

func _ready() -> void:
	mimic()

func _process(delta: float) -> void:
	mimic()

func mimic() -> void:
	if to_mimic:
		for property: String in mimic_properties:
			if property in self:
				match property:
					"collision_mask":
						set(property, to_mimic.get(property) >> mimic_collision_mask_bit_offset)

					"global_position", "position":
						set(property, to_mimic.get(property) + mimic_position_offset)

					"z_index":
						set(property, get_global_z_index(to_mimic))
						z_as_relative = false

					_:
						set(property, to_mimic.get(property))
	else:
		queue_free()

func get_global_z_index(canvas_item: CanvasItem) -> int:
	var global_z_index: int = canvas_item.z_index
	var parent: Node = canvas_item.get_parent()

	while parent is CanvasItem:
		global_z_index += parent.z_index

		if parent.z_as_relative:
			parent = parent.get_parent()
		else:
			return global_z_index

	return global_z_index
