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

extends YumeCharacterState


func _physics_process(delta: float) -> void:
	if character.current_movement_keys.size() <= 0:
		return

	var direction: YumeCharacter.Direction = (
			character.MOVEMENT_KEYS[character.current_movement_keys[-1]])

	# Do not move when calling opposite movement events (e.g. pressing
	# both 'up' and 'down' keys at once).
	if character.current_movement_keys.size() > 1:
		if (direction & character.HORIZONTAL and
				character.MOVEMENT_KEYS[character.current_movement_keys[-2]]
				& character.HORIZONTAL):

			return

		if (direction & character.VERTICAL and
				character.MOVEMENT_KEYS[character.current_movement_keys[-2]]
				& character.VERTICAL):

			return

	if not character.is_sitting:
		if character.facing != direction:
				character.facing = direction

		character.move(direction)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not character.is_busy:
		character.interact()

	if event.is_action_pressed("ui_go_back"):
		if character.is_busy:
			if character.moving:
				if not character.menu_queued:
					character.menu_queued = true
					await character.moved
					Game.open_menu(character.menu_path, { "player": character })
					character.menu_queued = false
		else:
			Game.open_menu(character.menu_path, { "player": character })
