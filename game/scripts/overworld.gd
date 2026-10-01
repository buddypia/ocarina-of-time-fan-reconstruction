extends RefCounted

const Art=preload("res://scripts/art.gd")
var world:Node3D
var scene:Node3D
var places:Dictionary
var place:="field"
var patrols:Array=[]
var caught_cooldown:=0.0
var horse:Node3D
var horse_legs:Array=[]
var horse_tail:Node3D
var horse_stride:=0.0
var delivery_gate:StaticBody3D
var bridge:Node3D
var sky_tick:=0.0

func _init(owner_world:Node3D) -> void:
	world=owner_world
	places=JSON.parse_string(FileAccess.get_file_as_string("res://data/hyrule.json"))

func enter(next:String, from:String="") -> void:
	if next=="forest":
		world.return_forest()
		world.player.position=Vector3(-22,0,7)
		world.player.yaw=-PI/2
		world.player.update_camera(1)
		return
	if not places.has(next): return
	world.clear_landscape()
	scene=world.landscape
	place=next
	world.area=next
	patrols=[]
	horse=null
	horse_legs=[]
	horse_tail=null
	horse_stride=0
	delivery_gate=null
	bridge=null
	world.player.lock_target=null
	world.player.climbing=false
	world.player.velocity=Vector3.ZERO
	world.player.position=Vector3(0,.2,17)
	world.player.yaw=0
	world.set_ambience(false)
	match place:
		"field": field()
		"market":
			if world.state.adult: world.graveyard.market()
			else: market()
		"castle": castle()
		"temple": world.time_quest.build()
		"sages": world.time_quest.build_chamber()
		"ranch": ranch()
		"crater": world.fire_quest.crater()
		"lost_woods","meadow": world.woodland.build(place)
		"river","domain","lake","fountain": world.zora.build(place)
		"kakariko","trail","goron": world.mountain.build(place)
		"graveyard","dampe_race","shield_grave","heart_grave","royal_tomb","windmill": world.graveyard.build(place)
	for passage in places[place].exits:
		var at=world.vec(passage.at)
		world.interactions.append({"id":"travel:"+passage.to,"position":passage.at,"label":passage.label})
		if at.y>=0: signpost(at+Vector3(4,0,0),passage.label)
		if passage.to==from:
			var inward=Vector3(-at.x,0,-at.z).normalized()
			var arrival_distance=4.0 if place=="trail" and from in ["goron","dodongo"] else 2.0
			if at.y<0: arrival_distance=0
			world.player.position=at+inward*arrival_distance+Vector3.UP*.2
			world.player.yaw=atan2(-inward.x,-inward.z)
	for person in places[place].people:
		if person.get("adult_only",false) and not world.state.adult: continue
		if place in ["market","goron","trail"] and world.state.adult: continue
		if place=="castle" and world.state.castle_escape and person.id in ["zelda","impa"]: continue
		if person.id=="talon" and world.state.talon_awake: continue
		if person.id=="talon_ranch" and not world.state.talon_awake: continue
		make_person(person)
	Art.batch_static(scene)
	world.apply_state()
	world.player.visual.rotation.y=world.player.yaw
	world.player.update_camera(1)
	world.checkpoint={"area":place,"position":world.player.position}
	if world.state.adult and place=="market":
		world.tell("The ruined Market","The stalls have vanished and the dead roam the square. Survivors fled to Kakariko. The Temple of Time still stands to the northeast.")
	elif world.state.adult and place=="goron":
		world.tell("Goron City, seven years later","The fires have gone quiet. A single young Goron rolls through the empty city, afraid to stop.")
	elif world.state.adult and place=="trail":
		world.tell("Death Mountain","Ash drifts down the deserted trail. Goron City is silent above the quarry.")
	elif world.state.adult and place=="kakariko":
		world.tell("Kakariko, seven years later","Families from the fallen castle town have found shelter here. The cemetery is east, beyond the last house.")
	else: world.tell(places[place].name,places[place].arrival)

func ground(size:Vector2, color:Color) -> void:
	Art.box(scene,Vector3(0,-.3,0),Vector3(size.x,.6,size.y),color,true)
	for side in [-1,1]:
		Art.collision_box(scene,Vector3(side*size.x*.5,3,0),Vector3(1,6,size.y))
		Art.collision_box(scene,Vector3(0,3,side*size.y*.5),Vector3(size.x,6,1))

