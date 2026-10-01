extends Node3D

var world: Node3D
var creator: CollisionObject3D
var velocity := Vector3.ZERO
var kind := "seed"
var life := 3.0
var reflected := false
var visual: MeshInstance3D

func _ready() -> void:
	visual=ForestArt.ellipsoid(self,Vector3.ZERO,Vector3.ONE*(.11 if kind=="nut" else .065),Color("af8353") if kind=="nut" else Color("e4c980"))

func _physics_process(delta: float) -> void:
	if not world.player.enabled: return
	life-=delta
	if life<=0:
		queue_free()
		return
	var next=global_position+velocity*delta
	var query=PhysicsRayQueryParameters3D.create(global_position,next,7)
	query.collide_with_areas=true
	query.exclude=[creator.get_rid()] if is_instance_valid(creator) else []
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		var body=hit.collider
		if body==world.player:
			if kind=="nut" and world.can_block(global_position):
				reflected=true
				world.stats.reflections+=1
				var shooter=creator
				creator=world.player
				velocity=(shooter.global_position+Vector3.UP*.8-global_position).normalized()*14.0 if is_instance_valid(shooter) else -velocity
				global_position+=velocity.normalized()*.3
				world.chime(900,.12)
				return
			world.damage_player(1,global_position)
		elif body.has_method("projectile_hit"):
			body.projectile_hit(kind,reflected)
		elif body.has_meta("eye_id"):
			if world.area.begins_with("dodongo_"): world.dodongo.hit_eye(str(body.get_meta("eye_id")))
			else: world.dungeon.hit_eye(str(body.get_meta("eye_id")))
		queue_free()
		return
	global_position=next
	visual.rotate_x(delta*12)
