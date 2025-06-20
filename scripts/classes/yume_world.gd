# Copyright (C) 2025 Libre Nikki Developers.
#
# This file is part of Libre Nikki.
#
# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

class_name YumeWorld
extends Node2D

@export var pretty_name: String

## Indicates the playable area of the world. Can be left empty for infinite worlds.
@export var bounds: Rect2

## Indicates if the world should loop.
@export_enum("All Sides", "Horizontally", "Vertically", "None") var loop: String = "All Sides":
	set(value):
		if bounds.has_area():
			match value:
				"All Sides":
					camera_limits = [-2147483647, 2147483647, -2147483647, 2147483647]
					duplicate_positions = [Vector2(0, bounds.size.y), Vector2(0, -bounds.size.y), Vector2(bounds.size.x, 0), Vector2(-bounds.size.x, 0), Vector2(bounds.size.x, bounds.size.y), Vector2(bounds.size.x, -bounds.size.y), Vector2(-bounds.size.x, bounds.size.y), Vector2(-bounds.size.x, -bounds.size.y)]

				"Horizontally":
					camera_limits = [bounds.position.x, 2147483647, -2147483647, bounds.end.x]
					duplicate_positions = [Vector2(0, bounds.size.y), Vector2(0, -bounds.size.y)]

				"Vertically":
					camera_limits = [-2147483647, bounds.end.y, bounds.position.y, 2147483647]
					duplicate_positions = [Vector2(bounds.size.x, 0), Vector2(-bounds.size.x, 0)]

				"None":
					camera_limits = [bounds.position.x, bounds.end.y, bounds.position.y, bounds.end.x]

			return(value)

		else:
			return("None")

## Node of the player character.[br][b]Note:[/b] More than one player character is not supported.
@export var player: YumePlayer

## The distance between this world and the Nexus measured in the amount of worlds required to visit. Optionally, value in brackets is the distance with the unlocked shortcut (if exists).
@export var depth: String = "1"

## If there are no tiles on the surface, [YumeHumanoid]s will use this sound for footsteps.
@export var default_footstep_sound: AudioStream = preload("res://sounds/あるく1.wav") # placeholder

## True, if this is a dream world.
@export var dreaming: bool = true

## Size of a single tile (in pixels). Used for character movement.
@export var tile_size: int = 16

## Positions for node duplicates. Used only for looping worlds.
var duplicate_positions: Array[Vector2] = []

## Limits for the player character's camera. The camera will stop moving, if the limit is reached. By default, they are set to the lowest and the highest values in the following order: left, bottom, top, right.
var camera_limits: Array[float] = [-2147483647, 2147483647, -2147483647, 2147483647]:
	set(value):
		camera_limits = value

		if player:
			if player.camera:
				player.camera.limit_left = floor(camera_limits[0] - player.camera.offset.x)
				player.camera.limit_bottom = floor(camera_limits[1] - player.camera.offset.y)
				player.camera.limit_top = floor(camera_limits[2] - player.camera.offset.y)
				player.camera.limit_right = floor(camera_limits[3] - player.camera.offset.x)

func _initialize_node(node: Node):
	for child: Node in node.get_children():
		_on_node_added(child)
		_initialize_node(child)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			get_tree().connect("node_added", _on_node_added)

			if not Game.persistent_data.has("world_visits"):
				Game.persistent_data["world_visits"] = {}

			if Game.persistent_data["world_visits"].get(name):
				Game.persistent_data["world_visits"][name] += 1
			else:
				Game.persistent_data["world_visits"][name] = 1

			if loop == "All Sides":
				loop = loop

			_initialize_node(self)

func _on_node_added(node: Node):
	if not node.is_in_group("Duplicate"):
		match node.get_class():
			"AnimatedSprite2D":
				for duplicate_position: Vector2 in duplicate_positions:
					var instance: AnimatedSprite2D = node.duplicate()
					instance.add_to_group("Duplicate")
					instance.set_script(preload("res://scripts/templates/AnimatedSprite2D/mimic.gd"))
					instance.global_position += duplicate_position
					instance.to_mimic = node
					node.add_child.call_deferred(instance)
			"AudioStreamPlayer2D":
				for duplicate_position: Vector2 in duplicate_positions:
					var instance: AudioStreamPlayer2D = node.duplicate()
					instance.add_to_group("Duplicate")
					instance.global_position += duplicate_position
					node.add_child.call_deferred(instance)
			"Parallax2D":
				node.add_to_group("Parallax")
			"TileMapLayer":
				for duplicate_position: Vector2 in duplicate_positions:
					var instance: TileMapLayer = node.duplicate()
					instance.add_to_group("Duplicate")

					for source_id: int in instance.tile_set.get_source_count():
						if instance.tile_set.get_source(source_id) is TileSetScenesCollectionSource:
							for cell: Vector2i in instance.get_used_cells_by_id(source_id):
								instance.erase_cell(cell)

					instance.collision_enabled = false
					instance.z_as_relative = false

					for child: Node in instance.get_children():
						instance.remove_child(child)

					instance.global_position += duplicate_position
					node.add_child.call_deferred(instance)

	# if player:
		# player.get_parent().move_child(player, -1)

func wrap_around_world(value: Vector2) -> Vector2:
	if bounds.has_area():
		match loop:
			"All Sides":
				return Vector2(wrap(value.x, bounds.position.x, bounds.end.x), wrap(value.y, bounds.position.y, bounds.end.y))

			"Horizontally":
				return Vector2(wrap(value.x, bounds.position.x, bounds.end.x), value.y)

			"Vertically":
				return Vector2(value.x, wrap(value.y, bounds.position.y, bounds.end.y))

	return value
