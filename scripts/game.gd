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

extends CanvasLayer

## An autoload singleton that handles the game's most important data as well as
## it provides functions specific to Libre Nikki.

enum SCENE_STATES { DEFAULT = 0, PACKED = 1, FROM_FILE = 2 }

const SCREENSHOTS_DIRECTORY: String = "user://screenshots"

const MAPSHOTS_DIRECTORY: String = "user://mapshots"

@onready var mouse_timer: Timer = get_node("MouseTimer")

@onready var music_player: AudioStreamPlayer = get_node("MusicPlayer")

@onready var transition_handler: AnimationPlayer = get_node("TransitionHandler")

var current_scene_state: SCENE_STATES = SCENE_STATES.DEFAULT

var is_current_scene_loaded_from_file: bool = false

var key_hold_time: float = 0.5

## Contains data that are preserved in a save file.
var persistent_data: Dictionary = {}

var scene_data: Dictionary[String, PackedScene] = {}

## Contains settings data.
var settings := ConfigFile.new()

signal scene_changed

func _init() -> void:
	if settings.load("user://settings.ini") == OK:
		if settings.has_section_key("display", "fps_counter"):
			var fps_counter: Variant = settings.get_value(
					"display", "fps_counter", false)

			if fps_counter is bool:
				if fps_counter:
					fps_counter = preload(
							"res://scenes/ui/fps_counter.tscn").instantiate()

					fps_counter.position = Vector2(4.0, 4.0)
					fps_counter.z_index = 2
					add_child(fps_counter)

		if settings.has_section_key("display", "max_fps"):
			var max_fps: Variant = settings.get_value("display", "max_fps", 0)

			if max_fps is int:
				Engine.max_fps = max_fps

		if settings.has_section_key("display", "vsync"):
			var vsync: Variant = settings.get_value("display", "vsync", 1)

			if vsync is int:
				DisplayServer.window_set_vsync_mode(
						vsync as DisplayServer.VSyncMode)

	if OS.is_debug_build():
		var fast_forward_indicator: Control = preload(
				"res://scenes/ui/fast_forward_indicator.tscn").instantiate()

		fast_forward_indicator.position += Vector2(-4.0, 4.0)
		fast_forward_indicator.z_index = 2
		fast_forward_indicator.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		add_child(fast_forward_indicator)

func _ready() -> void:
	_on_scene_changed()
	get_tree().connect("scene_changed", _on_scene_changed)
	get_window().min_size = Vector2i(640, 480)

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse_timer.start(5.0)

	if event.is_action_pressed("screenshot"):
		var screenshot: Image = await take_screenshot()

		if screenshot:
			if not DirAccess.dir_exists_absolute(SCREENSHOTS_DIRECTORY):
				DirAccess.make_dir_absolute(SCREENSHOTS_DIRECTORY)

			screenshot.save_png(SCREENSHOTS_DIRECTORY.path_join(get_timestamp() + ".png"))

func _on_scene_changed() -> void:
	var current_scene: Node = get_tree().current_scene
	var scene_path: String = current_scene.scene_file_path

	var emit_scene_changed: Callable = func ():
		if not current_scene.is_node_ready():
			await current_scene.ready

		scene_changed.emit()

	if scene_path.is_empty():
		scene_path = persistent_data["current_scene"]

		if is_current_scene_loaded_from_file:
			current_scene_state = SCENE_STATES.FROM_FILE
			is_current_scene_loaded_from_file = false
			emit_scene_changed.call()
			return
		else:
			current_scene_state = SCENE_STATES.PACKED
	else:
		persistent_data["current_scene"] = scene_path
		current_scene_state = SCENE_STATES.DEFAULT

	if not persistent_data.has("scene_visits"):
		persistent_data["scene_visits"] = {}

	persistent_data["scene_visits"][scene_path] = persistent_data["scene_visits"].get(scene_path, 0) + 1
	emit_scene_changed.call()

func change_scene(path: String) -> void:
	if not is_current_scene_loaded_from_file:
		persistent_data["entered_from"] = persistent_data["current_scene"]

	if scene_data.has(path):
		get_tree().change_scene_to_packed(scene_data[path])
		persistent_data["current_scene"] = path
		return

	get_tree().change_scene_to_file(path)

