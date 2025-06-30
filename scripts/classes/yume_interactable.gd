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

class_name YumeInteractable
extends CharacterBody2D

## A simple node that can be interacted with.

## Pixel-perfect position.
var pixel_position: Vector2i:
	get:
		return Vector2i(round(position))

	set(value):
		position = value
		pixel_position = value

## Emitted when something interacted with this node.
signal body_interacted(body: Node2D)

## Emitted when something touched this node.
signal body_touched(body: Node2D)

## Emitted when something stepped on this node.
signal body_stepped_on(body: Node2D)
