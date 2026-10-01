extends "res://tests/world_playthrough.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	scope="Explicit post-Hookshot adult fixture. Forest Temple representative scene and room construction only; full progression and final visual quality unverified."
	await frames(25)
	world.start_game()
	for key in ["sword","shield","ocarina","ocarina_of_time","adult","master_sword","light_medallion","castle_escape","emerald","ruby","sapphire","zelda_letter","mountain_pass","hookshot","hylian_shield","stones_placed","door_of_time","sword_inspected"]: world.state[key]=true
	world.state.songs=["lullaby","saria","epona","time"]
	world.state.max_health=12;world.state.health=12
	world.apply_state()
	if OS.has_environment("OOT_FOREST_SAVE"):
		scope="Resume an isolated previously earned Forest Temple stage save. Earlier acquisition is not rerun; initial fixture provenance is retained in the prior evidence. Target selection is assisted."
		world.save_path=OS.get_environment("OOT_FOREST_SAVE")
		world.load_game()
		world.save_path=output+"/test-save.json"
		scope+=" Source: "+OS.get_environment("OOT_FOREST_SAVE")
		if world.area=="ft_boss": await temple_boss_stage()
		elif world.area=="forest" and world.state.forest_medallion: await forest_epilogue()
		elif world.area=="ft_basement": await temple_basement_stage()
		elif world.area=="ft_green": await temple_green_stage()
		elif world.area=="ft_frozen": await temple_final_rooms()
		else: await temple_second_half()
		await finish();return
	if OS.get_environment("OOT_FOREST_STAGE")=="contracts":
		await failure_contracts()
		await finish();return
	if OS.get_environment("OOT_FOREST_STAGE")=="art":
		await equipment_views()
		await finish();return
	if OS.get_environment("OOT_FOREST_STAGE")=="east":
		scope="Explicit two-key and map fixture, testing the eastern courtyard, well, block room and Bow acquisition. Earlier key acquisition is excluded from this focused run."
		world.state.forest_keys=2
		world.state.forest_chests=["tree_key","guard_key","map"]
		world.state.forest_clear=["north","map"]
		world.state.forest_time_block=true
		world.forest_temple.enter("map")
		await temple_courtyards()
		await finish();return
	if not "--capture-only" in OS.get_cmdline_user_args():
		if "--dungeon" in OS.get_cmdline_user_args():
			scope="Explicit post-Hookshot meadow fixture. Physical entry and first-half temple acquisition; Lost Woods route not repeated."
			world.overworld.enter("meadow")
			world.player.position=Vector3(0,.1,-13)
			await temple_entry()
			await temple_first_half()
		else: await forest_route_full()
		await temple_second_half()
		await finish()
		return
	world.forest_temple.enter("west")
	await seconds(1)
	await capture("90-west-courtyard")
	await walk(Vector3(-8,0,8))
	await walk(Vector3(-9,0,-8.9))
	await press("interact")
	Input.action_press("forward")
	await seconds(1.8)
	Input.action_release("forward")
	await seconds(.3)
	check("Courtyard vines reach a real upper ledge",world.player.position.y>3.9)
	await capture("91-courtyard-upper")
	if "--capture-only" in OS.get_cmdline_user_args():
		world.forest_temple.enter("north")
		await seconds(1)
		await capture("92-stalfos-chamber")
		await finish();return
	for key in world.forest_temple.data.rooms:
		world.forest_temple.enter(key)
		await seconds(.15)
		check("Room builds: "+key,world.area=="ft_"+key)
	await finish()

func approach_use(id:String,at:Vector3) -> void:
	world.player.lock_target=null
	await walk(at)
	await frames(3)
	check("Use target "+id,world.nearest==id,{"nearest":world.nearest})
	await press("interact")

func door(next:String) -> void:
	var old=world.area
	for entry in world.forest_temple.data.rooms[world.forest_temple.room].exits:
		if entry.to!=next: continue
		var at=world.vec(entry.at)
		var inward=Vector3(-at.x,0,-at.z).normalized()
		if at.length()<1: inward=Vector3.BACK
		await approach_use("ft_door:"+next,at+inward*1.3)
		check("Passage "+old+" to "+next,world.area=="ft_"+next)
		return

