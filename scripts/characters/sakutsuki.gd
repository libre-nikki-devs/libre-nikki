# Copyright (C) 2024-2025 Libre Nikki Developers.
#
# This file is part of Libre Nikki.
#
# Libre Nikki is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# Libre Nikki is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with Libre Nikki. If not, see <https://www.gnu.org/licenses/>.

extends YumePlayer

## A default player character. Libre Nikki protagonist.

signal act_started(effect: EFFECT)
signal act_finished(effect: EFFECT)

func _ready() -> void:
	connect("accept_key_held", _on_accept_key_held)
	connect("cancel_key_held", _on_cancel_key_held)

func _physics_process(delta: float) -> void:
	if not is_busy:
		if current_movement_keys.size() > 0:
			var direction: DIRECTION = MOVEMENT_KEYS[current_movement_keys[-1]]

			# Do not move when calling opposite movement events (eg. pressing both 'up' and 'down' keys at once).
			if current_movement_keys.size() > 1:
				if direction & HORIZONTAL:
					if MOVEMENT_KEYS[current_movement_keys[-2]] & HORIZONTAL:
						return

				if direction & VERTICAL:
					if MOVEMENT_KEYS[current_movement_keys[-2]] & VERTICAL:
						return

			if is_sitting:
				look(direction)
			else:
				facing = direction
				move(direction)

func _on_accept_key_held() -> void:
	if not is_busy:
		#act()
		pass
	else:
		accept_key_hold_time = 0.0

func _on_cancel_key_held() -> void:
	if not is_busy:
		equip()
	else:
		cancel_key_hold_time = 0.0

## Perform an action.
func act() -> void:
	act_started.emit(equipped_effect)

	match equipped_effect:
		EFFECT.BIKE:
			return
		EFFECT.DEFAULT:
			is_busy = true

			if is_sitting:
				set_animation(str(DIRECTION.find_key(facing)).to_lower() + "Action2", 1.0)
				await animation_player.animation_finished
				action = "Default"
			else:
				set_animation(str(DIRECTION.find_key(facing)).to_lower() + "Action", 1.0)
				await animation_player.animation_finished
				action = "Sit"

			is_sitting = !is_sitting
			is_busy = false
		_:
			pass

	act_finished.emit(equipped_effect)
