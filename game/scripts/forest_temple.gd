extends RefCounted

const Art=preload("res://scripts/art.gd")
const F=preload("res://scripts/forest_temple_art.gd")
const G=preload("res://scripts/grave_art.gd")
var world:Node3D
var data:Dictionary
var room:=""
var targets:Dictionary={}
var hook_targets:Array=[]
var doors:Dictionary={}
var blocks:Dictionary={}
var moving:Dictionary={}
var pots:Array=[]
var portrait_index:=0
var portrait_time:=0.0
var bow_stage:=0
var revival:=0.0
var amy_time:=0.0
var ceiling_time:=0.0
var ceiling:Node3D
var rotor:AnimatableBody3D
var boss:CharacterBody3D
var time_stone:Node3D
var flames:Dictionary={}
var basement:Node3D
var basement_buttons:Dictionary={}
var rotation_time:=0.0
var rotation_start:=0.0
var rotation_end:=0.0

static func defaults() -> Dictionary:
	return {"bow":false,"arrows":0,"adult_tool":"hookshot","forest_keys":0,"forest_chests":[],"forest_doors":[],"forest_clear":[],"forest_poes":[],"forest_portraits":[],"forest_blocks":{},"forest_time_block":false,"forest_well_drained":false,"forest_straight_w":false,"forest_eye_east":false,"forest_frozen_eye":false,"forest_amy_solved":false,"forest_basement_switches":[],"forest_basement_rotation":0,"forest_boss_key":false,"forest_map":false,"forest_compass":false,"phantom_ganon":false,"forest_saria_stage":0,"forest_sprout_stage":0,"woods_stage":0,"woods_mido":false}

func _init(owner_world:Node3D) -> void:
	world=owner_world
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/forest_temple.json"))

func reset() -> void:
	room=""
	basement_buttons={};rotation_time=0
	targets={};hook_targets=[];doors={};blocks={};moving={};pots=[];flames={}
	ceiling=null;rotor=null;boss=null;time_stone=null;basement=null
	portrait_time=0;portrait_index=0;bow_stage=0;revival=0;amy_time=0;ceiling_time=0

func enter(next:String,from:String="") -> void:
	if next=="meadow":
		world.overworld.enter("meadow")
		world.player.position=Vector3(0,4.1,-23)
		world.player.update_camera(1)
		return
	if not data.rooms.has(next): return
	world.clear_landscape()
	room=next
	world.area="ft_"+room
	world.overworld.scene=world.landscape
	var spec=data.rooms[room]
	F.chamber(world,Vector2(spec.size[0],spec.size[1]),spec.open_sky)
	world.player.position=Vector3(0,.1,float(spec.size[1])*.5-7)
	world.player.velocity=Vector3.ZERO
	world.player.climbing=false
	world.player.yaw=0
	world.apply_state()
	build_room()
	for exit in spec.exits:
		var at=world.vec(exit.at)
		var inward=Vector3(-at.x,0,-at.z).normalized()
		if at.length()<1: inward=Vector3.BACK
		if (room=="lobby" and exit.to=="basement") or (room=="basement" and exit.to=="lobby"):
			var lift=F.block(world.landscape,at+Vector3.UP*.025,Vector3(3,.05,3))
			lift.material_override=Art.material(Color("48625a"),.65,.25)
		else: F.portal(world.landscape,at,atan2(inward.x,inward.z))
		var gate:StaticBody3D
		if (room=="lobby" and exit.to=="basement") or (room=="basement" and exit.to=="lobby"):
			gate=StaticBody3D.new();world.landscape.add_child(gate)
		else: gate=Art.collision_box(world.landscape,at+Vector3.UP*1.5,Vector3(2.5,3,.25))
		gate.rotation.y=atan2(inward.x,inward.z)
		doors[exit.to]=gate
		add_use("door:"+exit.to,at+inward*.7,"Enter "+str(data.rooms.get(exit.to,{"name":"Sacred Forest Meadow"}).name))
		if exit.to==from:
			world.player.position=at+inward*(1.4 if at.y>0 else 4.8)+Vector3.UP*.1
			world.player.yaw=atan2(-inward.x,-inward.z)
	if room=="frozen" and from in ["twist_e",""]: world.player.position=Vector3(0,.1,12.5)
	if room=="basement" and from=="lobby": world.player.position=Vector3(0,.1,2.4)
	refresh()
	Art.batch_static(world.landscape)
	world.player.visual.rotation.y=world.player.yaw
	world.player.update_camera(1)
	world.checkpoint={"area":world.area,"position":world.player.position}
	world.tell(spec.name,objective())

func add_use(id:String,at:Vector3,label:String) -> void:
	world.interactions.append({"id":"ft_"+id,"position":[at.x,at.y,at.z],"label":label})

