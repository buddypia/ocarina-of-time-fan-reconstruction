extends RefCounted

const Art=preload("res://scripts/art.gd")
const Stone=preload("res://scripts/natural_art.gd")
const Temple=preload("res://scripts/time_temple_art.gd")
const G=preload("res://scripts/grave_art.gd")
static var materials:Dictionary={}

static func masonry() -> StandardMaterial3D:
	if not materials.has("stone"):
		var mat=Temple.stone("limestone").duplicate()
		mat.albedo_color=Color("b3b0a1")
		mat.normal_scale=.75
		mat.uv1_world_triplanar=false
		materials.stone=mat
	return materials.stone

static func block(parent:Node3D,at:Vector3,size:Vector3,solid:bool=false) -> MeshInstance3D:
	var mesh=Stone.block(parent,at,size,false,false)
	if solid: Art.collision_box(mesh,Vector3.ZERO,size)
	mesh.material_override=masonry()
	return mesh

static func column(parent:Node3D,at:Vector3,height:float=5) -> void:
	# Clustered shafts have a shared load-bearing pier, stepped bases and capitals.
	block(parent,at+Vector3.UP*.16,Vector3(1.4,.32,1.4),true)
	block(parent,at+Vector3.UP*.39,Vector3(1.1,.16,1.1))
	for offset in [Vector3.ZERO,Vector3(.35,0,0),Vector3(-.35,0,0),Vector3(0,0,.35),Vector3(0,0,-.35)]:
		var radius=.30 if offset==Vector3.ZERO else .17
		var shaft=Art.cylinder(parent,at+offset+Vector3.UP*(height*.5+.35),radius,radius*.94,height-.7,Color.WHITE,80)
		shaft.material_override=masonry()
		for y in [.5,height-.20]:
			var collar=Art.cylinder(parent,at+offset+Vector3.UP*y,radius*1.23,radius*1.23,.10,Color.WHITE,80)
			collar.material_override=masonry()
	block(parent,at+Vector3.UP*height,Vector3(1.15,.25,1.15))
	Art.collision_box(parent,at+Vector3.UP*(height*.5),Vector3(1.03,height,1.03))

static func arch(parent:Node3D,at:Vector3,width:float=2.5,rise:float=2.9,depth:float=.75) -> void:
	# Two orders of dressed voussoirs surround the opening, following a pointed arch.
	for order in range(2):
		var radius=width+order*.19
		for side in [-1,1]:
			for i in range(32):
				var t=float(i)/32
				var u=float(i+1)/32
				var a=Vector3(side*radius*(1-t),rise*sqrt(1-pow(1-t*.5,2))/sqrt(.75),0)
				var b=Vector3(side*radius*(1-u),rise*sqrt(1-pow(1-u*.5,2))/sqrt(.75),0)
				var stone=block(parent,at+(a+b)*.5+Vector3(0,order*.12,order*.10),Vector3(a.distance_to(b)+.005,.23,depth-order*.12))
				stone.rotation.z=atan2(b.y-a.y,b.x-a.x)

static func chamber(world:Node3D,size:Vector2,open_sky:bool=false) -> void:
	var parent=world.landscape
	var floor=Stone.block(parent,Vector3(0,-.25,0),Vector3(size.x,.5,size.y),true,true)
	floor.material_override=Temple.stone("floor")
	for side in [-1,1]:
		var wall=Stone.block(parent,Vector3(side*size.x*.5,4,0),Vector3(.8,8,size.y),false,true)
		wall.material_override=Temple.stone("wall")
		wall=Stone.block(parent,Vector3(0,4,side*size.y*.5),Vector3(size.x,8,.8),false,true)
		wall.material_override=Temple.stone("wall")
		for z in range(-int(size.y*.5)+4,int(size.y*.5)-2,6):
			column(parent,Vector3(side*(size.x*.5-1),0,z),5)
			G.lantern(parent,Vector3(side*(size.x*.5-1.6),2.7,z),.70)
	if not open_sky:
		block(parent,Vector3(0,8.25,0),Vector3(size.x,.5,size.y),true)
		for z in range(-int(size.y*.5)+4,int(size.y*.5)-2,6): arch(parent,Vector3(0,5.12,z),size.x*.5-1,2.7,.40)
		# A suspended iron lantern ring provides motivated light at the room's center.
		G.rod(parent,Vector3(0,8,0),Vector3(0,6.3,0),.035,Color("413e33"))
		var ring=MeshInstance3D.new();var torus=TorusMesh.new()
		torus.inner_radius=.96;torus.outer_radius=1.04;torus.rings=64;torus.ring_segments=16
		ring.mesh=torus;ring.position=Vector3(0,5.7,0);ring.material_override=Art.material(Color("494333"),.55,.75);parent.add_child(ring)
		for i in range(4):
			var at=Vector3(sin(i*TAU/4),5.94,cos(i*TAU/4))
			G.rod(parent,Vector3(0,6.3,0),at-Vector3.UP*.24,.015,Color("514a38"))
			G.lantern(parent,at,.35)
		var lamp=SpotLight3D.new();parent.add_child(lamp)
		lamp.position=Vector3(0,5.65,0);lamp.rotation.x=-PI/2
		lamp.light_color=Color("ffe1b4");lamp.light_energy=2.6;lamp.spot_range=18;lamp.spot_angle=65;lamp.shadow_enabled=true
	else:
		for side in [-1,1]:
			for z in [-6,0,6]:
				var bay=Node3D.new()
				bay.position=Vector3(side*(size.x*.5-5),0,z)
				bay.rotation.y=PI/2
				parent.add_child(bay)
				for x in [-3,3]: column(bay,Vector3(x,0,0),3.8)
				arch(bay,Vector3(0,3.92,0),3,2.5,.65)
				block(bay,Vector3(0,6.75,0),Vector3(6.9,.28,1.2))
		var soil=G.earth()
		Art.box(parent,Vector3(0,.012,0),Vector3(size.x-13,.024,size.y-9),Color.WHITE).material_override=soil
		for x in [-4,4]: tree(parent,Vector3(x,0,-4),.9,34+int(x))
	world.set_ambience(not open_sky)
	var env=world.world_environment.environment
	env.ambient_light_color=Color("d5dcdf")
	env.ambient_light_energy=.47 if open_sky else .20
	env.fog_density=.0015
	env.fog_light_color=Color("697979")
	env.ssao_enabled=RenderingServer.get_current_rendering_method()!="gl_compatibility"
	env.ssao_intensity=1.0
	world.sunlight.light_color=Color("f4ead7")
	world.sunlight.light_energy=.55 if open_sky else .04
	var sky=env.sky.sky_material
	sky.sky_top_color=Color("60849a")
	sky.sky_horizon_color=Color("c4cfca")
	sky.ground_horizon_color=Color("667467")

