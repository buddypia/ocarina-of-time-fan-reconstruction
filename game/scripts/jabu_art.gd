extends RefCounted
const Art=preload("res://scripts/art.gd")

static func tissue(color:Color=Color("98656a"), wet:float=.38) -> ShaderMaterial:
	var mat=ShaderMaterial.new()
	mat.shader=preload("res://shaders/organic.gdshader")
	mat.set_shader_parameter("tissue",color)
	mat.set_shader_parameter("wetness",wet)
	return mat

static func blob(parent:Node3D, at:Vector3, size:Vector3, mat:Material) -> MeshInstance3D:
	var sphere=SphereMesh.new()
	sphere.radial_segments=64
	sphere.rings=32
	sphere.radius=1
	sphere.height=2
	var node=MeshInstance3D.new()
	node.mesh=sphere
	node.position=at
	node.scale=size
	node.material_override=mat
	parent.add_child(node)
	return node

static func tube(parent:Node3D, points:PackedVector3Array, radius:float, mat:Material, taper:float=1.0) -> MeshInstance3D:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices:Array[Vector3]=[]
	var normals:Array[Vector3]=[]
	for i in range(points.size()):
		var axis=(points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]).normalized()
		var tangent=axis.cross(Vector3.UP).normalized()
		if tangent.length()<.1: tangent=Vector3.RIGHT
		var side=axis.cross(tangent).normalized()
		for j in range(25):
			var a=j*TAU/24
			var normal=tangent*cos(a)+side*sin(a)
			normals.append(normal)
			vertices.append(points[i]+normal*radius*lerpf(1,taper,float(i)/(points.size()-1)))
	for i in range(points.size()-1):
		for j in range(24):
			for index in [i*25+j,(i+1)*25+j,i*25+j+1,i*25+j+1,(i+1)*25+j,(i+1)*25+j+1]:
				st.set_normal(normals[index])
				st.add_vertex(vertices[index])
	var node=MeshInstance3D.new()
	node.mesh=st.commit()
	node.material_override=mat
	parent.add_child(node)
	return node

static func chamber(parent:Node3D, radius:float=12, flooded:bool=false) -> ShaderMaterial:
	var mat=tissue()
	# Continuous inward-facing vault, broad folds and small surface structure.
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points:Array[Vector3]=[]
	for row in range(49):
		var elevation=float(row)/48*PI*.5
		for col in range(161):
			var a=col*TAU/160
			var r=radius*cos(elevation)*(1+.024*sin(a*12+elevation*2)+.014*sin(a*7-elevation*5))
			points.append(Vector3(sin(a)*r,sin(elevation)*9,cos(a)*r*1.12))
	for row in range(48):
		for col in range(160):
			for index in [row*161+col,(row+1)*161+col,row*161+col+1,row*161+col+1,(row+1)*161+col,(row+1)*161+col+1]:
				st.add_vertex(points[index])
	st.generate_normals()
	var vault=MeshInstance3D.new()
	vault.mesh=st.commit()
	vault.material_override=mat
	parent.add_child(vault)
	if flooded:
		for slab in [[Vector3(-7.5,-.25,0),Vector3(9,.5,27)],[Vector3(7.5,-.25,0),Vector3(9,.5,27)],[Vector3(0,-.25,-9.25),Vector3(6,.5,8.5)],[Vector3(0,-.25,7.25),Vector3(6,.5,12.5)],[Vector3(0,-2.65,-2),Vector3(6,.3,6)]]:
			var floor_mesh=Art.box(parent,slab[0],slab[1],Color.WHITE,true)
			floor_mesh.material_override=tissue(Color("997678"),.45)
		for bank in [[Vector3(-3.12,-1.3,-2),Vector3(.24,2.6,6)],[Vector3(3.12,-1.3,-2),Vector3(.24,2.6,6)],[Vector3(0,-1.3,-5.12),Vector3(6,2.6,.24)],[Vector3(0,-1.3,1.12),Vector3(6,2.6,.24)]]:
			var wall_mesh=Art.box(parent,bank[0],bank[1],Color.WHITE)
			wall_mesh.material_override=tissue(Color("73535e"))
		Art.walkway(parent,Vector3(0,-2.5,0),Vector3(3,0,0),1.65,Color("ab8c8a"))
	else:
		var floor_mesh=Art.cylinder(parent,Vector3(0,-.18,0),radius,radius,.36,Color.WHITE,128)
		floor_mesh.scale.z=1.12
		floor_mesh.material_override=tissue(Color("997678"),.45)
		Art.collision_box(parent,Vector3(0,-.25,0),Vector3(radius*2,.5,radius*2.3))
	for i in range(40):
		var a=i*TAU/40
		var wall=Art.collision_box(parent,Vector3(sin(a)*(radius-.5),4,cos(a)*(radius-.5)*1.12),Vector3(2.7,8,.6))
		wall.rotation.y=a
		wall.collision_layer=9
	# Large radial folds support the vault and catch light at different depths.
	for i in range(18):
		var a=(i+.35)*TAU/18
		var path=PackedVector3Array()
		for j in range(49):
			var t=float(j)/48*PI*.5
			var r=(radius-.23)*cos(t)
			path.append(Vector3(sin(a)*r,sin(t)*8.8+.08,cos(a)*r*1.12))
		tube(parent,path,.22+.06*sin(i*3),tissue(Color("a77d7c"),.48),.25)
	for side in [-1,1]:
		for z in [-7,1,8]:
			var at=Vector3(side*(radius-2.2),1.8,z)
			blob(parent,at,Vector3(.30,.7,.28),Art.material(Color("b9a992"),.26))
			var light=OmniLight3D.new()
			light.position=at+Vector3(-side*.4,.3,0)
			light.light_color=Color("ffbaa0")
			light.light_energy=1.25
			light.omni_range=14
			light.shadow_enabled=z==1
			light.omni_shadow_mode=OmniLight3D.SHADOW_CUBE
			parent.add_child(light)
	return mat

static func portal(parent:Node3D, at:Vector3, hue:Color=Color("d3a09b")) -> Node3D:
	var root=Node3D.new()
	root.position=at
	parent.add_child(root)
	root.look_at_from_position(at,Vector3(0,at.y,0))
	var camera_block=Art.collision_box(root,Vector3(0,1.4,0),Vector3(2.8,3.2,.6))
	camera_block.collision_layer=8
	for layer in range(3):
		var path=PackedVector3Array()
		for i in range(65):
			var a=i*TAU/64
			path.append(Vector3(sin(a)*(1.12+layer*.12),1.36+cos(a)*(1.38+layer*.1),layer*.16))
		tube(root,path,.13,tissue(hue,.36))
	blob(root,Vector3(0,1.25,.33),Vector3(1.04,1.28,.10),tissue(Color("48383e"),.6))
	var seal=blob(root,Vector3(0,1.25,-.08),Vector3(1.04,1.28,.12),tissue(Color("a6838c"),.4))
	seal.name="Seal"
	return root

static func boomerang(parent:Node3D) -> Node3D:
	var root=Node3D.new()
	parent.add_child(root)
	var mat=Art.material(Color("c6a567"),.38)
	var path=PackedVector3Array()
	for i in range(33):
		var t=float(i)/32
		path.append(Vector3((t-.5)*.74,0,.25*pow(absf(t-.5)*2,1.7)))
	var blade=tube(root,path,.055,mat)
	blade.scale.y=.4
	for x in [-.12,.12]:
		var binding=blob(root,Vector3(x,0,.025),Vector3(.043,.026,.07),Art.material(Color("684b38"),.74))
		binding.rotation.y=-signf(x)*.4
	return root
