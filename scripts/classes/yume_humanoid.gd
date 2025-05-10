# Copyright (C) 2025 boot <bootovy@proton.me> and contributors.

# This file is part of Libre Nikki.

# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

class_name YumeHumanoid
extends YumeCharacter

## A character that resembles a human.

enum { STEP_LEFT = 0, STEP_RIGHT = 1 }

## [AnimationPlayer] for this character.
@export var animation_player: AnimationPlayer

## Direction the character is facing.
@export var facing: Game.DIRECTION = 1:
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

## Face this 'direction'.
func face(direction: Game.DIRECTION) -> void:
	facing = direction

## Look this 'direction'.
func look(direction: Game.DIRECTION) -> void:
	set_animation(str(Game.DIRECTION.find_key(facing)).to_lower() + action + "Look" + str(Game.DIRECTION.find_key(direction)).capitalize())

## 'face()' and 'move()' functions combined.
func face_and_move(direction: Game.DIRECTION) -> void:
	face(direction)
	move(direction)

## Get a footstep sound based on a tile.
func get_tile_footstep_sound(tile_data: TileData) -> AudioStream:
	if tile_data:
		match tile_data.get_custom_data("surface"):
			Game.SURFACE.SILENT:
				return
			_:
				return Game.world.default_footstep_sound
			# SURFACE.CONCRETE:
			# SURFACE.METAL:
			# SURFACE.GRASS:
			# SURFACE.DIRT:
			# SURFACE.SAND:
			# SURFACE.WATER:
			# SURFACE.SNOW:
			# SURFACE.WOOD:
			# SURFACE.CARPET:
	else:
		return Game.world.default_footstep_sound

## If there are no colliding objects on the same Z index as the character, move this 'direction' (diagonally, if on stairs and 'can_move_on_stairs' is true) by one tile. Otherwise, trigger 'body_touched()' signal in the colliding YumeInteractable's script.
func move(direction: Game.DIRECTION) -> void:
	set_pointer(direction)
	target = Game.DIRECTIONS[direction] * Game.world.tile_size

	for body: Node2D in current_pointer.surfaces:
		if body.global_position == current_pointer.global_position and body is YumeInteractable:
			body.body_stepped_on.emit(self)

		if body is TileMapLayer:
			var current_tile = body.local_to_map(current_pointer.global_position)
			var tile_data = body.get_cell_tile_data(current_tile)

			if can_use_stairs:
				target = get_tile_stair_target_corrections(tile_data, target, direction)

	if is_colliding(direction):
		return

	# var collision_shapes: Array[CollisionShape2D]

	# for shape_owner: int in get_shape_owners():
		# collision_shapes.append(shape_owner_get_owner(shape_owner))

	# for collision_shape: CollisionShape2D in collision_shapes:
		# if Game.world:
			# collision_shape.position = Game.world.wrap_around_world(collision_shape.global_position + target)
		# else:
			# collision_shape.position += collision_shape.global_position + target
		# collision_shape.top_level = true

	for pointer: YumePointer in pointers.get_children():
		if Game.world:
			pointer.position = Game.world.wrap_around_world(pointer.global_position + target)
		else:
			pointer.position += pointer.global_position + target
		pointer.top_level = true

	is_busy = true
	is_moving = true

	set_footstep_sound()

	if last_step:
		set_animation(str(Game.DIRECTION.find_key(facing)).to_lower() + action, speed, 0.125)
	else:
		set_animation(str(Game.DIRECTION.find_key(facing)).to_lower() + action + "2", speed, 0.125)

	last_step = !last_step
	var tween: Tween = create_tween()
	tween.tween_property(self, "pixel_position", Vector2i(target), 0.25 / speed).as_relative()
	await tween.finished

	# for collision_shape: CollisionShape2D in collision_shapes:
		# collision_shape.position = Vector2.ZERO
		# collision_shape.top_level = false

	#for pointer: YumePointer in pointers.get_children():
		#pointer.position = pointer.offset * Game.world.tile_size
		#pointer.top_level = false

	is_busy = false
	is_moving = false
	moved.emit()

func play_footstep_sound() -> void:
	Game.play_sound(footstep_sound, self, 256, RandomNumberGenerator.new().randf_range(0.90, 1.10))

func set_footstep_sound() -> void:
	for body: Node2D in current_pointer.surfaces:
		if body is TileMapLayer:
			var current_tile = body.local_to_map(current_pointer.global_position)
			var tile_data = body.get_cell_tile_data(current_tile)
			footstep_sound = get_tile_footstep_sound(tile_data)
			return

	footstep_sound = Game.world.default_footstep_sound

func set_animation(animation: String = str(Game.DIRECTION.find_key(facing)).to_lower() + action, animation_speed: float = 0.0, animation_position: float = 0.0, from_end: bool = false) -> void:
	if animation_player.get_animation_library("").has_animation(animation):
		animation_player.play(animation, -1, animation_speed, from_end)
		animation_player.seek(animation_position, true)
