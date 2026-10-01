extends RefCounted

const Art=preload("res://scripts/art.gd")
var world:Node3D
var scene:Node3D
var eye_nodes:Dictionary={}
var web:Node3D
var room:="lobby"
var scrub_order:Array=[]
var torch_position:=Vector3(-7,0,4)
var web_door_position:=Vector3(0,0,-9)

func _init(owner_world:Node3D) -> void:
	world=owner_world

func enter(next:String, from:String="") -> void:
	world.clear_landscape()
	scene=world.landscape
	room=next
	world.area="deku_"+room
	world.state.deku_entered=true
	eye_nodes={}
	web=null
	world.ladders=[]
	world.player.lock_target=null
	world.player.climbing=false
	world.player.velocity=Vector3.ZERO
	world.player.position=Vector3(0,.2,8)
	world.player.yaw=0
	world.set_ambience(true)
	match room:
		"lobby": lobby(from)
		"slingshot": slingshot_room()
		"basement": basement()
		"scrubs": scrubs()
		"gohma": boss()
	Art.batch_static(scene)
	world.player.update_camera(1.0)
	world.apply_state()
	world.checkpoint={"area":world.area,"position":world.player.position}

func shell(radius:float, height:float, floor_hole:float=0) -> void:
	if floor_hole>0:
		ring(radius,floor_hole,0,Color("6f6045"),true)
	else:
		Art.cylinder(scene,Vector3(0,-.2,0),radius,radius,.4,Color("6f6045"),32)
		Art.collision_box(scene,Vector3(0,-.2,0),Vector3(radius*2,.4,radius*2))
	for i in range(32):
		var a=i*TAU/32.0
		var p=Vector3(sin(a)*radius,height*.5,cos(a)*radius)
		var wall=Art.box(scene,p,Vector3(radius*.22,height,.65),Color("514433"))
		wall.rotation.y=a
		var col=Art.collision_box(scene,p,Vector3(radius*.22,height,.65))
		col.rotation.y=a
		if i%2==1:
			var rib=Art.beam(scene,Vector3(sin(a)*(radius-.8),0,cos(a)*(radius-.8)),Vector3(sin(a)*(radius-1.8),height*.94,cos(a)*(radius-1.8)),.26,Color("3d382b"))
			rib.create_trimesh_collision()
	# Open crown admits a cool shaft of light; candles define the routes below.
	for i in range(6):
		var a=i*TAU/6
		Art.beam(scene,Vector3(sin(a)*radius,height-.4,cos(a)*radius),Vector3(sin(a+1)*(radius-5),height+.7,cos(a+1)*(radius-5)),.5,Color("3b382a"))

func ring(outer:float, inner:float, y:float, color:Color, solid:bool) -> MeshInstance3D:
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(48):
		var a=i*TAU/48.0
		var b=(i+1)*TAU/48.0
		var p=[Vector3(sin(a)*inner,y,cos(a)*inner),Vector3(sin(a)*outer,y,cos(a)*outer),Vector3(sin(b)*outer,y,cos(b)*outer),Vector3(sin(b)*inner,y,cos(b)*inner)]
		for index in [0,2,1,0,3,2]:
			surface.set_normal(Vector3.UP)
			surface.set_uv(Vector2(p[index].x,p[index].z)*.2)
			surface.add_vertex(p[index])
	var node=MeshInstance3D.new()
	node.mesh=surface.commit()
	node.material_override=Art.material(color)
	scene.add_child(node)
	if solid: node.create_trimesh_collision()
	return node

func door(id:String, position:Vector3, label:String) -> void:
	world.interactions.append({"id":id,"position":[position.x,position.y,position.z],"label":label})
	for side in [-1,1]: Art.beam(scene,position+Vector3(side*.9,0,-.45),position+Vector3(side*.9,2.4,-.45),.14,Color("857153"))
	Art.beam(scene,position+Vector3(-.9,2.4,-.45),position+Vector3(.9,2.4,-.45),.14,Color("857153"))
	Art.box(scene,position+Vector3(0,1.05,-.50),Vector3(1.6,2.1,.12),Color("26312a"))
	var camera_blocker=Art.collision_box(scene,position+Vector3(0,1.05,-.50),Vector3(1.6,2.1,.16))
	camera_blocker.collision_layer=8

func flame(at:Vector3) -> void:
	Art.cylinder(scene,at+Vector3.UP*.65,.10,.08,1.3,Color("5c422e"),8)
	Art.ellipsoid(scene,at+Vector3.UP*1.4,Vector3(.16,.35,.16),Color("f0b957"))
	var lamp=OmniLight3D.new()
	lamp.position=at+Vector3.UP*1.6
	lamp.light_color=Color("ffc276")
	lamp.light_energy=1.4
	lamp.omni_range=7
	scene.add_child(lamp)

