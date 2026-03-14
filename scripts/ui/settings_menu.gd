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

extends YumeMenu

@onready var licenses_button := $SidePanelContainer/SideVBoxContainer/LicensesButton
@onready var licenses_menu := $MainPanelContainer/LicensesVBoxContainer
@onready var side_menu := $SidePanelContainer/SideVBoxContainer
@onready var main_label := $MainPanelContainer/MainLabel

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_go_back"):
		var viewport: Viewport = get_viewport()

		if not viewport:
			return

		var focus_owner: Control = viewport.gui_get_focus_owner()

		if focus_owner:
			match focus_owner.get_parent():
				licenses_menu:
					main_label.show()
					licenses_menu.hide()
					licenses_button.grab_focus()

				side_menu:
					close()

func _get_focus_grabber() -> Control:
	return licenses_button

func _on_main_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)

func _on_licenses_button_pressed() -> void:
	main_label.hide()
	licenses_menu.show()

	for child: Node in licenses_menu.get_children():
		if child is Button:
			child.grab_focus()
			break

func _on_cc_button_pressed() -> void:
	open_submenu("res://scenes/ui/license_menu.tscn", { "license_text": preload("res://scenes/ui/license_menu.tscn").instantiate().CC_FORMATTED })

func _on_gpl_button_pressed() -> void:
	open_submenu("res://scenes/ui/license_menu.tscn", { "license_text": preload("res://scenes/ui/license_menu.tscn").instantiate().GPL_FORMATTED })

func _on_updates_button_pressed() -> void:
	open_submenu("res://scenes/ui/update_checker.tscn")