func shoot(target:Node3D,tool:String="bow",aim_delay:float=.3) -> void:
	world.player.lock_target=target
	if world.state.adult_tool!=tool: await press("tool")
	await seconds(aim_delay)
	await press("shoot")
	await seconds(1.0 if tool=="bow" else .6)

func battle(max_kills:int=999) -> void:
	var initial=world.forest_temple.alive_enemies().size()
	var limit=Time.get_ticks_msec()+75000
	while not world.forest_temple.alive_enemies().is_empty() and Time.get_ticks_msec()<limit and world.state.health>0:
		if initial-world.forest_temple.alive_enemies().size()>=max_kills: break
		var alive=world.forest_temple.alive_enemies()
		alive.sort_custom(func(a,b): return a.position.distance_to(world.player.position)<b.position.distance_to(world.player.position))
		var enemy=alive[0]
		world.player.lock_target=enemy
		if world.state.adult_tool!="hookshot" and world.state.bow: await press("tool")
		Input.action_press("shield")
		if enemy.position.distance_to(world.player.position)>1.8:
			await shoot(enemy,"hookshot")
			Input.action_release("shield")
			world.player.lock_target=null
			await close_distance(enemy,1.6)
		else:
			if enemy.stun<=0: await shoot(enemy,"hookshot")
			await press("attack")
			await seconds(.5)
		Input.action_release("shield")
	world.player.lock_target=null
	check("Combat clears "+world.area,world.forest_temple.alive_enemies().is_empty() or initial-world.forest_temple.alive_enemies().size()>=max_kills)

func forest_route_full() -> void:
	scope="Post-Hookshot fixture with input-driven Lost Woods and Forest Temple route. Target selection is assisted by assigning a known aim target; equipment, keys and rewards must be earned. Full original layouts and final visual quality remain incomplete."
	world.overworld.enter("lost_woods")
	await approach_use("wood:left",Vector3(-10.5,0,0))
	check("A wrong forest turn returns to Kokiri",world.area=="forest" and world.state.woods_stage==0)
	world.woodland.interact("wood:enter")
	for i in range(7):
		if i==2:
			await approach_use("wood:mido",Vector3(6,0,1.7))
			await play_notes(["down","right","left","down","right","left"])
			check("Saria's song earns Mido's passage",world.state.woods_mido)
		var direction=world.forest_temple.data.woods.sequence[i]
		var at=Vector3(10.5,0,0) if direction=="right" else Vector3(-10.5,0,0) if direction=="left" else Vector3(0,0,-10.5)
		await approach_use("wood:"+direction,at)
	check("Seven heard turns reach the meadow",world.area=="meadow")
	await capture("93-meadow-maze")
	await walk(Vector3(7,0,20));await battle(1);await walk(Vector3(7,0,10))
	await walk(Vector3(-7,0,10));await battle(1);await walk(Vector3(-7,0,1))
	await walk(Vector3(7,0,1));await battle(1);await walk(Vector3(7,0,-8))
	await approach_use("wood:sheik",Vector3(-4,0,-12))
	check("Sheik teaches the warp song",world.state.songs.has("minuet"))
	await temple_entry()
	await temple_first_half()

func temple_entry() -> void:
	await walk(Vector3(0,0,-13))
	await shoot(world.graveyard.targets[0],"hookshot")
	await seconds(3)
	check("Physical Hookshot reaches the temple terrace",world.player.position.y>3.9 and world.player.position.z< -21)
	world.player.lock_target=null
	await approach_use("wood:temple",Vector3(0,4,-23.5))
	check("The meadow leads into the Forest Temple",world.area=="ft_trees")

