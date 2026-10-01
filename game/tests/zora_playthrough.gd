extends "res://tests/mountain_playthrough.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	await frames(30)
	world.start_game()
	if "--capture-only" in OS.get_cmdline_user_args():
		scope="Water-region rendering fixture: direct scene entry, no progression acceptance."
		for place in ["river","domain","lake","fountain"]:
			world.overworld.enter(place)
			await seconds(1)
			await capture("view-"+place)
			if place=="domain":
				world.message_panel.hide()
				for shot in [{"name":"pool","at":Vector3(0,0,18),"yaw":0.0},{"name":"stone-close","at":Vector3(13,0,-7),"yaw":-PI*.5},{"name":"diving-platform","at":Vector3(-13,3,1),"yaw":.6}]:
					world.player.position=shot.at
					world.player.yaw=shot.yaw
					world.player.update_camera(1)
					await seconds(1)
					await capture("detail-"+shot.name)
		await finish()
		return
	if "--fixture" in OS.get_cmdline_user_args():
		scope="Water route from an explicit post-Ruby equipment fixture and field entrance. No water progression granted. Then isolated water failure contracts. Full game incomplete."
		for key in ["sword","shield","mido","saria","slingshot","gohma","emerald","ocarina","zelda_letter","bottle","bracelet","bomb_bag","ruby"]: world.state[key]=true
		world.state.songs=["lullaby","epona","saria"]
		world.state.milk=2
		world.state.max_health=10
		world.state.health=10
		world.state.seeds=30
		world.state.bomb_count=20
		world.state.rupees=40
		world.apply_state()
		world.overworld.enter("field","kakariko")
	else:
		scope="New journey through the forest, mountain and water regions, Silver Scale, Ruto's letter and Jabu-Jabu's fish offering. Full game incomplete."
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
	await water_contracts()
	await finish()