func road(points:Array, width:float=2.2) -> void:
	for i in range(points.size()-1):
		var a:Vector3=points[i]
		var b:Vector3=points[i+1]
		var length=a.distance_to(b)
		for j in range(int(length/2)+1):
			var at=a.lerp(b,j/maxf(1,int(length/2)))+Vector3.UP*.022
			Art.cylinder(scene,at,width,width,.04,Color("b4a37b"),12)

func signpost(at:Vector3, caption:String) -> void:
	Art.beam(scene,at,at+Vector3.UP*1.7,.065,Color("755838"))
	Art.box(scene,at+Vector3.UP*1.5,Vector3(2.1,.52,.12),Color("765739"))
	var text=Label3D.new()
	text.text=caption
	text.position=at+Vector3(0,1.5,.08)
	text.font_size=36
	text.pixel_size=.007
	text.modulate=Color("efdfb0")
	scene.add_child(text)

func building(at:Vector3, size:Vector3, roof_color:Color, door_side:float=0) -> void:
	var root=Node3D.new()
	root.position=at
	root.rotation.y=door_side
	scene.add_child(root)
	Art.box(root,Vector3(0,size.y*.5,0),size,Color("c7b998"),true)
	Art.box(root,Vector3(0,.27,0),Vector3(size.x+.25,.54,size.z+.25),Color("7e8274"))
	for side in [-1,1]:
		var roof=Art.box(root,Vector3(side*size.x*.25,size.y+.58,0),Vector3(size.x*.62,.25,size.z+1),roof_color)
		roof.rotation.z=-side*.42
		# Close the gable instead of leaving the roof floating above an open triangle.
		var gable=SurfaceTool.new()
		gable.begin(Mesh.PRIMITIVE_TRIANGLES)
		var corners=[Vector3(-size.x*.5,size.y,side*size.z*.5),Vector3(0,size.y+1.5,side*size.z*.5),Vector3(size.x*.5,size.y,side*size.z*.5)]
		for index in ([0,1,2] if side>0 else [2,1,0]): gable.add_vertex(corners[index])
		gable.generate_normals()
		var face=MeshInstance3D.new()
		face.mesh=gable.commit()
		face.material_override=Art.material(Color("c7b998"))
		root.add_child(face)
		for x in [-size.x*.42,0,size.x*.42]: Art.box(root,Vector3(x,size.y*.5,side*size.z*.502),Vector3(.13,size.y,.10),Color("695240"))
		Art.box(root,Vector3(side*size.x*.27,size.y*.60,size.z*.51),Vector3(.8,1,.08),Color("556775"))
		Art.box(root,Vector3(side*size.x*.27,size.y*.60,size.z*.52),Vector3(.055,1,.04),Color("d3bb84"))
	Art.box(root,Vector3(0,.85,size.z*.515),Vector3(1.15,1.7,.12),Color("64503a"))
	Art.box(root,Vector3(size.x*.28,size.y+.8,-size.z*.2),Vector3(.65,1.7,.65),Color("948372"))

func tower(at:Vector3, height:float=10) -> void:
	Art.cylinder(scene,at+Vector3.UP*height*.5,2.1,1.8,height,Color("b8b69a"),16)
	Art.cylinder(scene,at+Vector3.UP*(height+.2),2.1,2.1,.7,Color("8c9688"),16)
	for i in range(8):
		var a=i*TAU/8
		Art.box(scene,at+Vector3(sin(a)*1.85,height+.8,cos(a)*1.85),Vector3(.65,.8,.65),Color("c6c3a5"))
	Art.cylinder(scene,at+Vector3.UP*(height+2.3),1.6,0,3,Color("3c6486"),12)
	Art.beam(scene,at+Vector3.UP*(height+3.8),at+Vector3.UP*(height+5.2),.04,Color("806744"))
	Art.box(scene,at+Vector3(.5,height+4.7,0),Vector3(1,.5,.025),Color("9b3b43"))

