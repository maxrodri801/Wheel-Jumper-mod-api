extends RefCounted
class_name WheelModAPI

# Reference to loader and game
var loader = null
var game = null
var current_mod = ""

# === PUBLIC API FOR MODS ===

# 1. GAME CONTROL
func get_player():
    if game and game.has_node("Player"):
        return game.get_node("Player")
    return null

func get_wheel():
    var player = get_player()
    if player and player.has_node("Wheel"):
        return player.get_node("Wheel")
    return null

func get_game_state():
    return {
        "score": game.score if game else 0,
        "coins": game.coins if game else 0,
        "level": game.current_level if game else 1,
        "time": Time.get_ticks_msec() / 1000.0
    }

# 2. WHEEL MODIFICATION
func set_wheel_speed(multiplier: float):
    var wheel = get_wheel()
    if wheel and wheel.has_method("set_speed_multiplier"):
        wheel.set_speed_multiplier(multiplier)
        return true
    return false

func set_wheel_jump_force(force: float):
    var wheel = get_wheel()
    if wheel and wheel.has_method("set_jump_force"):
        wheel.set_jump_force(force)
        return true
    return false

func set_wheel_gravity(gravity: float):
    var wheel = get_wheel()
    if wheel and wheel.has_method("set_gravity_scale"):
        wheel.set_gravity_scale(gravity)
        return true
    return false

func set_wheel_texture(texture_path: String):
    var wheel = get_wheel()
    if wheel and ResourceLoader.exists(texture_path):
        var texture = load(texture_path)
        wheel.set_texture(texture)
        return true
    return false

# 3. LEVEL MODIFICATION
func spawn_object(type: String, position: Vector2):
    if game and game.has_method("spawn_object"):
        return game.spawn_object(type, position)
    return null

func remove_object(obj):
    if game and game.has_method("remove_object"):
        game.remove_object(obj)

func get_objects_in_range(position: Vector2, radius: float) -> Array:
    if game and game.has_method("get_objects_in_range"):
        return game.get_objects_in_range(position, radius)
    return []

# 4. UI MODIFICATION
func create_ui_element(type: String, parent_path: String = "/root/Game/UI"):
    var parent = get_node(parent_path)
    if not parent:
        return null
    
    match type:
        "label":
            var label = Label.new()
            parent.add_child(label)
            return label
        "button":
            var button = Button.new()
            parent.add_child(button)
            return button
        "panel":
            var panel = Panel.new()
            parent.add_child(panel)
            return panel
        _:
            return null

func show_message(text: String, duration: float = 3.0):
    if game and game.has_method("show_message"):
        game.show_message(text, duration)

# 5. UTILITIES
func get_random(min_val: float, max_val: float) -> float:
    return randf_range(min_val, max_val)

func get_random_int(min_val: int, max_val: int) -> int:
    return randi_range(min_val, max_val)

func create_timer(timeout: float, callback: Callable):
    var timer = Timer.new()
    timer.wait_time = timeout
    timer.one_shot = true
    timer.timeout.connect(callback)
    get_tree().root.add_child(timer)
    timer.start()
    return timer

func load_texture(path: String):
    if FileAccess.file_exists(path):
        return load(path)
    return null

# 6. DATA STORAGE (mod-specific)
func save_data(key: String, value):
    var mod_data = load_mod_data()
    mod_data[current_mod] = mod_data.get(current_mod, {})
    mod_data[current_mod][key] = value
    
    var file = FileAccess.open("user://mod_data.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(mod_data))

func load_data(key: String, default = null):
    var mod_data = load_mod_data()
    if mod_data.has(current_mod) and mod_data[current_mod].has(key):
        return mod_data[current_mod][key]
    return default

func load_mod_data() -> Dictionary:
    var file = FileAccess.open("user://mod_data.json", FileAccess.READ)
    if file:
        return JSON.parse_string(file.get_as_text()) or {}
    return {}

# 7. EVENT SYSTEM ACCESS
func connect_event(event_name: String, callback: Callable):
    if loader and loader.event_bus:
        loader.event_bus.connect(event_name, callback)

func emit_event(event_name: String, data = null):
    if loader and loader.event_bus:
        loader.event_bus.emit_event(event_name, data)

# 8. LOGGING
func log(message: String):
    if loader:
        loader.print_mod("[%s] %s" % [current_mod, message])

func log_error(message: String):
    if loader:
        loader.print_mod("[%s] ERROR: %s" % [current_mod, message], "error")

func log_warning(message: String):
    if loader:
        loader.print_mod("[%s] WARNING: %s" % [current_mod, message], "warning")

# Set current mod for API calls
func _set_current_mod(mod_name: String):
    current_mod = mod_name
