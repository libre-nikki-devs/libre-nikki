extends YumeWorld

@onready var player: YumePlayer = get_node("Sakutsuki")

@onready var duplicates: Node2D = get_node("SubViewport/Duplicates")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	Game.transition_handler.play("fade_in")
	await Game.transition_handler.animation_finished
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_child_entered_tree(node: Node):
	super(node)

	if not node.is_in_group("Duplicate") and not node.is_in_group("SubViewport"):
		match node.get_class():
			"AnimatedSprite2D":
				var instance: AnimatedSprite2D = node.duplicate()
				instance.add_to_group("SubViewport")
				instance.set_script(preload("res://scripts/templates/Node2D/mimic.gd"))
				instance.mimic_properties.append_array(["animation", "frame", "global_position", "sprite_frames", "visible", "z_index"])
				instance.to_mimic = node
				duplicates.add_child.call_deferred(instance)

			"TileMapLayer":
				var instance: TileMapLayer = node.duplicate()
				instance.add_to_group("SubViewport")
				instance.set_script(preload("res://scripts/templates/Node2D/mimic.gd"))
				instance.mimic_properties.append_array(["global_position", "visible", "z_index"])
				instance.collision_enabled = false
				instance.to_mimic = node
				duplicates.add_child.call_deferred(instance)

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
