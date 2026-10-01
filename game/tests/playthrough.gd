extends Node

var world: Node3D
var checks: Array = []
var output := "res://../evidence/authored"
var headless := false
var scope := "Authored forest preparation and Deku Tree entrance; full game incomplete."

func run(target: Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	await frames(90)
	await capture("01-title")
	world.start_game()
	await frames(90)
	await capture("02-forest")
	if "--capture-only" in OS.get_cmdline_user_args():
		await finish()
		return
	await forest_route()
	await finish()

func forest_route() -> void:
	await walk(Vector3(2.5,0,10.5))
	await press("interact")
	check("Saria conversation through interaction input",world.state.saria)
	await walk(Vector3(0,0,10.5))
	await walk(Vector3(0,0,-20.5))
	await press("interact")
	check("Mido refuses entry without equipment",not world.state.mido and world.gate.collision_layer==1)
	# Follow navigable routes, including the opening in the sword clearing.
	await walk(Vector3(-5,0,-10))
	await walk(Vector3(-17,0,-10))
	await walk(Vector3(-18,0,-17.5))
	await press("interact")
	check("Kokiri Sword obtained from chest",world.state.sword)
	await frames(35)
	await capture("03-sword")
	for at in [Vector3(-16,0,-15),Vector3(-14,0,-11),Vector3(-9,0,-7),Vector3(-10,0,-2),Vector3(-7,0,3),Vector3(-4,0,7),Vector3(5,0,-5),Vector3(8,0,-8)]:
		await walk(at)
	check("Eight blue rupees collected by collision proximity",world.state.rupees==40)
	await walk(Vector3(10,0,-8))
	await press("interact")
	check("Shop exchanges 40 rupees for shield",world.state.shield and world.state.rupees==0)
	await walk(Vector3(0,0,-20.5))
	await press("interact")
	check("Mido admits equipped player",world.state.mido and world.gate.collision_layer==0)
	await press("attack")
	check("Sword input starts attack animation",world.player.attacking>0)
	await press("save")
	var saved=world.player.position
	world.player.position=Vector3(0,.3,14)
	world.state.sword=false
	world.load_game()
	check("Save restores equipment and position",world.state.sword and world.player.position.distance_to(saved)<.3)
	await walk(Vector3(0,0,-34.5))
	await capture("04-deku-approach")
	await press("interact")
	await frames(30)
	check("Entry transition uses the same player",world.area=="deku_lobby")
	await capture("05-deku-interior")

func walk(destination: Vector3) -> void:
	var stalled:=0
	var previous:Vector3=world.player.position
	for i in range(1100):
		var offset:Vector3=destination-world.player.position
		offset.y=0
		if offset.length()<.28: break
		# World has yaw-relative controls. Keep camera north for deterministic route input.
		world.player.yaw=0
		var direction=offset.normalized()
		Input.action_press("right",maxf(0,direction.x))
		Input.action_press("left",maxf(0,-direction.x))
		Input.action_press("back",maxf(0,direction.z))
		Input.action_press("forward",maxf(0,-direction.z))
		await get_tree().physics_frame
		if world.player.position.distance_to(previous)<.002: stalled+=1
		else: stalled=0
		previous=world.player.position
		if stalled>90: break
	for action in ["right","left","back","forward"]: Input.action_release(action)
	await frames(4)
	var error=Vector2(destination.x-world.player.position.x,destination.z-world.player.position.z).length()
	check("Walk to "+str(destination),error<.65,{"remaining":error,"actual":str(world.player.position)})
	if error>=.65:
		await capture("failed-route")
		await finish()

func press(action: String) -> void:
	await get_tree().process_frame
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func frames(count: int) -> void:
	for i in range(count): await get_tree().process_frame

func check(name: String, ok: bool, extra: Dictionary={}) -> void:
	checks.append({"name":name,"pass":ok,"extra":extra})
	print("CHECK ",name,": ",ok)

func capture(name: String) -> void:
	if headless: return
	await get_tree().process_frame
	if world.message_panel.visible:
		var bounds:Rect2=world.message_panel.get_global_rect()
		var viewport_size:Vector2=get_viewport().get_visible_rect().size
		check("Dialogue stays on screen above the controls: "+name,bounds.position.x>=0 and bounds.position.y>=0 and bounds.end.x<=viewport_size.x and bounds.end.y<=viewport_size.y-100,{"bounds":str(bounds)})
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")
	print("CAPTURE ",name)

func finish() -> void:
	var success=true
	for result in checks:
		if not result.pass: success=false
	var frames_sorted=world.samples.duplicate()
	frames_sorted.sort()
	var p95=0.0
	if frames_sorted.size()>0: p95=frames_sorted[int((frames_sorted.size()-1)*.95)]*1000
	var report={"checks":checks,"passed":success,"headless":headless,"frame_ms_p95":p95,"walked_metres":world.player.distance_walked,"state":world.state,"scope":scope,"combat_stats":world.stats,"human_playtest":false}
	var wall=world.wall_samples.duplicate()
	report.area_performance={}
	for area_name in world.area_samples:
		var timings:Array=world.area_samples[area_name].duplicate()
		timings.sort()
		if timings.is_empty(): continue
		report.area_performance[area_name]={"samples":timings.size(),"median_ms":timings[int(timings.size()/2)]*1000,"p95_ms":timings[int((timings.size()-1)*.95)]*1000,"max_ms":timings.back()*1000}
	wall.sort()
	if wall.size()>0:
		report.wall_frame_ms_p95=wall[int((wall.size()-1)*.95)]*1000
		report.wall_frame_ms_median=wall[int(wall.size()/2)]*1000
		report.wall_sample_count=wall.size()
		report.wall_measurement="Monotonic microseconds between _process callbacks, most recent 3600 frames; includes screenshot capture and scene transitions."
	var f=FileAccess.open(output+"/report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	f.close()
	print(JSON.stringify(report))
	await world.quit_cleanly(0 if success else 1)