func chest(id:String,at:Vector3) -> void:
	var node=Art.chest(world.landscape,at)
	world.chest_nodes[id]=node
	if id in world.state.forest_chests: node.get_node("Lid").rotation.x=-1.15
	add_use("chest:"+id,at+Vector3.BACK*1.1,"Open chest")

func supply(at:Vector3) -> void:
	var id=str(pots.size())
	var pot=Node3D.new()
	world.landscape.add_child(pot)
	pot.position=at
	pot.set_meta("animated",true)
	G.sphere(pot,Vector3(0,.42,0),Vector3(.37,.44,.37),Color("a08060"))
	Art.cylinder(pot,Vector3(0,.78,0),.20,.25,.14,Color("574b40"),64)
	pots.append(pot)
	add_use("pot:"+id,at,"Break supply jar")

func ladder(id:String,base:Vector3,top:Vector3,exit_offset:Vector3=Vector3(0,0,-1.2)) -> void:
	for side in [-1,1]: G.rod(world.landscape,base+Vector3(side*.4,0,0),top+Vector3(side*.4,.3,0),.045,Color("535b34"))
	for i in range(int((top.y-base.y)/.30)+1): G.rod(world.landscape,base+Vector3(-.4,i*.30,0),base+Vector3(.4,i*.30,0),.03,Color("697745"))
	world.ladders.append({"id":id,"base":base,"top":top,"exit_offset":exit_offset})
	add_use("climb:"+id,base,"Climb vines")

func make_target(id:String,at:Vector3,eye:bool=true) -> Area3D:
	var target=Area3D.new()
	target.set_script(preload("res://scripts/forest_target.gd"))
	target.dungeon=self
	target.target_id=id
	target.position=at
	target.set_meta("animated",true)
	world.landscape.add_child(target)
	if eye:
		var visual=Node3D.new()
		target.add_child(visual)
		G.sphere(visual,Vector3.ZERO,Vector3(.65,.40,.12),Color("aa864a"))
		G.sphere(visual,Vector3(0,0,.13),Vector3(.20,.28,.06),Color("416373"))
		G.sphere(visual,Vector3(0,0,.19),Vector3(.065,.16,.035),Color("171d1b"))
		target.visual=visual
	targets[id]=target
	return target

func spawn(kind:String,id:String,at:Vector3) -> CharacterBody3D:
	var enemy=CharacterBody3D.new()
	enemy.set_script(preload("res://scripts/forest_enemy.gd"))
	enemy.world=world;enemy.kind=kind;enemy.enemy_id=id;enemy.position=at
	if kind=="poe": enemy.color=Color({"joelle":"9e5b51","beth":"5286ab","amy":"649760","meg":"8e6aab"}.get(id,"9e5b51"))
	world.landscape.add_child(enemy)
	world.creatures.append(enemy)
	return enemy

func build_room() -> void:
	match room:
		"trees":
			F.block(world.landscape,Vector3(-9,1.5,-6),Vector3(6,3,8),true)
			ladder("tree",Vector3(-7,0,-1.7),Vector3(-7,3,-1.7))
			chest("tree_key",Vector3(-9,3,-7))
			spawn("skulltula","entrance_spider",Vector3(3,0,-4))
		"hall": spawn("skulltula","hall_spider",Vector3(0,0,0))
		"lobby": build_lobby()
		"north":
			if not cleared("north"):
				spawn("stalfos","north_a",Vector3(-4,0,-2));spawn("stalfos","north_b",Vector3(4,0,-5))
			chest("guard_key",Vector3(0,0,-8))
		"west","east": build_courtyard()
		"map":
			if not cleared("map"): spawn("bubble","map_guard",Vector3(0,0,-2))
			chest("map",Vector3(5,0,-6))
		"well":
			chest("well_key",Vector3(0,0,0))
			for z in range(-10,11,4): F.arch(world.landscape,Vector3(0,3,z),5,2.5,.4)
		"blocks": build_blocks()
		"twist_w":
			make_target("straight_w",Vector3(0,4,8))
			for z in [-6,-2,2,6]:
				var arch=Node3D.new();world.landscape.add_child(arch);arch.position=Vector3(0,0,z)
				arch.rotation.z=0 if world.state.forest_straight_w else z*.05
				F.arch(arch,Vector3(0,3,0),6,3,.4)
		"boss_key": chest("boss_key",Vector3(-4,0,-4))
		"below":
			if not cleared("below"): spawn("bubble","below_guard",Vector3(0,0,-1))
		"west_upper": pass
		"floormaster":
			if not cleared("floormaster"): spawn("floormaster","hand",Vector3(0,0,-1))
			chest("hand_key",Vector3(0,0,-8))
		"red","blue": build_portraits()
		"bow":
			if not cleared("bow"): spawn("stalfos","bow_first",Vector3(0,0,-3))
			chest("bow",Vector3(5,0,-8))
		"twist_e":
			for z in [-5,0,5]: F.arch(world.landscape,Vector3(0,3,z),6,3,.5)
		"frozen": build_frozen()
		"ceiling": build_ceiling()
		"green": build_amy()
		"basement": build_basement()
		"boss": build_boss()
		"saria":
			world.overworld.scene=world.landscape
			world.overworld.make_person({"id":"forest_saria","name":"Saria","style":"saria","at":[0,0,-5],"lines":data.saria},false)
			add_use("saria",Vector3(0,0,-3.5),"Speak to Saria")
	if room in ["lobby","north","blocks","red","bow","blue","frozen","green","boss"]:
		supply(Vector3(-5,0,7));supply(Vector3(5,0,7))

