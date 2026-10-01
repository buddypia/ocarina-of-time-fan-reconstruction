extends "res://tests/world_playthrough.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	await frames(30)
	world.start_game()
	scope="Post-Sapphire equipment fixture; new castle escape, moat pickup, learned song and Temple of Time are exercised through action input. Negative guards use isolated state setup. Full game and final visual quality incomplete."
	for key in ["sword","shield","slingshot","ocarina","bracelet","bomb_bag","ruby","emerald","sapphire","silver_scale","zelda_letter","boomerang"]: world.state[key]=true
	world.state.max_health=12
	world.state.health=12
	world.state.seeds=30
	world.state.songs=["lullaby","saria","epona"]
	if "--dungeon" in OS.get_cmdline_user_args():
		scope="Explicit sanctuary fixture: three stones, royal ocarina and opened Door of Time prepared. Master Sword, adult awakening, age equipment and save/reload tested through input. Later time-travel unlock is an isolated Forest Medallion fixture, not a completed Forest Temple."
		for key in ["castle_escape","ocarina_of_time","stones_placed","door_of_time"]: world.state[key]=true
		world.learn_song("time")
		world.overworld.enter("temple")
		world.player.position=Vector3(0,0,-21)
		await frames(10)
		await press("interact")
		await adult_route()
		await finish()
		return
	if "--capture-only" in OS.get_cmdline_user_args():
		scope="Temple nave, altar and aisle rendering fixture with prepared Spiritual Stones. Castle event, adult progression and time travel are not exercised in this capture-only mode."
		world.overworld.enter("temple")
		await seconds(2)
		await capture("70-temple-nave")
		await walk(Vector3(0,0,-7.6))
		await press("interact")
		await capture("71-temple-altar")
		world.player.yaw=PI*.65
		await seconds(.8)
		await capture("72-temple-aisle")
		await finish()
		return
	world.state.sapphire=false
	world.overworld.enter("field")
	world.player.position=Vector3(0,0,-60)
	await frames(6)
	await press("interact")
	check("Returning with only two stones does not trigger the castle escape",world.area=="market" and not world.state.castle_escape and world.time_quest.sequence.is_empty())
	world.state.sapphire=true
	world.overworld.enter("field")
	world.player.position=Vector3(0,0,-55)
	await walk(Vector3(0,0,-60))
	await press("interact")
	check("Three stones trigger the castle escape instead of entering town",world.time_quest.sequence=="escape" and not world.player.enabled)
	await seconds(2)
	await capture("65-castle-escape")
	await press("pause")
	var frozen=world.time_quest.time
	var rider_position:Vector3=world.time_quest.riders[0].node.position
	await seconds(.5)
	check("Pausing the scene freezes the timeline and actors",world.time_quest.time==frozen and world.time_quest.riders[0].node.position==rider_position)
	check("A save cannot record a half-finished escape",not world.save_game() and not FileAccess.file_exists(world.save_path))
	await press("pause")
	await wait_sequence()
	check("Finishing the escape leaves the blue instrument in the real moat",world.state.castle_escape and is_instance_valid(world.time_quest.ocarina) and not world.state.ocarina_of_time)
	await press("save")
	world.load_game()
	check("Reloading after the escape rebuilds the uncollected ocarina",world.state.castle_escape and is_instance_valid(world.time_quest.ocarina) and not world.state.ocarina_of_time)
	await walk(Vector3(2,0,-57))
	await walk(Vector3(9,0,-57))
	await seconds(.8)
	check("Stepping east of the bridge enters swimmable water",world.player.swimming)
	await walk(Vector3(9,-1,-60))
	await press("interact")
	check("The instrument cannot be recovered from the surface",not world.state.ocarina_of_time and world.time_quest.sequence.is_empty())
	Input.action_press("roll")
	await seconds(1.4)
	await press("interact")
	Input.action_release("roll")
	check("Diving to the instrument begins Zelda's remembered melody",world.time_quest.sequence=="echo")
	await capture("66-ocarina-memory")
	await wait_sequence()
	check("The complete memory awards the Ocarina of Time and its song",world.state.ocarina_of_time and "time" in world.state.songs)
	await walk(Vector3(9,0,-56))
	await walk(Vector3(9,0,-49.5))
	check("The sloping bank returns Link to dry ground",not world.player.swimming and world.player.position.y>-.2)
	await walk(Vector3(2,0,-49.5))
	await walk(Vector3(0,0,-60))
	await press("interact")
	check("The castle gate stays accessible after the escape",world.area=="market")
	await walk(Vector3(7,0,15))
	await walk(Vector3(7,0,-18))
	await walk(Vector3(10,0,-21))
	await press("interact")
	check("The northeast market route enters the Temple of Time",world.area=="temple")
	await seconds(.5)
	await capture("70-temple-nave")
	await temple_route()
	await adult_route()
	await finish()

