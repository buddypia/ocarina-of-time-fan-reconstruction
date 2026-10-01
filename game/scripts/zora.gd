extends RefCounted

const Art=preload("res://scripts/art.gd")
const Natural=preload("res://scripts/natural_art.gd")
var world:Node3D
var scene:Node3D
var curtain:Node3D
var waterfall_gate:StaticBody3D
var fish_nodes:Array=[]
var fish_cooldown:=0.0
var diving_tokens:Array=[]
var diving_time:=0.0
var diving_count:=0
var jaw:Node3D
var jabu_body:Node3D
var letter:Node3D
var king_home:=Vector3(0,3,-20)

func _init(owner_world:Node3D) -> void:
	world=owner_world
	world.overworld.places.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/zora.json")))
	world.overworld.places.field.exits.append({"to":"river","at":[54,0,-8],"label":"Zora's River"})
	world.overworld.places.field.exits.append({"to":"lake","at":[-12,0,66],"label":"Lake Hylia"})

func build(place:String) -> void:
	scene=world.landscape
	curtain=null
	waterfall_gate=null
	jaw=null
	jabu_body=null
	letter=null
	fish_nodes=[]
	diving_tokens=[]
	diving_time=0
	diving_count=0
	fish_cooldown=0
	match place:
		"river": river()
		"domain": domain()
		"lake": lake()
		"fountain": fountain()

func bank(center:Vector2, size:Vector2, height:float=0, bottom:float=-7) -> void:
	if world.area=="domain":
		Natural.block(scene,Vector3(center.x,(height+bottom)*.5,center.y),Vector3(size.x,height-bottom,size.y),false,true)
		Natural.block(scene,Vector3(center.x,height-.06,center.y),Vector3(size.x,.12,size.y),true)
		return
	Art.box(scene,Vector3(center.x,(height+bottom)*.5,center.y),Vector3(size.x,height-bottom,size.y),Color("82978a"),true)
	Art.box(scene,Vector3(center.x,height-.06,center.y),Vector3(size.x,.12,size.y),Color("96ada1") if world.area=="domain" else Color("7f9677"))

func basin(bounds:Rect2, bottom:float=-6.5) -> void:
	Art.box(scene,Vector3(bounds.get_center().x,bottom-.25,bounds.get_center().y),Vector3(bounds.size.x,.5,bounds.size.y),Color("5f827b"),true)
	world.add_water(bounds,0,bottom)
	for i in range(14):
		var x=bounds.position.x+1+fmod(i*3.17,bounds.size.x-2)
		var z=bounds.position.y+1+fmod(i*5.31,bounds.size.y-2)
		Art.ellipsoid(scene,Vector3(x,bottom+.2,z),Vector3(.7,.4,.6),Color("728d80"))
		for j in range(3): Art.beam(scene,Vector3(x+j*.15,bottom,z),Vector3(x+j*.17,bottom+.8+j*.13,z+.2),.045,Color("42695a"))

func cliffs(radius:Vector2, height:float=12) -> void:
	if world.area=="domain":
		Natural.cave(scene,radius)
		return
	for i in range(24):
		var a=i*TAU/24
		var at=Vector3(sin(a)*(radius.x+4),1,cos(a)*(radius.y+4))
		var rock=Art.ellipsoid(scene,at,Vector3(5.8,height+(i%3)*1.1,6.2),Color("708779") if i%2 else Color("819788"))
		rock.create_trimesh_collision()
		rock.get_child(0).collision_layer=1
	for side in [-1,1]:
		Art.collision_box(scene,Vector3(side*(radius.x-2),3,0),Vector3(1,20,radius.y*2))
		Art.collision_box(scene,Vector3(0,3,side*(radius.y-2)),Vector3(radius.x*2,20,1))

func arch(at:Vector3, width:float=4, height:float=4) -> void:
	for side in [-1,1]:
		Art.ellipsoid(scene,at+Vector3(side*width*.65,height*.5,0),Vector3(.8,height*.6,1.1),Color("8eaaa0"))
		Art.collision_box(scene,at+Vector3(side*width*.65,height*.5,0),Vector3(1.1,height,1.5))
	Art.ellipsoid(scene,at+Vector3(0,height,0),Vector3(width*.85,.85,1.1),Color("aac4b5"))
	Art.collision_box(scene,at+Vector3(0,height*.55,0),Vector3(width*1.8,height+1,2)).collision_layer=8
	Art.box(scene,at+Vector3(0,height*.45,-.25),Vector3(width,height*.9,.1),Color("254c50"))

