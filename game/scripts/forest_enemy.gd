extends CharacterBody3D
const G=preload("res://scripts/grave_art.gd")
const Art=preload("res://scripts/art.gd")
var world:Node3D
var kind:="stalfos"
var enemy_id:=""
var mode:="guard"
var surrendered:=false
var health:=6
var max_health:=6
var visual:Node3D
var animator:AnimationPlayer
var home:=Vector3.ZERO
var timer:=1.0
var age:=0.0
var hurt:=0.0
var phase:=0
var stun:=0.0
var color:=Color("9e5b51")
var painting_hits:=0
var required_rallies:=2
var orb:Node3D
var horse:Node3D
var decoy:Node3D
var clones:Array=[]
var true_clone:=0
var alive_time:=0.0

func _ready() -> void:
	home=position
	health=int(world.forest_temple.data.combat.get(kind,5))
	max_health=health
	collision_layer=2
	collision_mask=1
	var col=CollisionShape3D.new()
	var capsule=CapsuleShape3D.new()
	capsule.height=2.0 if kind in ["stalfos","phantom","moblin"] else (1.8 if kind=="poe" else 1.2)
	capsule.radius=.42 if kind in ["stalfos","phantom"] else .55
	col.shape=capsule
	col.position.y=capsule.height*.5
	add_child(col)
	visual=Node3D.new()
	visual.set_meta("animated",true)
	add_child(visual)
	if kind in ["stalfos","phantom","moblin"]: warrior()
	elif kind=="poe": ghost_form(visual,color)
	elif kind in ["floormaster","handlet"]: hand_form()
	elif kind=="bubble":
		G.sphere(visual,Vector3(0,.9,0),Vector3(.35,.38,.31),Color("b2b097"))
		for x in [-.15,.15]: G.sphere(visual,Vector3(x,.99,-.25),Vector3(.11,.14,.08),Color("2e3231"))
		var aura=G.sphere(visual,Vector3(0,.9,0),Vector3(.52,.55,.5),Color("70b3cf"))
		var mat=aura.material_override.duplicate()
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a=.28
		mat.emission_enabled=true
		mat.emission=Color("3985c6")
		aura.material_override=mat
	else:
		G.sphere(visual,Vector3(0,.7,0),Vector3(.5,.42,.42),Color("71614b"))
		for side in [-1,1]:
			for i in range(4):
				G.rod(visual,Vector3(side*.25,.65,-.3+i*.2),Vector3(side*.9,.9,-.6+i*.4),.05,Color("51483d"))
				G.rod(visual,Vector3(side*.9,.9,-.6+i*.4),Vector3(side*1.1,.05,-.65+i*.42),.035,Color("736253"))
	if kind=="phantom":
		horse=world.overworld.create_horse(Vector3.ZERO)
		horse.reparent(self,false)
		horse.position=Vector3(0,0,.25)
		visual.position.y=.85
		mode="painting"
		timer=1
		decoy=world.forest_temple.make_target("phantom_decoy",Vector3(0,1.3,12),false)
		var shape=Node3D.new();decoy.add_child(shape);shape.position.y=-1.3;decoy.visual=shape
		var rider=load("res://assets/stalfos.glb").instantiate();rider.position.y=.85;shape.add_child(rider)
		var mount=horse.duplicate();mount.position=Vector3.ZERO;shape.add_child(mount)
		decoy.set_active(false)
	if kind=="poe" and enemy_id=="meg": make_clones()

func warrior() -> void:
	var model=load("res://assets/stalfos.glb").instantiate()
	model.rotation.y=PI
	visual.add_child(model)
	animator=model.find_child("AnimationPlayer",true,false)
	if animator:
		animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		animator.play("Idle")
	var sword=load("res://assets/master_sword.glb").instantiate()
	sword.position=Vector3(.55,.8,-.10)
	sword.rotation.x=PI/2
	equip_to_bone(model,sword,"wrist.R",Vector3(-.015,-.045,.06),Vector3(PI/2,0,0))
	var shield=load("res://assets/hylian_shield.glb").instantiate()
	shield.position=Vector3(-.48,.9,-.16)
	shield.rotation.y=PI
	equip_to_bone(model,shield,"wrist.L",Vector3(.02,-.04,.09),Vector3(0,0,-.2))
	if kind=="moblin": visual.scale=Vector3(1.5,1.5,1.5)

func equip_to_bone(model:Node3D,item:Node3D,bone_name:String,at:Vector3,angles:Vector3) -> void:
	var skeleton=model.find_child("Skeleton3D",true,false)
	var attachment=BoneAttachment3D.new();attachment.bone_name=bone_name;skeleton.add_child(attachment)
	var socket=Node3D.new();attachment.add_child(socket)
	socket.basis=skeleton.get_bone_global_rest(skeleton.find_bone(bone_name)).basis.inverse()
	socket.add_child(item);item.position=at;item.rotation=angles