func wait_sequence() -> void:
	for i in range(300):
		if world.time_quest.sequence.is_empty(): return
		await seconds(.1)
	check("Story sequence terminates",false)

func temple_route() -> void:
	await walk(Vector3(3,0,-7.6))
	await walk(Vector3(3,0,-11))
	await walk(Vector3(0,0,-12))
	Input.action_press("forward")
	await seconds(1)
	Input.action_release("forward")
	check("The sealed door physically stops Link before the sanctuary",world.player.position.z>-13.5)
	await walk(Vector3(0,0,-12))
	await walk(Vector3(3,0,-11))
	await walk(Vector3(3,0,-7.6))
	await walk(Vector3(0,0,-7.6))
	await play_notes(["right","a","down","right","a","down"])
	check("Song before placing the stones leaves the seal closed",not world.state.door_of_time)
	world.state.sapphire=false
	await press("interact")
	check("Two stones cannot fill the altar",not world.state.stones_placed)
	world.state.sapphire=true
	await press("interact")
	check("E places all three stones in the altar sockets",world.state.stones_placed and world.time_quest.stones[0].visible)
	world.state.ocarina_of_time=false
	await play_notes(["right","a","down","right","a","down"])
	check("The Fairy Ocarina cannot open the Door of Time",not world.state.door_of_time)
	world.state.ocarina_of_time=true
	await walk(Vector3(0,0,2))
	await play_notes(["right","a","down","right","a","down"])
	check("The seal requires playing near the altar",not world.state.door_of_time)
	await walk(Vector3(0,0,-7.6))
	await play_notes(["left","up","right","left","up","right"])
	check("Zelda's Lullaby does not replace the Song of Time",not world.state.door_of_time)
	await play_notes(["right","a","down","right","a","down"])
	check("Royal ocarina, three placed stones and Song of Time open the seal",world.state.door_of_time)
	await seconds(.7)
	await press("pause")
	var opening=world.time_quest.opening
	await seconds(.5)
	check("Pause freezes the heavy sliding door",world.time_quest.opening==opening)
	await press("pause")
	await seconds(4)
	check("The opened doors remove their collision",world.time_quest.door_bodies[0].collision_layer==0 and world.time_quest.door_bodies[1].collision_layer==0)
	await capture("71-door-of-time")
	await walk(Vector3(3,0,-7.6))
	await walk(Vector3(3,0,-11))
	await walk(Vector3(0,0,-12))
	await walk(Vector3(0,0,-21))
	await press("interact")
	await capture("72-master-sword")
	await press("save")
	world.state.door_of_time=false
	world.load_game()
	check("Save restores placed stones, the open door and sanctuary position",world.state.door_of_time and world.state.stones_placed and world.player.position.z<-20 and world.time_quest.door_bodies[0].collision_layer==0)
	world.player.yaw=PI*.6
	await seconds(1)
	await capture("73-sanctuary-side")

