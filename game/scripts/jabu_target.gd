extends Area3D
const Forms=preload("res://scripts/jabu_art.gd")
var dungeon:RefCounted
var target_id:=""
var only_boomerang:=false
var spent:=false
var actor:Node3D
var visual:MeshInstance3D

func _ready() -> void:
	collision_layer=4
	collision_mask=0
	var shape=CollisionShape3D.new()
	var sphere=SphereShape3D.new()
	sphere.radius=.65
	shape.shape=sphere
	add_child(shape)
	visual=Forms.blob(self,Vector3.ZERO,Vector3(.5,.35,.5),Forms.tissue(Color("ded097")))
	Forms.blob(self,Vector3(0,-.17,.20),Vector3(.18,.19,.16),Forms.tissue(Color("69466b")))
	if target_id in dungeon.world.state.jabu_switches: activate(false)

func activate(record:bool=true) -> void:
	if spent: return
	spent=true
	visual.scale.y=.12
	if record: dungeon.hit_switch(target_id)

func projectile_hit(kind:String, _reflected:bool) -> void:
	if kind=="seed" and not only_boomerang: activate()

func boomerang_hit() -> void:
	if is_instance_valid(actor): actor.boomerang_link(self)
	else: activate()