func temple_first_half() -> void:
	await walk(Vector3(-7,0,2))
	await approach_use("ft_climb:tree",Vector3(-7,0,-1.2))
	Input.action_press("forward");await seconds(1.25);Input.action_release("forward");await seconds(.2)
	await approach_use("ft_chest:tree_key",Vector3(-9,3,-5.9))
	check("Entrance tree chest grants the first key",world.state.forest_keys==1)
	await walk(Vector3(-5,0,-5));await walk(Vector3(0,0,-7))
	await door("hall");await battle();await door("lobby")
	await walk(Vector3(8,0,0));await door("north")
	await battle()
	await approach_use("ft_chest:guard_key",Vector3(0,0,-6.9))
	check("Lower Stalfos guard the second key",world.state.forest_keys==2)
	await capture("94-stalfos-cleared")
	await door("lobby")
	await walk(Vector3(-8,0,-8))
	await walk(Vector3(-9.6,0,-7))
	await play_notes(["right","a","down","right","a","down"])
	check("Song of Time clears the courtyard stone",world.state.forest_time_block)
	await door("west")
	await walk(Vector3(4,0,8));await walk(Vector3(-8,0,8))
	await approach_use("ft_climb:court",Vector3(-9,0,-8.9))
	Input.action_press("forward");await seconds(1.55);Input.action_release("forward");await seconds(.2)
	await door("map")
	await battle()
	await approach_use("ft_chest:map",Vector3(5,0,-4.9))
	await temple_courtyards()

func temple_courtyards() -> void:
	await door("east")
	await approach_use("ft_drain",Vector3(-6,4,-11.7))
	check("Upper switch drains the shared well",world.state.forest_well_drained)
	await walk(Vector3(7,0,-7))
	await door("well")
	await walk(Vector3(2,0,-3));await walk(Vector3(2,0,2))
	await approach_use("ft_chest:well_key",Vector3(0,0,1.1))
	check("Drained well yields the third key",world.state.forest_keys==3)
	await door("west")
	await walk(Vector3(11,0,-2));await door("lobby")
	await walk(Vector3(-8,0,0));await door("blocks")
	check("First locked door consumes exactly one key",world.state.forest_keys==2 and world.state.forest_doors.has("west_door"))
	for z in [5.6,3.6,1.6]:
		await approach_use("ft_push:green",Vector3(-4,0,z));await seconds(.5)
	check("Green block aligns with the first ledge",world.state.forest_blocks.get("green",[]).size()==3 and world.state.forest_blocks.green[2]==-2)
	await approach_use("ft_climb:green",Vector3(-4,0,-.3))
	Input.action_press("forward");await seconds(.95);Input.action_release("forward");await seconds(.2)
	await walk(Vector3(-4,2,-3.5));await walk(Vector3(2.5,2,-3.5));await walk(Vector3(2.5,2,-2.4))
	for z in [-2.4,-4.4,-6.4]:
		await approach_use("ft_push:brown",Vector3(4,2,z));await seconds(.5)
	await approach_use("ft_climb:brown",Vector3(4,2,-8.3))
	Input.action_press("forward");await seconds(.95);Input.action_release("forward");await seconds(.2)
	await door("twist_w");await door("red");await door("bow")
	check("Three keys opened three distinct doors",world.state.forest_keys==0 and world.state.forest_doors.size()==3)
	await battle()
	await approach_use("ft_chest:bow",Vector3(5,0,-6.9))
	check("The Stalfos pair releases the Fairy Bow",world.state.bow and world.state.arrows==30)
	await capture("95-fairy-bow")
	await press("save")
	world.load_game()
	check("Bow and spent keys survive reload",world.state.bow and world.state.forest_keys==0 and world.state.forest_doors.size()==3)

func close_distance(enemy:Node3D,distance:float) -> void:
	world.player.lock_target=null
	for i in range(600):
		var offset:Vector3=enemy.position-world.player.position
		offset.y=0
		if offset.length()<distance: break
		world.player.yaw=0
		var direction=offset.normalized()
		Input.action_press("right",maxf(0,direction.x));Input.action_press("left",maxf(0,-direction.x))
		Input.action_press("back",maxf(0,direction.z));Input.action_press("forward",maxf(0,-direction.z))
		await get_tree().physics_frame
	for action in ["right","left","back","forward"]: Input.action_release(action)
	await frames(3)

