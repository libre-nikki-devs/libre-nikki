# Copyright (C) 2025 Libre Nikki Developers.
#
# This file is part of Libre Nikki.
#
# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

class_name YumeCharacter
extends YumeInteractable

## A simple moving character.

## If true, prevent the character from performing certain actions. For [YumePlayer]s, useful for scripted sequences where the player interaction is forbidden.[br][b]Warning:[/b] might cause softlocks when used incorrectly; make sure to set it to false once the sequence is done.
@export var is_busy: bool = false:
	set(value):
		is_busy = value
		if self is YumePlayer and Game.accept_timer:
			if Game.accept_held and not Game.accept_timer.is_stopped():
				Game.accept_timer.start(Game.settings["key_hold_time"])

		if self is YumePlayer and Game.cancel_timer:
			if Game.cancel_held and not Game.cancel_timer.is_stopped():
				Game.cancel_timer.start(Game.settings["key_hold_time"])

@export_group("Movement")

## Character's movement speed.
@export_range(0, 10, 0.5) var speed: float = 1.0

## If true, the character is able to move if there are no surfaces below.
@export var can_move_in_vacuum: bool = true

## If true, the character will move diagonally on stairs.
@export var can_use_stairs: bool = true

## True, if the character is moving.
var is_moving: bool = false

## Contains pointers that check occuring collisions.
var pointers: Node2D

## Pointer that determines where the character should move.
var current_pointer: YumePointer

## Target movement point.
var target: Vector2

var collision_checked: bool = false

## Emitted when the character has moved.
signal moved

func _init() -> void:
	# initialize pointers
	pointers = Node2D.new()
	pointers.name = "Pointers"
	for side: Vector2 in [Vector2.UP + Vector2.LEFT, Vector2.UP, Vector2.UP + Vector2.RIGHT, Vector2.LEFT, Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN + Vector2.LEFT, Vector2.DOWN, Vector2.DOWN + Vector2.RIGHT]:
		var pointer: YumePointer = YumePointer.new()
		pointer.offset = side
		pointer.collision_owner = self
		pointer.position = pointer.offset * Game.world.tile_size
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		collision_shape.shape = SegmentShape2D.new()
		collision_shape.shape.a = Vector2.ZERO
		collision_shape.shape.b = Vector2.ZERO
		pointer.add_child(collision_shape)
		pointers.add_child(pointer)
	add_child(pointers)

func _ready() -> void:
	if Game.world:
		for pointer: YumePointer in pointers.get_children():
			pointer.global_position = Game.world.wrap_around_world(pointer.global_position + target)

func _physics_process(delta: float) -> void:
	# we need to wait a physics frame for area2d to start detecting collisions before moving
	if ready and not collision_checked:
		if not is_busy:
			is_busy = true
			await get_tree().physics_frame
			is_busy = false
			collision_checked = true

func _move() -> void:
	pass

func get_tile_stair_target_corrections(tile_data: TileData, new_target: Vector2, direction: Game.DIRECTION) -> Vector2:
	if tile_data:
		if tile_data.has_custom_data("stair"):
			match tile_data.get_custom_data("stair"):
				# \-shaped stairs; horizontal movement
				1 when direction & Game.HORIZONTAL:
						new_target += Vector2(0, target.x)
						current_pointer = pointers.get_child(current_pointer.get_index() + 3 * int(Game.DIRECTIONS[direction].x))
				# /-shaped stairs; horizontal movement
				2 when direction & Game.HORIZONTAL:
						new_target -= Vector2(0, target.x)
						current_pointer = pointers.get_child(current_pointer.get_index() - 3 * int(Game.DIRECTIONS[direction].x))
				# \-shaped stairs; vertical movement
				3 when direction & Game.VERTICAL:
						new_target += Vector2(target.y, 0)
						current_pointer = pointers.get_child(current_pointer.get_index() + int(Game.DIRECTIONS[direction].y))
				# /-shaped stairs; vertical movement
				4 when direction & Game.VERTICAL:
						new_target -= Vector2(target.y, 0)
						current_pointer = pointers.get_child(current_pointer.get_index() - int(Game.DIRECTIONS[direction].y))
	return new_target

## Returns true, if the character is colliding with something.
func is_colliding(direction: Game.DIRECTION) -> bool:
	if current_pointer.surfaces.is_empty() and not can_move_in_vacuum:
		return true

	for body: Node2D in current_pointer.collisions:
		if body is YumeInteractable:
			body.body_touched.emit(self)
		return true

	return false

## If there are no colliding objects on the same Z index as the character, move this [param direction] (diagonally, if on stairs and if [member can_use_stairs] is [code]true[/code]) by one tile. Otherwise, emit [signal YumeInteractable.body_touched] on the colliding [YumeInteractable].
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

	if Game.world:
		var previous_position: Vector2 = global_position
		global_position = Game.world.wrap_around_world(global_position + target) - target

		if self == get_viewport().get_camera_2d().get_parent():
			for parallax: Parallax2D in get_tree().get_nodes_in_group("Parallax"):
				parallax.scroll_offset -= previous_position - global_position

	is_busy = true
	is_moving = true
	_move()
	var tween: Tween = create_tween()
	tween.tween_property(self, "pixel_position", Vector2i(target), 0.25 / speed).as_relative()
	var collision_shapes: Array[CollisionShape2D]

	for shape_owner: int in get_shape_owners():
		collision_shapes.append(shape_owner_get_owner(shape_owner))

	for collision_shape: CollisionShape2D in collision_shapes:
		collision_shape.position = target
		tween.parallel()
		tween.tween_property(collision_shape, "position", -target, 0.25 / speed).as_relative()

	for pointer: YumePointer in pointers.get_children():
		if Game.world:
			pointer.global_position = Game.world.wrap_around_world(pointer.global_position + target)
		else:
			pointer.global_position = pointer.global_position + target

		tween.parallel()
		tween.tween_property(pointer, "position", -target, 0.25 / speed).as_relative()

	await tween.finished
	is_busy = false
	is_moving = false
	moved.emit()

func set_pointer(direction: Game.DIRECTION) -> void:
	for pointer: YumePointer in pointers.get_children():
		if pointer.offset == Game.DIRECTIONS[direction]:
			current_pointer = pointer