func river() -> void:
	basin(Rect2(-4,-26,8,56),-3.5)
	world.water_zones[0].current=Vector3(0,0,1.2)
	bank(Vector2(-12,1),Vector2(16,58))
	bank(Vector2(12,1),Vector2(16,58))
	bank(Vector2(0,28),Vector2(8,4))
	cliffs(Vector2(25,35),11)
	world.overworld.road([Vector3(-12,0,27),Vector3(-12,0,4),Vector3(-9,0,-8)],2)
	# Two supported bridges cross the river at different elevations.
	for z in [3,-13]:
		Art.walkway(scene,Vector3(-7,0,z),Vector3(7,0,z),3,Color("b2b7a1"))
		for x in [-3,3]: Art.cylinder(scene,Vector3(x,-1.8,z),.45,.55,3.6,Color("84998a"),10)
		for side in [-1,1]: Art.beam(scene,Vector3(-5,.65,z+side*1.4),Vector3(5,.65,z+side*1.4),.055,Color("869789"))
	Art.walkway(scene,Vector3(7,0,-12),Vector3(7,2,-22),4,Color("afbaa1"))
	bank(Vector2(0,-25),Vector2(18,6),2)
	Art.walkway(scene,Vector3(-2,-2,9),Vector3(-4,0,9),3.2,Color("a6b698"))
	arch(Vector3(0,2,-27),4.5,4.3)
	Art.cylinder(scene,Vector3(0,2.015,-22.8),1.7,1.7,.03,Color("a8b9a6"),24)
	for i in range(3):
		var a=i*TAU/3
		Art.cylinder(scene,Vector3(sin(a)*.5,2.05,-22.8+cos(a)*.5),.32,0,.055,Color("d5c585"),3)
	waterfall_gate=Art.collision_box(scene,Vector3(0,4,-25.2),Vector3(4.3,4,.4))
	waterfall_gate.collision_layer=0 if world.state.waterfall_open else 1
	curtain=Node3D.new()
	curtain.set_meta("animated",true)
	curtain.position=Vector3(0,2,-25.2)
	scene.add_child(curtain)
	for i in range(10):
		var ribbon=Art.box(curtain,Vector3(-2+i*.45,2,0),Vector3(.48,4,.12),Color("9bcac1"))
		ribbon.material_override=Art.material(Color(.55,.79,.77,.62),.22).duplicate()
		ribbon.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	if world.state.waterfall_open: curtain.scale.x=.035
	world.interactions.append({"id":"royal_waterfall","position":[0,2,-22.8],"label":"Read the crest before the waterfall"})
	if not world.state.river_open:
		var rock=Node3D.new()
		rock.position=Vector3(-12,0,14)
		rock.set_meta("animated",true)
		scene.add_child(rock)
		Art.ellipsoid(rock,Vector3(0,1,0),Vector3(2.2,1.8,1.4),Color("8f9683"))
		Art.collision_box(rock,Vector3(0,1,0),Vector3(3.5,2.5,1.8))
		for i in range(3): Art.beam(rock,Vector3(-.3+i*.2,.25+i*.5,1.27),Vector3(.15-i*.15,.8+i*.5,1.28),.038,Color("424f4a"))
		world.blast_targets.append({"id":"river_rock","node":rock,"position":Vector3(-12,1,14),"radius":1.0})
	world.add_rupee(Vector3(-15,0,8),"river_ledge",20)
	world.add_rupee(Vector3(11,0,-12),"river_bridge",5)
	world.add_bomb_flower(Vector3(-15,0,20),"river_flower")
	shore_plants([-4.8,4.8],[-19,-7,10,23])
	world.player.position=Vector3(-12,.2,25)