func water_route() -> void:
	await walk(Vector3(35,0,-25))
	await walk(Vector3(40,0,-8))
	await walk(Vector3(53,0,-8))
	await press("interact")
	check("Eastern road enters Zora's River",world.area=="river")
	await capture("31-zoras-river")
	await walk(Vector3(-12,0,18))
	await walk(Vector3(-12,0,17.2))
	await press("bomb")
	await press("bomb")
	await walk(Vector3(-12,0,22))
	await seconds(4)
	check("A carried bomb breaks the riverbank rock",world.state.river_open)
	# Pass on the road before turning toward the ledge; the merchant occupies its west edge.
	await walk(Vector3(-12,0,11))
	await walk(Vector3(-15,0,8))
	await walk(Vector3(-8,0,3))
	await walk(Vector3(7,0,3))
	await walk(Vector3(7,0,-12))
	await walk(Vector3(7,2,-23))
	await walk(Vector3(0,2,-23))
	await press("interact")
	check("The waterfall does not admit a silent visitor",world.area=="river" and not world.state.waterfall_open)
	await play_notes(["left","up","right","left","up","right"])
	check("The royal melody parts the waterfall",world.state.waterfall_open and world.zora.waterfall_gate.collision_layer==0)
	await capture("32-waterfall")
	await walk(Vector3(0,2,-24.5))
	await press("interact")
	check("The parted waterfall leads into the Domain",world.area=="domain")
	await capture("33-domain")
	await walk(Vector3(-13,0,20))
	await walk(Vector3(-13,0,8))
	await walk(Vector3(-13,3,1))
	await press("interact")
	check("Paying the diving master begins a five-rupee round",world.zora.diving_time>0 and world.zora.diving_tokens.size()==5)
	await capture("34-diving-master")
	await walk(Vector3(-10.5,3,1))
	await walk(Vector3(-8,3,-1))
	await walk(Vector3(-6,0,2))
	Input.action_press("roll")
	await seconds(1)
	check("Walking off the board enters swimmable water",world.player.swimming)
	await capture("35-diving")
	await walk(Vector3(-2,-2,1))
	await walk(Vector3(2,-2,0))
	Input.action_release("roll")
	await seconds(1.1)
	check("Releasing the dive input returns toward the surface",world.player.position.y> -1.3)
	await walk(Vector3(5,0,4))
	Input.action_press("roll")
	await seconds(.9)
	await walk(Vector3(0,-2,6))
	await seconds(.25)
	Input.action_release("roll")
	check("All five submerged rupees complete the timed challenge",world.zora.diving_count==5 and world.state.diving_won)
	await walk(Vector3(-5,0,10))
	await walk(Vector3(-10,0,10))
	check("The pale pool ramp returns the swimmer to dry land",not world.player.swimming and world.player.position.y>-.15)
	await walk(Vector3(-13,0,8))
	await walk(Vector3(-13,3,1))
	await press("interact")
	check("Returning to the master awards the Silver Scale",world.state.silver_scale)
	await capture("36-silver-scale")
	await walk(Vector3(-13,0,8))
	await walk(Vector3(-10,0,10))
	await walk(Vector3(-5,0,10))
	await walk(Vector3(4,0,13.5))
	Input.action_press("roll")
	await seconds(1.3)
	await walk(Vector3(7,-4.6,13.5))
	await seconds(.15)
	check("The scale allows a deeper dive than the first pool challenge",world.player.position.y< -3.5)
	await press("interact")
	Input.action_release("roll")
	check("The submerged passage connects the Domain to Lake Hylia",world.area=="lake")
	await capture("37-lake-passage")
	await seconds(1.8)
	await walk(Vector3(-3,0,-10))
	Input.action_press("roll")
	await seconds(1.7)
	await press("interact")
	check("Diving to the bottle retrieves Ruto's letter",world.state.ruto_letter)
	await capture("38-rutos-letter")
	Input.action_release("roll")
	await seconds(1.9)
	await walk(Vector3(-7,0,10))
	await walk(Vector3(-7,0,20))
	check("The lake's sloping shore allows a swimmer to leave the water",not world.player.swimming and world.player.position.y>-.15)
	await capture("38b-lake-shore")
	await walk(Vector3(0,0,32))
	await press("interact")
	check("Lake Hylia also has a dry-land road to the field",world.area=="field")
	await press("interact")
	check("The southern field road returns to the lake",world.area=="lake")
	await walk(Vector3(-7,0,20))
	await walk(Vector3(-7,0,10))
	await walk(Vector3(-7,0,-11.5))
	Input.action_press("roll")
	await seconds(1.6)
	await press("interact")
	Input.action_release("roll")
	check("The underwater route works in the return direction",world.area=="domain")
	await seconds(1.6)
	await walk(Vector3(5,0,10))
	await walk(Vector3(10,0,10))
	await walk(Vector3(11,0,-6))
	await walk(Vector3(0,0,-6))
	await walk(Vector3(0,3,-18.35))
	await press("interact")
	check("The letter grants an empty bottle and the king's permission",world.state.letter_delivered and world.state.letter_bottle)
	await seconds(2)
	check("The king physically moves aside",world.npc_nodes.king_zora.position.x>4.4)
	await capture("39-king-zora")
	await walk(Vector3(0,0,-6))
	await walk(Vector3(11,0,-6))
	await walk(Vector3(12,0,5))
	await press("bottle")
	check("Bottle input catches a swimming spring fish",world.state.fish)
	await walk(Vector3(11,0,-6))
	await walk(Vector3(0,0,-6))
	await walk(Vector3(0,3,-22))
	await press("interact")
	check("The opened royal path reaches the sacred fountain",world.area=="fountain")
	await capture("40-jabu-jabu")
	await walk(Vector3(0,0,5.6))
	await press("bottle")
	await seconds(1.6)
	check("Offering the bottled fish opens the guardian's jaw",world.state.jabu_open and not world.state.fish and world.zora.jaw.rotation.x>.65)
	await capture("41-jabu-mouth")
	await press("save")
	world.state.silver_scale=false
	world.state.ruto_letter=false
	world.state.letter_delivered=false
	world.state.jabu_open=false
	world.load_game()
	check("Save and reload retain the scale, letter, royal passage and open mouth",world.state.silver_scale and world.state.ruto_letter and world.state.letter_delivered and world.state.jabu_open and world.area=="fountain")

