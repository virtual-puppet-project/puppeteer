class_name Puppet3DData
extends PuppetData

@export
var position := Vector3.ZERO

## The name of the head bone.
@export
var head_bone := ""
@export
var ik_targets := IKTargets3D.new()

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
