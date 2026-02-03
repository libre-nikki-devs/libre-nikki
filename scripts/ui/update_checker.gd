# Copyright (C) 2026 Libre Nikki Developers.
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

@onready var button := $PanelContainer/VBoxContainer/CenterContainer/Button
@onready var label := $PanelContainer/VBoxContainer/RichTextLabel
@onready var http := $HTTPRequest
@onready var panel_container := $PanelContainer

const RELEASES_API: String = "https://api.github.com/repos/libre-nikki-devs/libre-nikki/releases/latest"

func _ready() -> void:
	http.request(RELEASES_API)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_go_back"):
		var viewport: Viewport = get_viewport()

		if not viewport:
			return

		var focus_owner: Control = viewport.gui_get_focus_owner()

		if focus_owner == button:
			http.cancel_request()
			close()

func _get_focus_grabber() -> Control:
	return button

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json: Variant = null
	var json_string: String = body.get_string_from_utf8()
	button.text = " OK "

	if not json_string.is_empty():
		json = JSON.parse_string(json_string)

	if response_code != 200 or json is not Dictionary:
		label.text = "Failed to check for updates."
		return

	var current_version: String = ProjectSettings.get_setting("application/config/version")
	var latest_version: String = json["tag_name"].lstrip("v")

	if current_version == latest_version:
		label.text = "Libre Nikki is up to date."
	else:
		panel_container.size.x = 320.0
		panel_container.position.x = 0.0
		label.autowrap_mode = TextServer.AutowrapMode.AUTOWRAP_WORD_SMART
		label.text = "Update for Libre Nikki is available:\n%s -> %s\n\nDownload it from:\n[url]https://github.com/libre-nikki-devs/libre-nikki/releases/latest[/url]" % [current_version, latest_version]

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)

func _on_button_pressed() -> void:
	http.cancel_request()
	close()
