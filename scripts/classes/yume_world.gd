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

class_name YumeWorld
extends Node2D

@export var pretty_name: String

## Indicates the playable area of the world. Can be left empty for infinite
## worlds.
@export var bounds: Rect2

## Indicates if the world should loop.
@export_enum("All Sides", "Horizontally", "Vertically", "None") var loop: String = "None":
	set(value):
		if bounds.has_area():
			match value:
				"All Sides":
					camera_limits = [-2147483647.0, 2147483647.0, -2147483647.0, 2147483647.0]
					duplicate_positions = [Vector2(0, bounds.size.y), Vector2(0, -bounds.size.y), Vector2(bounds.size.x, 0), Vector2(-bounds.size.x, 0), Vector2(bounds.size.x, bounds.size.y), Vector2(bounds.size.x, -bounds.size.y), Vector2(-bounds.size.x, bounds.size.y), Vector2(-bounds.size.x, -bounds.size.y)]

				"Horizontally":
					camera_limits = [-2147483647.0, bounds.end.y, bounds.position.y, 2147483647.0]
					duplicate_positions = [Vector2(bounds.size.x, 0), Vector2(-bounds.size.x, 0)]

				"Vertically":
					camera_limits = [bounds.position.x, 2147483647.0, -2147483647.0, bounds.end.x]
					duplicate_positions = [Vector2(0, bounds.size.y), Vector2(0, -bounds.size.y)]

				"None":
					camera_limits = [bounds.position.x, bounds.end.y, bounds.position.y, bounds.end.x]

			loop = value

		else:
			loop = "None"

## The distance between this world and the Nexus measured in the amount of
## worlds required to visit. Optionally, value in brackets is the distance with
## the unlocked shortcut (if exists).
@export var depth: String = "1"

## If there are no tiles on the surface, [YumeHumanoid]s will use this sound for
## footsteps.
@export var default_footstep_sound: AudioStream = preload("res://sounds/あるく1.wav") # placeholder

## True, if this is a dream world.
@export var dreaming: bool = true

## Size of a single tile (in pixels). Used for character movement.
@export var tile_size: int = 16

## Positions for node duplicates. Used only for looping worlds.
var duplicate_positions: Array[Vector2] = []

## Limits for the player character's camera. The camera will stop moving after
## the limit is reached.
var camera_limits: Array[float] = []

func _initialize_node(node: Node):
	for child: Node in node.get_children():
		if child is not YumeWorld:
			if not child.is_connected("child_entered_tree", _on_child_entered_tree):
				child.connect("child_entered_tree", _on_child_entered_tree)

			_on_child_entered_tree(child)
			_initialize_node(child)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			connect("child_entered_tree", _on_child_entered_tree)

			if not Game.persistent_data.has("world_visits"):
				Game.persistent_data["world_visits"] = {}

			if Game.persistent_data["world_visits"].get(name):
				Game.persistent_data["world_visits"][name] += 1
			else:
				Game.persistent_data["world_visits"][name] = 1

			if loop == "None":
				loop = loop

			_initialize_node(self)

func _on_child_entered_tree(node: Node):
	if not node.is_in_group("Duplicate"):
		match node.get_class():
			"AnimatedSprite2D":
				for duplicate_position: Vector2 in duplicate_positions:
					var instance: AnimatedSprite2D = node.duplicate()
					var parent: Node = node.get_parent()
					instance.add_to_group("Duplicate")
					instance.set_script(preload("res://scripts/templates/Node2D/mimic.gd"))
					instance.mimic_properties.append_array(["animation", "frame", "sprite_frames"])
					instance.mimic_position_offset += duplicate_position
					instance.to_mimic = node

					if parent:
						parent.add_child.call_deferred(instance)
					else:
						add_child.call_deferred(instance)

			"AudioStreamPlayer2D":
				for duplicate_position: Vector2 in duplicate_positions:
					var instance: AudioStreamPlayer2D = node.duplicate()
					var parent: Node2D = node.get_parent()
					instance.add_to_group("Duplicate")
					instance.set_script(preload("res://scripts/templates/Node2D/mimic.gd"))
					instance.mimic_position_offset += duplicate_position
					instance.to_mimic = node

					if parent:
						parent.add_child.call_deferred(instance)
					else:
						add_child.call_deferred(instance)

			"Parallax2D":
				node.add_to_group("Parallax")

			"TileMapLayer":
				for duplicate_position: Vector2 in duplicate_positions:
					var instance: TileMapLayer = node.duplicate()
					var parent: Node2D = node.get_parent()
					instance.add_to_group("Duplicate")
					instance.set_script(preload("res://scripts/templates/Node2D/mimic.gd"))

					for source_id: int in instance.tile_set.get_source_count():
						if instance.tile_set.get_source(source_id) is TileSetScenesCollectionSource:
							for cell: Vector2i in instance.get_used_cells_by_id(source_id):
								instance.erase_cell(cell)

					instance.collision_enabled = false
					instance.mimic_position_offset += duplicate_position
					instance.to_mimic = node

					for child: Node in instance.get_children():
						instance.remove_child(child)

					if parent:
						parent.add_child.call_deferred(instance)
					else:
						add_child.call_deferred(instance)

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
