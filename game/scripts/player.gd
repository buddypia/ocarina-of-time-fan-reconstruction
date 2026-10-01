extends CharacterBody3D

var adult_model:=false
var collider:CollisionShape3D
var visual: Node3D
var camera: Camera3D
var yaw := 0.0
var roll_direction := Vector3.FORWARD
var rolling := 0.0
var attacking := 0.0
var enabled := true
var skeleton: Skeleton3D
var animator: AnimationPlayer
var sockets: Dictionary = {}
var current_motion := ""
var sword: Node3D
var scabbard: Node3D
var shield: Node3D
var distance_walked := 0.0
var lock_target:Node3D
var climbing:=false
var climb_base:=Vector3.ZERO
var climb_top:=Vector3.ZERO
var fall_speed:=0.0
var knockback:=Vector3.ZERO
var invulnerable:=0.0
var sling:Node3D
var stick:Node3D
var arm_band:Node3D
var swimming:=false
var air:=8.0
var forced_surface:=false
var hook_pulling:=false
var hook_gun:Node3D
var dread_time:=0.0
var bow:Node3D
var bow_strings:Array=[]
var held_arrow:Node3D
var climb_exit:=Vector3(0,0,.6)

func _ready() -> void:
	collision_mask=3
	floor_snap_length=.25
	var shape := CapsuleShape3D.new()
	shape.radius = .25
	shape.height = 1.40
	var col := CollisionShape3D.new()
	collider=col
	col.shape = shape
	col.position.y = .70
	add_child(col)
	visual = Node3D.new()
	add_child(visual)
	build_model()
	camera = Camera3D.new()
	get_parent().add_child(camera)
	camera.fov = 62
	camera.far = 180
	camera.current = true
	update_motion(0.0,0.0)
	update_camera(1.0)

func build_model() -> void:
	var model:Node3D=load("res://assets/link_adult.glb" if adult_model else "res://assets/link_anatomical.glb").instantiate()
	visual.add_child(model)
	model.rotation.y=PI
	skeleton=model.find_child("Skeleton3D",true,false)
	animator=model.find_child("AnimationPlayer",true,false)
	animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in animator.get_animation_list():
		animator.get_animation(clip).loop_mode=Animation.LOOP_NONE if clip=="Attack" else Animation.LOOP_LINEAR
	for pair in [["right","wrist.R"],["left","wrist.L"],["back","spine03"],["forearm","lowerarm02.R"]]:
		var attachment=BoneAttachment3D.new()
		attachment.bone_name=pair[1]
		skeleton.add_child(attachment)
		var socket=Node3D.new()
		attachment.add_child(socket)
		# Keep each socket in the model's rest axes; the parent supplies bone motion.
		socket.basis=skeleton.get_bone_global_rest(skeleton.find_bone(pair[1])).basis.inverse()
		sockets[pair[0]]=socket
	sword=load("res://assets/master_sword.glb" if adult_model else "res://assets/kokiri_sword.glb").instantiate()
	visual.add_child(sword)
	shield=load("res://assets/hylian_shield.glb" if adult_model else "res://assets/deku_shield.glb").instantiate()
	visual.add_child(shield)
	scabbard=load("res://assets/master_scabbard.glb" if adult_model else "res://assets/kokiri_scabbard.glb").instantiate()
	sockets.back.add_child(scabbard)
	scabbard.position=Vector3(-.16,.18,-.085)
	scabbard.rotation=Vector3(0,0,2.65)
	arm_band=ForestArt.cylinder(visual,Vector3.ZERO,.041,.039,.055,Color("c3943f"),64)
	arm_band.reparent(sockets.forearm,false)
	arm_band.position=Vector3(0,-.01,.005)
	arm_band.basis=Basis(Quaternion(Vector3.UP,skeleton.get_bone_global_rest(skeleton.find_bone("lowerarm02.R")).basis.y.normalized()))
	arm_band.hide()
	sling=Node3D.new()
	visual.add_child(sling)
	sling.position=Vector3(.3,.9,-.25)
	for end in [Vector3(-.12,.25,0),Vector3(.12,.25,0)]: ForestArt.beam(sling,Vector3.ZERO,end,.025,Color("a78453"))
	ForestArt.beam(sling,Vector3(-.12,.25,0),Vector3(.12,.25,0),.009,Color("c1b991"))
	sling.reparent(sockets.left,false)
	sling.position=Vector3(.015,-.04,.06)
	sling.hide()
	stick=Node3D.new()
	visual.add_child(stick)
	stick.position=Vector3(.4,.75,-.2)
	ForestArt.beam(stick,Vector3.ZERO,Vector3(0,.7,0),.035,Color("a08250"))
	ForestArt.ellipsoid(stick,Vector3(0,.8,0),Vector3(.10,.22,.10),Color("f6bf57"))
	stick.reparent(sockets.right,false)
	stick.position=Vector3(-.015,-.04,.06)
	stick.hide()
	hook_gun=load("res://assets/hookshot.glb").instantiate()
	sockets.right.add_child(hook_gun)
	hook_gun.position=Vector3(-.015,-.04,.06)
	hook_gun.rotation.x=-PI/2
	hook_gun.hide()
	bow=load("res://assets/fairy_bow.glb").instantiate()
	sockets.left.add_child(bow)
	bow.position=Vector3(.015,-.04,.06)
	bow.find_child("Bowstring",true,false).hide()
	bow_strings=[]
	for i in range(2):
		var string_mesh=CylinderMesh.new()
		string_mesh.top_radius=.0022;string_mesh.bottom_radius=.0022;string_mesh.height=1;string_mesh.radial_segments=16
		var segment=MeshInstance3D.new();segment.mesh=string_mesh
		segment.material_override=ForestArt.material(Color("ae9e78"),.85)
		bow.add_child(segment);bow_strings.append(segment)
	held_arrow=load("res://assets/arrow.glb").instantiate()
	bow.add_child(held_arrow);held_arrow.hide()
	bow.hide()