func domain() -> void:
	basin(Rect2(-9,-4,18,20))
	bank(Vector2(-15.5,0),Vector2(13,52))
	bank(Vector2(15.5,0),Vector2(13,52))
	bank(Vector2(0,-15),Vector2(18,22))
	bank(Vector2(0,21),Vector2(18,10))
	cliffs(Vector2(26,30),12)
	Art.walkway(scene,Vector3(-5,-3.5,10),Vector3(-9,0,10),3.5,Color("c0c3a3"))
	Art.walkway(scene,Vector3(5,-3.5,10),Vector3(9,0,10),3.5,Color("c0c3a3"))
	bank(Vector2(-13,-1),Vector2(6,5),3)
	Art.walkway(scene,Vector3(-13,0,8),Vector3(-13,3,1.5),3.7,Color("aebba6"),true)
	Art.box(scene,Vector3(-8.9,2.85,-1),Vector3(2.2,.3,1.6),Color("c4c7ad"),true)
	Art.beam(scene,Vector3(-11,0,-1),Vector3(-8,2.7,-1),.18,Color("81988b"))
	world.overworld.signpost(Vector3(-16,0,9),"Diving game · 20 rupees")
	bank(Vector2(0,-20),Vector2(14,10),3)
	Art.walkway(scene,Vector3(0,0,-6),Vector3(0,3,-15),5,Color("c0c5ac"),true)
	arch(Vector3(0,3,-24.3),3.1,4)
	for z in [-18,-5,9]:
		for x in [-19,19]: Natural.column(scene,Vector3(x,0,z))
		Natural.vault_rib(scene,z)
	Natural.pool_edge(scene)
	# The spring fish are shallow enough to reach from the keeper's stone lip.
	Art.cylinder(scene,Vector3(12,.015,5),1.8,1.8,.03,Color("597e70"),24)
	for i in range(16):
		var a=i*TAU/16
		Art.ellipsoid(scene,Vector3(12+sin(a)*1.7,.17,5+cos(a)*1.7),Vector3(.34,.23,.34),Color("96ac97"))
	var pool_water=Art.cylinder(scene,Vector3(12,.29,5),1.55,1.55,.025,Color("477d7f"),24)
	pool_water.material_override=Art.material(Color(.28,.49,.50,.45),.3).duplicate()
	pool_water.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in range(4):
		var fish=make_fish(scene)
		fish.scale=Vector3.ONE*.6
		fish_nodes.append({"node":fish,"phase":i*TAU/4})
	world.interactions.append({"id":"fish_pool","position":[12,0,5],"label":"Fish in the shallow spring · V uses a bottle"})
	underwater_arch(Vector3(7,-5.7,13.5),-.8)
	Natural.cavern_roof(scene)
	for x in [-19,19]:
		for z in [-5,9]: Natural.lamp(scene,Vector3(x*.971,3.3,z),-PI*.5 if x>0 else PI*.5)
	for model in scene.find_children("*","MeshInstance3D",true,false):
		if model.get_parent()==scene and model.mesh is BoxMesh: model.material_override=Natural.stone()
	for ramp in scene.get_children():
		if ramp.get_class()=="Node3D" and ramp.get_child_count()==2 and ramp.get_child(0) is MeshInstance3D and ramp.get_child(1) is StaticBody3D:
			ramp.get_child(0).material_override=Natural.stone(true)
	var daylight=SpotLight3D.new()
	daylight.position=Vector3(0,8,24)
	daylight.rotation_degrees=Vector3(-24,0,0)
	daylight.spot_range=65
	daylight.spot_angle=65
	daylight.light_energy=7
	daylight.light_color=Color("e5e9ec")
	daylight.shadow_enabled=true
	scene.add_child(daylight)
	if RenderingServer.get_current_rendering_method()=="forward_plus":
		world.world_environment.environment.ssao_enabled=true
		world.world_environment.environment.ssao_radius=1.1
		world.world_environment.environment.ssao_intensity=1.3
		world.world_environment.environment.ssr_enabled=true
	# Give the four shadow-casting wall lamps a full quadrant each.
	world.get_viewport().positional_shadow_atlas_size=4096
	for quadrant in range(4): world.get_viewport().set_positional_shadow_atlas_quadrant_subdiv(quadrant,Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1)
	var reflection=ReflectionProbe.new()
	reflection.position=Vector3(0,3,0)
	reflection.size=Vector3(68,30,80)
	reflection.origin_offset=Vector3(0,-1,0)
	reflection.interior=true
	reflection.box_projection=true
	reflection.enable_shadows=true
	reflection.ambient_mode=ReflectionProbe.AMBIENT_DISABLED
	scene.add_child(reflection)
	world.player.position=Vector3(0,.2,22)

func underwater_arch(at:Vector3, angle:float=0) -> void:
	var root=Node3D.new()
	root.position=at
	root.rotation.y=angle
	scene.add_child(root)
	for side in [-1,1]: Art.ellipsoid(root,Vector3(side*1.35,.8,0),Vector3(.55,1.3,.7),Color("526f69"))
	Art.ellipsoid(root,Vector3(0,2,0),Vector3(1.7,.45,.7),Color("859e8b"))
	Art.box(root,Vector3(0,.7,.15),Vector3(2.2,2,.1),Color("183f46"))
	var light=OmniLight3D.new()
	light.position=at+Vector3(0,1,-1)
	light.light_color=Color("85c5bc")
	light.light_energy=.65
	light.omni_range=5
	scene.add_child(light)

