extends RefCounted

const Art=preload("res://scripts/art.gd")
const Stone=preload("res://scripts/natural_art.gd")
const Temple=preload("res://scripts/time_temple_art.gd")
var world:Node3D
var data:Dictionary
var doors:Array=[]
var door_bodies:Array=[]
var stones:Array=[]
var ocarina:Node3D
var pedestal_sword:Node3D
var sequence:=""
var stage:=0
var time:=0.0
var sequence_paused:=false
var riders:Array=[]
var tossed:Node3D
var opening:=0.0

func _init(owner_world:Node3D) -> void:
	world=owner_world
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/time_quest.json"))
	world.overworld.places.temple=data.temple
	world.overworld.places.sages=data.sages
	world.overworld.places.market.exits.append({"to":"temple","at":[10,0,-21],"label":"Temple of Time"})

func three_stones() -> bool:
	return world.state.emerald and world.state.ruby and world.state.sapphire

func build() -> void:
	doors=[]
	door_bodies=[]
	stones=[]
	opening=1.0 if world.state.door_of_time else 0.0
	Temple.build(world.landscape)
	world.set_ambience(true)
	world.sunlight.light_energy=0
	var env=world.world_environment.environment
	env.ambient_light_color=Color("bec5cd")
	env.ambient_light_energy=.42
	env.fog_density=0
	for side in [-1,1]:
		var leaf=Node3D.new()
		leaf.set_meta("animated",true)
		leaf.position=Vector3(side*1.5,0,-14)
		world.landscape.add_child(leaf)
		Temple.dressed(leaf,Vector3(0,2.8,0),Vector3(2.99,5.6,.75))
		Temple.dressed(leaf,Vector3(0,2.7,.43),Vector3(2.58,4.9,.13))
		for x in [-1.24,1.24]: Temple.dressed(leaf,Vector3(x,2.7,.53),Vector3(.10,4.8,.08))
		for y in [.36,5.02]: Temple.dressed(leaf,Vector3(0,y,.53),Vector3(2.6,.12,.08))
		var body=Art.collision_box(leaf,Vector3(0,2.8,0),Vector3(3,5.6,.75))
		doors.append(leaf)
		door_bodies.append(body)
	# Recessed sockets keep the stones grounded in a readable, physical altar.
	Temple.dressed(world.landscape,Vector3(0,.22,-9),Vector3(4.4,.44,1.8),true)
	Temple.dressed(world.landscape,Vector3(0,.68,-9),Vector3(3.5,.60,1.25),true)
	Temple.dressed(world.landscape,Vector3(0,1.02,-9),Vector3(4,.16,1.6))
	var index=0
	for color in [Color("42b17d"),Color("d16c48"),Color("608acb")]:
		var x=(index-1)*1.2
		var socket=Art.cylinder(world.landscape,Vector3(x,1.115,-9),.30,.30,.045,Color("736143"),64)
		socket.material_override=Art.material(Color("8b7044"),.32,.8)
		var gem=MeshInstance3D.new()
		var shape=SphereMesh.new()
		shape.radial_segments=64
		shape.rings=32
		shape.radius=.19
		shape.height=.31
		gem.mesh=shape
		gem.position=Vector3(x,1.27,-9)
		gem.material_override=Art.material(color,.14,.25)
		var holder=Node3D.new()
		holder.set_meta("animated",true)
		world.landscape.add_child(holder)
		holder.add_child(gem)
		stones.append(holder)
		index+=1
	Temple.dressed(world.landscape,Vector3(0,.16,-23),Vector3(3.4,.32,3.4),true)
	Temple.dressed(world.landscape,Vector3(0,.43,-23),Vector3(1.6,.30,1.4),true)
	Temple.dressed(world.landscape,Vector3(0,.70,-23),Vector3(1.1,.24,.95),true)
	pedestal_sword=load("res://assets/master_sword.glb").instantiate()
	pedestal_sword.set_meta("animated",true)
	pedestal_sword.position=Vector3(0,1.58,-23)
	pedestal_sword.rotation.z=PI
	world.landscape.add_child(pedestal_sword)
	var shaft=SpotLight3D.new()
	shaft.position=Vector3(0,9,-22)
	shaft.rotation_degrees.x=-90
	shaft.light_color=Color("e5e9ed")
	shaft.light_energy=5
	shaft.spot_range=14
	shaft.spot_angle=24
	shaft.shadow_enabled=true
	world.landscape.add_child(shaft)
	world.interactions.append({"id":"time_altar","position":[0,0,-7.6],"label":"Read / Place Spiritual Stones"})
	world.interactions.append({"id":"time_door","position":[0,0,-12.6],"label":"Examine the Door of Time"})
	world.interactions.append({"id":"master_sword","position":[0,0,-21.6],"label":"Examine the Master Sword"})
	if world.state.adult:
		world.overworld.make_person({"id":"sheik","name":"Sheik","at":[3,0,-19],"style":"impa"},false)
		world.interactions.append({"id":"sheik","position":[3,0,-19],"label":"Talk to Sheik"})
	apply_visuals()

