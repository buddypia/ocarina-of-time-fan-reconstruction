extends RefCounted

const Art=preload("res://scripts/art.gd")
const Stone=preload("res://scripts/natural_art.gd")
const Temple=preload("res://scripts/time_temple_art.gd")

static func dressed(parent:Node3D,at:Vector3,size:Vector3,solid:bool=false) -> MeshInstance3D:
	var mesh=Stone.block(parent,at,size,false,solid)
	mesh.material_override=Temple.stone("limestone")
	return mesh

static func sphere(parent:Node3D,at:Vector3,size:Vector3,color:Color,metal:float=0) -> MeshInstance3D:
	var mesh=MeshInstance3D.new()
	var shape=SphereMesh.new()
	shape.radial_segments=64
	shape.rings=32
	shape.radius=1
	shape.height=2
	mesh.mesh=shape
	mesh.position=at
	mesh.scale=size
	mesh.material_override=Art.material(color,.65,metal)
	parent.add_child(mesh)
	return mesh

static func rod(parent:Node3D,a:Vector3,b:Vector3,r:float,color:Color) -> MeshInstance3D:
	var mesh=Art.cylinder(parent,(a+b)*.5,r,r,a.distance_to(b),color,32)
	mesh.basis=Basis(Quaternion(Vector3.UP,(b-a).normalized()))
	return mesh

static func grave(parent:Node3D,at:Vector3,variant:int=0) -> Node3D:
	var root=Node3D.new()
	root.position=at
	parent.add_child(root)
	var stone=load("res://assets/gravestone.glb").instantiate()
	stone.rotation.y=(posmod(variant,5)-2)*.018
	stone.scale=Vector3(1.0+(posmod(variant,3)-1)*.045,1.0+(posmod(variant,4)-2)*.055,1)
	root.add_child(stone)
	return root

static func earth() -> StandardMaterial3D:
	var material=StandardMaterial3D.new()
	material.albedo_texture=load("res://assets/natural/rocky_terrain_02/diff.jpg")
	material.normal_enabled=true
	material.normal_texture=load("res://assets/natural/rocky_terrain_02/nor_gl.jpg")
	material.normal_scale=.7
	material.roughness=1
	material.uv1_triplanar=true
	material.uv1_world_triplanar=true
	material.uv1_scale=Vector3.ONE*.35
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material

static func lantern(parent:Node3D,at:Vector3,energy:float=1.1,tint:Color=Color("ffd398")) -> Node3D:
	var root=Node3D.new()
	root.position=at
	parent.add_child(root)
	for y in [-.22,.22]:
		var cap=Art.cylinder(root,Vector3(0,y,0),.14,.14,.045,Color("39382f"),48)
		cap.material_override=Art.material(Color("39382f"),.4,.7)
	for x in [-.11,.11]:
		for z in [-.11,.11]: rod(root,Vector3(x,-.22,z),Vector3(x,.22,z),.009,Color("383a33"))
	var flame=sphere(root,Vector3.ZERO,Vector3(.04,.12,.04),tint)
	var mat=flame.material_override.duplicate()
	mat.emission_enabled=true
	mat.emission=tint
	flame.material_override=mat
	var light=OmniLight3D.new()
	light.light_color=tint
	light.light_energy=energy
	light.omni_range=8
	root.add_child(light)
	return root

static func room(parent:Node3D,size:Vector2) -> void:
	Stone.block(parent,Vector3(0,-.3,0),Vector3(size.x,.6,size.y),true,true)
	Stone.block(parent,Vector3(0,5.3,0),Vector3(size.x,.6,size.y),false,true)
	for side in [-1,1]:
		Stone.block(parent,Vector3(side*size.x*.5,2.5,0),Vector3(.65,5,size.y),false,true)
		Stone.block(parent,Vector3(0,2.5,side*size.y*.5),Vector3(size.x,5,.65),false,true)
	for z in range(-int(size.y*.5)+3,int(size.y*.5),7):
		for side in [-1,1]:
			dressed(parent,Vector3(side*(size.x*.5-.55),2.3,z),Vector3(.65,4.6,.9))
			lantern(parent,Vector3(side*(size.x*.5-1),2.4,z),.9)

static func corridor(parent:Node3D,route:Array) -> void:
	# Rasterize the union of six-metre passages, then merge boundary runs.
	# Interior junctions stay open while every outer corner has a physical wall.
	var cells:Dictionary={}
	for i in range(route.size()-1):
		var a=Vector3(route[i][0],0,route[i][2])
		var b=Vector3(route[i+1][0],0,route[i+1][2])
		var size=Vector3(absf(a.x-b.x)+6,.6,absf(a.z-b.z)+6)
		Stone.block(parent,(a+b)*.5+Vector3.DOWN*.3,size,true,true)
		Stone.block(parent,(a+b)*.5+Vector3.UP*4.6,size,false,true)
		for x in range(int(minf(a.x,b.x)/2)-1,int(maxf(a.x,b.x)/2)+2):
			for z in range(int(minf(a.z,b.z)/2)-1,int(maxf(a.z,b.z)/2)+2): cells[Vector2i(x,z)]=true
	var lines:Dictionary={}
	for cell in cells:
		for side in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if cells.has(cell+side): continue
			var axis=0 if side.x else 1
			var fixed=cell.x*2+side.x if axis==0 else cell.y*2+side.y
			var along=cell.y*2 if axis==0 else cell.x*2
			var key=Vector2i(axis,fixed)
			if not lines.has(key): lines[key]=[]
			lines[key].append(along)
	for key in lines:
		var runs=lines[key]
		runs.sort()
		var start=runs[0]
		var previous=start
		runs.append(runs[-1]+4)
		for coordinate in runs.slice(1):
			if coordinate>previous+2:
				var center=(start+previous)*.5
				var length=previous-start+2
				var at=Vector3(key.y,2.15,center) if key.x==0 else Vector3(center,2.15,key.y)
				var size=Vector3(.35,4.3,length) if key.x==0 else Vector3(length,4.3,.35)
				Stone.block(parent,at,size,false,true)
				start=coordinate
			previous=coordinate
	for i in range(0,route.size(),2): lantern(parent,Vector3(route[i][0]+2,2.6,route[i][2]),1.6)