func lake() -> void:
	basin(Rect2(-23,-29,46,48))
	bank(Vector2(-31.5,0),Vector2(17,76))
	bank(Vector2(31.5,0),Vector2(17,76))
	bank(Vector2(0,28.5),Vector2(46,19))
	bank(Vector2(0,-33.5),Vector2(46,9))
	cliffs(Vector2(44,43),10)
	Art.walkway(scene,Vector3(-7,-4,10),Vector3(-7,0,19),3.5,Color("bec1a0"))
	world.overworld.building(Vector3(-32,0,4),Vector3(8,5,9),Color("627c80"))
	world.overworld.building(Vector3(33,0,6),Vector3(8,3,7),Color("897852"))
	for x in [-5,5]:
		Art.beam(scene,Vector3(x,-6,13),Vector3(x,.6,13),.15,Color("756e50"))
	Art.box(scene,Vector3(0,.15,13),Vector3(10,.3,1.5),Color("a4936a"),true)
	Art.box(scene,Vector3(0,.15,16),Vector3(2.3,.3,6),Color("a4936a"),true)
	Art.walkway(scene,Vector3(0,0,21),Vector3(0,.3,19),2.3,Color("b4a579"))
	for i in range(11): Art.box(scene,Vector3(-5+i,.315,13),Vector3(.07,.03,1.5),Color("6d684e"))
	underwater_arch(Vector3(-7,-5.7,-13),.4)
	letter=make_bottle(scene,Vector3(-3,-4.8,-10),true)
	letter.visible=not world.state.ruto_letter
	if not world.state.ruto_letter: world.interactions.append({"id":"ruto_letter","position":[-3,-4.8,-10],"label":"Take the bottle from the lake bed"})
	world.overworld.road([Vector3(0,0,33),Vector3(0,0,24),Vector3(-27,0,22),Vector3(-27,0,10)],2)
	world.add_rupee(Vector3(14,0,20),"lake_bank",20)
	shore_plants([-23.8,23.8],[-23,-16,-7,3,14])
	for at in [Vector3(-20,0,24),Vector3(26,0,24),Vector3(-26,0,-20),Vector3(26,0,-22)]: Art.tree(scene,at,.85,int(at.x+50))
	world.player.position=Vector3(0,.2,31)

func make_bottle(parent:Node3D, at:Vector3, paper:bool=false) -> Node3D:
	var root=Node3D.new()
	root.set_meta("animated",true)
	root.position=at
	parent.add_child(root)
	var glass=Art.ellipsoid(root,Vector3(0,.24,0),Vector3(.17,.24,.17),Color("79bdb8"))
	glass.material_override=Art.material(Color(.47,.76,.71,.5),.15).duplicate()
	glass.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	Art.cylinder(root,Vector3(0,.49,0),.08,.07,.16,Color("8bcac1"),12)
	Art.cylinder(root,Vector3(0,.58,0),.072,.07,.07,Color("b08e58"),10)
	if paper: Art.cylinder(root,Vector3(0,.25,0),.05,.05,.3,Color("e5d2a0"),10)
	return root

func make_fish(parent:Node3D) -> Node3D:
	var root=Node3D.new()
	root.set_meta("animated",true)
	parent.add_child(root)
	Art.ellipsoid(root,Vector3.ZERO,Vector3(.10,.16,.31),Color("91b3a0"))
	var tail=Art.cylinder(root,Vector3(0,0,.35),.20,0,.18,Color("6d8f79"),3)
	tail.rotation.x=PI/2
	for side in [-1,1]: Art.ellipsoid(root,Vector3(side*.09,.06,-.17),Vector3(.035,.035,.025),Color("293d3b"))
	return root

