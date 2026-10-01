extends CharacterBody3D
const Art=preload("res://scripts/art.gd")
const Forms=preload("res://scripts/jabu_art.gd")
const Target=preload("res://scripts/jabu_target.gd")
var world:Node3D
var kind:="biri"
var enemy_id:=""
var mode:="idle"
var surrendered:=false
var health:=2
var max_health:=2
var body:Node3D
var home:Vector3
var age:=0.0
var timer:=1.5
var cooldown:=0.0
var links:Array=[]
var attachments:Array=[]
var orbiters:Array=[]
var orbit_owner:Node3D
var orbit_index:=0
var wave:=0
var opening_hits:=0
var warning:MeshInstance3D
var appendages:Array=[]

func _ready() -> void:
	collision_layer=2
	collision_mask=1
	home=position
	health=int(world.jabu.data.combat.get(kind+"_health",1))
	max_health=health
	var col=CollisionShape3D.new()
	var shape=CapsuleShape3D.new()
	shape.radius=1.05 if kind in ["barinade","big_octo"] else .4
	shape.height=2.8 if kind=="barinade" else (2.2 if kind=="tentacle" else 1.2)
	col.position.y=shape.height*.5
	col.shape=shape
	add_child(col)
	body=Node3D.new()
	body.set_meta("animated",true)
	add_child(body)
	var mat=Forms.tissue(Color("937685"))
	if kind=="tentacle":
		mode="retracted"
		var path=PackedVector3Array()
		for i in range(33): path.append(Vector3(sin(i*.11)*.3,1+float(i)/32*6,0))
		Forms.tube(body,path,.6,mat,1.25)
		Forms.blob(body,Vector3(0,1.1,0),Vector3(.75,.4,.75),Forms.tissue(Color("d4c29c")))
	elif kind=="barinade":
		mode="attached"
		Forms.blob(body,Vector3(0,1.65,0),Vector3(1.1,1.4,1.1),Forms.tissue(Color("9b916d")))
		Forms.blob(body,Vector3(0,2.4,0),Vector3(1.7,.75,1.7),mat)
		# Two unequal crowns, curved tapers and soft tips informed by NOAA anemone photographs.
		for layer in range(2):
			var count=22 if layer==0 else 15
			for i in range(count):
				var a=(i+.3*layer)*TAU/count
				var path=PackedVector3Array()
				var tip_radius=.065 if layer==0 else .045
				for j in range(41):
					var t=float(j)/40
					var r=.8+t*(1.3 if layer==0 else .8)+sin(t*PI)*(.35 if layer==0 else .6)
					var h=2.5-t*2.1+sin(t*PI)*.24 if layer==0 else 2.68+sin(t*PI*.9)*(.65+.22*sin(i*2.1))
					var bend=a+sin(t*PI)*.14*sin(i*1.7)
					path.append(Vector3(sin(bend)*r,h,cos(bend)*r))
				var tentacle=Node3D.new()
				body.add_child(tentacle)
				var flesh=Forms.tissue(Color("bcaa96") if layer==0 else Color("d0bfb2"),.38)
				Forms.tube(tentacle,path,.15 if layer==0 else .10,flesh,.4)
				Forms.blob(tentacle,path[-1],Vector3.ONE*tip_radius*1.1,flesh)
				appendages.append(tentacle)
		for i in range(4):
			var rim=PackedVector3Array()
			for j in range(97):
				var a=j*TAU/96
				var r=.32+i*.27+sin(a*9+i)*.018
				rim.append(Vector3(sin(a)*r,2.8-i*.055,cos(a)*r))
			Forms.tube(body,rim,.065,Forms.tissue(Color("aa8987"),.43))
		for i in range(3):
			var a=i*TAU/3
			var at=Vector3(sin(a)*2.1,4,cos(a)*2.1)
			var target=Area3D.new()
			target.set_script(Target)
			target.dungeon=world.jabu
			target.target_id="barinade_link_"+str(i)
			target.only_boomerang=true
			target.actor=self
			target.position=at
			add_child(target)
			links.append(target)
			world.jabu.targets[target.target_id]=target
			attachments.append(Forms.tube(self,PackedVector3Array([Vector3(0,2.4,0),at,at+Vector3.UP*3]),.15,Forms.tissue(Color("c5ae84"))))
		warning=Forms.blob(self,Vector3(0,.025,0),Vector3(4.7,.025,4.7),Art.material(Color("b09a48"),.4))
		warning.hide()
	elif kind=="big_octo":
		mode="circle"
		Forms.blob(body,Vector3(0,.85,0),Vector3(1.15,.85,1.25),Forms.tissue(Color("8e9676")))
		Forms.blob(body,Vector3(0,.8,1.07),Vector3(.65,.55,.25),Forms.tissue(Color("d0a897")))
		for i in range(8):
			var a=i*TAU/8
			appendages.append(Forms.tube(body,PackedVector3Array([Vector3(sin(a)*.7,.55,cos(a)*.7),Vector3(sin(a)*1.4,.12,cos(a)*1.4),Vector3(sin(a)*1.7,.08,cos(a)*1.7)]),.16,mat,.4))
		for side in [-1,1]:
			Forms.blob(body,Vector3(side*.45,1.2,-1),Vector3(.24,.22,.12),Art.material(Color("d9c681"),.3))
			Forms.blob(body,Vector3(side*.45,1.2,-1.1),Vector3(.08,.13,.05),Art.material(Color("2e3940"),.3))
	elif kind=="stinger":
		mode="submerged"
		Forms.blob(body,Vector3(0,.6,0),Vector3(.42,.20,.65),Forms.tissue(Color("708ba4")))
		for side in [-1,1]:
			var fin=Forms.blob(body,Vector3(side*.47,.57,.12),Vector3(.51,.05,.5),Forms.tissue(Color("9ca8b9")))
			fin.rotation.y=side*.3
			appendages.append(fin)
		Forms.tube(body,PackedVector3Array([Vector3(0,.6,.5),Vector3(0,.58,1),Vector3(.1,.5,1.5)]),.05,mat,.2)
	else:
		var bubble=kind=="shabom"
		Forms.blob(body,Vector3(0,1,0),Vector3(.55,.45,.55) if bubble else Vector3(.48,.36,.48),Forms.tissue(Color("afc3c9") if bubble else Color("aca9c5"),.16))
		if not bubble:
			for i in range(7):
				var a=i*TAU/7
				var path=PackedVector3Array()
				for j in range(17): path.append(Vector3(sin(a)*(.24+.06*sin(j*.5)),.8-j*.042,cos(a)*(.24+.06*sin(j*.5))))
				appendages.append(Forms.tube(body,path,.022,Forms.tissue(Color("d1cbbb")),.4))

