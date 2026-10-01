extends RefCounted
const Art=preload("res://scripts/art.gd")
const Stone=preload("res://scripts/natural_art.gd")
const G=preload("res://scripts/grave_art.gd")
static var materials:Dictionary={}

static func basalt() -> StandardMaterial3D:
	if not materials.has("basalt"):
		var mat=StandardMaterial3D.new()
		mat.albedo_texture=load("res://assets/fire/crust_diff.png")
		mat.normal_enabled=true;mat.normal_texture=load("res://assets/fire/crust_normal.png")
		mat.albedo_color=Color("c4c0b8")
		mat.roughness=.88;mat.normal_scale=.28
		mat.uv1_triplanar=true;mat.uv1_world_triplanar=true;mat.uv1_scale=Vector3.ONE*.18
		mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		materials.basalt=mat
	return materials.basalt

static func masonry() -> StandardMaterial3D:
	if not materials.has("masonry"):
		var mat=Stone.stone().duplicate()
		var base="res://assets/natural/volcanic_rock_tiles/"
		mat.albedo_texture=load(base+"diff.jpg");mat.normal_texture=load(base+"nor_gl.jpg")
		mat.ao_texture=load(base+"arm.jpg");mat.roughness_texture=mat.ao_texture
		mat.uv1_scale=Vector3.ONE/1.8;mat.normal_scale=.75
		materials.masonry=mat
	return materials.masonry

static func block(parent:Node3D,at:Vector3,size:Vector3,solid:bool=true) -> MeshInstance3D:
	var node=Stone.block(parent,at,size,false,false)
	node.material_override=masonry()
	var collider=Art.collision_box(node,Vector3.ZERO,size)
	# Decorative portal lintels must still shorten the camera boom.
	collider.collision_layer=9 if solid else 8
	return node

static func platform(parent:Node3D,at:Vector3,size:Vector2,depth:float=1.5) -> void:
	block(parent,at-Vector3.UP*depth*.5,Vector3(size.x,depth,size.y))
	# Wide bedding slabs establish an edge; individual joints and worn bevels catch light.
	for side in [-1,1]:
		for i in range(maxi(1,int(size.y/1.5))):
			block(parent,at+Vector3(side*(size.x*.5-.15),-.12,-size.y*.5+.7+i*1.5),Vector3(.3,.24,1.47),false)

static func portal(parent:Node3D,at:Vector3,yaw:float=0) -> void:
	var root=Node3D.new();root.position=at;root.rotation.y=yaw;parent.add_child(root)
	for side in [-1,1]:
		for y in range(6): block(root,Vector3(side*1.8,y*.57+.28,0),Vector3(.8,.55,1.2),false)
		G.lantern(root,Vector3(side*2.5,2.2,.75),.8,Color("ffd1a0"))
	block(root,Vector3(0,3.6,0),Vector3(4.5,.65,1.4),false)
	for x in [-.8,0,.8]:
		var bolt=Art.cylinder(root,Vector3(x,3.6,.73),.12,.12,.05,Color("a77835"),48)
		bolt.rotation.x=PI/2

static func cage(parent:Node3D,at:Vector3) -> Node3D:
	var root=Node3D.new();root.position=at;root.set_meta("animated",true);parent.add_child(root)
	var bars=AnimatableBody3D.new();bars.name="Bars";bars.collision_layer=9;root.add_child(bars)
	for x in range(-4,5):
		var bar=G.rod(bars,Vector3(x*.42,0,0),Vector3(x*.42,3.3,0),.045,Color("423b35"))
		bar.material_override=Art.material(Color("423b35"),.52,.85)
	for y in [.25,1.7,3.15]:
		var rail=G.rod(bars,Vector3(-1.85,y,0),Vector3(1.85,y,0),.075,Color("594735"))
		rail.material_override=Art.material(Color("594735"),.46,.8)
	var collider=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(3.8,3.2,.25)
	collider.shape=shape;collider.position.y=1.6;bars.add_child(collider)
	block(parent,at+Vector3(0,3.5,0),Vector3(4.5,.5,1),false)
	for side in [-1,1]:
		block(parent,at+Vector3(side*2.15,3.3,0),Vector3(.5,6.6,1))
		G.rod(parent,at+Vector3(side*1.89,0,.12),at+Vector3(side*1.89,6.6,.12),.06,Color("413a32"))
		for y in [.4,2.8,5.7]: G.sphere(parent,at+Vector3(side*2, y,.51),Vector3(.08,.08,.04),Color("75604b"),.8)
	return root

static func button(parent:Node3D,at:Vector3,pressed:bool=false) -> Node3D:
	var root=Node3D.new();root.position=at;root.set_meta("animated",true);parent.add_child(root)
	block(root,Vector3(0,.07,0),Vector3(1.3,.14,1.3),false)
	var plate=Art.cylinder(root,Vector3(0,.16 if not pressed else .07,0),.49,.49,.13,Color("b28540"),80)
	plate.name="Plate";plate.material_override=Art.material(Color("ae8548"),.42,.8)
	for i in range(4): G.sphere(root,Vector3(sin(i*TAU/4)*.40,.25,cos(i*TAU/4)*.40),Vector3(.035,.02,.035),Color("d1b874"),1)
	return root

