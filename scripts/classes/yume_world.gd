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

class_name YumeWorld
extends Node2D

@export var pretty_name: String

## Indicates the playable area of the world. Can be left empty for infinite
## worlds.
@export var bounds: Rect2:
	set(value):
		if is_node_ready():
			_recursive_call(self, _on_child_exiting_tree)

		if not value.has_area():
			loop = "None"

		bounds = value
		_update_duplicate_positions()
		_recursive_call(self, _on_child_entered_tree)

## Indicates if the world should loop.
@export_enum("All Sides", "Horizontally", "Vertically", "None") var loop: String = "None":
	set(value):
		if is_node_ready():
			_recursive_call(self, _on_child_exiting_tree)

		if bounds.has_area():
			loop = value
		else:
			loop = "None"

		_update_duplicate_positions()
		_recursive_call(self, _on_child_entered_tree)

## The distance between this world and the Nexus measured in the amount of
## worlds required to visit. Optionally, value in brackets is the distance with
## the unlocked shortcut (if exists).
@export var depth: String = "1"

## If there are no tiles on the surface, [YumeHumanoid]s will use this sound for
## footsteps.
@export var default_footstep_sound: AudioStream = preload("res://sounds/あるく1.wav") # placeholder

@export var default_mimic_data: Dictionary[String, Array] = {
	"AnimatedSprite2D": ["animation", "frame", "global_position", "sprite_frames", "visible", "z_index"],
	"AudioStreamPlayer2D": ["global_position"],
	"TileMapLayer": []
}

## True, if this is a dream world.
@export var dreaming: bool = true

## Size of a single tile (in pixels). Used for character movement.
@export var tile_size: int = 16

## Positions for node duplicates. Used only for looping worlds.
var duplicate_positions: Array[Vector2] = []

## Limits for the player character's camera. The camera will stop moving after
## the limit is reached.
var camera_limits: Array[int] = []

var parallaxes: Array[Parallax2D] = []

func _recursive_call(node: Node, method: Callable):
	for child: Node in node.get_children():
		if child is not YumeWorld:
			method.call(child)
			_recursive_call(child, method)

func _update_duplicate_positions() -> void:
	match loop:
		"All Sides":
			camera_limits = []
			duplicate_positions = [Vector2(0, bounds.size.y), Vector2(0, -bounds.size.y), Vector2(bounds.size.x, 0), Vector2(-bounds.size.x, 0), Vector2(bounds.size.x, bounds.size.y), Vector2(bounds.size.x, -bounds.size.y), Vector2(-bounds.size.x, bounds.size.y), Vector2(-bounds.size.x, -bounds.size.y)]

		"Horizontally":
			camera_limits = [-10000000, bounds.end.y, bounds.position.y, 10000000]
			duplicate_positions = [Vector2(bounds.size.x, 0), Vector2(-bounds.size.x, 0)]

		"Vertically":
			camera_limits = [bounds.position.x, 10000000, -10000000, bounds.end.x]
			duplicate_positions = [Vector2(0, bounds.size.y), Vector2(0, -bounds.size.y)]

		"None":
			camera_limits = [bounds.position.x, bounds.end.y, bounds.position.y, bounds.end.x]
			duplicate_positions = []

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			connect("child_entered_tree", _on_child_entered_tree)
			connect("child_exiting_tree", _on_child_exiting_tree)

			if loop == "None":
				loop = loop

			_recursive_call(self, _on_child_entered_tree)

func _on_child_entered_tree(node: Node):
	if not node.is_connected("child_entered_tree", _on_child_entered_tree):
		node.connect("child_entered_tree", _on_child_entered_tree)

	if not node.is_connected("child_exiting_tree", _on_child_exiting_tree):
		node.connect("child_exiting_tree", _on_child_exiting_tree)

	if not node.is_in_group("Duplicate"):
		var node_class: String = node.get_class()

		match node_class:
			"Camera2D":
				if camera_limits.is_empty():
					node.limit_enabled = false
				else:
					node.limit_enabled = true
					node.limit_left = floor(camera_limits[0] - node.offset.x)
					node.limit_bottom = floor(camera_limits[1] - node.offset.y)
					node.limit_top = floor(camera_limits[2] - node.offset.y)
					node.limit_right = floor(camera_limits[3] - node.offset.x)

			"Parallax2D":
				parallaxes.append(node)

			"TileMapLayer":
				var tile_set: TileSet = node.tile_set

				if tile_set:
					for index: int in tile_set.get_source_count():
						var source_id: int = tile_set.get_source_id(index)
						var source: TileSetSource = tile_set.get_source(source_id)

						if source is TileSetScenesCollectionSource:
							for cell: Vector2i in node.get_used_cells_by_id(source_id):
								var alt_id: int = node.get_cell_alternative_tile(cell)
								var instance: Node = source.get_scene_tile_scene(alt_id).instantiate()
								instance.position = node.map_to_local(cell)
								node.add_child.call_deferred(instance)
								instance.set_owner.call_deferred(self)

							tile_set.remove_source(source_id)

		if loop == "None":
			return

		if not node.has_meta("mimic_properties") and not default_mimic_data.has(node_class):
			return

		var mimic_properties: Variant = node.get_meta("mimic_properties", [])

		if mimic_properties is not Array:
			mimic_properties = []

		if mimic_properties.is_empty():
			mimic_properties = default_mimic_data.get(node_class, [])

		for property: Variant in mimic_properties:
			if property is not String:
				mimic_properties.erase(property)

		var template: Node = node.duplicate(0)
		template.add_to_group("Duplicate")

		for child: Node in template.get_children():
			child.free()

		for duplicate_position: Vector2 in duplicate_positions:
			var instance: Node = template.duplicate(2)
			instance.global_position += duplicate_position

			if not mimic_properties.is_empty():
				instance.set_script(preload("res://scripts/templates/Node2D/mimic.gd"))
				instance.mimic_properties.append_array(mimic_properties)
				instance.mimic_position_offset += duplicate_position
				instance.to_mimic = node

			node.get_parent().add_child.call_deferred(instance)

func _on_child_exiting_tree(node: Node):
	if node.is_connected("child_entered_tree", _on_child_entered_tree):
		node.disconnect("child_entered_tree", _on_child_entered_tree)

	if node.is_connected("child_exiting_tree", _on_child_exiting_tree):
		node.disconnect("child_exiting_tree", _on_child_exiting_tree)

	if node.is_in_group("Duplicate"):
		node.queue_free()

	if node is Parallax2D:
		if parallaxes.has(node):
			parallaxes.erase(node)

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
