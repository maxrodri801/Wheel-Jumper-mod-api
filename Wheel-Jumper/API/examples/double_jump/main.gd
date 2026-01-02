extends Node
class_name DoubleJumpMod

# Mod info
var mod_info = {
    "name": "Double Jump",
    "version": "1.0.0",
    "author": "Wheel Jumper Team",
    "description": "Allows the wheel to jump twice in mid-air!",
    "category": "Gameplay"
}

# References
var api = null
var player = null
var has_double_jumped = false
var original_jump_force = 0.0
var double_jump_force = 600.0

# Required mod methods
func _mod_init():
    api.log("Double Jump mod loading...")
    
    # Get player
    player = api.get_player()
    if player:
        # Store original jump force
        original_jump_force = player.jump_force if player.has("jump_force") else 400.0
        
        # Connect to events
        api.connect_event("player_jump", _on_player_jump)
        api.connect_event("player_land", _on_player_land)
        
        api.log("Ready! Press jump twice in air for double jump!")
    else:
        api.log_error("Player not found!")

func _connect_events(event_bus):
    # Already connected via API
    pass

func _mod_disable():
    # Restore original jump force
    if player and player.has("jump_force"):
        player.jump_force = original_jump_force
    
    api.log("Double Jump disabled")

func _mod_exit():
    api.log("Double Jump mod exiting")

# Event handlers
func _on_player_jump():
    if player and player.is_on_floor():
        has_double_jumped = false
    else:
        if not has_double_jumped:
            # Allow double jump
            has_double_jumped = true
            api.create_timer(0.1, _enable_double_jump)

func _on_player_land():
    has_double_jumped = false

func _enable_double_jump():
    if player and has_double_jumped:
        # Apply double jump force
        player.jump_force = double_jump_force
        api.create_timer(0.1, _reset_jump_force)
        
        # Visual effect
        api.emit_event("double_jump_used")

func _reset_jump_force():
    if player:
        player.jump_force = original_jump_force

# Optional: Mod configuration UI
func get_mod_info():
    return mod_info
