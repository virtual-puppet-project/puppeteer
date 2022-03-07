class_name ExtensionManager
extends AbstractManager

const Config := {
	"DEFAULT_SEARCH_FOLDER": "resources/extensions",

	"CONFIG_NAME": "config.ini",
	"GENERAL": "General",
	"GENERAL_KEYS": {
		# How the resource will be referred to when loading via RLM
		"NAME": "name"
	},
	"SECTION_KEYS": {
		"TYPE": "type",
		"ENTRYPOINT": "entrypoint"
	}
}

var scan_path := ""

var extensions := {} # Extension name: String -> Extension object: Extension

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("ExtensionManager")

func _setup_class() -> void:
	if not OS.is_debug_build():
		scan_path = "%s/%s" % [OS.get_executable_path().get_base_dir(), Config.DEFAULT_SEARCH_FOLDER]
	else:
		scan_path = "%s/%s" % [ProjectSettings.globalize_path("res://"), Config.DEFAULT_SEARCH_FOLDER]
	
	var result := _scan()
	if result.is_err():
		logger.error(result.to_string())

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _scan() -> Result:
	"""
	Scans the scan_path for folders. For each folder, the resource config file is read and the
	extension is added to the list of known extensions
	
	AVOID CALLING THIS IN USER CODE, this could cause things to crash unexpectedly and without
	an error log. Hence why it's labeled as private. Unexpected crashes are generally due to
	loading/unloading gdnative libraries at runtime but without logs it's hard to tell.
	"""
	var dir := Directory.new()

	if dir.open(scan_path) != OK:
		return Result.err(Error.Code.EXTENSION_MANAGER_RESOURCE_PATH_DOES_NOT_EXIST)

	dir.list_dir_begin(true, true)

	var possible_extensions := []

	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			# The directory that houses the extension
			possible_extensions.append("%s/%s" % [scan_path, file_name])

		file_name = dir.get_next()

	for i in possible_extensions:
		var r := _parse_extension(i)
		if r.is_err():
			logger.error(r.to_string())
			continue

	return Result.ok()

func _parse_extension(path: String) -> Result:
	var file := File.new()

	if file.open("%s/%s" % [path, Config.CONFIG_NAME], File.READ) != OK:
		return Result.err(
			Error.Code.EXTENSION_MANAGER_CONFIG_DOES_NOT_EXIST,
			"%s/%s" % [path, Config.CONFIG_NAME])

	var c := ConfigFile.new()
	if c.parse(file.get_as_text()) != OK:
		return Result.err(Error.Code.EXTENSION_MANAGER_RESOURCE_CONFIG_PARSE_FAILURE, path)

	if not c.has_section(Config.GENERAL):
		return Result.err(Error.Code.EXTENSION_MANAGER_MISSING_GENERAL_SECTION, path)

	var extension_name: String = c.get_value(Config.GENERAL, Config.GENERAL_KEYS.NAME, "")
	if extension_name.empty():
		return Result.err(Error.Code.EXTENSION_MANAGER_MISSING_EXTENSION_NAME, path)

	var ext = Extension.new(path)
	ext.extension_name = extension_name
	
	for i in c.get_sections():
		if i == Config.GENERAL:
			continue
		var r := _parse_extension_section(path, c, i, ext)
		if r.is_err():
			return r
	
	extensions[extension_name] = ext

	return Result.ok()

func _parse_extension_section(path: String, c: ConfigFile, section_name: String, e: Extension) -> Result:
	for key in Config.SECTION_KEYS.keys():
		if not c.has_section_key(section_name, Config.SECTION_KEYS[key]):
			return Result.err(Error.Code.EXTENSION_MANAGER_MISSING_EXTENSION_SECTION_KEY,
				Config.SECTION_KEYS[key])

	var res := e.add_resource(
		section_name,
		c.get_value(section_name, Config.SECTION_KEYS.TYPE).to_lower(),
		"%s/%s" % [path, c.get_value(section_name, Config.SECTION_KEYS.ENTRYPOINT)]
	)
	if res.is_err():
		return res

	return Result.ok()

###############################################################################
# Public functions                                                            #
###############################################################################

func query_extensions_for_type(ext_type: String) -> Array:
	"""
	Gets all extensions of a certain type

	Params:
		ext_type: String - The extension type

	Return:
		Array[ExtensionResource] - All extension resources that match the ext_type
	"""
	var r := []

	for key in extensions.keys():
		var ext_resources: Dictionary = extensions[key].resources
		for inner_key in ext_resources.keys():
			if ext_resources[inner_key].resource_type == ext_type:
				r.append(ext_resources[inner_key])

	return r

func find_in_extensions(query: String) -> Result:
	"""
	Finds a given value in an extension using Godot-style node syntax

	e.g. extension_name/resources/resource_name/resource_entrypoint

	Params:
		query: String - A '/' delimited string containing the path to a Variant

	Return:
		Result[Variant] - The Variant found for the query
	"""
	var split_query := query.strip_edges().lstrip("/").rstrip("/").split("/")

	if split_query.empty():
		return Result.err(Error.Code.EXTENSION_MANAGER_EMPTY_QUERY, query)

	var r := [extensions]

	for key_idx in split_query.size():
		var current_container = r[key_idx]
		var key: String = split_query[key_idx]

		var val

		match typeof(current_container):
			TYPE_ARRAY:
				if key.is_valid_integer():
					val = current_container[int(key)]
			TYPE_DICTIONARY, TYPE_OBJECT:
				val = current_container.get(key)
		
		if val != null:
			r.append(val)
			continue

		return Result.err(Error.Code.EXTENSION_MANAGER_BAD_QUERY, "%s: %s" % [str(split_query), key])
	
	return Result.ok(r.pop_back())

func get_context(extension_name: String) -> Result:
	"""
	Wrapper function for safely getting an extension's context
	"""
	var ext: Extension = extensions.get(extension_name)
	if ext == null:
		return Result.err(Error.Code.EXTENSION_MANAGER_EXTENSION_DOES_NOT_EXIST, extension_name)

	return Result.ok(ext.context)

func load_resource(extension_name: String, rel_res_path: String) -> Result:
	"""
	Wrapper function for safely loading a resource from an extension's context
	"""
	var result := get_context(extension_name)
	if result.is_err():
		return result

	result = result.unwrap().load_resource(rel_res_path)
	if result.is_err():
		return result
	
	return result