func build_lobby() -> void:
	var colors={"joelle":"ab5946","beth":"477cac","amy":"5f9160","meg":"8a5fa6"}
	for i in range(4):
		var id=colors.keys()[i]
		var at=Vector3(-5 if i%2==0 else 5,0,-5 if i<2 else 5)
		F.block(world.landscape,at+Vector3.UP*.4,Vector3(1.3,.8,1.3),true)
		G.rod(world.landscape,at+Vector3.UP*.8,at+Vector3.UP*1.2,.07,Color("514d3b"))
		var flame=G.lantern(world.landscape,at+Vector3.UP*1.5,1.3,Color(colors[id]))
		flame.scale=Vector3.ONE*1.5
		flame.set_meta("animated",true)
		flames[id]=flame
		flame.visible=id in world.state.forest_poes
	make_target("east",Vector3(12,4,-7))
	time_stone=F.block(world.landscape,Vector3(-12,1.5,-7),Vector3(2,3,3),true)
	time_stone.material_override=Art.material(Color("568190"),.8)
	time_stone.set_meta("animated",true)
	if world.state.forest_time_block: world.hide_breakable(time_stone)
	if world.state.forest_poes.size()==3 and not "meg" in world.state.forest_poes: boss=spawn("poe","meg",Vector3.ZERO)

func build_courtyard() -> void:
	F.block(world.landscape,Vector3(-9,2,-13),Vector3(8,4,6),true)
	F.block(world.landscape,Vector3(0,2,-13),Vector3(12,4,6),true)
	if room=="west": ladder("court",Vector3(-9,0,-9.4),Vector3(-9,4,-9.4))
	else:
		F.block(world.landscape,Vector3(-6,4.06,-12),Vector3(1,.12,1))
		add_use("drain",Vector3(-6,4,-12),"Press the well switch")
		make_target("east",Vector3(10,3,7))
	F.block(world.landscape,Vector3(8,.25,-8),Vector3(3,.5,3))
	if not world.state.forest_well_drained:
		var water=G.sphere(world.landscape,Vector3(8,.53,-8),Vector3(1.2,.03,1.2),Color("386f72"))
		water.name="WellWater"
		water.set_meta("animated",true)

func cleared(id:String) -> bool: return id in world.state.forest_clear
func mark_clear(id:String) -> void:
	if not cleared(id): world.state.forest_clear.append(id)

func condition(requirement:String) -> bool:
	match requirement:
		"time_block": return world.state.forest_time_block
		"map_guard": return cleared("map")
		"below_guard": return cleared("below")
		"drained": return world.state.forest_well_drained
		"eye_east": return world.state.forest_eye_east
		"twisted_w": return not world.state.forest_straight_w
		"straight_w": return world.state.forest_straight_w
		"bow": return world.state.bow
		"frozen_eye": return world.state.forest_frozen_eye
		"amy": return "amy" in world.state.forest_poes
		"four_poes": return world.state.forest_poes.size()==4
		"boss_door": return world.state.forest_boss_key and world.state.forest_basement_switches.size()==3
	return true

func may_pass(exit:Dictionary) -> bool:
	if not condition(exit.get("require","")): return false
	if room=="lobby" and exit.to=="east" and not world.state.forest_eye_east: return false
	if room=="lobby" and exit.to=="green" and not "amy" in world.state.forest_poes: return false
	if room=="blocks" and exit.to=="west_upper" and not world.state.forest_boss_key: return false
	if room=="bow" and not cleared("bow"): return false
	if room=="north" and not cleared("north"): return false
	if room=="boss" and not world.state.phantom_ganon: return false
	return true

func refresh() -> void:
	if not world.area.begins_with("ft_"): return
	for exit in data.rooms[room].exits:
		var locked=not exit.get("lock","").is_empty() and not exit.lock in world.state.forest_doors
		if doors.has(exit.to): doors[exit.to].collision_layer=1 if locked or not may_pass(exit) else 0
	for id in world.chest_nodes:
		world.chest_nodes[id].visible=chest_available(id)
	for id in flames: flames[id].visible=id in world.state.forest_poes
	if targets.has("frozen"):
		targets.frozen.get_node("FrozenCrust").visible=not world.state.forest_frozen_eye

