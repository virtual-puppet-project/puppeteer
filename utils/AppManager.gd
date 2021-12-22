extends Node

const DYNAMIC_PHYSICS_BONES: bool = false

# TODO currently unused
# onready var tm: TranslationManager = TranslationManager.new()
onready var sb: SignalBroadcaster = load("res://utils/SignalBroadcaster.gd").new()
onready var cm: ConfigManager = load("res://utils/ConfigManager.gd").new()
var nm: NotificationManager = load("res://utils/NotificationManager.gd").new()
onready var lsm: LipSyncManager = load("res://utils/LipSyncManager.gd").new()
onready var logger: Logger = load("res://utils/Logger.gd").new()

# Debounce
const DEBOUNCE_TIME: float = 5.0
var debounce_counter: float = 0.0
var should_save := false
var config_to_save: Reference

var main: MainScreen
var env: String = "default"

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	self.connect("tree_exiting", self, "_on_tree_exiting")

	# if not OS.is_debug_build():
	# 	save_directory_path = OS.get_executable_path().get_base_dir()
	# else:
	# 	save_directory_path = "res://export"
		# Run unit tests
#		var goth = load("res://addons/goth/GOTH.gd").new()
#		goth.run_unit_tests()
		# goth.run_bdd_tests()

	cm.setup()
	add_child(nm)
	add_child(lsm)

func _process(delta: float) -> void:
	if should_save:
		debounce_counter += delta
		if debounce_counter > DEBOUNCE_TIME:
			debounce_counter = 0.0
			should_save = false
			cm.save_config(config_to_save)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tree_exiting() -> void:
	OpenSeeGd.stop_receiver()

	if env != "tests":
		cm.save_config()
	
	logger.info("Exiting. おやすみ。")

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func save_config(p_config: Reference = null) -> void:
	"""
	Start saving config based off a debounce time
	
	If p_config is null, will save the current config in use
	"""
	should_save = true
	config_to_save = p_config

func save_config_instant(p_config: Reference = null) -> void:
	"""
	Immediately save config and stop debouncing if in progress
	
	If p_config is null, will save the current config in use
	"""
	should_save = false
	debounce_counter = 0.0
	cm.save_config(p_config)