func seed_pot(at:Vector3) -> void:
	Art.cylinder(scene,at+Vector3.UP*.28,.25,.32,.55,Color("917049"),10)
	Art.cylinder(scene,at+Vector3.UP*.58,.32,.32,.07,Color("b2996b"),10)
	world.interactions.append({"id":"seeds","position":[at.x,at.y,at.z],"label":"Refill Deku Seeds"})

func ladder(base:Vector3, top:Vector3, id:String) -> void:
	for side in [-1,1]: Art.beam(scene,base+Vector3(side*.38,0,0),top+Vector3(side*.38,.5,0),.045,Color("719057"))
	var height=top.y-base.y
	for i in range(int(height/.34)+1): Art.beam(scene,base+Vector3(-.4,i*.34,0),base+Vector3(.4,i*.34,0),.04,Color("718c4e"))
	world.ladders.append({"id":id,"base":base,"top":top})
	world.interactions.append({"id":"climb:"+id,"position":[base.x,base.y,base.z+1],"label":"Climb vines · W / S"})

func make_web(at:Vector3, radius:float, vertical:bool=false) -> Node3D:
	var root=Node3D.new()
	root.set_meta("animated",true)
	root.position=at
	scene.add_child(root)
	for i in range(12):
		var a=i*TAU/12
		Art.beam(root,Vector3.ZERO,Vector3(sin(a)*radius,.01,cos(a)*radius),.017,Color("d7d4b8"))
	for r in [.3,.6,.85,1.0]:
		for i in range(18):
			var a=i*TAU/18
			var b=(i+1)*TAU/18
			Art.beam(root,Vector3(sin(a)*radius*r,.01,cos(a)*radius*r),Vector3(sin(b)*radius*r,.01,cos(b)*radius*r),.014,Color("c5c7ae"))
	if vertical: root.rotation.x=PI/2
	return root

func lobby(from:String) -> void:
	shell(12,11,3.5)
	Art.cylinder(scene,Vector3(0,-3.2,0),3.5,3.5,.1,Color("1e2821"),32)
	for i in range(24):
		var a=i*TAU/24.0
		var shaft=Art.box(scene,Vector3(sin(a)*3.5,-1.6,cos(a)*3.5),Vector3(.95,3.2,.16),Color("443f2b"))
		shaft.rotation.y=a
	for side in [-1,1]: Art.beam(scene,Vector3(-11,2.4,side*.7),Vector3(-5,5.8,side*.7),.30,Color("574b32"))
	ring(11.4,8.8,6,Color("79684a"),true)
	Art.box(scene,Vector3(-6.9,5.82,0),Vector3(5.6,.36,1.6),Color("8b7751"),true)
	for side in [-1,1]: Art.beam(scene,Vector3(-9.6,5.65,side*.65),Vector3(-4.3,5.65,side*.65),.17,Color("574b32"))
	ladder(Vector3(-10,0,0),Vector3(-10,6,0),"gallery")
	if not world.state.web_broken:
		web=make_web(Vector3(0,.02,0),3.5)
		Art.collision_box(web,Vector3(0,-.02,0),Vector3(6.8,.12,6.8))
	door("room:slingshot",Vector3(8.5,0,-3),"Enter the chamber")
	door("exit",Vector3(0,0,9.5),"Return to Kokiri Forest")
	flame(Vector3(3,0,7))
	world.spawn_creature("baba",Vector3(5,0,1),"lobby_baba")
	if from=="slingshot": world.player.position=Vector3(7,0,-3)
	world.tell("Navi", "Vines reach the upper gallery. A fall from above could break that thick web. The eastern chamber holds something useful.")

