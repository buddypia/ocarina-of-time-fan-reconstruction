extends RefCounted
const Art=preload("res://scripts/art.gd")
const A=preload("res://scripts/fire_art.gd")
const Stone=preload("res://scripts/natural_art.gd")
const G=preload("res://scripts/grave_art.gd")
var world:Node3D
var data:Dictionary
var statue:AnimatableBody3D
var statue_time:=0.0
var lava:ShaderMaterial
var safe_at:=Vector3.ZERO
var lava_cooldown:=0.0
var son:CharacterBody3D
var city_gate:Node3D

static func defaults() -> Dictionary:
	return {"goron_stopped":false,"goron_son_stage":0,"goron_tunic":false,"goron_statue":false,"fire_heat_elapsed":0.0,"fire_darunia_stage":0,"fire_keys":0,"fire_doors":[],"fire_chests":[],"fire_rescued":[],"fire_walls":[]}

func _init(owner_world:Node3D) -> void:
	world=owner_world
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/fire_mountain.json"))
	world.overworld.places.merge(data.places)

func reset() -> void:
	statue=null;statue_time=0;lava=null;son=null;city_gate=null;lava_cooldown=0

func use_at(id:String,at:Vector3,label:String) -> void:
	world.interactions.append({"id":"fire:"+id,"position":[at.x,at.y,at.z],"label":label})

func city() -> void:
	var scene=world.landscape
	A.platform(scene,Vector3.ZERO,Vector2(42,56),1)
	Stone.cave(scene,Vector2(24,31))
	A.atmosphere(world)
	for side in [-1,1]:
		var ramp=Art.walkway(scene,Vector3(side*10,0,16),Vector3(side*16,4,0),4,Color("92816c"),true)
		for mesh in ramp.find_children("*","MeshInstance3D",true,false): mesh.material_override=A.basalt()
		A.platform(scene,Vector3(side*16,4,-9),Vector2(6,18),4)
		for z in [-4,-10,-16]:
			A.portal(scene,Vector3(side*17,4,z),-side*PI/2)
			A.block(scene,Vector3(side*18.4,5.5,z),Vector3(.3,3,2.5))
		A.block(scene,Vector3(side*11,2,-14),Vector3(16,4,1.2))
		G.lantern(scene,Vector3(side*4,2.4,-14),1.8)
		G.lantern(scene,Vector3(side*12,2,15),1.6)
	A.portal(scene,Vector3(0,0,-14))
	if not world.state.goron_tunic:
		city_gate=A.cage(scene,Vector3(0,0,-14))
	use_at("chamber",Vector3(0,0,-12),"Inspect Darunia's chamber")
	statue=AnimatableBody3D.new();statue.set_meta("animated",true);statue.position=Vector3(0,0,-24);scene.add_child(statue)
	A.goron(statue,Vector3.ZERO,1.65)
	# One moving collision body, not a nested static collider.
	for body in statue.find_children("*","StaticBody3D",true,false): body.collision_layer=0
	var collider=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(3,4,1.8);collider.shape=shape;collider.position.y=2;statue.add_child(collider)
	if world.state.goron_statue: statue.position.x=4
	A.portal(scene,Vector3(0,0,-25))
	use_at("statue",Vector3(0,0,-22),"Pull the stone figure")
	use_at("crater",Vector3(0,0,-25),"Enter the crater passage")
	world.add_bomb_flower(Vector3(-12,0,12),"adult_goron_bomb")
	son=CharacterBody3D.new();son.set_script(preload("res://scripts/rolling_goron.gd"));son.world=world;son.position=Vector3(9,0,5);scene.add_child(son);world.creatures.append(son)
	use_at("stores",Vector3(7,0,-18),"Take the rescue supplies")
	for x in [6,7,8]: G.sphere(scene,Vector3(x,.4,-19),Vector3(.35,.42,.35),Color("897757"))

