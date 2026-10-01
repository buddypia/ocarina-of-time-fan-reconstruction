extends Node3D

var world:Node3D
var direction:=Vector3.FORWARD
var origin:=Vector3.ZERO
var mode:="out"
var travelled:=0.0
var reach:=14.0
var anchor:Node3D
var landing:=Vector3.ZERO
var pulling_time:=0.0
var contact_recorded:=false
var head:Node3D
var chain:MeshInstance3D

func _ready() -> void:
	head=load("res://assets/hookshot_head.glb").instantiate()
	add_child(head)
	head.rotation.x=-PI/2
	chain=MeshInstance3D.new()
	var mesh=CylinderMesh.new()
	mesh.top_radius=.011
	mesh.bottom_radius=.011
	mesh.radial_segments=16
	mesh.height=1
	chain.mesh=mesh
	chain.material_override=ForestArt.material(Color("9b9f9e"),.28,.9)
	world.landscape.add_child(chain)
	if direction.length()>.01: look_at(position+direction)

func _physics_process(delta:float) -> void:
	if not is_instance_valid(world.player) or world.state.health<=0:
		cancel()
		return
	if not world.player.enabled: return
	var hand=world.player.position+Vector3.UP*1.20
	if mode=="out":
		var step=minf(delta*24,reach-travelled)
		var next=global_position+direction*step
		var ray=PhysicsRayQueryParameters3D.create(global_position,next,3)
		ray.exclude=[world.player.get_rid()]
		var hit=world.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			if world.verify_mode: print("HOOK FLIGHT HIT ",hit.position," anchor=",hit.collider.has_meta("hook_landing"))
			global_position=hit.position
			if hit.collider.has_meta("hook_landing"):
				anchor=hit.collider
				landing=anchor.get_meta("hook_landing")
				mode="pull"
				world.player.hook_pulling=true
				world.player.rolling=0
				world.chime(700,.12)
			else:
				if hit.collider.has_method("hook_hit"): hit.collider.hook_hit()
				mode="return"
		else:
			global_position=next
			travelled+=step
			if travelled>=reach: mode="return"
	elif mode=="pull":
		pulling_time+=delta
		if pulling_time>5:
			cancel()
			return
		if not is_instance_valid(anchor):
			cancel()
			return
		var offset=landing-world.player.position
		if offset.length()<.18:
			world.player.velocity=Vector3.ZERO
			cancel()
			return
		# A swept capsule, not a position teleport, protects against intervening walls.
		var motion=offset.normalized()*minf(11*delta,offset.length())
		var hit=world.player.move_and_collide(motion)
		if hit:
			if world.verify_mode and not contact_recorded:
				print("HOOK PULL CONTACT ",world.player.position," normal=",hit.get_normal()," destination=",landing)
				contact_recorded=true
			# The chain keeps lifting at a ledge face. Only the unobstructed
			# component is swept again; ceilings and level walls still stop Link.
			if hit.get_normal().y>-.25 and offset.y>.06:
				var lift=Vector3.UP*minf(delta*11,offset.y)
				if world.player.move_and_collide(lift):
					cancel()
					return
			else:
				cancel()
				return
	else:
		global_position=global_position.move_toward(hand,delta*30)
		if global_position.distance_to(hand)<.20:
			cancel()
			return
	var end=global_position
	var offset=end-hand
	chain.position=(hand+end)*.5
	chain.scale.y=maxf(.001,offset.length())
	if offset.length()>.001: chain.basis=Basis(Quaternion(Vector3.UP,offset.normalized())).scaled(Vector3(1,offset.length(),1))

func cancel() -> void:
	if is_instance_valid(world.player): world.player.hook_pulling=false
	if is_instance_valid(chain): chain.queue_free()
	if world.active_hook==self: world.active_hook=null
	queue_free()