func field() -> void:
	# Four dry slabs leave open water on both sides of the castle bridge.
	for entry in [[Vector3(0,-.3,12),Vector3(126,.6,126)],[Vector3(0,-.3,-70),Vector3(126,.6,10)],[Vector3(-38.5,-.3,-58),Vector3(49,.6,14)],[Vector3(38.5,-.3,-58),Vector3(49,.6,14)],[Vector3(0,-.3,-58),Vector3(8,.6,14)]]:
		Art.box(scene,entry[0],entry[1],Color("6e7e45"),true)
	for side in [-1,1]:
		Art.collision_box(scene,Vector3(side*63,3,0),Vector3(1,6,150))
		Art.collision_box(scene,Vector3(0,3,side*75),Vector3(126,6,1))
	world.time_quest.field_moat()
	road([Vector3(52,0,40),Vector3(30,0,25),Vector3(17,0,4),Vector3(13,0,-28),Vector3(0,0,-61)],2.5)
	road([Vector3(17,0,12),Vector3(0,0,12)],2)
	road([Vector3(13,0,-28),Vector3(49,0,-41)],2.4)
	road([Vector3(17,0,4),Vector3(54,0,-8)],2.1)
	road([Vector3(17,0,14),Vector3(8,0,45),Vector3(-12,0,66)],2.1)
	# Hills frame the playable plain; the castle and mountain are navigational landmarks.
	for i in range(18):
		var a=i*TAU/18
		Art.ellipsoid(scene,Vector3(sin(a)*69,-1,cos(a)*85),Vector3(15,8+(i%4)*2,17),Color("63764b"))
	for side in [-1,1]:
		tower(Vector3(side*8,0,-67),11)
		Art.box(scene,Vector3(side*28,4.5,-68),Vector3(35,9,3),Color("9ca68d"))
	Art.box(scene,Vector3(0,10,-68),Vector3(13,2,3),Color("b8b69a"))
	bridge=Node3D.new()
	bridge.set_meta("animated",true)
	bridge.position=Vector3(0,.06,-63)
	scene.add_child(bridge)
	Art.box(bridge,Vector3(0,0,3),Vector3(8,.2,6),Color("6e5940"))
	for x in [-3.7,3.7]: Art.beam(bridge,Vector3(x,.4,0),Vector3(x,.4,6),.1,Color("a59a7b"))
	# Ranch silhouette occupies the center without obstructing its approach.
	building(Vector3(-8,0,-2),Vector3(11,4,8),Color("ac704d"))
	building(Vector3(7,0,-2),Vector3(7,5,8),Color("945c45"))
	var rng=RandomNumberGenerator.new()
	rng.seed=930
	for i in range(52):
		var at=Vector3(rng.randf_range(-58,58),0,rng.randf_range(-55,66))
		if at.x>-3 and at.x<34: continue
		Art.tree(scene,at,rng.randf_range(.5,.85),i)
	for i in range(80):
		var at=Vector3(rng.randf_range(-56,56),0,rng.randf_range(-55,64))
		for j in range(3): Art.beam(scene,at+Vector3(j*.1,0,0),at+Vector3(j*.1-.1,.25,0),.018,Color("909958"))
	Art.cylinder(scene,Vector3(56,13,-75),25,5,35,Color("847866"),14)
	Art.cylinder(scene,Vector3(56,32,-75),6,7,1.4,Color("6f594b"),14)
	for i in range(4): Art.ellipsoid(scene,Vector3(56+i*2,36+i*3,-75),Vector3(3+i,2,3+i),Color("aaa796"))
	var lamp=OmniLight3D.new()
	lamp.position=Vector3(22,1,17)
	lamp.light_color=Color("ffc276")
	lamp.omni_range=8
	lamp.light_energy=1.2
	scene.add_child(lamp)
	world.interactions.append({"id":"camp","position":[22,0,17],"label":"Rest until dawn"})
	for i in range(8): Art.ellipsoid(scene,Vector3(22+sin(i)*.65,.12,17+cos(i)*.65),Vector3(.24,.18,.24),Color("77766a"))
	Art.ellipsoid(scene,Vector3(22,.55,17),Vector3(.25,.55,.25),Color("e6a954"))
	signpost(Vector3(25,0,18),"Travelers' fire")
	world.player.position=Vector3(49,.2,39)

