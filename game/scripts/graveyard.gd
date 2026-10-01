extends RefCounted

const Art=preload("res://scripts/art.gd")
const Stone=preload("res://scripts/natural_art.gd")
const G=preload("res://scripts/grave_art.gd")
var world:Node3D
var data:Dictionary
var graves:Dictionary={}
var targets:Array=[]
var race:="idle"
var timer:=0.0
var ghost_index:=1
var player_index:=1
var ghost:Node3D
var gates:Array=[]
var fires:Array=[]
var fire_time:=0.0
var fire_index:=0
var race_repeat:=false
var time_block:Node3D
var tomb_gate:StaticBody3D
var heart_chest:Node3D

func _init(owner_world:Node3D) -> void:
	world=owner_world
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/graveyard.json"))
	world.overworld.places.merge(data.places)
	world.overworld.places.kakariko.exits.append({"to":"graveyard","at":[21,0,19],"label":"Graveyard"})
	world.overworld.places.kakariko.exits.append({"to":"windmill","at":[-13,0,-14.6],"label":"Windmill"})
	world.overworld.places.kakariko.people.append({"id":"market_refugee","name":"Former market baker","style":"talon","at":[4,0,11],"adult_only":true,"lines":["I baked bread beside the fountain before the castle fell. We fled with what we could carry. The carpenter found room for us here.","A house can be rebuilt. I still hope the people who never reached the village found another road."]})
	world.overworld.places.kakariko.people.append({"id":"graveyard_witness","name":"Village resident","style":"elder","at":[-4,0,15],"adult_only":true,"lines":["Dampe's grave is on the west side of the cemetery, where someone still leaves flowers. He said his finest treasure would go to a visitor who could keep up."]})

func reset() -> void:
	graves={}
	targets=[]
	gates=[]
	fires=[]
	ghost=null
	time_block=null
	tomb_gate=null
	heart_chest=null
	race="idle"
	timer=0

func build(place:String) -> void:
	match place:
		"graveyard": cemetery()
		"dampe_race": course()
		"shield_grave":
			interior(Vector2(16,24))
			chest("hylian_shield",Vector3(0,0,-5),world.state.hylian_shield)
		"heart_grave":
			interior(Vector2(16,24))
			heart_chest=chest("grave_heart",Vector3(0,0,-5),world.state.grave_heart)
			heart_chest.visible=world.state.grave_heart_revealed
			spawn_enemy("redead",Vector3(0,0,0),"grave_redead")
		"royal_tomb": royal_tomb()
		"windmill": windmill()

func interior(size:Vector2) -> void:
	world.set_ambience(true)
	world.sunlight.light_energy=0
	world.world_environment.environment.ambient_light_energy=.35
	world.world_environment.environment.fog_density=.004
	G.room(world.landscape,size)
	world.player.position=Vector3(0,.1,size.y*.5-4)

func chest(id:String,at:Vector3,opened:bool=false) -> Node3D:
	var node=Art.chest(world.landscape,at)
	world.chest_nodes[id]=node
	if opened: node.get_node("Lid").rotation.x=-1.15
	world.interactions.append({"id":"grave_chest:"+id,"position":[at.x,at.y,at.z+1.2],"label":"Open chest"})
	return node

