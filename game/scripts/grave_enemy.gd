extends CharacterBody3D

const G=preload("res://scripts/grave_art.gd")
var world:Node3D
var kind:="redead"
var enemy_id:=""
var mode:="idle"
var surrendered:=false
var health:=4
var visual:Node3D
var animator:AnimationPlayer
var wings:Array=[]
var cooldown:=2.0
var stunned:=0.0
var hurt:=0.0
var age:=0.0
var home:=Vector3.ZERO

func _ready() -> void:
	home=position
	collision_layer=2
	collision_mask=1
	visual=Node3D.new()
	add_child(visual)
	visual.set_meta("animated",true)
	var col=CollisionShape3D.new()
	var shape=CapsuleShape3D.new()
	shape.radius=.33 if kind=="redead" else .24
	shape.height=1.6 if kind=="redead" else .50
	col.shape=shape
	col.position.y=.8 if kind=="redead" else 0
	add_child(col)
	if kind=="redead":
		var model=load("res://assets/link_adult.glb").instantiate()
		visual.add_child(model)
		model.rotation.y=PI
		animator=model.find_child("AnimationPlayer",true,false)
		animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		animator.play("Idle")
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			mesh.material_override=ForestArt.material(Color("6c6554"),.97)
		visual.rotation.x=.13
	else:
		health=1
		G.sphere(visual,Vector3.ZERO,Vector3(.17,.13,.26),Color("38352f"))
		G.sphere(visual,Vector3(0,.07,-.22),Vector3(.13,.11,.12),Color("50453c"))
		for side in [-1,1]:
			var pivot=Node3D.new()
			visual.add_child(pivot)
			wings.append(pivot)
			var surface=SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range(32):
				var a=float(i)/32
				var b=float(i+1)/32
				var pa=Vector3(side*(.15+a*.70),sin(a*PI)*.13,-.20+a*.60)
				var pb=Vector3(side*(.15+b*.70),sin(b*PI)*.13,-.20+b*.60)
				var ca=Vector3(side*(.15+a*.70),0,.27+sin(a*PI*3)*.065)
				var cb=Vector3(side*(.15+b*.70),0,.27+sin(b*PI*3)*.065)
				for point in [pa,pb,ca,pb,cb,ca]: surface.add_vertex(point)
				if i%8==0: G.rod(pivot,Vector3(side*.15,0,-.2),ca,.008,Color("584c3f"))
			surface.generate_normals()
			var wing=MeshInstance3D.new()
			wing.mesh=surface.commit()
			var material=ForestArt.material(Color("504035"),.91)
			material.cull_mode=BaseMaterial3D.CULL_DISABLED
			wing.material_override=material
			pivot.add_child(wing)

func aim_point() -> Vector3:
	return global_position+Vector3.UP*(1.0 if kind=="redead" else 0)

func _physics_process(delta:float) -> void:
	if not world.player.enabled or mode=="dead": return
	age+=delta
	hurt=maxf(0,hurt-delta)
	stunned=maxf(0,stunned-delta)
	cooldown=maxf(0,cooldown-delta)
	if stunned>0:
		mode="stunned"
		return
	var offset=world.player.position-global_position
	var distance=offset.length()
	var ray=PhysicsRayQueryParameters3D.create(aim_point(),world.player.position+Vector3.UP,1)
	ray.exclude=[world.player.get_rid()]
	var visible_target=world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	if kind=="keese":
		mode="swoop" if distance<10 and visible_target else "circle"
		var target=world.player.position+Vector3.UP*.85 if mode=="swoop" else home+Vector3(sin(age)*2,sin(age*1.5)*.5,cos(age)*2)
		velocity=(target-position).normalized()*2.5
		move_and_slide()
		for i in range(wings.size()): wings[i].rotation.z=sin(age*15)*.55*(-1 if i==0 else 1)
		if distance<1.1 and cooldown<=0:
			world.damage_player(1,position)
			cooldown=2
	else:
		mode="pursue" if distance<9 and visible_target else "idle"
		velocity=Vector3.ZERO
		if mode=="pursue":
			var direction=Vector3(offset.x,0,offset.z).normalized()
			visual.rotation.y=atan2(-direction.x,-direction.z)
			velocity=direction*.85
			if distance<5 and distance>1.5 and cooldown<=0:
				# A brief, readable scream slows Link; it never disables input indefinitely.
				world.player.dread_time=1.1
				cooldown=5
				world.chime(110,.4)
			if distance<1.2 and cooldown<=2:
				world.damage_player(2,position,false)
				cooldown=3
		velocity.y=-2
		move_and_slide()
		var clip="Walk" if mode=="pursue" else "Idle"
		if animator.current_animation!=clip: animator.play(clip,.25)
		animator.advance(delta*.5)

func sword_hit() -> void:
	if hurt>0 or mode=="dead": return
	health-=2 if world.state.adult else 1
	world.stats.sword_hits+=1
	hurt=.45
	stunned=.7
	if health<=0:
		mode="dead"
		collision_layer=0
		visual.rotation.x=PI/2
		visual.position.y=.25
		if kind=="keese": hide()

func seed_hit() -> void:
	if kind=="keese": sword_hit()
	else: stunned=1.5

func hook_hit() -> void:
	world.stats["hook_hits"]=world.stats.get("hook_hits",0)+1
	if kind=="keese": sword_hit()
	else: stunned=3

func blast_hit() -> void:
	sword_hit()

func sun_stun() -> void:
	if kind=="redead" and mode!="dead": stunned=12
