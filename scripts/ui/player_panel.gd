# Copyright (C) 2025 Libre Nikki Developers.
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

@onready var player: YumePlayer = get_tree().get_first_node_in_group("Players")
@onready var player_label: Label = get_node("VBoxContainer/PlayerLabel")
@onready var avatar: AnimatedSprite2D = get_node("AvatarFrame/Avatar")
@onready var effects_label: Label = get_node("VBoxContainer/HBoxContainer/EffectsLabel")
@onready var health_label: Label = get_node("VBoxContainer/HBoxContainer/HealthLabel")

func _ready() -> void:
	if player.equipped_effect == YumePlayer.EFFECT.DEFAULT:
		avatar.animation = "down"
	else:
		avatar.animation = "down" + YumePlayer.EFFECT.find_key(player.equipped_effect).capitalize()

	player_label.text = player.name

	if Game.persistent_data.has("acquired_effects"):
		effects_label.text = "✨: " + str(_count_ones(Game.persistent_data["acquired_effects"])) + "/" + str(YumePlayer.EFFECT.size() - 1)
	else:
		effects_label.text = "✨: 0/" + str(YumePlayer.EFFECT.size() - 1)

	if Game.persistent_data.has("health"):
		health_label.text = "❤️: " + str(Game.persistent_data["health"])
	else:
		health_label.text = "❤️: 0"

func _count_ones(number: int) -> int:
	var ones_count: int = 0

	while number > 0:
		ones_count += number % 2;
		number /= 2;

	return ones_count
