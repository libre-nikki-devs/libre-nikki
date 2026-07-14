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

enum Direction { NULL = 0, LEFT = 1, DOWN = 2, UP = 4, RIGHT = 8 }

const DIRECTIONS: Dictionary[Direction, Vector2] = {
	Direction.NULL: Vector2.ZERO,
	Direction.LEFT: Vector2.LEFT,
	Direction.DOWN: Vector2.DOWN,
	Direction.UP: Vector2.UP,
	Direction.RIGHT: Vector2.RIGHT,
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

## Size of a single tile (in pixels).
@export var tile_size: int = 16

var current_world: YumeWorld = null

## Direction the character is moving.
var moving := Direction.NULL

static var current_collisions: Array[CollisionShape2D] = []

static var collisions_last_checked: int = 0

## Emitted when the character has moved.
signal moved

## Emitted when the character has been wrapped around [member current_world].
signal wrapped(previous_position: Vector2)


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


func _get_current_collider(motion: Vector2) -> YumeCharacter:
	var physics_frames: int = Engine.get_physics_frames()

	if collisions_last_checked == physics_frames:
		for current_collision_shape: CollisionShape2D in current_collisions:
			var current_collision_shape_parent: YumeCharacter = \
					current_collision_shape.get_parent()

			if collision_mask & current_collision_shape_parent.collision_layer \
					and not current_collision_shape.disabled:

				for i: int in get_shape_owners():
					var shape_owner: Object = shape_owner_get_owner(i)

					var target_origin: Vector2 = (
							current_world.wrap_around_world(
							shape_owner.global_transform.origin + \
							motion) - \
							shape_owner.global_transform.origin \
							if current_world else motion
					)

					var current_shape: Shape2D = current_collision_shape.shape
					var target_transform := \
							Transform2D(shape_owner.global_transform)

					target_transform.origin += target_origin

					if not shape_owner_get_shape(i, 0).collide_and_get_contacts(
							target_transform,
							current_shape,
							current_collision_shape.global_transform) \
							.is_empty():

						return current_collision_shape_parent
	else:
		current_collisions.clear()
		collisions_last_checked = physics_frames

	return null


func _move(motion: Vector2, ground_result: Dictionary) -> void:
	var tween: Tween = create_tween()

	tween.tween_method(
			func (value: Vector2) -> void:
				position = value.round()
	, position, position + motion, 0.25 / speed)

	for i: int in get_shape_owners():
		var shape_owner: Object = shape_owner_get_owner(i)
		shape_owner.position += motion

		tween.parallel()

		tween.tween_property(shape_owner, "position",
				-motion, 0.25 / speed).as_relative()

	await tween.finished


func collide_point(motion: Vector2, mask: int = collision_mask) -> Dictionary:
	var parameters := PhysicsPointQueryParameters2D.new()
	parameters.collision_mask = mask
	parameters.exclude = [get_rid()]

	var space_state: PhysicsDirectSpaceState2D = (
			get_world_2d().direct_space_state)

	# Check collisions for each collision shape individually.
	for i: int in get_shape_owners():
		var shape_owner: Object = shape_owner_get_owner(i)

		if current_world:
			parameters.position = (current_world.wrap_around_world(
					shape_owner.global_position + motion))
		else:
			parameters.position = (
					shape_owner.global_position + motion)

		var result: Array[Dictionary] = space_state.intersect_point(
				parameters, 1)

		if result:
			result[0]["position"] = parameters.position
			return result[0]

	return {}


func collide_ray(offset_and_motion: PackedVector2Array,
		mask: int = collision_mask) -> Dictionary:

	var offset: Vector2 = offset_and_motion[0]
	var motion: Vector2 = offset_and_motion[1]
	var parameters := PhysicsRayQueryParameters2D.new()
	parameters.collision_mask = mask
	parameters.exclude = [get_rid()]
	parameters.hit_from_inside = true

	var space_state: PhysicsDirectSpaceState2D = (
			get_world_2d().direct_space_state)

	# Check collisions for each collision shape individually.
	for i: int in get_shape_owners():
		var result: Dictionary = {}
		var shape_owner: Object = shape_owner_get_owner(i)
		var to: Vector2 = shape_owner.global_position + motion
		parameters.from = shape_owner.global_position + offset

		if current_world:
			# Wrap the ray to ensure that `parameters.from` is within bounds.
			parameters.from = current_world.wrap_around_world(parameters.from)
			to = parameters.from + motion - offset

			# Check if ray is intersecting with bounds.
			var intersection: Variant = (
					current_world.intersect_segment_with_bounds(
					parameters.from, to)
			)

			if intersection == null:
				parameters.to = to
				result = space_state.intersect_ray(parameters)

				if result:
					return result

			# If ray is intersecting with bounds, break it down into two parts.
			# First part: within bounds, second part: out of bounds. Then wrap
			# the second part and check for collisions for each part.
			else:
				parameters.to = intersection
				result = space_state.intersect_ray(parameters)

				if result:
					return result

				# Hack for `@GlobalScope.wrap`'s `max` exclusiveness.
				parameters.from = current_world.wrap_around_world(
						intersection + motion) - motion

				parameters.to = current_world.wrap_around_world(to)
				result = space_state.intersect_ray(parameters)

				if result:
					return result

	return {}


func face(what: Vector2) -> Direction:
	var closest: Vector2 = global_position

	if current_world:
		var distance: float = global_position.distance_squared_to(what)

		for duplicate_position: Vector2 in current_world.duplicate_positions:
			var duplicate_distance: float = (global_position +
					duplicate_position).distance_squared_to(what)

			if duplicate_distance < distance:
				distance = duplicate_distance
				closest = global_position + duplicate_position

	var closest_angle: float = closest.angle_to_point(what)

	if closest_angle >= -0.25 * PI and closest_angle <= 0.25 * PI:
		return Direction.RIGHT
	elif closest_angle > 0.25 * PI and closest_angle < 0.75 * PI:
		return Direction.DOWN
	elif closest_angle > -0.75 * PI and closest_angle < -0.25 * PI:
		return Direction.UP
	else:
		return Direction.LEFT


func get_offset_and_motion(direction: Direction) -> PackedVector2Array:
	var offset := Vector2.ZERO
	var motion: Vector2 = DIRECTIONS[direction] * tile_size

	if not can_use_stairs:
		return [offset, motion]

	var result: Dictionary = collide_point(motion, collision_mask >> 1)

	if result:
		var ground: Object = result.collider

		if ground is TileMapLayer:
			var current_tile: Vector2i = ground.local_to_map(result.position)
			var tile_data: TileData = ground.get_cell_tile_data(current_tile)

			if tile_data:
				if tile_data.has_custom_data("stair"):
					match tile_data.get_custom_data("stair"):
						# \-shaped stairs; horizontal movement.
						1, 5 when direction & HORIZONTAL:
							motion.y += motion.x
							offset += Vector2(0.0, motion.x)

						# /-shaped stairs; horizontal movement.
						2, 6 when direction & HORIZONTAL:
							motion.y -= motion.x
							offset += Vector2(0.0, -motion.x)

						# \-shaped stairs; vertical movement.
						3, 5 when direction & VERTICAL:
							motion.x += motion.y
							offset += Vector2(motion.y, 0.0)

						# /-shaped stairs; vertical movement.
						4, 6 when direction & VERTICAL:
							motion.x -= motion.y
							offset += Vector2(-motion.y, 0.0)

	return [offset, motion]


func move(direction: Direction,
		offset_and_motion: PackedVector2Array = get_offset_and_motion(
		direction), respect_collisions: bool = true) -> void:

	var motion: Vector2 = offset_and_motion[1]
	var result: Dictionary = {}

	if respect_collisions:
		result = collide_ray(offset_and_motion, collision_mask)

		if result:
			var collider: Object = result.collider

			if collider is YumeInteractable:
				collider.body_touched.emit(self)

			return

		result = collide_point(motion, collision_mask >> 1)

		if result:
			var ground: Object = result.collider

			if ground is YumeInteractable:
				ground.body_stepped_on.emit.call_deferred(self)

		elif not can_move_in_vacuum:
			return

		var current_collider: YumeCharacter = _get_current_collider(motion)

		if current_collider:
			current_collider.body_touched.emit(self)
			return

	for i: int in get_shape_owners():
		current_collisions.append(shape_owner_get_owner(i))

	wrap_around_world(motion)
	is_busy = true
	moving = direction
	await _move(motion, result)
	is_busy = false
	moving = Direction.NULL
	moved.emit()


func is_colliding(offset_and_motion: PackedVector2Array) -> bool:
	if collide_ray(offset_and_motion):
		return true

	var motion: Vector2 = offset_and_motion[1]

	if not can_move_in_vacuum:
		if collide_point(motion, collision_mask >> 1):
			return true

	if _get_current_collider(motion):
		return true

	return false


func wrap_around_world(motion: Vector2) -> void:
	if current_world:
		var wrapped_position: Vector2 = current_world.wrap_around_world(
				global_position + motion) - motion

		if global_position != wrapped_position:
			var previous_position: Vector2 = global_position
			global_position = wrapped_position
			wrapped.emit(previous_position)

func get_next_direction(direction: Direction) -> Direction:
	match direction:
		Direction.LEFT:
			return Direction.UP
		Direction.DOWN:
			return Direction.LEFT
		Direction.UP:
			return Direction.RIGHT
		Direction.RIGHT:
			return Direction.DOWN

	return direction

func get_opposite_direction(direction: Direction) -> Direction:
	if direction == Direction.NULL:
		return direction
	elif direction & HORIZONTAL:
		return (~direction & ALL) ^ VERTICAL as Direction
	else:
		return (~direction & ALL) ^ HORIZONTAL as Direction