func cemetery() -> void:
	var scene=world.landscape
	var earth_material=G.earth()
	Stone.block(scene,Vector3(0,-.3,0),Vector3(42,.6,52),true,true).material_override=earth_material
	var path_material=preload("res://scripts/time_temple_art.gd").stone("floor")
	Stone.block(scene,Vector3(0,.018,2),Vector3(4.4,.036,45),true).material_override=path_material
	for z in [4.2,19]: Stone.block(scene,Vector3(0,.018,z),Vector3(39,.036,2.4),true).material_override=path_material
	world.world_environment.environment.ssao_enabled=RenderingServer.get_current_rendering_method()!="gl_compatibility"
	world.world_environment.environment.ssao_intensity=1.3
	for side in [-1,1]:
		Stone.block(scene,Vector3(side*21,2,0),Vector3(.8,4,52),false,true)
		Stone.block(scene,Vector3(side*12,.8,25.5),Vector3(17,1.6,.8),false,true)
		for z in range(-22,23,4):
			G.dressed(scene,Vector3(side*20.5,2.4,z),Vector3(1.1,4.8,1.1),true)
			G.dressed(scene,Vector3(side*20.5,4.85,z),Vector3(1.3,.16,1.3))
	Stone.block(scene,Vector3(0,2,-26),Vector3(42,4,.8),false,true)
	# Burial plots use low curbs and dark earth; broad paths keep the route readable.
	for side in [-1,1]:
		for z in [15,8,1,-6,-13]:
			for column in [0,1]:
				var x=side*(7+column*8)
				G.grave(scene,Vector3(x,0,z-1),int(z+column))
				var earth=Art.box(scene,Vector3(x,.045,z+.9),Vector3(2.6,.09,3.2),Color("414a3b"))
				earth.material_override=earth_material
				for edge in [-1,1]: G.dressed(scene,Vector3(x+edge*1.45,.12,z+.9),Vector3(.20,.24,3.5))
				Art.collision_box(scene,Vector3(x,.68,z-1),Vector3(1.55,1.36,.7))
	for entry in data.graves:
		var at=world.vec(entry.at)
		var root=Node3D.new()
		root.set_meta("animated",true)
		root.position=at
		scene.add_child(root)
		G.grave(root,Vector3.ZERO,0)
		var body=Art.collision_box(root,Vector3(0,.7,0),Vector3(1.5,1.4,.8))
		graves[entry.id]={"node":root,"body":body,"home":at}
		if entry.id in world.state.opened_graves: root.position.z-=1.6
		G.dressed(scene,at+Vector3(0,.05,1.15),Vector3(1.5,.10,1.7))
		world.interactions.append({"id":"grave:"+entry.id,"position":[at.x,0,at.z+1.2],"label":"Read / Pull "+entry.name})
		if entry.id=="dampe":
			for i in range(7):
				var stem=at+Vector3(-.55+i*.17,.16,1)
				G.rod(scene,stem,stem+Vector3(0,.23,-.12),.008,Color("4a6440"))
				G.sphere(scene,stem+Vector3(0,.23,-.12),Vector3(.07,.03,.07),Color("d5caba"))
	# Royal tomb portal and crest remain visible from the village approach.
	G.dressed(scene,Vector3(0,.24,-21),Vector3(8,.48,5),true)
	Art.walkway(scene,Vector3(0,0,-16),Vector3(0,.48,-19),4,Color("90958b"),false)
	for side in [-1,1]:
		G.dressed(scene,Vector3(side*2,2,-22),Vector3(1,3.3,1.5),true)
		G.lantern(scene,Vector3(side*2,2.8,-20.9),1.3)
	G.dressed(scene,Vector3(0,3.8,-22),Vector3(5,.8,1.5),true)
	G.dressed(scene,Vector3(0,1.95,-22),Vector3(2.9,2.9,.3))
	world.interactions.append({"id":"royal_tomb","position":[0,.48,-19.3],"label":"Read the royal inscription"})
	for z in [-12,4,20]:
		for side in [-1,1]:
			G.rod(scene,Vector3(side*3,0,z),Vector3(side*3,2.3,z),.045,Color("353e36"))
			G.lantern(scene,Vector3(side*3,2.25,z),.7)
	# A practice ledge is reached by the acquired Hookshot; no progression reward is here.
	Stone.block(scene,Vector3(-15,1.5,-20),Vector3(7,3,6),false,true)
	anchor(Vector3(-15,4.2,-20),Vector3(-15,3.08,-17.9))
	world.interactions.append({"id":"gravekeeper_note","position":[-15,3,-20],"label":"Read the gravekeeper's journal"})

func royal_tomb() -> void:
	interior(Vector2(20,40))
	for x in [-7,7]:
		for z in [-11,0,10]:
			G.dressed(world.landscape,Vector3(x,.65,z),Vector3(2,1.3,3),true)
	for i in range(3): spawn_enemy("keese",Vector3(-4+i*4,2,5-i*4),"tomb_bat_"+str(i))
	spawn_enemy("redead",Vector3(-2,0,-8),"tomb_redead")
	tomb_gate=Art.collision_box(world.landscape,Vector3(0,1.8,-12),Vector3(20,3.6,.25))
	tomb_gate.set_meta("animated",true)
	for x in range(-9,10): G.rod(tomb_gate,Vector3(x,-1.8,0),Vector3(x,1.8,0),.036,Color("4a463c"))
	for y in [-1.4,1.4]: G.rod(tomb_gate,Vector3(-10,y,0),Vector3(10,y,0),.05,Color("4a463c"))
	G.dressed(world.landscape,Vector3(0,1.5,-17),Vector3(5,3,.65),true)
	world.interactions.append({"id":"sun_inscription","position":[0,0,-15.8],"label":"Read the composer's melody"})

