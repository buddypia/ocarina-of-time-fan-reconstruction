extends RefCounted

const Art=preload("res://scripts/art.gd")
var world:Node3D
var scene:Node3D
var room:="cavern"
var eye_nodes:Dictionary={}
var chain_times:Dictionary={}
var chain_nodes:Dictionary={}
var stair_gate:Node3D
var skull_gate:Node3D
var lava_radius:=0.0
var dual_defeats:=0

func _init(owner_world:Node3D) -> void:
	world=owner_world

func enter(next:String, from:String="") -> void:
	world.clear_landscape()
	scene=world.landscape
	room=next
	world.area="dodongo_"+room
	eye_nodes={}
	chain_times={}
	chain_nodes={}
	stair_gate=null
	skull_gate=null
	lava_radius=0
	dual_defeats=0
	world.player.lock_target=null
	world.player.climbing=false
	world.player.velocity=Vector3.ZERO
	world.player.position=Vector3(0,.2,6)
	world.player.yaw=0
	world.player.visual.rotation.y=0
	world.set_ambience(true)
	world.sunlight.light_energy=.12
	world.world_environment.environment.ambient_light_color=Color("b4a38b")
	world.world_environment.environment.ambient_light_energy=.27
	world.world_environment.environment.fog_light_color=Color("51453b")
	match room:
		"king": king_room()
		"cavern": cavern(from)
		"duel": duel()
		"stairs": staircase()
		"gallery": gallery()
		"armory": armory()
		"skull": skull_bridge()
	Art.batch_static(scene)
	world.apply_state()
	world.player.update_camera(1)
	world.checkpoint={"area":world.area,"position":world.player.position}

func shell(radius:float=15, pit:float=0) -> void:
	if pit>0:
		Art.ring(scene,radius,pit,0,Color("726451"))
		Art.collision_box(scene,Vector3(0,-1.8,0),Vector3(radius*2,.5,radius*2))
		lava_radius=pit
		var lava=Art.cylinder(scene,Vector3(0,-.35,0),pit,pit,.10,Color("b65324"),40)
		var mat=ShaderMaterial.new()
		mat.shader=preload("res://shaders/lava.gdshader")
		lava.material_override=mat
		lamp(Vector3(0,2,0),Color("ec8746"),1.4,pit*3)
	else: Art.box(scene,Vector3(0,-.3,0),Vector3(radius*2,.6,radius*2),Color("736651"),true)
	for i in range(24):
		var a=i*TAU/24
		var at=Vector3(sin(a)*radius,4,cos(a)*radius)
		var wall=Art.box(scene,at,Vector3(radius*.29,8,1.5),Color("6a6152") if i%2 else Color("625b50"))
		wall.rotation.y=a
		var collision=Art.collision_box(scene,at,Vector3(radius*.29,8,1.5))
		collision.rotation.y=a
		Art.ellipsoid(scene,Vector3(sin(a)*(radius-.5),7.5,cos(a)*(radius-.5)),Vector3(1.4,1.7,1.5),Color("706450"))
	for side in [-1,1]: lamp(Vector3(side*(radius-3),3,2),Color("e8a365"),1.0,10)

func lamp(at:Vector3, color:Color, energy:float, radius:float) -> void:
	var node=OmniLight3D.new()
	node.position=at
	node.light_color=color
	node.light_energy=energy
	node.omni_range=radius
	scene.add_child(node)

func door(to:String, at:Vector3, text:String) -> void:
	world.interactions.append({"id":"dodongo:"+to,"position":[at.x,at.y,at.z],"label":text})
	for side in [-1,1]: Art.box(scene,at+Vector3(side*1.15,1.3,-.5),Vector3(.6,2.6,.8),Color("9d9279"))
	Art.box(scene,at+Vector3(0,2.6,-.5),Vector3(2.9,.7,.8),Color("a29981"))
	Art.box(scene,at+Vector3(0,1.2,-.6),Vector3(1.8,2.4,.1),Color("3d4037"))
	var camera_block=Art.collision_box(scene,at+Vector3(0,1.5,-.5),Vector3(3,3.2,.9))
	camera_block.collision_layer=8

