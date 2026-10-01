extends "res://scripts/creature.gd"

var jaw:Node3D
var flame:Node3D
var roll_angle:=0.0
var max_health:=12
var stride:=0.0
var opening_hits:=0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer=2
	collision_mask=1
	var col=CollisionShape3D.new()
	var capsule=CapsuleShape3D.new()
	capsule.radius=1.15 if kind=="king_dodongo" else .38
	capsule.height=2.4 if kind=="king_dodongo" else (1.5 if kind=="lizalfos" else .9)
	col.shape=capsule
	col.position.y=capsule.height*.5
	add_child(col)
	body=Node3D.new()
	body.set_meta("animated",true)
	add_child(body)
	home=position
	health=12 if kind=="king_dodongo" else 3
	max_health=health
	if kind=="lizalfos": build_lizalfos()
	else:
		build_dragon()
		if kind!="king_dodongo": body.scale=Vector3.ONE*.42
	flame=Node3D.new()
	flame.set_meta("animated",true)
	add_child(flame)
	for i in range(5):
		ForestArt.ellipsoid(flame,Vector3(0,.9,-2.2-i*.7),Vector3(.35+i*.15,.40+i*.09,.7),Color("df8641") if i%2 else Color("f4b965"))
	if kind!="king_dodongo": flame.scale=Vector3(.6,.65,.65)
	flame.hide()

func build_dragon() -> void:
	ForestArt.ellipsoid(body,Vector3(0,1.15,.4),Vector3(1.15,.85,1.65),Color("a36e42"))
	ForestArt.ellipsoid(body,Vector3(0,.85,-.2),Vector3(.91,.55,1.35),Color("b99762"))
	for side in [-1,1]:
		for i in range(2):
			var leg=Node3D.new()
			leg.position=Vector3(side*.85,1,-.65+i*1.65)
			body.add_child(leg)
			ForestArt.ellipsoid(leg,Vector3(side*.15,-.3,0),Vector3(.42,.5,.45),Color("84633f"))
			ForestArt.ellipsoid(leg,Vector3(side*.35,-.81,-.2),Vector3(.45,.20,.55),Color("b39969"))
			for claw in [-1,0,1]: ForestArt.beam(leg,Vector3(side*.35+claw*.18,-.8,-.45),Vector3(side*.35+claw*.18,-.86,-.75),.075,Color("d6c499"))
			limbs.append(leg)
	var head=Node3D.new()
	head.position=Vector3(0,1.3,-1.3)
	body.add_child(head)
	ForestArt.ellipsoid(head,Vector3(0,.25,-.2),Vector3(.96,.55,.82),Color("987141"))
	ForestArt.ellipsoid(head,Vector3(0,-.12,-.7),Vector3(.78,.38,.12),Color("362c26"))
	for side in [-1,1]:
		ForestArt.ellipsoid(head,Vector3(side*.68,.40,-.65),Vector3(.22,.16,.11),Color("dca845"))
		ForestArt.ellipsoid(head,Vector3(side*.68,.40,-.745),Vector3(.035,.12,.025),Color("252824"))
		ForestArt.beam(head,Vector3(side*.8,.5,.04),Vector3(side*1.15,1.05,.3),.24,Color("c1b28e"))
	jaw=Node3D.new()
	jaw.position=Vector3(0,-.14,-.02)
	head.add_child(jaw)
	ForestArt.ellipsoid(jaw,Vector3(0,-.03,-.5),Vector3(.87,.18,.76),Color("b08b58"))
	for x in [-.6,-.3,0,.3,.6]:
		ForestArt.cylinder(jaw,Vector3(x,.13,-.9),.065,0,.22,Color("e0ce9f"),6)
		ForestArt.cylinder(head,Vector3(x,-.08,-.89),0,.055,.17,Color("e0ce9f"),6)
	for i in range(6):
		var scale_plate=ForestArt.ellipsoid(body,Vector3(0,1.95,.1+i*.28),Vector3(.55-i*.035,.22,.28),Color("75674e"))
		scale_plate.rotation.x=-.15
		ForestArt.cylinder(body,Vector3(0,2.16,.1+i*.28),.16,0,.42,Color("c0ac79"),6)
	ForestArt.beam(body,Vector3(0,1,1.65),Vector3(0,.5,3.4),.52,Color("966c43"))
	ForestArt.beam(body,Vector3(0,.5,3.3),Vector3(0,.15,4.15),.24,Color("ae8955"))

