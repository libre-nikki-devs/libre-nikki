extends YumeWorld

@onready var player: YumePlayer = get_node("Sakutsuki")

@onready var parallax_world := $SubViewport/ParallaxWorld

func _init() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func _ready() -> void:
	await Game.scene_changed

	if Game.current_scene_state != Game.SCENE_STATES.FROM_FILE:
		player.facing = YumeCharacter.DIRECTION.DOWN
		player.position = Vector2(424.0, 584.0)

	Game.transition_handler.play("fade_in")
	await Game.transition_handler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_child_entered_tree(node: Node):
	super(node)

	if not node.is_in_group("Duplicate"):
		var node_class: String = node.get_class()

		if node.has_meta("mimic_properties") or default_mimic_data.has(node_class):
			var mimic_properties: Variant = node.get_meta("mimic_properties", [])

			if mimic_properties is not Array:
				mimic_properties = []

			if mimic_properties.is_empty():
				mimic_properties = default_mimic_data.get(node_class, [])

			for property: Variant in mimic_properties:
				if property is not String:
					mimic_properties.erase(property)

			var instance: Node = node.duplicate(0)
			instance.position = node.global_position

			for child: Node in instance.get_children():
				remove_child(child)

			if instance is TileMapLayer:
				var tile_set: TileSet = instance.tile_set
				instance.collision_enabled = false

				if tile_set:
					for source_id: int in tile_set.get_source_count():
						if instance.tile_set.get_source(source_id) is TileSetScenesCollectionSource:
							for cell: Vector2i in instance.get_used_cells_by_id(source_id):
								instance.erase_cell(cell)

			if not mimic_properties.is_empty():
				instance.set_script(preload("res://scripts/templates/Node2D/mimic.gd"))
				instance.mimic_properties.append_array(mimic_properties)
				instance.to_mimic = node

			parallax_world.add_child.call_deferred(instance)

func _on_nexus_door_opened() -> void:
	Game.transition_handler.play("fade_out")
	process_mode = Node.PROCESS_MODE_DISABLED
	await Game.transition_handler.animation_finished
	Game.save_current_scene()
	Game.change_scene("res://scenes/maps/nexus.tscn")

func _on_snowflake_door_opened() -> void:
	Game.transition_handler.play("fade_out")
	process_mode = Node.PROCESS_MODE_DISABLED
	await Game.transition_handler.animation_finished
	player.can_move_in_vacuum = false
	player.collision_layer = 20
	player.collision_mask = 20
	player.facing = YumeCharacter.DIRECTION.DOWN
	player.position = Vector2(2056.0, 376.0)
	player.z_index = 2
	Game.transition_handler.play("fade_in")
	await Game.transition_handler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_upper_door_opened() -> void:
	Game.transition_handler.play("fade_out")
	process_mode = Node.PROCESS_MODE_DISABLED
	await Game.transition_handler.animation_finished
	player.can_move_in_vacuum = true
	player.collision_layer = 2
	player.collision_mask = 2
	player.facing = YumeCharacter.DIRECTION.DOWN
	player.position = Vector2(440.0, 1896.0)
	player.z_index = 1
	Game.transition_handler.play("fade_in")
	await Game.transition_handler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE
