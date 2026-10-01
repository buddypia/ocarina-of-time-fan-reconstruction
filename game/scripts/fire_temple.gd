extends RefCounted
const Art=preload("res://scripts/art.gd")
const A=preload("res://scripts/fire_art.gd")
const G=preload("res://scripts/grave_art.gd")
var world:Node3D
var data:Dictionary
var room:=""
var cages:Dictionary={}
var buttons:Dictionary={}
var prisoners:Dictionary={}
var lava:ShaderMaterial
var cracked:Node3D
var chief:Node3D
var pots:Array=[]
var lifting:Dictionary={}

func _init(owner_world:Node3D) -> void:
	world=owner_world
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/fire_mountain.json"))

func reset() -> void:
	room="";cages={};buttons={};prisoners={};pots=[];lifting={};lava=null;cracked=null;chief=null

func add_use(id:String,at:Vector3,label:String) -> void:
	world.interactions.append({"id":"fire_t:"+id,"position":[at.x,at.y,at.z],"label":label})

func enter(next:String,from:String="") -> void:
	if next=="crater":
		world.overworld.enter("crater");world.player.position=Vector3(0,.1,-22);world.fire_quest.safe_at=world.player.position;world.player.update_camera(1);return
	if not data.rooms.has(next): return
	world.clear_landscape();room=next;world.area="fire_"+next;world.overworld.scene=world.landscape
	var spec=data.rooms[room]
	A.chamber(world,Vector2(spec.size[0],spec.size[1]),spec.lava)
	if spec.lava: lava=A.lava(world,Vector2(spec.size[0],spec.size[1]),-1.2)
	world.player.position=Vector3(0,.1,float(spec.size[1])*.5-5);world.player.velocity=Vector3.ZERO;world.player.climbing=false;world.player.yaw=0
	build_room()
	for passage in spec.exits:
		var at=world.vec(passage.at);var inward=Vector3(-at.x,0,-at.z).normalized()
		A.portal(world.landscape,at,atan2(inward.x,inward.z))
		add_use("door:"+passage.to,at+inward*.8,"Enter "+str(data.rooms.get(passage.to,{"name":"Death Mountain Crater"}).name))
		if from==passage.to:
			world.player.position=at+inward*3.8+Vector3.UP*.1
			world.player.yaw=atan2(-inward.x,-inward.z)
	world.fire_quest.safe_at=world.player.position
	world.apply_state();Art.batch_static(world.landscape)
	world.player.visual.rotation.y=world.player.yaw;world.player.update_camera(1)
	world.checkpoint={"area":world.area,"position":world.player.position}
	world.tell(spec.name,objective())

func bridge(a:Vector3,b:Vector3,width:float=3) -> void:
	var root=Art.walkway(world.landscape,a,b,width,Color.WHITE,true)
	for mesh in root.find_children("*","MeshInstance3D",true,false): mesh.material_override=A.basalt()
	for t in range(int(a.distance_to(b)/2)+1):
		var at=a.lerp(b,minf(1,t*2/a.distance_to(b)))
		G.rod(world.landscape,at-Vector3.UP*.30,at-Vector3.UP*1.5,.15,Color("514437"))

