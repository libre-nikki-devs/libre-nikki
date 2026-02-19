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

class_name YumeCharacter
extends YumeInteractable

## A simple moving character.

enum { ALL = 15, HORIZONTAL = 9, VERTICAL = 6 }

enum DIRECTION { LEFT = 1, DOWN = 2, UP = 4, RIGHT = 8 }

const DIRECTIONS: Dictionary[DIRECTION, Vector2] = {
	DIRECTION.LEFT: Vector2.LEFT,
	DIRECTION.DOWN: Vector2.DOWN,
	DIRECTION.UP: Vector2.UP,
	DIRECTION.RIGHT: Vector2.RIGHT,
}

## If true, prevent the character from performing certain actions.
## For [YumePlayer]s, useful for scripted sequences where the player interaction
## is forbidden.[br][b]Warning:[/b] might cause softlocks when used incorrectly;
## make sure to set it to false once the sequence is done.
@export var is_busy: bool = false

@export_group("Movement")

## Character's movement speed.
@export_range(0, 10) var speed: float = 1.0

## If true, the character is able to move if there are no surfaces below.
@export var can_move_in_vacuum: bool = true

## If true, the character will move diagonally on stairs.
@export var can_use_stairs: bool = true

var current_world: YumeWorld = null

## True, if the character is moving.
var is_moving: bool = false

## Target movement point.
var target_position: Vector2

var surface_detector: RayCast2D = RayCast2D.new()

var collision_detector: RayCast2D = RayCast2D.new()

static var current_collisions: Array[CollisionShape2D] = []

static var collisions_last_checked: int = 0

## Emitted when the character has moved.
signal moved

## Emitted when the character has been wrapped around [member current_world].
signal wrapped(previous_position: Vector2)

func _init() -> void:
	collision_detector.name = "CollisionDetector"
	collision_detector.enabled = false
	collision_detector.light_mask = 0
	collision_detector.visibility_layer = 0
	collision_detector.set_script(preload("res://scripts/templates/Node2D/mimic.gd"))
	collision_detector.mimic_properties.append("collision_mask")
	collision_detector.to_mimic = self
	surface_detector.name = "SurfaceDetector"
	surface_detector.enabled = false
	surface_detector.light_mask = 0
	surface_detector.visibility_layer = 0
	surface_detector.set_script(preload("res://scripts/templates/Node2D/mimic.gd"))
	surface_detector.mimic_properties.append("collision_mask")
	surface_detector.mimic_collision_mask_bit_offset = 1
	surface_detector.to_mimic = self
	add_child(collision_detector)
	add_child(surface_detector)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			current_world = null
			var node: Node = self

			while true:
				var parent: Node = node.get_parent()
				node = parent

				if not parent:
					return

				if parent is YumeWorld:
					current_world = parent
					return

func _move() -> void:
	pass

func _update_detectors(direction: DIRECTION) -> void:
	if current_world:
		target_position = DIRECTIONS[direction] * current_world.tile_size
		collision_detector.global_position = current_world.wrap_around_world(global_position + target_position) - target_position
	else:
		target_position = DIRECTIONS[direction] * 16.0
		collision_detector.global_position = global_position

	collision_detector.target_position = target_position
	collision_detector.force_raycast_update()
	surface_detector.global_position = collision_detector.global_position
	surface_detector.target_position = target_position
	surface_detector.force_raycast_update()
	var ground: Object = surface_detector.get_collider()

	if ground and can_use_stairs:
		if ground is TileMapLayer:
			var current_tile: Vector2i = ground.local_to_map(global_position + target_position)

			if current_world:
				current_tile = ground.local_to_map(current_world.wrap_around_world(global_position + target_position))

			var tile_data: TileData = ground.get_cell_tile_data(current_tile)

			if tile_data:
				if tile_data.has_custom_data("stair"):
					match tile_data.get_custom_data("stair"):
						# \-shaped stairs; horizontal movement.
						1, 5 when direction & HORIZONTAL:
							target_position += Vector2(0.0, target_position.x)
							_update_detector_positions(Vector2(0.0, target_position.x))

						# /-shaped stairs; horizontal movement.
						2, 6 when direction & HORIZONTAL:
							target_position -= Vector2(0.0, target_position.x)
							_update_detector_positions(-Vector2(0.0, target_position.x))

						# \-shaped stairs; vertical movement.
						3, 5 when direction & VERTICAL:
							target_position += Vector2(target_position.y, 0.0)
							_update_detector_positions(Vector2(target_position.y, 0.0))

						# /-shaped stairs; vertical movement.
						4, 6 when direction & VERTICAL:
							target_position -= Vector2(target_position.y, 0.0)
							_update_detector_positions(-Vector2(target_position.y, 0.0))

			collision_detector.force_raycast_update()
			surface_detector.force_raycast_update()