func water_contracts() -> void:
	# Explicit isolated fixtures exercise refusal, timeout and surfacing contracts.
	world.state.silver_scale=false
	world.state.diving_won=false
	world.state.rupees=19
	world.overworld.enter("domain")
	world.player.position=Vector3(-13,3,1)
	await frames(8)
	await press("interact")
	check("The diving game refuses insufficient funds without a fee",world.state.rupees==19 and world.zora.diving_time==0)
	world.state.rupees=40
	await press("interact")
	await press("pause")
	var time:float=world.zora.diving_time
	await seconds(.25)
	check("Pausing freezes the diving clock",absf(time-world.zora.diving_time)<.001)
	await press("pause")
	world.zora.diving_time=.10
	await seconds(.2)
	check("A missed round expires without a scale or prize",world.zora.diving_time==0 and not world.state.silver_scale and not world.state.diving_won)
	await press("interact")
	check("A failed diving round can immediately be retried",world.zora.diving_time>0 and world.state.rupees==0)
	world.player.position=Vector3(0,-2,10)
	world.player.velocity=Vector3.ZERO
	await seconds(.2)
	var bombs:int=world.state.bomb_count
	var seeds:int=world.state.seeds
	await press("bomb")
	await press("shoot")
	await press("ocarina")
	check("Swimming blocks bomb, slingshot and instrument use",world.state.bomb_count==bombs and world.state.seeds==seeds and not world.instrument_open)
	# The preceding input guards take a variable number of rendered frames. Reset
	# this separate drowning fixture below the breath threshold before timing it.
	world.player.position=Vector3(0,-2,10)
	world.player.velocity=Vector3.ZERO
	world.player.air=.1
	Input.action_press("roll")
	await seconds(.4)
	var hurt:int=world.state.health
	check("Running out of air forces an ascent",world.player.forced_surface and world.player.velocity.y>0,{"y":world.player.position.y,"air":world.player.air,"velocity_y":world.player.velocity.y})
	await seconds(1.3)
	check("Holding dive cannot prevent emergency surfacing",world.player.position.y> -1.3 and world.state.health==hurt)
	Input.action_release("roll")
	await seconds(.2)
	check("Releasing the dive button resets emergency surfacing",not world.player.forced_surface)
	world.state.silver_scale=true
	world.state.letter_delivered=true
	world.state.letter_bottle=true
	world.overworld.enter("domain")
	world.player.position=Vector3(12,0,5)
	await frames(8)
	world.state.letter_bottle=false
	world.state.milk=2
	await press("bottle")
	check("A full milk bottle refuses to scoop up a fish",not world.state.fish and world.state.milk==2)
	world.state.letter_bottle=true
	await press("bottle")
	var fish_before=world.state.fish
	await press("bottle")
	check("Using a full fish bottle cannot catch a second fish",fish_before and world.state.fish)
	# A fish occupies the sole ranch bottle until the letter grants a second one.
	world.state.letter_bottle=false
	world.state.bottle=true
	world.state.milk=0
	world.state.fish=true
	world.state.talon_awake=true
	world.state.rupees=30
	world.overworld.enter("ranch")
	world.overworld.speak("talon_ranch")
	check("Milk cannot replace the fish in the only bottle",world.state.milk==0 and world.state.fish and world.state.rupees==30)
	world.state.letter_bottle=true
	world.overworld.speak("talon_ranch")
	check("A separate empty milk bottle can be refilled while carrying a fish",world.state.milk==2 and world.state.fish and world.state.rupees==20)
	world.overworld.enter("fountain")
	world.player.position=Vector3(0,.35,5.5)
	await frames(8)
	await press("bottle")
	check("An already-open mouth does not consume another fish",world.state.jabu_open and world.state.fish)
	world.state.silver_scale=false
	world.state.ruto_letter=false
	world.overworld.enter("lake")
	world.player.position=Vector3(-3,-4.8,-10)
	await frames(8)
	await press("interact")
	check("The deep bottle refuses retrieval without the diving skill",not world.state.ruto_letter)
	world.state.letter_delivered=false
	world.overworld.enter("domain")
	world.player.position=Vector3(0,3,-22.5)
	await frames(8)
	await press("interact")
	check("The sacred fountain refuses entry without the king's permission",world.area=="domain")
	world.load_game()
	await seconds(.4)
