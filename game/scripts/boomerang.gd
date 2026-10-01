extends Node3D
const Forms=preload("res://scripts/jabu_art.gd")
var world:Node3D
var target:Node3D
var start:Vector3
var endpoint:Vector3
var age:=0.0
var returning:=false
var hits:Array=[]
var path:Array[Vector3]=[]
var visual:Node3D
var duration:=.65
var side:=Vector3.ZERO

func _ready() -> void:
	visual=Forms.boomerang(self)
	start=position
	var direction=-world.player.visual.global_basis.z
	endpoint=start+direction*11
	if is_instance_valid(target): endpoint=world.aim_point(target)
	var span=endpoint-start
	duration=clampf(span.length()/17,.2,.85)
	side=-span.normalized().cross(Vector3.UP)*minf(2.2,span.length()*.22)
	path.append(start)

func _physics_process(delta:float) -> void:
	if not world.player.enabled: return
	age+=delta
	visual.rotate_y(delta*26)
	if returning:
		var destination:Vector3=path.back() if not path.is_empty() else world.player.position+Vector3.UP*.95
		position=position.move_toward(destination,delta*21)
		if position.distance_to(destination)<.12:
			if not path.is_empty(): path.pop_back()
			else:
				world.active_boomerang=null
				queue_free()
		return
	if is_instance_valid(target):
		endpoint=start+(world.aim_point(target)-start).limit_length(18)
	var t=minf(1,age/duration)
	var next=start.lerp(endpoint,t)+side*sin(t*PI)
	var query=PhysicsRayQueryParameters3D.create(position,next,7)
	query.collide_with_areas=true
	query.exclude=[world.player.get_rid()]
	for body in hits:
		if is_instance_valid(body): query.exclude.append(body.get_rid())
	var result=get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		var body=result.collider
		if body.has_method("boomerang_hit"):
			body.boomerang_hit()
			hits.append(body)
		else:
			next=result.position
			returning=true
	position=next
	path.append(position)
	if t>=1: returning=true
