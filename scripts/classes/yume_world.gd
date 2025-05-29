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
extends Node

@export var pretty_name: String

## Indicates the playable area of the world. Should contain two vectors being coordinates of the world's diagonal. Can be left empty for infinite worlds.
@export var bounds: Array[Vector2] = [Vector2(-256, -256), Vector2(256, 256)]:
	set(value):
		if value.is_empty():
			bounds = value
			return

		if value.size() < 2:
			push_error("\'bounds\' must have two or no elements.")
			return

		if value[0] <= value[1]:
			bounds[0] = value[0]
			bounds[1] = value[1]
		else:
			bounds[0] = value[1]
			bounds[1] = value[0]

## Indicates if the world should loop.
@export_enum("All Sides", "Horizontally", "Vertically", "None") var loop: String = "All Sides":
	set(value):
		if bounds.size() >= 2:
			var size: Vector2 = Vector2(abs(bounds[0].x) + abs(bounds[1].x), abs(bounds[0].y) + abs(bounds[1].y))

			match value:
				"All Sides":
					camera_limits = [-2147483647, 2147483647, -2147483647, 2147483647]
					duplicate_positions = [Vector2(0, size.y), Vector2(0, -size.y), Vector2(size.x, 0), Vector2(-size.x, 0), Vector2(size.x, size.y), Vector2(size.x, -size.y), Vector2(-size.x, size.y), Vector2(-size.x, -size.y)]
					loop = value
				"Horizontally":
					camera_limits = [bounds[0].x, 2147483647, -2147483647, bounds[1].x]
					duplicate_positions = [Vector2(0, size.y), Vector2(0, -size.y)]
					loop = value
				"Vertically":
					camera_limits = [-2147483647, bounds[1].y, bounds[0].y, 2147483647]
					duplicate_positions = [Vector2(size.x, 0), Vector2(-size.x, 0)]
					loop = value
				"None":
					camera_limits = [bounds[0].x, bounds[1].y, bounds[0].y, bounds[1].x]
					loop = value
		else:
			loop = "None"

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

func _init() -> void:
	Game.world = self

func _initialize_node(node: Node):
	for child: Node in node.get_children():
		_on_node_added(child)
		_initialize_node(child)

func _ready() -> void:
	get_tree().connect("node_added", _on_node_added)

	if !Game.persistent_data.has("world_visits"):
		Game.persistent_data["world_visits"] = {}

	if Game.persistent_data["world_visits"].get(name):
		Game.persistent_data["world_visits"][name] += 1
	else:
		Game.persistent_data["world_visits"][name] = 1

	if player:
		if not Game.persistent_data.has("player_data"):
			Game.persistent_data["player_data"] = {}

		for property: String in Game.persistent_data["player_data"].keys():
			player.set(property, Game.persistent_data["player_data"][property])

	if bounds == [Vector2(-256, -256), Vector2(256, 256)]:
		bounds = bounds
	
	if loop == "All Sides":
		loop = loop

	_initialize_node(self)

func _on_node_added(node: Node):
	if not node.is_in_group("Duplicate"):
		match node.get_class():
			"AnimatedSprite2D":
				for position: Vector2 in duplicate_positions:
					var instance: AnimatedSprite2D = node.duplicate()
					instance.add_to_group("Duplicate")
					instance.set_script(preload("res://scripts/templates/AnimatedSprite2D/mimic.gd"))
					instance.global_position += position
					instance.to_mimic = node
					node.add_child.call_deferred(instance)
			"AudioStreamPlayer2D":
				for position: Vector2 in duplicate_positions:
					var instance: AudioStreamPlayer2D = node.duplicate()
					instance.add_to_group("Duplicate")
					instance.global_position += position
					node.add_child.call_deferred(instance)
			"Parallax2D":
				node.add_to_group("Parallax")
			"TileMapLayer":
				for position: Vector2 in duplicate_positions:
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

					instance.global_position += position
					node.add_child.call_deferred(instance)

	# if player:
		# player.get_parent().move_child(player, -1)

## Change the current world to this [param world].
func change_world(world: String, save_current_state: bool = true, player_properties: Array = ["accept_events", "cancel_events", "effect", "facing", "last_step", "speed"]) -> void:
	if save_current_state:
		if !Game.persistent_data.has("world_data"):
			Game.persistent_data["world_data"] = {}

		Game.persistent_data["world_data"][name] = PackedScene.new()
		Game.persistent_data["world_data"][name].pack(self)

	set_player_data(player_properties)

	Game.persistent_data["entered_from"] = name

	if Game.persistent_data.has("world_data"):
		if Game.persistent_data["world_data"].has(world):
			get_tree().change_scene_to_packed(Game.persistent_data["world_data"][world])
			return

	get_tree().change_scene_to_file("res://scenes/maps/" + world.to_snake_case() + ".tscn")

func set_player_data(player_properties: Array = ["effect", "facing", "speed"]):
	if player:
		if not Game.persistent_data.has("player_data"):
			Game.persistent_data["player_data"] = {}

		for property: String in player_properties:
			if property in player:
				Game.persistent_data["player_data"][property] = player.get(property)

func wrap_around_world(value: Vector2) -> Vector2:
	if bounds.size() >= 2:
		match loop:
			"All Sides":
				return Vector2(wrap(value.x, bounds[0].x, bounds[1].x), wrap(value.y, bounds[0].y, bounds[1].y))
			"Horizontally":
				return Vector2(wrap(value.x, bounds[0].x, bounds[1].x), value.y)
			"Vertically":
				return Vector2(value.x , wrap(value.y, bounds[0].y, bounds[1].y))
	return value
