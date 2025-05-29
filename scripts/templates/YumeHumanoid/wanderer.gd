# Copyright (C) 2025 Libre Nikki Developers.
#
# This file is part of Libre Nikki.
#
# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

extends YumeHumanoid

## A simple, non-playable character that walks around mindlessly.

## Amount of time (in seconds) to wait before attempting to move a randomly-picked direction.
@export var wait_time: float = 2.0

func _ready() -> void:
	super()
	_move_loop()

func _move_loop():
	var available_directions: Array[Game.DIRECTION]

	for direction in Game.DIRECTION.values():
		available_directions.append(direction)

	await get_tree().create_timer(wait_time, false, true).timeout

	if not is_busy:
		var can_move: bool = false

		while not (available_directions.is_empty() or can_move):
			var picked_direction: Game.DIRECTION = available_directions.pick_random()
			set_pointer(picked_direction)

			if is_colliding(picked_direction):
				available_directions.erase(picked_direction)
			else:
				can_move = true
				Game.call_on_available_physics_tick(face_and_move.bind(picked_direction))

	_move_loop()
