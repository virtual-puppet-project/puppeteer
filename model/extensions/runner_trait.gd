class_name RunnerTrait
extends Node

## The logger assigned for this class
var logger: Logger

# TODO this should be stored on the model
var current_model_path := ""

## @type: Dictionary<String, TrackingBackendTrait>
var trackers := {}
var main_tracker: TrackingBackendTrait

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

## DON'T OVERRIDE THIS
func _init(args: Dictionary = {}) -> void:
	_initialize(args)

## DON'T OVERRIDE THIS
func _ready() -> void:
	_setup_logger()

	_pre_setup_scene()
	_setup_scene()
	_post_setup_scene()

	_setup_config()

## DON'T OVERRIDE THIS
func _exit_tree() -> void:
	_teardown()

## DON'T OVERRIDE THIS
func _process(delta: float) -> void:
	_process_step(delta)

## DONT'T OVERRIDE THIS
func _physics_process(delta: float) -> void:
	_physics_step(delta)

func _initialize(_args: Dictionary) -> void:
	pass

## Virtual function that sets up the local logger
func _setup_logger() -> void:
	logger = Logger.new("RunnerTrait")
	logger.info("Using base logger, this is not recommended")

## Virtual function that sets up commonly used config connections
func _setup_config() -> void:
	pass

## Virtual function that sets up the scene
func _pre_setup_scene() -> void:
	pass

## Virtual function that sets up the scene
func _setup_scene() -> void:
	pass

## Virtual function that sets up the scene
func _post_setup_scene() -> void:
	pass

## Virtual function that is run when exiting the SceneTree
func _teardown() -> void:
	AM.save_config_instant()
	
	_generate_preview()

	main_tracker = null
	for tracker in trackers.values():
		if not tracker is TrackingBackendTrait:
			logger.error("Tracker %s does not inherit from TrackingBackendTrait" % str(tracker))
			continue
		tracker.stop_receiver()
	trackers.clear()

## Virtual function that should be overridden instead of `_process`
func _process_step(_delta: float) -> void:
	pass

## Virtual function that should be overridden instead of `_physics_process`
func _physics_step(_delta: float) -> void:
	pass

## Virtual function that takes a screenshot to be used on the runner preview screen
func _generate_preview() -> void:
	var image := get_viewport().get_texture().get_data()
	image.flip_y()

	var dir := Directory.new()
	if not dir.dir_exists(Globals.RUNNER_PREVIEW_DIR_PATH):
		if dir.make_dir_recursive(Globals.RUNNER_PREVIEW_DIR_PATH) != OK:
			logger.error("Unable to create %s, declining to create runner preview" %
				Globals.RUNNER_PREVIEW_DIR_PATH)
			return

	if image.save_png("%s/%s.%s" % [
		Globals.RUNNER_PREVIEW_DIR_PATH,
		name,
		Globals.RUNNER_PREVIEW_FILE_EXT
	]) != OK:
		logger.error("Unable to save image preview")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

## Virtual callback, will not do anything until overridden
##
## @param: value: Variant - The changed value
## @param: signal_name: String - The signal the `value` is associated with
func _on_config_changed(value, signal_name: String) -> void:
	logger.error("Signal %s received with value %s\n_on_config_changed not yet implemented" %
			[signal_name, str(value)])

func _on_event_published(payload: SignalPayload) -> void:
	logger.error("Event published with signal_name %s, not yet implemented" % payload.signal_name)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

static func _normalize_euler(vector: Vector3, position: int) -> Vector3:
	var new_value = vector[position]
	if new_value < 0.0:
		new_value += 360
	
	vector[position] = new_value

	return vector

## Finds all loaders implemented on the Runner along with loaders from plugins
##
## A loader must be in format load_<file_type>(path: String) -> Result. If not,
## things might break.
##
## Implementation note: `get_method_list` returns an array of dicts in format
## ```
## [
##	{
##		"name": String,
##		"args: [
##			{
##				"name": String,
##				"class_name": String,
##				"type": int,
##				"hint": int,
##				"hint_string": String,
##				"usage": int
##			}
##		],
##		"default_args": [
##			"args"
##		],
##		"flags": int,
##		"id": int,
##		"return": {
##			"name": String,
##			"class_name": String,
##			"type": int,
##			"hint_string": String,
##			"usage": int
##		}
##	},
##	...
## ```
func _find_loaders() -> Dictionary:
	var r := {} # File type: String -> Loader method: String

	# Start with Loaders implemented in the current/sub scope
	var object_methods := get_method_list()

	for method_desc in object_methods:
		var split_name: PoolStringArray = method_desc.name.split("_")
		if split_name.size() != 2:
			continue
		if split_name[0] != "load":
			continue
		if method_desc.name == "load_model":
			continue
		
		r[split_name[1]] = method_desc.name
	
	return r

## Tries to load a mode from a given path
##
## Will try and match the model's file extension to all registered loaders
##
## @param: path: String - The absolute path to a model
##
## @return: Result<Variant> - The loaded model
func _try_load_model(path: String) -> Result:
	var file := File.new()
	if not file.file_exists(path):
		return Safely.err(Error.Code.RUNNER_FILE_NOT_FOUND, path)

	var loaders := _find_loaders()
	if loaders.empty():
		return Safely.err(Error.Code.RUNNER_NO_LOADERS_FOUND)

	var file_ext := path.get_extension().to_lower()

	if not loaders.has(file_ext):
		return Safely.err(Error.Code.RUNNER_UNHANDLED_FILE_FORMAT, file_ext)

	var method_name: String = loaders[file_ext]

	logger.info("Loading %s using %s" % [path, method_name])
	
	return(call(method_name, path))

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

## Virtual function for loading a model
##
## @param: path: String - The absolute path to a model
##
## @return: Result - The error code
func load_model(_path: String) -> Result:
	return Result.err(Error.Code.NOT_YET_IMPLEMENTED, "load_model")

## Uses the built-in scene loader to load a PackedScene
##
## @param: path: String - The absolute path to a PackedScene
##
## @return: Result<Variant> - The loaded scene
func load_scn(path: String) -> Result:
	logger.info("Using scn loader")

	var model = load(path)
	if model == null:
		return Safely.err(Error.Code.RUNNER_LOAD_FILE_FAILED)

	var model_instance: Node = model.instance()
	if model_instance == null:
		return Safely.err(Error.Code.RUNNER_LOAD_FILE_FAILED)

	return Safely.ok(model_instance)

## Uses the built-in scene loader to load a PackedScene
##
## @see: `load_scn`
func load_tscn(path: String) -> Result:
	return load_scn(path)
