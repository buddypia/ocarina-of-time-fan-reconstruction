extends "res://tests/bomb_combat.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	scope="New journey through the authored forest, Deku Tree, castle, ranch, mountain and Dodongo's Cavern to Goron's Ruby. Full game incomplete."
	await frames(30)
	world.start_game()
	if "--capture-only" in OS.get_cmdline_user_args():
		scope="Direct scene entry and rendered camera inspection fixture; does not establish progression."
		for place in ["kakariko","trail","goron"]:
			world.overworld.enter(place)
			await frames(30)
			await capture("view-"+place)
		for entrance in ["goron","dodongo"]:
			world.state.cavern_open=true
			world.overworld.enter("trail",entrance)
			await frames(30)
			await capture("view-trail-from-"+entrance)
		for room in ["cavern","duel","stairs","gallery","armory","skull","king"]:
			world.dodongo.enter(room)
			await frames(30)
			await capture("view-"+room)
		await finish()
		return
	if "--fixture" in OS.get_cmdline_user_args():
		scope="Mountain route from an explicit post-castle equipment and song fixture; no mountain or cavern solutions granted. Full game incomplete."
		for key in ["sword","shield","mido","saria","slingshot","gohma","emerald","ocarina","zelda_letter","bottle"]: world.state[key]=true
		world.state.songs=["lullaby","epona","saria"]
		world.state.milk=2
		world.state.max_health=8
		world.state.health=8
		world.state.seeds=30
		world.apply_state()
	else:
		await forest_route()
		await dungeon_route()
		await world_route()
	await mountain_route()
	await finish()

func mountain_route() -> void:
	await walk(Vector3(-12,0,5))
	await walk(Vector3(-22,0,7))
	await walk(Vector3(-24,0,7))
	await press("interact")
	await walk(Vector3(32,0,25))
	await walk(Vector3(17,0,4))
	await walk(Vector3(13,0,-28))
	await walk(Vector3(47.5,0,-41))
	await press("interact")
	check("The eastern field road reaches Kakariko",world.area=="kakariko")
	await capture("19-kakariko")
	for at in [Vector3(-8,0,15),Vector3(-1,0,8),Vector3(6,0,1)]:
		await walk(at)
		await press("interact")
	await walk(Vector3(8,0,0))
	check("Village pickup contributes twenty spendable rupees", "village_stash" in world.state.world_collected)
	await walk(Vector3(0,0,12))
	await walk(Vector3(-7,0,17.5))
	await press("interact")
	check("Three rescued cuccos receive Anju's one-time reward",world.state.cuccos.size()==3 and world.state.cucco_reward and world.state.rupees>=40)
	await walk(Vector3(0,0,12))
	await walk(Vector3(0,0,-18))
	await walk(Vector3(1.3,0,-20))
	await press("interact")
	check("The royal letter opens the mountain gate",world.state.mountain_pass and world.mountain.gate.collision_layer==0)
	await walk(Vector3(0,0,-25))
	await press("interact")
	check("The open gate connects to Death Mountain Trail",world.area=="trail")
	await ascend_trail()
	await capture("20-mountain-climb")
	check("The three trail ramps reach the upper ledge",absf(world.player.position.y-9)<.35)
	await press("interact")
	check("The high trail enters Goron City",world.area=="goron")
	await walk(Vector3(0,0,-7.5))
	await play_notes(["left","up","right","left","up","right"])
	check("Playing the learned royal melody opens Darunia's door",world.state.darunia_door)
	await walk(Vector3(0,0,-19.5))
	await press("interact")
	await play_notes(["down","right","left","down","right","left"])
	check("Saria's Song earns the bracelet from Darunia",world.state.bracelet and world.player.arm_band.visible)
	await capture("21-darunia")
	await walk(Vector3(0,0,22.6))
	await press("interact")
	await walk(Vector3(0,9,-19.5))
	await walk(Vector3(12,6,-8))
	await walk(Vector3(12,6,-3))
	await walk(Vector3(3,3,5))
	await walk(Vector3(-4.1,3,5))
	await press("interact")
	check("The bracelet lifts a live Bomb Flower",is_instance_valid(world.held_bomb))
	# Carry toward the quarry and turn along the westward stone bridge before throwing.
	await walk(Vector3(-6.3,3,3.3))
	await press("bomb")
	await walk(Vector3(-3,3,5))
	await seconds(4)
	check("A thrown flower's blast opens the cracked quarry rock",world.state.cavern_open and world.stats.rocks_broken==1)
	await capture("22-quarry-open")
	await walk(Vector3(-9,3,2))
	await walk(Vector3(-11,3,2))
	await press("interact")
	check("The opened quarry leads into Dodongo's Cavern",world.area=="dodongo_cavern")
	await capture("23-dodongo-cavern")
	await cavern_route()

func ascend_trail() -> void:
	await walk(Vector3(0,3,5))
	await walk(Vector3(3,3,5))
	await walk(Vector3(12,6,-3))
	await walk(Vector3(12,6,-8))
	await walk(Vector3(0,9,-22.7))