func temple_second_half() -> void:
	await door("red")
	await release_portrait_poe("joelle")
	await approach_use("ft_chest:red_key",Vector3(-7,0,-5.9))
	check("Joelle returns the red flame and a key",world.state.forest_poes.has("joelle") and world.state.forest_keys==1)
	await door("twist_w")
	await shoot(world.forest_temple.targets.straight_w)
	check("The bow straightens the western passage",world.state.forest_straight_w)
	await door("boss_key")
	await approach_use("ft_chest:boss_key",Vector3(-4,0,-2.9))
	await door("below");await battle();await door("west_upper");await door("floormaster")
	await battle()
	await approach_use("ft_chest:hand_key",Vector3(0,0,-6.9))
	check("All Floormaster fragments must fall for the fifth key",world.state.forest_keys==2 and world.forest_temple.cleared("floormaster"))
	await door("west_upper");await door("blocks")
	await walk(Vector3(0,2,-5));await walk(Vector3(4,2,-8.3))
	await press("interact")
	Input.action_press("forward");await seconds(.95);Input.action_release("forward");await seconds(.2)
	await door("twist_w")
	await shoot(world.forest_temple.targets.straight_w)
	await door("red");await door("bow");await door("blue")
	await release_portrait_poe("beth")
	await approach_use("ft_chest:compass",Vector3(-7,0,-5.9))
	check("Beth returns the blue flame and compass",world.state.forest_compass and world.state.forest_poes.has("beth"))
	await door("twist_e");await door("frozen")
	check("Five keys unlock five doors without a deficit",world.state.forest_keys==0 and world.state.forest_doors.size()==5)
	await stage_save("frozen")
	await temple_final_rooms()

func temple_final_rooms() -> void:
	await approach_use("ft_pot:0",Vector3(-5,0,7.2))
	await walk(Vector3(-4,0,12.5));await walk(Vector3(4,0,12.5));await walk(Vector3(4,0,8))
	await shoot(world.forest_temple.targets.frozen)
	check("An ordinary arrow cannot thaw the frozen eye",not world.state.forest_frozen_eye)
	await walk(Vector3(4,0,12.5));await walk(Vector3(0,0,12.5));await walk(Vector3(0,0,11));await walk(Vector3(0,2,7.8))
	# Board the physical rotating pad when it passes the ramp.
	while fposmod(world.forest_temple.rotor.rotation.y,TAU)<TAU-.12: await seconds(.025)
	await walk(world.forest_temple.rotor.transform*Vector3(0,2,6))
	var boarded:Vector3=world.player.position
	await seconds(.7)
	check("The rotating pad physically carries Link",world.player.position.y>1.8 and world.player.position.distance_to(boarded)>.6,{"before":str(boarded),"after":str(world.player.position),"platform_linear":str(world.player.get_platform_velocity()),"platform_angular":str(world.player.get_platform_angular_velocity()),"on_floor":world.player.is_on_floor()})
	await capture("96-rotating-pad")
	if world.player.position.y<1.8:
		await finish();return
	world.player.lock_target=world.forest_temple.targets.frozen
	while absf(world.player.position.x)>.15 or world.player.position.z<5: await seconds(.025)
	await shoot(world.forest_temple.targets.frozen,"bow",0)
	check("An arrow through the flame melts the ice",world.state.forest_frozen_eye)
	var screen=world.player.camera.unproject_position(world.player.global_position+Vector3.UP)
	check("Long-range aim retains Link inside the frame",not world.player.camera.is_position_behind(world.player.global_position+Vector3.UP) and Rect2(40,40,1200,660).has_point(screen),{"screen":str(screen)})
	await capture("97-frozen-eye")
	world.player.lock_target=null
	await walk(Vector3(8,0,7));await walk(Vector3(4,0,12.5));await walk(Vector3(0,0,12.5));await door("twist_e");await door("ceiling")
	# Wait on a visible safe tile through one complete falling cycle.
	await walk(Vector3(0,0,12))
	var health=world.state.health
	await seconds(6.1)
	check("Marked opening protects Link from the ceiling",world.state.health==health)
	for at in [Vector3(-4,0,4),Vector3(4,0,-4),Vector3(0,0,-12)]:
		while world.forest_temple.ceiling_time>1: await seconds(.1)
		await walk(at)
	await door("green")
	await stage_save("green")
	await temple_green_stage()

