extends RefCounted

const Art=preload("res://scripts/art.gd")
var world:Node3D
var scene:Node3D
var gate:StaticBody3D
var gate_visual:Node3D
var royal_door:Node3D
var windmill:Node3D
var dance_time:=0.0
var cuccos:Array=[]

func _init(owner_world:Node3D) -> void:
	world=owner_world
	world.overworld.places.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/mountain.json")))
	world.overworld.places.field.exits.append({"to":"kakariko","at":[49,0,-41],"label":"Kakariko Village"})

func build(place:String) -> void:
	scene=world.landscape
	gate=null
	gate_visual=null
	royal_door=null
	windmill=null
	cuccos=[]
	match place:
		"kakariko": village()
		"trail": trail()
		"goron":
			if world.state.adult: world.fire_quest.city()
			else: goron_city()

func rocks(radius:Vector2, height:float, color:Color) -> void:
	for i in range(20):
		var a=i*TAU/20
		Art.ellipsoid(scene,Vector3(sin(a)*radius.x,height*.38,cos(a)*radius.y),Vector3(5,height*(.6+(i%3)*.08),6),color)

func village() -> void:
	world.overworld.ground(Vector2(48,58),Color("9c986a"))
	rocks(Vector2(31,38),10,Color("7c8860"))
	world.overworld.road([Vector3(0,0,25),Vector3(0,0,-24)],2.4)
	for side in [-1,1]:
		for i in range(2): world.overworld.building(Vector3(side*15,0,11-i*20),Vector3(9,3.5,9),Color("847659"),side*-.15)
	# Well, wash basin and carpentry give the village work and scale.
	Art.cylinder(scene,Vector3(-6,.6,0),1.8,1.8,1.2,Color("9d9b82"),16)
	Art.cylinder(scene,Vector3(-6,1.21,0),1.4,1.4,.02,Color("36483e"),16)
	Art.collision_box(scene,Vector3(-6,.6,0),Vector3(3.3,1.2,3.3))
	for side in [-1,1]: Art.beam(scene,Vector3(-6+side*1.3,0,0),Vector3(-6+side*1.3,2.9,0),.12,Color("846d48"))
	Art.beam(scene,Vector3(-7.3,2.7,0),Vector3(-4.7,2.7,0),.15,Color("92794e"))
	for i in range(5): Art.beam(scene,Vector3(10+i*.4,.15,-1),Vector3(10+i*.4,.15,4),.12,Color("b09564"))
	Art.cylinder(scene,Vector3(-13,4,-19),3.2,2.5,8,Color("b6b092"),16)
	Art.cylinder(scene,Vector3(-13,9,-19),3.3,0,3,Color("756b50"),12)
	windmill=Node3D.new()
	windmill.position=Vector3(-13,6.5,-15.5)
	windmill.set_meta("animated",true)
	scene.add_child(windmill)
	for i in range(4):
		var arm=Node3D.new()
		arm.rotation.z=i*PI/2
		windmill.add_child(arm)
		Art.beam(arm,Vector3.ZERO,Vector3(0,5,0),.10,Color("8d774e"))
		Art.box(arm,Vector3(.4,3.3,0),Vector3(.8,2.9,.10),Color("c9c1a2"))
	Art.cylinder(windmill,Vector3.ZERO,.4,.4,.3,Color("69583f"),12).rotation.x=PI/2
	for side in [-1,1]: Art.beam(scene,Vector3(side*3,0,-24),Vector3(side*3,3.1,-24),.16,Color("856c48"))
	gate=Art.collision_box(scene,Vector3(0,1.4,-24),Vector3(6,2.8,.4))
	gate.collision_layer=0 if world.state.mountain_pass else 1
	gate_visual=Node3D.new()
	gate_visual.position=Vector3(-3,0,-24)
	gate_visual.set_meta("animated",true)
	scene.add_child(gate_visual)
	for i in range(8): Art.beam(gate_visual,Vector3(.3+i*.75,.1,0),Vector3(.3+i*.75,2.7,0),.09,Color("9e895c"))
	for y in [.55,2.1]: Art.beam(gate_visual,Vector3(0,y,0),Vector3(6,y,0),.09,Color("aa9366"))
	if world.state.mountain_pass: gate_visual.rotation.y=-PI/2
	for i in range(3): add_cucco(Vector3(-8+i*7,0,15-i*7),str(i))
	world.add_rupee(Vector3(8,0,0),"village_stash",20)
	world.add_rupee(Vector3(-19,0,-2),"well_stash",5)

