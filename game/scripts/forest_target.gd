extends Area3D
var dungeon:RefCounted
var target_id:=""
var active:=true
var spent:=false
var visual:Node3D

func _ready() -> void:
	collision_layer=4
	collision_mask=0
	var shape=CollisionShape3D.new()
	var sphere=SphereShape3D.new()
	sphere.radius=.65
	shape.shape=sphere
	add_child(shape)

func aim_point() -> Vector3: return global_position

func projectile_hit(kind:String,_reflected:bool=false) -> void:
	if active and not spent and kind in ["arrow","fire_arrow"]: dungeon.hit_target(target_id,kind)

func set_active(value:bool) -> void:
	active=value
	collision_layer=4 if value else 0
	if is_instance_valid(visual): visual.visible=value
