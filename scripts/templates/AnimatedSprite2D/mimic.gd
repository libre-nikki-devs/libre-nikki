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

extends AnimatedSprite2D

var to_mimic: AnimatedSprite2D

func _ready() -> void:
	to_mimic.connect("animation_changed", _on_animated_sprite_2d_animation_changed)
	to_mimic.connect("frame_changed", _on_animated_sprite_2d_frame_changed)

func _on_animated_sprite_2d_animation_changed() -> void:
	animation = to_mimic.animation

func _on_animated_sprite_2d_frame_changed() -> void:
	frame = to_mimic.frame
