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

extends YumeHumanoid

## A simple, non-playable character that walks around aimlessly.

## Amount of time (in seconds) to wait before attempting to move a
## randomly-picked direction.
@export var wait_time: float = 2.0

func _ready() -> void:
	_move_loop()

func _move_loop():
	while true:
		var available_directions: Array[DIRECTION]
		var current_scene: Node = get_tree().current_scene

		for direction in DIRECTION.values():
			available_directions.append(direction)

		await get_tree().create_timer(wait_time, false, true).timeout

		if not is_busy:
			var can_move: bool = false
			var picked_direction: DIRECTION = DIRECTION.LEFT

			while not (available_directions.is_empty() or can_move):
				picked_direction = available_directions.pick_random()

				if current_scene is YumeWorld:
					target_position = DIRECTIONS[picked_direction] * current_scene.tile_size
				else:
					target_position = DIRECTIONS[picked_direction] * 16.0

				if test_move(transform, target_position):
					available_directions.erase(picked_direction)
				else:
					can_move = true

			if can_move:
				facing = picked_direction
				move(picked_direction)

func _on_body_interacted(body: Node2D) -> void:
	if not is_busy:
		face(body.global_position)
