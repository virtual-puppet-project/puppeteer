class_name IKCube
extends MeshInstance

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_gui"):
		self.visible = not self.visible

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