func market() -> void:
	ground(Vector2(48,54),Color("9d9b88"))
	for side in [-1,1]:
		Art.box(scene,Vector3(side*23,3,0),Vector3(1.5,6,54),Color("929b89"))
		for end in [-1,1]:
			Art.box(scene,Vector3(side*15,3,end*26),Vector3(20,6,2),Color("a5ac97"))
			Art.box(scene,Vector3(0,6,end*26),Vector3(10,2,2),Color("bbc0a8"))
		Art.tree(scene,Vector3(side*26,0,-10),1.4,side+2,false)
	for x in range(-20,21,4):
		for z in range(-22,23,4): Art.box(scene,Vector3(x,.012,z),Vector3(3.92,.024,3.92),Color("a6a18a") if (x+z)%8==0 else Color("979987"))
	for side in [-1,1]:
		for i in range(3):
			building(Vector3(side*18,0,-14+i*13),Vector3(9,4.5+(i%2),9),Color("845f4e") if i%2 else Color("566f76"),-side*PI/2)
			tower(Vector3(side*8,0,-26),8)
	Art.cylinder(scene,Vector3(0,.25,0),2.7,2.7,.5,Color("888d80"),24)
	Art.cylinder(scene,Vector3(0,.52,0),2.4,2.4,.06,Color("6d9c9f"),24)
	Art.cylinder(scene,Vector3(0,1.1,0),.45,.25,1.7,Color("b7b499"),12)
	Art.cylinder(scene,Vector3(0,1.7,0),1.05,1.25,.3,Color("b7b499"),20)
	Art.collision_box(scene,Vector3(0,.3,0),Vector3(4.8,.6,4.8))
	for side in [-1,1]:
		var root=Node3D.new()
		root.position=Vector3(side*11,0,5)
		scene.add_child(root)
		Art.box(root,Vector3(0,.65,0),Vector3(3,1.3,1.4),Color("866741"),true)
		for x in [-1.6,1.6]: Art.beam(root,Vector3(x,0,0),Vector3(x,2.6,0),.065,Color("766448"))
		for i in range(6):
			var awning=Art.box(root,Vector3(-1.3+i*.52,2.6,0),Vector3(.52,.08,2.3),Color("a85d47") if i%2 else Color("ddd0a7"))
			awning.rotation.x=.1
		for i in range(5): Art.ellipsoid(root,Vector3(-1+i*.48,1.42,0),Vector3(.20,.12,.31),Color("bf9253") if side<0 else Color("a4503c"))

func castle() -> void:
	ground(Vector2(38,54),Color("67804e"))
	road([Vector3(0,0,21),Vector3(0,0,-23)],1.9)
	for side in [-1,1]:
		Art.box(scene,Vector3(side*18,3,0),Vector3(2,6,54),Color("a4aa93"),true)
		tower(Vector3(side*13,0,-26),11)
		Art.box(scene,Vector3(side*10,4,-27),Vector3(15,8,2),Color("c2bea1"))
		for z in range(-21,18,9):
			Art.tree(scene,Vector3(side*15,0,z),.62,z+40)
	for entry in [[-10,3],[10,-5],[-10,-13]]:
		var at=Vector3(entry[0],1,entry[1])
		Art.box(scene,at,Vector3(14,2,2),Color("3f6341"),true)
		for x in [-6,-4,-2,0,2,4,6]: Art.ellipsoid(scene,at+Vector3(x,.5,0),Vector3(1.3,.65,1.1),Color("4f754b"))
	for i in range(3):
		var person={"id":"patrol_"+str(i),"name":"Castle Guard","at":[-1 if i%2==0 else 2,0,4-i*8],"style":"guard"}
		var npc=make_person(person,false)
		patrols.append({"node":npc,"home":npc.position,"phase":i*1.7})
	if not world.state.talon_awake:
		delivery_gate=Art.collision_box(scene,Vector3(0,1,8),Vector3(34,2,1))
		for side in [-1,1]:
			for i in range(3): Art.box(scene,Vector3(side*(2+i*1.6),.65,8),Vector3(1.4,1.3,1.4),Color("887449"),true)
		Art.box(scene,Vector3(0,1.0,8),Vector3(2.2,2,.15),Color("826743"))
		world.interactions.append({"id":"delivery_gate","position":[0,0,9.5],"label":"The milk delivery blocks the gate"})
	for i in range(12):
		var a=i*TAU/12
		Art.ellipsoid(scene,Vector3(sin(a)*5,.1,-22+cos(a)*3),Vector3(.25,.16,.25),Color("cfa7a2") if i%2 else Color("c8be72"))

