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
@export_range(0, 10, 0.5) var speed: float = 1.0

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

## Emitted when the character has moved.
signal moved

func _init() -> void:
	collision_detector.name = "CollisionDetector"
	collision_detector.enabled = false
	collision_detector.light_mask = 0
	collision_detector.visibility_layer = 0
	surface_detector.name = "SurfaceDetector"
	surface_detector.enabled = false
	surface_detector.light_mask = 0
	surface_detector.visibility_layer = 0
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

		NOTIFICATION_READY:
			collision_detector.collision_mask = collision_mask
			surface_detector.collision_mask = collision_mask - 1

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
			var current_tile: Vector2i = ground.local_to_map(surface_detector.global_position + surface_detector.target_position)

			if current_world:
				current_tile = ground.local_to_map(current_world.wrap_around_world(surface_detector.global_position + surface_detector.target_position))

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
	var ground: Object = surface_detector.get_collider()

	if collider:
		if collider is YumeInteractable:
			collider.emit_signal("body_touched", self)

		return

	if ground:
		if ground is YumeInteractable:
			ground.emit_signal("body_stepped_on", self)

	elif not can_move_in_vacuum:
		return

	if current_world:
		var previous_position: Vector2 = global_position
		global_position = current_world.wrap_around_world(global_position + target_position) - target_position

		if self == get_viewport().get_camera_2d().get_parent():
			for parallax: Parallax2D in get_tree().get_nodes_in_group("Parallax"):
				parallax.scroll_offset -= previous_position - global_position

	is_busy = true
	is_moving = true
	_move()
	var tween: Tween = create_tween()
	tween.tween_property(self, "pixel_position", Vector2i(target_position), 0.25 / speed).as_relative()
	var collision_shapes: Array[CollisionShape2D]

	for shape_owner: int in get_shape_owners():
		collision_shapes.append(shape_owner_get_owner(shape_owner))

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
	elif not (surface_detector.get_collider() or can_move_in_vacuum):
		return true
	else:
		return false
