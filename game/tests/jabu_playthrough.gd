extends "res://tests/zora_playthrough.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	await frames(30)
	world.start_game()
	if "--fixture" in OS.get_cmdline_user_args():
		scope="Post-water equipment fixture. Jabu route uses movement and action input without granting Jabu progression; combat target selection is assisted by direct lock assignment. Failure contracts use explicit setup. Authored layout, full game and final visual quality incomplete."
		for key in ["sword","shield","slingshot","ocarina","bracelet","bomb_bag","ruby","emerald","silver_scale","letter_delivered","jabu_open"]: world.state[key]=true
		world.state.max_health=10
		world.state.health=10
		world.state.seeds=30
		world.state.bomb_count=20
		world.overworld.enter("fountain")
		world.player.position=Vector3(0,0,5.6)
		await frames(10)
		await press("interact")
		check("The opened guardian mouth enters the authored interior",world.area=="jabu_mouth")
	else:
		scope="New journey through existing forest, mountain and water routes, followed by authored Jabu route with assisted combat target selection. Full game incomplete."
		await forest_route()
		await dungeon_route()
		await world_route()
		await mountain_route()
		await walk(Vector3(0,3,5))
		await walk(Vector3(0,0,27))
		await press("interact")
		await walk(Vector3(0,0,25))
		await press("interact")
		await water_route()
		await press("interact")
	if "--dungeon" in OS.get_cmdline_user_args() and "--fixture" in OS.get_cmdline_user_args():
		scope="Explicit Jabu combat fixture: boomerang, rescued Ruto and roots prepared. Two bosses and failure contracts only; not a progression playthrough."
		world.state.boomerang=true
		world.state.ruto_met=true
		world.state.ruto_rescued=true
		world.state.ruto_room="octo"
		world.state.ruto_position=[0,0,3]
		world.state.jabu_tentacles=["west","east","north"]
		world.jabu.enter("octo")
		world.carried_person=world.jabu.ruto
		await octo_route()
		if not world.state.big_octo or world.area!="jabu_barinade": await finish(); return
		await barinade_route()
		await jabu_contracts()
		await finish()
		return
	await core_route()
	if "--capture-only" in OS.get_cmdline_user_args():
		await finish()
		return
	await roots_route()
	await octo_route()
	if not world.state.big_octo or world.area!="jabu_barinade": await finish(); return
	await barinade_route()
	await jabu_contracts()
	await finish()

func walk(destination:Vector3) -> void:
	world.player.lock_target=null
	await super.walk(destination)

func core_route() -> void:
	await seconds(.5)
	await capture("50-mouth")
	await walk(Vector3(0,0,-9))
	await press("interact")
	check("Entry membrane blocks the untreated passage",world.area=="jabu_mouth")
	await walk(Vector3(0,0,0))
	await press("target")
	check("Q focuses the ceiling membrane",world.player.lock_target==world.jabu.targets.mouth)
	await press("shoot")
	await seconds(.8)
	check("A physical seed releases the entry membrane","mouth" in world.state.jabu_switches)
	await passage("lift")
	await passage("holes")
	await walk(Vector3(-4,0,-1))
	await press("interact")
	check("Ruto falls toward the tidal pocket after the first conversation",world.state.ruto_met and world.state.ruto_room=="water")
	await passage("water")
	await walk(Vector3(-4,0,2))
	await press("interact")
	check("Speaking to Ruto establishes the rescue",world.state.ruto_rescued)
	await press("interact")
	check("Interaction lifts Ruto",is_instance_valid(world.carried_person))
	await capture("51-ruto-carry")
	await walk(Vector3(-4,0,2))
	await walk(Vector3(4,0,2))
	await walk(Vector3(4,0,0))
	check("The pressure nodule raises the return passage","water" in world.state.jabu_switches)
	await seconds(1.4)
	check("Water surface and swimming height rise together",world.jabu.water_height>-.1 and absf(world.water_zones[0].height-world.jabu.water_surface.position.y)<.01)
	await walk(Vector3(4,0,-7))
	await passage("lift")
	check("Ruto remains carried across the room boundary",is_instance_valid(world.carried_person) and world.state.ruto_room=="lift")
	await passage("holes")
	await passage("fork")
	await passage("stingers",false)
	check("The eastern weight seal rejects an empty nodule",world.area=="jabu_fork")
	await walk(Vector3(7,0,2))
	# Face inward so the set-down position remains on the pressure nodule.
	world.player.visual.rotation.y=PI/2
	await press("interact")
	await seconds(.25)
	check("Putting Ruto on the nodule opens the eastern seal","east_door" in world.state.jabu_switches and not is_instance_valid(world.carried_person))
	await capture("52-weight-seal")
	await passage("stingers")
	await small_fight()
	await walk(Vector3(0,0,-7))
	await press("interact")
	check("Four Stingers defeated before the boomerang chest opens",world.state.boomerang and world.jabu.living_enemies()==0)
	await capture("53-boomerang")
	await passage("fork")
	check("Ruto waits at the nodule after the side-room encounter",is_instance_valid(world.jabu.ruto) and world.jabu.ruto.position.distance_to(Vector3(7,0,2))<1.2)

