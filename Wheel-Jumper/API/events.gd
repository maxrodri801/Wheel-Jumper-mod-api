extends Node
class_name ModEvents

# Event registry
var event_listeners = {}

# Connect to an event
func connect(event_name: String, callback: Callable, mod_name: String = ""):
    if not event_listeners.has(event_name):
        event_listeners[event_name] = []
    
    event_listeners[event_name].append({
        "callback": callback,
        "mod": mod_name
    })

# Emit an event
func emit_event(event_name: String, data = null):
    if event_listeners.has(event_name):
        for listener in event_listeners[event_name]:
            if listener.callback.is_valid():
                listener.callback.call(data)

# Disconnect all events for a mod
func disconnect_mod(mod_name: String):
    for event_name in event_listeners:
        event_listeners[event_name] = event_listeners[event_name].filter(
            func(listener): return listener.mod != mod_name
        )

# Game Events (these should be emitted by your game)
func emit_player_jump():
    emit_event("player_jump")

func emit_player_land():
    emit_event("player_land")

func emit_coin_collected(coin_value: int):
    emit_event("coin_collected", coin_value)

func emit_obstacle_hit(obstacle_type: String):
    emit_event("obstacle_hit", obstacle_type)

func emit_level_complete(level: int, time: float):
    emit_event("level_complete", {"level": level, "time": time})

func emit_game_paused():
    emit_event("game_paused")

func emit_game_resumed():
    emit_event("game_resumed")
