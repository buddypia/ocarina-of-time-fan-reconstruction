extends CharacterBody3D

var world:Node3D
var kind:="baba"
var enemy_id:=""
var health:=2
var mode:="idle"
var timer:=1.0
var age:=0.0
var body:Node3D
var eye:MeshInstance3D
var limbs:Array=[]
var home:=Vector3.ZERO
var attack_direction:=Vector3.FORWARD
var surrendered:=false
var hit_cooldown:=0.0
var climbing_done:=false

func _ready() -> void:
	add_to_group("enemies")
	collision_layer=2
	collision_mask=1
	var shape=CapsuleShape3D.new()
	shape.radius=1.05 if kind=="gohma" else .40
	shape.height=2.4 if kind=="gohma" else 1.2
	var col=CollisionShape3D.new()
	col.shape=shape
	col.position.y=shape.height*.5
	add_child(col)
	body=Node3D.new()
	body.set_meta("animated",true)
	add_child(body)
	home=position
	if kind=="gohma":
		health=9
		build_gohma()
	elif kind=="scrub":
		health=1
		build_scrub()
	else: build_baba()

func build_baba() -> void:
	ForestArt.beam(body,Vector3(0,0,0),Vector3(0,1.1,0),.10,Color("587039"))
	for i in range(5):
		var a=i*TAU/5
		var leaf=ForestArt.ellipsoid(body,Vector3(cos(a)*.4,.08,sin(a)*.4),Vector3(.42,.065,.15),Color("416b36"))
		leaf.rotation.y=-a
	var head=ForestArt.ellipsoid(body,Vector3(0,1.2,0),Vector3(.45,.33,.4),Color("3858a0"))
	limbs.append(head)
	ForestArt.ellipsoid(head,Vector3(0,-.1,-.75),Vector3(.8,.33,.2),Color("722c31"))
	for x in [-.19,0,.19]:
		var tooth=ForestArt.cylinder(body,Vector3(x,1.2,-.36),.02,.065,.19,Color("d3d0a7"),5)
		limbs.append(tooth)

func build_scrub() -> void:
	ForestArt.cylinder(body,Vector3(0,.18,0),.68,.45,.3,Color("61532e"),10)
	ForestArt.ellipsoid(body,Vector3(0,.7,0),Vector3(.45,.57,.38),Color("805337"))
	for side in [-1,1]:
		ForestArt.ellipsoid(body,Vector3(side*.15,.86,-.34),Vector3(.08,.11,.04),Color("e8c952"))
	var snout=ForestArt.cylinder(body,Vector3(0,.68,-.5),.17,.20,.32,Color("a07745"),8)
	snout.rotation.x=PI/2
	ForestArt.ellipsoid(body,Vector3(0,.67,-.67),Vector3(.11,.11,.025),Color("292b18"))
	for i in range(5):
		var leaf=ForestArt.ellipsoid(body,Vector3(sin(i)*.26,1.18,cos(i)*.2),Vector3(.18,.10,.43),Color("627933"))
		leaf.rotation.y=i
	var number=Label3D.new()
	number.text=enemy_id.trim_prefix("scrub_")
	number.position.y=1.7
	number.font_size=44
	number.pixel_size=.01
	number.modulate=Color("eee1b6")
	number.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	body.add_child(number)

func build_gohma() -> void:
	ForestArt.ellipsoid(body,Vector3(0,1.4,.4),Vector3(1.25,.65,1.50),Color("614c36"))
	ForestArt.ellipsoid(body,Vector3(0,1.5,-.8),Vector3(1.1,.70,.75),Color("7c6340"))
	for side in [-1,1]:
		for i in range(3):
			var leg=Node3D.new()
			leg.position=Vector3(side*.85,1.4,-.4+i*.6)
			body.add_child(leg)
			var knee=Vector3(side*(1.2+i*.1),.3,-.9+i*.7)
			var foot=Vector3(side*(1.9+i*.05),-1.35,-1.3+i*1.1)
			ForestArt.beam(leg,Vector3.ZERO,knee,.18,Color("81674a"))
			ForestArt.ellipsoid(leg,knee,Vector3.ONE*.25,Color("544431"))
			ForestArt.beam(leg,knee,foot,.16,Color("b5a378"))
			limbs.append(leg)
		ForestArt.beam(body,Vector3(side*.5,1,-1.1),Vector3(side*.8,.55,-1.7),.20,Color("c4ac7d"))
	for i in range(5):
		var spike=ForestArt.cylinder(body,Vector3(0,2.0,.2+i*.25),.22,0,.7,Color("a4824e"),6)
		spike.rotation.x=-.3
	ForestArt.ellipsoid(body,Vector3(0,1.65,-1.32),Vector3(.70,.52,.24),Color("242d20"))
	eye=ForestArt.ellipsoid(body,Vector3(0,1.65,-1.52),Vector3(.50,.38,.07),Color("c6ad4b"))
	ForestArt.ellipsoid(body,Vector3(0,1.65,-1.59),Vector3(.10,.32,.025),Color("141c14"))

