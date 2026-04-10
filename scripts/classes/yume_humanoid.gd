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

class_name YumeHumanoid
extends YumeCharacter

## A character that resembles a human.

enum { STEP_LEFT = 0, STEP_RIGHT = 1 }

## Direction the character is facing.
@export var facing: DIRECTION = DIRECTION.DOWN:
	set(value):
		facing = value
		_force_animation_update()

## True, if the character is sitting.
@export var is_sitting: bool = false

var footstep_sound: AudioStream

var last_step: int = STEP_LEFT

func _force_animation_update() -> void:
	pass

func _move() -> void:
	footstep_sound = (current_world.default_footstep_sound if current_world
			else load("res://sounds/あるく1.wav")) # placeholder

	var ground: Object = surface_detector.get_collider()

	if ground is TileMapLayer:
		var current_tile: Vector2i = (ground.local_to_map(
			current_world.wrap_around_world(surface_detector.global_position +
			surface_detector.target_position)) if current_world else
			ground.local_to_map(surface_detector.global_position +
			surface_detector.target_position))

		var tile_data: TileData = ground.get_cell_tile_data(current_tile)
		footstep_sound = get_tile_footstep_sound(tile_data)

	elif ground is YumeInteractable:
		footstep_sound = get_footstep_sound(ground.surface)

	last_step = !last_step

	await super()

func get_footstep_sound(ground: SURFACE) -> AudioStream:
	match ground:
		SURFACE.SILENT:
			return
		#SURFACE.CONCRETE:
		#SURFACE.METAL:
		#SURFACE.GRASS:
		#SURFACE.DIRT:
		#SURFACE.SAND:
		#SURFACE.WATER:
		#SURFACE.SNOW:
		#SURFACE.WOOD:
		#SURFACE.CARPET:

	if current_world:
		if current_world.default_footstep_sound:
			return current_world.default_footstep_sound

	return load("res://sounds/あるく1.wav") # placeholder

## Get a footstep sound based on a tile.
func get_tile_footstep_sound(tile_data: TileData) -> AudioStream:
	if tile_data:
		if tile_data.has_custom_data("surface"):
			return get_footstep_sound(tile_data.get_custom_data("surface") as YumeInteractable.SURFACE)

	if current_world:
		if current_world.default_footstep_sound:
			return current_world.default_footstep_sound

	return load("res://sounds/あるく1.wav") # placeholder

func play_footstep_sound() -> void:
	play_sound(footstep_sound, 256.0, randf_range(0.90, 1.10))