func windmill() -> void:
	interior(Vector2(20,24))
	Stone.block(world.landscape,Vector3(0,2.7,-7),Vector3(18,.6,8),true,true)
	for x in [-7,7]:
		G.rod(world.landscape,Vector3(x,0,-3),Vector3(x,5,-3),.23,Color("675442"))
	G.rod(world.landscape,Vector3(0,0,-7),Vector3(0,5,-7),.4,Color("746149"))
	world.overworld.make_person({"id":"guru","name":"Windmill keeper","style":"elder","at":[3,0,4]},false)
	world.interactions.append({"id":"windmill_song","position":[3,0,4],"label":"Talk to the windmill keeper"})
	chest("windmill_heart",Vector3(5,3,-7),world.state.windmill_heart)
	anchor(Vector3(-5,4.1,-6),Vector3(-5,3.05,-4.2))

func course() -> void:
	world.set_ambience(true)
	world.sunlight.light_energy=0
	world.world_environment.environment.ambient_light_energy=.38
	world.world_environment.environment.fog_density=.004
	G.corridor(world.landscape,data.race.route)
	world.player.position=Vector3(0,.1,10)
	ghost=world.overworld.make_person({"id":"dampe_ghost","name":"Dampe","at":[0,0,5],"style":"elder"},false)
	for body in ghost.find_children("*","CollisionObject3D",true,false): body.collision_layer=0
	G.lantern(ghost,Vector3(.65,1.1,0),2.0)
	world.interactions.append({"id":"dampe_start","position":[0,0,6.5],"label":"Challenge the gravekeeper"})
	world.interactions.append({"id":"dampe_leave","position":[0,0,10],"label":"Return to the graveyard"})
	world.interactions.append({"id":"dampe_finish","position":[0,0,-89],"label":"Talk to Dampe"})
	for index in data.race.gates:
		var at=world.vec(data.race.route[int(index)])
		var horizontal=absf(world.vec(data.race.route[int(index)+1]).x-at.x)>1
		var root=Node3D.new()
		root.set_meta("animated",true)
		root.position=at+Vector3.UP*4
		world.landscape.add_child(root)
		var size=Vector3(.32,4,5.8) if horizontal else Vector3(5.8,4,.32)
		G.dressed(root,Vector3.UP*2,size)
		var body=Art.collision_box(root,Vector3.UP*2,size)
		gates.append({"node":root,"index":int(index),"deadline":-1.0,"passed":false,"body":body})
	chest("hookshot",Vector3(-1,0,-92),world.state.hookshot)
	time_block=Node3D.new()
	time_block.set_meta("animated",true)
	world.landscape.add_child(time_block)
	time_block.position=Vector3(1.5,0,-92)
	G.dressed(time_block,Vector3.UP*1.1,Vector3(2.2,2.2,2.2),true)
	world.interactions.append({"id":"race_exit","position":[1.5,0,-90.2],"label":"Examine the blue time stone"})
	if world.state.race_time_block:
		time_block.hide()
		for body in time_block.find_children("*","CollisionObject3D",true,false): body.collision_layer=0

func anchor(at:Vector3,landing:Vector3) -> void:
	var body=StaticBody3D.new()
	body.set_meta("hook_landing",landing)
	body.position=at
	world.landscape.add_child(body)
	var col=CollisionShape3D.new()
	var shape=CylinderShape3D.new()
	shape.radius=.55
	shape.height=.4
	col.shape=shape
	col.rotation.x=PI/2
	body.add_child(col)
	var plate=Art.cylinder(body,Vector3.ZERO,.55,.55,.4,Color("725034"),96)
	plate.rotation.x=PI/2
	for side in [-1,1]:
		G.rod(body,Vector3(side*.33,-.33,.21),Vector3(-side*.33,.33,.21),.04,Color("a69a70"))
	targets.append(body)