func aim_point() -> Vector3:
	return global_position+Vector3.UP*(1.65 if kind=="gohma" else .8)

func _physics_process(delta:float) -> void:
	if not world.started or not world.player.enabled or mode=="dead": return
	age+=delta
	timer-=delta
	hit_cooldown=maxf(0,hit_cooldown-delta)
	var offset:Vector3=world.player.position-position
	var flat=Vector3(offset.x,0,offset.z)
	var distance=flat.length()
	if mode!="lunge" and mode!="stunned":
		rotation.y=lerp_angle(rotation.y,atan2(-flat.x,-flat.z),minf(1,delta*3))
	if kind=="scrub":
		if surrendered:
			body.position.y=sin(age*3)*.025
			return
		body.position.y=lerpf(body.position.y,-.65 if distance<2 else 0.0,minf(1,delta*8))
		if timer<=0 and distance>=2 and distance<16:
			world.spawn_projectile(self,aim_point()-basis.z*.8,(world.player.global_position+Vector3.UP*.75-aim_point()).normalized()*8,"nut")
			timer=2.6
		return
	if mode=="stunned":
		body.position.y=lerpf(body.position.y,-.45,minf(1,delta*8))
		if timer<=0: change_mode("recover",1.0)
		return
	if mode=="ceiling":
		position.y=move_toward(position.y,5.8,delta*3)
		set_eye(Color("c75e38"))
		if timer<=0:
			position.y=0
			for side in [-1,1]: world.spawn_creature("baba",position+Vector3(side*3,0,2),enemy_id+"_larva_"+str(side))
			change_mode("recover",1.3)
		return
	body.position.y=lerpf(body.position.y,0.0,minf(1,delta*6))
	for i in range(limbs.size()):
		if kind=="gohma": limbs[i].rotation.z=sin(age*5+i*PI)*.10
		elif i==0: limbs[i].position.y=1.2+sin(age*2)*.06
	match mode:
		"idle":
			if kind=="gohma" and health<=4 and not climbing_done:
				climbing_done=true
				change_mode("ceiling",5.5)
			elif distance<(12 if kind=="gohma" else 3.5) and timer<=0:
				attack_direction=flat.normalized()
				change_mode("windup",1.1 if kind=="gohma" else .85)
			elif kind=="gohma" and distance>4:
				velocity=flat.normalized()*1.25
				move_and_slide()
		"windup":
			set_eye(Color("e26b3c"))
			body.rotation.x=-.13*sin((1.1-timer)*PI)
			if timer<=0: change_mode("lunge",.52)
		"lunge":
			velocity=attack_direction*(8 if kind=="gohma" else 4)
			move_and_slide()
			if distance<(2.1 if kind=="gohma" else .9): world.damage_player(2 if kind=="gohma" else 1,global_position)
			if timer<=0: change_mode("recover",1.2)
		"recover":
			set_eye(Color("b8a150"))
			body.rotation.x=0
			if kind=="baba": position=position.move_toward(home,delta*2)
			if timer<=0: change_mode("idle",.6)

func change_mode(next:String, duration:float) -> void:
	mode=next
	timer=duration
	velocity=Vector3.ZERO

func set_eye(color:Color) -> void:
	if eye: eye.material_override=ForestArt.material(color,.4)

func projectile_hit(projectile_kind:String, reflected:bool) -> void:
	if mode=="dead": return
	if kind=="scrub":
		if reflected:
			surrendered=true
			world.dungeon.scrub_surrendered(self)
		return
	if kind=="gohma":
		if mode in ["windup","ceiling"]:
			position.y=0
			change_mode("stunned",2.1)
			set_eye(Color("75b889"))
			world.stats.stuns+=1
			world.chime(900,.12)
		return
	if projectile_kind=="seed": sword_hit()

func sword_hit() -> bool:
	if mode=="dead" or hit_cooldown>0: return false
	if kind=="scrub" or (kind=="gohma" and mode!="stunned"):
		world.chime(180,.09)
		return false
	health-=1
	hit_cooldown=.45
	world.stats.sword_hits+=1
	if health<=0:
		mode="dead"
		collision_layer=0
		create_tween().tween_property(body,"scale",Vector3(.9,.12,.9),.55)
		world.creature_defeated(self)
	return true

func reset_scrub() -> void:
	surrendered=false
	timer=1.5
