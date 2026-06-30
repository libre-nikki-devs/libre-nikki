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

extends Control


@onready var container: Container = $PanelContainer

@onready var difference_label: Label = $Label

@onready var money_label: Label = $PanelContainer/Label

@onready var timer: Timer = $Timer

@onready var _raise_position: float = (
		container.position.y - container.size.y * container.scale.y
)

var _tween: Tween = null


func _ready() -> void:
	money_label.text = str(Game.persistent_data.money) + "♎"


func raise(difference: int):
	var draw_label: Callable

	if Game.persistent_data.money < -difference:
		draw_label = (
				func (diff: int) -> void:
					difference_label.text = str("%+d" % [diff])
					difference_label.modulate.a = 0.5
					difference_label.show()
					await timer.timeout
					difference_label.hide()
		)

		money_label.text = str(Game.persistent_data.money) + "♎"
	else:
		draw_label = (
				func (diff: int) -> void:
					difference_label.hide()

					var label: Label = difference_label.duplicate()
					label.modulate.a = 1.0
					label.text = str("%+d" % [diff])
					label.show()
					add_child(label)

					var tween: Tween = create_tween()
					tween.tween_property(label, "modulate:a", 0.0, 5.0)
					tween.parallel()

					tween.tween_property(label, "position:y",
							-32.0, 5.0).as_relative()

					await tween.finished
					label.queue_free()
		)

		money_label.text = str(Game.persistent_data.money + difference) + "♎"

	draw_label.call(difference)

	if _tween:
		if _tween.is_running():
			_tween.kill()
			_tween = create_tween()

			_tween.tween_property(container, "position:y", _raise_position,
					(_raise_position - container.position.y) /
					_raise_position * 0.5)

			await _tween.finished

	if not timer.is_stopped():
		timer.start()
		return

	_tween = create_tween()
	_tween.tween_property(container, "position:y", _raise_position, 0.5)
	await _tween.finished
	timer.start()
	await timer.timeout
	_tween = create_tween()

	_tween.tween_property(container, "position:y",
			container.size.y * container.scale.y, 0.5).as_relative()
