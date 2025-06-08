# Copyright (C) 2025 Libre Nikki Developers.
#
# This file is part of Libre Nikki.
#
# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

class_name YumePointer
extends Area2D

@export var offset: Vector2
@export var collision_owner: Node2D
var collisions: Array[Node2D]
var surfaces: Array[Node2D]

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			body_shape_entered.connect(_on_pointer_body_shape_entered)
			body_shape_exited.connect(_on_pointer_body_shape_exited)

func _on_pointer_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	var additional_z_index: int = 0

	if body is TileMapLayer:
		var current_tile = body.local_to_map(global_position)
		if body.get_cell_tile_data(current_tile):
			additional_z_index = body.get_cell_tile_data(current_tile).z_index

	if body != collision_owner:
		match Game.get_global_z_index(collision_owner) - (Game.get_global_z_index(body) + additional_z_index):
			0:
				collisions.append(body)
			1:
				surfaces.append(body)

func _on_pointer_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	collisions.erase(body)
	surfaces.erase(body)
