extends RefCounted
const Art=preload("res://scripts/art.gd")
const Forms=preload("res://scripts/jabu_art.gd")
const Target=preload("res://scripts/jabu_target.gd")
var world:Node3D
var data:Dictionary
var scene:Node3D
var room:="mouth"
var targets:Dictionary={}
var doors:Dictionary={}
var ruto:Node3D
var ruto_velocity:=Vector3.ZERO
var pads:Array=[]
var bubble_time:=0.0
var tissue_material:ShaderMaterial
var ruto_body:Node3D
var platform:Node3D
var water_surface:MeshInstance3D
var water_height:=-.8

func _init(owner_world:Node3D) -> void:
	world=owner_world
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/jabu.json"))

func enter(next:String, from:String="") -> void:
	if not data.rooms.has(next): next="mouth"
	var carrying=is_instance_valid(world.carried_person)
	if carrying:
		world.state.ruto_room=next
		world.state.ruto_position=[0,0,7]
	world.clear_landscape()
	scene=world.landscape
	room=next
	world.area="jabu_"+room
	targets={}
	doors={}
	pads=[]
	ruto=null
	ruto_body=null
	ruto_velocity=Vector3.ZERO
	platform=null
	water_surface=null
	world.player.position=Vector3(0,.15,5.5)
	world.player.velocity=Vector3.ZERO
	world.player.climbing=false
	world.player.yaw=0
	world.player.visual.rotation=Vector3.ZERO
	world.set_ambience(true)
	world.sunlight.light_energy=.05
	var env=world.world_environment.environment
	env.ambient_light_color=Color("dac0bc")
	env.ambient_light_energy=.38
	env.fog_density=.001
	env.fog_light_color=Color("71535c")
	tissue_material=Forms.chamber(scene,12,room=="water")
	for exit_data in data.rooms[room].exits:
		var at=Vector3(exit_data[1],exit_data[2],exit_data[3])
		doors[exit_data[0]]=Forms.portal(scene,at)
		add_interaction("jabu:"+exit_data[0],at,"Pass into "+(str(data.rooms[exit_data[0]].name).to_lower() if data.rooms.has(exit_data[0]) else "Zora's Fountain"))
		if exit_data[0]==from:
			world.player.position=at.move_toward(Vector3.ZERO,4.0)+Vector3.UP*.1
			world.player.visual.rotation.y=atan2(at.x,at.z)
	if room=="mouth":
		make_target("mouth",Vector3(0,3.5,-8))
		add_interaction("jabu_seeds",Vector3(-4,0,7),"Gather loose Deku seeds")
		Forms.blob(scene,Vector3(-4,.2,7),Vector3(.45,.24,.4),Forms.tissue(Color("b5b17c")))
	elif room=="lift":
		platform=Forms.blob(scene,Vector3(0,.12,0),Vector3(2.4,.16,2.4),Forms.tissue(Color("c7a69d")))
	elif room=="holes":
		add_interaction("ruto_first",Vector3(-4,0,-2),"Call to Princess Ruto")
		if not world.state.ruto_met: make_ruto(Vector3(-4,0,-2))
		for at in [Vector3(-4,-.05,-4),Vector3(4,-.05,-4)]: Forms.blob(scene,at,Vector3(2,.1,2),Forms.tissue(Color("4d3845")))
	elif room=="water":
		if not world.state.ruto_met: world.state.ruto_met=true
		if not world.state.ruto_rescued: world.state.ruto_room="water"
		if world.state.ruto_room=="water": make_ruto(world.vec(world.state.ruto_position))
		pressure_pad("water",Vector3(4,0,0))
		water_height=-.05 if "water" in world.state.jabu_switches else -.8
		water_surface=MeshInstance3D.new()
		var surface=PlaneMesh.new()
		surface.size=Vector2(6,6)
		water_surface.mesh=surface
		water_surface.position=Vector3(0,water_height,-2)
		var water_mat=StandardMaterial3D.new()
		water_mat.albedo_color=Color(.25,.45,.43,.78)
		water_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		water_mat.roughness=.18
		water_mat.metallic=.14
		water_surface.material_override=water_mat
		scene.add_child(water_surface)
		world.water_zones.append({"bounds":Rect2(-3,-5,6,6),"height":water_height,"bottom":-2.5,"current":Vector3.ZERO})

	elif room=="fork":
		pressure_pad("east_door",Vector3(7,0,2))
	elif room=="stingers":
		if not world.state.boomerang:
			for i in range(4): world.spawn_creature("stinger",Vector3(-4+i*2.7,0,-3-(i%2)*3),"stinger_"+str(i))
		world.chest_nodes.boomerang=Art.chest(scene,Vector3(0,0,-8))
		add_interaction("boomerang_chest",Vector3(0,0,-7),"Open the returning-weapon chest")
		if world.state.boomerang: world.chest_nodes.boomerang.get_node("Lid").rotation.x=-1.15
	elif room in ["west","east","north"]:
		if room not in world.state.jabu_tentacles: world.spawn_creature("tentacle",Vector3(0,0,-3),room)
		if room=="north" and room not in world.state.jabu_tentacles:
			for side in [-1,1]: world.spawn_creature("biri",Vector3(side*4,0,-1),"root_biri"+str(side))
	elif room=="bubbles":
		if not world.state.jabu_compass:
			bubble_time=float(data.combat.bubble_time)
			for i in range(9): world.spawn_creature("shabom",Vector3(sin(i*2.4)*6,0,cos(i*2.4)*6),"bubble_"+str(i))
	elif room=="octo":
		pressure_pad("altar",Vector3(0,0,-2))
		add_interaction("ruto_altar",Vector3(0,0,0),"Help Ruto reach the stone")
		if world.state.ruto_altar and not world.state.big_octo: world.spawn_creature("big_octo",Vector3(0,0,-5),"big_octo")
	elif room=="jigglies":
		for z in [2,-3]:
			var pad=Forms.blob(scene,Vector3(0,.18,z),Vector3(3,.20,1.5),Forms.tissue(Color("ac778f")))
			pads.append({"node":pad,"until":0.0,"at":Vector3(0,0,z)})
			make_target("pad_"+str(z),Vector3(0,.65,z),true)
		# Raised side folds make the two trembling pads the traversable route.
		for side in [-1,1]:
			Art.collision_box(scene,Vector3(side*7,1,-.5),Vector3(7,2,11))
			Forms.blob(scene,Vector3(side*7,0,-.5),Vector3(4,2,6),Forms.tissue(Color("856477")))
	elif room=="near_boss":
		make_target("final",Vector3(0,2,-7),true)
		var veil=Art.collision_box(scene,Vector3(0,1.6,-4),Vector3(3.6,3.2,.35))
		veil.name="SwitchScreen"
		Forms.blob(scene,veil.position,Vector3(1.85,1.65,.22),Forms.tissue(Color("ad858c")))
	elif room=="barinade":
		if not world.state.barinade: world.spawn_creature("barinade",Vector3(0,0,-2),"barinade")
		else: rewards()
	if world.state.ruto_room==room and not is_instance_valid(ruto) and not world.state.ruto_altar:
		make_ruto(world.vec(world.state.ruto_position))
	if carrying and is_instance_valid(ruto): world.carried_person=ruto
	world.apply_state()
	world.player.update_camera(1)
	world.checkpoint={"area":world.area,"position":world.player.position}
	world.tell("Navi",data.rooms[room].hint)