static func ghost_form(parent:Node3D,tint:Color) -> void:
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile=[Vector2(.60,0),Vector2(.49,.45),Vector2(.34,.90),Vector2(.20,1.25),Vector2(.18,1.5)]
	for j in range(profile.size()-1):
		for i in range(96):
			var points=[]
			for step in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var p=profile[j+step.y]
				var a=(i+step.x)*TAU/96
				var r=p.x*(1+.055*sin(a*12))
				points.append(Vector3(cos(a)*r,p.y+(.07*sin(a*7) if j+step.y==0 else 0),sin(a)*r))
			for index in [0,1,2,0,2,3]: surface.add_vertex(points[index])
	surface.generate_normals()
	var cloth=MeshInstance3D.new()
	cloth.mesh=surface.commit()
	cloth.material_override=Art.material(tint,.95)
	parent.add_child(cloth)
	G.sphere(parent,Vector3(0,1.52,0),Vector3(.32,.40,.31),tint.darkened(.16))
	G.sphere(parent,Vector3(0,1.49,-.25),Vector3(.215,.255,.07),Color("171e23"))
	for x in [-.08,.08]: G.sphere(parent,Vector3(x,1.54,-.31),Vector3(.035,.05,.025),Color("efe4a6"))
	G.rod(parent,Vector3(.24,1.1,0),Vector3(.62,.85,-.17),.075,tint)
	G.lantern(parent,Vector3(.64,.52,-.17),.8)

func hand_form() -> void:
	var scale_value=.50 if kind=="handlet" else 1.0
	visual.scale=Vector3.ONE*scale_value
	G.sphere(visual,Vector3(0,.35,0),Vector3(.46,.27,.58),Color("767563"))
	for i in range(5):
		var x=-.40+i*.2
		G.rod(visual,Vector3(x,.38,-.25),Vector3(x*1.5,.58,-.72),.075,Color("8d8b76"))
		G.rod(visual,Vector3(x*1.5,.58,-.72),Vector3(x*1.7,.12,-1.12),.060,Color("aaa38a"))
		G.sphere(visual,Vector3(x*1.7,.12,-1.10),Vector3(.055,.08,.14),Color("c1bda4"))

func make_clones() -> void:
	collision_layer=0
	visual.hide()
	for i in range(4):
		var at=Vector3(sin(i*PI/2)*6,0,cos(i*PI/2)*6)
		var target=world.forest_temple.make_target("meg_"+str(i),at+Vector3.UP*1.1,false)
		var model=Node3D.new()
		target.add_child(model)
		model.position.y=-1.1
		ghost_form(model,Color("7a598a"))
		target.visual=model
		clones.append(target)
	start_meg_round()

func start_meg_round() -> void:
	true_clone=posmod(phase*3+1,4)
	phase+=1
	timer=5
	for i in range(clones.size()):
		clones[i].set_active(true)
		clones[i].visual.rotation.y=0

func hit_clone(index:int) -> void:
	if timer>4.15 or mode=="dead": return
	if index==true_clone:
		health-=1
		world.chime(700,.1)
		if health<=0:
			for clone in clones: clone.set_active(false)
			die()
		else: start_meg_round()
	else:
		world.damage_player(1,clones[index].global_position,false)
		start_meg_round()

func aim_point() -> Vector3: return global_position+Vector3.UP*(1.3 if kind in ["stalfos","phantom","moblin","poe"] else .7)

func _physics_process(delta:float) -> void:
	if not world.player.enabled or mode=="dead": return
	age+=delta
	alive_time+=delta
	hurt=maxf(0,hurt-delta)
	timer-=delta
	stun=maxf(0,stun-delta)
	if kind=="phantom":
		phantom_tick(delta)
		return
	if kind=="poe" and enemy_id=="meg":
		if timer>4.15: clones[true_clone].visual.rotation.y+=(TAU/.85)*delta
		if timer<=0:
			world.damage_player(1,position,false)
			start_meg_round()
		return
	if stun>0:
		mode="stunned"
		return
	if mode=="stunned": mode="guard";timer=.8
	var offset=world.player.position-position
	offset.y=0
	var distance=offset.length()
	visual.rotation.y=atan2(-offset.x,-offset.z)
	velocity=Vector3.ZERO
	if kind in ["stalfos","moblin"]:
		if distance>1.55 and mode=="guard": velocity=offset.normalized()*(1.8 if kind=="stalfos" else 3.3)
		if mode=="guard" and timer<=0 and distance<2.2:
			mode="windup";timer=.62
		elif mode=="windup" and timer<=0:
			mode="strike";timer=.25
			if distance<2.3: world.damage_player(2,position,true)
		elif mode=="strike" and timer<=0: mode="recover";timer=1.55
		elif mode=="recover" and timer<=0: mode="guard";timer=.65
		if animator:
			var clip="Attack" if mode in ["windup","strike"] else ("Walk" if velocity.length()>0 else "Idle")
			if animator.current_animation!=clip: animator.play(clip,.12)
			animator.advance(delta)
	elif kind=="poe":
		visual.position.y=sin(age*2)*.13+.1
		if timer<=0:
			mode="visible" if mode=="guard" else "guard"
			timer=3.2 if mode=="visible" else 1.5
		if mode=="guard":
			visual.rotate_y(delta*8)
			if distance<1.5: world.damage_player(1,position,true)
		if distance>4: velocity=offset.normalized()*.8
	elif kind=="bubble":
		visual.position.y=sin(age*2)*.3
		if distance<7: velocity=offset.normalized()*1.6
		if distance<1.3: world.damage_player(1,position,true)
	elif kind in ["floormaster","handlet"]:
		if distance>1: velocity=offset.normalized()*(1.5 if kind=="floormaster" else 2.5)
		elif timer<=0:
			world.damage_player(1,position,false);timer=2
		if kind=="handlet" and alive_time>12:
			world.forest_temple.regrow_hand(self)
			return
	else:
		visual.rotation.y=age*.8
		if distance<1.35: world.damage_player(1,position,true)
	velocity.y=-2
	move_and_slide()

