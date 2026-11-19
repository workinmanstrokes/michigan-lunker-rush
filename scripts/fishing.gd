extends Node2D
## Michigan Lunker Rush — core fishing loop.
##
## States: IDLE -> AIMING -> CAST -> WAITING_BITE -> REELING -> CAUGHT.
## Tap-drag on the water to aim, release to cast. The scout drone reveals
## fish silhouettes for 5 seconds. Once a fish bites, tap rhythmically to
## reel in: tension climbs with each tap and decays over time. Too much
## tension snaps the 15 lb braid; too little and the fish escapes.

const FishScript := preload("res://scripts/fish.gd")

const LINE_BREAK_TENSION := 100.0
const LINE_SLACK_ESCAPE := 0.0
const DRONE_REVEAL_SECONDS := 5.0
const DRONE_COOLDOWN_SECONDS := 12.0
const SAVE_PATH := "user://lunker_rush_save.cfg"

enum State { IDLE, AIMING, CAST, WAITING_BITE, REELING, CAUGHT }

var state: State = State.IDLE
var coins: int = 0
var total_catches: int = 0
var selected_lure: String = "basic_jig"
var unlocked_lures: Array[String] = ["basic_jig"]

var weather: String = "sunny"
var aim_start: Vector2 = Vector2.ZERO
var aim_current: Vector2 = Vector2.ZERO
var cast_target: Vector2 = Vector2.ZERO
var hooked_fish: LunkerFish = null
var tension: float = 40.0
var reel_progress: float = 0.0
var bite_timer: float = 0.0
var drone_timer: float = 0.0
var drone_cooldown: float = 0.0
var fish_list: Array[LunkerFish] = []

@onready var bobber: ColorRect = $Bobber
@onready var hud: CanvasLayer = $HUD
@onready var coins_label: Label = $HUD/CoinsLabel
@onready var weather_label: Label = $HUD/WeatherLabel
@onready var tension_bar: ProgressBar = $HUD/TensionBar
@onready var tension_label: Label = $HUD/TensionLabel
@onready var cast_hint: Label = $HUD/CastHint
@onready var message_label: Label = $HUD/MessageLabel
@onready var drone_button: Button = $HUD/DroneButton
@onready var fish_layer: Node2D = $FishLayer


func _ready() -> void:
	randomize()
	_load_profile()
	_roll_weather()
	_update_hud()
	_spawn_fish(6)
	drone_button.pressed.connect(_on_drone_button_pressed)


