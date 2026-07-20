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
@export var facing: Direction = Direction.DOWN:
	set(value):
		facing = value
		_force_animation_update()

## True, if the character is sitting.
@export var is_sitting: bool = false

var footstep_sound: AudioStream

var last_step: int = STEP_LEFT

func _force_animation_update() -> void:
	pass


func _move(motion: Vector2, ground_result: Dictionary) -> void:
	footstep_sound = (current_world.default_footstep_sound if current_world
			else load("res://resources/sounds/step.wav"))

	if ground_result:
		var ground: Object = ground_result.collider

		if ground is TileMapLayer:
			var current_tile: Vector2i = ground.local_to_map(
					ground_result.position)

			var tile_data: TileData = ground.get_cell_tile_data(current_tile)
			footstep_sound = get_tile_footstep_sound(tile_data)

		elif ground is YumeInteractable:
			footstep_sound = get_footstep_sound(ground.surface)

	last_step = !last_step

	await super(motion, ground_result)

func get_footstep_sound(ground: Surface) -> AudioStream:
	match ground:
		Surface.SILENT:
			return
		#Surface.CONCRETE:
		#Surface.METAL:
		#Surface.GRASS:
		#Surface.DIRT:
		#Surface.SAND:
		#Surface.WATER:
		#Surface.SNOW:
		#Surface.WOOD:
		#Surface.CARPET:

	if current_world:
		if current_world.default_footstep_sound:
			return current_world.default_footstep_sound

	return load("res://resources/sounds/step.wav")

## Get a footstep sound based on a tile.
func get_tile_footstep_sound(tile_data: TileData) -> AudioStream:
	if tile_data:
		if tile_data.has_custom_data("surface"):
			return get_footstep_sound(tile_data.get_custom_data("surface")
					as Surface)

	if current_world:
		if current_world.default_footstep_sound:
			return current_world.default_footstep_sound

	return load("res://resources/sounds/step.wav")

func play_footstep_sound() -> void:
	play_sound(footstep_sound, 256.0, randf_range(0.90, 1.10))
