# Copyright (C) 2025 Libre Nikki Developers.
#
# This file is part of Libre Nikki.
#
# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

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

var current_movement_keys: Array[String] = []

var accept_key_hold_time: float = 0.0

var cancel_key_hold_time: float = 0.0

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

			if Input.is_action_pressed("ui_cancel"):
				cancel_key_hold_time += get_process_delta_time()

				if cancel_key_hold_time > Game.settings["key_hold_time"]:
					emit_signal("cancel_key_held")

			else:
				cancel_key_hold_time = 0.0

func _move() -> void:
	super()

	if not Game.persistent_data.has("steps_taken"):
		Game.persistent_data["steps_taken"] = 0

	Game.persistent_data["steps_taken"] += 1

## Equip this [param effect].
func equip(effect: EFFECT = 0, silently: bool = false) -> void:
	equipped_effect = effect

	match effect:
		EFFECT.BIKE:
			speed = 2
		_:
			speed = 1

	equipped.emit()

## If there are colliding nodes on the same Z index as this character, emit both [signal YumeInteractable.body_interacted] and [signal YumeInteractable.body_touched] on the colliding [YumeInteractable].
func interact() -> void:
	if Game.accept_events.is_empty():
		if not is_sitting:
			var collider: Object = collision_detector.get_collider()

			if collider:
				if collider is YumeInteractable:
					collider.emit_signal("body_interacted", self)
					collider.emit_signal("body_touched", self)

	else:
		if Game.accept_events.front().get_argument_count() > 0:
			Game.accept_events.front().call(self)
		else:
			Game.accept_events.front().call()
		Game.accept_events.pop_front()

## Play the cheek pinching animation. Wakes up the character, if is dreaming.
func pinch_cheek() -> void:
	var effect_name: String = EFFECT.find_key(equipped_effect).capitalize()

	if animation_player.has_animation_library(effect_name):
		if animation_player.get_animation_library(effect_name).has_animation("downPinch"):
			is_busy = true
			facing = DIRECTION.DOWN
			set_animation("downPinch", 1.0)
			await animation_player.animation_finished

			var current_scene: Node = get_tree().current_scene

			if current_scene is YumeWorld:
				if current_scene.dreaming:
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