static func lava(world:Node3D,size:Vector2,y:float=-1) -> ShaderMaterial:
	var node=MeshInstance3D.new();var mesh=PlaneMesh.new();mesh.size=size;mesh.subdivide_width=64;mesh.subdivide_depth=64
	node.mesh=mesh;node.position.y=y;node.set_meta("animated",true)
	var mat=ShaderMaterial.new();mat.shader=preload("res://shaders/lava.gdshader")
	for pair in [["crust","diff"],["relief","normal"],["heat","heat"],["roughness_map","rough"]]: mat.set_shader_parameter(pair[0],load("res://assets/fire/crust_"+pair[1]+".png"))
	node.material_override=mat;world.landscape.add_child(node)
	for x in [-size.x*.27,size.x*.27]:
		for z in [-size.y*.25,size.y*.25]:
			var light=OmniLight3D.new();light.position=Vector3(x,y+.3,z);light.light_color=Color("ff7e36");light.light_energy=.75;light.omni_range=18;world.landscape.add_child(light)
	return mat

static func atmosphere(world:Node3D,crater:bool=false) -> void:
	world.set_ambience(true)
	var env=world.world_environment.environment
	env.ambient_light_color=Color("acb5c6");env.ambient_light_energy=.50 if crater else .32
	env.fog_density=.0025;env.fog_light_color=Color("5b4840")
	env.ssao_enabled=RenderingServer.get_current_rendering_method()!="gl_compatibility"
	world.sunlight.light_energy=.85 if crater else .025
	world.sunlight.light_color=Color("cfdaed")
	var sky=env.sky.sky_material
	sky.sky_top_color=Color("303a4b");sky.sky_horizon_color=Color("716c69");sky.ground_horizon_color=Color("504b49")

static func crater_walls(parent:Node3D) -> void:
	# A continuous open caldera, widening at the rim. No ceiling or masonry shell.
	var vertices=PackedVector3Array();var uv=PackedVector2Array();var indices=PackedInt32Array()
	var segments=256;var rows=48
	for row in range(rows+1):
		var t=float(row)/rows
		for i in range(segments+1):
			var a=float(i)/segments*TAU
			var radius=30+10*t+sin(a*5+t*4)*1.4+cos(a*13-t*8)*.6+sin(a*37+t*17)*.25
			var y=-6+t*(33+sin(a*7)*3+sin(a*3)*2)
			vertices.append(Vector3(sin(a)*radius,y,cos(a)*radius*1.12));uv.append(Vector2(a*8,t*7))
	for row in range(rows):
		for i in range(segments):
			var k=row*(segments+1)+i
			for index in [k,k+1,k+segments+1,k+1,k+segments+2,k+segments+1]: indices.append(index)
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var surface=SurfaceTool.new();surface.create_from(mesh,0);surface.generate_normals();surface.generate_tangents()
	var wall=MeshInstance3D.new();wall.mesh=surface.commit();wall.material_override=basalt();parent.add_child(wall)
	for side in [-1,1]:
		Art.collision_box(parent,Vector3(side*28,8,0),Vector3(1,30,60))
		Art.collision_box(parent,Vector3(0,8,side*31),Vector3(56,30,1))

static func chamber(world:Node3D,size:Vector2,lava_floor:bool=false) -> void:
	if not lava_floor: platform(world.landscape,Vector3.ZERO,size,.6)
	for side in [-1,1]:
		block(world.landscape,Vector3(side*size.x*.5,3,0),Vector3(1,10,size.y+1))
		block(world.landscape,Vector3(0,3,side*size.y*.5),Vector3(size.x+1,10,1))
		for z in range(-int(size.y*.5)+4,int(size.y*.5),7):
			block(world.landscape,Vector3(side*(size.x*.5-.8),3.5,z),Vector3(1.2,7,1.4))
			G.lantern(world.landscape,Vector3(side*(size.x*.5-1.5),2.7,z),.9)
	block(world.landscape,Vector3(0,8.25,0),Vector3(size.x+1,.5,size.y+1))
	atmosphere(world)

static func goron(parent:Node3D,at:Vector3,scale_factor:float=1.0) -> Node3D:
	var root=Node3D.new();root.position=at;root.scale=Vector3.ONE*scale_factor;root.set_meta("animated",true);parent.add_child(root)
	var model=load("res://assets/fire/goron.glb").instantiate();root.add_child(model)
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var material=mesh.mesh.surface_get_material(i)
			if material is StandardMaterial3D and material.resource_name=="Ochre mineral skin":
				var skin=material.duplicate();skin.vertex_color_use_as_albedo=true;skin.vertex_color_is_srgb=false
				mesh.set_surface_override_material(i,skin)
	# Blender -Y exports as Godot +Z, toward the approaching player.
	model.rotation.y=0
	Art.collision_box(root,Vector3(0,1.05,0),Vector3(1.7,2.1,1))
	return root