func build_chamber() -> void:
	var scene=world.landscape
	world.set_ambience(true)
	world.sunlight.light_energy=0
	var env=world.world_environment.environment
	env.ambient_light_color=Color("91a9c6")
	env.ambient_light_energy=.35
	env.fog_density=.014
	env.fog_light_color=Color("14202e")
	var dais=Art.cylinder(scene,Vector3(0,-.4,0),8,8,.8,Color.WHITE,128)
	dais.material_override=Temple.stone("floor")
	var body=StaticBody3D.new()
	var col=CollisionShape3D.new()
	var shape=CylinderShape3D.new()
	shape.radius=8
	shape.height=.8
	col.shape=shape
	body.position.y=-.4
	body.add_child(col)
	scene.add_child(body)
	for i in range(6):
		var a=i*TAU/6
		var at=Vector3(sin(a)*6,0,cos(a)*6)
		var seal=Art.cylinder(scene,at+Vector3.UP*.025,1.0,1.0,.05,Color.WHITE,96)
		seal.material_override=Art.material([Color("4c805d"),Color("9b5540"),Color("48768a"),Color("8b7248"),Color("6d5c80"),Color("c2b88b")][i],.4,.45)
		Stone.column(scene,at*2,7)
		var light=OmniLight3D.new()
		light.position=at+Vector3.UP*3
		light.light_color=Color("b9cce0")
		light.light_energy=1.7
		light.omni_range=12
		light.shadow_enabled=i==0
		light.omni_shadow_mode=OmniLight3D.SHADOW_CUBE
		scene.add_child(light)
	world.overworld.make_person({"id":"rauru","name":"Rauru","at":[0,0,-2],"style":"elder"},false)
	world.player.position=Vector3(0,0,4)
	world.player.yaw=0

func apply_visuals() -> void:
	for i in range(doors.size()):
		if not is_instance_valid(doors[i]): continue
		var side=-1 if i==0 else 1
		doors[i].position.x=side*(1.5+opening*3.0)
		door_bodies[i].collision_layer=0 if opening>=.99 else 1
	for stone in stones:
		if is_instance_valid(stone): stone.visible=world.state.stones_placed
	if is_instance_valid(pedestal_sword): pedestal_sword.visible=not world.state.adult

func field_moat() -> void:
	# The dry bridge is flanked by a real, swimmable moat and a sloping east bank.
	var scene=world.landscape
	for side in [-1,1]:
		var x=-14.0 if side<0 else 4.0
		world.add_water(Rect2(x,-65,10,14),-.12,-3.7)
		Stone.block(scene,Vector3(x+5,-4,-58),Vector3(10,.6,14),false,true)
		Stone.block(scene,Vector3(x+5,-1.7,-65.2),Vector3(10,3.4,.4),false,true)
		if side<0: Stone.block(scene,Vector3(x+5,-1.7,-50.8),Vector3(10,3.4,.4),false,true)
		else:
			for wall_x in [5.75,12.25]: Stone.block(scene,Vector3(wall_x,-1.7,-50.8),Vector3(3.5,3.4,.4),false,true)
		Stone.block(scene,Vector3(side*14.2,-1.7,-58),Vector3(.4,3.4,14),false,true)
		Stone.block(scene,Vector3(side*4,-1.7,-58),Vector3(.4,3.4,14),false,true)
	# A ramp reaches the southern dry bank without an underwater vertical lip.
	Art.walkway(scene,Vector3(9,-3.7,-56),Vector3(9,0,-51),3.0,Color("879181"),false)
	if world.state.castle_escape and not world.state.ocarina_of_time: make_pickup()

func make_pickup() -> void:
	ocarina=Temple.ocarina(world.landscape)
	ocarina.position=Vector3(9,-3.25,-60)
	ocarina.rotation=Vector3(.2,0,.2)
	var light=OmniLight3D.new()
	light.position.y=.25
	light.light_color=Color("8fbeff")
	light.light_energy=.8
	light.omni_range=3
	ocarina.add_child(light)
	world.interactions.append({"id":"time_ocarina","position":[9,-3.25,-60],"label":"Recover the blue ocarina"})

