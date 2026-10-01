extends Node3D
var world:Node3D
var velocity:=Vector3.ZERO
var life:=2.5
var burning:=false

func _ready() -> void:
	var model=load("res://assets/arrow.glb").instantiate()
	model.rotation.x=-PI/2
	add_child(model)

func _physics_process(delta:float) -> void:
	if not world.player.enabled: return
	life-=delta
	if life<=0:
		queue_free()
		return
	var next=position+velocity*delta
	if not burning and world.area=="ft_frozen" and Geometry3D.get_closest_point_to_segment(Vector3(0,3.3,0),position,next).distance_to(Vector3(0,3.3,0))<.30:
		burning=true
		var flame=preload("res://scripts/grave_art.gd").sphere(self,Vector3(0,0,-.3),Vector3(.07,.07,.22),Color("ffe0a0"))
		var material=flame.material_override.duplicate()
		material.emission_enabled=true;material.emission=Color("ffba57");material.emission_energy_multiplier=2
		flame.material_override=material
		var light=OmniLight3D.new();light.light_color=Color("ffc071");light.omni_range=2;add_child(light)
	var query=PhysicsRayQueryParameters3D.create(position,next,7)
	query.collide_with_areas=true
	query.exclude=[world.player.get_rid()]
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		if hit.collider.has_method("projectile_hit"): hit.collider.projectile_hit("fire_arrow" if burning else "arrow",false)
		queue_free()
		return
	position=next
	look_at(position+velocity)
	velocity.y-=delta*3
