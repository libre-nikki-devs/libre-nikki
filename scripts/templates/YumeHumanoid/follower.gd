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

## A simple, non-playable character that follows something.

## Node to follow.
@export var follow: Node2D

## Amount of time (in seconds) to wait before attempting to move.
@export var wait_time: float = 2.0

func _ready() -> void:
	_move_loop()

func _move_loop():
	while true:
		await get_tree().create_timer(wait_time, false, true).timeout

		if follow and not is_busy:
			var direction: DIRECTION = face(follow.global_position)
			facing = direction
			move(direction)
