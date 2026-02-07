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

extends "res://scripts/ai/YumeHumanoid/wanderer.gd"

func _init() -> void:
	super()

	if not is_connected("body_interacted", _on_body_interacted):
		connect("body_interacted", _on_body_interacted)

func _on_body_interacted(body: Node2D) -> void:
	if not is_busy:
		facing = face(body.global_position)
