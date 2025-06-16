# Copyright (C) 2025 Libre Nikki Developers.
#
# This file is part of Libre Nikki.
#
# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

class_name YumeHumanoid
extends YumeCharacter

## A character that resembles a human.

enum { STEP_LEFT = 0, STEP_RIGHT = 1 }

enum SURFACE { SILENT = -1, DEFAULT, CONCRETE, METAL, GRASS, DIRT, SAND, WATER, SNOW, WOOD, CARPET }

## [AnimationPlayer] for this character.
@export var animation_player: AnimationPlayer

## Direction the character is facing.
@export var facing: DIRECTION = DIRECTION.DOWN:
	set(value):
		facing = value
		set_animation()

## Indicates the extraordinary character behaviour (eg. ladder climbing).
@export_enum("Default", "Bench", "Ladder", "Sit") var action: String = "Default":
	set(value):
		action = value
		set_animation()
	get:
		if action == "Default":
			return ""
		else:
			return action

## True, if the character is sitting.
@export var is_sitting: bool = false

var footstep_sound: AudioStream

var last_step: int = STEP_LEFT

func _move() -> void:
	var current_scene: Node = get_tree().current_scene
	var surface: Object = surface_detector.get_collider()

	if current_scene is YumeWorld:
		footstep_sound = current_scene.default_footstep_sound
	else:
		footstep_sound = load("res://sounds/あるく1.wav") # placeholder

	if surface:
		if surface is TileMapLayer:
			var current_tile = surface.local_to_map(surface_detector.global_position + surface_detector.target_position)

			if current_scene is YumeWorld:
				current_tile = surface.local_to_map(current_scene.wrap_around_world(surface_detector.global_position + surface_detector.target_position))

			var tile_data = surface.get_cell_tile_data(current_tile)
			footstep_sound = get_tile_footstep_sound(tile_data)

	if last_step:
		set_animation(str(DIRECTION.find_key(facing)).to_lower() + action, speed, 0.125)
	else:
		set_animation(str(DIRECTION.find_key(facing)).to_lower() + action + "2", speed, 0.125)

	last_step = !last_step

## Look this 'direction'.
func look(direction: DIRECTION) -> void:
	set_animation(str(DIRECTION.find_key(facing)).to_lower() + action + "Look" + str(DIRECTION.find_key(direction)).capitalize())

## Get a footstep sound based on a tile.
func get_tile_footstep_sound(tile_data: TileData) -> AudioStream:
	if tile_data:
		if tile_data.has_custom_data("surface"):
			match tile_data.get_custom_data("surface"):
				SURFACE.SILENT:
					return
				# SURFACE.CONCRETE:
				# SURFACE.METAL:
				# SURFACE.GRASS:
				# SURFACE.DIRT:
				# SURFACE.SAND:
				# SURFACE.WATER:
				# SURFACE.SNOW:
				# SURFACE.WOOD:
				# SURFACE.CARPET:

	var current_scene: Node = get_tree().current_scene

	if current_scene is YumeWorld:
		return current_scene.default_footstep_sound
	else:
		return load("res://sounds/あるく1.wav") # placeholder

func play_footstep_sound() -> void:
	Game.play_sound(footstep_sound, self, 256, RandomNumberGenerator.new().randf_range(0.90, 1.10))

func set_animation(animation: String = str(DIRECTION.find_key(facing)).to_lower() + action, animation_speed: float = 0.0, animation_position: float = 0.0, from_end: bool = false) -> void:
	if animation_player.get_animation_library("").has_animation(animation):
		animation_player.play(animation, -1, animation_speed, from_end)
		animation_player.seek(animation_position, true)

# WIP
func face(what: Vector2) -> void:
	if position.x > what.x:
		facing = DIRECTION.LEFT
	elif position.x < what.x:
		facing = DIRECTION.RIGHT

	if position.y > what.y:
		facing = DIRECTION.UP
	else:
		facing = DIRECTION.DOWN
