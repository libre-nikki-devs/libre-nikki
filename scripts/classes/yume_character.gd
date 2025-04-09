# Copyright (C) 2025 boot <bootovy@proton.me> and contributors.

# This file is part of Libre Nikki.

# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

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

## Contains three pointers that check occuring collisions.
var pointers: Array[Area2D] = []

## Pointer that determines where the character should move.
var current_pointer: Area2D

## Target movement point.
var target: Vector2

## Emitted when the character has moved.
signal moved

func _init() -> void:
	# initialize pointers
	for i: int in 3:
		pointers.insert(i, Area2D.new())
		var collision = CollisionShape2D.new()
		collision.shape = SegmentShape2D.new()
		collision.shape.a = Vector2(0, 0)
		collision.shape.b = Vector2(0, 0)
		pointers[i].add_child(collision)
		pointers[i].set_script(preload("res://script_templates/Area2D/pointer.gd"))
		add_child(pointers[i])

func get_tile_stair_target_corrections(tile_data: TileData, new_target: Vector2, direction: Game.DIRECTION):
	if tile_data:
		if tile_data.get_custom_data("stair"):
			match tile_data.get_custom_data("stair"):
				# \-shaped stairs; horizontal movement
				1 when direction in [Game.DIRECTION.LEFT, Game.DIRECTION.RIGHT]: 
						new_target += Vector2(0, target.x)
				# /-shaped stairs; horizontal movement
				2 when direction in [Game.DIRECTION.LEFT, Game.DIRECTION.RIGHT]: 
						new_target -= Vector2(0, target.x)
				# \-shaped stairs; vertical movement
				3 when direction in [Game.DIRECTION.DOWN, Game.DIRECTION.UP]:
						new_target += Vector2(target.y, 0)
				# /-shaped stairs; vertical movement
				4 when direction in [Game.DIRECTION.DOWN, Game.DIRECTION.UP]: 
						new_target -= Vector2(target.y, 0)
	return new_target

## Returns true, if the character is colliding with something.
func is_colliding(direction: Game.DIRECTION) -> bool:
	target = Game.DIRECTIONS[direction] * Game.world.tile_size
	pointers[0].position = target

	if direction in [Game.DIRECTION.DOWN, Game.DIRECTION.UP]:
		pointers[1].position = target + Vector2(1, 0) * Game.world.tile_size
		pointers[2].position = target + Vector2(-1, 0) * Game.world.tile_size
	else:
		pointers[1].position = target + Vector2(0, 1) * Game.world.tile_size
		pointers[2].position = target + Vector2(0, -1) * Game.world.tile_size

	for i: int in 3:
		Game.world.wrap_node_around_world(pointers[i])

	await get_tree().physics_frame

	current_pointer = pointers[0]

	# these probably should be in different functions 
	for object: Node2D in current_pointer.stepped_on_objects:
		if object.global_position == current_pointer.global_position and object is YumeInteractable:
			object.body_stepped_on.emit(self)

		if object is TileMapLayer:
			var current_tile = object.local_to_map(current_pointer.global_position)
			var tile_data = object.get_cell_tile_data(current_tile)

			if can_use_stairs:
				target = get_tile_stair_target_corrections(tile_data, target, direction)

	if direction in [Game.DIRECTION.LEFT, Game.DIRECTION.RIGHT]:
		if target.y < 0:
			current_pointer = pointers[2]
		elif target.y > 0:
			current_pointer = pointers[1]
	else:
		if target.x < 0:
			current_pointer = pointers[2]
		elif target.x > 0:
			current_pointer = pointers[1]

	if current_pointer.stepped_on_objects.is_empty() and !can_move_in_vacuum:
		return true

	for object: Node2D in current_pointer.colliding_objects:
		if object is YumeInteractable:
			object.body_touched.emit(self)
		return true
	return false

## If there are no colliding objects on the same Z index as the character, move this [param direction] (diagonally, if on stairs and if [member can_use_stairs] is [code]true[/code]) by one tile. Otherwise, emit [signal YumeInteractable.body_touched] on the colliding [YumeInteractable].
func move(direction: Game.DIRECTION) -> void:
	if await is_colliding(direction) or speed <= 0:
		return

	is_busy = true
	is_moving = true

	var tween: Tween = create_tween()
	tween.tween_property(self, "position", position + target, 0.25 / speed)
	await tween.finished

	is_moving = false
	is_busy = false

	await get_tree().physics_frame
	moved.emit()