func aim_point() -> Vector3:
	if kind=="barinade" and mode=="attached":
		for link in links:
			if not link.spent: return link.global_position
	return global_position+Vector3.UP*(1.8 if kind=="barinade" else 1.1)

func _physics_process(delta:float) -> void:
	if not world.started or not world.player.enabled or mode=="dead": return
	age+=delta
	timer-=delta
	cooldown=maxf(0,cooldown-delta)
	var offset=world.player.position-position
	offset.y=0
	var distance=offset.length()
	if kind=="tentacle":
		if mode=="retracted":
			body.scale.y=lerpf(body.scale.y,.58,delta*5)
			if distance<6 and timer<=0: mode="exposed"; timer=2.4
		else:
			body.scale.y=lerpf(body.scale.y,1,delta*6)
			body.rotation.z=sin(age*2)*.1
			if distance<2.1: world.damage_player(1,position,false)
			if timer<=0: mode="retracted"; timer=1.1
	elif kind=="stinger":
		if mode=="submerged":
			body.position.y=-.45
			if timer<=0 and distance<8: mode="leap"; timer=1.1; velocity=offset.normalized()*4
		elif mode=="leap":
			body.position.y=sin((1.1-timer)/1.1*PI)*1.6
			move_and_slide()
			if distance<1: world.damage_player(1,position)
			if timer<=0: mode="exposed"; timer=2.2; velocity=Vector3.ZERO
		elif timer<=0: mode="submerged"; timer=1.2
	elif kind=="big_octo":
		if mode=="circle":
			var destination=Vector3(sin(age*.5)*4,0,cos(age*.5)*4-1)
			velocity=(destination-position).limit_length(3.2)
			if velocity.length()>.1: body.rotation.y=lerp_angle(body.rotation.y,atan2(-velocity.x,-velocity.z),delta*5)
			move_and_slide()
			if distance<2: world.damage_player(1,position,false)
		elif timer<=0: mode="circle"
		for i in range(appendages.size()): appendages[i].position.y=sin(age*7+i)*.07 if mode=="circle" else 0
	elif kind=="barinade": boss_tick(delta,distance)
	else:
		if mode=="stunned":
			body.position.y=-.5
			if timer<=0: mode="idle"
		else:
			body.position.y=sin(age*2+home.x)*.16
			if is_instance_valid(orbit_owner):
				var a=age*.7+orbit_index*TAU/6
				position=orbit_owner.position+Vector3(sin(a)*3.7,0,cos(a)*3.7)
			elif kind=="shabom": position=home+Vector3(sin(age*.4+home.z)*.8,0,cos(age*.4+home.x)*.8)
			elif distance<8: position+=offset.normalized()*delta*.65
			if distance<.85: world.damage_player(1,position,kind=="shabom")