func chest_available(id:String) -> bool:
	match id:
		"guard_key": return cleared("north")
		"map": return cleared("map")
		"hand_key": return cleared("floormaster")
		"red_key": return "joelle" in world.state.forest_poes
		"compass": return "beth" in world.state.forest_poes
		"bow": return cleared("bow")
	return true

func interact(id:String) -> bool:
	if not id.begins_with("ft_"): return false
	var action=id.trim_prefix("ft_")
	if action.begins_with("door:"):
		var next=action.trim_prefix("door:")
		for exit in data.rooms[room].exits:
			if exit.to!=next: continue
			if not may_pass(exit): world.tell("Sealed passage","The mechanism or curse holding this passage has not been released.");return true
			var lock_id=exit.get("lock","")
			if not lock_id.is_empty() and not lock_id in world.state.forest_doors:
				if world.state.forest_keys<=0: world.tell("Locked door","A small key is needed. Search the temple's side rooms and courtyards.");return true
				world.state.forest_keys-=1
				world.state.forest_doors.append(lock_id)
			enter(next,room)
			return true
	elif action.begins_with("chest:"):
		var key=action.trim_prefix("chest:")
		if not chest_available(key): return true
		if key in world.state.forest_chests: world.tell("Empty chest","You already took this treasure.");return true
		world.state.forest_chests.append(key)
		world.open_chest(key)
		if data.key_chests.has(key): world.state.forest_keys+=1;world.tell("Small key","A key for the Forest Temple. Unlocked doors stay unlocked.")
		else:
			match key:
				"bow": world.state.bow=true;world.state.arrows=30;world.state.adult_tool="bow";world.tell("Fairy Bow","Hold R to draw; release to shoot. Q focuses a target. X switches between Bow and Hookshot. Supply jars refill arrows.")
				"boss_key": world.state.forest_boss_key=true;world.tell("Boss Key","This ornate key opens the door beneath the four flames.")
				"map": world.state.forest_map=true;world.tell("Dungeon Map","Two courtyards share a well. The western block room leads toward the missing flames.")
				"compass": world.state.forest_compass=true;world.tell("Compass","The remaining sisters haunt the portrait puzzle and the central hall.")
	elif action.begins_with("climb:"):
		var key=action.trim_prefix("climb:")
		for route in world.ladders:
			if route.id==key: world.player.start_climbing(route.base,route.top,route.exit_offset)
	elif action.begins_with("pot:"):
		var index=int(action.trim_prefix("pot:"))
		if pots[index].visible:
			pots[index].hide()
			if world.state.bow: world.state.arrows=mini(30,int(world.state.arrows)+10)
			world.state.health=mini(int(world.state.max_health),int(world.state.health)+2)
			world.tell("Supply jar","A bundle of arrows and a small heart. More jars await in the next rooms.")
	elif action=="ceiling_hint": world.tell("Worn floor","Pale squares lie beneath openings. Cross while the ceiling rises; wait on a marked square when the stone trembles.")
	elif action=="drain":
		world.state.forest_well_drained=true
		var water=world.landscape.get_node_or_null("WellWater")
		if water: water.hide()
		world.tell("The well","Water drains from both courtyards. The channel below is passable.")
	elif action.begins_with("push:"): push_block(action.trim_prefix("push:"))
	elif action=="rotate": rotate_basement()
	elif action.begins_with("switch:"):
		var index=int(action.trim_prefix("switch:"))
		if rotation_time<=0 and int(world.state.forest_basement_rotation)==index and not index in world.state.forest_basement_switches:
			world.state.forest_basement_switches.append(index);world.chime(1050,.3)
			basement_buttons[index].material_override=Art.material(Color("62866e"),.8)
			world.tell("Alcove switch",str(world.state.forest_basement_switches.size())+" of three seals released.")
	elif action=="reward": enter("saria")
	elif action=="saria":
		var stage=int(world.state.forest_saria_stage)
		world.tell("Saria",data.saria[mini(stage,data.saria.size()-1)])
		world.state.forest_saria_stage+=1
		if world.state.forest_saria_stage>=2:
			var first_reward=not world.state.forest_medallion
			if first_reward:
				world.state.forest_medallion=true
				world.state.max_health+=2;world.state.health=world.state.max_health
			world.return_forest()
			if first_reward: world.tell("Forest Medallion","Saria's power joins yours. The forest can grow again. The Master Sword can now carry you between the two ages at the Temple of Time.")
			else: world.tell("Saria",data.saria.back())
	refresh()
	return true

func on_song(id:String) -> bool:
	if world.area=="ft_lobby" and id=="time" and world.player.position.distance_to(Vector3(-12,0,-7))<5:
		world.state.forest_time_block=true
		world.hide_breakable(time_stone)
		refresh()
		world.tell("Song of Time","The blue stone disappears. A courtyard waits beyond.")
		return true
	return false

