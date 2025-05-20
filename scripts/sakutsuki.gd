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
	super()
	Game.accept_held.connect(_on_accept_held)
	Game.cancel_held.connect(_on_cancel_held)

func _physics_process(delta: float) -> void:
	super(delta)

	if not is_busy:
	# do not move when calling opposite movement events (eg. pressing both 'up' and 'down' keys at once)
		if not Game.movement_events.is_empty() and (Game.movement_events.find(Game.DIRECTION.UP) <= -1 or Game.movement_events.find(Game.DIRECTION.DOWN) <= -1 or absi(Game.movement_events.find(Game.DIRECTION.UP) - Game.movement_events.find(Game.DIRECTION.DOWN)) != 1) and (Game.movement_events.find(Game.DIRECTION.LEFT) <= -1 or Game.movement_events.find(Game.DIRECTION.RIGHT) <= -1 or absi(Game.movement_events.find(Game.DIRECTION.LEFT) - Game.movement_events.find(Game.DIRECTION.RIGHT)) != 1):
			if is_sitting:
				look(Game.movement_events.front())
			else:
				face_and_move(Game.movement_events.front())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("accept") and not is_busy:
		interact()

	if event.is_action_pressed("cancel") and not is_busy:
		open_menu()

func _on_accept_held() -> void:
	if not is_busy:
		# act()
		pass
	else:
		if not Game.cancel_timer.is_stopped():
			Game.accept_timer.start(Game.settings["key_hold_time"])

func _on_cancel_held() -> void:
	if not is_busy:
		equip()
	else:
		if not Game.cancel_timer.is_stopped():
			Game.cancel_timer.start(Game.settings["key_hold_time"])

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
		Game.transition(Game.TRANSITION.FADE_OUT, 0.1)
		await Game.transition_finished
		menu = preload("res://scenes/menu.tscn").instantiate()
		Game.canvas_layer.add_child(menu)
		Game.transition(Game.TRANSITION.FADE_IN, 0.1)
		get_tree().paused = true
	else:
		if Game.cancel_events.front().get_argument_count() > 0:
			Game.cancel_events.front().call(self)
		else:
			Game.cancel_events.front().call()
		Game.cancel_events.pop_front()

func interact() -> void:
	if Game.accept_events.is_empty():
		if not is_sitting and current_pointer:
			for body: Node2D in current_pointer.collisions:
				if body is YumeInteractable:
					body.body_interacted.emit(self)
					body.body_touched.emit(self)
	else:
		if Game.accept_events.front().get_argument_count() > 0:
			Game.accept_events.front().call(self)
		else:
			Game.accept_events.front().call()
		Game.accept_events.pop_front()
