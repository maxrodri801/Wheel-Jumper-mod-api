extends Node
class_name WheelModLoader

# Colors for console output
const MOD_COLORS = {
    "info": "#4ECDC4",
    "error": "#FF6B6B", 
    "warning": "#FFD166",
    "success": "#06D6A0"
}

# Registry
var loaded_mods = {}        # {mod_name: mod_instance}
var mod_files = {}          # {mod_name: file_path}
var mod_enabled = {}        # {mod_name: bool}

# API instance
var mod_api = null
var event_bus = null

# UI for mod management
var mod_menu = null
var mod_list_ui = null

func _ready():
    print_mod("[Wheel Mod Loader] Initializing...")
    
    # Create API instance
    mod_api = WheelModAPI.new()
    mod_api.loader = self
    mod_api.game = get_node("/root/Game")  # Adjust based on your game structure
    
    # Create event bus
    event_bus = ModEvents.new()
    add_child(event_bus)
    
    # Load all mods automatically
    if not Engine.is_editor_hint():
        call_deferred("load_all_mods")
    
    print_mod("Ready! Place mods in: user://mods/", "success")

# Load all mods from the mods folder
func load_all_mods():
    var mod_dirs = [
        "res://mods/",           # Built-in mods
        "user://mods/",          # User mods (save location)
        "user://mods_disabled/"  # Disabled mods
    ]
    
    for dir_path in mod_dirs:
        load_mods_from_directory(dir_path)
    
    # Call mod initialization
    initialize_all_mods()
    
    # Save enabled/disabled state
    save_mod_states()

# Load mods from a specific directory
func load_mods_from_directory(dir_path: String):
    var dir = DirAccess.open(dir_path)
    if not dir:
        print_mod("Directory not found: " + dir_path, "warning")
        return
    
    print_mod("Scanning: " + dir_path)
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if file_name.ends_with(".gd") and not file_name.begins_with("_"):
            var full_path = dir_path + file_name
            load_single_mod(full_path)
        file_name = dir.get_next()

# Load a single mod file
func load_single_mod(mod_path: String):
    var mod_name = mod_path.get_file().get_basename()
    
    # Skip if already loaded
    if loaded_mods.has(mod_name):
        print_mod("Skipping (already loaded): " + mod_name, "warning")
        return
    
    print_mod("Loading: " + mod_name + " from " + mod_path)
    
    # Load the script
    var script = load(mod_path)
    if not script:
        print_mod("Failed to load script: " + mod_path, "error")
        return
    
    # Create mod instance
    var mod_instance = script.new()
    
    # Check if it's a valid mod
    if not mod_instance.has_method("_mod_init"):
        print_mod("Invalid mod (missing _mod_init): " + mod_name, "error")
        return
    
    # Store mod
    loaded_mods[mod_name] = mod_instance
    mod_files[mod_name] = mod_path
    mod_enabled[mod_name] = true
    
    # Store mod name in instance
    mod_instance.mod_name = mod_name
    mod_instance.mod_path = mod_path
    
    print_mod("✓ Loaded: " + mod_name, "success")

# Initialize all loaded mods
func initialize_all_mods():
    for mod_name in loaded_mods:
        if mod_enabled.get(mod_name, false):
            initialize_mod(mod_name)

# Initialize a single mod
func initialize_mod(mod_name: String):
    var mod = loaded_mods[mod_name]
    
    # Give mod access to API
    if mod.has_method("_set_api"):
        mod._set_api(mod_api)
    
    # Initialize mod
    if mod.has_method("_mod_init"):
        print_mod("Initializing: " + mod_name)
        mod._mod_init()
    
    # Connect to event bus if mod wants events
    if mod.has_method("_connect_events"):
        mod._connect_events(event_bus)

# Enable/disable mod at runtime
func set_mod_enabled(mod_name: String, enabled: bool):
    if not loaded_mods.has(mod_name):
        print_mod("Mod not found: " + mod_name, "error")
        return
    
    mod_enabled[mod_name] = enabled
    
    if enabled:
        print_mod("Enabling: " + mod_name, "success")
        initialize_mod(mod_name)
    else:
        print_mod("Disabling: " + mod_name, "warning")
        disable_mod(mod_name)
    
    save_mod_states()

# Disable a mod
func disable_mod(mod_name: String):
    var mod = loaded_mods[mod_name]
    if mod.has_method("_mod_disable"):
        mod._mod_disable()
    
    # Disconnect from events
    if event_bus:
        event_bus.disconnect_mod(mod_name)

# Reload a mod (for development)
func reload_mod(mod_name: String):
    if not loaded_mods.has(mod_name):
        return
    
    disable_mod(mod_name)
    
    var mod_path = mod_files[mod_name]
    var script = load(mod_path)
    
    if script:
        loaded_mods[mod_name] = script.new()
        if mod_enabled[mod_name]:
            initialize_mod(mod_name)

# Call a function in a mod
func call_mod_function(mod_name: String, function: String, args: Array = []):
    if not loaded_mods.has(mod_name):
        return null
    
    var mod = loaded_mods[mod_name]
    if mod.has_method(function):
        return mod.callv(function, args)
    
    return null

# Get list of all mods
func get_mod_list() -> Array:
    return loaded_mods.keys()

# Get mod info
func get_mod_info(mod_name: String) -> Dictionary:
    var mod = loaded_mods.get(mod_name)
    if mod and mod.has_method("get_mod_info"):
        return mod.get_mod_info()
    
    return {
        "name": mod_name,
        "enabled": mod_enabled.get(mod_name, false),
        "path": mod_files.get(mod_name, "")
    }

# Save mod states to config
func save_mod_states():
    var config = {}
    for mod_name in mod_enabled:
        config[mod_name] = mod_enabled[mod_name]
    
    var file = FileAccess.open("user://mod_settings.cfg", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(config))

# Load mod states from config
func load_mod_states():
    var file = FileAccess.open("user://mod_settings.cfg", FileAccess.READ)
    if file:
        var config = JSON.parse_string(file.get_as_text())
        if config is Dictionary:
            mod_enabled = config

# Helper for colored console output
func print_mod(message: String, type: String = "info"):
    var color = MOD_COLORS.get(type, "#FFFFFF")
    print_rich("[color=%s][ModLoader][/color] %s" % [color, message])

# Cleanup
func _exit_tree():
    for mod_name in loaded_mods:
        var mod = loaded_mods[mod_name]
        if mod.has_method("_mod_exit"):
            mod._mod_exit()
