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

const SCREENSHOTS_DIRECTORY: String = "user://screenshots"

@onready var mouse_timer: Timer = get_node("MouseTimer")

@onready var music_player: AudioStreamPlayer = get_node("MusicPlayer")

@onready var transition_handler: AnimationPlayer = get_node("TransitionHandler")

## Contains data that are preserved in a save file.
var persistent_data: Dictionary = {}

## Contains settings data.
var settings: Dictionary = {
	"key_hold_time" = 0.5
}

func _ready() -> void:
	_on_scene_changed()
	get_tree().connect("scene_changed", _on_scene_changed)
	get_window().min_size = Vector2i(640, 480)
	_count_playtime()

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse_timer.start(5.0)

	if event.is_action_pressed("screenshot"):
		var screenshot: Image = await take_screenshot()

		if screenshot:
			if not DirAccess.dir_exists_absolute(SCREENSHOTS_DIRECTORY):
				DirAccess.make_dir_absolute(SCREENSHOTS_DIRECTORY)

			var date: Dictionary = Time.get_datetime_dict_from_system()
			var process_frames: int = Engine.get_process_frames()
			screenshot.save_png(SCREENSHOTS_DIRECTORY.path_join(str("%d%02d%02d_%02d%02d%02d_%d.png" % [date.year, date.month, date.day, date.hour, date.minute, date.second, process_frames])))

func _on_scene_changed() -> void:
	var scene_path: String = get_tree().current_scene.scene_file_path

	if scene_path.is_empty():
		scene_path = persistent_data["current_scene"]
	else:
		persistent_data["current_scene"] = scene_path

	if not persistent_data.has("scene_visits"):
		persistent_data["scene_visits"] = {}

	if persistent_data["scene_visits"].has(scene_path):
		persistent_data["scene_visits"][scene_path] += 1
	else:
		persistent_data["scene_visits"][scene_path] = 1

func _count_playtime() -> void:
	while true:
		await get_tree().create_timer(1.0, false, true).timeout

		if persistent_data.has("playtime"):
			persistent_data["playtime"] += 1
		else:
			persistent_data["playtime"] = 0

func change_scene(path: String) -> void:
	persistent_data["entered_from"] = persistent_data["current_scene"]

	if persistent_data.has("scene_data"):
		if persistent_data["scene_data"].has(path):
			get_tree().change_scene_to_packed(persistent_data["scene_data"][path])
			persistent_data["current_scene"] = path
			return

	get_tree().change_scene_to_file(path)

func save_current_scene() -> void:
	var scene_tree: SceneTree = get_tree()
	var current_scene: Node = scene_tree.current_scene
	var scene_path = current_scene.scene_file_path
	if scene_path == "":
		scene_path = persistent_data["current_scene"]

	for tween: Tween in scene_tree.get_processed_tweens():
		if tween.is_running():
			tween.custom_step(INF)
			tween.kill()

	if not persistent_data.has("scene_data"):
		persistent_data["scene_data"] = {}
	
	persistent_data["scene_data"][scene_path] = PackedScene.new()
	persistent_data["scene_data"][scene_path].pack(current_scene)

func save_player_data(player: YumePlayer, player_properties: Array[String] = ["accept_events", "cancel_events", "equipped_effect", "facing", "last_step", "name", "speed"]) -> void:
	if player:
		persistent_data["player_data"] = {}

		for property: String in player_properties:
			if property in player:
				persistent_data["player_data"][property] = player.get(property)

func play_sound(sound: AudioStream, parent: Node2D, distance: int = 256, pitch: float = 1.0, volume_offset: float = 0.0) -> void:
	if sound:
		var audio_stream_player = AudioStreamPlayer2D.new()
		audio_stream_player.attenuation = 2.0
		audio_stream_player.autoplay = true
		audio_stream_player.bus = "SFX"
		audio_stream_player.max_distance = distance
		audio_stream_player.pitch_scale = pitch
		audio_stream_player.process_mode = Node.PROCESS_MODE_ALWAYS
		audio_stream_player.stream = sound
		audio_stream_player.volume_db = linear_to_db(1.0 + volume_offset)
		parent.add_child(audio_stream_player)
		await audio_stream_player.finished
		audio_stream_player.queue_free()

func play_sound_everywhere(sound: AudioStream, pitch: float = 1.0, volume_offset: float = 0.0) -> void:
	if sound:
		var audio_stream_player = AudioStreamPlayer.new()
		audio_stream_player.autoplay = true
		audio_stream_player.bus = "SFX"
		audio_stream_player.pitch_scale = pitch
		audio_stream_player.stream = sound
		audio_stream_player.volume_db = linear_to_db(1.0 + volume_offset)
		add_child(audio_stream_player)
		await audio_stream_player.finished
		audio_stream_player.queue_free()

func take_screenshot() -> Image:
	var viewport: Viewport = get_viewport()

	if viewport:
		await RenderingServer.frame_post_draw
		return viewport.get_texture().get_image()

	return null

func open_menu(menu_path: String, menu_property_list: Dictionary = {}) -> void:
	var menu: YumeMenu = load(menu_path).instantiate()
	var scene_tree: SceneTree = get_tree()

	if scene_tree:
		if not scene_tree.paused:
			scene_tree.paused = true
			menu.connect("tree_exited", _on_menu_tree_exited)

	await menu._pre_open()

	for property: String in menu_property_list.keys():
		if property in menu:
			menu.set(property, menu_property_list[property])

	add_child(menu)

## Start the dream session.
func sleep() -> void:
	persistent_data["random"] = RandomNumberGenerator.new().randi_range(0, 255)

	if not persistent_data.has("times_slept"):
		persistent_data["times_slept"] = 1
	else:
		persistent_data["times_slept"] += 1

	change_scene("res://scenes/maps/sakutsukis_dream_bedroom.tscn")

## End the dream session.
func wake_up() -> void:
	persistent_data["player_data"] = {}
	persistent_data["scene_data"] = {}
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

func _on_mouse_timer_timeout() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_menu_tree_exited() -> void:
	var scene_tree: SceneTree = get_tree()

	if scene_tree:
		scene_tree.paused = false