func fountain() -> void:
	basin(Rect2(-17,-24,34,42),-5.5)
	bank(Vector2(-22,0),Vector2(10,58))
	bank(Vector2(22,0),Vector2(10,58))
	bank(Vector2(0,24),Vector2(34,12))
	bank(Vector2(0,-26),Vector2(34,4))
	cliffs(Vector2(30,33),17)
	Art.walkway(scene,Vector3(0,-3.5,12),Vector3(0,0,18),5,Color("bdc5a5"))
	Art.box(scene,Vector3(0,.15,11),Vector3(6,.4,14),Color("a0b0a0"),true)
	Art.walkway(scene,Vector3(0,0,21),Vector3(0,.35,18),6,Color("afbaa1"))
	for side in [-1,1]:
		for z in [6,12,17]: Art.cylinder(scene,Vector3(side*2.4,-2.8,z),.35,.4,5.6,Color("809991"),10)
	jabu_body=Node3D.new()
	jabu_body.set_meta("animated",true)
	jabu_body.position=Vector3(0,0,-6)
	scene.add_child(jabu_body)
	soft_form(jabu_body,Vector3(0,1,-4),Vector3(8,5.2,11),Color("759c9f"))
	soft_form(jabu_body,Vector3(0,2,1),Vector3(6.7,4.4,6),Color("84a8a5"))
	soft_form(jabu_body,Vector3(0,1,6.9),Vector3(3.4,1.2,.7),Color("172d35"))
	for side in [-1,1]:
		soft_form(jabu_body,Vector3(side*4.5,4.3,3.6),Vector3(1.5,1.0,1.0),Color("b7c4a5"))
		soft_form(jabu_body,Vector3(side*4.6,4.25,4.45),Vector3(.8,.65,.24),Color("d5ce9b"))
		soft_form(jabu_body,Vector3(side*4.55,4.2,4.68),Vector3(.28,.42,.12),Color("303d48"))
		var fin=soft_form(jabu_body,Vector3(side*7.9,.6,-4),Vector3(4,.45,3),Color("77918d"))
		fin.rotation.z=side*.20
		for i in range(4): Art.beam(jabu_body,Vector3(side*(6.15-i*.08),2.7,-1-i*.85),Vector3(side*(6.6-i*.08),.4,-.7-i*.85),.16,Color("587d80"))
		for i in range(3): soft_form(jabu_body,Vector3(side*(3+i*.4),5.3-i*.25,-1),Vector3(.18,.14,.24),Color("d3bb8c"))
	soft_form(jabu_body,Vector3(0,5.7,-.5),Vector3(1.4,.3,3.4),Color("b6af82"))
	jaw=Node3D.new()
	jaw.position=Vector3(0,-.7,4.5)
	jabu_body.add_child(jaw)
	soft_form(jaw,Vector3(0,1.7,2.4),Vector3(4.2,1.35,2.1),Color("a3b7a3"))
	soft_form(jaw,Vector3(0,2.1,3.2),Vector3(3.2,.40,.8),Color("b29486"))
	jaw.rotation.x=.70 if world.state.jabu_open else 0
	for i in range(13):
		var a=(i-6)*PI/12
		soft_form(jabu_body,Vector3(sin(a)*3.5,1.0+cos(a)*1.35,7.0),Vector3(.45,.27,.32),Color("a6b7a1"))
	for side in [-1,1]:
		soft_form(jabu_body,Vector3(side*1.6,3.8,6.1),Vector3(.36,.18,.16),Color("476b70"))
	world.interactions.append({"id":"jabu_mouth","position":[0,.35,4.5],"label":"Enter Lord Jabu-Jabu" if world.state.jabu_open else "Approach Lord Jabu-Jabu · V offers a fish"})
	if world.state.sapphire:
		var princess=make_zora({"id":"ruto_after","style":"ruto","at":[-1.5,.35,13],"name":"Princess Ruto"})
		world.jabu.smooth_ruto(princess)
	world.player.position=Vector3(0,.2,21)

func fin(parent:Node3D, points:Array, color:Color) -> void:
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0,1,2,2,1,0]: surface.add_vertex(points[index])
	surface.generate_normals()
	var mesh=MeshInstance3D.new()
	mesh.mesh=surface.commit()
	mesh.material_override=Art.material(color,.45)
	parent.add_child(mesh)