func spawn_enemy(kind:String,at:Vector3,id:String) -> void:
	var enemy=CharacterBody3D.new()
	enemy.set_script(preload("res://scripts/grave_enemy.gd"))
	enemy.world=world
	enemy.kind=kind
	enemy.enemy_id=id
	enemy.position=at
	world.landscape.add_child(enemy)
	world.creatures.append(enemy)

func start_race() -> void:
	race="running"
	race_repeat=world.state.hookshot
	timer=0
	ghost_index=1
	player_index=1
	fire_time=1.4
	fire_index=0
	ghost.position=world.vec(data.race.route[0])
	for gate in gates:
		gate.node.position.y=4
		gate.deadline=-1
		gate.passed=false
	for fire in fires:
		if is_instance_valid(fire.node): fire.node.queue_free()
	fires=[]
	world.tell("Dampe","Keep up! I will drop fire behind me. Watch which side is clear. The gates stay open for nine seconds after I pass.")

func fail_race(reason:String) -> void:
	race="failed"
	world.tell("The light has vanished",reason+" Press E to return to the starting lantern and try again.")

func tick(delta:float) -> void:
	if world.area=="royal_tomb" and is_instance_valid(tomb_gate):
		var bats=0
		for enemy in world.creatures:
			if is_instance_valid(enemy) and enemy.kind=="keese" and enemy.mode!="dead": bats+=1
		tomb_gate.collision_layer=1 if bats>0 else 0
		tomb_gate.visible=bats>0
	if world.area!="dampe_race" or race!="running": return
	timer+=delta
	var route=data.race.route
	if ghost_index<route.size():
		var next=world.vec(route[ghost_index])
		var direction=next-ghost.position
		ghost.rotation.y=atan2(-direction.x,-direction.z)
		ghost.position=ghost.position.move_toward(next,float(data.race.speed)*delta)
		if ghost.position.distance_to(next)<.05:
			for gate in gates:
				if gate.index==ghost_index: gate.deadline=timer+float(data.race.gate_seconds)
			ghost_index+=1
	if player_index<route.size() and world.player.position.distance_to(world.vec(route[player_index]))<3.0: player_index+=1
	for gate in gates:
		if player_index>gate.index: gate.passed=true
		if gate.deadline>=0 and timer>gate.deadline:
			gate.node.position.y=move_toward(gate.node.position.y,0,delta*8)
			if not gate.passed:
				fail_race("A stone gate has closed before you reached it.")
				return
	fire_time-=delta
	if fire_time<=0 and ghost_index<route.size()-1:
		fire_time=2.6
		var behind=ghost.position+ghost.basis.z*1.6+ghost.basis.x*[-1.35,0,1.35][fire_index%3]
		var fire=G.lantern(world.landscape,behind+Vector3.UP*.3,.5)
		fire.set_meta("animated",true)
		fires.append({"node":fire,"at":behind,"life":7.0})
		fire_index+=1
	for fire in fires:
		fire.life-=delta
		if fire.life<=0:
			fire.node.hide()
			continue
		if world.player.position.distance_to(fire.at)<.72:
			world.damage_player(1,fire.at,false)
	if world.player.position.y < -3: fail_race("You lost the path.")
	if player_index>=route.size() and ghost_index>=route.size():
		race="finished"
		world.state.dampe_won=true
		if world.state.race_best<0 or timer<world.state.race_best: world.state.race_best=timer
		world.tell("Dampe","You made it in %.1f seconds. Talk to me, then open the chest. A melody can shift the stone beside it." % timer)

func on_song(id:String) -> bool:
	if world.area=="graveyard" and id=="lullaby" and world.player.position.distance_to(Vector3(0,.48,-19.3))<4:
		world.state.royal_tomb_open=true
		world.tell("Royal Family's Tomb","The royal melody wakes the inscription. Press E at the entrance to descend.")
		return true
	if id=="sun" and world.area in ["royal_tomb","heart_grave","market"]:
		for enemy in world.creatures:
			if is_instance_valid(enemy) and enemy.has_method("sun_stun"): enemy.sun_stun()
		if world.area=="heart_grave":
			world.state.grave_heart_revealed=true
			heart_chest.show()
		world.tell("Sun's Song","The dead grow still as light fills the chamber.")
		return true
	if world.area=="dampe_race" and id=="time" and world.player.position.distance_to(Vector3(1.5,0,-90.2))<4 and world.state.hookshot:
		world.state.race_time_block=true
		time_block.hide()
		for body in time_block.find_children("*","CollisionObject3D",true,false): body.collision_layer=0
		world.tell("Song of Time","The block dissolves. The passage leads up into the windmill. Press E beside the opening.")
		return true
	return false