func ranch() -> void:
	ground(Vector2(48,54),Color("8a8d54"))
	for i in range(14):
		var a=i*TAU/14
		Art.ellipsoid(scene,Vector3(sin(a)*38,-1,cos(a)*42),Vector3(17,7+i%3*2,18),Color("71845a"))
		if i%2==0: Art.tree(scene,Vector3(sin(a)*29,0,cos(a)*30),1.1,i,false)
	for side in [-1,1]:
		for z in range(-24,26,4): Art.beam(scene,Vector3(side*22,0,z),Vector3(side*22,1.4,z),.08,Color("ad9466"))
		for y in [.5,1.0]: Art.beam(scene,Vector3(side*22,y,-25),Vector3(side*22,y,25),.07,Color("ad9466"))
	building(Vector3(-14,0,-10),Vector3(12,5,16),Color("a7714d"))
	building(Vector3(15,0,-10),Vector3(10,3.8,16),Color("9c7250"))
	for side in [-1,1]:
		for z in range(-19,9,3):
			Art.beam(scene,Vector3(side*8,0,z),Vector3(side*8,1.4,z),.08,Color("ad9466"))
		for y in [.5,1.0]: Art.beam(scene,Vector3(side*8,y,-20),Vector3(side*8,y,8),.065,Color("baa277"))
	for x in range(-7,8,3):
		Art.beam(scene,Vector3(x,0,-20),Vector3(x,1.4,-20),.08,Color("ad9466"))
	for y in [.5,1.0]: Art.beam(scene,Vector3(-8,y,-20),Vector3(8,y,-20),.065,Color("baa277"))
	for i in range(6): Art.cylinder(scene,Vector3(12+i%2*2,.6,10+int(i/2)*1.5),.65,.65,1.2,Color("b7a065"),12)
	create_horse(Vector3(2,0,-5))
	world.interactions.append({"id":"epona","position":[2,0,-5],"label":"Approach Epona"})

func create_horse(at:Vector3) -> Node3D:
	horse_legs=[]
	horse=Node3D.new()
	horse.set_meta("animated",true)
	horse.position=at
	scene.add_child(horse)
	Art.ellipsoid(horse,Vector3(0,1,.2),Vector3(.40,.5,.82),Color("895739"))
	var neck=Art.ellipsoid(horse,Vector3(0,1.45,-.45),Vector3(.26,.56,.30),Color("a26843"))
	neck.rotation.x=-.3
	Art.ellipsoid(horse,Vector3(0,1.85,-.68),Vector3(.25,.30,.42),Color("925c40"))
	Art.ellipsoid(horse,Vector3(0,1.74,-1.02),Vector3(.22,.15,.20),Color("b8a082"))
	for side in [-1,1]:
		Art.ellipsoid(horse,Vector3(side*.26,1.92,-.77),Vector3(.018,.04,.06),Color("201c19"))
		Art.ellipsoid(horse,Vector3(side*.16,2.15,-.63),Vector3(.065,.19,.08),Color("85563a"))
		for z in [-.38,.67]:
			var thigh=Node3D.new()
			thigh.position=Vector3(side*.26,.94,z)
			horse.add_child(thigh)
			Art.beam(thigh,Vector3.ZERO,Vector3(0,-.43,0),.085,Color("875a40"))
			var knee=Node3D.new()
			knee.position.y=-.43
			thigh.add_child(knee)
			Art.ellipsoid(knee,Vector3.ZERO,Vector3.ONE*.095,Color("956748"))
			Art.beam(knee,Vector3.ZERO,Vector3(0,-.43,0),.065,Color("b8a586"))
			var hoof=Art.ellipsoid(knee,Vector3(0,-.43,0),Vector3(.12,.12,.17),Color("534c40"))
			horse_legs.append({"thigh":thigh,"knee":knee,"hoof":hoof,"phase":(0 if side<0 else PI)+(0 if z<0 else PI*.5)})
	for i in range(5): Art.ellipsoid(horse,Vector3(0,1.2+i*.17,-.23-i*.035),Vector3(.12,.24,.18),Color("e3d5b6"))
	horse_tail=Node3D.new()
	horse_tail.position=Vector3(0,1.2,.8)
	horse.add_child(horse_tail)
	Art.beam(horse_tail,Vector3.ZERO,Vector3(0,-.85,.45),.16,Color("d6c4a1"))
	horse_pose(0,0)
	return horse

