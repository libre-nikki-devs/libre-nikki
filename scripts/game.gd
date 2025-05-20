# Copyright (C) 2024-2025 Libre Nikki Developers.
#
# This file is part of Libre Nikki.
#
# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

extends Node

## An autoload singleton that handles the game's most important data as well as it provides functions specific to Libre Nikki.

const DIRECTIONS: Dictionary[DIRECTION, Vector2] = {
	DIRECTION.LEFT: Vector2.LEFT,
	DIRECTION.DOWN: Vector2.DOWN,
	DIRECTION.UP: Vector2.UP,
	DIRECTION.RIGHT: Vector2.RIGHT,
}

enum { ALL = 15, HORIZONTAL = 9, VERTICAL = 6 }

enum DIRECTION { LEFT = 1, DOWN = 2, UP = 4, RIGHT = 8 }

enum EFFECT { DEFAULT = 0, BIKE = 1 }

enum SURFACE { SILENT = -1, DEFAULT, CONCRETE, METAL, GRASS, DIRT, SAND, WATER, SNOW, WOOD, CARPET }

enum TRANSITION { FADE_IN, FADE_OUT }

@onready var music: AudioStreamPlayer = get_node("AudioStreamPlayer")

## Contains data that are preserved in a save file.
var persistent_data: Dictionary = {}

## Contains settings data.
var settings: Dictionary = {
	"key_hold_time" = 0.5
}

## Node of the currently visiting world.
var world: YumeWorld

## Indicates what movement events are currently called. Index 0 is the most recently called event. Note: most keyboards will not register all events at once.
var movement_events: Array[DIRECTION] = []

var accept_events: Array[Callable] = []

var cancel_events: Array[Callable] = []

@onready var canvas_layer: CanvasLayer = get_node("CanvasLayer")

@onready var transitionrect: ColorRect = get_node("CanvasLayer/ColorRect")

signal accept_held()
signal cancel_held()
signal transition_finished()

@onready var accept_timer: Timer = get_node("AcceptTimer")
@onready var cancel_timer: Timer = get_node("CancelTimer")

var accept_is_hold = false
var cancel_is_hold = false

func _on_accept_timer_timeout() -> void:
	accept_held.emit()

func _on_cancel_timer_timeout() -> void:
	cancel_held.emit()

func _input(event: InputEvent) -> void:
	for direction: String in DIRECTION:
		if event.is_action_pressed(str(direction).to_lower()):
			movement_events.push_front(Game.DIRECTION[direction])

		if event.is_action_released(str(direction).to_lower()):
			movement_events.erase(Game.DIRECTION[direction])

	if event.is_action_pressed("accept"):
		accept_is_hold = true
		accept_timer.start(settings["key_hold_time"])

	if event.is_action_released("accept"):
		accept_is_hold = false
		if not accept_timer.is_stopped():
			accept_timer.stop()

	if event.is_action_pressed("cancel"):
		cancel_is_hold = true
		cancel_timer.start(settings["key_hold_time"])

	if event.is_action_released("cancel"):
		cancel_is_hold = false
		if not cancel_timer.is_stopped():
			cancel_timer.stop()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			movement_events = []
		NOTIFICATION_READY:
			DisplayServer.window_set_min_size(Vector2(640, 480))

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
		Game.add_child(audio_stream_player)
		await audio_stream_player.finished
		audio_stream_player.queue_free()

## Grant the player an effect.
func grant_effect(effect: EFFECT) -> void:
	if not persistent_data.has("acquired_effects"):
		persistent_data["acquired_effects"] = 0
	if persistent_data["acquired_effects"] & effect == 0:
		persistent_data["acquired_effects"] ^= effect

func revoke_effect(effect: EFFECT) -> void:
	if persistent_data.has("acquired_effects"):
		if persistent_data["acquired_effects"] & effect:
			persistent_data["acquired_effects"] -= effect

## Start the dream session.
func sleep() -> void:
	persistent_data["random"] = RandomNumberGenerator.new().randi_range(0, 255)

	if !persistent_data.has("times_slept"):
		persistent_data["times_slept"] = 1
	else:
		persistent_data["times_slept"] += 1

	world.change_world("Sakutsuki's Dream Room", false, [])

## End the dream session.
func wake_up() -> void:
	persistent_data["player_data"] = {}
	persistent_data["world_data"] = {}

	transition(TRANSITION.FADE_OUT, 1.0)
	get_tree().paused = true
	await transition_finished
	world.change_world("Sakutsuki's Room", false, [])

# WIP
func face(object: Node2D, what: Vector2) -> DIRECTION:
	if object.position.x > what.x:
		return DIRECTION.LEFT
	elif object.position.x < what.x:
		return DIRECTION.RIGHT
	if object.position.y > what.y:
		return DIRECTION.UP
	else:
		return DIRECTION.DOWN

## Get the global Z index of a node.
func get_global_z_index(body: Node2D) -> int:
	var global_z_index: int = body.z_index
	if body.z_as_relative:
		while body.get_parent() is CanvasItem:
			body = body.get_parent()
			global_z_index += body.z_index
	return global_z_index

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

## Make a transition.
func transition(transition_type: TRANSITION, duration: float):
	match transition_type:
		TRANSITION.FADE_IN:
			transitionrect.color = Color(0, 0, 0, 1)
			var tween: Tween = create_tween()
			tween.tween_property(transitionrect, "color:a", 0, duration)
			await tween.finished
			transition_finished.emit()
		TRANSITION.FADE_OUT:
			transitionrect.color = Color(0, 0, 0, 0)
			var tween: Tween = create_tween()
			tween.tween_property(transitionrect, "color:a", 1, duration)
			await tween.finished
			transition_finished.emit()

## Open settings menu.
func open_settings(focus):
	var settings_menu: Control
	settings_menu = preload("res://scenes/settings.tscn").instantiate()
	settings_menu.focus = focus
	canvas_layer.add_child(settings_menu)
	transition(Game.TRANSITION.FADE_IN, 0.1)