func heart_piece(flag:String) -> void:
	if world.state[flag]:
		world.tell("Empty chest","You have already taken this Piece of Heart.")
		return
	world.state[flag]=true
	world.state.heart_pieces+=1
	if world.state.heart_pieces>=4:
		world.state.heart_pieces-=4
		world.state.max_health+=2
		world.state.health=world.state.max_health
	world.tell("Piece of Heart","Collect four to gain another heart. Pieces toward the next heart: %d / 4." % world.state.heart_pieces)

func interact(id:String) -> bool:
	if race=="failed" and world.area=="dampe_race":
		world.overworld.enter("dampe_race")
		return true
	if id.begins_with("grave:"):
		var key=id.trim_prefix("grave:")
		for entry in data.graves:
			if entry.id!=key: continue
			if key=="dampe" and not world.state.adult:
				world.tell("The gravekeeper's plot","The gravekeeper still tends this ground. There is no entrance here in this time.")
			elif not world.state.adult and not world.overworld.is_night():
				world.tell("Respect the resting place","A child watches the graves during the day. Return after nightfall.")
			elif not key in world.state.opened_graves:
				world.state.opened_graves.append(key)
				graves[key].node.position.z-=1.6
				world.tell(entry.name,entry.epitaph+" The stone slides back. Press E again to descend.")
			else: world.overworld.enter(entry.to)
		return true
	if id.begins_with("grave_chest:"):
		var key=id.trim_prefix("grave_chest:")
		if key=="hookshot":
			if not world.state.dampe_won:
				world.tell("Locked chest","Reach the end of Dampe's challenge before claiming his legacy.")
				return true
			world.state.hookshot=true
			world.tell("Hookshot","R fires a spring-loaded hook. Q focuses on wooden targets; the hook pulls you to them. Stone and metal stop its flight. Its reach is fourteen metres.")
		elif key=="hylian_shield":
			world.state.hylian_shield=true
			world.apply_state()
			world.tell("Hylian Shield","A steel shield survives within the tomb. As an adult, hold Shift and face the attack to defend.")
		elif key=="grave_heart":
			if not world.state.grave_heart_revealed: return true
			heart_piece(key)
		else: heart_piece(key)
		world.open_chest(key)
		return true
	match id:
		"royal_tomb":
			if world.state.royal_tomb_open: world.overworld.enter("royal_tomb")
			else: world.tell("Royal inscription","Those who know the royal family's melody may enter. Play Zelda's Lullaby here.")
		"sun_inscription":
			if is_instance_valid(tomb_gate) and tomb_gate.collision_layer!=0: return true
			world.learn_song("sun")
			world.tell("The composers' resting place","You learned the Sun's Song: L K I L K I. It changes day and night outdoors, and stills the restless dead.")
		"dampe_start":
			if race=="running": world.tell("Dampe","Follow my light!")
			else: start_race()
		"dampe_leave":
			if race!="running": world.overworld.enter("graveyard","dampe_race")
		"dampe_finish":
			if race=="finished":
				if race_repeat and timer<=float(data.race.bonus_seconds): heart_piece("race_heart")
				else: world.tell("Dampe","The chest holds my Hookshot. Return for another race: finish in sixty seconds for a Piece of Heart.")
			else: world.tell("Dampe","Follow the whole course from the starting lantern.")
		"race_exit":
			if world.state.race_time_block:
				world.overworld.enter("windmill")
				world.player.position=Vector3(-5,3.1,-6)
				world.player.update_camera(1)
			else: world.tell("Time stone","A blue block seals the way. The Song of Time may move it once the gravekeeper's legacy is yours.")
		"windmill_song":
			if world.state.adult:
				world.learn_song("storms")
				world.tell("Windmill keeper","That child made my windmill spin wildly with this tune seven years ago! Song of Storms: J K I J K I.")
			else: world.tell("Windmill keeper","Round and round... I want a tune that turns as fast as the wind.")
		"gravekeeper_note": world.tell("Dampe's journal","Wood gives the hook purchase. Stone does not. Look up when the path seems to end. The forest keeps older secrets than these graves.")
		"market_memory": world.tell("Seven years later","The stalls are gone. Rubble fills the houses and the dead wander the square. Survivors sought shelter in Kakariko; the Temple of Time still stands to the northeast.")
		_:
			if world.state.adult and world.area=="kakariko" and id.begins_with("person:"):
				var key=id.trim_prefix("person:")
				if data.adult_dialogue.has(key):
					world.tell(key.replace("_"," ").capitalize(),data.adult_dialogue[key][0])
					return true
			if world.state.adult and world.area=="market" and id=="travel:castle":
				world.tell("The ruined castle road","Beyond this road lies Ganondorf's stronghold. The sages' power is needed before the final approach.")
				return true
			return false
	return true