func _process(delta: float) -> void:
	if drone_timer > 0.0:
		drone_timer -= delta
		if drone_timer <= 0.0:
			_hide_silhouettes()
	if drone_cooldown > 0.0:
		drone_cooldown -= delta
		drone_button.disabled = drone_cooldown > 0.0
		drone_button.text = "Drone (%ds)" % int(ceil(drone_cooldown)) if drone_cooldown > 0.0 else "Scout Drone"

	match state:
		State.WAITING_BITE:
			bite_timer -= delta
			if bite_timer <= 0.0:
				_start_bite()
		State.REELING:
			# Tension decays when the player is not tapping; the hooked fish
			# also pulls, so tension drifts up while it fights.
			tension = move_toward(tension, 25.0, 18.0 * delta)
			if hooked_fish != null:
				tension += hooked_fish.fight_pull * delta
			tension_bar.value = tension
			if tension >= LINE_BREAK_TENSION:
				_line_snapped()
			elif tension <= LINE_SLACK_ESCAPE and reel_progress < 100.0:
				_fish_escaped()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_press(event.position)
		else:
			_on_release(event.position)
	elif event is InputEventScreenDrag:
		_on_drag(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_press(event.position)
			else:
				_on_release(event.position)
	elif event is InputEventMouseMotion and state == State.AIMING:
		_on_drag(event.position)


func _on_press(pos: Vector2) -> void:
	if state == State.IDLE and pos.y > 330.0:
		state = State.AIMING
		aim_start = pos
		aim_current = pos
		cast_hint.text = "Drag to aim — longer drag, farther cast"
	elif state == State.REELING:
		# Rhythmic tap: each tap reels in and adds tension.
		tension = min(tension + 14.0, LINE_BREAK_TENSION)
		reel_progress += 9.0 + (hooked_fish.reel_bonus if hooked_fish != null else 0.0)
		tension_bar.value = tension
		if reel_progress >= 100.0:
			_land_fish()


func _on_drag(pos: Vector2) -> void:
	if state == State.AIMING:
		aim_current = pos


func _on_release(pos: Vector2) -> void:
	if state != State.AIMING:
		return
	aim_current = pos
	var drag: Vector2 = aim_current - aim_start
	var power: float = clamp(drag.length() / 400.0, 0.15, 1.0)
	# Cast upward into the water, away from the angler at the bottom.
	var direction: Vector2 = Vector2(drag.x, -abs(drag.y)).normalized()
	cast_target = aim_start + direction * (180.0 + power * 420.0)
	cast_target.x = clamp(cast_target.x, 40.0, 680.0)
	cast_target.y = clamp(cast_target.y, 360.0, 1180.0)
	state = State.CAST
	bobber.visible = true
	bobber.position = cast_target
	cast_hint.text = "Waiting for a bite…"
	_start_bite_timer()


func _start_bite_timer() -> void:
	state = State.WAITING_BITE
	var base_wait: float = randf_range(1.5, 4.0)
	var weather_mod: float = {"sunny": 1.0, "cloudy": 0.85, "rain": 0.6}.get(weather, 1.0)
	bite_timer = base_wait * weather_mod


func _start_bite() -> void:
	var nearby: Array[LunkerFish] = []
	for f in fish_list:
		if f.global_position.distance_to(cast_target) < 220.0:
			nearby.append(f)
	if nearby.is_empty():
		message_label.text = "No bite — cast closer to the fish!"
		_reset_to_idle()
		return
	hooked_fish = nearby[randi() % nearby.size()]
	hooked_fish.start_fight()
	state = State.REELING
	tension = 40.0
	reel_progress = 0.0
	tension_bar.visible = true
	tension_label.visible = true
	tension_bar.value = tension
	message_label.text = "Fish on! Tap to reel!"
	cast_hint.text = "Tap rhythmically — don't let tension hit the red!"


func _land_fish() -> void:
	var species: String = hooked_fish.species_name
	var value: int = hooked_fish.coin_value
	coins += value
	total_catches += 1
	state = State.CAUGHT
	message_label.text = "Caught a %s! +%d coins" % [species, value]
	hooked_fish.queue_free()
	fish_list.erase(hooked_fish)
	hooked_fish = null
	_save_profile()
	_update_hud()
	_spawn_fish(1)
	await get_tree().create_timer(2.0).timeout
	_reset_to_idle()


func _line_snapped() -> void:
	state = State.CAUGHT
	message_label.text = "SNAP! The 15 lb braid broke…"
	if hooked_fish != null:
		hooked_fish.escape()
		hooked_fish = null
	await get_tree().create_timer(2.0).timeout
	_reset_to_idle()


func _fish_escaped() -> void:
	state = State.CAUGHT
	message_label.text = "Too slack — the fish got away!"
	if hooked_fish != null:
		hooked_fish.escape()
		hooked_fish = null
	await get_tree().create_timer(2.0).timeout
	_reset_to_idle()


func _reset_to_idle() -> void:
	state = State.IDLE
	bobber.visible = false
	tension_bar.visible = false
	tension_label.visible = false
	message_label.text = ""
	cast_hint.text = "Tap-drag on the water to aim, release to cast"


func _on_drone_button_pressed() -> void:
	if drone_cooldown > 0.0 or state != State.IDLE:
		return
	drone_timer = DRONE_REVEAL_SECONDS
	drone_cooldown = DRONE_COOLDOWN_SECONDS
	_show_silhouettes()
	message_label.text = "Drone up — fish revealed for 5 seconds!"
	await get_tree().create_timer(2.0).timeout
	if state == State.IDLE:
		message_label.text = ""


func _show_silhouettes() -> void:
	for f in fish_list:
		f.set_silhouette_visible(true)


func _hide_silhouettes() -> void:
	for f in fish_list:
		f.set_silhouette_visible(false)


func _spawn_fish(count: int) -> void:
	for i in count:
		var f: LunkerFish = FishScript.new()
		fish_layer.add_child(f)
		f.setup_random(Vector2(randf_range(60.0, 660.0), randf_range(380.0, 1150.0)), weather)
		fish_list.append(f)


func _roll_weather() -> void:
	var roll: float = randf()
	if roll < 0.55:
		weather = "sunny"
	elif roll < 0.85:
		weather = "cloudy"
	else:
		weather = "rain"
	weather_label.text = weather.capitalize()


func _update_hud() -> void:
	coins_label.text = "Coins: %d" % coins


func _load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	coins = int(cfg.get_value("profile", "coins", 0))
	total_catches = int(cfg.get_value("profile", "total_catches", 0))
	selected_lure = str(cfg.get_value("profile", "selected_lure", "basic_jig"))


func _save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "coins", coins)
	cfg.set_value("profile", "total_catches", total_catches)
	cfg.set_value("profile", "selected_lure", selected_lure)
	cfg.save(SAVE_PATH)