func make_zora(person:Dictionary, interactable:bool=true) -> Node3D:
	var root=Node3D.new()
	root.position=world.vec(person.at)
	root.set_meta("animated",true)
	scene.add_child(root)
	world.npc_nodes[person.id]=root
	var royal=person.style=="king_zora"
	var skin=Color("83b6c1") if not royal else Color("86b8ba")
	var pale=Color("d0d9ba")
	var form=Node3D.new()
	form.name="Body"
	root.add_child(form)
	if royal:
		Art.ellipsoid(form,Vector3(0,1.15,0),Vector3(1.7,1.45,1.25),skin)
		Art.ellipsoid(form,Vector3(0,1.1,.9),Vector3(1.3,1.05,.46),pale)
		Art.ellipsoid(form,Vector3(0,2.3,0),Vector3(.85,.65,.85),skin)
		for side in [-1,1]:
			Art.ellipsoid(form,Vector3(side*1.3,.34,.9),Vector3(.48,.28,.7),skin)
			Art.ellipsoid(form,Vector3(side*1.5,1.3,.45),Vector3(.5,.7,.43),skin)
			Art.ellipsoid(form,Vector3(side*.40,2.5,.71),Vector3(.25,.2,.09),pale)
			Art.ellipsoid(form,Vector3(side*.39,2.48,.80),Vector3(.08,.11,.04),Color("273e46"))
		Art.cylinder(form,Vector3(0,2.97,0),.6,.64,.25,Color("bfa568"),12)
		for i in range(6): Art.cylinder(form,Vector3(sin(i*TAU/6)*.56,3.21,cos(i*TAU/6)*.56),.14,0,.4,Color("d4bd74"),4)
		Art.ellipsoid(form,Vector3(0,2.95,.62),Vector3(.14,.2,.08),Color("456c99"))
		Art.beam(form,Vector3(-.35,2.10,.86),Vector3(.35,2.10,.86),.045,Color("5b7980"))
		Art.collision_box(root,Vector3(0,1.3,0),Vector3(3.2,2.6,2.3))
		if world.state.letter_delivered: root.position.x=4.5
	else:
		Art.ellipsoid(form,Vector3(0,1.15,0),Vector3(.31,.55,.25),skin)
		Art.ellipsoid(form,Vector3(0,1.14,.17),Vector3(.23,.44,.10),pale)
		Art.beam(form,Vector3(0,1.5,0),Vector3(0,1.84,0),.13,skin)
		Art.ellipsoid(form,Vector3(0,1.96,.02),Vector3(.28,.25,.34),skin)
		Art.ellipsoid(form,Vector3(0,1.85,.25),Vector3(.22,.10,.2),pale)
		Art.beam(form,Vector3(0,2.06,-.12),Vector3(0,1.54,-.61),.17,skin)
		fin(form,[Vector3(0,2.08,-.2),Vector3(0,1.43,-.72),Vector3(0,1.54,-.23)],Color("6a929c"))
		for side in [-1,1]:
			Art.beam(form,Vector3(side*.20,.82,0),Vector3(side*.24,.42,.04),.14,skin)
			Art.beam(form,Vector3(side*.24,.42,.04),Vector3(side*.28,.10,.02),.08,skin)
			Art.ellipsoid(form,Vector3(side*.28,.09,.16),Vector3(.14,.08,.30),skin)
			Art.beam(form,Vector3(side*.28,1.52,0),Vector3(side*.44,1.19,.03),.095,skin)
			Art.beam(form,Vector3(side*.44,1.19,.03),Vector3(side*.50,.84,.13),.07,skin)
			Art.ellipsoid(form,Vector3(side*.50,.82,.15),Vector3(.1,.15,.045),skin)
			fin(form,[Vector3(side*.45,1.24,.01),Vector3(side*.8,1.15,-.18),Vector3(side*.5,.92,.08)],Color("aacbbc"))
			Art.ellipsoid(form,Vector3(side*.17,2.01,.28),Vector3(.078,.065,.04),pale)
			Art.ellipsoid(form,Vector3(side*.17,2.01,.315),Vector3(.033,.042,.025),Color("263e49"))
			for i in range(3): Art.beam(form,Vector3(side*.12,1.75-i*.07,.11),Vector3(side*.21,1.74-i*.07,.09),.014,Color("618c98"))
		Art.collision_box(root,Vector3(0,.9,0),Vector3(.55,1.8,.55))
		if person.style=="ruto": root.scale=Vector3.ONE*.67
	if interactable: world.interactions.append({"id":"person:"+person.id,"position":[root.position.x,root.position.y,root.position.z],"label":"Talk to "+person.name})
	return root

func start_diving() -> void:
	if world.state.silver_scale:
		world.tell("Diving Master", "The Silver Scale is yours. Hold Space in the water to dive deeper; release it to surface. The tunnel below leads to Lake Hylia.")
		return
	if world.state.diving_won:
		world.state.silver_scale=true
		world.chime(1200,.4)
		world.tell("Silver Scale", "A scale from the Zoras! You can now dive six metres. Follow the submerged arch in the southeast corner to Lake Hylia.")
		return
	if diving_time>0:
		world.tell("Diving Master", "All five blue rupees, before the bell! Hold Space to dive, and let go when you need air. The pale ramps lead back to shore.")
		return
	if world.state.rupees<20:
		world.tell("Diving Master", "The diving game costs 20 rupees. There are glints along the riverbank. Bring them back and we can begin.")
		return
	world.state.rupees-=20
	diving_time=55
	diving_count=0
	for token in diving_tokens:
		if is_instance_valid(token.node): token.node.queue_free()
	diving_tokens=[]
	for at in [Vector3(-6,-2,2),Vector3(-2,-2.2,1),Vector3(2,-2.2,0),Vector3(5,-2.1,4),Vector3(0,-2,6)]:
		var node=Art.rupee(scene,at+Vector3.UP*.25)
		node.set_meta("animated",true)
		diving_tokens.append({"node":node,"position":at,"taken":false})
	world.tell("Diving Master", "Collect five blue rupees in 55 seconds! Walk off the board. Hold Space to dive; release it to breathe. Then return up the pale ramp for your prize. Leaving ends the round.")

