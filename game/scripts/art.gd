class_name ForestArt
extends RefCounted

static var mats: Dictionary = {}
static var grain: NoiseTexture2D

static func material(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var key := str(color) + str(roughness) + str(metallic)
	if mats.has(key): return mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if roughness > .6:
		if grain == null:
			grain = NoiseTexture2D.new()
			grain.width = 128
			grain.height = 128
			grain.seamless = true
			var noise = FastNoiseLite.new()
			noise.frequency = .055
			noise.fractal_octaves = 3
			grain.noise = noise
			var ramp = Gradient.new()
			ramp.colors = PackedColorArray([Color(.78,.78,.78),Color(1,1,1)])
			grain.color_ramp = ramp
		m.albedo_texture = grain
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * .24
	mats[key] = m
	return m

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.position = at
	node.material_override = material(color)
	parent.add_child(node)
	return node

static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	var node := mesh(parent, shape, at, color)
	if solid: collision_box(parent, at, size)
	return node

static func collision_box(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
	return body

static func ellipsoid(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 10
	sphere.rings = 5
	sphere.radius = 1.0
	sphere.height = 2.0
	var node := mesh(parent, sphere, at, color)
	node.scale = size
	return node

static func cylinder(parent: Node3D, at: Vector3, bottom: float, top: float, height: float, color: Color, segments: int = 12) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = bottom
	shape.top_radius = top
	shape.height = height
	shape.radial_segments = segments
	return mesh(parent, shape, at, color)

static func beam(parent: Node3D, start: Vector3, end: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := cylinder(parent, (start + end) * 0.5, radius, radius * .65, start.distance_to(end), color, 7)
	var direction := (end - start).normalized()
	node.quaternion = Quaternion(Vector3.UP, direction)
	return node

static func walkway(parent:Node3D, start:Vector3, end:Vector3, width:float, color:Color, grounded:bool=false) -> Node3D:
	var direction=end-start
	direction.y=0
	var side=Vector3(-direction.z,0,direction.x).normalized()*width*.5
	var bottom=-.3 if grounded else minf(start.y,end.y)-.5
	var points=PackedVector3Array([start-side,start+side,end+side,end-side])
	for i in range(4): points.append(Vector3(points[i].x,bottom,points[i].z))
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0,2,1,0,3,2,4,5,6,4,6,7,0,1,5,0,5,4,1,2,6,1,6,5,2,3,7,2,7,6,3,0,4,3,4,7]:
		surface.set_uv(Vector2(points[index].x,points[index].z)*.2)
		surface.add_vertex(points[index])
	surface.generate_normals()
	var root=Node3D.new()
	parent.add_child(root)
	var model=MeshInstance3D.new()
	model.mesh=surface.commit()
	model.material_override=material(color)
	root.add_child(model)
	var body=StaticBody3D.new()
	var collider=CollisionShape3D.new()
	var shape=ConvexPolygonShape3D.new()
	shape.points=points
	collider.shape=shape
	body.add_child(collider)
	root.add_child(body)
	return root

static func ring(parent:Node3D, outer:float, inner:float, y:float, color:Color) -> MeshInstance3D:
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(64):
		var a=i*TAU/64.0
		var b=(i+1)*TAU/64.0
		var points=[Vector3(sin(a)*inner,y,cos(a)*inner),Vector3(sin(a)*outer,y,cos(a)*outer),Vector3(sin(b)*outer,y,cos(b)*outer),Vector3(sin(b)*inner,y,cos(b)*inner)]
		for index in [0,2,1,0,3,2]:
			surface.set_normal(Vector3.UP)
			surface.set_uv(Vector2(points[index].x,points[index].z)*.2)
			surface.add_vertex(points[index])
	var mesh_node=MeshInstance3D.new()
	mesh_node.mesh=surface.commit()
	mesh_node.material_override=material(color)
	parent.add_child(mesh_node)
	mesh_node.create_trimesh_collision()
	return mesh_node

static func tree(parent: Node3D, at: Vector3, size: float, seed_value: int, solid: bool = true) -> Node3D:
	var root := Node3D.new()
	root.position = at
	parent.add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var bark := Color("66503a").darkened(rng.randf_range(0.0, .16))
	cylinder(root, Vector3(0, 3.2 * size, 0), .7 * size, .32 * size, 6.4 * size, bark)
	for i in range(5):
		var angle := TAU * i / 5.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		beam(root, direction * 2.0 * size + Vector3.UP * .08, Vector3.UP * 1.1 * size, .32 * size, bark)
		beam(root, Vector3.UP * 4.0 * size, direction * 1.8 * size + Vector3.UP * 6.8 * size, .24 * size, bark)
		ellipsoid(root, direction * 1.5 * size + Vector3.UP * rng.randf_range(6.3, 7.8) * size, Vector3(2.2,1.55,2.2) * size, Color("456a37").lightened(rng.randf_range(-.12,.10)))
	if solid: collision_box(root, Vector3.UP * 2.3 * size, Vector3(1.05,4.6,1.05) * size)
	return root

static func house(parent: Node3D, at: Vector3, size: float, angle: float) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	root.rotation.y = angle
	root.scale = Vector3.ONE * size
	var bark := Color("77553a")
	cylinder(root, Vector3(0,1.8,0), 2.25, 1.9, 3.6, bark, 16)
	collision_box(root, Vector3(0,1.65,-.4), Vector3(3.6,3.3,2.6))
	# Roots, layered roof and a raised threshold belong to the same tree trunk.
	for i in range(9):
		var a := i * TAU / 9.0
		beam(root, Vector3(cos(a)*3.0,.08,sin(a)*3.0), Vector3(cos(a)*1.7,1.2,sin(a)*1.7), .33, bark.darkened(.12))
		beam(root, Vector3(cos(a)*2.14,.5,sin(a)*2.14), Vector3(cos(a)*1.84,3.25,sin(a)*1.84), .048, bark.lightened(.11))
	cylinder(root, Vector3(0,3.75,0), 2.65, 1.4, .9, Color("536c32"), 14)
	cylinder(root, Vector3(0,4.25,0), 1.65, .4, .7, Color("6e833a"), 12)
	cylinder(root, Vector3(0,4.66,0), .65, .25, .25, Color("829146"), 10)
	box(root, Vector3(0,1,2.0), Vector3(1.12,1.9,.10), Color("211e18"))
	beam(root, Vector3(-.64,.1,2.13), Vector3(-.64,1.7,2.13), .115, Color("9c7c4e"))
	beam(root, Vector3(.64,.1,2.13), Vector3(.64,1.7,2.13), .115, Color("9c7c4e"))
	beam(root, Vector3(-.64,1.7,2.13), Vector3(0,2.15,2.13), .115, Color("9c7c4e"))
	beam(root, Vector3(.64,1.7,2.13), Vector3(0,2.15,2.13), .115, Color("9c7c4e"))
	for side in [-1,1]:
		var window := cylinder(root, Vector3(side*1.4,2.1,1.6), .35,.35,.08,Color("d0bd72"))
		window.rotation.x = PI/2
		beam(root, Vector3(side*1.4-.3,2.1,1.67), Vector3(side*1.4+.3,2.1,1.67), .035,Color("4b382b"))
	return root

static func chest(parent: Node3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.set_meta("animated",true)
	parent.add_child(root)
	root.position = at
	box(root, Vector3(0,.34,0), Vector3(1.05,.60,.72),Color("704627"), true)
	var lid := Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0,.64,-.34)
	root.add_child(lid)
	box(lid, Vector3(0,.06,.34),Vector3(1.12,.20,.78), Color("91603a"))
	for x in [-.38,.38]:
		box(root,Vector3(x,.36,.372),Vector3(.09,.61,.035),Color("aa9569"))
		box(lid,Vector3(x,.17,.34),Vector3(.09,.03,.78),Color("aa9569"))
	box(root,Vector3(0,.49,.39),Vector3(.16,.22,.05),Color("d0b364"))
	return root

static func rupee(parent: Node3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.set_meta("animated",true)
	root.position = at
	parent.add_child(root)
	var upper := cylinder(root,Vector3(0,.08,0),.18,0,.30,Color("399ae3"),4)
	var lower := cylinder(root,Vector3(0,-.14,0),0,.18,.14,Color("2b66a1"),4)
	upper.material_override = material(Color("459ddb"),.3,.2)
	lower.material_override = material(Color("307bb5"),.3,.2)
	return root

static func batch_static(parent: Node3D) -> void:
	# Merge static geometry by material. Animated chests, pickups and characters
	# retain their editable hierarchy; collision bodies are unchanged.
	var groups:Dictionary={}
	var indexed_meshes:Dictionary={}
	for node in parent.find_children("*","MeshInstance3D",true,false):
		var ancestor=node.get_parent()
		var animated=node.has_meta("animated")
		while ancestor!=parent and ancestor!=null:
			if ancestor.has_meta("animated"): animated=true
			ancestor=ancestor.get_parent()
		if animated or node.material_override==null: continue
		var mat=node.material_override
		if not groups.has(mat): groups[mat]=[]
		groups[mat].append(node)
	for mat in groups:
		var surface=SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(mat)
		for node in groups[mat]:
			# SurfaceTool keeps a single index stream. Mixing indexed primitives with
			# non-indexed authored triangles otherwise silently drops the latter.
			if not indexed_meshes.has(node.mesh):
				var arrays=node.mesh.surface_get_arrays(0)
				if arrays[Mesh.ARRAY_INDEX]==null or arrays[Mesh.ARRAY_INDEX].is_empty():
					arrays[Mesh.ARRAY_INDEX]=PackedInt32Array(range(arrays[Mesh.ARRAY_VERTEX].size()))
					var indexed=ArrayMesh.new()
					indexed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
					indexed_meshes[node.mesh]=indexed
				else: indexed_meshes[node.mesh]=node.mesh
			surface.append_from(indexed_meshes[node.mesh],0,parent.global_transform.affine_inverse()*node.global_transform)
			node.visible=false
		var combined=MeshInstance3D.new()
		combined.name="StaticGeometry"
		combined.mesh=surface.commit()
		combined.material_override=mat
		parent.add_child(combined)

static func deku(parent: Node3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = at
	parent.add_child(root)
	cylinder(root,Vector3(0,9,0),7.2,5.8,10,Color("76614a"),18)
	for i in range(18):
		var a=i*TAU/18.0
		if cos(a)>.94: continue
		var stave=box(root,Vector3(sin(a)*6.6,2,cos(a)*6.6),Vector3(2.5,4,1.8),Color("76614a"))
		stave.rotation.y=a
	for i in range(9):
		var a := i*TAU/9.0
		if not (sin(a)>.6 and absf(cos(a))<.4):
			beam(root,Vector3(cos(a)*10,.1,sin(a)*10),Vector3(cos(a)*5,4,sin(a)*5),1.4,Color("6c5841"))
		ellipsoid(root,Vector3(cos(a)*6,15+sin(a*3)*2,sin(a)*6),Vector3(6,3,5),Color("41613c").lightened(.04*sin(a)))
	box(root,Vector3(0,1.7,6.65),Vector3(2.9,3.4,.3),Color("171d17"))
	for side in [-1,1]:
		var brow := ellipsoid(root,Vector3(side*2.3,8.6,5.3),Vector3(2.0,.7,.85),Color("9b825f"))
		brow.rotation.z = side*.13
		ellipsoid(root,Vector3(side*2.15,7.9,5.7),Vector3(1.1,.35,.2),Color("302e24"))
		ellipsoid(root,Vector3(side*2.15,7.87,5.94),Vector3(.32,.25,.08),Color("b7a375"))
		beam(root,Vector3(side*.3,4.0,7.1),Vector3(side*2.5,3.3,6.4),.50,Color("a58b62"))
	ellipsoid(root,Vector3(0,6.4,6.1),Vector3(.95,1.8,1),Color("8d7654"))
	return root
