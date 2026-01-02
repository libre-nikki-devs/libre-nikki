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

## A character controllable by the player.

class_name YumePlayer
extends YumeHumanoid

enum EFFECT { DEFAULT = 0, BIKE = 1 }

const MOVEMENT_KEYS: Dictionary[String, DIRECTION] = {
	"ui_left": DIRECTION.LEFT,
	"ui_down": DIRECTION.DOWN,
	"ui_up": DIRECTION.UP,
	"ui_right": DIRECTION.RIGHT
}

## [Camera2D] node that follows the character.
@export var camera: Camera2D

## Currently equipped effect.
@export var equipped_effect: EFFECT = EFFECT.DEFAULT:
	set(value):
		equipped_effect = value
		set_animation()

@export var menu_path: StringName = "res://scenes/ui/player_menu.tscn"

var accept_events: Array[Callable] = []

var cancel_events: Array[Callable] = []

var current_movement_keys: Array[String] = []

var accept_key_hold_time: float = 0.0

var cancel_key_hold_time: float = 0.0

var menu_queued: bool = false

signal accept_key_held()
signal cancel_key_held()

## Emitted when the character equips an effect.
signal equipped(effect: EFFECT)

func _init() -> void:
	super()
	add_to_group("Players")
	set_process(true)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			if camera and current_world:
				if current_world.bounds.has_area():
					if not current_world.is_node_ready():
						await current_world.ready

					if current_world.camera_limits.is_empty():
						camera.limit_enabled = false
					else:
						camera.limit_enabled = true
						camera.limit_left = floor(current_world.camera_limits[0] - camera.offset.x)
						camera.limit_bottom = floor(current_world.camera_limits[1] - camera.offset.y)
						camera.limit_top = floor(current_world.camera_limits[2] - camera.offset.y)
						camera.limit_right = floor(current_world.camera_limits[3] - camera.offset.x)

		NOTIFICATION_READY:
			if Game.persistent_data.has("player_data"):
				for property: String in Game.persistent_data["player_data"].keys():
					set(property, Game.persistent_data["player_data"][property])

		NOTIFICATION_PROCESS:
			for movement_key: StringName in MOVEMENT_KEYS.keys():
				var is_movement_key_pressed: bool = Input.is_action_pressed(movement_key)

				if is_movement_key_pressed and movement_key not in current_movement_keys:
					current_movement_keys.append(movement_key)

				elif not is_movement_key_pressed and movement_key in current_movement_keys:
					current_movement_keys.erase(movement_key)

			if Input.is_action_pressed("ui_accept"):
				accept_key_hold_time += get_process_delta_time()

				if accept_key_hold_time > Game.settings["key_hold_time"]:
					emit_signal("accept_key_held")

			else:
				accept_key_hold_time = 0.0

			if Input.is_action_pressed("ui_go_back"):
				cancel_key_hold_time += get_process_delta_time()

				if cancel_key_hold_time > Game.settings["key_hold_time"]:
					emit_signal("cancel_key_held")

			else:
				cancel_key_hold_time = 0.0

		NOTIFICATION_PAUSED:
			current_movement_keys.clear()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not is_busy:
		interact()

	if event.is_action_pressed("ui_go_back"):
		if is_busy:
			if is_moving:
				if not menu_queued:
					menu_queued = true
					await moved
					open_menu()
					menu_queued = false
		else:
			open_menu()

func _move() -> void:
	super()

	if not Game.persistent_data.has("steps_taken"):
		Game.persistent_data["steps_taken"] = 0

	Game.persistent_data["steps_taken"] += 1

## Equip this [param effect].
func equip(effect: EFFECT = EFFECT.DEFAULT, silently: bool = false) -> void:
	equipped_effect = effect

	match effect:
		EFFECT.BIKE:
			speed = 2
		_:
			speed = 1

	equipped.emit()

func interact() -> void:
	if accept_events.is_empty():
		if not is_sitting:
			await get_tree().physics_frame
			_update_detectors(facing)
			var collider: Object = collision_detector.get_collider()

			if collider:
				if collider is YumeInteractable:
					collider.emit_signal("body_interacted", self)
					collider.emit_signal("body_touched", self)
	else:
		if accept_events.front().get_argument_count() > 0:
			accept_events.front().call(self)
		else:
			accept_events.front().call()

		accept_events.pop_front()

## Play the cheek pinching animation. Wakes up the character, if is dreaming.
func pinch_cheek() -> void:
	var effect_name: String = EFFECT.find_key(equipped_effect).capitalize()

	if animation_player.has_animation_library(effect_name):
		if animation_player.get_animation_library(effect_name).has_animation("downPinch"):
			is_busy = true

			if facing != DIRECTION.DOWN:
				await get_tree().create_timer(0.5, false, true).timeout
				facing = DIRECTION.DOWN
				await get_tree().create_timer(0.5, false, true).timeout

			set_animation("downPinch", 1.0)
			await animation_player.animation_finished
			await get_tree().create_timer(0.25, false, true).timeout

			if current_world:
				if current_world.dreaming:
					Game.wake_up()

			set_animation("downPinch", -1.0, 1.0, true)
			await animation_player.animation_finished
			set_animation()
			is_busy = false
			return

	equip()
	pinch_cheek()

func set_animation(animation: String = str(DIRECTION.find_key(facing)).to_lower() + action, animation_speed: float = 0.0, animation_position: float = 0.0, from_end: bool = false) -> void:
	var effect_name: String = EFFECT.find_key(equipped_effect).capitalize()

	if animation_player.has_animation_library(effect_name):
		if animation_player.get_animation_library(effect_name).has_animation(animation):
			animation_player.play(effect_name + "/" + animation, -1, animation_speed, from_end)
			animation_player.seek(animation_position, true)

## Grant the player an effect.
func grant_effect(effect: EFFECT) -> void:
	if not Game.persistent_data.has("acquired_effects"):
		Game.persistent_data["acquired_effects"] = 0

	if Game.persistent_data["acquired_effects"] & effect == 0:
		Game.persistent_data["acquired_effects"] ^= effect

func revoke_effect(effect: EFFECT) -> void:
	if Game.persistent_data.has("acquired_effects"):
		if Game.persistent_data["acquired_effects"] & effect:
			Game.persistent_data["acquired_effects"] -= effect

func open_menu() -> void:
	if cancel_events.is_empty():
		Game.open_menu(menu_path)
	else:
		if cancel_events.front().get_argument_count() > 0:
			cancel_events.front().call(self)
		else:
			cancel_events.front().call()

		cancel_events.pop_front()