func save_current_scene(where: Dictionary = persistent_data) -> void:
	var scene_tree: SceneTree = get_tree()
	var current_scene: Node = scene_tree.current_scene
	var scene_path = current_scene.scene_file_path
	if scene_path == "":
		scene_path = persistent_data["current_scene"]

	for tween: Tween in scene_tree.get_processed_tweens():
		if tween.is_running():
			tween.custom_step(INF)
			tween.kill()

	# Pack `current_scene` to `scene_data` when saving to `persistent_data`.
	if is_same(where, persistent_data):
		scene_data[scene_path] = PackedScene.new()
		scene_data[scene_path].pack(current_scene)

	var get_persistent_nodes: Callable = (
			func (node: Node, _recursion: Callable) -> Array[Node]:
				var nodes: Array[Node] = []

				if node.has_meta("persistent_properties"):
					nodes.append(node)

				for child: Node in node.get_children():
					nodes += _recursion.call(child, _recursion)

				return nodes
	)

	if not where.has("scene_data"):
		where["scene_data"] = {}

	if not where["scene_data"].has(scene_path):
		where["scene_data"][scene_path] = {}

	# Save persistent nodes' properties to `where["scene_data"][scene_path]`.
	for node: Node in get_persistent_nodes.call(
			current_scene, get_persistent_nodes):

		var persistent_properties: Variant = node.get_meta(
				"persistent_properties")

		if persistent_properties is Array:
			var node_path: NodePath = current_scene.get_path_to(node)

			if not where["scene_data"][scene_path].has(node_path):
				where["scene_data"][scene_path][node_path] = {}

			if not where["scene_data"][scene_path][node_path]:
				where["scene_data"][scene_path][node_path] = {}

			for property: Variant in (persistent_properties +
					["scene_file_path"]):

				if property is String:
					if property in node:
						where["scene_data"][scene_path][node_path].set(
								property, node.get(property))

	var original_scene: Node = load(scene_path).instantiate()

	for node: Node in get_persistent_nodes.call(
			original_scene, get_persistent_nodes):

		var node_path: NodePath = original_scene.get_path_to(node)

		# Remove persistent nodes that are in `original_scene`
		# but are not present in `current_scene`.
		if not current_scene.has_node(node_path):
			where["scene_data"][scene_path][node_path] = null

func take_screenshot() -> Image:
	var viewport: Viewport = get_viewport()

	if viewport:
		await RenderingServer.frame_post_draw
		return viewport.get_texture().get_image()

	return null

func take_mapshot(map: YumeWorld) -> Image:
	if not map.bounds.has_area():
		return null

	var viewport: Viewport = get_viewport()

	if not viewport:
		return null

	var camera := Camera2D.new()
	var scene_tree: SceneTree = get_tree()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	camera.position = map.bounds.position
	map.add_child(camera)
	camera.make_current()

	if not scene_tree.paused:
		scene_tree.paused = true
		camera.connect("tree_exited", scene_tree.set_pause.bind(false))

	hide()
	await RenderingServer.frame_post_draw
	var image := Image.create_empty(int(map.bounds.size.x), int(map.bounds.size.y), false, Image.FORMAT_RGBA8)
	var segment_size := Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))

	while (camera.position.y - map.bounds.position.y) < map.bounds.size.y:
		while (camera.position.x - map.bounds.position.x) < map.bounds.size.x:
			await RenderingServer.frame_post_draw
			var segment: Image = viewport.get_texture().get_image()

			if segment:
				image.blit_rect(segment, Rect2i(Vector2.ZERO, segment_size), camera.position - map.bounds.position)

			camera.position.x += segment_size.x

		camera.position.x = map.bounds.position.x
		camera.position.y += segment_size.y

	show()
	camera.free()
	return image

func open_menu(menu_path: String, menu_property_list: Dictionary = {}) -> void:
	var menu: YumeMenu = load(menu_path).instantiate()
	var scene_tree: SceneTree = get_tree()

	if not scene_tree.paused:
		scene_tree.paused = true
		menu.connect("tree_exited", scene_tree.set_pause.bind(false))

	await menu._pre_open()

	for property: String in menu_property_list.keys():
		if property in menu:
			menu.set(property, menu_property_list[property])

	add_child(menu)

## Start the dream session.
func sleep() -> void:
	persistent_data["random"] = RandomNumberGenerator.new().randi_range(0, 255)
	persistent_data["times_slept"] = persistent_data.get("times_slept", 0) + 1
	change_scene("res://scenes/maps/sakutsukis_dream_bedroom.tscn")

## End the dream session.
func wake_up() -> void:
	persistent_data["scene_data"] = {}
	scene_data.clear()
	var scene_tree: SceneTree = get_tree()
	var tween: Tween

	if music_player.playing:
		tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(0.01), 5.0)

	transition_handler.play("pixelate_out")
	scene_tree.paused = true
	await transition_handler.animation_finished
	scene_tree.paused = false
	change_scene("res://scenes/maps/sakutsukis_bedroom.tscn")

	if tween:
		if tween.is_running():
			await tween.finished
			music_player.stop()

func get_timestamp() -> String:
	var date: Dictionary = Time.get_datetime_dict_from_system()

	return str("%d%02d%02d_%02d%02d%02d_%d" % [date.year, date.month, date.day, date.hour, date.minute, date.second, Engine.get_frames_drawn()])

func _on_mouse_timer_timeout() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_playtime_timer_timeout() -> void:
	persistent_data["playtime"] = persistent_data.get("playtime", 0) + 1