func objective() -> String:
	if not world.area.begins_with("ft_"): return ""
	var hint="Find the missing flames"
	match room:
		"trees": hint="Climb the roots to search the high chest"
		"north": hint="Guard the Stalfos strikes; attack their recovery"
		"west": hint="Climb the vines to the upper passage"
		"east": hint="The upper courtyard switch drains both wells"
		"blocks": hint="E pushes each block along its worn track; climb when aligned"
		"red","blue": hint="Shoot the portraits from a distance; pursue the revealed sister"
		"bow": hint="Defeat both Stalfos before a fallen warrior rises again"
		"twist_w": hint="An arrow changes the corridor and the route beyond"
		"frozen": hint="Shoot through the central flame to thaw the frozen eye"
		"ceiling": hint="Wait beneath the marked openings when the ceiling falls"
		"green": hint="Shoot the portrait, then push its four pieces into the central square"
		"basement": hint="Rotate the wall; press the three revealed switches"
		"boss": hint="Shoot the true rider; return his magic with your sword"
		"saria": hint="Speak with the awakened sage"
	return data.rooms[room].name.to_upper()+" · "+hint+" · KEYS "+str(int(world.state.forest_keys))+" / FLAMES "+str(world.state.forest_poes.size())+" of 4"

func build_blocks() -> void:
	F.block(world.landscape,Vector3(0,1,-9),Vector3(24,2,12),true)
	F.block(world.landscape,Vector3(7,1,-2),Vector3(10,2,2),true)
	F.block(world.landscape,Vector3(4,3,-14),Vector3(8,2,6),true)
	create_block("green",Vector3(-4,0,4),Color("6b7955"),2)
	create_block("brown",Vector3(4,2,-4),Color("8e7659"),2)
	update_block_ladders()
	for x in [-4,4]:
		for z in range(-10,7,2): F.block(world.landscape,Vector3(x,.02 if x<0 else 2.02,z),Vector3(.10,.035,1.7))

func create_block(id:String,at:Vector3,color:Color,size:float) -> void:
	var node=Node3D.new()
	node.set_meta("animated",true)
	world.landscape.add_child(node)
	node.position=world.vec(world.state.forest_blocks[id]) if world.state.forest_blocks.has(id) and room=="blocks" else at
	var stone=F.block(node,Vector3.UP*size*.5,Vector3.ONE*size,true)
	stone.material_override=F.masonry().duplicate()
	stone.material_override.albedo_color=color
	blocks[id]={"node":node,"origin":at,"size":size}
	add_use("push:"+id,node.position+Vector3.BACK*(size*.5+.4),"Push the carved block")

func update_block_ladders() -> void:
	if blocks.has("green") and blocks.green.node.position.z<=-1.9 and not has_ladder("green"):
		ladder("green",Vector3(-4,0,-.8),Vector3(-4,2,-.8))
	if blocks.has("brown") and blocks.brown.node.position.z<=-9.9 and not has_ladder("brown"):
		ladder("brown",Vector3(4,2,-8.8),Vector3(4,4,-8.8))

func has_ladder(id:String) -> bool:
	for route in world.ladders:
		if route.id==id: return true
	return false

func push_block(id:String) -> void:
	if not moving.is_empty() or not blocks.has(id): return
	if room=="green" and amy_time<=0: return
	var node=blocks[id].node
	var offset=node.position-world.player.position
	offset.y=0
	if offset.length()>2.9: return
	var direction=Vector3(signf(offset.x),0,0) if absf(offset.x)>absf(offset.z) else Vector3(0,0,signf(offset.z))
	var destination:Vector3=node.position+direction*(2.2 if room=="green" else 2.0)
	if room=="blocks":
		if direction!=Vector3.FORWARD: world.tell("Worn track","The stone slides north along the worn track.");return
		if (id=="green" and destination.z< -2.1) or (id=="brown" and destination.z< -10.1): return
	else:
		if absf(destination.x)>8 or absf(destination.z)>8: return
		for other in blocks:
			if other!=id and destination.distance_to(blocks[other].node.position)<2.1: return
	moving={"id":id,"start":node.position,"end":destination,"time":0.0}

func portrait_frame(parent:Node3D,at:Vector3,color:Color,size:Vector2=Vector2(2.2,2.8)) -> Node3D:
	var root=Node3D.new();parent.add_child(root);root.position=at
	root.set_meta("animated",true)
	for side in [-1,1]:
		G.rod(root,Vector3(side*size.x*.5,-size.y*.5,0),Vector3(side*size.x*.5,size.y*.5,0),.09,Color("947544"))
		G.rod(root,Vector3(-size.x*.5,side*size.y*.5,0),Vector3(size.x*.5,side*size.y*.5,0),.09,Color("947544"))
	Art.box(root,Vector3(0,0,-.09),Vector3(size.x,size.y,.10),Color("252e30"))
	G.sphere(root,Vector3(0,0,.03),Vector3(.4,.8,.06),color)
	return root