func build_room() -> void:
	match room:
		"foyer":
			for side in [-1,1]:
				A.block(world.landscape,Vector3(side*7,1.6,-7),Vector3(2,3.2,2))
				A.goron(world.landscape,Vector3(side*7,3.2,-7),.8)
			add_use("lower_seal",Vector3(0,0,-10),"Inspect the heavy stone seal")
			A.block(world.landscape,Vector3(0,1.4,-12),Vector3(3.5,2.8,1))
		"near":
			A.platform(world.landscape,Vector3(0,0,10),Vector2(9,8),2)
			A.platform(world.landscape,Vector3(-8,0,-9),Vector2(9,10),2)
			A.platform(world.landscape,Vector3(8,0,-10),Vector2(10,8),2)
			bridge(Vector3(0,0,7),Vector3(-8,0,3));bridge(Vector3(-8,0,3),Vector3(-8,0,-5))
			chief=A.goron(world.landscape,Vector3(2,0,9),1.15)
			chief.visible=world.state.fire_darunia_stage<2
			if world.state.fire_darunia_stage>=2: world.hide_breakable(chief)
			if world.state.fire_darunia_stage<2: add_use("darunia",Vector3(2,0,10.3),"Speak to Darunia")
			prison("near",Vector3(-8,0,-7),Vector3(-8,0,-4.5))
			A.portal(world.landscape,Vector3(8,0,-12))
			add_use("boss_seal",Vector3(8,0,-11),"Inspect the dragon door")
		"lava":
			for at in [Vector3(0,0,14),Vector3(0,0,-14),Vector3(-13,0,0),Vector3(13,0,0)]: A.platform(world.landscape,at,Vector2(7,7),2)
			bridge(Vector3(0,0,14),Vector3(0,0,-14),3.2)
			bridge(Vector3(-13,0,0),Vector3(13,0,0),3.2)
			if not "cell_wall" in world.state.fire_walls:
				cracked=Node3D.new();cracked.position=Vector3(12.1,0,0);cracked.set_meta("animated",true);world.landscape.add_child(cracked)
				A.block(cracked,Vector3(0,1.8,0),Vector3(.75,3.6,4))
				for z in [-1,-.3,.5,1.2]: G.rod(cracked,Vector3(-.4,.4,z),Vector3(-.4,3,z+.35),.035,Color("22201e"))
				world.blast_targets.append({"id":"fire:cell_wall","position":Vector3(12.1,1.2,0),"node":cracked,"spent":false,"radius":1.6})
			A.block(world.landscape,Vector3(0,1.8,-17),Vector3(4,3.6,1))
			add_use("shaft",Vector3(0,0,-15),"Examine the sealed rising shaft")
		"curved","blocked": prison(room,Vector3(0,0,-4),Vector3(-3,0,-1))
	for at in [Vector3(-3,0,float(data.rooms[room].size[1])*.5-4),Vector3(3,0,float(data.rooms[room].size[1])*.5-4)]: supply(at)

func supply(at:Vector3) -> void:
	var pot=G.sphere(world.landscape,at+Vector3.UP*.4,Vector3(.32,.42,.32),Color("a58462"))
	pot.set_meta("animated",true)
	add_use("supply:"+str(pots.size()),at,"Break the supply jar")
	pots.append(pot)

func prison(id:String,at:Vector3,switch_at:Vector3) -> void:
	cages[id]=A.cage(world.landscape,at)
	buttons[id]=A.button(world.landscape,switch_at,id in world.state.fire_rescued)
	prisoners[id]=A.goron(world.landscape,at+Vector3(-.8,0,-2),.80)
	var chest=Art.chest(world.landscape,at+Vector3(1,0,-2))
	world.chest_nodes["fire_"+id]=chest
	if id in world.state.fire_chests: chest.get_node("Lid").rotation.x=-1.15
	if id in world.state.fire_rescued: cages[id].get_node("Bars").position.y=3.4
	add_use("prisoner:"+id,at+Vector3(-.8,0,-.7),"Speak with the freed Goron")
	add_use("chest:"+id,at+Vector3(1,0,-.7),"Open the prisoner's chest")

