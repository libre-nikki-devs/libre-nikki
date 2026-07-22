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
## A simple, non-playable character that follows something.


## Node to follow.
var followee: Node2D = null

## Amount of time (in seconds) to wait before attempting to move.
var wait_time: float = 2.0

var wait_timer: float = randf_range(0.0, wait_time)


func _physics_process(delta: float) -> void:
	wait_timer += delta

	if wait_timer >= wait_time:
		wait_timer = 0.0
		_move_loop()


func _move_loop():
	if followee and not character.is_busy:
		var direction: YumeCharacter.Direction = character.face(
				followee.global_position)

		if character is YumeHumanoid:
			character.facing = direction

		character.move(direction)
