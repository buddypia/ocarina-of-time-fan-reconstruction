extends "res://tests/world_playthrough.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	scope="Explicit post-awakening equipment fixture. Native input through Kakariko graveyard, Dampe race, Hookshot acquisition and physical grapple, time stone, windmill, shields, songs and isolated negative contracts. Full game, exact original layout and final visual quality incomplete."
	await frames(25)
	world.start_game()
	for key in ["sword","shield","ocarina","ocarina_of_time","adult","master_sword","light_medallion","castle_escape","emerald","ruby","sapphire","zelda_letter","mountain_pass"]: world.state[key]=true
	world.state.songs=["lullaby","saria","epona","time"]
	world.state.health=12
	world.state.max_health=12
	world.state.time_of_day=.40
	world.apply_state()
	if "--dungeon" in OS.get_cmdline_user_args():
		scope="Explicit acquired-Hookshot adult fixture for grapple collisions, tomb combat, songs, shield and repeat race. Initial acquisition is not tested in this mode."
		world.state.hookshot=true
		world.state.windmill_heart=true
		world.state.heart_pieces=1
		world.state.songs.append("storms")
		world.overworld.enter("windmill")
		await hook_contract()
		if "--capture-only" in OS.get_cmdline_user_args():
			scope="Explicit adult Hookshot fixture: visible shot, pause, ledge pull, wall obstruction, damage and scene cleanup. No acquisition or race acceptance in this mode."
			await finish()
			return
		await side_graves()
		await repeat_race()
		await views()
		await finish()
		return
	if "--capture-only" in OS.get_cmdline_user_args():
		scope="Prepared adult Market and graveyard rendering fixture: approach, tombs and equipment inspection only. No race progression acceptance."
		world.overworld.enter("market")
		await seconds(.5)
		check("The adult arrival text describes the ruined market",world.message_label.text.contains("dead roam"))
		await capture("80-ruined-market")
		world.overworld.enter("graveyard")
		await seconds(1)
		await capture("80-graveyard-approach")
		await views()
		await finish()
		return
	world.overworld.enter("market")
	await seconds(.5)
	check("Adult market has ruined buildings and ReDead instead of child shopkeepers",world.creatures.size()==3 and not world.npc_nodes.has("malon_market"))
	await capture("80-ruined-market")
	world.overworld.enter("kakariko")
	check("Adult Kakariko shelters former market residents",world.npc_nodes.has("market_refugee") and world.npc_nodes.has("graveyard_witness"))
	await walk(Vector3(0,0,20))
	await walk(Vector3(19.7,0,19))
	await press("interact")
	check("The eastern village path enters the graveyard",world.area=="graveyard")
	await capture("81-graveyard-approach")
	await walk(Vector3(-3,0,20))
	await walk(Vector3(-3,0,4.2))
	await walk(Vector3(-11,0,4.2))
	await press("interact")
	check("Pulling Dampe's stone persists the opened grave",world.state.opened_graves.has("dampe") and world.graveyard.graves.dampe.node.position.z<2)
	await press("interact")
	check("The opened grave leads to the underground race",world.area=="dampe_race")
	await walk(Vector3(0,0,6.5))
	await press("interact")
	check("The lantern starts the race",world.graveyard.race=="running")
	await seconds(.5)
	await press("pause")
	var frozen=world.graveyard.timer
	var ghost_at:Vector3=world.graveyard.ghost.position
	await seconds(.5)
	check("Pause freezes the race and the guide",world.graveyard.timer==frozen and world.graveyard.ghost.position==ghost_at)
	check("An active race cannot be stored as an ambiguous partial save",not world.save_game())
	await press("pause")
	await seconds(28)
	check("Losing the guide closes a gate and fails the attempt",world.graveyard.race=="failed" and not world.state.dampe_won and not world.state.hookshot)
	await press("interact")
	check("E after failure rebuilds a clean starting course",world.graveyard.race=="idle" and world.player.position.z>9 and world.graveyard.fires.is_empty())
	await race_route()
	if not world.state.dampe_won:
		await capture("failed-race")
		await finish()
		return
	await capture("82-race-finish")
	await walk(Vector3(-1,0,-90.8))
	await press("interact")
	check("Completing the physical course unlocks the Hookshot chest",world.state.hookshot)
	await press("save")
	world.load_game()
	check("Reload restores the acquired Hookshot without an active race",world.state.hookshot and world.graveyard.race=="idle" and not is_instance_valid(world.active_hook))
	await walk(Vector3(1.5,0,-90))
	await press("interact")
	check("The time stone blocks the windmill exit before its melody",world.area=="dampe_race" and not world.state.race_time_block)
	await play_notes(["left","up","right","left","up","right"])
	check("Another royal song cannot move the time stone",not world.state.race_time_block)
	await play_notes(["right","a","down","right","a","down"])
	check("Song of Time removes the block and its collision",world.state.race_time_block and not world.graveyard.time_block.visible)
	await press("interact")
	check("The passage emerges on the windmill's upper gallery",world.area=="windmill" and world.player.position.y>3)
	await walk(Vector3(5,3,-5.8))
	await press("interact")
	check("The upper windmill chest grants one quarter heart",world.state.windmill_heart and world.state.heart_pieces==1)
	await press("interact")
	check("Reopening a heart chest does not duplicate its reward",world.state.heart_pieces==1)
	await walk(Vector3(5,0,-1))
	await walk(Vector3(3,0,4))
	await press("interact")
	check("The adult windmill keeper teaches the Song of Storms",world.state.songs.has("storms"))
	await capture("83-windmill")
	await hook_contract()
	await side_graves()
	await repeat_race()
	await views()
	await finish()