func boss_tick(delta:float, distance:float) -> void:
	body.rotation.y+=delta*(1.5 if mode=="orbit" else .2)
	for i in range(appendages.size()): appendages[i].rotation.z=sin(age*2+i)*.05
	warning.visible=mode=="charge" or mode=="attached" and timer<.9
	if mode=="attached":
		if timer<=0:
			if distance<4.7: world.damage_player(1,position,false)
			timer=2.5
	elif mode=="orbit":
		var remaining=0
		for biri in orbiters:
			if is_instance_valid(biri) and biri.mode!="dead": remaining+=1
		if remaining==0: mode="exposed"; timer=3
	elif mode=="stunned":
		body.position.y=-.35
		if timer<=0: mode="exposed"; timer=2
	elif mode=="exposed":
		body.position.y=0
		if timer<=0: mode="charge"; timer=1.4
	elif mode=="charge":
		warning.scale.x=lerpf(warning.scale.x,4.7,delta*3)
		if timer<=0:
			if distance<4.7: world.damage_player(2,position,false)
			mode="exposed"; timer=2.2
	if distance<1.6 and mode!="stunned": world.damage_player(1,position,false)

func boomerang_link(link:Area3D) -> void:
	if mode!="attached" or link.spent: return
	link.activate(false)
	link.hide()
	link.collision_layer=0
	if world.player.lock_target==link: world.player.lock_target=null
	attachments[links.find(link)].hide()
	var left=0
	for connection in links:
		if not connection.spent: left+=1
	world.chime(900,.15)
	if left==0: summon_biri()

func summon_biri() -> void:
	mode="orbit"
	wave+=1
	orbiters=[]
	for i in range(6):
		var biri=world.spawn_creature("biri",position+Vector3(sin(i*TAU/6)*3.7,0,cos(i*TAU/6)*3.7),"orbit_"+str(wave)+"_"+str(i))
		biri.orbit_owner=self
		biri.orbit_index=i
		orbiters.append(biri)
	world.tell("Navi","The ceiling connections are cut! Break the ring of Biri with your boomerang, then stun the body.")

func projectile_hit(_kind:String, _reflected:bool) -> void:
	if kind=="shabom": take_hit()
	elif kind=="stinger" and mode!="submerged": mode="exposed"; timer=2.5

func boomerang_hit() -> void:
	if mode=="dead" or cooldown>0: return
	if kind=="tentacle":
		if mode=="exposed": take_hit(); mode="retracted" if mode!="dead" else mode; timer=1
	elif kind in ["biri","shabom"]: take_hit()
	elif kind=="stinger": mode="exposed"; timer=3
	elif kind=="big_octo":
		if mode!="stunned": mode="stunned"; timer=3.5; opening_hits=0; world.stats.stuns+=1
	elif kind=="barinade" and mode in ["exposed","charge"]:
		mode="stunned"; timer=3.5; opening_hits=0; world.stats.stuns+=1

func sword_hit() -> void:
	if mode=="dead" or cooldown>0: return
	if kind=="stinger" and mode=="exposed" or kind=="shabom": take_hit()
	elif kind=="biri": world.damage_player(1,position,false)
	elif kind=="big_octo" and mode=="stunned" and opening_hits<1:
		var offset=(world.player.position-position).normalized()
		if (-body.global_basis.z).dot(offset)<-.25:
			opening_hits+=1
			take_hit()
			if mode!="dead": mode="circle"; timer=1
	elif kind=="barinade" and mode=="stunned" and opening_hits<2:
		opening_hits+=1
		take_hit()
		if health<=6 and wave==1 and mode!="dead": summon_biri()

func ruto_hit() -> void:
	if kind in ["stinger","shabom"]: take_hit()

func blast_hit() -> void:
	if kind=="shabom" or kind=="stinger" and mode=="exposed": take_hit()

func take_hit() -> void:
	if mode=="dead" or cooldown>0: return
	health-=1
	cooldown=.5
	world.stats.sword_hits+=1
	world.chime(900,.12)
	if health<=0:
		mode="dead"
		collision_layer=0
		body.hide()
		if is_instance_valid(warning): warning.hide()
		world.creature_defeated(self)
