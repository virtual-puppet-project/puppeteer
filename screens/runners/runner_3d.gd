class_name Runner3D
extends Node3D

## A runner for 3D models.

const RenIK: GDScript = preload("res://addons/renik/renik.gd")

## The main camera in use.
@onready
var _camera: RunnerCamera3D = $RunnerCamera3D
## The main light for the runner.
@onready
var _main_light: DirectionalLight3D = $DirectionalLight3D

## The logger for the runner.
var _logger := Logger.create("Runner3D")

## The context. Should always be set during initialization.
var context: Context = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	if context == null:
		_logger.error("No context was found, bailing out of _ready")
		return
	
	var model: Node3D = context.model
	if model is VrmPuppet:
		_setup_vrm(model)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	# TODO testing
	if event.keycode == KEY_0 and event.pressed:
		fly_camera(true)
	elif event.keycode == KEY_1 and event.pressed:
		fly_camera(false)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _setup_vrm(model: VrmPuppet) -> Error:
	var ren_ik: RenIK3D = RenIK.new()
	ren_ik.name = "RenIK3D"
	
	var ik_targets := model.ik_targets_3d
#
	ren_ik.armature_skeleton_path = model.skeleton.get_path()
#
	var armature_targets := Node3D.new()
	armature_targets.name = "ArmatureTargets"
	add_child(armature_targets)
	
	if ik_targets.head != null:
		var marker_offset = Marker3D.new()
		marker_offset.name = "HeadAdjust"
		armature_targets.add_child(marker_offset)
		marker_offset.add_child(ik_targets.head)
		ren_ik.armature_head_target = ik_targets.head.get_path()
	if ik_targets.left_hand != null:
		var target := ik_targets.left_hand
		target.position.y = 0
		target.rotation_degrees.x = 164
		ik_targets.left_hand_starting_transform = target.transform
		var marker_offset = Marker3D.new()
		marker_offset.name = "LeftHandAdjust"
		armature_targets.add_child(marker_offset)
		marker_offset.add_child(target)
		ren_ik.armature_left_hand_target = target.get_path()
	if ik_targets.right_hand != null:
		var target := ik_targets.right_hand
		target.position.y = 0
		target.rotation_degrees.x = 164
		ik_targets.right_hand_starting_transform = target.transform
		var marker_offset = Marker3D.new()
		marker_offset.name = "RightHandAdjust"
		armature_targets.add_child(marker_offset)
		marker_offset.add_child(target)
		ren_ik.armature_right_hand_target = target.get_path()
	if ik_targets.hips != null:
		var marker_offset = Marker3D.new()
		marker_offset.name = "HipsAdjust"
		armature_targets.add_child(marker_offset)
		marker_offset.add_child(ik_targets.hips)
		ren_ik.armature_hip_target = ik_targets.hips.get_path()
	if ik_targets.left_foot != null:
		var marker_offset = Marker3D.new()
		marker_offset.name = "LeftFootAdjust"
		armature_targets.add_child(marker_offset)
		marker_offset.add_child(ik_targets.left_foot)
		ren_ik.armature_left_foot_target = ik_targets.left_foot.get_path()
	if ik_targets.right_foot != null:
		var marker_offset = Marker3D.new()
		marker_offset.name = "RightFootAdjust"
		armature_targets.add_child(marker_offset)
		marker_offset.add_child(ik_targets.right_foot)
		ren_ik.armature_right_foot_target = ik_targets.right_foot.get_path()
	
	add_child(ren_ik)
	ren_ik.live_preview = true
	
	return OK

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Enable/disable a flying camera for inspecting the runner.
func fly_camera(enabled: bool) -> Error:
	const NAME := &"FlyCamera"
	if enabled:
		_logger.info("Enabling fly camera")
		
		var camera := FlyCamera.new()
		camera.name = NAME
		
		add_child(camera)
		camera.make_current()
		
		_camera.display(true)
	else:
		_logger.info("Disabling fly camera")
		
		var camera: Node = get_node_or_null(NodePath(NAME))
		if camera == null:
			_logger.error("Unable to find fly camera")
			return ERR_DOES_NOT_EXIST
		
		_camera.make_current()
		camera.queue_free()
		
		_camera.display(false)
	
	return OK