func race_route() -> void:
	await walk(Vector3(0,0,6.5))
	await press("interact")
	for i in range(1,world.graveyard.data.race.route.size()):
		if world.graveyard.race!="running": break
		await walk(world.vec(world.graveyard.data.race.route[i]))
	for i in range(50):
		if world.graveyard.race!="running": break
		await seconds(.1)
	check("Traversing every passage reaches Dampe before the closing gates",world.graveyard.race=="finished" and world.state.dampe_won)

func hook_contract() -> void:
	# Start on the windmill floor; the wooden anchor is an actual colliding target.
	await walk(Vector3(-5,0,3))
	world.player.lock_target=null
	world.player.yaw=0
	world.player.visual.rotation.y=0
	await press("target")
	check("Q acquires the nearby wooden grappling plate",is_instance_valid(world.player.lock_target) and world.player.lock_target.has_meta("hook_landing"))
	await press("shoot")
	check("R launches a visible physical grappling head",is_instance_valid(world.active_hook))
	await press("pause")
	var hook_at:Vector3=world.active_hook.position
	await seconds(.3)
	check("A paused Hookshot remains at the same position",world.active_hook.position==hook_at)
	check("Saving during an active Hookshot is rejected",not world.save_game())
	await press("pause")
	await seconds(2)
	check("The hook pulls the adult capsule onto the upper ledge",world.player.position.y>2.9 and world.player.position.z<-3 and not is_instance_valid(world.active_hook) and not world.player.hook_pulling,{"position":str(world.player.position),"hook_active":is_instance_valid(world.active_hook)})
	await capture("84-hookshot-ledge")
	# An explicit obstruction contract creates a wall between a target and Link.
	world.player.position=Vector3(-5,0,3)
	var barrier=ForestArt.collision_box(world.landscape,Vector3(-5,2,0),Vector3(5,4,.5))
	await frames(5)
	await press("shoot")
	await seconds(1.5)
	check("Stone blocks the flying hook and prevents a pull through a wall",world.player.position.z>2 and world.player.position.y<.2 and not is_instance_valid(world.active_hook))
	barrier.queue_free()
	await frames(5)
	# Target is still visible to Q beyond fourteen metres, but the shot must retract.
	world.player.position=Vector3(-5,0,9.8)
	await frames(5)
	await press("shoot")
	await seconds(1.6)
	check("An out-of-range wooden target cannot pull Link beyond fourteen metres",world.player.position.z>9 and world.player.position.y<.2 and not is_instance_valid(world.active_hook))
	world.player.position=Vector3(-5,0,3)
	await frames(5)
	await press("shoot")
	await seconds(.15)
	world.damage_player(1,world.player.position+Vector3.RIGHT,false)
	check("Damage cancels the hook and releases the movement state",not is_instance_valid(world.active_hook) and not world.player.hook_pulling)
	await press("shoot")
	world.overworld.enter("graveyard")
	check("Changing scene cleans up the projectile, chain and pull state",not is_instance_valid(world.active_hook) and not world.player.hook_pulling and world.graveyard.targets.size()==1)