func crater() -> void:
	var scene=world.landscape
	A.crater_walls(scene)
	lava=A.lava(world,Vector2(64,74),-4)
	A.platform(scene,Vector3(0,0,19),Vector2(12,14),5)
	A.platform(scene,Vector3(0,0,8),Vector2(3.2,8),5)
	A.platform(scene,Vector3(0,0,-7),Vector2(13,14),5)
	A.platform(scene,Vector3(0,0,-20),Vector2(6,12),5)
	# Fractured bridge: the eight metre gap requires the Hookshot both ways.
	for z in [4,-.9]:
		for side in [-1,1]:
			G.rod(scene,Vector3(side*1.2,0,z),Vector3(side*1.2,2,z),.13,Color("51412e"))
	world.graveyard.anchor(Vector3(1.25,1.6,-2),Vector3(0,.10,-2.8))
	world.graveyard.anchor(Vector3(1.25,1.6,6),Vector3(0,.10,7))
	A.portal(scene,Vector3(0,0,24),PI)
	A.portal(scene,Vector3(0,0,-25))
	use_at("city",Vector3(0,0,23),"Return to Goron City")
	use_at("temple",Vector3(0,0,-24),"Descend to the Fire Temple")
	var person={"id":"crater_sheik","name":"Sheik","at":[-3,0,-6],"style":"sheik","lines":[]}
	world.overworld.make_person(person,false)
	use_at("sheik",Vector3(-3,0,-4.7),"Listen to Sheik")
	var pad=Art.cylinder(scene,Vector3(0,.025,-10),2,2,.05,Color("906b39"),96)
	pad.material_override=Art.material(Color("9b7141"),.60,.35)
	for i in range(8):
		var a=i*TAU/8;G.rod(scene,Vector3(sin(a)*1.4,.07,-10+cos(a)*1.4),Vector3(sin(a)*1.8,.07,-10+cos(a)*1.8),.025,Color("d6b578"))
	A.atmosphere(world,true)
	world.player.position=Vector3(0,.1,20)
	safe_at=world.player.position

func interact(id:String) -> bool:
	if not id.begins_with("fire:"): return false
	match id.trim_prefix("fire:"):
		"son":
			var stage=mini(2,int(world.state.goron_son_stage))
			world.tell("Link, Darunia's son",data.link_goron[stage])
			world.state.goron_son_stage=mini(3,stage+1)
			if stage==2 and not world.state.goron_tunic:
				world.state.goron_tunic=true
				if is_instance_valid(city_gate): world.hide_breakable(city_gate)
				world.apply_state()
				world.tell("Goron Tunic",data.link_goron[2])
		"chamber": world.tell("Darunia's chamber","The north passage is open. Pull the stone figure at the back." if world.state.goron_tunic else "The chamber is barred. The small rolling Goron may know what happened here.")
		"stores":
			world.state.bomb_count=maxi(world.state.bomb_count,10);world.state.arrows=maxi(world.state.arrows,15)
			world.tell("Rescue supplies","The remaining store contains ten bombs and fifteen arrows. Take what you need to bring the prisoners home.")
		"statue":
			if not world.state.adult: return true
			if not world.state.goron_tunic: world.tell("Navi","Darunia's son still needs your help.")
			elif world.state.goron_statue: world.tell("Hidden passage","The opening leads into Death Mountain Crater.")
			elif statue_time<=0:
				statue_time=1.8;world.tell("Moving stone","The heavy figure slides across its worn stone runners.")
		"crater":
			if world.state.goron_statue: world.overworld.enter("crater")
			else: world.tell("Sealed passage","Move the stone figure first.")
		"city":
			world.overworld.enter("goron");world.player.position=Vector3(0,.1,-21);world.player.update_camera(1)
		"sheik":
			world.learn_song("bolero")
			world.tell("Sheik · Bolero of Fire","Even a mountain changes. What endures is the courage to return for those left behind. Remember this melody: K J K J L K L K. It will bring you back to this stone circle.")
		"temple":
			if world.state.adult: world.fire_temple.enter("foyer")
			else: world.tell("Navi","The descent is built for an adult. Return through time before entering the Fire Temple.")
	return true

