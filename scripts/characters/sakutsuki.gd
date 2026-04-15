# Copyright (C) 2024-2026 Libre Nikki Developers.
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

extends YumePlayer

## A default player character. Libre Nikki protagonist.

signal act_started(effect: EFFECT)
signal act_finished(effect: EFFECT)

@onready var animation_player := $AnimationPlayer

@onready var sprite := $AnimatedSprite2D

func _ready() -> void:
	accept_key_held.connect(
			func () -> void:
				if not is_busy:
					act()
				else:
					accept_key_hold_time = 0.0
	)

	cancel_key_held.connect(
			func () -> void:
				if not is_busy:
					equip()
				else:
					cancel_key_hold_time = 0.0
	)

func _physics_process(delta: float) -> void:
	if not is_busy:
		if current_movement_keys.size() > 0:
			var direction: DIRECTION = MOVEMENT_KEYS[current_movement_keys[-1]]

			# Do not move when calling opposite movement events (eg. pressing
			# both 'up' and 'down' keys at once).
			if current_movement_keys.size() > 1:
				if direction & HORIZONTAL:
					if MOVEMENT_KEYS[current_movement_keys[-2]] & HORIZONTAL:
						return

				if direction & VERTICAL:
					if MOVEMENT_KEYS[current_movement_keys[-2]] & VERTICAL:
						return

			if is_sitting:
				#look(direction)
				pass
			else:
				if facing != direction:
						facing = direction

				move(direction)

func _force_animation_update() -> void:
	if not is_node_ready():
		await ready

	var effect_name: StringName = EFFECT.find_key(equipped_effect).capitalize()

	if effect_name == &"Default":
		effect_name = &""

	sprite.animation = DIRECTION.find_key(facing).to_lower() + effect_name

func _move() -> void:
	var animation_name: StringName = EFFECT.find_key(
			equipped_effect).capitalize().path_join(
			DIRECTION.find_key(facing).to_lower())

	if last_step:
		animation_name += &"2"

	animation_player.play(animation_name, -1.0, speed)
	animation_player.seek(0.125)

	await super()

## Perform an action.
func act() -> void:
	act_started.emit(equipped_effect)

	match equipped_effect:
		EFFECT.BIKE:
			return
		EFFECT.DEFAULT:
			is_busy = true

			var animation_name: StringName = EFFECT.find_key(
					equipped_effect).capitalize().path_join(
					DIRECTION.find_key(facing).to_lower()) + &"Action"

			if is_sitting:
				animation_name += &"2"

			animation_player.play(animation_name, -1.0)
			await animation_player.animation_finished

			if is_sitting:
				_force_animation_update()

			await get_tree().create_timer(0.25, false, true).timeout
			is_sitting = !is_sitting
			is_busy = false

	act_finished.emit(equipped_effect)

func pinch_cheek() -> void:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)

	while true:
		var animation_name: StringName = EFFECT.find_key(
				equipped_effect).capitalize().path_join(&"downPinch")

		if not animation_player.has_animation(animation_name):
			equip()
			continue

		is_busy = true

		if facing != DIRECTION.DOWN:
			timer.start(0.5)
			await timer.timeout
			facing = DIRECTION.DOWN
			timer.start(0.5)
			await timer.timeout

		animation_player.play(animation_name)
		await animation_player.animation_finished
		timer.start(0.25)
		await timer.timeout
		timer.queue_free()

		if current_world:
			if current_world.dreaming:
				Game.wake_up()
				return

		animation_player.play(animation_name, -1.0, -1.0, true)
		await animation_player.animation_finished
		_force_animation_update()
		is_busy = false
		return
