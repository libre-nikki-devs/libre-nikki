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

signal act_started(effect: Game.EFFECT)
signal act_finished(effect: Game.EFFECT)

func _ready() -> void:
	connect("accept_key_held", _on_accept_key_held)
	connect("cancel_key_held", _on_cancel_key_held)

func _physics_process(delta: float) -> void:
	if not is_busy:
		if current_movement_keys.size() > 0:
			var direction: Game.DIRECTION = MOVEMENT_KEYS[current_movement_keys[-1]]

			# Do not move when calling opposite movement events (eg. pressing both 'up' and 'down' keys at once).
			if current_movement_keys.size() > 1:
				if direction & Game.HORIZONTAL:
					if MOVEMENT_KEYS[current_movement_keys[-2]] & Game.HORIZONTAL:
						return

				if direction & Game.VERTICAL:
					if MOVEMENT_KEYS[current_movement_keys[-2]] & Game.VERTICAL:
						return

			if is_sitting:
				look(direction)
			else:
				face_and_move(direction)

func _input(event: InputEvent) -> void:
	if not is_busy:
		if event.is_action_pressed("ui_accept"):
			interact()

		if event.is_action_pressed("ui_cancel"):
			open_menu()

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
	act_started.emit(effect)

	match effect:
		Game.EFFECT.BIKE:
			return
		Game.EFFECT.DEFAULT:
			is_busy = true

			if is_sitting:
				set_animation(str(Game.DIRECTION.find_key(facing)).to_lower() + "Action2", 1.0)
				await animation_player.animation_finished
				action = "Default"
			else:
				set_animation(str(Game.DIRECTION.find_key(facing)).to_lower() + "Action", 1.0)
				await animation_player.animation_finished
				action = "Sit"

			is_sitting = !is_sitting
			is_busy = false
		_:
			pass

	act_finished.emit(effect)

	if Game.accept_is_hold:
		Game.accept_timer.start(Game.settings["key_hold_time"])

var menu = Control.new()

func open_menu() -> void:
	if Game.cancel_events.is_empty():
		Game.transition_handler.play("fade_out", -1, 10.0)
		await Game.transition_handler.animation_finished
		menu = preload("res://scenes/menus/players_menu.tscn").instantiate()
		Game.add_child(menu)
		Game.transition_handler.play("fade_in", -1, 10.0)
		get_tree().paused = true
	else:
		if Game.cancel_events.front().get_argument_count() > 0:
			Game.cancel_events.front().call(self)
		else:
			Game.cancel_events.front().call()
		Game.cancel_events.pop_front()
