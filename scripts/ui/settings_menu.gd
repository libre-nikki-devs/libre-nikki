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

@onready var display_button := $SidePanelContainer/SideVBoxContainer/DisplayButton
@onready var display_menu := $MainPanelContainer/DisplayVBoxContainer
@onready var fps_counter_value := $MainPanelContainer/DisplayVBoxContainer/FPSCounterButton/ValueLabel
@onready var vsync_value := $MainPanelContainer/DisplayVBoxContainer/VSyncButton/ValueLabel
@onready var max_fps_value := $MainPanelContainer/DisplayVBoxContainer/MaxFPSButton/ValueLabel
@onready var licenses_button := $SidePanelContainer/SideVBoxContainer/LicensesButton
@onready var licenses_menu := $MainPanelContainer/LicensesVBoxContainer
@onready var side_menu := $SidePanelContainer/SideVBoxContainer
@onready var main_label := $MainPanelContainer/MainLabel

func _ready() -> void:
	var vsync_mode: DisplayServer.VSyncMode = \
		DisplayServer.window_get_vsync_mode()

	if vsync_mode == DisplayServer.VSYNC_DISABLED:
		vsync_value.text = "[OFF] "
	else:
		vsync_value.text = "[ON] "

	var max_fps = Engine.max_fps

	if max_fps == 0:
		max_fps_value.text = "INF "
	else:
		max_fps_value.text = str(max_fps) + " "

	if Game.has_node(^"FPSCounter"):
		fps_counter_value.text = "[ON] "
	else:
		fps_counter_value.text = "[OFF] "

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_go_back"):
		var viewport: Viewport = get_viewport()

		if not viewport:
			return

		var focus_owner: Control = viewport.gui_get_focus_owner()

		if focus_owner:
			match focus_owner.get_parent():
				display_menu:
					Game.settings.save("user://settings.ini")
					main_label.show()
					display_menu.hide()
					licenses_menu.hide()
					display_button.grab_focus()

				licenses_menu:
					main_label.show()
					display_menu.hide()
					licenses_menu.hide()
					licenses_button.grab_focus()

				side_menu:
					close()

func _get_focus_grabber() -> Control:
	return display_button

func _on_main_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)

func _on_display_button_pressed() -> void:
	main_label.hide()
	display_menu.show()
	licenses_menu.hide()

	for child: Node in display_menu.get_children():
		if child is Button:
			child.grab_focus()
			break

func _on_fps_counter_button_pressed() -> void:
	var fps_counter: PanelContainer = Game.get_node_or_null(^"FPSCounter")

	if fps_counter:
		Game.remove_child(fps_counter)
		fps_counter_value.text = "[OFF] "
		Game.settings.set_value("display", "fps_counter", false)
	else:
		fps_counter = preload("res://scenes/ui/fps_counter.tscn").instantiate()
		fps_counter.position = Vector2(4.0, 4.0)
		fps_counter.z_index = 2
		Game.add_child(fps_counter)
		fps_counter_value.text = "[ON] "
		Game.settings.set_value("display", "fps_counter", true)

func _on_v_sync_button_pressed() -> void:
	var vsync_mode: DisplayServer.VSyncMode = \
		DisplayServer.window_get_vsync_mode()

	if vsync_mode == DisplayServer.VSYNC_DISABLED:
		vsync_mode = DisplayServer.VSYNC_ENABLED
		vsync_value.text = "[ON] "
	else:
		vsync_mode = DisplayServer.VSYNC_DISABLED
		vsync_value.text = "[OFF] "

	DisplayServer.window_set_vsync_mode(vsync_mode)
	Game.settings.set_value("display", "vsync", vsync_mode)

func _on_max_fps_button_pressed() -> void:
	const FPS_SETTINGS: Array[int] = [30, 60, 90, 120, 150, 180]
	var max_fps: int = Engine.max_fps
	var fps_set: bool = false

	for setting: int in FPS_SETTINGS:
		if setting > max_fps:
			max_fps = setting
			fps_set = true
			break

	if not fps_set:
		max_fps = 0

	if max_fps == 0:
		max_fps_value.text = "INF "
	else:
		max_fps_value.text = str(max_fps) + " "

	Engine.max_fps = max_fps
	Game.settings.set_value("display", "max_fps", max_fps)

func _on_licenses_button_pressed() -> void:
	main_label.hide()
	display_menu.hide()
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
