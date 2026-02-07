# Copyright (C) 2026 Libre Nikki Developers.
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

extends YumeCharacter

## A simple, non-playable character that walks around aimlessly.

## Amount of time (in seconds) to wait before attempting to move a
## randomly-picked direction.
@export var wait_time: float = 2.0

var wait_timer: float = randf_range(0.0, wait_time)

signal waited

func _ready() -> void:
	_move_loop()

func _physics_process(delta: float) -> void:
	wait_timer += delta

	if wait_timer >= wait_time:
		wait_timer = 0.0
		waited.emit()

func _move_loop():
	while true:
		var available_directions: Array[DIRECTION]

		for direction in DIRECTION.values():
			available_directions.append(direction)

		await waited

		if not is_busy:
			var can_move: bool = false
			var picked_direction: DIRECTION = DIRECTION.LEFT

			while not (available_directions.is_empty() or can_move):
				picked_direction = available_directions.pick_random()

				if is_colliding(picked_direction):
					available_directions.erase(picked_direction)
				else:
					can_move = true

			if can_move:
				move(picked_direction)
