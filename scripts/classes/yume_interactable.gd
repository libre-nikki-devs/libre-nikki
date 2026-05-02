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

class_name YumeInteractable
extends CharacterBody2D

## A simple node that can be interacted with.

enum SURFACE { SILENT = -1, DEFAULT = 0, CONCRETE = 1, METAL = 2,
		GRASS = 3, DIRT = 4, SAND = 5, WATER = 6, SNOW = 7,
		WOOD = 8, CARPET = 9 }

@export var surface: SURFACE = SURFACE.DEFAULT

## Emitted when something interacted with this node.
signal body_interacted(body: Node2D)

## Emitted when something touched this node.
signal body_touched(body: Node2D)

## Emitted when something stepped on this node.
signal body_stepped_on(body: Node2D)

func play_sound(sound: AudioStream, distance: float = 256.0, pitch: float = 1.0,
		volume_offset: float = 0.0) -> void:

	var audio_stream_player := AudioStreamPlayer2D.new()
	audio_stream_player.attenuation = 2.0
	audio_stream_player.autoplay = true
	audio_stream_player.bus = &"SFX"
	audio_stream_player.max_distance = distance
	audio_stream_player.pitch_scale = pitch
	audio_stream_player.process_mode = PROCESS_MODE_ALWAYS
	audio_stream_player.stream = sound
	audio_stream_player.volume_db = linear_to_db(1.0 + volume_offset)

	audio_stream_player.finished.connect(
		func () -> void:
			audio_stream_player.queue_free()
	)

	add_child(audio_stream_player)