func slingshot_room() -> void:
	shell(10,7)
	Art.box(scene,Vector3(0,1,-6.5),Vector3(12,2,6),Color("796143"),true)
	# A solid wedge meets the floor and platform without a vertical end lip.
	var vertices=PackedVector3Array([
		Vector3(-5,-.2,4.6),Vector3(-3,-.2,4.6),Vector3(-5,-.03,4.6),Vector3(-3,-.03,4.6),
		Vector3(-5,-.2,-3.5),Vector3(-3,-.2,-3.5),Vector3(-5,2,-3.5),Vector3(-3,2,-3.5)])
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [2,7,3,2,6,7,0,3,1,0,2,3,4,5,7,4,7,6,0,4,6,0,6,2,1,3,7,1,7,5,0,1,5,0,5,4]:
		surface.set_uv(Vector2(vertices[index].x,vertices[index].z)*.2)
		surface.add_vertex(vertices[index])
	surface.generate_normals()
	var ramp=MeshInstance3D.new()
	ramp.mesh=surface.commit()
	ramp.material_override=Art.material(Color("887752"))
	scene.add_child(ramp)
	var ramp_body=StaticBody3D.new()
	var collision=CollisionShape3D.new()
	var shape=ConvexPolygonShape3D.new()
	shape.points=vertices
	collision.shape=shape
	ramp_body.add_child(collision)
	scene.add_child(ramp_body)
	world.chest_nodes.slingshot=Art.chest(scene,Vector3(0,2,-7))
	world.interactions.append({"id":"slingshot","position":[0,2,-6],"label":"Open chest"})
	door("room:lobby",Vector3(0,0,8),"Return to the hollow")
	make_eye("ladder",Vector3(0,3.5,8.7))
	flame(Vector3(5,0,3))
	seed_pot(Vector3(4,0,5))
	world.player.position=Vector3(0,.2,6)
	world.tell("Navi", "Follow the fallen branch up to the chest. Look for the eye above the exit.")

func make_eye(id:String, at:Vector3) -> void:
	var body=Area3D.new()
	body.position=at
	body.collision_layer=4
	body.collision_mask=0
	body.set_meta("eye_id",id)
	body.set_meta("animated",true)
	scene.add_child(body)
	var shape=CollisionShape3D.new()
	var sphere=SphereShape3D.new()
	sphere.radius=.62
	shape.shape=sphere
	body.add_child(shape)
	Art.ellipsoid(body,Vector3.ZERO,Vector3(.7,.42,.17),Color("9e8052"))
	Art.ellipsoid(body,Vector3(0,0,-.16),Vector3(.25,.31,.06),Color("d6a950"))
	eye_nodes[id]=body

func hit_eye(id:String) -> void:
	if id=="ladder":
		world.state.ladder_down=true
		world.stats.eye_hits+=1
		world.tell("Navi", "The eye closed. The vines at the doorway have loosened!")
		if eye_nodes.has(id): eye_nodes[id].scale.y=.15

func basement() -> void:
	shell(12,7)
	flame(torch_position)
	Art.cylinder(scene,Vector3(5,.025,0),3,3,.05,Color("395f5b"),24)
	for i in range(5): Art.box(scene,Vector3(5,.08,-3+i*1.35),Vector3(1,.16,1),Color("877d5f"),true)
	if not world.state.web_burned: web=make_web(web_door_position+Vector3.UP*1.5,1.7,true)
	door("room:scrubs",web_door_position,"Pass through the web")
	world.interactions.append({"id":"light_stick","position":[-7,0,4],"label":"Light a Deku Stick · 12 seconds"})
	world.interactions.append({"id":"room:lobby","position":[0,0,9.5],"label":"Climb back to the hollow"})
	for i in range(3): Art.beam(scene,Vector3(-6.5+i*.12,.12,3),Vector3(-6.6+i*.12,.12,4),.04,Color("a0814d"))
	world.spawn_creature("baba",Vector3(-3,0,-2),"basement_baba")
	seed_pot(Vector3(-5,0,6))
	world.tell("Navi", "A dry web blocks the next door. Carry fire from the torch before your stick burns out.")

func scrubs() -> void:
	shell(11,7)
	scrub_order=[]
	for i in range(3):
		var scrub=world.spawn_creature("scrub",Vector3(-4+i*4,0,-3),"scrub_"+str(i+1))
		scrub.surrendered=world.state.scrubs_solved
	door("room:gohma",Vector3(0,0,-9),"Open the sealed door")
	door("room:basement",Vector3(0,0,9),"Return to the roots")
	flame(Vector3(-8,0,4))
	flame(Vector3(8,0,4))
	world.tell("Navi", "Their nuts rebound from your shield. Listen to the brothers: the middle one first, then the right, then the left.")

func scrub_surrendered(enemy:Node3D) -> void:
	for item in world.interactions:
		if item.id==enemy.enemy_id: return
	world.interactions.append({"id":enemy.enemy_id,"position":[enemy.position.x,0,enemy.position.z],"label":"Talk to the Deku Scrub"})