func build_portraits() -> void:
	var id="joelle" if room=="red" else "beth"
	var color=Color("a45c4d") if room=="red" else Color("4d80b7")
	chest("red_key" if room=="red" else "compass",Vector3(-7,0,-7))
	if id in world.state.forest_poes: return
	for i in range(3):
		var target=make_target(id+"_"+str(i),Vector3(-7+i*7,3,-10),false)
		target.visual=portrait_frame(target,Vector3.ZERO,color)
		if target.target_id in world.state.forest_portraits: target.spent=true;target.set_active(false)
	activate_portrait(id)

func activate_portrait(id:String) -> void:
	var remaining=[]
	for i in range(3):
		var key=id+"_"+str(i)
		if not key in world.state.forest_portraits: remaining.append(key)
	if remaining.is_empty():
		boss=spawn("poe",id,Vector3(0,0,-2))
		return
	portrait_index=posmod(portrait_index,remaining.size())
	for key in targets:
		if key.begins_with(id+"_"): targets[key].set_active(key==remaining[portrait_index])

func hit_target(id:String,projectile:String) -> void:
	if id.begins_with("meg_"):
		if is_instance_valid(boss): boss.hit_clone(int(id.trim_prefix("meg_")))
		return
	match id:
		"phantom_decoy": world.tell("A false rider","The pale rider fades into the picture. Watch the other frame.");return
		"east": world.state.forest_eye_east=true;world.tell("The eye opens","The eastern courtyard now connects to the central hall.")
		"straight_w":
			world.state.forest_straight_w=not world.state.forest_straight_w
			world.tell("The corridor shifts","The treasury is aligned." if world.state.forest_straight_w else "The red portrait passage is aligned.")
		"frozen":
			if projectile!="fire_arrow": world.tell("Frozen eye","Ordinary arrows cannot melt the ice. Line up the eye with the flame.");return
			world.state.forest_frozen_eye=true
			world.tell("Ice gives way","The eastern corridor twists. Its side passage now descends beneath the ceiling trap.")
		"amy_start":
			if amy_time>0 or world.state.forest_amy_solved: return
			amy_time=60
			for item in blocks.values(): item.node.position=item.origin
			world.tell("Amy's portrait","Four fragments, one picture. Stand behind a block and press E to push it. You have one minute.")
		_:
			if id.begins_with("joelle_") or id.begins_with("beth_"):
				if not id in world.state.forest_portraits:
					world.state.forest_portraits.append(id)
					targets[id].spent=true;targets[id].set_active(false)
					activate_portrait("joelle" if id.begins_with("joelle") else "beth")
	refresh()
	world.chime(900,.2)

func build_frozen() -> void:
	var eye=make_target("frozen",Vector3(0,3,-10))
	var ice=G.sphere(eye,Vector3(0,0,.18),Vector3(.78,.53,.22),Color("a4d7df"))
	ice.name="FrozenCrust"
	var glass=StandardMaterial3D.new()
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color=Color(.65,.86,.91,.72)
	glass.roughness=.21
	glass.metallic_specular=.7
	ice.material_override=glass
	G.lantern(world.landscape,Vector3(0,3.3,0),1.6)
	G.rod(world.landscape,Vector3(0,1.95,0),Vector3(0,3.08,0),.055,Color("736248"))
	F.column(world.landscape,Vector3.ZERO,1.8)
	rotor=AnimatableBody3D.new()
	rotor.set_meta("animated",true)
	rotor.collision_layer=1
	world.landscape.add_child(rotor)
	var platform=F.block(rotor,Vector3(0,1.8,6),Vector3(3.4,.4,3.4))
	var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(3.4,.4,3.4);shape.shape=box;shape.position=platform.position;rotor.add_child(shape)
	G.rod(rotor,Vector3(0,1.65,0),Vector3(0,1.65,6),.12,Color("625b48"))
	Art.walkway(world.landscape,Vector3(0,0,12),Vector3(0,2,7.8),3,Color("8b8b7a"),false)

func build_ceiling() -> void:
	ceiling=Node3D.new();ceiling.set_meta("animated",true);world.landscape.add_child(ceiling)
	ceiling.position.y=7
	for x in [-8,-4,0,4,8]:
		for z in [-12,-8,-4,0,4,8,12]:
			var safe=(x==-4 and z==4) or (x==4 and z==-4) or (x==0 and abs(z)==12)
			if safe:
				var slab=F.block(world.landscape,Vector3(x,.025,z),Vector3(3.7,.05,3.7))
				slab.material_override=F.masonry().duplicate();slab.material_override.albedo_color=Color("bba972")
			else: F.block(ceiling,Vector3(x,0,z),Vector3(3.98,.6,3.98))
	add_use("ceiling_hint",Vector3(0,0,11),"Read the worn floor")