func objective() -> String:
	if not world.time_quest.sequence.is_empty(): return ""
	if world.area in ["temple","sages"]: return ""
	if world.area=="dampe_race":
		if race=="running": return "DAMPE'S RACE · %.1f s · Follow the lantern; avoid the fire" % timer
		if race=="failed": return "DAMPE'S RACE · E to retry from the starting lantern"
		if world.state.hookshot: return "GRAVEKEEPER'S LEGACY · Play the Song of Time beside the blue block"
		return "GRAVEKEEPER'S LEGACY · Challenge Dampe, reach the finish, then open his chest"
	if world.area=="graveyard": return "GRAVEYARD · The western flower-covered grave holds Dampe's legacy" if world.state.adult else "GRAVEYARD · The royal family's melody opens the northern tomb"
	if world.area=="royal_tomb": return "ROYAL TOMB · Defeat the bats and read the composers' inscription"
	if world.area=="heart_grave": return "UNMARKED GRAVE · Wake the chamber with the Sun's Song"
	if world.area=="shield_grave": return "SOLDIER'S GRAVE · Open the chest, then return by the southern ladder"
	if world.area=="windmill": return "WINDMILL · Speak to the keeper; an upper ledge holds a Piece of Heart"
	if world.state.adult:
		if world.state.forest_medallion:
			return "FOREST RESTORED · Return to Sheik in the Temple of Time" if not "prelude" in world.state.songs else "THE NEXT SAGE · Seek the Gorons on Death Mountain"
		return "SEVEN YEARS LATER · Take the Hookshot to the forest" if world.state.hookshot else "SEVEN YEARS LATER · Kakariko's eastern graveyard holds the gravekeeper's legacy"
	return ""

func market() -> void:
	var scene=world.landscape
	world.overworld.ground(Vector2(48,54),Color("77756a"))
	var paving=G.earth()
	paving.albedo_texture=load("res://assets/natural/cobblestone_floor_08/diff.jpg")
	paving.normal_texture=load("res://assets/natural/cobblestone_floor_08/nor_gl.jpg")
	Stone.block(scene,Vector3(0,.002,0),Vector3(47,.004,53),true).material_override=paving
	for side in [-1,1]:
		for z in [-14,-1,12]:
			Stone.block(scene,Vector3(side*18,.55,z),Vector3(9,1.1,8),false,true)
			for corner in [-1,1]:
				Stone.block(scene,Vector3(side*21,2.6,z+corner*3),Vector3(1.1,5.2,1.1),false,true)
			Stone.block(scene,Vector3(side*18,1.8,z-3.5),Vector3(9,3.6,.6),false,true)
			for n in range(6):
				var rubble=Stone.block(scene,Vector3(side*(13.6+n*.40),.40,z-2+n*.70),Vector3(.8,.7,1.1),false,true)
				rubble.rotation.y=n*.73
			G.rod(scene,Vector3(side*17,.9,z-2),Vector3(side*20,3,z+2),.16,Color("353029"))
	G.dressed(scene,Vector3(0,.35,0),Vector3(6,.7,6),true)
	G.dressed(scene,Vector3(0,.95,0),Vector3(1.2,1.2,1.2),true)
	for at in [Vector3(-6,0,6),Vector3(5,0,-5),Vector3(-5,0,-13)]: spawn_enemy("redead",at,"market_"+str(at))
	world.interactions.append({"id":"market_memory","position":[0,0,5],"label":"Look over the ruined square"})
