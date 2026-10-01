extends "res://tests/playthrough.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	scope="Authored forest and five-room Deku Tree route through Gohma, emerald and ocarina; full game incomplete."
	await frames(30)
	world.start_game()
	if "--fixture" in OS.get_cmdline_user_args():
		scope="Deku Tree route with explicit equipment fixture: sword, shield and Mido permission. Full game incomplete."
		world.state.sword=true
		world.state.shield=true
		world.state.mido=true
		world.enter_deku()
	else: await forest_route()
	await dungeon_route()
	await finish()

func dungeon_route() -> void:
	await frames(20)
	await capture("07-hollow")
	await walk(Vector3(7,0,5))
	await walk(Vector3(8,0,-2))
	await press("interact")
	check("Enter slingshot chamber",world.area=="deku_slingshot")
	await walk(Vector3(-4,0,4.9))
	await walk(Vector3(-4,2,-5))
	await walk(Vector3(0,2,-6))
	await press("interact")
	check("Climb physical ramp and open slingshot chest",world.state.slingshot and world.player.position.y>1.9)
	await capture("08-slingshot")
	await walk(Vector3(-4,2,-5))
	await walk(Vector3(-4,0,4.9))
	await walk(Vector3(0,0,6.5))
	await press("interact")
	check("Unsolved eye prevents leaving after taking the slingshot",world.area=="deku_slingshot" and not world.state.ladder_down)
	await press("target")
	await seconds(.6)
	await press("shoot")
	await seconds(.8)
	check("Actual seed projectile activates the eye",world.state.ladder_down and world.stats.eye_hits==1)
	await press("target")
	await press("interact")
	check("Eye releases exit",world.area=="deku_lobby")
	await walk(Vector3(0,0,-6))
	await walk(Vector3(-8,0,-4))
	await walk(Vector3(-10,0,1))
	await press("interact")
	Input.action_press("forward")
	await seconds(2.4)
	Input.action_release("forward")
	check("Vines reach the high gallery",world.player.position.y>5.5 and not world.player.climbing)
	await walk(Vector3(-4.8,6,0))
	await capture("09-web-dive")
	world.player.yaw=0
	Input.action_press("right")
	for i in range(150):
		await get_tree().physics_frame
		if world.area=="deku_basement": break
	Input.action_release("right")
	check("Fall through the web opens the lower dungeon",world.state.web_broken and world.area=="deku_basement")
	if world.area!="deku_basement":
		await capture("failed-web")
		await finish()
		return
	await walk(Vector3(0,0,-7.4))
	await press("interact")
	check("Unburned web guards the passage",world.area=="deku_basement")
	await walk(Vector3(-7,0,4.8))
	await press("interact")
	check("Torch lights a limited-duration stick",world.torch_time>10)
	await walk(Vector3(-8,0,-5))
	await walk(Vector3(0,0,-7.7))
	check("Carried fire burns the blocking web",world.state.web_burned)
	await capture("10-burned-web")
	await press("interact")
	check("Enter brothers' chamber",world.area=="deku_scrubs")
	await walk(Vector3(0,0,-.2))
	await reflect_scrub(2)
	await walk(Vector3(0,0,-1.5))
	await press("interact")
	await walk(Vector3(4,0,.5))
	await reflect_scrub(3)
	await walk(Vector3(4,0,-1.5))
	await press("interact")
	await walk(Vector3(-4,0,.5))
	await reflect_scrub(1)
	await walk(Vector3(-4,0,-1.5))
	await press("interact")
	check("Shield reflections and 2, 3, 1 conversations unseal boss",world.state.scrubs_solved and world.stats.reflections>=3)
	await capture("11-brothers")
	await walk(Vector3(-7,0,-5))
	await walk(Vector3(0,0,-7.6))
	await press("save")
	world.load_game()
	check("Dungeon save restores solved mechanisms",world.area=="deku_scrubs" and world.state.scrubs_solved and world.state.web_burned and world.state.web_broken and world.state.ladder_down)
	await press("interact")
	check("Enter Gohma arena",world.area=="deku_gohma")
	await capture("12-gohma")
	await fight_gohma()
	check("Gohma defeated through timed projectiles and sword input",world.state.gohma and world.stats.stuns>=3 and world.stats.sword_hits>=9)
	if not world.state.gohma:
		await capture("failed-gohma")
		await finish()
		return
	await walk(Vector3(0,0,-4))
	await press("interact")
	check("Emerald and heart reward return to forest",world.area=="forest" and world.state.emerald and world.state.max_health==8)
	await walk(Vector3(0,0,8.6))
	await walk(Vector3(2,0,9.5))
	await press("interact")
	check("Saria gives the ocarina after the emerald",world.state.ocarina)
	await press("save")
	world.load_game()
	check("Post-dungeon progression survives reload",world.state.gohma and world.state.emerald and world.state.ocarina and world.state.max_health==8)
	await capture("13-forest-reward")

func seconds(duration:float) -> void:
	await get_tree().create_timer(duration).timeout

func reflect_scrub(number:int) -> void:
	var enemy:Node3D
	for candidate in world.creatures:
		if candidate.enemy_id=="scrub_"+str(number): enemy=candidate
	world.player.yaw=0
	world.player.visual.rotation.y=0
	Input.action_press("shield")
	for i in range(480):
		await get_tree().physics_frame
		if enemy.surrendered: break
	Input.action_release("shield")
	check("Reflect a real nut from brother "+str(number),enemy.surrendered)

func fight_gohma() -> void:
	var boss:Node3D
	for enemy in world.creatures:
		if enemy.kind=="gohma": boss=enemy
	await press("target")
	await seconds(.5)
	# Fight using the same held movement and discrete action inputs as gameplay.
	var elapsed_frames=0
	var captured_stun=false
	for i in range(7200):
		if world.state.gohma or world.state.health<=0: break
		var flat:Vector3=boss.position-world.player.position
		flat.y=0
		var distance=flat.length()
		var desired_distance=2.2 if boss.mode=="stunned" else 4.5
		Input.action_press("forward",1.0 if distance>desired_distance+.3 else 0.0)
		Input.action_press("back",1.0 if distance<desired_distance-.4 else 0.0)
		if boss.mode=="stunned": Input.action_release("shield")
		else: Input.action_press("shield")
		if boss.mode in ["windup","ceiling"] and world.shot_cooldown<=0:
			await press("shoot")
		elif boss.mode=="stunned" and distance<2.8 and world.attack_cooldown<=0:
			await press("attack")
			if not captured_stun:
				await capture("12b-stunned-gohma")
				captured_stun=true
		else: await get_tree().physics_frame
		elapsed_frames+=1
	for action in ["forward","back","shield"]: Input.action_release(action)
	check("Combat fixture uses no death retry",world.stats.deaths==0,{"iterations":elapsed_frames,"health":world.state.health,"boss_hp":boss.health,"mode":boss.mode})
