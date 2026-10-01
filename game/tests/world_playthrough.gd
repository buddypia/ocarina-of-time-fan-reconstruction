extends "res://tests/dungeon_playthrough.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	scope="From new journey through the authored Deku Tree, castle audience, three learned melodies and Epona friendship. Full game incomplete."
	await frames(30)
	world.start_game()
	if "--fixture" in OS.get_cmdline_user_args():
		scope="Post-Deku overworld route. Explicit completed-Deku equipment/progression fixture; full game incomplete."
		for key in ["sword","shield","mido","saria","slingshot","gohma","emerald","ocarina"]: world.state[key]=true
		world.state.max_health=8
		world.state.health=8
		world.state.seeds=30
		world.apply_state()
	else:
		await forest_route()
		await dungeon_route()
	await world_route()
	await finish()

func world_route() -> void:
	await walk(Vector3(-12,0,5))
	await walk(Vector3(-22,0,7))
	await walk(Vector3(-24,0,7))
	await press("interact")
	check("Forest exit leads into Hyrule Field",world.area=="field")
	await capture("14-hyrule-field")
	await walk(Vector3(32,0,25))
	await walk(Vector3(17,0,4))
	await walk(Vector3(13,0,-28))
	await walk(Vector3(0,0,-59.7))
	await press("interact")
	check("Northern road reaches castle town",world.area=="market")
	await walk(Vector3(5,0,8))
	await walk(Vector3(4,0,2.5))
	await press("interact")
	check("Malon entrusts the egg before castle access",world.state.egg and not world.state.talon_awake)
	await capture("15-market")
	await walk(Vector3(5,0,8))
	await walk(Vector3(0,0,19.6))
	await press("interact")
	await walk(Vector3(13,0,-28))
	await walk(Vector3(20,0,4))
	await walk(Vector3(22,0,18.4))
	await press("interact")
	check("Resting at the travelers' fire hatches the egg",world.state.day>world.state.egg_day and world.state.time_of_day<.35)
	await walk(Vector3(20,0,4))
	await walk(Vector3(13,0,-28))
	await walk(Vector3(0,0,-59.7))
	await press("interact")
	await walk(Vector3(5,0,8))
	await walk(Vector3(5,0,-10))
	await walk(Vector3(0,0,-21.5))
	await press("interact")
	check("Market connects to castle delivery yard",world.area=="castle")
	await walk(Vector3(0,0,12.5))
	await press("interact")
	check("The hatched cucco wakes Talon and clears the gate",world.state.talon_awake and world.overworld.delivery_gate.collision_layer==0)
	await walk(Vector3(0,0,7))
	# Cross each gap while the nearest guard looks toward the opposite hedge.
	await sneak_gap(0,6,1)
	await walk(Vector3(6,0,-.1))
	await sneak_gap(1,-6,-7)
	await walk(Vector3(-6,0,-8.1))
	await sneak_gap(2,6,-15)
	await walk(Vector3(6,0,-18))
	await walk(Vector3(0,0,-20.5))
	await press("interact")
	await press("interact")
	check("Zelda's audience grants the royal letter",world.state.zelda_letter)
	await walk(Vector3(3,0,-18.6))
	await press("interact")
	check("Impa teaches Zelda's Lullaby", "lullaby" in world.state.songs)
	await capture("16-castle-audience")
	await play_notes(["left","up","right","left","up","right"])
	check("Six note inputs recognize the learned lullaby",world.stats.songs_played==1 and not world.instrument_open)
	await press("save")
	world.load_game()
	check("Castle save restores quest, song and room",world.area=="castle" and world.state.zelda_letter and "lullaby" in world.state.songs)
	await walk(Vector3(6,0,-18))
	await walk(Vector3(6,0,-9))
	await walk(Vector3(-6,0,-9))
	await walk(Vector3(-6,0,-1))
	await walk(Vector3(6,0,-1))
	await walk(Vector3(6,0,7))
	await walk(Vector3(0,0,19.5))
	await press("interact")
	await walk(Vector3(5,0,-10))
	await walk(Vector3(5,0,8))
	await walk(Vector3(0,0,19.6))
	await press("interact")
	await walk(Vector3(13,0,-28))
	await walk(Vector3(17,0,12))
	await walk(Vector3(0,0,13.5))
	await press("interact")
	check("The ranch is reachable from the central plain",world.area=="ranch")
	await walk(Vector3(-6,0,8))
	await walk(Vector3(-6,0,.5))
	await press("interact")
	check("Malon teaches Epona's melody", "epona" in world.state.songs)
	await play_notes(["up","left","right","up","left","right"])
	check("Played song befriends Epona",world.state.epona_friend and world.stats.songs_played==2)
	var horse_start:Vector3=world.overworld.horse.position
	var leg_start:float=world.overworld.horse_legs[0].thigh.rotation.x
	await seconds(.3)
	check("Epona follows the melody with articulated walking legs",world.overworld.horse.position.distance_to(horse_start)>.1 and absf(world.overworld.horse_legs[0].thigh.rotation.x-leg_start)>.01)
	await capture("17a-epona-walk")
	await seconds(1.7)
	await capture("17-ranch")
	await walk(Vector3(-6,0,8))
	await walk(Vector3(-8.6,0,8))
	await press("interact")
	check("Rescued Talon gives the two-serving milk bottle",world.state.bottle and world.state.milk==2)
	await press("milk")
	check("Full health does not waste milk",world.state.milk==2)
	await press("save")
	world.load_game()
	check("Ranch save preserves bottle, songs and Epona friendship",world.area=="ranch" and world.state.bottle and world.state.epona_friend and world.state.songs.size()==2)
	await walk(Vector3(-6,0,8))
	await walk(Vector3(0,0,20.5))
	await press("interact")
	await walk(Vector3(17,0,14))
	await walk(Vector3(32,0,25))
	await walk(Vector3(50.5,0,40))
	await press("interact")
	check("Plain returns to the same forest with persistent progress",world.area=="forest" and world.state.emerald and world.state.zelda_letter)
	await walk(Vector3(-12,0,5))
	await walk(Vector3(0,0,8.6))
	await walk(Vector3(2,0,9.5))
	await press("interact")
	check("Saria responds to the princess quest and teaches her song", "saria" in world.state.songs)
	await play_notes(["down","right","left","down","right","left"])
	check("Saria's song is playable after the return visit",world.stats.songs_played==3)
	await capture("18-return-with-songs")

func sneak_gap(index:int, side:float, destination_z:float) -> void:
	var patrol=world.overworld.patrols[index]
	for i in range(1400):
		var phase=world.elapsed*.32+patrol.phase
		var faces_away=cos(phase)*signf(side)<-.65
		if faces_away: break
		await get_tree().physics_frame
	await walk(Vector3(side,0,patrol.home.z+3))
	await walk(Vector3(side,0,destination_z))

func play_notes(notes:Array) -> void:
	await press("ocarina")
	for note in notes:
		await press("note_"+note)
		await seconds(.12)