func temple_green_stage() -> void:
	await walk(Vector3(3,0,8))
	await shoot(world.forest_temple.targets.amy_start)
	check("The portrait starts Amy's timed puzzle",world.forest_temple.amy_time>0)
	await press("pause")
	var timer=world.forest_temple.amy_time
	await seconds(.4)
	check("Pause freezes the portrait countdown",world.forest_temple.amy_time==timer)
	check("The timed arrangement cannot be saved halfway",not world.save_game())
	await press("pause")
	# Four independent fragments each travel two squares inward.
	for route in [["0",Vector3(-7.1,0,-1.1),Vector3(-4.9,0,-1.1)],["1",Vector3(7.1,0,-1.1),Vector3(4.9,0,-1.1)],["2",Vector3(-1.1,0,7.1),Vector3(-1.1,0,4.9)],["3",Vector3(7.1,0,1.1),Vector3(4.9,0,1.1)]]:
		if world.player.position.x>4: await walk(Vector3(9.5,0,world.player.position.z))
		await walk(Vector3(world.player.position.x,0,8.5))
		if route[1].x>7:
			await walk(Vector3(9.5,0,8.5));await walk(Vector3(9.5,0,route[1].z))
		else: await walk(Vector3(route[1].x,0,8.5))
		for at in [route[1],route[2]]:
			await approach_use("ft_push:"+route[0],at);await seconds(.5)
	check("Four assembled fragments reveal Amy",world.state.forest_amy_solved)
	await defeat_poe("amy")
	await door("lobby")
	check("Three sisters summon Meg to the central hall",world.state.forest_poes.size()==3 and is_instance_valid(world.forest_temple.boss))
	await walk(Vector3(9,0,0));await walk(Vector3(0,0,1.8))
	var meg=world.forest_temple.boss
	for i in range(5):
		while meg.timer>4.65: await seconds(.025)
		var actual:Node3D
		for clone in meg.clones:
			if absf(clone.visual.rotation.y)>1: actual=clone
		check("One visible clone spins to identify Meg",is_instance_valid(actual))
		while meg.timer>4.1: await seconds(.025)
		if actual: await shoot(actual)
	check("Meg restores the fourth flame",world.state.forest_poes.size()==4)
	await capture("98-four-flames")
	await door("basement")
	await stage_save("basement")
	await temple_basement_stage()

func temple_basement_stage() -> void:
	for i in range(1,4):
		await approach_use("ft_rotate",Vector3(0,0,3))
		var at=Vector3(0,0,-10).rotated(Vector3.UP,i*PI/2)
		await walk(Vector3.ZERO)
		if i==2: await walk(Vector3(2,0,3));await walk(Vector3(2,0,8))
		await approach_use("ft_switch:"+str(i),at)
		if i==2: await walk(Vector3(2,0,8));await walk(Vector3(2,0,3))
		await walk(Vector3.ZERO)
	check("Three reachable alcoves release the boss passage",world.state.forest_basement_switches.size()==3)
	await approach_use("ft_rotate",Vector3(0,0,3))
	await walk(Vector3.ZERO);await door("boss")
	await stage_save("boss")
	await temple_boss_stage()

func temple_boss_stage() -> void:
	await phantom_battle()
	if not world.state.phantom_ganon: return
	await approach_use("ft_reward",Vector3.ZERO)
	await approach_use("ft_saria",Vector3(0,0,-3.3))
	await press("interact")
	check("Saria awards the normally earned Forest Medallion",world.state.forest_medallion and world.area=="forest")
	await capture("100-forest-medallion")
	await press("save")
	world.load_game()
	check("Reload preserves every flame, key door and the medallion",world.state.forest_medallion and world.state.forest_poes.size()==4 and world.state.forest_doors.size()==5)
	await stage_save("medallion")
	await forest_epilogue()