func add_interaction(id:String, at:Vector3, label:String) -> void:
	world.interactions.append({"id":id,"position":[at.x,at.y,at.z],"label":label})

func make_target(id:String, at:Vector3, boom:bool=false) -> Area3D:
	var node=Area3D.new()
	node.set_script(Target)
	node.dungeon=self
	node.target_id=id
	node.only_boomerang=boom
	node.position=at
	scene.add_child(node)
	targets[id]=node
	return node

func make_ruto(at:Vector3) -> void:
	# Existing Zora form is provisional; do not treat this as final character quality.
	world.zora.scene=scene
	ruto=world.zora.make_zora({"id":"ruto","style":"ruto","at":[at.x,at.y,at.z],"name":"Ruto"},false)
	for child in ruto.get_children():
		if child is StaticBody3D: child.collision_layer=0
	ruto_body=ruto.get_node("Body")
	smooth_ruto(ruto_body)
	add_interaction("ruto_carry",at,"Speak to / lift Ruto")

func pressure_pad(id:String, at:Vector3) -> void:
	var pad=Forms.blob(scene,at+Vector3.UP*.06,Vector3(.85,.1,.85),Forms.tissue(Color("b8be9b")))
	pad.name="Pressure_"+id

func hit_switch(id:String) -> void:
	if id.begins_with("pad_"):
		for pad in pads:
			if str(int(pad.at.z))==id.trim_prefix("pad_"): pad.until=world.logic_time+8
		return
	if id not in world.state.jabu_switches: world.state.jabu_switches.append(id)
	world.stats.eye_hits+=1
	world.chime(1046,.3)
	world.tell("Navi","The membrane relaxes. The passage is open.")