func add_cucco(at:Vector3, id:String) -> void:
	var root=Node3D.new()
	root.position=at
	root.set_meta("animated",true)
	scene.add_child(root)
	Art.ellipsoid(root,Vector3(0,.35,0),Vector3(.30,.28,.35),Color("dedac5"))
	Art.ellipsoid(root,Vector3(0,.64,-.2),Vector3(.17,.2,.17),Color("e8e1c8"))
	Art.ellipsoid(root,Vector3(0,.82,-.16),Vector3(.06,.12,.1),Color("bb6150"))
	Art.beam(root,Vector3(0,.62,-.3),Vector3(0,.6,-.48),.065,Color("d5ad60"))
	for side in [-1,1]:
		Art.beam(root,Vector3(side*.12,.2,0),Vector3(side*.12,.03,-.1),.025,Color("bb934c"))
		Art.ellipsoid(root,Vector3(side*.12,.67,-.29),Vector3.ONE*.025,Color("353831"))
	var taken=id in world.state.cuccos
	root.visible=not taken
	cuccos.append({"id":id,"node":root,"taken":taken})
	if not taken: world.interactions.append({"id":"cucco:"+id,"position":[at.x,at.y,at.z],"label":"Bring this cucco back to the pen"})

func trail() -> void:
	world.overworld.ground(Vector2(42,64),Color("7a705b"))
	rocks(Vector2(23,37),17,Color("887a62"))
	Art.walkway(scene,Vector3(0,0,27),Vector3(0,3,9),6,Color("b3a17b"),true)
	Art.box(scene,Vector3(0,1.5,5),Vector3(10,3,8),Color("96845f"),true)
	Art.walkway(scene,Vector3(0,3,5),Vector3(-12,3,2),5,Color("a49470"),true)
	Art.walkway(scene,Vector3(3,3,5),Vector3(12,6,-3),5,Color("b3a17b"),true)
	Art.box(scene,Vector3(12,3,-7),Vector3(10,6,8),Color("96845f"),true)
	Art.walkway(scene,Vector3(12,6,-8),Vector3(0,9,-19.5),5,Color("b3a17b"),true)
	Art.box(scene,Vector3(0,4.5,-23),Vector3(10,9,7),Color("96845f"),true)
	for entrance in [{"at":Vector3(-13,3,2),"angle":PI/2},{"at":Vector3(0,9,-26),"angle":0}]:
		var arch=Node3D.new()
		arch.position=entrance.at
		arch.rotation.y=entrance.angle
		scene.add_child(arch)
		Art.box(arch,Vector3(0,1.7,-.4),Vector3(3.8,3.4,.25),Color("38362d"))
		for side in [-1,1]: Art.ellipsoid(arch,Vector3(side*2.6,2,0),Vector3(1.4,2.8,2),Color("756953"))
		Art.ellipsoid(arch,Vector3(0,4,0),Vector3(3.2,1.2,2),Color("8e7e5e"))
		for side in [-1,1]:
			var pillar_camera=Art.collision_box(arch,Vector3(side*2.6,2,0),Vector3(2.8,5.6,4))
			pillar_camera.collision_layer=8
		var lintel_camera=Art.collision_box(arch,Vector3(0,4,0),Vector3(6.4,2.4,4))
		lintel_camera.collision_layer=8
	world.add_bomb_flower(Vector3(-5,3,5),"quarry")
	if not world.state.cavern_open:
		var rock=Node3D.new()
		rock.position=Vector3(-10.8,3,2)
		rock.set_meta("animated",true)
		scene.add_child(rock)
		Art.ellipsoid(rock,Vector3(0,1.4,0),Vector3(1.65,1.7,1.5),Color("a89879"))
		Art.collision_box(rock,Vector3(0,1.3,0),Vector3(2.8,2.6,2.4))
		for i in range(3): Art.beam(rock,Vector3(-.7+i*.5,.5,1.36),Vector3(-.4+i*.35,2.1,1.36),.025,Color("6e6148"))
		world.blast_targets.append({"id":"quarry_rock","position":Vector3(-10.8,4,2),"node":rock,"radius":1.2})
	world.add_rupee(Vector3(13,6,-7),"trail_ledge",5)
	world.player.position=Vector3(0,.2,26)