func supplies(at:Vector3) -> void:
	Art.cylinder(scene,at+Vector3.UP*.45,.36,.3,.9,Color("a58251"),12)
	world.interactions.append({"id":"bomb_supply","position":[at.x,at.y,at.z],"label":"Refill bombs and seeds"})

func cavern(from:String) -> void:
	shell(16,5)
	world.player.position=Vector3(0,.2,8)
	for side in [-1,1]: Art.walkway(scene,Vector3(side*7,0,12),Vector3(side*12,0,0),3,Color("918168"))
	door("trail",Vector3(0,0,13),"Return to Death Mountain")
	door("duel",Vector3(12.5,0,0),"Enter the eastern passage")
	door("skull",Vector3(-12,0,-2),"Climb to the skull bridge")
	door("king",Vector3(0,0,-12.5),"Enter the giant Dodongo's mouth")
	skull_gate=Node3D.new()
	skull_gate.set_meta("animated",true)
	scene.add_child(skull_gate)
	Art.box(skull_gate,Vector3(0,1.3,-12),Vector3(3.1,2.6,.65),Color("776b50"))
	Art.collision_box(skull_gate,Vector3(0,1.3,-12),Vector3(3.1,2.6,.65))
	for side in [-1,1]:
		Art.ellipsoid(scene,Vector3(side*3.5,3.8,-13),Vector3(2.5,2.5,1.5),Color("9f9273"))
		var eye=Art.ellipsoid(scene,Vector3(side*3.5,4.2,-11.6),Vector3(.9,.6,.17),Color("d3914c") if str(side) in world.state.dodongo_eyes else Color("393a2f"))
		for i in range(3): Art.cylinder(scene,Vector3(side*(.8+i*.9),2.6,-11.4),0,.2,.9,Color("cec09a"),6)
	Art.ellipsoid(scene,Vector3(0,5.6,-13),Vector3(4.2,1.6,1.8),Color("8e8269"))
	if world.state.dodongo_eyes.size()==2: world.hide_breakable(skull_gate)
	world.add_bomb_flower(Vector3(8,0,8),"cavern")
	if from=="skull": world.player.position=Vector3(-10.5,.2,-1)
	world.tell("Navi", "The giant skull's eyes are dark. The eastern passage winds upward toward its crown. Bomb Flowers grow in the warm stone.")

func duel() -> void:
	shell(13)
	for at in [Vector3(-7,.6,-4),Vector3(7,.6,1)]: Art.ellipsoid(scene,at,Vector3(2,.6,2),Color("877963"))
	if not world.state.dodongo_duel:
		world.spawn_creature("lizalfos",Vector3(-3,0,-3),"duel_left")
		world.spawn_creature("lizalfos",Vector3(3,0,-6),"duel_right")
	door("cavern",Vector3(0,0,10.5),"Return to the cavern")
	door("stairs",Vector3(0,0,-10.5),"Enter the staircase chamber")
	supplies(Vector3(-7,0,7))
	world.tell("Navi", "Lizalfos guard this passage. Their blades leave an opening after a lunge. A Deku seed can interrupt them, but your sword must finish the fight.")