func interact(id:String) -> bool:
	if id.begins_with("jabu:"):
		var next=id.trim_prefix("jabu:")
		var refusal=blocked(next)
		if not refusal.is_empty(): world.tell("Navi",refusal)
		elif next=="fountain":
			if is_instance_valid(world.carried_person): put_ruto(false)
			world.overworld.enter("fountain")
		else:
			if room=="jigglies" and next=="near_boss": world.state.jabu_lift_lowered=true
			enter(next,room)
		return true
	match id:
		"jabu_seeds": world.state.seeds=30; world.tell("Deku seeds","Thirty seeds gathered. Aim at the ceiling membrane.")
		"ruto_first":
			world.state.ruto_met=true
			world.state.ruto_room="water"
			world.state.ruto_position=[-4,0,2]
			if is_instance_valid(ruto): ruto.queue_free(); ruto=null
			world.tell("Ruto",data.ruto.first+" Ruto slips through the lower fold. Follow the western passage.")
		"ruto_carry":
			if not is_instance_valid(ruto) or room=="holes" and not world.state.ruto_rescued: return true
			if not world.state.ruto_rescued:
				world.state.ruto_rescued=true
				world.tell("Ruto",data.ruto.rescue)
			elif not is_instance_valid(world.held_bomb) and not world.player.swimming:
				world.carried_person=ruto
				world.tell("Ruto",data.ruto.carry)
		"boomerang_chest":
			if living_enemies()>0: world.tell("Navi","Four Stingers guard the chest. Wait for each to surface before striking.")
			elif not world.state.boomerang:
				world.state.boomerang=true
				world.open_chest("boomerang")
				world.tell("Boomerang","T throws the boomerang. Q focuses a target. The curved flight can reach around a narrow obstacle, and returns to your hand.")
		"ruto_altar":
			if world.state.big_octo: world.tell("Navi","The upper fold is open. Ruto was lifted into the chamber beyond. Keep going.")
			elif not world.state.ruto_altar:
				if not is_instance_valid(world.carried_person): world.tell("Ruto",data.ruto.altar)
				else:
					world.state.ruto_altar=true
					world.carried_person=null
					ruto.queue_free(); ruto=null
					world.spawn_creature("big_octo",Vector3(0,0,-5),"big_octo")
					world.tell("Navi","The seal turned! Big Octo guards the lift. Stun it with the boomerang, circle behind, and strike its soft rear.")
		"jabu_reward":
			if not world.state.barinade: return true
			if not world.state.sapphire:
				world.state.sapphire=true
				world.state.max_health+=2
			world.state.health=world.state.max_health
			world.overworld.enter("fountain")
			world.tell("Ruto",data.ruto.reward)
		_: return false
	return true

