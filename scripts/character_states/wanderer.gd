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

extends YumeCharacterState
## A simple, non-playable character that walks around aimlessly.


## Amount of time (in seconds) to wait before attempting to move a
## randomly-picked direction.
var wait_time: float = 2.0

var wait_timer: float = randf_range(0.0, wait_time)


func _physics_process(delta: float) -> void:
	wait_timer += delta

	if wait_timer >= wait_time:
		wait_timer = 0.0
		_move_loop()


func _move_loop():
	var available_directions: Array[YumeCharacter.Direction] = [
			YumeCharacter.Direction.LEFT,
			YumeCharacter.Direction.DOWN,
			YumeCharacter.Direction.UP,
			YumeCharacter.Direction.RIGHT]

	if not character.is_busy:
		var picked_direction: YumeCharacter.Direction

		while not available_directions.is_empty():
			picked_direction = available_directions.pick_random()

			var offset_and_motion: PackedVector2Array = (
					character.get_offset_and_motion(picked_direction))

			if character.is_colliding(offset_and_motion):
				available_directions.erase(picked_direction)
			else:
				if character is YumeHumanoid:
					character.facing = picked_direction

				character.move(picked_direction, offset_and_motion, false)
				break