func forest_epilogue() -> void:
	await approach_use("wood:sprout",Vector3(4,0,-31))
	for i in range(3): await press("interact")
	check("The sprout tells Link's origin and the forest's recovery",world.state.forest_sprout_stage==4)
	await capture("101-deku-sprout")
	# Geography assistance: the return trip across Field is outside this dungeon run.
	scope+=" Temple epilogue uses direct geographic entry; pedestal, conversations and warp songs use input."
	world.overworld.enter("temple")
	await walk(Vector3(0,0,-7.6))
	if not world.state.door_of_time:
		await press("interact")
		await play_notes(["right","a","down","right","a","down"])
		await seconds(4)
	await walk(Vector3(3,0,-7.6));await walk(Vector3(3,0,-11));await walk(Vector3(0,0,-12))
	await walk(Vector3(0,0,-17));await approach_use("sheik",Vector3(3,0,-17.8))
	check("The earned medallion unlocks Sheik's Prelude of Light",world.state.songs.has("prelude"))
	await walk(Vector3(0,0,-18));await approach_use("master_sword",Vector3(0,0,-21))
	await seconds(4.6)
	check("The earned Forest Medallion opens the path to childhood",not world.state.adult and world.state.forest_medallion and world.area=="temple")
	await capture("102-childhood-return")
	await approach_use("master_sword",Vector3(0,0,-21))
	await seconds(4.6)
	check("Drawing the sword restores the adult journey",world.state.adult and world.state.bow and world.state.hookshot)
	if not "minuet" in world.state.songs:
		# Earlier focused saves began after the meadow lesson; earn it now by talking.
		world.overworld.enter("meadow")
		world.player.position=Vector3(-4,.1,-12)
		await frames(5);await press("interact")
	await play_notes(["a","up","left","right","left","right"])
	check("The Minuet returns Link to the forest clearing",world.area=="meadow" and world.player.position.z< -12)
	await play_notes(["up","right","up","right","left","up"])
	check("The Prelude returns Link to the sanctuary",world.area=="temple" and world.player.position.z< -16)
	await press("save");world.load_game()
	check("Reload retains the epilogue, warp songs and both ages' progress",world.state.adult and world.state.forest_medallion and world.state.forest_sprout_stage==4 and world.state.songs.has("prelude"))

func release_portrait_poe(id:String) -> void:
	await walk(Vector3(0,0,0))
	for i in range(3):
		var active:Node3D
		for target in world.forest_temple.targets.values():
			if target.active and not target.spent: active=target
		if active: await shoot(active)
	check("Three destroyed portraits reveal "+id,is_instance_valid(world.forest_temple.boss))
	await defeat_poe(id)

func defeat_poe(id:String) -> void:
	var enemy=world.forest_temple.boss
	if not is_instance_valid(enemy): return
	var limit=Time.get_ticks_msec()+30000
	while enemy.mode!="dead" and Time.get_ticks_msec()<limit and world.state.health>0:
		if enemy.position.distance_to(world.player.position)>1.8:
			world.player.lock_target=null
			await walk(enemy.position+(world.player.position-enemy.position).normalized()*1.5)
		world.player.lock_target=enemy
		await seconds(.2)
		if enemy.mode=="visible": await press("attack");await seconds(.5)
	world.player.lock_target=null
	check("The visible sister can be defeated: "+id,enemy.mode=="dead")