func blocked(next:String) -> String:
	if room=="mouth" and next=="lift" and "mouth" not in world.state.jabu_switches: return "The ceiling membrane holds this door shut. A Deku seed should loosen it."
	if next=="near_boss" and room=="lift" and not world.state.jabu_lift_lowered: return "The upper fold has not lowered yet. Find a way around through the body."
	if room=="water" and next=="lift" and "water" not in world.state.jabu_switches: return "The current is too low. Step on the pale pressure nodule on the right."
	if room=="holes" and next=="fork" and not world.state.ruto_rescued: return "Ruto is below us. Bring her out of the flooded pocket first."
	if next=="octo" and room=="holes" and "north" not in world.state.jabu_tentacles: return "A northern root blocks the passage. Trace it back to its source."
	if room=="fork":
		if next=="stingers" and "east_door" not in world.state.jabu_switches: return "The eastern seal needs someone to stay on the pressure nodule. Carry Ruto onto it and put her down."
		if next in ["bubbles","east"] and "west" not in world.state.jabu_tentacles: return "The western root binds this doorway."
		if next=="north" and "east" not in world.state.jabu_tentacles: return "The eastern root binds this doorway."
	if room=="octo" and next=="jigglies" and not world.state.big_octo: return "The lift is held below. Help Ruto reach the stone, then defeat its guardian."
	if room=="near_boss" and next=="barinade" and "final" not in world.state.jabu_switches: return "The protected ceiling nodule holds the last seal shut. Curve the boomerang around the fold."
	return ""

func put_ruto(thrown:bool) -> void:
	if not is_instance_valid(world.carried_person): return
	world.carried_person=null
	ruto.position=world.player.position-world.player.visual.basis.z*.7+Vector3.UP*(.8 if thrown else .1)
	ruto.rotation=Vector3.ZERO
	ruto_body.rotation=Vector3.ZERO
	ruto_body.position=Vector3.ZERO
	ruto_velocity=-world.player.visual.basis.z*8+Vector3.UP*3 if thrown else Vector3.ZERO
	remember_ruto()

func remember_ruto() -> void:
	if not is_instance_valid(ruto) or not world.state.ruto_rescued: return
	world.state.ruto_room=room
	world.state.ruto_position=[ruto.position.x,ruto.position.y,ruto.position.z]

func tick(delta:float) -> void:
	tissue_material.set_shader_parameter("pulse",world.logic_time)
	for next_room in doors:
		var seal=doors[next_room].get_node("Seal")
		seal.scale.x=lerpf(seal.scale.x,1.04 if not blocked(next_room).is_empty() else .035,minf(1,delta*5))
	if is_instance_valid(water_surface):
		water_height=move_toward(water_height,-.05 if "water" in world.state.jabu_switches else -.8,delta*.6)
		water_surface.position.y=water_height
		world.water_zones[0].height=water_height
	if is_instance_valid(platform): platform.scale.y=.16+sin(world.logic_time*.8)*.025
	if is_instance_valid(ruto):
		if is_instance_valid(world.carried_person) and world.player.swimming: put_ruto(false)
		if is_instance_valid(world.carried_person):
			ruto.global_position=world.player.carried_item_position()+Vector3.UP*.18
			ruto.rotation.y=world.player.visual.rotation.y
			ruto_body.rotation.z=PI*.5
			ruto_body.position=Vector3(1.1,0,0)
		else:
			ruto_velocity.y-=delta*18
			var next=ruto.position+ruto_velocity*delta
			var hit=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ruto.position+Vector3.UP*.1,next,1))
			if not hit.is_empty(): next=hit.position; ruto_velocity=Vector3.ZERO
			ruto.position=next
			if room=="water" and world.water_zones[0].bounds.has_point(Vector2(ruto.position.x,ruto.position.z)) and ruto.position.y<water_height:
				ruto.position=Vector3(-4,0,2)
				ruto_velocity=Vector3.ZERO
				world.tell("Ruto","The current brought me back to this ledge. Carry me around the pool!")
			elif ruto.position.y<0 and (room!="water" or not world.water_zones[0].bounds.has_point(Vector2(ruto.position.x,ruto.position.z))): ruto.position.y=0; ruto_velocity=Vector3.ZERO
			if Vector2(ruto.position.x,ruto.position.z).length()>10.3: ruto.position=world.player.position+Vector3.RIGHT; ruto_velocity=Vector3.ZERO
			if ruto_velocity.length()>2:
				for enemy in world.creatures:
					if is_instance_valid(enemy) and enemy.mode!="dead" and enemy.global_position.distance_to(ruto.position)<1.3 and enemy.has_method("ruto_hit"): enemy.ruto_hit(); ruto_velocity=Vector3.ZERO
		remember_ruto()
		for item in world.interactions:
			if item.id=="ruto_carry": item.position=[ruto.position.x,0,ruto.position.z]
	if room=="water" and world.player.position.distance_to(Vector3(4,0,0))<.95 and "water" not in world.state.jabu_switches:
		hit_switch("water")
		world.tell("Navi","The current lifts the far fold. Carry Ruto through the northern passage.")
	if room=="fork" and is_instance_valid(ruto) and not is_instance_valid(world.carried_person) and ruto.position.distance_to(Vector3(7,0,2))<1 and "east_door" not in world.state.jabu_switches:
		hit_switch("east_door")
		world.tell("Ruto","I will hold this seal. Come back when you have found what is inside!")
	for pad in pads:
		var quiet=world.logic_time<pad.until
		pad.node.scale.y=.12 if quiet else .2+sin(world.logic_time*7)*.06
		var target=targets["pad_"+str(int(pad.at.z))]
		if not quiet: target.spent=false; target.visual.scale.y=.35
		if not quiet and absf(world.player.position.z-pad.at.z)<1.2 and absf(world.player.position.x)<3.5:
			world.damage_player(1,pad.at,false)
			world.player.position.z=pad.at.z+1.6
	if room=="bubbles" and not world.state.jabu_compass and bubble_time>0:
		bubble_time=maxf(0,bubble_time-delta)
		if living_enemies()==0:
			world.state.jabu_compass=true
			world.tell("Compass","Nine bubbles cleared. The compass points to the deepest chamber beyond the trembling bridge.")
		elif bubble_time==0: world.tell("Navi","The chamber exhaled. Leave and return to try again.")