func set_age(adult:bool) -> void:
	if adult_model==adult: return
	adult_model=adult
	for child in visual.get_children():
		visual.remove_child(child)
		child.queue_free()
	sockets={}
	current_motion=""
	var height=1.73 if adult else 1.40
	collider.shape.height=height
	collider.shape.radius=.28 if adult else .25
	collider.position.y=height*.5
	rolling=0
	attacking=0
	build_model()
	update_motion(0,0)

func _physics_process(delta: float) -> void:
	if not enabled:
		velocity = Vector3.ZERO
		update_camera(delta)
		return
	invulnerable=maxf(0,invulnerable-delta)
	dread_time=maxf(0,dread_time-delta)
	if hook_pulling:
		velocity=Vector3.ZERO
		update_motion(delta,0)
		update_camera(delta)
		return
	knockback=knockback.move_toward(Vector3.ZERO,delta*12)
	var water:Dictionary=get_parent().water_at(position)
	swimming=not water.is_empty() and position.y<float(water.height)-.25
	if climbing:
		velocity=Vector3.ZERO
		position.y=clampf(position.y+Input.get_axis("back","forward")*delta*2.8,climb_base.y,climb_top.y+.1)
		update_motion(delta,absf(Input.get_axis("back","forward"))*2.8)
		if position.y>=climb_top.y or Input.is_action_just_pressed("roll"):
			climbing=false
			position+=climb_exit
		update_camera(delta)
		return
	if is_instance_valid(lock_target):
		var offset=lock_target.global_position-global_position
		yaw=lerp_angle(yaw,atan2(-offset.x,-offset.z),minf(1,delta*9))
	yaw += Input.get_axis("camera_left", "camera_right") * delta * 1.8
	var axis := Input.get_vector("left","right","forward","back")
	var direction := Vector3(axis.x,0,axis.y).rotated(Vector3.UP,yaw)
	var speed := 4.4
	if dread_time>0: speed=1.1
	if get_parent().bow_draw>0: speed=1.6
	if is_instance_valid(get_parent().active_hook): speed=0
	rolling = maxf(0,rolling-delta)
	attacking = maxf(0,attacking-delta)
	if Input.is_action_just_pressed("roll") and is_on_floor() and not swimming and not is_instance_valid(get_parent().carried_person):
		rolling = .5
		roll_direction=direction.normalized() if direction.length()>.1 else Vector3.FORWARD.rotated(Vector3.UP,visual.rotation.y)
	if rolling > 0:
		speed = 7.4
		direction=roll_direction
	if Input.is_action_pressed("shield") and shield.visible: speed = 1.8
	if is_instance_valid(get_parent().held_bomb) or is_instance_valid(get_parent().carried_person): speed=3.1
	if swimming:
		speed=2.8
		rolling=0
	velocity.x = move_toward(velocity.x,direction.x*speed+knockback.x,delta*30)
	velocity.z = move_toward(velocity.z,direction.z*speed+knockback.z,delta*30)
	if swimming:
		var submerged=position.y<float(water.height)-1.2
		if submerged: air=maxf(0,air-delta)
		else:
			air=minf(8,air+delta*4)
			if not Input.is_action_pressed("roll"): forced_surface=false
		if air<=0:
			forced_surface=true
			get_parent().damage_player(1,position+Vector3.DOWN,false)
			air=2.0
		var depth=6.0 if get_parent().state.silver_scale else 2.5
		var diving=Input.is_action_pressed("roll") and not forced_surface
		var level=float(water.height)-(depth if diving else .78)
		velocity.y=clampf((level-position.y)*4,-2.6,3.4)
		velocity+=water.get("current",Vector3.ZERO)*delta*2
	else:
		air=minf(8,air+delta*4)
		forced_surface=false
		if not is_on_floor(): velocity.y -= 18*delta
		else: velocity.y = -.2
	var previous := position
	fall_speed=velocity.y
	move_and_slide()
	distance_walked += Vector2(position.x-previous.x,position.z-previous.z).length()
	if is_instance_valid(lock_target): visual.rotation.y=yaw
	elif direction.length() > .05:
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),minf(1,delta*13))
	var moving := Vector2(velocity.x,velocity.z).length()
	update_motion(delta,moving)
	if position.y < -25: get_parent().fall_recover()
	update_camera(delta)