func staircase() -> void:
	shell(14)
	door("duel",Vector3(0,0,11.5),"Return to the lower hall")
	stair_gate=Node3D.new()
	stair_gate.set_meta("animated",true)
	scene.add_child(stair_gate)
	Art.box(stair_gate,Vector3(0,1.5,-7),Vector3(12,3,1.5),Color("776b55"))
	Art.collision_box(stair_gate,Vector3(0,1.5,-7),Vector3(12,3,1.5))
	Art.walkway(scene,Vector3(0,0,-7),Vector3(0,3,-12),6,Color("a59475"))
	door("gallery",Vector3(0,3,-11.7),"Climb into the upper gallery")
	world.add_bomb_flower(Vector3(-6,0,5),"stairs")
	for i in range(5):
		var at=Vector3(-4+i*2,.3,-4)
		var root=Node3D.new()
		root.position=at
		root.set_meta("animated",true)
		scene.add_child(root)
		Art.ellipsoid(root,Vector3.ZERO,Vector3.ONE*.32,Color("6e6947"))
		Art.cylinder(root,Vector3(0,-.18,0),.5,.4,.18,Color("637542"),8)
		chain_nodes[str(i)]=root
		world.blast_targets.append({"id":"chain:"+str(i),"position":at,"node":root,"radius":.2})
	if world.state.dodongo_stairs: world.hide_breakable(stair_gate)
	world.tell("Navi", "Five Bomb Flowers line the stair seal. Both ends must burst together. Place a bomb in the center of the row, then retreat.")

func gallery() -> void:
	shell(14,4)
	Art.walkway(scene,Vector3(0,0,11),Vector3(-7,0,3),2.8,Color("9e8e70"))
	Art.walkway(scene,Vector3(-7,0,3),Vector3(-7,2,-5),3,Color("9e8e70"))
	Art.box(scene,Vector3(0,1,-8),Vector3(16,2,6),Color("8a7c62"),true)
	make_eye("gallery",Vector3(4,3.5,-11.4))
	door("stairs",Vector3(0,0,11.5),"Return to the staircase")
	door("armory",Vector3(4,2,-8.8),"Pass the sealed gallery door")
	supplies(Vector3(-8,0,6))
	world.tell("Navi", "The gallery crosses the molten heart of the mountain. Follow the stone ramps, then shoot the eye above the far doorway.")

func armory() -> void:
	shell(12)
	world.player.position=Vector3(0,.2,3.5)
	if not world.state.bomb_bag:
		world.spawn_creature("dodongo",Vector3(-4,0,0),"armory_left")
		world.spawn_creature("dodongo",Vector3(4,0,-3),"armory_right")
	Art.box(scene,Vector3(0,.6,-7),Vector3(6,1.2,4),Color("8f7d5c"),true)
	Art.walkway(scene,Vector3(0,0,-2),Vector3(0,1.2,-5),2.5,Color("a4926b"))
	world.chest_nodes.bomb_bag=Art.chest(scene,Vector3(0,1.2,-7))
	if world.state.bomb_bag: world.chest_nodes.bomb_bag.get_node("Lid").rotation.x=-1.15
	world.interactions.append({"id":"bomb_bag","position":[0,1.2,-5.8],"label":"Open the Bomb Bag chest"})
	door("gallery",Vector3(0,0,9.5),"Return to the gallery")
	door("skull",Vector3(-9,0,0),"Cross to the giant skull")
	world.add_bomb_flower(Vector3(7,0,6),"armory")
	world.tell("Navi", "Dodongos wear hard scales over their heads. Reach their tails while they breathe fire, or use a Bomb Flower. The chest is on the raised altar.")

func skull_bridge() -> void:
	shell(14)
	world.player.position=Vector3(0,1.48,6)
	Art.walkway(scene,Vector3(0,0,10),Vector3(0,4,-2.5),4,Color("9d8b6b"))
	Art.box(scene,Vector3(0,3.7,-5),Vector3(13,.6,5),Color("a99a79"),true)
	for side in [-1,1]: Art.box(scene,Vector3(side*5,1.7,-5),Vector3(2,3.4,4.5),Color("928369"),true)
	for side in [-1,1]:
		var at=Vector3(side*4,4,-6.2)
		var bowl=Node3D.new()
		bowl.set_meta("animated",true)
		bowl.position=at
		scene.add_child(bowl)
		Art.cylinder(bowl,Vector3.ZERO,.70,.70,.10,Color("dc9551") if str(side) in world.state.dodongo_eyes else Color("473e30"),16)
		for j in range(8): Art.ellipsoid(bowl,Vector3(sin(j)*.8,.1,cos(j)*.8),Vector3(.25,.22,.25),Color("c0ac82"))
		world.blast_targets.append({"id":"skull:"+str(side),"position":at+Vector3.UP*.3,"node":bowl,"radius":.3,"spent":str(side) in world.state.dodongo_eyes})
	door("cavern",Vector3(0,0,11.5),"Descend to the giant skull's mouth")
	supplies(Vector3(5,0,8))
	world.tell("Navi", "Two sockets look down into the skull's eyes. Place a bomb in each. When both eyes burn, the mouth below will open.")