func phantom_battle() -> void:
	await walk(Vector3(0,0,1))
	await approach_use("ft_pot:0",Vector3(-5,0,7.1))
	await walk(Vector3(0,0,1))
	var phantom=world.forest_temple.boss
	for i in range(3):
		while phantom.mode!="emerge": await seconds(.05)
		await shoot(phantom)
	check("Three arrows force the true rider out of the paintings",phantom.painting_hits==3 and not phantom.horse.visible)
	await capture("99-phantom-volley")
	var deadline=Time.get_ticks_msec()+120000
	while phantom.mode!="dead" and world.state.health>0 and Time.get_ticks_msec()<deadline:
		world.player.lock_target=phantom
		if phantom.mode=="stunned":
			world.player.lock_target=null
			await walk(Vector3(0,0,-5.5))
			world.player.lock_target=phantom
			await seconds(.2)
			await press("attack");await seconds(.52);await press("attack");await seconds(.52)
			world.player.lock_target=null
			await walk(Vector3(0,0,1))
			# One approach per stun. Wait for the next volley after retreating.
			while phantom.mode=="stunned": await seconds(.025)
		elif is_instance_valid(phantom.orb) and not phantom.orb.returning and phantom.orb.position.distance_to(world.player.position+Vector3.UP*1.05)<1.9:
			await press("attack")
		else: await seconds(.025)
	world.player.lock_target=null
	check("Sword returns and exposed attacks defeat Phantom Ganon",world.state.phantom_ganon and world.stats.get("phantom_returns",0)>=2)

func stage_save(id:String) -> void:
	world.save_path=output+"/"+id+"-save.json"
	check("Save reached stage: "+id,world.save_game())
	world.save_path=output+"/test-save.json"

func failure_contracts() -> void:
	scope="Isolated Forest Temple failure contracts. Prepared Bow, direct room entry, health resets, one-key grant and lethal enemy damage establish boundary states; interactions, arrows, waiting, pause, save and retry use input. This is not route completion."
	world.state.bow=true;world.state.arrows=30
	world.forest_temple.enter("lobby")
	await approach_use("ft_door:blocks",Vector3(-11.7,0,7))
	check("A locked door refuses entry without a key",world.area=="ft_lobby" and world.state.forest_doors.is_empty())
	world.state.forest_keys=1
	await door("blocks");await door("lobby");await door("blocks")
	check("Reopening a door does not consume another key",world.state.forest_keys==0 and world.state.forest_doors==["west_door"])
	await press("save");world.load_game()
	check("An unlocked door remains usable after reload",world.state.forest_doors==["west_door"])
	world.forest_temple.enter("trees")
	await walk(Vector3(-7,0,2));await approach_use("ft_climb:tree",Vector3(-7,0,-1.2))
	Input.action_press("forward");await seconds(1.25);Input.action_release("forward");await seconds(.2)
	await approach_use("ft_chest:tree_key",Vector3(-9,3,-5.9));await press("interact")
	check("An opened key chest cannot duplicate its reward",world.state.forest_keys==1 and world.state.forest_chests.count("tree_key")==1)
	world.forest_temple.enter("bow")
	world.player.position=Vector3(9,0,9)
	world.forest_temple.alive_enemies()[0].damage(999)
	await frames(3)
	world.forest_temple.alive_enemies()[0].damage(999)
	await press("pause")
	var revival=world.forest_temple.revival
	await seconds(.4)
	check("Pause stops the defeated Stalfos revival countdown",world.forest_temple.revival==revival)
	await press("pause")
	await seconds(10.3)
	check("A surviving Stalfos brings its partner back",world.forest_temple.alive_enemies().size()==2 and not world.forest_temple.cleared("bow"))
	world.state.health=12
	world.forest_temple.enter("floormaster")
	world.player.position=Vector3(9,0,9)
	world.forest_temple.alive_enemies()[0].damage(999)
	await frames(3)
	check("A fallen Floormaster divides into three fragments",world.forest_temple.alive_enemies().size()==3)
	await seconds(12.3)
	check("A surviving fragment regrows one Floormaster",world.forest_temple.alive_enemies().size()==1 and world.forest_temple.alive_enemies()[0].kind=="floormaster")
	check("Regrowth releases old hand bodies",world.creatures.filter(func(enemy): return is_instance_valid(enemy)).size()==1)
	world.state.health=12
	world.forest_temple.enter("green")
	await walk(Vector3(3,0,8));await shoot(world.forest_temple.targets.amy_start)
	await approach_use("ft_push:2",Vector3(-1.1,0,7.1));await seconds(.5)
	await walk(Vector3(3,0,8))
	await seconds(world.forest_temple.amy_time+.3)
	var reset=true
	for block in world.forest_temple.blocks.values():
		if block.node.position.distance_to(block.origin)>.01: reset=false
	check("Running out of time resets all portrait pieces",reset and not world.state.forest_amy_solved and world.forest_temple.amy_time==0)
	await shoot(world.forest_temple.targets.amy_start)
	check("Shooting the portrait restarts the failed puzzle",world.forest_temple.amy_time>58)
	await capture("103-portrait-retry")
	world.state.forest_poes=["joelle","beth","amy"]
	world.forest_temple.enter("lobby")
	world.player.position=Vector3(0,0,1.8)
	var meg=world.forest_temple.boss
	await seconds(.95)
	var health=meg.health
	await shoot(meg.clones[(meg.true_clone+1)%4])
	check("An arrow at a false clone cannot restore the fourth flame",meg.health==health and world.state.forest_poes.size()==3)
	world.state.health=12
	world.forest_temple.enter("boss")
	var phantom=world.forest_temple.boss
	while phantom.mode!="emerge": await seconds(.05)
	await shoot(phantom.decoy)
	check("The false painting rider takes no true-rider hit",phantom.painting_hits==0)
	await capture("104-false-rider")
	world.state.health=0
	world.player.enabled=false
	await press("interact")
	await seconds(.3)
	check("Retry rebuilds the boss encounter with earned equipment",world.player.enabled and world.state.health>0 and world.area=="ft_boss" and world.state.bow and world.forest_temple.boss.painting_hits==0)
	# A direct chamber fixture tests conversation routing and reward idempotence.
	world.forest_temple.enter("saria")
	await approach_use("ft_saria",Vector3(1.2,0,-5))
	await press("interact")
	check("Saria's reward works when approached from the side",world.state.forest_medallion and world.area=="forest")
	var capacity=world.state.max_health
	world.forest_temple.enter("saria")
	await approach_use("ft_saria",Vector3(1.2,0,-5))
	check("Revisiting the sage returns to the forest without another heart",world.area=="forest" and world.state.max_health==capacity)

