# Copyright (C) 2025 boot <bootovy@proton.me> and contributors.

# This file is part of Libre Nikki.

# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

extends YumeInteractable

@export var animated_sprite: AnimatedSprite2D

signal opened

func _init() -> void:
	body_interacted.connect(_on_door_body_interacted)

func _ready() -> void:
	if animated_sprite.frame != 0:
		animated_sprite.frame = 0
		Game.play_sound([preload("res://sounds/boot_steel_door_close-1.wav"), preload("res://sounds/boot_steel_door_close-2.wav")].pick_random(), self, 512)

func _on_door_body_interacted(body: Node2D):
	if body is YumePlayer and body.facing == Game.DIRECTION.UP:
		body.is_busy = true
		animated_sprite.play("open")
		Game.play_sound(preload("res://sounds/boot_steel_door_open-1.wav"), self, 512)
		await animated_sprite.animation_finished
		body.is_busy = false
		opened.emit()