func make_eye(id:String, at:Vector3) -> void:
	var area=Area3D.new()
	area.position=at
	area.collision_layer=4
	area.collision_mask=0
	area.set_meta("eye_id",id)
	area.set_meta("animated",true)
	scene.add_child(area)
	var col=CollisionShape3D.new()
	var sphere=SphereShape3D.new()
	sphere.radius=.6
	col.shape=sphere
	area.add_child(col)
	Art.ellipsoid(area,Vector3.ZERO,Vector3(.65,.40,.15),Color("b48d51"))
	Art.ellipsoid(area,Vector3(0,0,.15),Vector3(.20,.25,.05),Color("5f392b"))
	if id in world.state.dodongo_switches: area.scale.y=.2
	eye_nodes[id]=area

func hit_eye(id:String) -> void:
	if id not in world.state.dodongo_switches: world.state.dodongo_switches.append(id)
	if eye_nodes.has(id): eye_nodes[id].scale.y=.2
	world.stats.eye_hits+=1
	world.tell("Navi", "The eye closes. The gallery passage is open.")

func king_room() -> void:
	shell(17,4.5)
	for i in range(8):
		var a=i*TAU/8
		Art.ellipsoid(scene,Vector3(sin(a)*5,-.2,cos(a)*5),Vector3(.7,.6,.7),Color("564d42"))
	supplies(Vector3(7,0,11))
	world.player.position=Vector3(0,.2,13)
	if not world.state.king_dodongo:
		world.spawn_creature("king_dodongo",Vector3(-10,0,5.6),"king_dodongo")
		world.tell("INFERNAL DINOSAUR · KING DODONGO", "Focus with Q. When he opens his mouth to inhale, take out a bomb with C and press C again to throw. Strike with F while he is down. Keep clear when he rolls!")
	else: rewards()

func rewards() -> void:
	var portal=Node3D.new()
	portal.position=Vector3(0,.05,11)
	scene.add_child(portal)
	Art.cylinder(portal,Vector3.ZERO,1.1,1.1,.1,Color("97bba2"),24)
	Art.ellipsoid(portal,Vector3(0,.8,0),Vector3(.35,.45,.25),Color("c87954"))
	world.interactions.append({"id":"ruby","position":[0,0,11],"label":"Take the Goron's Ruby and return"})
	world.tell("Navi", "The cavern is quiet. Darunia is waiting outside. Take the light back to the mountain.")

func enemy_defeated(enemy:Node3D) -> void:
	if room=="duel" and enemy.kind=="lizalfos":
		dual_defeats+=1
		if dual_defeats>=2:
			world.state.dodongo_duel=true
			world.tell("Navi", "Both guards have fallen. The northern passage opens.")

func blast_hit(id:String, node:Node3D) -> void:
	if id.begins_with("chain:"):
		var number=id.trim_prefix("chain:")
		chain_times[number]=world.logic_time
		node.hide()
		world.spawn_bomb(node.position,false,.12)
		if chain_times.has("0") and chain_times.has("4"):
			if absf(chain_times["0"]-chain_times["4"])<.3:
				world.state.dodongo_stairs=true
				world.hide_breakable(stair_gate)
				world.tell("Navi", "Both ends burst together! The sealed staircase has opened.")
			else: world.tell("Navi", "One end was too late. Let the flowers grow back and try the center.")
	elif id.begins_with("skull:"):
		var side=id.trim_prefix("skull:")
		if side not in world.state.dodongo_eyes: world.state.dodongo_eyes.append(side)
		Art.cylinder(node,Vector3(0,.04,0),.6,.6,.04,Color("e2a24d"),16)
		world.tell("Navi", "One eye burns." if world.state.dodongo_eyes.size()==1 else "Both eyes burn. The great mouth has opened below!")