func equipment_views() -> void:
	scope="Forest equipment rendering fixture with prepared Bow and paused actors. Three Stalfos angles and a drawn Bow are inspected; model realism and full campaign acceptance remain incomplete."
	world.state.bow=true;world.state.arrows=30;world.state.adult_tool="bow"
	world.forest_temple.enter("north")
	await seconds(.3)
	await press("pause")
	world.message_panel.hide()
	var enemy=world.forest_temple.alive_enemies()[0]
	var camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.fov=45
	var views=[["105-stalfos-front",Vector3(2.6,1.8,-3.4),Vector3(0,.95,0)],["106-stalfos-back",Vector3(-2.5,1.8,3.1),Vector3(0,.95,0)],["107-stalfos-close",Vector3(.6,1.7,-1.2),Vector3(0,1.45,0)]]
	for view in views:
		camera.position=enemy.position+view[1];camera.look_at(enemy.position+view[2])
		await capture(view[0])
	await press("pause")
	world.player.position=Vector3(0,.1,5)
	world.player.lock_target=enemy
	await seconds(.3)
	Input.action_press("shoot");await seconds(.35)
	await press("pause")
	world.message_panel.hide()
	check("A held shot presents the Bow in the left hand",world.player.bow.visible and world.player.bow.get_parent()==world.player.sockets.left)
	for view in [["108-bow-drawn-front",Vector3(2.2,1.6,-2.8)],["109-bow-drawn-side",Vector3(-2.2,1.6,-1.6)]]:
		camera.position=world.player.position+view[1];camera.look_at(world.player.position+Vector3.UP*1.25)
		await capture(view[0])
	await press("pause")
	Input.action_release("shoot");await seconds(.2)
	check("Releasing the drawn Bow consumes one arrow",world.state.arrows==29)
	world.player.camera.current=true;camera.queue_free()
