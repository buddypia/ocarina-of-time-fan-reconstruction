extends RefCounted

const Art=preload("res://scripts/art.gd")
const Stone=preload("res://scripts/natural_art.gd")

static var surfaces:Dictionary={}

static func stone(kind:String="limestone") -> StandardMaterial3D:
	if surfaces.has(kind): return surfaces[kind]
	var material=StandardMaterial3D.new()
	var base="res://assets/temple/"+kind
	material.albedo_texture=load(base+"_diff.png")
	material.normal_enabled=true
	material.normal_texture=load(base+"_nor_gl.png")
	material.normal_scale=.6
	material.roughness_texture=load(base+"_rough.png")
	material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness=1
	material.uv1_triplanar=true
	material.uv1_world_triplanar=true
	material.uv1_scale=Vector3.ONE*(.23 if kind=="wall" else .35)
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	surfaces[kind]=material
	return material

static func dressed(parent:Node3D, at:Vector3, size:Vector3, solid:bool=false) -> MeshInstance3D:
	var mesh=Stone.block(parent,at,size,true,solid)
	mesh.material_override=stone()
	return mesh

static func arch(parent:Node3D, at:Vector3, radius:float, rise:float, depth:float, width:float=.30) -> void:
	# Individually dressed voussoirs carry the arch into the abaci below.
	var count=48
	for i in range(count):
		var a=float(i)*PI/count
		var b=float(i+1)*PI/count
		var start=Vector3(cos(a)*radius,sin(a)*rise,0)
		var end=Vector3(cos(b)*radius,sin(b)*rise,0)
		var mesh=dressed(parent,at+(start+end)*.5,Vector3(start.distance_to(end)-.008,width,depth))
		mesh.rotation.z=atan2(end.y-start.y,end.x-start.x)

static func vault(parent:Node3D) -> void:
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in range(96):
		var a=float(segment)*PI/96
		var b=float(segment+1)*PI/96
		var points=[Vector3(cos(a)*6.25,7.35+sin(a)*3.4,-27),Vector3(cos(b)*6.25,7.35+sin(b)*3.4,-27),Vector3(cos(b)*6.25,7.35+sin(b)*3.4,21),Vector3(cos(a)*6.25,7.35+sin(a)*3.4,21)]
		for i in [0,1,2,0,2,3]:
			tool.set_normal(Vector3(-points[i].x/6.25,-(points[i].y-7.35)/3.4,0).normalized())
			tool.add_vertex(points[i])
	var mesh=MeshInstance3D.new()
	mesh.mesh=tool.commit()
	mesh.material_override=Stone.stone()
	parent.add_child(mesh)
	Art.collision_box(parent,Vector3(0,10.9,-3),Vector3(13,.3,48)).collision_layer=8

static func window_glass(index:int) -> StandardMaterial3D:
	var key="glass"+str(index)
	if surfaces.has(key): return surfaces[key]
	var glass=StandardMaterial3D.new()
	glass.albedo_color=Color("b1c0c4").lerp(Color("cfc9a1"),index/6.0)
	glass.roughness=.25
	glass.emission_enabled=true
	glass.emission=glass.albedo_color
	glass.emission_energy_multiplier=.9
	surfaces[key]=glass
	return glass

static func window(parent:Node3D, side:int, z:float) -> void:
	var root=Node3D.new()
	root.position=Vector3(side*9.82,4.1,z)
	root.rotation.y=-side*PI/2
	parent.add_child(root)
	for x in [-1.15,1.15]: dressed(root,Vector3(x,1.7,0),Vector3(.25,3.4,.48))
	arch(root,Vector3(0,3.4,0),1.15,1.4,.48,.26)
	dressed(root,Vector3(0,-.08,0),Vector3(2.65,.24,.72))
	# Thick lead cames divide pale glass into small, irregularly tinted lights.
	var lead=Art.material(Color("414541"),.42,.7)
	for col in range(6):
		for row in range(12):
			var x=-.99+col*.397
			var y=.16+row*.39
			if y>3.4 and pow(x/1.02,2)+pow((y-3.4)/1.32,2)>1: continue
			var pane=Art.box(root,Vector3(x,y,-.045),Vector3(.386,.378,.035),Color.WHITE)
			var glass=window_glass((col*3+row*2)%7)
			pane.material_override=glass
			for offset in [Vector3(.194,0,0),Vector3(0,.19,0)]:
				var bar=Art.box(root,Vector3(x,y,0)+offset,Vector3(.017,.39,.045) if offset.x>0 else Vector3(.40,.017,.045),Color.WHITE)
				bar.material_override=lead
	for x in [-.38,.38]: dressed(root,Vector3(x,1.7,.09),Vector3(.08,3.5,.18))
	var light=SpotLight3D.new()
	light.position=Vector3(side*9.1,7,z)
	parent.add_child(light)
	light.look_at(Vector3(-side*2.0,0,z+2.0))
	light.light_color=Color("dfe7ef")
	light.light_energy=2.3 if RenderingServer.get_current_rendering_method()=="gl_compatibility" else 7.5
	light.spot_range=25
	light.spot_angle=43
	light.spot_angle_attenuation=.35
	light.shadow_enabled=z==side*8
	light.shadow_bias=.15 if RenderingServer.get_current_rendering_method()=="gl_compatibility" else .025
	light.shadow_normal_bias=2.0 if RenderingServer.get_current_rendering_method()=="gl_compatibility" else 1.0