func goron_city() -> void:
	world.overworld.ground(Vector2(42,56),Color("8e7b58"))
	rocks(Vector2(24,31),17,Color("8c7855"))
	for i in range(24):
		var a=i*TAU/24
		var wall=Art.box(scene,Vector3(sin(a)*26,7,cos(a)*33),Vector3(10,20,3),Color("726246"))
		wall.rotation.y=a
	world.set_ambience(true)
	world.sunlight.light_energy=.18
	world.world_environment.environment.ambient_light_color=Color("c2b290")
	for side in [-1,1]:
		Art.walkway(scene,Vector3(side*10,0,15),Vector3(side*16,4,.5),4,Color("b09a6c"),true)
		Art.box(scene,Vector3(side*16,2,-8),Vector3(6,4,17),Color("97815a"),true)
		for i in range(3):
			Art.ellipsoid(scene,Vector3(side*16,6,-3-i*5),Vector3(2,2.3,1.3),Color("766044"))
		Art.box(scene,Vector3(side*11,2.4,-13),Vector3(16,4.8,1.5),Color("a89064"),true)
	royal_door=Node3D.new()
	royal_door.set_meta("animated",true)
	royal_door.position=Vector3(0,0,-13)
	scene.add_child(royal_door)
	Art.box(royal_door,Vector3(0,2,0),Vector3(5,4,.7),Color("796543"))
	Art.collision_box(royal_door,Vector3(0,2,0),Vector3(5,4,.7))
	if world.state.darunia_door: world.hide_breakable(royal_door)
	for at in [Vector3(0,.03,-9),Vector3(-.5,.03,-8.2),Vector3(.5,.03,-8.2)]:
		Art.cylinder(scene,at,.55,.55,.04,Color("cab170"),3)
	world.interactions.append({"id":"royal_crest","position":[0,0,-9],"label":"Read the royal crest"})
	for at in [Vector3(-7,0,7),Vector3(7,0,-5),Vector3(0,0,-24)]:
		Art.cylinder(scene,at+Vector3.UP*.35,.75,.9,.7,Color("8e7551"),12)
		Art.ellipsoid(scene,at+Vector3.UP*.9,Vector3(.4,.8,.4),Color("d89c51"))
		var lamp=OmniLight3D.new()
		lamp.position=at+Vector3.UP*1.5
		lamp.light_color=Color("efb475")
		lamp.light_energy=1.2
		lamp.omni_range=12
		scene.add_child(lamp)
	world.add_rupee(Vector3(-11,0,6),"goron_pot",5)

func make_goron(person:Dictionary, interactable:bool=true) -> Node3D:
	var root=Node3D.new()
	root.position=world.vec(person.at)
	root.set_meta("animated",true)
	scene.add_child(root)
	world.npc_nodes[person.id]=root
	var chief=person.style=="darunia"
	var size=1.25 if chief else 1.0
	var skin=Color("b9975e") if chief else Color("bda779")
	Art.ellipsoid(root,Vector3(0,1.05,0)*size,Vector3(.70,.87,.56)*size,skin)
	Art.ellipsoid(root,Vector3(0,1.85,-.03)*size,Vector3(.5,.48,.4)*size,skin)
	Art.ellipsoid(root,Vector3(0,.95,-.45)*size,Vector3(.70,.75,.30)*size,Color("90815e"))
	for side in [-1,1]:
		Art.ellipsoid(root,Vector3(side*.68,.9,0)*size,Vector3(.3,.63,.3)*size,skin)
		Art.ellipsoid(root,Vector3(side*.73,.4,.12)*size,Vector3(.34,.28,.33)*size,Color("c7b182"))
		Art.ellipsoid(root,Vector3(side*.34,.18,.11)*size,Vector3(.31,.20,.42)*size,skin)
		Art.ellipsoid(root,Vector3(side*.2,1.93,.35)*size,Vector3(.12,.065,.04)*size,Color("36332a"))
		Art.beam(root,Vector3(side*.1,2.1,.32)*size,Vector3(side*.34,2.07,.30)*size,.06*size,Color("756748"))
	Art.ellipsoid(root,Vector3(0,1.67,.38)*size,Vector3(.23,.075,.055)*size,Color("776347"))
	for i in range(5): Art.ellipsoid(root,Vector3(sin(i)*.35,2.22,cos(i)*.24)*size,Vector3(.15,.2,.15)*size,Color("927b4e"))
	if chief:
		for side in [-1,1]: Art.beam(root,Vector3(side*.22,1.45,.6),Vector3(side*.42,1.35,.6),.06,Color("dfd1a5"))
	Art.collision_box(root,Vector3(0,1,0)*size,Vector3(1.2,2,1)*size)
	if interactable: world.interactions.append({"id":"person:"+person.id,"position":person.at,"label":"Talk to "+person.name})
	return root

func open_quarry(node:Node3D) -> void:
	world.state.cavern_open=true
	world.stats.rocks_broken+=1
	world.hide_breakable(node)
	world.tell("Navi", "The cracked boulder shattered! Dodongo's Cavern is open.")

