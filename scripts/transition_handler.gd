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

extends AnimationPlayer


@onready var texture_rect: TextureRect = $TextureRect


func _ready() -> void:
	reparent.call_deferred(Game)


func prepare_texture() -> Error:
	var screenshot: Image = await Game.take_screenshot()

	if not screenshot:
		return ERR_CANT_CREATE

	var texture := ImageTexture.create_from_image(screenshot)
	texture_rect.texture = texture
	texture_rect.modulate.a = 1.0
	texture_rect.show()

	return OK
