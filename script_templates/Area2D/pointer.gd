# Copyright (C) 2025 boot <bootovy@proton.me> and contributors.

# This file is part of Libre Nikki.

# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

extends Area2D

## Indicates what objects are colliding with the pointer.
var colliding_objects: Array[Node2D] = []

## Indicates what objects are on the surface level of the pointer.
var stepped_on_objects: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_area_2d_body_entered)
	body_exited.connect(_on_area_2d_body_exited)

func _on_area_2d_body_entered(body: Node2D) -> void:
	var additional_z_index: int = 0
	if body is TileMapLayer:
		var current_tile = body.local_to_map(global_position)
		if body.get_cell_tile_data(current_tile):
			additional_z_index = body.get_cell_tile_data(current_tile).z_index

	if body != get_parent():
		match Game.get_global_z_index(get_parent()) - (Game.get_global_z_index(body) + additional_z_index):
			0:
				colliding_objects.append(body)
			1:
				stepped_on_objects.append(body)

func _on_area_2d_body_exited(body: Node2D) -> void:
	colliding_objects.erase(body)
	stepped_on_objects.erase(body)
