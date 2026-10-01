extends "res://tests/playthrough.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	scope="Combat and recovery boundary fixtures. Direct position, phase and inventory setup; not campaign completion."
	await frames(20)
	world.start_game()
	world.state.sword=true
	world.state.shield=true
	world.state.slingshot=true
	world.state.seeds=0
	world.dungeon.enter("gohma")
	await frames(5)
	var boss:Node3D=world.creatures[0]
	world.player.position=Vector3(0,0,-1.6)
	world.player.visual.rotation.y=0
	boss.timer=30
	var before=boss.health
	for i in range(5): await press("attack")
	check("Sword spam cannot damage an unstunned boss",boss.health==before and world.stats.sword_hits==0)
	await press("shoot")
	check("Empty ammunition cannot create a shot",world.state.seeds==0 and world.stats.shots==0)
	world.state.seeds=10
	await press("target")
	await press("shoot")
	await get_tree().create_timer(.25).timeout
	check("Shooting an armored phase consumes a seed but causes no stun",world.state.seeds==9 and world.stats.stuns==0)
	await press("pause")
	var before_timer:float=boss.timer
	var before_position:Vector3=boss.position
	await get_tree().create_timer(.35).timeout
	check("Pause freezes enemy timer and movement",is_equal_approx(before_timer,boss.timer) and boss.position==before_position)
	await press("pause")
	world.player.lock_target=null
	world.player.visual.rotation.y=0
	world.player.invulnerable=0
	Input.action_press("shield")
	world.damage_player(1,world.player.position+Vector3(0,0,-2))
	check("Frontal shield guards damage",world.state.health==6 and world.stats.blocks==1)
	world.player.invulnerable=0
	world.damage_player(1,world.player.position+Vector3(0,0,2))
	check("Shield leaves the back vulnerable",world.state.health==5)
	Input.action_release("shield")
	world.damage_player(1,world.player.position+Vector3(0,0,2))
	check("Invulnerability prevents repeated contact damage",world.state.health==5)
	world.player.invulnerable=0
	world.player.rolling=.4
	world.damage_player(1,world.player.position+Vector3(0,0,2))
	check("Early roll can evade a hit",world.state.health==5)
	world.player.rolling=0
	world.state.web_burned=true
	world.damage_player(100,world.player.position+Vector3(0,0,2))
	check("Fatal damage disables movement and records death",world.state.health==0 and not world.player.enabled and world.stats.deaths==1)
	await capture("01-defeat")
	await press("interact")
	check("E retries at the room entrance with inventory and solved passages",world.player.enabled and world.area=="deku_gohma" and world.state.health==6 and world.state.web_burned and world.state.sword and world.state.seeds>=15 and world.player.position.z>7)
	world.player.invulnerable=0
	world.fall_recover()
	check("Falling costs health instead of healing the player",world.state.health==5)
	world.state.web_burned=false
	world.dungeon.enter("basement")
	world.torch_time=.05
	await get_tree().create_timer(.2).timeout
	check("Carried fire expires without burning a remote web",world.torch_time==0 and not world.state.web_burned)
	world.player.position=Vector3(6.5,0,0)
	world.torch_time=10
	await frames(3)
	check("Water extinguishes the carried flame",world.torch_time==0)
	world.state.slingshot=false
	world.state.scrubs_solved=true
	world.dungeon.enter("scrubs")
	check("Boss guard prevents entering without required slingshot",not world.dungeon.can_enter("gohma"))
	world.state.scrubs_solved=false
	world.dungeon.enter("scrubs")
	for enemy in world.creatures:
		enemy.surrendered=true
		world.dungeon.scrub_surrendered(enemy)
	world.dungeon.speak_scrub("scrub_1")
	check("Wrong brother order resets the puzzle and interactions",not world.state.scrubs_solved and world.dungeon.scrub_order.is_empty() and world.creatures.all(func(e): return not e.surrendered) and world.interactions.all(func(i): return not str(i.id).begins_with("scrub_")))
	await capture("02-recovery")
	world.state.time_of_day=.82
	world.overworld.enter("field")
	world.overworld.travel("market")
	check("Night drawbridge refuses town access",world.area=="field")
	world.overworld.interact("camp")
	world.overworld.travel("market")
	check("Dawn rest opens town access",world.area=="market")
	world.state.talon_awake=false
	world.state.egg=true
	world.state.egg_day=world.state.day
	world.overworld.enter("castle")
	world.overworld.speak("talon")
	check("Unhatched egg does not wake Talon",not world.state.talon_awake and world.overworld.delivery_gate.collision_layer==1)
	world.state.ocarina=true
	world.state.songs=[]
	world.state.epona_friend=false
	world.overworld.enter("ranch")
	await press("ocarina")
	for note in ["up","left","right","up","left","right"]: await press("note_"+note)
	check("Correct but unlearned melody grants no effect",not world.state.epona_friend and world.instrument_open)
	await press("ocarina")
	world.learn_song("epona")
	await press("ocarina")
	for note in ["up","up","right","up","left","right"]: await press("note_"+note)
	check("Wrong notes do not trigger a learned song",not world.state.epona_friend and world.instrument_open)
	await press("pause")
	check("Putting the ocarina away restores movement",not world.instrument_open and world.player.enabled)
	world.state.bottle=true
	world.state.milk=2
	world.state.health=1
	await press("milk")
	check("Milk restores hearts and consumes one serving",world.state.health==6 and world.state.milk==1)
	await press("mute")
	check("M mutes the audio bus",AudioServer.is_bus_mute(0))
	await press("mute")
	check("M restores audio",not AudioServer.is_bus_mute(0))
	await capture("03-world-boundaries")
	await finish()