func update_motion(delta:float, moving:float) -> void:
	var carrying=is_instance_valid(get_parent().held_bomb) or is_instance_valid(get_parent().carried_person)
	var defending=Input.is_action_pressed("shield") and shield.visible and not swimming and not carrying
	var motion="Idle"
	var rate=1.0
	if moving>.15:
		motion="Walk"
		rate=clampf(moving/2.5,.45,1.9)
	if defending: motion="Shield"
	if sling.visible or bow.visible: motion="Shoot"
	if is_instance_valid(get_parent().active_hook): motion="Shoot"
	if carrying:
		motion="Carry" if moving>.15 else "CarryIdle"
		rate=clampf(moving/2.5,.4,1.5) if moving>.15 else 1.0
	if attacking>0:
		motion="Attack"
		rate=animator.get_animation("Attack").length/.4
	if rolling>0: motion="Roll"
	if swimming: motion="Swim"
	if climbing:
		motion="Climb"
		rate=clampf(moving/2.8,0,1)
	if motion!=current_motion:
		var blend=.06 if motion in ["Attack","Roll"] else .14
		# A stopped climb must adopt its first cling pose without a stalled blend.
		if is_zero_approx(rate): blend=0
		animator.play(motion,blend)
		current_motion=motion
	animator.speed_scale=rate
	animator.advance(delta)
	visual.position=Vector3.ZERO
	visual.rotation.x=0
	if swimming:
		visual.rotation.x=-1.12
		visual.position=Vector3(0,.43,.35).rotated(Vector3.UP,visual.rotation.y)
	elif rolling>0:
		var angle=(.5-rolling)/.5*TAU
		visual.rotation.x=-angle
		visual.position=Vector3(0,.65*(1-cos(angle)),.65*sin(angle)).rotated(Vector3.UP,visual.rotation.y)
	var sword_parent=sockets.right if motion=="Attack" else sockets.back
	if sword.get_parent()!=sword_parent: sword.reparent(sword_parent,false)
	sword.position=Vector3(-.015,-.045,.060) if motion=="Attack" else Vector3(-.16,.18,-.085)
	sword.rotation=Vector3(PI/2,0,0) if motion=="Attack" else Vector3(0,0,2.65)
	var shield_parent=sockets.left if defending else sockets.back
	if shield.get_parent()!=shield_parent: shield.reparent(shield_parent,false)
	shield.position=Vector3(.02,-.04,.09) if defending else Vector3(0,.12,-.14)
	shield.rotation=Vector3(0,0,-.2) if defending else Vector3(0,PI,0)
	if defending: shield.global_basis=visual.global_basis*Basis(Vector3.UP,PI)
	if sling.visible: sling.global_basis=visual.global_basis*Basis(Vector3.UP,PI)
	if bow.visible:
		bow.global_basis=visual.global_basis
		update_bow_string()