func make_person(person:Dictionary, interactable:bool=true) -> Node3D:
	if person.style in ["zora","king_zora","ruto"]: return world.zora.make_zora(person,interactable)
	if person.style in ["goron","darunia"]: return world.mountain.make_goron(person,interactable)
	var root=Node3D.new()
	root.set_meta("animated",true)
	root.position=world.vec(person.at)
	scene.add_child(root)
	world.npc_nodes[person.id]=root
	if person.style=="owl":
		Art.beam(root,Vector3.ZERO,Vector3(0,1.9,0),.18,Color("645c3c"))
		Art.ellipsoid(root,Vector3(0,2.3,0),Vector3(.52,.7,.4),Color("947849"))
		for side in [-1,1]:
			Art.ellipsoid(root,Vector3(side*.21,2.6,.32),Vector3(.22,.24,.09),Color("d0b374"))
			Art.ellipsoid(root,Vector3(side*.21,2.6,.40),Vector3(.08,.10,.035),Color("252921"))
			Art.ellipsoid(root,Vector3(side*.48,2.2,0),Vector3(.15,.55,.37),Color("645339"))
		Art.cylinder(root,Vector3(0,2.32,.45),.01,.12,.2,Color("c9a66b"),6)
	else:
		var model:Node3D=load("res://assets/link.glb").instantiate()
		root.add_child(model)
		var adult=person.style not in ["malon","zelda"]
		model.scale=Vector3(.95,1.35,.95) if adult else Vector3.ONE
		var cloth=Color("967e5a")
		var hair=Color("5d432c")
		match person.style:
			"malon": cloth=Color("bcb394"); hair=Color("9c5531")
			"zelda": cloth=Color("b4829b"); hair=Color("c4a058")
			"guard": cloth=Color("849190"); hair=Color("686a60")
			"impa": cloth=Color("69788b"); hair=Color("bec6c3")
			"elder": cloth=Color("738378"); hair=Color("c0bab0")
			"talon": cloth=Color("995c43"); hair=Color("574233")
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			if "Cap" in mesh.name or "cap" in mesh.name: mesh.hide()
			if "Tunic" in mesh.name or "Sleeve" in mesh.name: mesh.material_override=Art.material(cloth)
			if "Hair" in mesh.name: mesh.material_override=Art.material(hair)
		if person.style in ["malon","zelda","elder"]:
			Art.cylinder(root,Vector3(0,.47,0),.33,.19,.65,cloth,12)
			for side in [-1,1]: Art.ellipsoid(root,Vector3(side*.20,.91,.07),Vector3(.09,.26,.10),hair)
		if person.style=="zelda":
			Art.ellipsoid(root,Vector3(0,1.34,.04),Vector3(.21,.18,.16),Color("ded7c3"))
			Art.ellipsoid(root,Vector3(0,1.27,.15),Vector3(.07,.055,.04),Color("9e506d"))
		if person.style=="guard":
			Art.ellipsoid(root,Vector3(0,1.65,0),Vector3(.22,.23,.18),Color("969e97"))
			Art.box(root,Vector3(0,1.66,.185),Vector3(.29,.07,.025),Color("303c3f"))
			Art.beam(root,Vector3(-.42,0,0),Vector3(-.42,2.0,0),.035,Color("80613e"))
			Art.cylinder(root,Vector3(-.42,2.1,0),.10,0,.25,Color("b7c3bb"),4)
		if person.style=="talon":
			Art.ellipsoid(root,Vector3(0,.88,0),Vector3(.31,.30,.23),Color("697697"))
			for side in [-1,1]: Art.ellipsoid(root,Vector3(side*.075,1.47,.19),Vector3(.1,.04,.04),Color("493b2e"))
		Art.collision_box(root,Vector3(0,.65,0),Vector3(.6,1.3,.6))
	if interactable: world.interactions.append({"id":"person:"+person.id,"position":person.at,"label":"Talk to "+person.name})
	return root

func travel(next:String) -> void:
	if place=="field" and next=="market" and world.time_quest.try_escape(): return
	if place=="field" and next=="market" and is_night() and not world.state.castle_escape:
		world.tell("Town Guard", "The drawbridge is raised for the night. Rest at the travelers' fire beside the ranch, or wait for sunrise.")
		return
	enter(next,place)