static func build(parent:Node3D) -> void:
	dressed(parent,Vector3(0,-.28,-3),Vector3(21,.56,50),true).material_override=stone("floor")
	for side in [-1,1]:
		Stone.block(parent,Vector3(side*10.3,2,-3),Vector3(.8,4,50),false,true)
		Stone.block(parent,Vector3(side*10.3,10,-3),Vector3(.8,2.4,50),false,true)
		Stone.block(parent,Vector3(side*10.3,6.4,-26.6),Vector3(.8,5.2,2.8),false,true)
		for z in [-24,-16,-8,0,8,16]:
			Stone.block(parent,Vector3(side*10.3,6.4,z+4),Vector3(.8,5.2,5.6),false,true)
			window(parent,side,z)
			var outer=Node3D.new()
			outer.position=Vector3(side*10.3,7.5,z)
			outer.rotation.y=-side*PI/2
			parent.add_child(outer)
			# Upper spandrels close the wall over the glazed arch.
			for i in range(12):
				var x=-1.15+i*.2
				var lower=1.4*sqrt(maxf(0,1-pow(x/1.15,2)))
				Stone.block(outer,Vector3(x,(lower+2.6)*.5,0),Vector3(.20,2.6-lower,.8))
		for y in [.24,3.8,7.42]: dressed(parent,Vector3(side*10,y,-3),Vector3(.4,.2,50))
		for z in [-28,-20,-12,-4,4,12,20]:
			var before=parent.get_child_count()
			Stone.column(parent,Vector3(side*6,0,z),7.4)
			for i in range(before,parent.get_child_count()):
				var item=parent.get_child(i)
				if item is MeshInstance3D: item.material_override=stone()
			if z<20:
				var arcade=Node3D.new()
				arcade.position=Vector3(side*6,4.5,z+4)
				arcade.rotation.y=PI/2
				parent.add_child(arcade)
				arch(arcade,Vector3.ZERO,4,2.4,.48,.36)
				Stone.block(parent,Vector3(side*6,8.9,z+4),Vector3(.65,3.0,8))
				# Lower aisles have their own structural roof.
				Stone.block(parent,Vector3(side*8.2,7.4,z+4),Vector3(4.4,.3,8))
		for z in [-15,1,17]: Stone.lamp(parent,Vector3(side*9.6,2.5,z),-side*PI/2)
	for z in [-20,-12,-4,4,12,20]:
		arch(parent,Vector3(0,7.3,z),6,3.3,.5,.33)
	vault(parent)
	for z in [-28,22]:
		Stone.block(parent,Vector3(0,6,z),Vector3(21,12,1),false,true)
	# Side panels isolate the sanctuary; the central sliding leaves are separate.
	for side in [-1,1]: Stone.block(parent,Vector3(side*6.8,3.4,-14),Vector3(7.6,6.8,1),false,true)
	Stone.block(parent,Vector3(0,7,-14),Vector3(7,2,1),false,true)
	arch(parent,Vector3(0,4.8,-13.35),3.15,1.6,.5,.4)
	# Long, worn floor inlays draw the eye toward the altar without obstructing movement.
	for side in [-1,1]:
		for z in range(-26,22,2):
			var band=dressed(parent,Vector3(side*2.25,.018,z),Vector3(.12,.025,1.985))
			band.material_override=Art.material(Color("8c7850"),.38,.48)

	for mesh in parent.find_children("*","MeshInstance3D",true,false):
		if mesh.material_override==Stone.stone(): mesh.material_override=stone("wall")
		elif mesh.material_override==Stone.stone(true): mesh.material_override=stone()
	for lamp in parent.find_children("*","OmniLight3D",true,false):
		lamp.shadow_enabled=false
		lamp.light_energy=.65
		lamp.omni_range=7

static func ocarina(parent:Node3D) -> Node3D:
	var root=Node3D.new()
	root.set_meta("animated",true)
	parent.add_child(root)
	var shape=SphereMesh.new()
	shape.radial_segments=64
	shape.rings=32
	shape.radius=1
	shape.height=2
	var ceramic=Art.material(Color("294980"),.22,.16)
	var body=Art.mesh(root,shape,Vector3.ZERO,Color.WHITE)
	body.scale=Vector3(.19,.10,.115)
	body.material_override=ceramic
	var mouth=Art.cylinder(root,Vector3(.19,.015,0),.055,.037,.19,Color.WHITE,64)
	mouth.rotation.z=-PI/2
	mouth.material_override=ceramic
	for i in range(5):
		var hole=Art.mesh(root,shape,Vector3(-.10+(i%3)*.075,.086,-.04+floori(i/3.0)*.075),Color("111e30"))
		hole.scale=Vector3(.014,.007,.014)
	return root