func try_escape() -> bool:
	if world.state.castle_escape or not three_stones(): return false
	world.player.position=Vector3(1.5,0,-54)
	world.player.yaw=0
	world.player.visual.rotation.y=0
	world.state.time_of_day=.75
	riders=[]
	for i in range(2):
		var horse=world.overworld.create_horse(Vector3(0,0,-68-i*4))
		horse.rotation.y=PI
		for mesh in horse.find_children("*","MeshInstance3D",true,false):
			mesh.material_override=Art.material(Color("c6c5b6") if i==0 else Color("292b2b"),.78)
		var person=world.overworld.make_person({"id":"escape_rider_"+str(i),"name":"Impa" if i==0 else "Ganondorf","at":[0,0,0],"style":"impa" if i==0 else "guard"},false)
		person.reparent(horse,false)
		person.position=Vector3(0,.80,.1)
		person.rotation.y=PI
		for body in person.find_children("*","CollisionObject3D",true,false): body.collision_layer=0
		if i==0:
			var princess=world.overworld.make_person({"id":"escape_zelda","name":"Zelda","at":[0,0,0],"style":"zelda"},false)
			princess.reparent(horse,false)
			princess.position=Vector3(0,.77,.52)
			princess.scale=Vector3.ONE*.72
			princess.rotation.y=PI
			for body in princess.find_children("*","CollisionObject3D",true,false): body.collision_layer=0
		riders.append({"node":horse,"legs":world.overworld.horse_legs.duplicate(),"tail":world.overworld.horse_tail})
	tossed=Temple.ocarina(world.landscape)
	tossed.hide()
	begin("escape")
	return true

func begin(id:String) -> void:
	sequence=id
	stage=0
	time=0
	sequence_paused=false
	world.player.enabled=false
	world.player.velocity=Vector3.ZERO
	show_line()

func show_line() -> void:
	world.tell(data[sequence][stage].speaker,data[sequence][stage].line)
	world.message_time=30

func tick_sequence(delta:float) -> void:
	if Input.is_action_just_pressed("pause"):
		sequence_paused=not sequence_paused
		if sequence_paused: world.tell("Paused","Esc resumes the scene. Progress is saved after the scene ends.")
		else: show_line()
	if Input.is_action_just_pressed("save"): world.tell("Scene in progress","Finish this scene before saving your journey.")
	world.prompt_label.text="Esc  Pause scene" if not sequence_paused else "Esc  Resume scene"
	world.message_time=30
	if sequence_paused: return
	time+=delta
	if sequence=="escape":
		var lead:Node3D=riders[0].node
		var pursuer:Node3D=riders[1].node
		if stage==0: lead.position.z=lerpf(-67,-54,clampf(time/4.5,0,1))
		elif stage==1:
			lead.position.z=-54+time*5
			tossed.show()
			var t=clampf(time/2.0,0,1)
			tossed.position=Vector3(0,2,-54).lerp(Vector3(9,-3.25,-60),t)+Vector3.UP*sin(t*PI)*3
			pursuer.position.z=lerpf(-70,-59,clampf(time/3.5,0,1))
		else:
			lead.position.z+=delta*7
			pursuer.position.z=-59+maxf(0,time-2)*7
		for rider in riders:
			world.overworld.horse_legs=rider.legs
			world.overworld.horse_tail=rider.tail
			world.overworld.horse_pose(delta,4.0)
	if time>=float(data[sequence][stage].duration):
		stage+=1
		time=0
		if stage>=data[sequence].size(): complete_sequence()
		else:
			if sequence=="awakening" and stage==2:
				world.overworld.enter("temple")
				world.player.position=Vector3(0,0,-20)
				world.player.yaw=-PI*.45
			show_line()

func complete_sequence() -> void:
	var finished=sequence
	sequence=""
	world.player.enabled=true
	if finished=="escape":
		world.state.castle_escape=true
		for rider in riders: rider.node.queue_free()
		riders=[]
		if is_instance_valid(tossed): tossed.queue_free()
		world.overworld.horse=null
		world.overworld.horse_legs=[]
		world.overworld.horse_tail=null
		make_pickup()
		world.tell("Navi","Zelda threw something into the water east of the bridge. Dive beneath the surface to find it.")
	elif finished=="echo":
		world.state.ocarina_of_time=true
		world.state.ocarina=true
		world.learn_song("time")
		if is_instance_valid(ocarina): ocarina.hide()
		world.interactions=world.interactions.filter(func(item): return item.id!="time_ocarina")
		world.tell("Ocarina of Time","Song of Time learned: L J K L J K. The sloping bank leads out of the moat; the temple stands northeast of the market.")

	elif finished=="awakening":
		world.state.light_medallion=true
		world.state.health=world.state.max_health
		world.tell("Light Medallion","Seven years have passed. Sheik can tell you where to begin. The Master Sword is yours, but your childhood shield and small weapons no longer fit.")
	elif finished in ["time_backward","time_forward"]:
		world.state.adult=finished=="time_forward"
		world.overworld.enter("temple")
		world.player.position=Vector3(0,0,-20)
		world.player.yaw=PI
		world.player.update_camera(1)
		world.tell("The pedestal of time","You return to the kingdom seven years later." if world.state.adult else "You return to your childhood. Your equipment and completed journeys remain with you.")