func tick(_delta:float) -> void:
	if lava_radius>0 and world.player.position.y<-.3:
		world.damage_player(1,world.player.position+Vector3.UP,false)
		if world.state.health>0:
			var hearts=world.state.health
			world.retry_checkpoint()
			world.state.health=hearts
	if room=="stairs" and not world.state.dodongo_stairs and chain_times.size()>0:
		var latest=0.0
		for time in chain_times.values(): latest=maxf(latest,time)
		if world.logic_time-latest>5:
			chain_times={}
			for node in chain_nodes.values(): node.show()
			for target in world.blast_targets: target.spent=false

func interact(id:String) -> bool:
	if id=="bomb_supply":
		world.state.seeds=30
		if world.state.bomb_bag: world.state.bomb_count=20
		world.tell("Supply jar", "Fresh seeds"+(" and twenty bombs." if world.state.bomb_bag else ". Bomb Flowers can be picked with the Goron's Bracelet."))
		return true
	if id=="bomb_bag":
		if world.state.bomb_bag:
			world.tell("Bomb Bag", "The chest is empty. Supply jars can refill your bag.")
			return true
		world.state.bomb_bag=true
		world.state.bomb_count=20
		world.open_chest("bomb_bag")
		world.tell("Bomb Bag", "You found a Bomb Bag! C takes out a bomb; C again throws it. E puts it down. Find supply jars when your bag runs low.")
		return true
	if id=="ruby":
		if not world.state.ruby:
			world.state.ruby=true
			world.state.max_health+=2
		world.state.health=world.state.max_health
		world.overworld.enter("trail","dodongo")
		world.tell("Darunia", "You saved our cavern! We are brothers now. Take the Goron's Ruby. May the strength of the mountain stay with you, wherever the river leads next.")
		return true
	if not id.begins_with("dodongo:"): return false
	var next=id.trim_prefix("dodongo:")
	if next=="trail": world.overworld.enter("trail","dodongo")
	elif next=="stairs" and not world.state.dodongo_duel: world.tell("Navi", "The two Lizalfos still guard the passage.")
	elif next=="gallery" and not world.state.dodongo_stairs: world.tell("Navi", "The staircase is sealed. Burst both ends of the row together.")
	elif next=="armory" and "gallery" not in world.state.dodongo_switches: world.tell("Navi", "The eye controls this door. Aim with Q and fire with R.")
	elif next=="skull" and not world.state.bomb_bag: world.tell("Navi", "The way up is barred from this side. Follow the eastern passage to find the Bomb Bag.")
	elif next=="king" and (world.state.dodongo_eyes.size()<2 or not world.state.bomb_bag): world.tell("Navi", "Light both eyes of the giant skull from the bridge above.")
	else: enter(next,room)
	return true

func objective() -> String:
	match room:
		"cavern": return "DODONGO'S CAVERN · Follow the eastern passage; awaken both eyes"
		"duel": return "DODONGO'S CAVERN · Defeat the two Lizalfos guards"
		"stairs": return "DODONGO'S CAVERN · Burst both ends of the Bomb Flower row together"
		"gallery": return "DODONGO'S CAVERN · Cross the stone ramps and shoot the eye"
		"armory": return "DODONGO'S CAVERN · Find the Bomb Bag on the raised altar"
		"skull": return "DODONGO'S CAVERN · Place a bomb into each eye socket"
		"king": return "KING DODONGO · Bomb the open mouth, strike the opening, evade the roll" if not world.state.king_dodongo else "DODONGO'S CAVERN · Take the Goron's Ruby"
	return "DODONGO'S CAVERN"
