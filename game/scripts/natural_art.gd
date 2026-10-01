extends RefCounted

const Art=preload("res://scripts/art.gd")
static var surfaces:Dictionary={}
static var blocks:Dictionary={}
static var rock_scene:PackedScene

static func stone(floor_surface:bool=false) -> StandardMaterial3D:
	var slug="slab_tiles" if floor_surface else "medieval_blocks_05"
	if surfaces.has(slug): return surfaces[slug]
	var material=StandardMaterial3D.new()
	var base="res://assets/natural/"+slug+"/"
	material.albedo_texture=load(base+"diff.jpg")
	material.normal_enabled=true
	material.normal_texture=load(base+"nor_gl.jpg")
	material.normal_scale=.7
	material.ao_enabled=true
	material.ao_texture=load(base+"arm.jpg")
	material.ao_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness_texture=material.ao_texture
	material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic=0
	material.uv1_triplanar=true
	material.uv1_world_triplanar=true
	material.uv1_scale=Vector3.ONE*(.30 if floor_surface else .36)
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	surfaces[slug]=material
	return material

static func block(parent:Node3D, at:Vector3, size:Vector3, floor_surface:bool=false, solid:bool=false) -> MeshInstance3D:
	var key=str(size)
	if not blocks.has(key):
		var half=size*.5
		var bevel=minf(.10,minf(size.x,minf(size.y,size.z))*.23)
		var inner=half-Vector3.ONE*bevel
		var surface=SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for axis in range(3):
			var u=(axis+1)%3
			var v=(axis+2)%3
			var us=[-half[u],-inner[u]-bevel*.7,-inner[u]-bevel*.3,-inner[u],inner[u],inner[u]+bevel*.3,inner[u]+bevel*.7,half[u]]
			var vs=[-half[v],-inner[v]-bevel*.7,-inner[v]-bevel*.3,-inner[v],inner[v],inner[v]+bevel*.3,inner[v]+bevel*.7,half[v]]
			for side in [-1,1]:
				for i in range(us.size()-1):
					for j in range(vs.size()-1):
						var points=[]
						for uv in [Vector2(us[i],vs[j]),Vector2(us[i+1],vs[j]),Vector2(us[i+1],vs[j+1]),Vector2(us[i],vs[j+1])]:
							var point=Vector3.ZERO
							point[axis]=side*half[axis]
							point[u]=uv.x
							point[v]=uv.y
							var center=point.clamp(-inner,inner)
							var normal=(point-center).normalized()
							points.append({"point":center+normal*bevel,"normal":normal})
						for index in ([0,2,1,0,3,2] if side>0 else [0,1,2,0,2,3]):
							surface.set_normal(points[index].normal)
							surface.add_vertex(points[index].point)
		blocks[key]=surface.commit()
	var mesh=MeshInstance3D.new()
	mesh.mesh=blocks[key]
	mesh.material_override=stone(floor_surface)
	mesh.position=at
	parent.add_child(mesh)
	if solid: Art.collision_box(parent,at,size)
	return mesh

static func cave(parent:Node3D, radius:Vector2) -> void:
	if rock_scene==null: rock_scene=load("res://assets/natural/rock_face_01/rock_face_01.gltf")
	# A continuous bedrock shell closes gaps behind the irregular scanned faces.
	var shell=CylinderMesh.new()
	shell.top_radius=1
	shell.bottom_radius=1
	shell.height=28
	shell.radial_segments=120
	shell.rings=24
	shell.cap_top=true
	shell.cap_bottom=false
	var arrays=shell.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	for i in range(vertices.size()):
		var a=atan2(vertices[i].x,vertices[i].z)
		var offset=1+.018*sin(a*7+vertices[i].y*.5)+.012*cos(a*13-vertices[i].y*.9)
		vertices[i].x*=radius.x*offset+9
		vertices[i].z*=radius.y*offset+9
		normals[i]=-normals[i]
	for i in range(0,indices.size(),3):
		var first=indices[i]
		indices[i]=indices[i+2]
		indices[i+2]=first
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_INDEX]=indices
	var surface=ArrayMesh.new()
	surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var wall=MeshInstance3D.new()
	wall.mesh=surface
	wall.material_override=stone().duplicate()
	wall.material_override.albedo_color=Color("7c817b")
	wall.position.y=8.0
	parent.add_child(wall)
	for row in range(-1,4):
		for i in range(30):
			var angle=(i+(row%2)*.42)*TAU/30
			var root=rock_scene.instantiate()
			root.position=Vector3(sin(angle)*(radius.x+2),row*3.0-1,cos(angle)*(radius.y+2))
			root.rotation.y=angle+PI+sin(i*2.4+row)*.08
			root.scale=Vector3.ONE*(1.55+sin(i*2.1+row)*.07)
			parent.add_child(root)
	for side in [-1,1]:
		block(parent,Vector3(side*(radius.x+4),-3.4,0),Vector3(14,5,radius.y*2+20))
		block(parent,Vector3(0,-3.4,side*(radius.y+4)),Vector3(radius.x*2+20,5,14))
		Art.collision_box(parent,Vector3(side*(radius.x-2),3,0),Vector3(1,20,radius.y*2))
		Art.collision_box(parent,Vector3(0,3,side*(radius.y-2)),Vector3(radius.x*2,20,1))