func update_bow_string() -> void:
	var drawn=get_parent().bow_draw>0
	var nock=bow.to_local(sockets.right.global_position+visual.global_basis*Vector3(0,-.025,.04)) if drawn else Vector3(0,0,-.05)
	var tips=[Vector3(0,.725,-.05),Vector3(0,-.725,-.05)]
	for i in range(2):
		var direction:Vector3=nock-tips[i]
		bow_strings[i].position=(nock+tips[i])*.5
		bow_strings[i].basis=Basis(Quaternion(Vector3.UP,direction.normalized())).scaled(Vector3(1,direction.length(),1))
	held_arrow.visible=drawn
	if drawn:
		var direction=(Vector3.ZERO-nock).normalized()
		held_arrow.position=nock+direction*.32
		held_arrow.basis=Basis(Quaternion(Vector3.UP,direction))


func carried_item_position() -> Vector3:
	return (sockets.left.global_position+sockets.right.global_position)*.5+Vector3.UP*.16-visual.global_basis.z*.02


func update_camera(delta: float) -> void:
	var focus := global_position+Vector3(0,1.30 if adult_model else 1.05,0)
	if is_instance_valid(lock_target):
		# Keep the player framed even when aiming across a large chamber.
		focus+=(get_parent().aim_point(lock_target)-focus).limit_length(4)*.25
	var boom=Vector3(0,1.65,6.1) if get_parent().area=="temple" else Vector3(0,3.2,6.1)
	var desired := focus+boom.rotated(Vector3.UP,yaw)
	var query := PhysicsRayQueryParameters3D.create(focus,desired,9)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit and focus.distance_to(hit.position)<3.6:
		# A steeper boom keeps Link visible when a wall is close behind him.
		desired=focus+Vector3(0,5.7,2.8).rotated(Vector3.UP,yaw)
		query.to=desired
		hit=get_world_3d().direct_space_state.intersect_ray(query)
	if hit: desired = hit.position + hit.normal*.3
	# Check the lower body too: an arch lintel can miss the head ray and hide Link's feet.
	query.from=global_position+Vector3.UP*.25
	query.to=desired
	var lower_hit=get_world_3d().direct_space_state.intersect_ray(query)
	if lower_hit: desired=lower_hit.position+lower_hit.normal*.35
	camera.global_position = camera.global_position.lerp(desired,minf(1,delta*9)) if delta<1 else desired
	camera.look_at(focus)

func equip(has_sword: bool, has_shield: bool) -> void:
	sword.visible = has_sword
	scabbard.visible = has_sword
	shield.visible = has_shield

func start_climbing(base:Vector3, top:Vector3, exit_offset:Vector3=Vector3(0,0,.6)) -> void:
	climb_exit=exit_offset
	lock_target=null
	climb_base=base
	climb_top=top
	climbing=true
	position=base+Vector3(0,.08,.32)
	visual.rotation.y=0