func tick(delta:float) -> void:
	if world.area!="temple": return
	if world.state.door_of_time and opening<1:
		opening=move_toward(opening,1,delta*.28)
		apply_visuals()

func interact(id:String) -> bool:
	match id:
		"time_ocarina":
			if not world.state.castle_escape or world.state.ocarina_of_time: return true
			if world.player.position.distance_to(Vector3(9,-3.25,-60))>1.1 or not world.player.swimming:
				world.tell("Navi","The blue instrument rests deep in the moat. Hold Space to dive close to it.")
			else: begin("echo")
		"time_altar":
			if not three_stones(): world.tell("The altar",data.altar+" Some of the stone hollows are still empty.")
			elif not world.state.stones_placed:
				world.state.stones_placed=true
				apply_visuals()
				world.tell("Three Spiritual Stones","The stones fit their hollows. Play the Song of Time here with Zelda's blue ocarina.")
			else: world.tell("The altar",data.altar)
		"time_door":
			world.tell("Door of Time",data.door if world.state.door_of_time else "The seam is sealed. The three stones and the royal instrument must answer the Song of Time before the altar.")
		"master_sword":
			if not world.state.door_of_time: world.tell("Navi","The Door of Time still separates us from the sacred blade.")
			elif world.state.adult:
				if not world.state.forest_medallion: world.tell("Sheik","First, answer the call from the Forest Temple. Then this pedestal will become the road between your two ages.")
				else: begin("time_backward")
			elif world.state.master_sword: begin("time_forward")
			elif not world.state.sword_inspected:
				world.state.sword_inspected=true
				world.tell("Master Sword",data.sword+" Press E again to draw it.")
			else:
				world.state.master_sword=true
				world.state.adult=true
				world.overworld.enter("sages")
				begin("awakening")
		"sheik":
			if world.state.forest_medallion:
				world.learn_song("prelude")
				world.tell("Sheik",data.prelude)
			else: world.tell("Sheik",data.awakening[2].line)
		_: return false
	return true

func on_song(id:String) -> bool:
	if id=="prelude" and "prelude" in world.state.songs:
		world.overworld.enter("temple")
		world.player.position=Vector3(0,.1,-17)
		world.player.update_camera(1)
		world.tell("Prelude of Light","The melody brings you to the sanctuary. The pedestal joins the two ages of your journey.")
		return true
	if id!="time" or world.area!="temple": return false
	if world.state.door_of_time:
		world.tell("Song of Time","The great doors remain open.")
	elif not world.state.ocarina_of_time or not three_stones() or not world.state.stones_placed:
		world.tell("Door of Time","The seal needs all three Spiritual Stones on the altar, and the Ocarina of Time.")
	elif world.player.position.distance_to(Vector3(0,0,-7.6))>4:
		world.tell("Navi","Stand before the altar so the melody reaches the seal.")
	else:
		world.state.door_of_time=true
		world.tell("Door of Time",data.door)
	return true

func objective() -> String:
	if world.state.adult:
		if world.area=="sages": return "SACRED REALM · Listen to Rauru, the Sage of Light"
		if world.state.forest_medallion:
			return "TEMPLE OF TIME · Speak with Sheik to learn the Prelude of Light" if not "prelude" in world.state.songs else "TEMPLE OF TIME · Return the sword to visit your childhood, or seek the Gorons on Death Mountain"
		return "SEVEN YEARS LATER · Speak to Sheik; seek the gravekeeper's legacy in Kakariko"
	if world.area=="temple":
		if world.state.door_of_time: return "TEMPLE OF TIME · Beyond the open door, examine the sword in its pedestal"
		if not world.state.stones_placed: return "TEMPLE OF TIME · Place the three Spiritual Stones at the altar"
		return "TEMPLE OF TIME · Play the Song of Time before the altar · L J K L J K"
	if not three_stones(): return ""
	if not world.state.castle_escape: return "THREE SPIRITUAL STONES · Return to the northern castle gate in Hyrule Field"
	if not world.state.ocarina_of_time: return "ZELDA'S TRUST · Dive east of the castle bridge and recover the blue ocarina"
	return "OCARINA OF TIME · Follow the northeast path from the market to the Temple of Time"