func interact(id:String) -> bool:
	if id=="person:mountain_guard":
		if world.state.zelda_letter:
			world.state.mountain_pass=true
			if is_instance_valid(gate): gate.collision_layer=0
			if is_instance_valid(gate_visual): world.create_tween().tween_property(gate_visual,"rotation:y",-PI/2,.8)
			world.tell("Mountain Guard", "The princess's seal! Go through. The Gorons have been cut off from their quarry. Watch for loose rock on the trail.")
		else: world.tell("Mountain Guard", "Death Mountain is closed. Bring permission from the royal family before I can open this gate.")
		return true
	if id=="travel:trail" and world.area=="kakariko" and not world.state.mountain_pass:
		world.tell("Navi", "Show Zelda's letter to the guard beside the gate.")
		return true
	if id=="travel:dodongo":
		if world.state.cavern_open: world.dodongo.enter("cavern")
		else: world.tell("Navi", "The cracked rock seals the quarry. That Bomb Flower might break it, if you can lift it.")
		return true
	if id=="royal_crest":
		world.tell("Royal crest", "A familiar crest is carved into the floor. Stand here and play Zelda's Lullaby: U I L U I L.")
		return true
	if id=="person:darunia":
		world.tell("Darunia", "Brother! Our people can eat again. The river folk hold the last stone you seek." if world.state.ruby else ("Show me what you can do, brother. Use the Bomb Flower above our quarry to break the entrance rock." if world.state.bracelet else "Our quarry is sealed and my people are hungry. Even a song would help — something warm, something from the forest."))
		return true
	if id.begins_with("cucco:"):
		var key=id.trim_prefix("cucco:")
		if key not in world.state.cuccos:
			world.state.cuccos.append(key)
			for cucco in cuccos:
				if cucco.id==key: cucco.node.hide(); cucco.taken=true
			world.interactions=world.interactions.filter(func(item): return item.id!=id)
			world.tell("Cucco", "You guide the wandering cucco back to its pen. "+str(world.state.cuccos.size())+" of 3 are safe.")
		return true
	if id=="person:cucco_lady":
		if world.state.cuccos.size()==3 and not world.state.cucco_reward:
			world.state.cucco_reward=true
			world.state.rupees=mini(99,int(world.state.rupees)+20)
			world.tell("Anju", "All three are home! Thank you. Take these twenty rupees for your journey. The village feels a little kinder today.")
		else: world.tell("Anju", "Three cuccos have wandered away. Please bring them back before the mountain wind picks up.")
		return true
	return false

func on_song(id:String) -> bool:
	if world.state.adult and world.area=="goron": return false
	if world.area!="goron": return false
	if id=="lullaby" and world.player.position.distance_to(Vector3(0,0,-9))<4:
		world.state.darunia_door=true
		world.hide_breakable(royal_door)
		world.tell("Navi", "The royal melody reaches the stone door. Darunia's chamber is open.")
		return true
	if id=="saria" and world.state.darunia_door and world.player.position.distance_to(Vector3(0,0,-21))<4:
		world.state.bracelet=true
		world.player.arm_band.show()
		dance_time=6
		world.tell("Darunia", "That rhythm! I can feel the mountain wake up! Take this Goron's Bracelet, brother. You can lift our Bomb Flowers now. Open the quarry and help my people.")
		return true
	return false

func tick(delta:float) -> void:
	if is_instance_valid(windmill): windmill.rotation.z+=delta*.20
	if world.area=="goron":
		world.sunlight.light_energy=.18
		world.world_environment.environment.ambient_light_energy=.27
		dance_time=maxf(0,dance_time-delta)
		if world.npc_nodes.has("darunia"):
			var chief=world.npc_nodes.darunia
			chief.rotation.z=sin(world.logic_time*7)*.12 if dance_time>0 else 0.0
			chief.position.y=absf(sin(world.logic_time*7))*.12 if dance_time>0 else 0.0

func objective() -> String:
	if world.area=="kakariko": return "KAKARIKO VILLAGE · Show Zelda's letter to the mountain guard" if not world.state.mountain_pass else "KAKARIKO VILLAGE · Follow the northern trail to the Gorons"
	if world.area=="trail": return "DEATH MOUNTAIN · Return to the river with the Goron's Ruby" if world.state.ruby else ("DEATH MOUNTAIN · Open the quarry with a Bomb Flower" if world.state.bracelet else "DEATH MOUNTAIN · Climb the trail to Goron City")
	if world.area=="goron": return "GORON CITY · Play the royal melody at the crest" if not world.state.darunia_door else ("GORON CITY · Play Saria's Song for Darunia" if not world.state.bracelet else "GORON CITY · Lift a Bomb Flower and restore the quarry")
	return ""