func speak(id:String) -> void:
	var person:Dictionary={}
	for item in places[place].people:
		if item.id==id: person=item
	if person.is_empty(): return
	var lines: Array=person.lines
	var seen=int(world.state.conversations.get(id,0))
	world.state.conversations[id]=seen+1
	match id:
		"malon_market":
			if world.state.talon_awake:
				world.tell("Malon", "You woke him! Thank you. Come visit Lon Lon Ranch; I'll introduce you to Epona.")
				return
			if not world.state.egg:
				world.state.egg=true
				world.state.egg_day=world.state.day
			else:
				world.tell("Malon", "The egg needs a night to hatch. Dad was headed for the castle's delivery yard.")
				return
		"talon":
			if world.state.egg and world.state.day>world.state.egg_day:
				world.state.talon_awake=true
				world.tell("Talon", "A cucco?! I'm awake! Malon must be furious. I'll move these crates and head back to the ranch. Thank you, kid!")
				if is_instance_valid(delivery_gate): delivery_gate.collision_layer=0
				if world.npc_nodes.has("talon"): world.npc_nodes.talon.position.x=7
				return
		"zelda":
			if not world.state.emerald:
				world.tell("Zelda", "Something is wrong in the forest. Your fairy seems to know more than she can say.")
				return
			if seen>=1:
				world.state.zelda_letter=true
				world.tell("Zelda",str(lines[1]))
				return
		"impa":
			if not world.state.zelda_letter:
				world.tell("Impa", "The princess wishes to speak with you. Hear everything she has to say.")
				return
			world.learn_song("lullaby")
		"malon_ranch": world.learn_song("epona")
		"talon_ranch":
			if not world.state.bottle:
				world.state.bottle=true
				world.state.milk=2
			elif world.state.milk==0:
				if world.state.fish and not world.state.letter_bottle:
					world.tell("Talon", "Your bottle already holds a fish. Bring an empty one for milk.")
					return
				if world.state.rupees>=10:
					world.state.rupees-=10
					world.state.milk=2
					world.tell("Talon", "Ten rupees for a fresh bottle of Lon Lon Milk. Two drinks — make them count!")
				else: world.tell("Talon", "Fresh milk is 10 rupees for two drinks. Bring your empty bottle back when you have enough.")
				return
			else:
				world.tell("Talon", "Two drinks in a bottle. Press B when you need some milk. Come back if the road wears you out.")
				return
		"baker":
			world.state.health=world.state.max_health
	world.tell(person.name,str(lines[mini(seen,lines.size()-1)]))

func interact(id:String) -> bool:
	if id.begins_with("travel:"):
		travel(id.trim_prefix("travel:"))
		return true
	if id.begins_with("person:"):
		speak(id.trim_prefix("person:"))
		return true
	match id:
		"camp":
			world.state.day+=1
			world.state.time_of_day=.28
			world.state.health=world.state.max_health
			world.tell("Dawn over Hyrule", "The fire settles into embers. Your hearts are restored."+(" The egg has hatched into a cucco!" if world.state.egg and world.state.day>world.state.egg_day else ""))
		"delivery_gate": world.tell("Navi", "The milkman is asleep beside his delivery. Malon's cucco might wake him.")
		"epona": world.tell("Malon", "Try the melody I taught you. Stand where Epona can hear, press 1, and play up, left, right; up, left, right.")
		_: return false
	return true

func is_night() -> bool:
	return world.state.time_of_day<.23 or world.state.time_of_day>.77