static func portal(parent:Node3D,at:Vector3,facing:float=0) -> Node3D:
	var root=Node3D.new()
	root.position=at
	root.rotation.y=facing
	parent.add_child(root)
	for side in [-1,1]:
		block(root,Vector3(side*1.4,1.5,0),Vector3(.40,3,.8))
		block(root,Vector3(side*1.4,.15,0),Vector3(.6,.3,1))
	arch(root,Vector3(0,3,0),1.4,1.0,.8)
	for x in range(9):
		var plank=block(root,Vector3(-1.10+x*.275,1.50,.04),Vector3(.263,2.92,.18))
		plank.material_override=Art.material(Color("474d3a"),.95)
	for y in [.6,2.4]: G.rod(root,Vector3(-1.15,y,.16),Vector3(1.15,y,.16),.04,Color("635840"))
	return root

static func tree(parent:Node3D,at:Vector3,scale_value:float,seed_value:int) -> void:
	var root=Node3D.new()
	root.position=at
	root.scale=Vector3.ONE*scale_value
	parent.add_child(root)
	var rng=RandomNumberGenerator.new()
	rng.seed=seed_value
	var bark=Art.material(Color("635340"),.96)
	if ResourceLoader.exists("res://assets/forest/bark_diff.png"):
		bark.albedo_texture=load("res://assets/forest/bark_diff.png")
		bark.albedo_color=Color.WHITE
		bark.normal_enabled=true
		bark.normal_texture=load("res://assets/forest/bark_nor_gl.png")
		bark.roughness_texture=load("res://assets/forest/bark_rough.png")
		bark.uv1_triplanar=true
		bark.uv1_scale=Vector3.ONE*.55
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(24):
		for segment in range(96):
			var points=[]
			for step in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var y=(row+step.y)/24.0*8
				var a=(segment+step.x)/96.0*TAU
				var radius=(.75-y*.06+exp(-y*1.8)*.6)*(1+.07*sin(a*7+y*.5))
				points.append(Vector3(cos(a)*radius+sin(y*.25)*.30,y,sin(a)*radius))
			for index in [0,1,2,0,2,3]: tool.add_vertex(points[index])
	tool.generate_normals()
	var trunk=MeshInstance3D.new()
	trunk.mesh=tool.commit()
	trunk.material_override=bark
	root.add_child(trunk)
	Art.collision_box(root,Vector3(0,3,0),Vector3(1.4,6,1.4))
	var tips=[]
	for i in range(9):
		var a=i*TAU/9+.3
		var tip=Vector3(cos(a)*rng.randf_range(3,5),rng.randf_range(6.5,9),sin(a)*rng.randf_range(3,5))
		var start=Vector3(.3,4.5+i*.24,0)
		var branch=G.rod(root,start,tip,.12 if i>4 else .19,Color("635340"))
		branch.material_override=bark
		tips.append(tip)
	var leaf=SurfaceTool.new()
	leaf.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var a=float(i)/12
		var b=float(i+1)/12
		for side in [-1,1]:
			for point in [Vector3(0,sin(a*PI)*.025,a*.28),Vector3(side*sin(a*PI)*.075,.01,a*.28),Vector3(side*sin(b*PI)*.075,.01,b*.28),Vector3(0,sin(a*PI)*.025,a*.28),Vector3(side*sin(b*PI)*.075,.01,b*.28),Vector3(0,sin(b*PI)*.025,b*.28)]: leaf.add_vertex(point)
	leaf.generate_normals()
	var material=Art.material(Color("466346"),.96)
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var mesh=leaf.commit()
	mesh.surface_set_material(0,material)
	var multi=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.use_colors=true
	multi.mesh=mesh
	multi.instance_count=1800
	for i in range(multi.instance_count):
		var center=tips[i%tips.size()]
		var p=center+Vector3(rng.randfn(0,1.25),rng.randfn(0,.65),rng.randfn(0,1.25))
		var basis=Basis.from_euler(Vector3(rng.randf()*2,rng.randf()*TAU,rng.randf()*2)).scaled(Vector3.ONE*rng.randf_range(.9,1.8))
		multi.set_instance_transform(i,Transform3D(basis,p))
		multi.set_instance_color(i,Color.WHITE.lerp(Color("869c65"),rng.randf()*.6))
	var leaves=MultiMeshInstance3D.new()
	leaves.multimesh=multi
	root.add_child(leaves)
