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

extends HBoxContainer

@onready var player_label: Label = get_node("VBoxContainer/PlayerLabel")
@onready var avatar: AnimatedSprite2D = get_node("AvatarFrame/Avatar")
@onready var effects_label: Label = get_node("VBoxContainer/HBoxContainer/EffectsLabel")
@onready var health_label: Label = get_node("VBoxContainer/HBoxContainer/HealthLabel")

var data: Game.Data = Game.persistent_data


func _ready() -> void:
	var player: YumePlayer = get_node_or_null(data.player_path)

	if player:
		player_label.text = player.name

		if player.equipped_effect == YumePlayer.Effect.DEFAULT:
			avatar.animation = "down"
		else:
			avatar.animation = "down" + YumePlayer.Effect.find_key(
					player.equipped_effect).capitalize()

	else:
		if data.scene_data.has(data.current_scene):
			var player_path: NodePath = data.player_path.slice(2)

			if data.scene_data[data.current_scene].has(player_path):
				var player_properties: Dictionary = (
						data.scene_data[data.current_scene][player_path]
				)

				if player_properties.has(&"name"):
					player_label.text = player_properties[&"name"]

				if player_properties.get(
						&"equipped_effect", 0) == YumePlayer.Effect.DEFAULT:

					avatar.animation = &"down"
				else:
					avatar.animation = &"down" + YumePlayer.Effect.find_key(
							player_properties[&"equipped_effect"]).capitalize()

	var count_ones: Callable = func (n: int) -> int:
		var ones: int = 0

		while n > 0:
			ones += n % 2;
			n /= 2;

		return ones

	effects_label.text = "✨: " + str(count_ones.call(
			data.acquired_effects)) + "/" + str(YumePlayer.Effect.size() - 1)

	health_label.text = "❤️: " + str(data.health)