func interact(id:String) -> bool:
	if not id.begins_with("fire_t:"): return false
	var action=id.trim_prefix("fire_t:")
	if action.begins_with("door:"):
		var next=action.trim_prefix("door:")
		for passage in data.rooms[room].exits:
			if passage.to!=next: continue
			if passage.has("bomb") and not passage.bomb in world.state.fire_walls:
				world.tell("Cracked masonry","A blast could break this wall.");return true
			if passage.has("key") and not passage.key in world.state.fire_doors:
				if world.state.fire_keys<=0:
					world.tell("Locked door","You need a Small Key from this temple. Search the prisoners' cells.");return true
				world.state.fire_keys-=1;world.state.fire_doors.append(passage.key);world.chime(550,.1)
			enter(next,room);return true
	elif action.begins_with("chest:"):
		var prisoner=action.trim_prefix("chest:")
		if not prisoner in world.state.fire_rescued:
			world.tell("Iron bars","Find the floor switch that opens this cell.");return true
		if prisoner in world.state.fire_chests:
			world.tell("Empty chest","You have already taken this Small Key.");return true
		world.state.fire_chests.append(prisoner);world.state.fire_keys+=1
		world.chest_nodes["fire_"+prisoner].get_node("Lid").rotation.x=-1.15
		world.tell("Small Key","A key to one locked door in the Fire Temple. Keys already used stay with their opened doors.");world.chime(720,.18)
	elif action.begins_with("prisoner:"):
		var prisoner=action.trim_prefix("prisoner:")
		world.tell("Goron prisoner",data.prisoners[prisoner] if prisoner in world.state.fire_rescued else "The floor switch outside should lift these bars. Please hurry!")
	elif action=="darunia":
		if world.state.fire_darunia_stage<2:
			world.tell("Darunia",data.darunia[world.state.fire_darunia_stage]);world.state.fire_darunia_stage+=1
			if world.state.fire_darunia_stage>=2:
				world.hide_breakable(chief)
				world.interactions=world.interactions.filter(func(item): return item.id!="fire_t:darunia")
	elif action.begins_with("supply:"):
		var index=int(action.trim_prefix("supply:"))
		if index<0 or index>=pots.size() or not pots[index].visible: return true
		pots[index].hide()
		world.interactions=world.interactions.filter(func(item): return item.id!=id)
		world.state.health=mini(world.state.max_health,world.state.health+2);world.state.bomb_count=maxi(world.state.bomb_count,5);world.state.arrows=maxi(world.state.arrows,10)
		world.tell("Temple supplies","A heart, five bombs and ten arrows are kept here for the rescue.")
	elif action=="lower_seal": world.tell("Ancient seal","The heavy stone bears the mark of a hammer.")
	elif action=="boss_seal": world.tell("The dragon's chamber","A large golden lock seals this door. The bridge support must also be lowered from above.")
	elif action=="shaft": world.tell("End of the current chapter","The upper prison maze is beyond this preview. Rescue the three Gorons below, then use the Bolero of Fire to return to the crater. Your journey can be saved with F5.")
	return true

func blast_wall(id:String,node:Node3D) -> void:
	var key=id.trim_prefix("fire:")
	if not key in world.state.fire_walls: world.state.fire_walls.append(key)
	world.hide_breakable(node);world.tell("A hidden cell","The fractured wall falls away. A prisoner is waiting beyond the eastern door.")

func tick(_delta:float) -> void:
	if lava: lava.set_shader_parameter("clock",world.logic_time)
	world.fire_quest.check_lava(-.65)
	for id in buttons:
		if id in world.state.fire_rescued: continue
		var at=buttons[id].position
		if world.player.position.distance_to(at)<.70 and world.player.is_on_floor():
			world.state.fire_rescued.append(id);lifting[id]=0.0;buttons[id].get_node("Plate").position.y=.07
			world.chime(640,.2);world.tell("Cell opened","The iron bars lift. Speak with the prisoner and search the chest inside.")

func physics_tick(delta:float) -> void:
	for id in lifting.keys():
		lifting[id]=minf(1.6,lifting[id]+delta)
		cages[id].get_node("Bars").position.y=3.4*smoothstep(0,1,lifting[id]/1.6)
		if lifting[id]>=1.6: lifting.erase(id)

func objective() -> String:
	if not world.area.begins_with("fire_"): return ""
	var keys=" · KEYS %d · RESCUED %d" % [world.state.fire_keys,world.state.fire_rescued.size()]
	match room:
		"foyer": return "FIRE TEMPLE · Search west for Darunia; the east door needs a key"+keys
		"near": return "FIRE TEMPLE · Cross to the western cell and step on its floor switch"+keys
		"lava": return "FIRE TEMPLE · Free the Gorons in both side cells"+keys
		"curved","blocked": return "FIRE TEMPLE · Open the cell; speak to the prisoner; collect the key"+keys
	return "FIRE TEMPLE"+keys