func tick(delta:float) -> void:
	if world.area not in ["river","domain","lake","fountain"]: return
	if world.area=="domain":
		world.sunlight.light_energy=.15
		world.world_environment.environment.ambient_light_energy=.26
		world.world_environment.environment.fog_light_color=Color("4b7477")
		world.world_environment.environment.fog_density=.0008
		world.world_environment.environment.ambient_light_color=Color("c9cfd4")
	for id in world.npc_nodes:
		var npc:Node3D=world.npc_nodes[id]
		var form=npc.get_node_or_null("Body")
		if form: form.rotation.z=sin(world.logic_time*.85+float(id.hash()%10))*.012
	fish_cooldown=maxf(0,fish_cooldown-delta)
	for fish in fish_nodes:
		var a=world.logic_time*.7+fish.phase
		fish.node.position=Vector3(12+cos(a)*1.05,.16,5+sin(a)*.7)
		fish.node.rotation.y=-a-PI*.5
		fish.node.rotation.z=sin(a*5)*.1
		fish.node.visible=fish_cooldown<=0
	if is_instance_valid(jaw): jaw.rotation.x=lerpf(jaw.rotation.x,.70 if world.state.jabu_open else .015+sin(world.logic_time*.8)*.018,delta*2)
	if is_instance_valid(jabu_body): jabu_body.scale.y=1+sin(world.logic_time*.7)*.007
	if diving_time>0:
		diving_time=maxf(0,diving_time-delta)
		for token in diving_tokens:
			if token.taken: continue
			token.node.rotation.y=world.logic_time*1.2
			if world.player.swimming and world.player.position.y<-.95 and world.player.position.distance_to(token.position)<.95:
				token.taken=true
				token.node.hide()
				diving_count+=1
				if diving_count==1: world.message_panel.hide()
				world.state.rupees=mini(99,world.state.rupees+5)
				world.chime(1050,.12)
		if diving_count==5:
			diving_time=0
			world.state.diving_won=true
			world.tell("Diving Master", "All five! Take a breath, swim to the pale ramp, and come back up for your Silver Scale.")
		elif diving_time<=0:
			for token in diving_tokens: token.node.hide()
			world.tell("Diving Master", "Time! You keep the rupees you found. Come back up the pale ramp to try again.")

func interact(id:String) -> bool:
	match id:
		"person:ruto_after":
			world.tell("Ruto","Father will be relieved, though I still have to explain the letter. Keep the Sapphire safe. You promised to remember us when you return to the castle.")
			return true
		"person:diving_master": start_diving(); return true
		"royal_waterfall": world.tell("Royal Crest", "When the royal family rests, the river remembers its song."); return true
		"fish_pool": world.tell("Shallow spring", "An empty bottle can hold a small fish. Stand beside the pool and press V."); return true
		"ruto_letter":
			if world.state.ruto_letter: return true
			if not world.state.silver_scale or world.player.position.y> -3:
				world.tell("Navi", "The bottle rests deep below. The Zoras can teach you to dive farther.")
				return true
			world.state.ruto_letter=true
			letter.hide()
			world.interactions=world.interactions.filter(func(item): return item.id!="ruto_letter")
			world.tell("Ruto's Letter", "Help me! I am inside Lord Jabu-Jabu. Please do not tell my father! — Ruto.\nThe bottle is yours. Take the letter to King Zora.")
			return true
		"person:king_zora":
			if world.state.sapphire:
				world.tell("King Zora", "Ruto is safe, and Lord Jabu-Jabu breathes easily again. You carry the trust of our people. Return to the princess of Hyrule with the three Spiritual Stones.")
			elif world.state.letter_delivered:
				world.tell("King Zora", "Please bring my daughter back. The shrine behind me leads to Lord Jabu-Jabu. Take a fresh fish from the shallow spring.")
			elif world.state.ruto_letter:
				world.state.letter_delivered=true
				world.state.letter_bottle=true
				world.create_tween().tween_property(world.npc_nodes.king_zora,"position:x",4.5,1.8)
				for item in world.interactions:
					if item.id==id: item.position=[4.5,3,-20]
				world.tell("King Zora", "Inside Lord Jabu-Jabu?! I will open the shrine. Please find Ruto. Keep the empty bottle; a fresh fish may persuade our guardian to open his mouth.")
			else: world.tell("King Zora", "My daughter Ruto has disappeared. Search the lake for any sign of her. The diving master knows a way beneath the water.")
			return true
		"jabu_mouth":
			if not world.state.jabu_open: world.tell("Navi", "His lips are closed. The shrine keeper says Ruto brought him a fish each morning. V offers a bottled fish.")
			elif world.jabu!=null: world.jabu.enter("mouth")
			else: world.tell("Lord Jabu-Jabu", "The guardian's mouth is open. The next part of this authored reconstruction is still being built.")
			return true
	if id.begins_with("travel:"):
		var next=id.trim_prefix("travel:")
		if world.area=="river" and next=="domain" and not world.state.waterfall_open:
			world.tell("Navi", "A royal crest stands in front of the waterfall. Try the melody Impa taught you.")
			return true
		if world.area=="domain" and next=="fountain" and not world.state.letter_delivered:
			world.tell("King Zora", "Only those with my permission may enter the sacred fountain. Please find my daughter.")
			return true
		if (world.area=="domain" and next=="lake") or (world.area=="lake" and next=="domain"):
			if not world.state.silver_scale or not world.player.swimming or world.player.position.y> -3:
				world.tell("Navi", "This passage runs deep. Win the Zoras' Silver Scale before trying to follow it.")
				return true
	return false