func tick(delta:float) -> void:
	if world.area in ["lost_woods","meadow","crater"] or (world.area=="goron" and world.state.adult): return
	world.graveyard.tick(delta)
	if place in ["dampe_race","shield_grave","heart_grave","royal_tomb","windmill"]: return
	if place in ["temple","sages"]:
		world.time_quest.tick(delta)
		return
	var previous=world.state.time_of_day
	world.state.time_of_day=fmod(previous+delta/480,1)
	if world.state.time_of_day<previous: world.state.day+=1
	var daylight=clampf(sin((world.state.time_of_day-.25)*TAU)*1.6+.35,.13,1)
	world.sunlight.light_energy=.40*daylight
	world.world_environment.environment.ambient_light_energy=.17+daylight*.11
	world.world_environment.environment.fog_light_color=Color("233651").lerp(Color("829481"),daylight)
	world.world_environment.environment.fog_density=.003
	sky_tick-=delta
	if sky_tick<=0:
		sky_tick=.5
		var sky=world.world_environment.environment.sky.sky_material
		sky.sky_top_color=Color("101b34").lerp(Color("5e8a9b"),daylight)
		sky.sky_horizon_color=Color("34445c").lerp(Color("b3c0b6"),daylight)
		sky.ground_horizon_color=sky.sky_horizon_color
	if is_instance_valid(bridge): bridge.rotation.x=lerpf(bridge.rotation.x,PI/2 if is_night() and not world.state.castle_escape else 0.0,delta*2)
	world.mountain.tick(delta)
	world.zora.tick(delta)
	caught_cooldown=maxf(0,caught_cooldown-delta)
	if place=="castle" and not world.state.zelda_letter:
		for patrol in patrols:
			var node:Node3D=patrol.node
			var phase=world.elapsed*.32+patrol.phase
			node.position.x=patrol.home.x+sin(phase)*3
			node.rotation.y=PI/2 if cos(phase)>0 else -PI/2
			var left_leg=node.find_child("LeftLeg",true,false)
			var right_leg=node.find_child("RightLeg",true,false)
			if left_leg: left_leg.rotation.x=sin(world.elapsed*5+patrol.phase)*.25
			if right_leg: right_leg.rotation.x=-sin(world.elapsed*5+patrol.phase)*.25
			var offset:Vector3=world.player.position-node.position
			offset.y=0
			if caught_cooldown>0 or offset.length()>7 or offset.length()<.01: continue
			if node.basis.z.dot(offset.normalized())<.67: continue
			var ray=PhysicsRayQueryParameters3D.create(node.position+Vector3.UP*1.5,world.player.position+Vector3.UP*.7,1)
			var hit=world.get_world_3d().direct_space_state.intersect_ray(ray)
			if hit and hit.collider!=world.player: continue
			world.player.position=Vector3(0,.1,12 if not world.state.talon_awake else 7)
			world.player.velocity=Vector3.ZERO
			world.player.update_camera(1)
			world.stats.guard_catches+=1
			caught_cooldown=3
			world.tell("Castle Guard", "You there! The inner gardens are off limits. Back to the delivery yard!")
			break
	if place=="ranch" and is_instance_valid(horse):
		var offset:Vector3=world.player.position-horse.position
		offset.y=0
		var speed=1.4 if world.state.epona_friend and offset.length()>2.5 else 0.0
		if speed>0:
			horse.position+=offset.normalized()*delta*speed
			horse.rotation.y=lerp_angle(horse.rotation.y,atan2(-offset.x,-offset.z),delta*3)
		horse_pose(delta,speed)
		for item in world.interactions:
			if item.id=="epona": item.position=[horse.position.x,horse.position.y,horse.position.z]

func horse_pose(delta:float, speed:float) -> void:
	horse_stride+=delta*speed*5
	for leg in horse_legs:
		var phase=horse_stride+leg.phase
		var stepping=speed>0
		var z=cos(phase)*.23 if stepping else 0.0
		var y=.12+maxf(0,sin(phase))*.13 if stepping else .12
		var down=.94-y
		var bend=acos(clampf(Vector2(down,z).length()/.86,.01,1))
		var upper=atan2(-z,down)-bend
		leg.thigh.rotation.x=lerp_angle(leg.thigh.rotation.x,upper,minf(1,delta*12) if delta>0 else 1)
		leg.knee.rotation.x=lerp_angle(leg.knee.rotation.x,bend*2,minf(1,delta*12) if delta>0 else 1)
		leg.hoof.rotation.x=-leg.thigh.rotation.x-leg.knee.rotation.x
	if is_instance_valid(horse_tail): horse_tail.rotation.z=sin(world.logic_time*1.8)*.12

func objective() -> String:
	var water_objective=world.zora.objective()
	if not water_objective.is_empty(): return water_objective
	var mountain_objective=world.mountain.objective()
	if not mountain_objective.is_empty(): return mountain_objective
	var prefix=places[place].name+" · "
	if world.state.sapphire: return prefix+"Three Spiritual Stones are safe; return to Hyrule Castle"
	if world.state.ruby: return prefix+"The forest and mountain stones are safe; seek the Zoras by the river"
	if world.state.zelda_letter: return prefix+"Follow the northeastern road to Kakariko and Death Mountain"
	if place=="ranch": return prefix+"Talk to Malon and play for Epona"
	if not world.state.egg: return prefix+"Find Malon in the castle town"
	if not world.state.talon_awake:
		return prefix+("Rest until dawn; then wake the milkman at the castle" if world.state.day<=world.state.egg_day else "Take the cucco to the sleeping milkman")
	return prefix+"Cross the guarded gardens and speak with Princess Zelda"