func passage(destination:String, expect:bool=true) -> void:
	for entry in world.jabu.data.rooms[world.jabu.room].exits:
		if entry[0]!=destination: continue
		var at=Vector3(entry[1],entry[2],entry[3]).move_toward(Vector3.ZERO,.9)
		await walk(at)
		await press("interact")
		await frames(8)
		if expect: check("Passage reaches "+destination,world.area=="jabu_"+destination)
		return
	check("Requested passage exists: "+destination,false)

func small_fight() -> void:
	for enemy in world.creatures.duplicate():
		if not is_instance_valid(enemy) or enemy.mode=="dead": continue
		for attempt in range(12):
			if enemy.mode=="dead" or world.state.health<=0: break
			if world.state.boomerang:
				await boom(enemy)
			else:
				var approach:Vector3=enemy.position+Vector3(0,0,1.3)
				await walk(approach)
				for tick in range(300):
					if enemy.mode=="exposed": break
					await get_tree().physics_frame
				world.player.lock_target=enemy
				await frames(5)
				await press("attack")
				await seconds(.52)
		check("Defeat "+enemy.enemy_id,enemy.mode=="dead",{"health":world.state.health,"mode":enemy.mode,"enemy_hp":enemy.health})

func boom(enemy:Node3D) -> void:
	world.player.lock_target=enemy
	await frames(3)
	await press("boomerang")
	for i in range(300):
		if not is_instance_valid(world.active_boomerang): break
		await get_tree().physics_frame
	await seconds(.12)

func roots_route() -> void:
	for root in ["west","east","north"]:
		await passage(root)
		await walk(Vector3(0,0,1.8))
		for enemy in world.creatures.duplicate():
			if enemy.kind=="biri": await boom(enemy)
		var tentacle=world.creatures[0]
		for attempt in range(12):
			if tentacle.mode=="dead": break
			for tick in range(240):
				if tentacle.mode=="exposed": break
				await get_tree().physics_frame
			await boom(tentacle)
		check("Sever "+root+" root with returning weapon",root in world.state.jabu_tentacles)
		await capture("54-root-"+root)
		await passage("fork")
	await passage("bubbles")
	await small_fight()
	await seconds(.2)
	check("Timed bubble chamber grants compass",world.state.jabu_compass)
	await passage("fork")
	await walk(Vector3(6.3,0,2))
	await press("interact")
	check("Ruto can be collected again",is_instance_valid(world.carried_person))
	await passage("holes")
	await passage("octo")

func octo_route() -> void:
	await walk(Vector3(0,0,0))
	await press("interact")
	check("Ruto's altar starts Big Octo encounter",world.state.ruto_altar and world.creatures.size()==1)
	var boss=world.creatures[0]
	for attempt in range(24):
		if boss.mode=="dead" or world.state.health<=0: break
		await boom(boss)
		if boss.mode!="stunned": continue
		var rear=boss.position+boss.body.global_basis.z*2.1
		await walk(rear)
		world.player.lock_target=boss
		await frames(8)
		await press("attack")
		await seconds(.6)
	check("Big Octo requires rear openings and is defeated",world.state.big_octo,{"boss_hp":boss.health,"player_hp":world.state.health})
	await capture("55-octo")
	if not world.state.big_octo: return
	await passage("jigglies")
	for z in [2,-3]:
		await walk(Vector3(0,0,z+2.3))
		await boom(world.jabu.targets["pad_"+str(z)])
		await walk(Vector3(0,0,z-1.7))
	check("Both trembling pads can be crossed after boomerang stun",world.player.position.z< -4)
	await capture("56-trembling-bridge")
	await passage("near_boss")
	check("Upper route lowers shortcut back to the lift",world.state.jabu_lift_lowered)
	await walk(Vector3(-3.4,0,-2))
	await boom(world.jabu.targets.final)
	check("Curved flight reaches the protected inner switch","final" in world.state.jabu_switches)
	await capture("57-inner-seal")
	await walk(Vector3(-3.4,0,-8))
	await passage("barinade")

