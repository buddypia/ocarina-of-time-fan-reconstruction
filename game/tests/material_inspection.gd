# Geometry regression and optional native Domain detail views.
# godot --headless --path game --script res://tests/material_inspection.gd
# OOT_EVIDENCE_DIRECTORY=<dir> godot --path game --rendering-method forward_plus --rendering-driver metal --script res://tests/material_inspection.gd -- --domain
extends SceneTree
const Natural=preload("res://scripts/natural_art.gd")
const Art=preload("res://scripts/art.gd")

func _initialize() -> void:
	call_deferred("run")

func triangles(stage:Node3D) -> int:
	var count=0
	for node in stage.find_children("*","MeshInstance3D",true,false):
		if not node.is_visible_in_tree(): continue
		var arrays=node.mesh.surface_get_arrays(0)
		var indices=arrays[Mesh.ARRAY_INDEX]
		count+=int((arrays[Mesh.ARRAY_VERTEX].size() if indices==null or indices.is_empty() else indices.size())/3)
	return count

func run() -> void:
	var output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	if output.is_empty(): output="user://material-inspection"
	DirAccess.make_dir_recursive_absolute(output)
	var stage=Node3D.new()
	root.add_child(stage)
	Natural.column(stage,Vector3(-3,0,0),5)
	Natural.block(stage,Vector3(0,-.1,0),Vector3(14,.2,10),true)
	# Same material, indexed primitive. This used to make the column disappear.
	var box=MeshInstance3D.new()
	box.mesh=BoxMesh.new()
	box.material_override=Natural.stone()
	box.position=Vector3(3,1,0)
	stage.add_child(box)
	var before=triangles(stage)
	Art.batch_static(stage)
	var after=triangles(stage)
	var result={"passed":before==after,"before_triangles":before,"after_triangles":after,"scope":"Mixed indexed and non-indexed geometry survives static batching."}
	FileAccess.open(output+"/batch-geometry.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result))
	stage.queue_free()
	await process_frame
	if before!=after:
		Natural.release_resources()
		quit(1)
		return
	if not "--domain" in OS.get_cmdline_user_args():
		Natural.release_resources()
		quit(0)
		return
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await create_timer(.5).timeout
	world.save_path=output+"/unused-test-save.json"
	world.start_game()
	world.overworld.enter("domain")
	world.message_panel.hide()
	world.player.set_physics_process(false)
	for shot in [{"name":"column-close","at":Vector3(15,4,-.5),"look":Vector3(19,3.5,-5)},{"name":"rock-close","at":Vector3(19,2.3,-11),"look":Vector3(27,2.0,-12)},{"name":"water-low","at":Vector3(-7,1.2,15),"look":Vector3(2,-1,2)}]:
		world.player.camera.position=shot.at
		world.player.camera.look_at(shot.look)
		await create_timer(1).timeout
		root.get_texture().get_image().save_png(output+"/"+shot.name+".png")
	await world.quit_cleanly(0)