func cavern_route() -> void:
	await walk(Vector3(8,0,8))
	await walk(Vector3(12,0,1))
	await press("interact")
	check("The eastern cavern passage reaches the Lizalfos hall",world.area=="dodongo_duel")
	await lizalfos_fight()
	check("Both Lizalfos must fall to release the staircase passage",world.state.dodongo_duel)
	await capture("24-lizalfos-hall")
	await walk(Vector3(0,0,-9))
	await press("interact")
	await walk(Vector3(-5.4,0,4.5))
	await press("interact")
	await walk(Vector3(0,0,1.5))
	await walk(Vector3(0,0,.8))
	await press("bomb")
	await walk(Vector3(0,0,3.5))
	await seconds(4.5)
	check("A central explosion sets off both ends of the flower row",world.state.dodongo_stairs)
	await capture("25-bomb-flower-stairs")
	await walk(Vector3(0,3,-11))
	check("Unsealed staircase is physically climbable",world.player.position.y>2.2)
	await press("interact")
	check("The staircase reaches the molten gallery",world.area=="dodongo_gallery")
	await walk(Vector3(-7,0,3))
	await walk(Vector3(-7,2,-6))
	await walk(Vector3(4,2,-7.3))
	check("Gallery ramps meet the raised far platform",absf(world.player.position.y-2)<.35)
	await press("target")
	await press("shoot")
	await seconds(.5)
	await press("target")
	check("A seed hits the gallery eye through the firing line", "gallery" in world.state.dodongo_switches)
	await capture("26-molten-gallery")
	await press("interact")
	check("The eye releases the armory door",world.area=="dodongo_armory")
	await walk(Vector3(0,0,-2))
	await walk(Vector3(0,1.2,-5.8))
	await press("interact")
	check("The altar chest grants a usable bag of twenty bombs",world.state.bomb_bag and world.state.bomb_count==20)
	await capture("27-bomb-bag")
	await walk(Vector3(0,0,-2))
	await walk(Vector3(-8,0,2))
	await walk(Vector3(-9,0,0))
	await press("interact")
	check("The armory connects to the giant skull bridge",world.area=="dodongo_skull")
	await walk(Vector3(0,4,-4))
	check("The skull's crown is reached by its stone ramp",absf(world.player.position.y-4)<.35)
	for side in [-1,1]:
		await walk(Vector3(side*4,4,-5.3))
		# Face into the socket with a short forward step before placing the bomb.
		await walk(Vector3(side*4,4,-5.8))
		await press("bomb")
		await press("interact")
		await walk(Vector3(side*4,4,-2.8))
		await seconds(4)
		check("Placed bomb lights skull eye "+str(side),str(side) in world.state.dodongo_eyes)
	await capture("28-skull-eyes")
	await walk(Vector3(0,4,-3.5))
	await walk(Vector3(0,0,10))
	await press("interact")
	await walk(Vector3(-8,0,-8))
	await walk(Vector3(0,0,-10.9))
	await press("interact")
	check("Both eyes open the path to King Dodongo",world.area=="dodongo_king")
	await capture("29-king-dodongo")
	await king_fight()
	check("Bombs and sword openings defeat the armored king",world.state.king_dodongo and world.stats.bombs_swallowed>=3)
	await walk(Vector3(0,0,11))
	await press("interact")
	check("The portal awards the Ruby and a new heart container",world.area=="trail" and world.state.ruby and world.state.max_health==10)
	await capture("30-gorons-ruby")
	await press("save")
	var bomb_count=world.state.bomb_count
	world.state.bomb_count=0
	world.state.bracelet=false
	world.state.dodongo_eyes=[]
	world.load_game()
	check("Reload preserves mountain rewards, bomb ammunition and both eyes",world.state.ruby and world.state.bracelet and world.state.bomb_count==bomb_count and world.state.dodongo_eyes.size()==2 and world.area=="trail")
	await seconds(1)

func lizalfos_fight() -> void:
	for iteration in range(6500):
		if world.state.dodongo_duel or world.state.health<=0: break
		if not is_instance_valid(world.player.lock_target): await press("target")
		var enemy=world.player.lock_target
		if not is_instance_valid(enemy):
			Input.action_press("forward")
		else:
			var distance=world.player.position.distance_to(enemy.position)
			Input.action_press("forward",1 if distance>1.3 else 0)
			Input.action_press("shield")
			if distance<7 and world.shot_cooldown<=0 and enemy.mode not in ["stunned","recover"]: await press("shoot")
			if distance<1.6 and world.attack_cooldown<=0: await press("attack")
		if world.state.health<=3 and world.state.milk>0: await press("milk")
		await get_tree().physics_frame
	Input.action_release("forward")
	Input.action_release("shield")
	check("Lizalfos encounter completes without a death",world.state.dodongo_duel and world.stats.deaths==0)