func build_lizalfos() -> void:
	ForestArt.ellipsoid(body,Vector3(0,.85,0),Vector3(.28,.43,.22),Color("587a4e"))
	ForestArt.ellipsoid(body,Vector3(0,1.36,-.10),Vector3(.28,.24,.35),Color("709450"))
	ForestArt.ellipsoid(body,Vector3(0,1.25,-.38),Vector3(.25,.10,.25),Color("96a968"))
	for side in [-1,1]:
		ForestArt.ellipsoid(body,Vector3(side*.20,1.43,-.31),Vector3(.075,.055,.035),Color("f2d484"))
		var leg=Node3D.new()
		leg.position=Vector3(side*.17,.65,0)
		body.add_child(leg)
		ForestArt.beam(leg,Vector3.ZERO,Vector3(side*.12,-.25,.18),.10,Color("62814e"))
		ForestArt.beam(leg,Vector3(side*.12,-.25,.18),Vector3(side*.08,-.58,-.05),.085,Color("83985e"))
		ForestArt.ellipsoid(leg,Vector3(side*.08,-.59,-.17),Vector3(.15,.08,.24),Color("b4b084"))
		limbs.append(leg)
		ForestArt.beam(body,Vector3(side*.24,1,0),Vector3(side*.48,.75,-.3),.095,Color("7d9256"))
	ForestArt.beam(body,Vector3(0,.62,.12),Vector3(.3,.16,1.2),.16,Color("749456"))
	ForestArt.beam(body,Vector3(.45,.78,-.3),Vector3(.52,1.55,-.5),.045,Color("bec6b1"))
	var shield=ForestArt.cylinder(body,Vector3(-.44,.85,-.37),.25,.25,.07,Color("80634c"),8)
	shield.rotation.x=PI/2

func aim_point() -> Vector3:
	return mouth_point() if kind=="king_dodongo" else global_position+Vector3.UP*(1 if kind=="lizalfos" else .6)

func mouth_point() -> Vector3:
	return global_transform*Vector3(0,1.1,-2.1)

func _physics_process(delta:float) -> void:
	if not world.started or not world.player.enabled or mode=="dead": return
	age+=delta
	timer-=delta
	hit_cooldown=maxf(0,hit_cooldown-delta)
	var flat:Vector3=world.player.position-position
	flat.y=0
	var distance=flat.length()
	flame.visible=mode=="fire"
	if kind=="king_dodongo": king_tick(delta,flat,distance)
	else: small_tick(delta,flat,distance)
	var open=mode in ["inhale","fire","swallow"]
	if is_instance_valid(jaw): jaw.rotation.x=lerpf(jaw.rotation.x,-.7 if open else -.03,minf(1,delta*9))
	if mode!="roll":
		body.rotation.x=lerp_angle(body.rotation.x,0,minf(1,delta*9))
		body.position.y=lerpf(body.position.y,-.35 if mode=="stunned" else 0.0,minf(1,delta*6))
	stride+=delta*(7 if mode in ["stalk","lunge"] else 1)
	for i in range(limbs.size()): limbs[i].rotation.x=sin(stride+(i%2)*PI)*(.30 if mode in ["stalk","lunge"] else .025)