func safe_tile(at:Vector3) -> bool:
	for center in [Vector2(-4,4),Vector2(4,-4),Vector2(0,12),Vector2(0,-12)]:
		if absf(at.x-center.x)<1.7 and absf(at.z-center.y)<1.7: return true
	return false

func build_amy() -> void:
	if "amy" in world.state.forest_poes: return
	if world.state.forest_amy_solved: boss=spawn("poe","amy",Vector3(0,0,-3));return
	var target=make_target("amy_start",Vector3(0,3,-10),false)
	target.visual=portrait_frame(target,Vector3.ZERO,Color("68935c"))
	var origins=[Vector3(-5.5,0,-1.1),Vector3(5.5,0,-1.1),Vector3(-1.1,0,5.5),Vector3(5.5,0,1.1),Vector3(7,0,5.5)]
	for i in range(5):
		create_block(str(i),origins[i],Color("78946d") if i<4 else Color("6f7265"),2.0)
		var mark=Label3D.new();mark.text=str(i+1) if i<4 else "x";mark.font_size=70;mark.pixel_size=.01;mark.position=Vector3(0,1,1.02);blocks[str(i)].node.add_child(mark)
		if i<4:
			var goal=Vector3(-1.1 if i in [0,2] else 1.1,.025,-1.1 if i<2 else 1.1)
			F.block(world.landscape,goal,Vector3(2.12,.05,2.12))
			var label=Label3D.new();label.text=str(i+1);label.position=goal+Vector3(0,.04,0);label.rotation.x=-PI/2;label.font_size=90;label.pixel_size=.013;world.landscape.add_child(label)

func build_basement() -> void:
	basement=Node3D.new();basement.set_meta("animated",true);world.landscape.add_child(basement)
	for i in range(4):
		var segment=Node3D.new();basement.add_child(segment);segment.rotation.y=i*PI/2
		# Wall segments leave one broad opening between two piers.
		if i!=0: F.block(segment,Vector3(0,2.1,-7),Vector3(12,4.2,.8),true)
		else:
			for side in [-1,1]: F.block(segment,Vector3(side*4.7,2.1,-7),Vector3(3,4.2,.8),true)
		F.column(segment,Vector3(-6,0,-7),4)
	for i in range(1,4):
		var at=Vector3(0,0,-10).rotated(Vector3.UP,i*PI/2)
		var plate=F.block(world.landscape,at+Vector3.UP*.07,Vector3(1.2,.14,1.2))
		plate.set_meta("animated",true)
		plate.material_override=Art.material(Color("62866e") if i in world.state.forest_basement_switches else Color("a08e66"),.8)
		basement_buttons[i]=plate
		add_use("switch:"+str(i),at,"Press alcove switch "+str(i))
	add_use("rotate",Vector3(0,0,4),"Rotate the central wall")
	F.block(world.landscape,Vector3(0,.8,4),Vector3(.7,1.6,.7),true)
	G.rod(world.landscape,Vector3(-1,1.4,4),Vector3(1,1.4,4),.09,Color("83734f"))
	basement.rotation.y=int(world.state.forest_basement_rotation)*PI/2

func rotate_basement() -> void:
	if rotation_time>0: return
	rotation_start=basement.rotation.y
	rotation_end=rotation_start+PI/2
	rotation_time=.8
	world.state.forest_basement_rotation=posmod(int(world.state.forest_basement_rotation)+1,4)
	world.tell("Rotating wall","Alcove "+str(world.state.forest_basement_rotation)+" faces the opening. Three switches release the boss passage.")

func build_boss() -> void:
	for i in range(6):
		var a=i*TAU/6
		var root=Node3D.new();world.landscape.add_child(root);root.position=Vector3(sin(a)*13,3,cos(a)*13);root.rotation.y=a+PI
		portrait_frame(root,Vector3.ZERO,Color("587357"),Vector2(4.8,5))
		G.lantern(root,Vector3(-3,0,.3),.8)
	if not world.state.phantom_ganon: boss=spawn("phantom","phantom_ganon",Vector3(0,0,-10))
	else: reward_portal()

func reward_portal() -> void:
	var node=Art.cylinder(world.landscape,Vector3(0,.025,0),2,2,.05,Color("7dccbc"),96)
	node.set_meta("animated",true)
	add_use("reward",Vector3.ZERO,"Enter the sage's light")