func side_graves() -> void:
	# Explicit era contract: child daytime cannot disturb a grave; night can.
	world.state.adult=false
	world.state.time_of_day=.4
	world.apply_state()
	await press("shoot")
	check("Owning a Hookshot does not let the child fire adult equipment",not is_instance_valid(world.active_hook))
	world.player.position=Vector3(10,0,9.2)
	await frames(5)
	await press("interact")
	check("A child cannot pull the soldier's grave in daylight",not world.state.opened_graves.has("soldier"))
	world.state.time_of_day=.85
	await press("interact")
	check("Night permits the child to open the soldier's grave",world.state.opened_graves.has("soldier"))
	await press("interact")
	await walk(Vector3(0,0,-3.8))
	await press("interact")
	check("The soldier's chest gives a persistent Hylian Shield",world.state.hylian_shield)
	world.state.adult=true
	world.apply_state()
	Input.action_press("shield")
	await frames(4)
	check("The adult equips the steel shield and can block a frontal attack",world.player.shield.visible and world.player.shield.scene_file_path.ends_with("hylian_shield.glb") and world.can_block(world.player.position-world.player.visual.basis.z))
	Input.action_release("shield")
	await capture("85-hylian-shield")
	world.overworld.enter("graveyard")
	world.player.position=Vector3(0,.5,-19.3)
	await frames(5)
	await press("interact")
	check("The royal tomb starts closed",world.area=="graveyard" and not world.state.royal_tomb_open)
	await play_notes(["left","up","right","left","up","right"])
	await press("interact")
	check("Zelda's Lullaby opens the royal tomb",world.area=="royal_tomb" and world.state.royal_tomb_open)
	check("The bat chamber has a visible sealed grille",world.graveyard.tomb_gate.visible and world.graveyard.tomb_gate.collision_layer==1)
	await walk(Vector3(3,0,0))
	for attempt in range(55):
		var bats=0
		for enemy in world.creatures:
			if enemy.kind=="keese" and enemy.mode!="dead": bats+=1
		if bats==0: break
		world.player.lock_target=null
		await press("target")
		await seconds(.2)
		await press("shoot")
		await press("attack")
		await seconds(.9)
	check("Approaching and fighting defeats the tomb bats with actual Hookshot hits",world.graveyard.tomb_gate.collision_layer==0 and world.stats.get("hook_hits",0)>0,{"enemies":world.creatures.map(func(enemy): return {"kind":enemy.kind,"health":enemy.health,"at":str(enemy.position)})})
	check("Defeating the bats removes both the grille and its collision",not world.graveyard.tomb_gate.visible and world.graveyard.tomb_gate.collision_layer==0)
	world.player.lock_target=null
	await walk(Vector3(3,0,10))
	await walk(Vector3(3,0,-14))
	await walk(Vector3(0,0,-15.8))
	await press("interact")
	check("The composers' inscription teaches the Sun's Song",world.state.songs.has("sun"))
	await play_notes(["right","down","up","right","down","up"])
	var still=false
	for enemy in world.creatures:
		if enemy.kind=="redead": still=enemy.stunned>10
	check("The Sun's Song stills the ReDead",still)
	await capture("86-composers-tomb")
	world.overworld.enter("heart_grave")
	await play_notes(["right","down","up","right","down","up"])
	await walk(Vector3(3,0,5))
	await walk(Vector3(3,0,-3.8))
	await walk(Vector3(0,0,-3.8))
	await press("interact")
	check("Sun's Song reveals the hidden heart chest",world.state.grave_heart and world.state.heart_pieces==2)

func repeat_race() -> void:
	world.state.health=world.state.max_health
	world.overworld.enter("dampe_race")
	await race_route()
	await walk(Vector3(0,0,-89))
	await press("interact")
	check("A repeat race under sixty seconds grants its single heart piece",world.graveyard.timer<=60 and world.state.race_heart and world.state.heart_pieces==3)
	await press("interact")
	check("The race heart cannot be awarded twice",world.state.heart_pieces==3)
	await press("save")
	world.load_game()
	check("Save preserves the shield, both songs, hook, records and heart pieces",world.state.hylian_shield and world.state.hookshot and world.state.songs.has("sun") and world.state.songs.has("storms") and world.state.heart_pieces==3 and world.state.race_best>0)
	# Explicit counter-boundary fixture; the preceding earned save stays intact.
	var maximum=world.state.max_health
	world.state.windmill_heart=false
	world.overworld.enter("windmill")
	world.player.position=Vector3(5,3,-5.8)
	await frames(5)
	await press("interact")
	check("An isolated fourth-piece chest awards one full heart and resets the counter",world.state.max_health==maximum+2 and world.state.heart_pieces==0)
	world.load_game()
	check("The earned save remains intact after the counter-boundary fixture",world.state.max_health==maximum and world.state.heart_pieces==3 and world.state.windmill_heart)

func views() -> void:
	world.overworld.enter("graveyard")
	world.player.enabled=false
	world.message_panel.hide()
	var camera=Camera3D.new()
	world.add_child(camera)
	camera.current=true
	camera.fov=48
	for shot in [["87-graves-close",Vector3(-10,2.2,8),Vector3(-11,.8,3)],["88-royal-tomb",Vector3(7,5,-8),Vector3(0,2,-21)]]:
		camera.position=shot[1]
		camera.look_at(shot[2])
		await frames(4)
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(output+"/"+shot[0]+".png")
	var equipment=load("res://assets/hookshot.glb").instantiate()
	world.player.position=Vector3(10,0,17)
	world.landscape.add_child(equipment)
	equipment.position=Vector3(0,1.2,16)
	equipment.rotation=Vector3(PI/2,0,.2)
	var lowest=INF
	for mesh in equipment.find_children("*","MeshInstance3D",true,false):
		var bounds:AABB=mesh.global_transform*mesh.get_aabb()
		lowest=minf(lowest,bounds.position.y)
	equipment.position.y+=1.242-lowest
	preload("res://scripts/grave_art.gd").dressed(world.landscape,Vector3(0,.62,16),Vector3(1.8,1.24,1.1))
	for shot in [["89-hookshot-mechanism",Vector3(.8,1.95,16.8)],["90-hookshot-reel",Vector3(-.75,1.9,15.7)]]:
		camera.position=shot[1]
		camera.look_at(Vector3(0,1.52,16))
		await frames(4)
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(output+"/"+shot[0]+".png")
	camera.queue_free()
	world.player.camera.current=true