func living_enemies() -> int:
	var count=0
	for enemy in world.creatures:
		if is_instance_valid(enemy) and enemy.mode!="dead": count+=1
	return count

func enemy_defeated(enemy:Node3D) -> void:
	if enemy.kind=="tentacle":
		if enemy.enemy_id not in world.state.jabu_tentacles: world.state.jabu_tentacles.append(enemy.enemy_id)
		if enemy.enemy_id=="west": world.state.jabu_map=true
		world.tell("Navi","The "+enemy.enemy_id+" root relaxes. A blocked passage elsewhere has opened.")
	elif enemy.kind=="big_octo":
		world.state.big_octo=true
		world.tell("Navi","The lift rises. Follow the upper passage to find Ruto.")
	elif enemy.kind=="barinade":
		world.state.barinade=true
		world.state.health=world.state.max_health
		rewards()

func rewards() -> void:
	if not is_instance_valid(ruto): make_ruto(Vector3(2,0,-3))
	add_interaction("jabu_reward",Vector3(0,0,-3),"Join Ruto in the blue light")
	Forms.blob(scene,Vector3(0,.06,-3),Vector3(1.3,.07,1.3),Art.material(Color("7ac7db"),.2))
	world.tell("Ruto",data.ruto.reward)

func objective() -> String:
	if room=="bubbles" and not world.state.jabu_compass: return "JABU-JABU · Air sac · %.0fs · %d bubbles" % [bubble_time,living_enemies()]
	return "JABU-JABU · "+data.rooms[room].name+" · "+("T Boomerang" if world.state.boomerang else "Find Ruto and the returning weapon")

func smooth_ruto(node:Node) -> void:
	for child in node.get_children(): smooth_ruto(child)
	if node is MeshInstance3D:
		if node.mesh is SphereMesh:
			node.mesh=node.mesh.duplicate()
			node.mesh.radial_segments=64
			node.mesh.rings=32
		elif node.mesh is CylinderMesh:
			node.mesh=node.mesh.duplicate()
			node.mesh.radial_segments=48
