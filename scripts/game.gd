# Copyright (C) 2024-2025 Libre Nikki Developers.
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

extends CanvasLayer

## An autoload singleton that handles the game's most important data as well as
## it provides functions specific to Libre Nikki.

@onready var music: AudioStreamPlayer = get_node("AudioStreamPlayer")

## Contains data that are preserved in a save file.
var persistent_data: Dictionary = {}

## Contains settings data.
var settings: Dictionary = {
	"key_hold_time" = 0.5
}

@onready var transition_handler: AnimationPlayer = get_node("TransitionHandler")

func _ready() -> void:
	get_window().min_size = Vector2i(640, 480)
	_count_playtime()

func _count_playtime():
	while true:
		await get_tree().create_timer(1.0, false, true).timeout

		if persistent_data.has("playtime"):
			persistent_data["playtime"] += 1
		else:
			persistent_data["playtime"] = 0

func change_scene(path: String) -> void:
	persistent_data["entered_from"] = get_tree().current_scene.scene_file_path

	if persistent_data.has("scene_data"):
		if persistent_data["scene_data"].has(path):
			get_tree().change_scene_to_packed(persistent_data["scene_data"][path])

	get_tree().change_scene_to_file(path)

func save_current_scene() -> void:
	var current_scene: Node = get_tree().current_scene

	if not persistent_data.has("scene_data"):
		persistent_data["scene_data"] = {}

		persistent_data["scene_data"][current_scene.scene_file_path] = PackedScene.new()
		persistent_data["scene_data"][current_scene.scene_file_path].pack(current_scene)

func save_player_data(player: YumePlayer, player_properties: Array[String] = ["accept_events", "cancel_events", "equipped_effect", "facing", "last_step", "speed"]) -> void:
	if player:
		persistent_data["player_data"] = {}

		for property: String in player_properties:
			if property in player:
				persistent_data["player_data"][property] = player.get(property)

func play_sound(sound: AudioStream, parent: Node2D, distance: int = 256, pitch: float = 1.0, volume_offset: float = 0.0) -> void:
	if sound:
		var audio_stream_player = AudioStreamPlayer2D.new()
		audio_stream_player.attenuation = 2.0
		audio_stream_player.autoplay = true
		audio_stream_player.bus = "SFX"
		audio_stream_player.max_distance = distance
		audio_stream_player.pitch_scale = pitch
		audio_stream_player.process_mode = Node.PROCESS_MODE_ALWAYS
		audio_stream_player.stream = sound
		audio_stream_player.volume_db = linear_to_db(1.0 + volume_offset)
		parent.add_child(audio_stream_player)
		await audio_stream_player.finished
		audio_stream_player.queue_free()

func play_sound_everywhere(sound: AudioStream, pitch: float = 1.0, volume_offset: float = 0.0) -> void:
	if sound:
		var audio_stream_player = AudioStreamPlayer.new()
		audio_stream_player.autoplay = true
		audio_stream_player.bus = "SFX"
		audio_stream_player.pitch_scale = pitch
		audio_stream_player.stream = sound
		audio_stream_player.volume_db = linear_to_db(1.0 + volume_offset)
		add_child(audio_stream_player)
		await audio_stream_player.finished
		audio_stream_player.queue_free()

## Start the dream session.
func sleep() -> void:
	persistent_data["random"] = RandomNumberGenerator.new().randi_range(0, 255)

	if !persistent_data.has("times_slept"):
		persistent_data["times_slept"] = 1
	else:
		persistent_data["times_slept"] += 1

	change_scene("res://scenes/maps/sakutsukis_dream_bedroom.tscn")

## End the dream session.
func wake_up() -> void:
	persistent_data["player_data"] = {}
	persistent_data["world_data"] = {}
	transition_handler.play("pixelate_out")
	get_tree().paused = true
	await transition_handler.animation_finished
	change_scene("res://scenes/maps/sakutsukis_bedroom.tscn")

func fade_in_music(audio: AudioStream, duration: float, pitch: float = 1.0, volume_offset: float = 0.0) -> void:
	music.pitch_scale = pitch
	music.stream = audio
	music.play()
	var tween = create_tween()
	tween.tween_property(music, "volume_db", linear_to_db(1.0 + volume_offset), duration).from(linear_to_db(0.01))

func fade_out_music(duration: float) -> void:
	var tween = create_tween()
	tween.parallel().tween_property(music, "volume_db", linear_to_db(0.01), duration)
	await tween.finished
	music.stop()

## Open settings menu.
func open_settings(focus):
	var settings_menu: Control
	settings_menu = preload("res://scenes/menus/settings_menu.tscn").instantiate()
	settings_menu.focus = focus
	add_child(settings_menu)
	transition_handler.play("fade_in", -1, 10.0)
