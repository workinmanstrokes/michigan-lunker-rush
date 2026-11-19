extends Node2D
class_name LunkerFish
## Fish data and behaviour for Michigan Lunker Rush.
##
## Each fish has a species (panfish, largemouth bass, northern pike, or a
## boss), size, fight strength, speed, and coin value. Fish wander the lake,
## can be revealed as silhouettes by the scout drone, bite when a bobber
## lands nearby, then fight during the reeling minigame or escape.

const SPECIES := {
	"panfish": {
		"size_range": Vector2(0.15, 0.35), "fight": 0.6, "speed": 55.0,
		"coins": 10, "aggression": 0.9, "color": Color(0.95, 0.75, 0.3, 1),
	},
	"largemouth_bass": {
		"size_range": Vector2(0.4, 0.9), "fight": 1.0, "speed": 85.0,
		"coins": 25, "aggression": 0.6, "color": Color(0.3, 0.65, 0.35, 1),
	},
	"northern_pike": {
		"size_range": Vector2(0.7, 1.4), "fight": 1.5, "speed": 120.0,
		"coins": 50, "aggression": 0.7, "color": Color(0.45, 0.6, 0.4, 1),
	},
	"boss_lunker": {
		"size_range": Vector2(1.5, 2.2), "fight": 2.2, "speed": 100.0,
		"coins": 150, "aggression": 0.5, "color": Color(0.85, 0.3, 0.3, 1),
	},
}

var species_name: String = "panfish"
var size_kg: float = 0.2
var fight_strength: float = 1.0
var speed: float = 60.0
var coin_value: int = 10
var aggression: float = 0.6
# How hard the fish pulls on the line per second while being reeled in.
var fight_pull: float = 6.0
# Extra reel progress per tap (weaker fish reel in faster).
var reel_bonus: float = 0.0

var _wander_target: Vector2 = Vector2.ZERO
var _fighting: bool = false
var _silhouette: Polygon2D
var _body: Polygon2D


func _ready() -> void:
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-26, 0), Vector2(-12, -12), Vector2(14, -10),
		Vector2(28, 0), Vector2(14, 10), Vector2(-12, 12),
	])
	_body.color = Color(0.2, 0.2, 0.25, 0.0) # hidden until revealed
	add_child(_body)
	_silhouette = Polygon2D.new()
	_silhouette.polygon = _body.polygon
	_silhouette.color = Color(0.05, 0.08, 0.12, 0.0)
	_silhouette.visible = false
	add_child(_silhouette)


func setup_random(spawn_pos: Vector2, weather: String) -> void:
	position = spawn_pos
	var keys: Array = SPECIES.keys()
	species_name = keys[randi() % 3] # v1 spawns panfish, bass, or pike
	var data: Dictionary = SPECIES[species_name]
	var size_range: Vector2 = data["size_range"]
	size_kg = randf_range(size_range.x, size_range.y)
	fight_strength = float(data["fight"])
	speed = float(data["speed"]) * randf_range(0.8, 1.2)
	coin_value = int(data["coins"]) + int(size_kg * 10.0)
	aggression = float(data["aggression"])
	if weather == "rain" and species_name == "northern_pike":
		aggression = min(aggression + 0.3, 1.0)
		speed *= 1.15
	fight_pull = 4.0 * fight_strength
	reel_bonus = 4.0 * (1.0 - clamp(fight_strength / 2.2, 0.0, 1.0))
	var body_color: Color = data["color"]
	_body.color = Color(body_color.r, body_color.g, body_color.b, 0.0)
	scale = Vector2.ONE * (0.7 + size_kg * 0.35)
	_pick_new_target()


func _process(delta: float) -> void:
	if _fighting:
		# Thrashing while hooked: dart side to side near the bobber.
		position += Vector2(sin(Time.get_ticks_msec() / 90.0) * 60.0, cos(Time.get_ticks_msec() / 110.0) * 30.0) * delta
		return
	if position.distance_to(_wander_target) < 12.0:
		_pick_new_target()
	var dir: Vector2 = (_wander_target - position).normalized()
	position += dir * speed * delta
	rotation = lerp_angle(rotation, dir.angle(), 4.0 * delta)


func _pick_new_target() -> void:
	_wander_target = Vector2(randf_range(60.0, 660.0), randf_range(380.0, 1150.0))


func set_silhouette_visible(visible: bool) -> void:
	_silhouette.visible = visible
	_silhouette.color = Color(0.05, 0.08, 0.12, 0.85 if visible else 0.0)


func start_fight() -> void:
	_fighting = true
	set_silhouette_visible(false)


func escape() -> void:
	_fighting = false
	_pick_new_target()