func adult_route() -> void:
	await press("interact")
	check("Drawing the sacred blade enters the Chamber of Sages as an adult",world.time_quest.sequence=="awakening" and world.area=="sages" and world.state.adult and world.state.master_sword)
	await seconds(1)
	await capture("74-chamber-of-sages")
	await press("pause")
	var frozen=world.time_quest.time
	await seconds(.4)
	check("The awakening can pause without completing the medallion reward",world.time_quest.time==frozen and not world.state.light_medallion)
	await press("pause")
	await wait_sequence()
	check("The awakening returns to Sheik and awards the Light Medallion",world.area=="temple" and world.state.light_medallion and world.player.enabled and world.npc_nodes.has("sheik"))
	check("Adult form uses its own anatomy and a taller physical capsule",world.player.adult_model and is_equal_approx(world.player.collider.shape.height,1.73) and world.player.sword.scene_file_path.ends_with("master_sword.glb"))
	check("Child shield ownership is preserved while the adult cannot equip it",world.state.shield and not world.player.shield.visible)
	var seeds=world.state.seeds
	await press("shoot")
	await press("boomerang")
	check("Adult cannot fire the slingshot or throw the child boomerang",world.state.seeds==seeds and not is_instance_valid(world.active_boomerang))
	Input.action_press("shield")
	await frames(3)
	check("An unequipped child shield cannot block for the adult",not world.can_block(world.player.position-world.player.visual.basis.z))
	Input.action_release("shield")
	await press("attack")
	check("Adult sword action drives the new skeletal model",world.player.attacking>0)
	await seconds(.6)
	await walk(Vector3(3,0,-19))
	await press("interact")
	check("Sheik explains the forest and graveyard route",world.message_label.text.begins_with("Sheik"))
	await capture("75-sheik")
	await walk(Vector3(0,0,-21))
	await press("interact")
	check("First awakening cannot return to childhood before the Forest Medallion",world.state.adult and world.time_quest.sequence.is_empty())
	await press("save")
	world.state.adult=false
	world.apply_state()
	world.load_game()
	check("Reload restores age, sword, medallion, capsule and equipment restrictions",world.state.adult and world.state.light_medallion and world.player.adult_model and world.player.sword.visible and not world.player.shield.visible)
	await capture("76-adult-save")
	await character_views()
	# This unlock flag is an explicit contract fixture, not earned temple progress.
	world.state.forest_medallion=true
	world.player.position=Vector3(0,0,-21)
	world.player.enabled=true
	await frames(6)
	await press("interact")
	await wait_sequence()
	check("Unlocked pedestal returns to the child body and its equipment",not world.state.adult and not world.player.adult_model and world.player.shield.visible and is_equal_approx(world.player.collider.shape.height,1.40))
	world.player.position=Vector3(0,0,-21)
	await frames(6)
	await press("interact")
	await wait_sequence()
	check("Drawing the blade again returns to adulthood without losing progress",world.state.adult and world.player.adult_model and world.state.light_medallion and world.state.ocarina_of_time)
	world.state.forest_medallion=false
	# Legacy saves omit new era fields. Loading them must reset new defaults,
	# not inherit the adult form currently in memory.
	var adult_save=world.save_path
	var legacy_state=world.state.duplicate(true)
	for key in ["adult","master_sword","light_medallion","sword_inspected","castle_escape","ocarina_of_time","stones_placed","door_of_time"]: legacy_state.erase(key)
	world.save_path=output+"/legacy-save.json"
	FileAccess.open(world.save_path,FileAccess.WRITE).store_string(JSON.stringify({"version":1,"state":legacy_state,"area":"market","position":[7,0,15]}))
	world.load_game()
	check("Legacy saves without era fields restore a child rather than inheriting adult state",not world.state.adult and not world.player.adult_model and world.player.shield.visible and not world.state.master_sword)
	world.save_path=adult_save
	world.load_game()
	check("The current adult save remains intact after legacy load",world.state.adult and world.state.light_medallion and world.player.adult_model)

func character_views() -> void:
	world.message_panel.hide()
	world.player.position=Vector3(0,0,-18)
	world.player.visual.rotation.y=0
	await frames(6)
	var inspection=Camera3D.new()
	world.add_child(inspection)
	inspection.fov=45
	inspection.current=true
	for shot in [["77-adult-front",Vector3(1.6,1.7,-20.6)],["78-adult-back",Vector3(-1.4,1.65,-15.5)],["79-adult-face",Vector3(.5,1.75,-19.1)]]:
		inspection.position=shot[1]
		inspection.look_at(world.player.position+Vector3.UP*(1.48 if shot[0]=="79-adult-face" else .92))
		await frames(3)
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(output+"/"+shot[0]+".png")
	inspection.queue_free()
	world.player.camera.current=true
	world.player.update_camera(1)