func barinade_route() -> void:
	var boss=world.creatures[0]
	await capture("58-barinade-attached")
	await walk(Vector3(0,0,4))
	for link in boss.links: await boom(link)
	check("Three ceiling connections sever independently",boss.mode=="orbit")
	await capture("58b-biri-ring")
	for attempt in range(20):
		if world.state.barinade or world.state.health<=0: break
		if boss.mode=="orbit":
			for biri in boss.orbiters:
				if biri.mode!="dead": await boom(biri)
			await seconds(.2)
		elif boss.mode in ["exposed","charge"]:
			await boom(boss)
			if boss.mode=="stunned":
				if boss.health==9: await capture("58c-barinade-opening")
				await walk(boss.position+Vector3(0,0,2.65))
				world.player.lock_target=boss
				await frames(8)
				for hit in range(2):
					await press("attack")
					await seconds(.55)
				await walk(Vector3(0,0,4.5))
		else: await seconds(.25)
	check("Barinade defeated through links, two Biri waves and stunned openings",world.state.barinade,{"boss_hp":boss.health,"mode":boss.mode,"player_hp":world.state.health,"wave":boss.wave})
	await capture("59-barinade-defeated")
	await walk(Vector3(0,0,-3))
	await press("interact")
	check("Ruto awards Sapphire and heart container at the Fountain",world.area=="fountain" and world.state.sapphire and world.state.max_health==12)
	await capture("60-sapphire")