func _update_detector_positions(target_vector: Vector2) -> void:
	if current_world:
		collision_detector.global_position = current_world.wrap_around_world(global_position + target_position + target_vector) - target_position
	else:
		collision_detector.global_position = global_position + target_vector

	surface_detector.global_position = collision_detector.global_position

func move(direction: DIRECTION) -> void:
	_update_detectors(direction)
	var collider: Object = collision_detector.get_collider()

	if collider:
		if collider is YumeInteractable:
			collider.emit_signal("body_touched", self)

		return

	var ground: Object = surface_detector.get_collider()

	if ground:
		if ground is YumeInteractable:
			ground.emit_signal("body_stepped_on", self)

	elif not can_move_in_vacuum:
		return

	var collision_shapes: Array[CollisionShape2D]

	for shape_owner: int in get_shape_owners():
		collision_shapes.append(shape_owner_get_owner(shape_owner))

	var physics_frames: int = Engine.get_physics_frames()

	if collisions_last_checked == physics_frames:
		for current_collision_shape: CollisionShape2D in current_collisions:
			var current_collision_shape_parent: YumeCharacter = current_collision_shape.get_parent()

			if collision_mask & current_collision_shape_parent.collision_layer and not current_collision_shape.disabled:
				for collision_shape: CollisionShape2D in collision_shapes:
					var target_origin: Vector2 = target_position

					if current_world:
						target_origin = current_world.wrap_around_world(collision_shape.global_transform.origin + target_origin) - collision_shape.global_transform.origin

					var shape: Shape2D = collision_shape.shape
					var current_shape: Shape2D = current_collision_shape.shape
					var target_transform := Transform2D(collision_shape.global_transform)
					target_transform.origin += target_origin

					if not shape.collide_and_get_contacts(target_transform, current_shape, current_collision_shape.global_transform).is_empty():
						current_collision_shape_parent.emit_signal("body_touched", self)
						return
	else:
		current_collisions.clear()
		collisions_last_checked = physics_frames

	for collision_shape: CollisionShape2D in collision_shapes:
		current_collisions.append(collision_shape)

	if current_world:
		var wrapped_position: Vector2 = current_world.wrap_around_world(global_position + target_position) - target_position

		if global_position != wrapped_position:
			var previous_position: Vector2 = global_position
			global_position = wrapped_position
			wrapped.emit(previous_position)

	is_busy = true
	is_moving = true
	_move()
	var tween: Tween = create_tween()
	tween.tween_property(self, "pixel_position", Vector2i(target_position), 0.25 / speed).as_relative()

	for collision_shape: CollisionShape2D in collision_shapes:
		collision_shape.position += target_position
		tween.parallel()
		tween.tween_property(collision_shape, "position", -target_position, 0.25 / speed).as_relative()

	await tween.finished
	is_busy = false
	is_moving = false
	moved.emit()

func is_colliding(direction: DIRECTION) -> bool:
	_update_detectors(direction)

	if collision_detector.is_colliding():
		return true

	if not (surface_detector.is_colliding() or can_move_in_vacuum):
		return true

	var collision_shapes: Array[CollisionShape2D]

	for shape_owner: int in get_shape_owners():
		collision_shapes.append(shape_owner_get_owner(shape_owner))

	var physics_frames: int = Engine.get_physics_frames()

	if collisions_last_checked == physics_frames:
		for current_collision_shape: CollisionShape2D in current_collisions:
			var current_collision_shape_parent: YumeCharacter = current_collision_shape.get_parent()

			if collision_mask & current_collision_shape_parent.collision_layer and not current_collision_shape.disabled:
				for collision_shape: CollisionShape2D in collision_shapes:
					var target_origin: Vector2 = target_position

					if current_world:
						target_origin = current_world.wrap_around_world(collision_shape.global_transform.origin + target_origin) - collision_shape.global_transform.origin

					var shape: Shape2D = collision_shape.shape
					var current_shape: Shape2D = current_collision_shape.shape
					var target_transform := Transform2D(collision_shape.global_transform)
					target_transform.origin += target_origin

					if not shape.collide_and_get_contacts(target_transform, current_shape, current_collision_shape.global_transform).is_empty():
						return true
	else:
		current_collisions.clear()
		collisions_last_checked = physics_frames

	return false

func get_opposite_direction(direction: DIRECTION) -> DIRECTION:
	if direction & HORIZONTAL:
		return (~direction & ALL) ^ VERTICAL as DIRECTION
	else:
		return (~direction & ALL) ^ HORIZONTAL as DIRECTION