func king_tick(delta:float, flat:Vector3, distance:float) -> void:
	if mode not in ["roll","stunned","swallow"]: rotation.y=lerp_angle(rotation.y,atan2(-flat.x,-flat.z),minf(1,delta*2.5))
	match mode:
		"idle","stalk":
			if distance>7:
				mode="stalk"
				var current=atan2(position.x,position.z)
				var goal=atan2(world.player.position.x,world.player.position.z)
				var next=rotate_toward(current,goal,delta*.28)
				position=Vector3(sin(next)*11.5,0,cos(next)*11.5)
			elif timer<=0: change_mode("windup",.9)
		"windup":
			if timer<=0: change_mode("inhale",2.5)
		"inhale":
			body.scale=Vector3(1+sin(age*8)*.025,1,1)
			if timer<=0: change_mode("fire",1.4)
		"fire":
			if distance<8 and (-basis.z).dot(flat.normalized())>.82: world.damage_player(2,mouth_point(),false)
			if timer<=0: begin_roll()
		"swallow":
			if timer<=0:
				world.blast_visual(mouth_point(),.8)
				opening_hits=0
				change_mode("stunned",3.2)
				world.stats.stuns+=1
		"stunned":
			if timer<=0: change_mode("recover",.55)
		"recover":
			if timer<=0: begin_roll()
		"roll":
			roll_angle+=delta*1.9
			position=Vector3(sin(roll_angle)*11.5,0,cos(roll_angle)*11.5)
			rotation.y=-roll_angle
			body.rotation.x+=delta*11
			body.position.y=.7
			if distance<2.5: world.damage_player(2,global_position,false)
			if timer<=0: change_mode("idle",1.1)

func begin_roll() -> void:
	roll_angle=atan2(position.x,position.z)
	body.scale=Vector3.ONE
	change_mode("roll",3.3)

func small_tick(delta:float, flat:Vector3, distance:float) -> void:
	if mode not in ["lunge","stunned","fire","recover"]: rotation.y=lerp_angle(rotation.y,atan2(-flat.x,-flat.z),minf(1,delta*2.5))
	match mode:
		"idle","stalk":
			if distance>2 and distance<13:
				mode="stalk"
				velocity=flat.normalized()*(2.0 if kind=="lizalfos" else .8)
				velocity.y=-.2
				move_and_slide()
			if distance<3 and timer<=0:
				attack_direction=flat.normalized()
				change_mode("windup",.75)
		"windup":
			if timer<=0: change_mode("lunge" if kind=="lizalfos" else "fire",.45 if kind=="lizalfos" else 1.3)
		"lunge":
			velocity=attack_direction*5
			move_and_slide()
			if distance<1.1: world.damage_player(1,global_position)
			if timer<=0: change_mode("recover",1.3)
		"fire":
			if distance<4 and (-basis.z).dot(flat.normalized())>.8: world.damage_player(1,global_position,false)
			if timer<=0: change_mode("recover",1.5)
		"recover","stunned":
			if timer<=0: change_mode("idle",.5)

func try_swallow(bomb:Node3D) -> bool:
	if kind!="king_dodongo" or mode!="inhale" or bomb.held: return false
	if mouth_point().distance_to(bomb.global_position)>1.35: return false
	world.stats.bombs_swallowed+=1
	change_mode("swallow",.75)
	return true

func projectile_hit(_projectile_kind:String, _reflected:bool) -> void:
	# Stone scales turn away Deku seeds; small warriors only flinch briefly.
	if kind=="lizalfos" and mode!="dead": change_mode("stunned",.65)

func blast_hit() -> void:
	if mode=="dead" or kind=="king_dodongo" or hit_cooldown>0: return
	change_mode("stunned",1.4)
	health-=1
	sword_hit()

func sword_hit() -> bool:
	if kind=="king_dodongo" and mode!="stunned": return false
	if kind=="lizalfos" and mode not in ["stunned","recover"]: return false
	if kind=="dodongo" and mode!="stunned":
		var offset:Vector3=world.player.position-position
		if (-basis.z).dot(offset.normalized())>-.15: return false
	var hit=super.sword_hit()
	if hit and kind=="king_dodongo" and health>0:
		opening_hits+=1
		if opening_hits>=4: change_mode("recover",.55)
	return hit