func on_song(id:String) -> bool:
	if world.area!="river" or id!="lullaby" or world.player.position.distance_to(Vector3(0,2,-22.8))>4: return false
	world.state.waterfall_open=true
	waterfall_gate.collision_layer=0
	world.create_tween().tween_property(curtain,"scale:x",.035,1.2)
	world.tell("The waterfall parts", "The royal melody stills the curtain. Beyond it, cool stone halls echo with the voices of the Zoras.")
	return true

func use_bottle() -> void:
	if is_instance_valid(world.held_bomb) or is_instance_valid(world.carried_person) or world.player.swimming or world.player.climbing: return
	if not world.state.letter_bottle and not (world.state.bottle and world.state.milk==0):
		world.tell("Bottle", "You need an empty bottle. Finish the ranch milk, or find the bottle that sank in Lake Hylia.")
		return
	if world.area=="fountain" and world.player.position.distance_to(Vector3(0,0,4.5))<3 and world.state.fish:
		if world.state.jabu_open:
			world.tell("Navi", "His mouth is already open. Keep the fish and approach the entrance.")
			return
		world.state.fish=false
		world.state.jabu_open=true
		for item in world.interactions:
			if item.id=="jabu_mouth": item.label="Enter Lord Jabu-Jabu"
		world.tell("Lord Jabu-Jabu", "The guardian smells the fish. His great jaw opens, and the spring draws a long, uneasy breath. E enters his mouth.")
		return
	if world.state.fish:
		world.tell("Bottle", "A small fish swims in your bottle. Take it to Lord Jabu-Jabu at the fountain.")
		return
	if world.area=="domain" and world.player.position.distance_to(Vector3(12,0,5))<2.5 and fish_cooldown<=0:
		world.state.fish=true
		fish_cooldown=7
		world.chime(900,.2)
		world.tell("Fish in a Bottle", "A quick scoop! The bottle now holds a lively fish. The shrine keeper says Lord Jabu-Jabu will eat it.")
		return
	world.tell("Empty Bottle", "Look for small fish in the shallow spring beside the Domain's pool keeper.")

func open_river(node:Node3D) -> void:
	world.state.river_open=true
	world.hide_breakable(node)
	world.tell("Riverbank cleared", "The cracked stone falls away. Follow the river upstream to the royal crest before the waterfall.")

func objective() -> String:
	if world.state.sapphire and world.area in ["river","domain","lake","fountain"] and diving_time<=0:
		return "ZORA'S REALM · Three Spiritual Stones · Return to Hyrule Castle"
	match world.area:
		"river": return "ZORA'S RIVER · Play the royal melody before the waterfall" if not world.state.waterfall_open else "ZORA'S RIVER · Enter the parted waterfall"
		"domain":
			if diving_time>0: return "DIVING GAME · %d / 5 rupees · %.0f seconds · Space dives; release to breathe" % [diving_count,ceil(diving_time)]
			if not world.state.silver_scale: return "ZORA'S DOMAIN · Return to the diving master for your prize" if world.state.diving_won else "ZORA'S DOMAIN · Climb the western ramp to the diving master"
			if not world.state.ruto_letter: return "ZORA'S DOMAIN · Dive through the southeast passage to Lake Hylia"
			if not world.state.letter_delivered: return "ZORA'S DOMAIN · Bring Ruto's letter to King Zora"
			return "ZORA'S DOMAIN · Bottle a fish with V, then pass behind the king"
		"lake": return "LAKE HYLIA · Bring the lake's letter to King Zora" if world.state.ruto_letter else "LAKE HYLIA · Find the bottle near the submerged northwest arch"
		"fountain":
			return "ZORA'S FOUNTAIN · Enter the guardian's open mouth" if world.state.jabu_open else "ZORA'S FOUNTAIN · Offer a bottled fish at Lord Jabu-Jabu's mouth"
	return ""

func shore_plants(xs:Array, zs:Array) -> void:
	for x in xs:
		for z in zs:
			Art.ellipsoid(scene,Vector3(x,-.2,z),Vector3(.9,.55,1.25),Color("6a8170"))
			for i in range(5):
				var at=Vector3(x+(i%2)*.13,0,z+i*.18)
				Art.beam(scene,at,at+Vector3(.1,.8+i*.04,-.15),.026,Color("687f48"))
				Art.ellipsoid(scene,at+Vector3(.1,.74+i*.04,-.15),Vector3(.065,.18,.065),Color("9c8b59"))

func soft_form(parent:Node3D, at:Vector3, size:Vector3, color:Color) -> MeshInstance3D:
	var sphere=SphereMesh.new()
	sphere.radial_segments=24
	sphere.rings=12
	sphere.radius=1
	sphere.height=2
	var mesh=Art.mesh(parent,sphere,at,color)
	mesh.material_override=Art.material(color,.58)
	mesh.scale=size
	return mesh
