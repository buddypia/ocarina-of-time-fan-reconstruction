# Native render and input fixture for the anatomical player; not a campaign playtest.
extends SceneTree
var world:Node3D
var output:String
var camera:Camera3D
var checks:Array=[]
var captures:Array=[]
func _initialize() -> void: call_deferred("run")
func check(label:String, passed:bool) -> void:
	checks.append({"name":label,"passed":passed})
	print("CHECK ",label,": ",passed)
func wait(seconds:float) -> void: await create_timer(seconds).timeout
func capture(label:String, angle:Vector3=Vector3(2.2,1.7,-3.2), focus:Vector3=Vector3(0,.8,0)) -> void:
	camera.position=world.player.position+angle
	camera.look_at(world.player.position+focus)
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(output+"/"+label+".png")
	captures.append({"name":label,"position":str(world.player.position),"motion":world.player.current_motion,"time":world.player.animator.current_animation_position})
func run() -> void:
	print("CHARACTER FIXTURE START")
	output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	if output.is_empty(): output="user://character-inspection"
	DirAccess.make_dir_recursive_absolute(output)
	world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await wait(.5)
	world.save_path=output+"/test-save.json"
	print("CHARACTER WORLD READY")
	world.start_game()
	world.state.sword=true
	world.state.shield=true
	world.state.bracelet=true
	world.state.bomb_bag=true
	world.state.bomb_count=10
	world.state.slingshot=true
	world.state.seeds=20
	world.overworld.enter("domain")
	world.player.position=Vector3(-13,.05,13)
	world.message_panel.hide()
	camera=Camera3D.new()
	world.add_child(camera)
	camera.fov=45
	camera.current=true
	await wait(.4)
	print("CHARACTER DOMAIN READY")
	await capture("01-idle-front")
	await capture("02-idle-back",Vector3(-2,1.5,3))
	await capture("02b-face-close",Vector3(.48,1.45,-.85),Vector3(0,1.22,0))
	await capture("02c-boots-close",Vector3(-.68,.45,.85),Vector3(0,.24,0))
	var before:Vector3=world.player.position
	await process_frame
	Input.action_press("forward")
	await wait(.18)
	await capture("03-walk-contact")
	for i in range(20): await physics_frame
	await capture("04-walk-passing")
	check("Walking input moves the skinned character",world.player.position.distance_to(before)>.8 and world.player.current_motion=="Walk" and world.player.animator.current_animation=="Walk")
	Input.action_release("forward")
	await wait(.3)
	await process_frame
	Input.action_press("attack")
	await wait(.08)
	Input.action_release("attack")
	await capture("05-sword-preparation")
	check("Sword follows the attacking wrist",world.player.sword.get_parent()==world.player.sockets.right and world.player.current_motion=="Attack" and world.player.animator.current_animation=="Attack")
	await wait(.12)
	await capture("06-sword-stroke")
	await wait(.3)
	check("Sword returns to the back after the stroke",world.player.sword.get_parent()==world.player.sockets.back)
	await process_frame
	Input.action_press("shield")
	await wait(.2)
	await capture("07-shield")
	check("Defending shield follows the left wrist",world.player.shield.get_parent()==world.player.sockets.left)
	Input.action_release("shield")
	world.player.position=Vector3(-13,.02,18)
	world.player.velocity=Vector3.ZERO
	world.player.visual.rotation.y=0
	await wait(.2)
	await process_frame
	Input.action_press("roll")
	await wait(.15)
	Input.action_release("roll")
	await capture("08-roll")
	await wait(.5)
	check("A standing roll continues forward through the somersault",world.player.position.z<15.5 and absf(world.player.position.x+13)<.2)
	await process_frame
	Input.action_press("bomb")
	await wait(.2)
	Input.action_release("bomb")
	await wait(.2)
	await capture("09-carry",Vector3(2.2,1.9,-3.2))
	check("Bomb input selects the carry motion",is_instance_valid(world.held_bomb) and world.player.current_motion in ["Carry","CarryIdle"] and world.player.animator.current_animation==world.player.current_motion)
	if is_instance_valid(world.held_bomb):
		var grip_center=(world.player.sockets.left.global_position+world.player.sockets.right.global_position)*.5
		check("Held bomb rests between the raised hands",world.held_bomb.position.distance_to(grip_center)<.3 and grip_center.y>world.player.position.y+1.25)
	await process_frame
	Input.action_press("interact")
	await wait(.03)
	Input.action_release("interact")
	world.player.position=Vector3(-13,.05,13)
	await process_frame
	Input.action_press("shoot")
	await wait(.15)
	Input.action_release("shoot")
	await capture("10-slingshot")
	check("Slingshot follows the left wrist",world.player.sling.visible and world.player.current_motion=="Shoot")
	await wait(.4)
	world.player.position=Vector3(0,-.78,10)
	world.player.velocity=Vector3.ZERO
	world.player.visual.rotation.y=0
	await process_frame
	Input.action_press("forward")
	await wait(.3)
	await capture("11-swim-front",Vector3(2.2,1.7,-3.2))
	await capture("12-swim-side",Vector3(3.5,.6,0))
	check("Water selects a horizontal swimming pose",world.player.swimming and world.player.current_motion=="Swim" and absf(world.player.visual.rotation.x)>1)
	Input.action_release("forward")
	world.player.enabled=false
	var frozen:float=world.player.animator.current_animation_position
	await wait(.25)
	check("Pausing freezes the skeletal pose",is_equal_approx(frozen,world.player.animator.current_animation_position))
	world.player.enabled=true
	world.dungeon.enter("lobby")
	var route=world.ladders[0]
	world.player.start_climbing(route.base,route.top)
	await wait(.2)
	var stationary_height:float=world.player.position.y
	var wrist_height:float=world.player.sockets.left.global_position.y-world.player.position.y
	check("Starting a climb at rest adopts the raised-arm cling pose",world.player.current_motion=="Climb" and wrist_height>1.2)
	await wait(.2)
	check("An idle climber remains at the ledge height",is_equal_approx(stationary_height,world.player.position.y))
	await capture("13a-cling-at-rest")
	await process_frame
	Input.action_press("forward")
	await wait(.3)
	await capture("13-climb")
	check("Climbing input moves the body with climbing animation",world.player.climbing and world.player.current_motion=="Climb" and world.player.position.y>route.base.y+.5)
	Input.action_release("forward")
	var timings:Array=world.area_samples.get("domain",[]).duplicate()
	timings.sort()
	var performance={}
	if not timings.is_empty():
		performance={"samples":timings.size(),"median_ms":timings[int(timings.size()/2)]*1000,"p95_ms":timings[int((timings.size()-1)*.95)]*1000,"max_ms":timings.back()*1000,"scope":"Domain frames during close-up input fixture, including captures and camera changes; not a campaign performance test."}
	var passed=checks.all(func(x): return x.passed)
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"captures":captures,"domain_frame_times":performance,"scope":"Native anatomical player integration fixture; direct inventory and location setup, input-driven motions. Visual quality requires image review; not a human playtest."},"\t"))
	await world.quit_cleanly(0 if passed else 1)
