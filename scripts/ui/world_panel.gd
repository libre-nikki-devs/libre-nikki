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

extends HFlowContainer

@onready var depth_label: Label = get_node("DepthContainer/Label")
@onready var world_label: Label = get_node("WorldContainer/Label")

func _ready() -> void:
	var current_scene: Node = get_tree().current_scene

	if current_scene is YumeWorld:
		depth_label.text = current_scene.depth

		if current_scene.pretty_name.is_empty():
			world_label.text = current_scene.name
		else:
			world_label.text = current_scene.pretty_name