func physics_tick(delta:float) -> void:
	if statue_time>0 and is_instance_valid(statue):
		statue_time=maxf(0,statue_time-delta)
		statue.position.x=4*smoothstep(0,1,1-statue_time/1.8)
		if statue_time<=0: world.state.goron_statue=true;world.chime(600,.15)

func tick(delta:float) -> void:
	var hot=world.area=="crater" or world.area.begins_with("fire_")
	if not hot:
		world.state.fire_heat_elapsed=0
		return
	if lava: lava.set_shader_parameter("clock",world.logic_time)
	lava_cooldown=maxf(0,lava_cooldown-delta)
	if world.area=="crater": check_lava(-3.3)
	if not (world.state.adult and world.state.goron_tunic):
		world.state.fire_heat_elapsed+=delta
		if world.state.fire_heat_elapsed>=heat_limit():
			world.state.fire_heat_elapsed=0
			world.damage_player(2,world.player.position-Vector3.UP,false)
			world.tell("Overwhelming heat","The hot air is burning you. Leave the crater or return with the Goron Tunic.")
	else: world.state.fire_heat_elapsed=0

func heat_limit() -> float: return maxf(24,float(world.state.max_health)*4)

func check_lava(level:float) -> void:
	if world.player.is_on_floor() and world.player.position.y>level+.8:
		# Require ground beneath the whole recovery footprint, not only one toe.
		var supported=true
		for offset in [Vector3(.4,0,.4),Vector3(-.4,0,.4),Vector3(.4,0,-.4),Vector3(-.4,0,-.4)]:
			var at=world.player.position+offset
			var ray=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.2,at-Vector3.UP*.3,1)
			if world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): supported=false;break
		if supported: safe_at=world.player.position
	if world.player.position.y<level and lava_cooldown<=0:
		world.damage_player(2,world.player.position-Vector3.UP,false)
		if is_instance_valid(world.active_hook): world.active_hook.cancel()
		world.player.position=safe_at+Vector3.UP*.25;world.player.velocity=Vector3.ZERO
		world.player.update_camera(1);lava_cooldown=1
		world.tell("Molten rock","The tunic resists heat, but lava still burns. You scramble back to the last ledge.")

func on_song(id:String) -> bool:
	if id!="bolero": return false
	world.overworld.enter("crater");world.player.position=Vector3(0,.1,-10);safe_at=world.player.position;world.player.update_camera(1)
	world.checkpoint={"area":"crater","position":world.player.position}
	world.tell("Bolero of Fire","The stone circle in Death Mountain Crater answers your melody.")
	return true

func objective() -> String:
	if world.area=="goron" and world.state.adult:
		if not world.state.goron_stopped: return "GORON CITY · Stop the rolling Goron with a bomb or an arrow"
		if not world.state.goron_tunic: return "GORON CITY · Speak with Darunia's son"
		return "GORON CITY · Pull the stone figure behind Darunia's chamber"
	if world.area=="crater":
		var warning=" · HEAT %02d s" % maxi(0,ceili(heat_limit()-world.state.fire_heat_elapsed)) if not (world.state.adult and world.state.goron_tunic) else " · GORON TUNIC"
		return "DEATH MOUNTAIN CRATER · Hook across the broken bridge; find Sheik"+warning
	return ""

func apply_tunic() -> void:
	if not is_instance_valid(world.player): return
	var hot=world.area=="crater" or world.area.begins_with("fire_")
	for mesh in world.player.visual.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var source=mesh.mesh.surface_get_material(i)
			if source is StandardMaterial3D and source.resource_name=="Dyed forest-green wool":
				if world.state.adult and world.state.goron_tunic and hot:
					var red=source.duplicate();red.albedo_color=Color("994838");mesh.set_surface_override_material(i,red)
				else: mesh.set_surface_override_material(i,null)
