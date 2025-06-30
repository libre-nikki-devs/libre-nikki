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

extends YumeInteractable

func _on_body_interacted(body: Node2D):
	if body is YumePlayer and body.facing == "up":
		body.is_sitting = true
		body.current_pointer.monitoring = false
		body.face_and_move("up")
		await body.moved
		body.face("down")
		body.action = "Bench"
		Game.accept_events.push_front(Callable(self, "something"))

func something(body: Node2D):
	body.is_sitting = false
	body.action = ""
	body.face_and_move("down")
	await body.moved
	body.current_pointer.monitoring = true
