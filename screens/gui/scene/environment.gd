extends VBoxContainer

signal message_received(message: GUIMessage)

const OPTION_KEY := &"common_options:environment_options"

var _logger := Logger.create("Environment")

@onready
var _background_type := %BackgroundType
@onready
var _chromakey_color := %ChromakeyColor

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_background_type.message_received.connect(func(message: GUIMessage) -> void:
		var new_message := message.to_data_update(
			OPTION_KEY,
			"background_mode",
			EnvironmentUtil.background_mode_string_to_enum(message.value)
		)
		if new_message == null:
			_logger.error("Failed to convert {message} to DATA_UPDATE".format({
				message = message
			}))
			return
		
		message_received.emit(new_message)
	)
	
	_chromakey_color.message_received.connect(func(message: GUIMessage) -> void:
		var new_message := message.to_data_update(OPTION_KEY, "background_color", message.value)
		if new_message == null:
			_logger.error("Failed to convert {message} to DATA_UPDATE".format({
				message = message
			}))
			return
		
		message_received.emit(new_message)
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func update(context: Context) -> void:
	var environment: Environment = context.runner_data.common_options.environment_options
	
	_background_type.update_option_button(
		EnvironmentUtil.background_mode_enum_to_string(environment.background_mode),
		EnvironmentUtil.EnvironmentBackground.values()
	)

	_chromakey_color.update_color_picker_button(environment.background_color)