func projectile_hit(projectile:String,_reflected:bool=false) -> void:
	if mode=="dead" or hurt>0 or not projectile in ["arrow","fire_arrow"]: return
	if kind=="phantom":
		if mode=="emerge":
			painting_hits+=1
			mode="painting";timer=.8
			world.stats["phantom_painting_hits"]=painting_hits
			if painting_hits>=3:
				horse.hide()
				decoy.set_active(false)
				visual.position.y=0
				mode="volley_wait";timer=1.5
				position=Vector3(0,2.0,-7)
		return
	if kind in ["stalfos","moblin"] and mode in ["guard","windup"]: return
	if kind=="poe" and mode!="visible": return
	if kind=="bubble" and stun<=0: return
	damage(1)

func sword_hit() -> void:
	if mode=="dead" or hurt>0: return
	if kind=="phantom" and mode!="stunned": return
	if kind in ["stalfos","moblin"] and mode in ["guard","windup"]:
		var offset=(world.player.position-position).normalized()
		if (-visual.basis.z).dot(offset)>.1:
			world.chime(900,.1)
			return
	if kind=="bubble" and stun<=0: return
	if kind=="poe" and mode!="visible": return
	world.stats.sword_hits+=1
	damage(2 if world.state.adult else 1)

func damage(amount:int) -> void:
	health-=amount
	hurt=.42
	if health<=0: die()

func hook_hit() -> void:
	if kind=="phantom" or kind=="poe": return
	stun=3
	world.stats.stuns+=1

func blast_hit() -> void:
	if kind!="phantom": damage(2)

func die() -> void:
	mode="dead"
	collision_layer=0
	visual.rotation.x=PI/2
	world.forest_temple.enemy_defeated(self)

func revive() -> void:
	health=max_health
	mode="guard"
	collision_layer=2
	visual.rotation.x=0
	timer=1
	alive_time=0

func phantom_tick(delta:float) -> void:
	if mode=="painting" and timer<=0:
		phase+=1
		var a=posmod(phase*5,6)*TAU/6
		position=Vector3(sin(a)*12,0,cos(a)*12)
		visual.rotation.y=atan2(position.x,position.z)
		horse.rotation.y=visual.rotation.y
		visual.show();horse.show()
		decoy.position=Vector3(sin(a+PI)*12,1.3,cos(a+PI)*12)
		decoy.visual.rotation.y=a
		decoy.set_active(true)
		mode="emerge";timer=3.5
	elif mode=="emerge":
		if timer<1.2: decoy.set_active(false)
		position=position.move_toward(Vector3.ZERO,delta*.55)
		if timer<=0: mode="charge";timer=1.5
	elif mode=="charge":
		decoy.set_active(false)
		position+=-visual.basis.z*delta*9
		if position.distance_to(world.player.position)<1.7: world.damage_player(2,position,false)
		if timer<=0: mode="painting";timer=.6;visual.hide();horse.hide()
	elif mode=="volley_wait" and timer<=0:
		mode="volley"
		orb=Node3D.new()
		orb.set_script(preload("res://scripts/phantom_orb.gd"))
		orb.world=world
		orb.boss=self
		orb.position=aim_point()
		world.landscape.add_child(orb)
	elif mode=="stunned" and timer<=0:
		position=Vector3(0,2,-7)
		visual.rotation.z=0
		mode="volley_wait";timer=1.4
		phase+=1
		required_rallies=2+phase%3
	if animator: animator.advance(delta)

func orb_finished(reflected:bool) -> void:
	orb=null
	if mode=="dead": return
	if reflected:
		mode="stunned";timer=4.5
		position.y=0
		visual.rotation.z=.35
		world.stats.stuns+=1
	else: mode="volley_wait";timer=1.5

func can_focus() -> bool:
	return enemy_id!="meg" and mode!="painting"