func enemy_defeated(enemy:CharacterBody3D) -> void:
	if not world.area.begins_with("ft_"): return
	if world.player.lock_target==enemy: world.player.lock_target=null
	if enemy.kind=="poe":
		if not enemy.enemy_id in world.state.forest_poes: world.state.forest_poes.append(enemy.enemy_id)
		world.tell("A flame returns",enemy.enemy_id.capitalize()+" releases her stolen flame. The central hall grows brighter.")
	elif enemy.kind=="phantom":
		world.state.phantom_ganon=true
		reward_portal()
		world.tell("Phantom Ganon defeated","The rider dissolves. A green light carries Saria's voice.")
	elif room=="north" and alive_enemies().is_empty(): mark_clear("north")
	elif room=="map": mark_clear("map")
	elif room=="below": mark_clear("below")
	elif room=="bow":
		if enemy.enemy_id=="bow_first":
			bow_stage=1
			spawn("stalfos","bow_pair_a",Vector3(-4,0,-3));spawn("stalfos","bow_pair_b",Vector3(4,0,-3))
		elif alive_enemies().is_empty(): mark_clear("bow");revival=0
		else: revival=10
	elif room=="floormaster":
		if enemy.kind=="floormaster":
			for i in range(3): spawn("handlet","handlet_"+str(i),enemy.position+Vector3(sin(i*TAU/3),0,cos(i*TAU/3)))
		elif alive_enemies().is_empty(): mark_clear("floormaster")
		enemy.queue_free()
	refresh()

func alive_enemies() -> Array:
	return world.creatures.filter(func(enemy): return is_instance_valid(enemy) and enemy.mode!="dead")

func regrow_hand(_child:CharacterBody3D) -> void:
	for enemy in alive_enemies():
		enemy.mode="dead";enemy.collision_layer=0;enemy.queue_free()
	spawn("floormaster","hand_regrown",Vector3(0,0,-1))
	world.tell("Floormaster","A surviving fragment regrows. Defeat all three before they gather strength.")

func tick(delta:float) -> void:
	if rotation_time>0:
		rotation_time=maxf(0,rotation_time-delta)
		basement.rotation.y=lerpf(rotation_start,rotation_end,smoothstep(0,1,1-rotation_time/.8))
	if not moving.is_empty():
		moving.time+=delta
		blocks[moving.id].node.position=moving.start.lerp(moving.end,minf(1,moving.time/.4))
		if moving.time>=.4:
			var p:Vector3=moving.end
			if room=="blocks": world.state.forest_blocks[moving.id]=[p.x,p.y,p.z]
			moving={}
			if room=="blocks": update_block_ladders()
	for item in world.interactions:
		if item.id.begins_with("ft_push:"):
			var key=item.id.trim_prefix("ft_push:")
			if blocks.has(key):
				var p:Vector3=blocks[key].node.position
				# Centered prompt permits pushing from each cardinal side.
				item.position=[p.x,p.y,p.z]
	if room in ["red","blue"] and not is_instance_valid(boss):
		portrait_time+=delta
		for target in targets.values():
			if target.active and not target.spent and world.player.position.distance_to(target.position)<4 and portrait_time>1.4:
				portrait_time=0;portrait_index+=1;activate_portrait("joelle" if room=="red" else "beth");break
	if revival>0:
		revival-=delta
		if revival<=0 and not cleared("bow"):
			for enemy in world.creatures:
				if enemy.enemy_id.begins_with("bow_pair") and enemy.mode=="dead": enemy.revive()
	if is_instance_valid(ceiling):
		ceiling_time=fmod(ceiling_time+delta,6)
		var y=7.0
		if ceiling_time>=4.7 and ceiling_time<5.1: y=lerpf(7,.8,(ceiling_time-4.7)/.4)
		elif ceiling_time>=5.1 and ceiling_time<5.65: y=.8
		elif ceiling_time>=5.65: y=lerpf(.8,7,(ceiling_time-5.65)/.35)
		ceiling.position.y=y
		if ceiling_time>4 and ceiling_time<4.7: world.prompt_label.text="The stone ceiling trembles - find an open tile!"
		if y<1.8 and not safe_tile(world.player.position):
			world.damage_player(2,world.player.position+Vector3.UP*4,false)
			if world.state.health>0: world.player.position=Vector3(0,.1,12)
	if amy_time>0:
		amy_time=maxf(0,amy_time-delta)
		var solved=true
		for i in range(4):
			var goal=Vector3(-1.1 if i in [0,2] else 1.1,0,-1.1 if i<2 else 1.1)
			if blocks[str(i)].node.position.distance_to(goal)>.15: solved=false
		if solved and moving.is_empty():
			amy_time=0;world.state.forest_amy_solved=true
			for item in blocks.values(): world.hide_breakable(item.node)
			boss=spawn("poe","amy",Vector3(0,0,-3))
		elif amy_time<=0:
			moving={}
			for item in blocks.values(): item.node.position=item.origin
			world.tell("The portrait scatters","Time ran out. Shoot the portrait to try again; each numbered piece belongs over its matching floor mark.")

func physics_tick(delta:float) -> void:
	if is_instance_valid(rotor): rotor.rotation.y+=delta*.32