func jabu_contracts() -> void:
	await press("save")
	var saved=world.state.duplicate(true)
	world.load_game()
	check("Sapphire and all roots survive saved-journey reload",world.state.sapphire and world.state.jabu_tentacles.size()==3)
	world.jabu.enter("barinade")
	world.player.position=Vector3(0,0,-3)
	await frames(10)
	await press("interact")
	check("Repeat reward cannot duplicate the heart container",world.state.max_health==12)
	world.jabu.enter("near_boss")
	world.state.jabu_switches.erase("final")
	world.jabu.targets.final.spent=false
	world.player.position=Vector3(0,0,0)
	world.player.lock_target=world.jabu.targets.final
	await frames(5)
	await press("shoot")
	await seconds(.6)
	check("Straight seed cannot cross the protective fold","final" not in world.state.jabu_switches)
	world.player.position=Vector3(-3.4,0,-2)
	await press("boomerang")
	await frames(8)
	await press("pause")
	var active=world.active_boomerang
	var paused_at:Vector3=active.position
	var paused_age:float=active.age
	await seconds(.3)
	await press("boomerang")
	check("Pause freezes boomerang flight and rejects another throw",active==world.active_boomerang and active.position==paused_at and active.age==paused_age)
	await press("pause")
	for i in range(300):
		if not is_instance_valid(world.active_boomerang): break
		await get_tree().physics_frame
	check("Resumed boomerang returns and clears the active slot",not is_instance_valid(world.active_boomerang))
	world.jabu.targets.final.spent=false
	world.state.jabu_switches.erase("final")
	world.player.position=Vector3(0,0,0)
	await boom(world.jabu.targets.final)
	check("A centered boomerang hits the broad fold and cannot trigger the switch","final" not in world.state.jabu_switches)
	world.player.position=Vector3(-3.4,0,-2)
	world.player.lock_target=world.jabu.targets.final
	await press("boomerang")
	var first=world.active_boomerang
	await press("boomerang")
	check("Only one returning weapon may be in flight",first==world.active_boomerang)
	world.jabu.enter("lift")
	await frames(5)
	check("Room transitions remove in-flight weapons and release the slot",not is_instance_valid(first) and not is_instance_valid(world.active_boomerang))
	world.state.ruto_altar=false
	world.state.ruto_rescued=true
	world.state.ruto_room="fork"
	world.state.ruto_position=[0,0,4]
	world.jabu.enter("fork")
	world.player.position=Vector3(0,0,4)
	await frames(8)
	await press("interact")
	await press("save")
	world.load_game()
	await frames(10)
	check("Save while carrying restores Ruto into the same room safely",world.area=="jabu_fork" and is_instance_valid(world.jabu.ruto) and world.jabu.ruto.position.y>=0 and not is_instance_valid(world.carried_person))
	world.player.position=world.jabu.ruto.position
	await frames(8)
	await press("interact")
	var seeds=world.state.seeds
	Input.action_press("shield")
	await press("shoot")
	check("Carrying prevents shooting and shield protection",world.state.seeds==seeds and not world.can_block(world.player.position-world.player.visual.basis.z))
	Input.action_release("shield")
	world.player.invulnerable=0
	world.damage_player(100,world.player.position+Vector3.RIGHT,false)
	await press("interact")
	check("Death retry restores the room and leaves Ruto recoverable",world.player.enabled and world.state.health==world.state.max_health and is_instance_valid(world.jabu.ruto))
	world.carried_person=null
	world.state.ruto_room="water"
	world.state.ruto_position=[-4,0,2]
	world.jabu.enter("water")
	world.player.position=Vector3(-4,0,2)
	await frames(8)
	await press("interact")
	check("Ruto is carried before the pool throw",is_instance_valid(world.carried_person))
	await walk(Vector3(-4,0,-2))
	world.player.visual.rotation.y=-PI/2
	await press("boomerang")
	await seconds(1.8)
	check("Ruto thrown into the pool returns to the safe ledge",is_instance_valid(world.jabu.ruto) and not is_instance_valid(world.carried_person) and world.jabu.ruto.position.distance_to(Vector3(-4,0,2))<.15,{"actual":str(world.jabu.ruto.position),"carried":is_instance_valid(world.carried_person)})
	await walk(Vector3(-4,0,2))
	await press("interact")
	await walk(Vector3(-4,0,-2))
	await walk(Vector3(-1,-1.5,-2))
	await seconds(.8)
	check("Falling into water starts swimming and releases carried Ruto safely",world.player.swimming and not is_instance_valid(world.carried_person) and world.jabu.ruto.position.distance_to(Vector3(-4,0,2))<.15)
	await walk(Vector3(0,-1.5,0))
	await walk(Vector3(3.8,0,0))
	await seconds(.2)
	check("The inner pool ramp returns the swimmer to dry floor",not world.player.swimming and world.player.position.y>-.1)
	await capture("61-tidal-return")
	world.state.jabu_compass=false
	world.jabu.enter("bubbles")
	world.jabu.bubble_time=.05
	await seconds(.15)
	check("Bubble deadline expires without granting compass",world.jabu.bubble_time==0 and not world.state.jabu_compass)
	world.jabu.enter("fork")
	world.jabu.enter("bubbles")
	check("Reentering failed bubble room resets its challenge",world.jabu.bubble_time>35 and world.jabu.living_enemies()==9)
	world.state.barinade=false
	world.jabu.enter("barinade")
	var protected_boss=world.creatures[0]
	world.player.position=protected_boss.position+Vector3(0,0,2.5)
	world.player.lock_target=protected_boss
	await seconds(.3)
	await press("attack")
	await press("shoot")
	await seconds(.6)
	check("Sword and seed cannot bypass Barinade's ceiling phase",protected_boss.health==9 and protected_boss.mode=="attached")
	await press("bomb")
	await press("bomb")
	await walk(Vector3(0,0,6))
	await seconds(4)
	check("Bomb blasts cannot bypass Barinade's ceiling phase",protected_boss.health==9 and protected_boss.mode=="attached")
	world.state.big_octo=false
	world.state.ruto_altar=true
	world.jabu.enter("octo")
	var octo=world.creatures[0]
	octo.mode="stunned"
	octo.timer=4
	world.player.position=octo.position-octo.body.global_basis.z*2.1
	world.player.lock_target=octo
	await seconds(.35)
	await press("attack")
	check("A stunned Big Octo still rejects a frontal sword strike",octo.health==4)
	world.state=saved
	world.overworld.enter("fountain")
