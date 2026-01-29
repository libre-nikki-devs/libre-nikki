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

extends PanelContainer

func _init() -> void:
	if OS.is_debug_build():
		hide()
	else:
		queue_free()

func _process(delta: float) -> void:
	if Input.is_action_pressed("fast_forward"):
		if Engine.time_scale == 1.0:
			show()

		Engine.time_scale = 3.0
	else:
		if Engine.time_scale == 3.0:
			hide()

		Engine.time_scale = 1.0