static func cavern_roof(parent:Node3D) -> void:
	# The same stratified bedrock turns over the chamber. Overlapping scanned
	# sections join the walls; the continuous shell behind them seals the volume.
	for row in range(12):
		for col in range(11):
			var x=-31.0+col*6.1+(row%2)*1.8
			var z=-37.0+row*6.0
			var root=rock_scene.instantiate()
			root.position=Vector3(x,12.8+2.8*maxf(0,1-pow(x/35.0,2))+.28*sin(row*.7+col),z)
			root.rotation=Vector3(PI*.5,.10*sin(row*1.8+col*.6),.025*sin(col*1.3))
			root.scale=Vector3(1.8+sin(row+col)*.12,1.85,1.65)
			parent.add_child(root)
	Art.collision_box(parent,Vector3(0,14.0,0),Vector3(72,1,84)).collision_layer=8

static func lamp(parent:Node3D, at:Vector3, facing:float=0) -> void:
	var holder=Node3D.new()
	holder.position=at
	holder.rotation.y=facing
	parent.add_child(holder)
	var bronze=StandardMaterial3D.new()
	bronze.albedo_color=Color("806441")
	bronze.metallic=.72
	bronze.roughness=.38
	var bracket=block(holder,Vector3(0,0,.04),Vector3(.20,.44,.12))
	bracket.material_override=bronze
	var arm=Art.cylinder(holder,Vector3(0,-.07,.33),.036,.036,.6,Color.WHITE,48)
	arm.rotation.x=PI*.5
	arm.material_override=bronze
	for y in [-.18,.23]:
		var rim=Art.cylinder(holder,Vector3(0,y,.63),.19,.16,.065,Color.WHITE,64)
		rim.material_override=bronze
	for i in range(6):
		var a=i*TAU/6
		var bar=Art.cylinder(holder,Vector3(sin(a)*.16,.02,.63+cos(a)*.16),.012,.012,.4,Color.WHITE,24)
		bar.material_override=bronze
	var shade=Art.cylinder(holder,Vector3(0,.025,.63),.137,.137,.34,Color.WHITE,64)
	var glass=StandardMaterial3D.new()
	glass.albedo_color=Color("eadbbd")
	glass.emission_enabled=true
	glass.emission=Color("f9da9c")
	glass.emission_energy_multiplier=2.1
	glass.roughness=.3
	shade.material_override=glass
	var light=OmniLight3D.new()
	light.position=Vector3(0,.03,.80)
	light.light_color=Color("f8dcac")
	light.omni_range=19
	light.light_energy=3.8
	light.shadow_enabled=true
	light.omni_shadow_mode=OmniLight3D.SHADOW_CUBE
	holder.add_child(light)

static func column(parent:Node3D, at:Vector3, height:float=8) -> void:
	# Turned bases, tapered drums and a spreading capital carry the vault ribs.
	var profile=[Vector2(.84,0),Vector2(.88,.04),Vector2(.88,.13),Vector2(.84,.18),Vector2(.72,.20),Vector2(.70,.25),Vector2(.70,.36),Vector2(.66,.42),Vector2(.58,.48),Vector2(.54,.55),Vector2(.53,.68),Vector2(.50,height-.9),Vector2(.54,height-.80),Vector2(.60,height-.72),Vector2(.64,height-.61),Vector2(.76,height-.48),Vector2(.83,height-.34),Vector2(.83,height-.27),Vector2(.96,height-.20),Vector2(.96,height-.06),Vector2(.9,height)]
	var tool=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(profile.size()-1):
		for segment in range(96):
			var a=segment*TAU/96
			var b=(segment+1)*TAU/96
			var points=[]
			for item in [Vector2(a,ring),Vector2(b,ring),Vector2(b,ring+1),Vector2(a,ring+1)]:
				var r=profile[int(item.y)]
				points.append(Vector3(sin(item.x)*r.x,r.y,cos(item.x)*r.x))
			for i in [0,2,1,0,3,2]: tool.add_vertex(points[i])
	tool.generate_normals()
	var mesh=MeshInstance3D.new()
	mesh.mesh=tool.commit()
	mesh.material_override=stone()
	mesh.position=at
	parent.add_child(mesh)
	Art.collision_box(parent,at+Vector3.UP*height*.5,Vector3(1.1,height,1.1))
	block(parent,at+Vector3.UP*.07,Vector3(1.95,.14,1.95))
	block(parent,at+Vector3.UP*(height-.03),Vector3(2,.18,1.5))

static func vault_rib(parent:Node3D, z:float) -> void:
	for i in range(40):
		var a=i*PI/40
		var b=(i+1)*PI/40
		var start=Vector3(cos(a)*19,7.9+sin(a)*4.6,z)
		var end=Vector3(cos(b)*19,7.9+sin(b)*4.6,z)
		var stone_block=block(parent,(start+end)*.5,Vector3(start.distance_to(end)+.016,.50,.82))
		stone_block.rotation.z=atan2(end.y-start.y,end.x-start.x)

static func pool_edge(parent:Node3D) -> void:
	# Overhanging coping has visible rounded thickness and a dark wet course below.
	for side in [-1,1]:
		for i in range(20):
			var z=-3.5+i
			# Leave both swimming ramps flush with the walkable bank.
			if z>8 and z<12: continue
			block(parent,Vector3(side*9.04,-.035,z),Vector3(.48,.20,.976),true)
		for i in range(18):
			block(parent,Vector3(-8.5+i,-.035,6+side*10),Vector3(.976,.20,.48),true)

static func release_resources() -> void:
	surfaces.clear()
	blocks.clear()
	rock_scene=null