func speak_scrub(id:String) -> void:
	var number=int(id.trim_prefix("scrub_"))
	if number in scrub_order: return
	scrub_order.append(number)
	var expected=[2,3,1]
	if scrub_order.back()!=expected[scrub_order.size()-1]:
		scrub_order=[]
		for enemy in world.creatures:
			if is_instance_valid(enemy) and enemy.kind=="scrub": enemy.reset_scrub()
		world.interactions=world.interactions.filter(func(item): return not str(item.id).begins_with("scrub_"))
		world.tell("Deku Scrub", "That's the wrong order! Remember: two, three, one.")
	elif scrub_order.size()==3:
		world.state.scrubs_solved=true
		world.tell("Deku Scrub", "You got us! The queen's eye turns red before she strikes. Stun it, then use your sword.")
	else: world.tell("Deku Scrub", "All right, all right! Now talk to brother "+str(expected[scrub_order.size()])+".")

func boss() -> void:
	shell(15,10)
	for at in [Vector3(-10,0,-7),Vector3(10,0,-7),Vector3(-10,0,7),Vector3(10,0,7)]: flame(at)
	seed_pot(Vector3(6,0,9))
	for i in range(6):
		var a=i*TAU/6
		Art.ellipsoid(scene,Vector3(sin(a)*13,.3,cos(a)*13),Vector3(1.5,.5,1),Color("697055"))
	if not world.state.gohma:
		world.spawn_creature("gohma",Vector3(0,0,-4),"gohma")
		world.tell("PARASITIC ARMORED ARACHNID · GOHMA", "Q focuses a target. R fires a seed. Wait for the red eye, stun her, then close in with F. Guard or roll away from her lunge.")
	else: rewards()

func rewards() -> void:
	var portal=Node3D.new()
	portal.set_meta("animated",true)
	portal.position=Vector3(0,.05,-4)
	scene.add_child(portal)
	Art.cylinder(portal,Vector3.ZERO,1.2,1.2,.08,Color("679597"),32)
	for i in range(8): Art.ellipsoid(portal,Vector3(sin(i)*.85,.25,cos(i)*.85),Vector3(.09,.12,.09),Color("b6dfbd"))
	world.interactions.append({"id":"deku_complete","position":[0,0,-4],"label":"Take the Kokiri Emerald and return"})
	world.tell("Navi", "The curse has lifted. Take the light back to the Great Deku Tree.")

func tick(_delta:float) -> void:
	if room=="lobby":
		if not world.state.web_broken and world.player.position.y<.5 and Vector2(world.player.position.x,world.player.position.z).length()<3.25 and world.player.fall_speed < -10:
			world.state.web_broken=true
			world.stats.web_breaks+=1
			if is_instance_valid(web):
				web.hide()
				for col in web.find_children("*","CollisionShape3D",true,false): col.set_deferred("disabled",true)
		if world.player.position.y < -2:
			enter("basement")
	elif room=="basement" and world.torch_time>0 and Vector2(world.player.position.x-5,world.player.position.z).length()<3 and world.player.position.y<.1:
		world.torch_time=0
		world.tell("Navi", "The water put the flame out. Relight your stick and keep to the dry roots.")
	elif room=="basement" and world.torch_time>0 and world.player.position.distance_to(web_door_position)<2:
		world.state.web_burned=true
		world.torch_time=0
		if is_instance_valid(web): web.hide()
		world.tell("Navi", "The web burned away. The passage is open.")

func can_enter(next:String) -> bool:
	if next=="gohma" and not world.state.slingshot:
		world.tell("Navi", "You need the slingshot from the hollow before facing the queen. Return upstairs through the roots.")
		return false
	if room=="slingshot" and next=="lobby" and world.state.slingshot and not world.state.ladder_down:
		world.tell("Navi", "The doorway is tangled shut. Use Q to aim at the eye, then R to fire a seed.")
		return false
	if next=="scrubs" and not world.state.web_burned:
		world.tell("Navi", "The dry web needs fire. Light a stick at the torch.")
		return false
	if next=="gohma" and not world.state.scrubs_solved:
		world.tell("Navi", "The three brothers still guard this door.")
		return false
	return true

func objective() -> String:
	match room:
		"lobby": return "DEKU TREE · Find the slingshot, climb the vines, break the central web"
		"slingshot": return "DEKU TREE · Open the chest; shoot the eye above the exit"
		"basement": return "DEKU TREE · Carry fire to the web-covered passage"
		"scrubs": return "DEKU TREE · Reflect their nuts, then speak in order: 2 → 3 → 1"
		"gohma": return "GOHMA · Stun the red eye; strike while the queen is down" if not world.state.gohma else "DEKU TREE · Take the Kokiri Emerald"
	return "DEKU TREE"
