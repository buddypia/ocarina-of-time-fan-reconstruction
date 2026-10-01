extends "res://tests/world_playthrough.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	scope="Bomb and King Dodongo combat fixture: direct setup of equipment and arena; not a new-journey playthrough."
	await frames(30)
	world.start_game()
	for key in ["sword","shield","slingshot","bracelet","bomb_bag"]: world.state[key]=true
	world.state.seeds=30
	world.state.bomb_count=20
	world.state.health=10
	world.state.max_health=10
	world.dodongo.enter("king")
	await frames(20)
	await capture("01-king-arena")
	await king_fight()
	check("King Dodongo falls to swallowed bombs and sword openings",world.state.king_dodongo and world.stats.bombs_swallowed>=3 and world.stats.sword_hits>=12)
	await capture("02-king-defeated")
	await bomb_contracts()
	await finish()

func king_fight() -> void:
	var boss:Node3D
	for enemy in world.creatures:
		if enemy.kind=="king_dodongo": boss=enemy
	await press("target")
	var attacked=false
	for i in range(14000):
		if world.state.king_dodongo or world.state.health<=0: break
		if not is_instance_valid(boss):
			check("Arena did not reset during the encounter",false)
			return
		var flat:Vector3=boss.position-world.player.position
		flat.y=0
		var distance=flat.length()
		if not is_instance_valid(world.player.lock_target) and distance<17: await press("target")
		var desired=2.45 if boss.mode=="stunned" else 5.0
		# Stay on the outer half of the arena while the boss approaches.
		if boss.mode=="roll":
			Input.action_release("forward")
			Input.action_release("back")
			var radial=Vector3(world.player.position.x,0,world.player.position.z)
			var direction=radial.normalized().rotated(Vector3.UP,-world.player.yaw) if radial.length()<14.5 else Vector3.ZERO
			Input.action_press("right",maxf(0,direction.x))
			Input.action_press("left",maxf(0,-direction.x))
			Input.action_press("back",maxf(0,direction.z))
			Input.action_press("forward",maxf(0,-direction.z))
		else:
			Input.action_release("right")
			Input.action_release("left")
			Input.action_press("forward",1 if distance>desired+.2 and distance<9 else 0)
			Input.action_press("back",1 if distance<desired-.3 else 0)
		if boss.mode=="inhale" and distance<7:
			Input.action_release("forward")
			Input.action_release("back")
			if not is_instance_valid(world.held_bomb) and world.bombs.is_empty(): await press("bomb")
			elif is_instance_valid(world.held_bomb): await press("bomb")
		elif boss.mode=="stunned" and distance<2.95 and world.attack_cooldown<=0:
			await press("attack")
			if not attacked:
				await capture("01b-king-opening")
				var on_screen=world.player.camera.unproject_position(world.player.position+Vector3.UP*.7)
				check("Combat camera keeps Link inside the viewport",Rect2(16,100,1248,590).has_point(on_screen),{"screen":str(on_screen),"camera":str(world.player.camera.position),"player":str(world.player.position)})
				attacked=true
		await get_tree().physics_frame
	for action in ["forward","back","left","right","shield"]: Input.action_release(action)
	check("King encounter terminates without a death retry",world.stats.deaths==0,{"health":world.state.health,"boss_hp":boss.health,"mode":boss.mode,"bombs_left":world.state.bomb_count,"player":str(world.player.position)})

func bomb_contracts() -> void:
	world.player.position=Vector3(0,0,11)
	await frames(8)
	await press("interact")
	var rewarded_health=world.state.max_health
	world.dodongo.enter("king")
	world.player.position=Vector3(0,0,11)
	await frames(8)
	await press("interact")
	check("Revisiting the defeated king cannot duplicate the heart container",world.state.ruby and world.state.max_health==rewarded_health)
	world.state.health=world.state.max_health
	world.state.bracelet=false
	world.overworld.enter("trail")
	world.player.position=Vector3(-4.5,3,5)
	await frames(8)
	await press("interact")
	check("A Bomb Flower rejects hands without the bracelet",not is_instance_valid(world.held_bomb))
	world.state.bracelet=true
	await press("interact")
	check("The same flower becomes carryable with the bracelet",is_instance_valid(world.held_bomb))
	var active_bomb=world.held_bomb
	await press("pause")
	var remaining:float=active_bomb.fuse
	await seconds(.3)
	await press("interact")
	check("Pause freezes the fuse and blocks dropping",is_instance_valid(world.held_bomb) and absf(active_bomb.fuse-remaining)<.001)
	await press("pause")
	world.state.ocarina=true
	await press("ocarina")
	check("A carried lit bomb prevents opening the instrument",not world.instrument_open and world.player.enabled)
	var seeds=world.state.seeds
	await press("shoot")
	check("Carrying a bomb occupies the slingshot hand",world.state.seeds==seeds)
	world.dodongo.enter("stairs")
	check("Scene travel releases carried explosives without a stale holder",world.held_bomb==null and world.bombs.is_empty())
	world.state.bomb_count=0
	await press("bomb")
	check("An empty Bomb Bag cannot create a bomb",world.bombs.is_empty())
	world.state.bomb_bag=false
	world.state.bomb_count=5
	await press("bomb")
	check("Ammunition alone cannot bypass the Bomb Bag requirement",world.bombs.is_empty() and world.state.bomb_count==5)
	world.state.bomb_bag=true
	world.player.position=Vector3(0,0,6)
	world.player.invulnerable=0
	world.player.visual.rotation.y=0
	await frames(5)
	await press("bomb")
	check("Taking one bomb decrements the bag exactly once",world.state.bomb_count==4 and world.bombs.size()==1)
	await press("interact")
	var hearts=world.state.health
	await seconds(4)
	check("Remaining beside an unshieldable explosion costs a heart",world.state.health==hearts-2 and world.bombs.is_empty())
	world.player.position=Vector3(1,0,0)
	world.player.invulnerable=0
	var wall=ForestArt.collision_box(world.landscape,Vector3(0,1,0),Vector3(.3,2,5))
	await frames(6)
	hearts=world.state.health
	world.spawn_bomb(Vector3(-1,.3,0),false,.1)
	await seconds(.4)
	check("A solid wall blocks blast damage to Link",world.state.health==hearts)
	wall.queue_free()
	world.player.position=Vector3(8,0,8)
	world.spawn_bomb(Vector3(-4,.3,-4),false,.1)
	await seconds(1)
	check("Starting at one end fails the simultaneous flower seal",not world.state.dodongo_stairs and world.dodongo.chain_times.size()==5)
	await seconds(5.3)
	var reset=world.dodongo.chain_times.is_empty()
	for flower in world.dodongo.chain_nodes.values(): reset=reset and flower.visible
	check("A failed flower chain regrows into a retryable puzzle",reset)
	world.spawn_bomb(Vector3(0,.3,-4),false,.1)
	await seconds(1)
	check("A central blast satisfies the simultaneous flower seal",world.state.dodongo_stairs)
	world.dodongo.enter("cavern")
	world.state.dodongo_eyes=[]
	world.interact("dodongo:king")
	check("The boss route rejects an unlit skull",world.area=="dodongo_cavern")
	world.state.dodongo_eyes=["-1"]
	world.interact("dodongo:king")
	check("Lighting only one eye cannot open the boss route",world.area=="dodongo_cavern")
	world.dodongo.enter("armory")
	world.state.bomb_count=2
	world.interact("bomb_bag")
	check("Reopening the Bomb Bag chest cannot duplicate its ammunition",world.state.bomb_count==2)
	world.interact("bomb_supply")
	check("A supply jar restores ammunition for another attempt",world.state.bomb_count==20 and world.state.seeds==30)
	world.state.king_dodongo=false
	world.dodongo.enter("king")
	var boss=world.creatures[0]
	world.player.position=boss.position+Vector3(0,0,2.5)
	world.player.invulnerable=0
	boss.rotation.y=0
	boss.change_mode("idle",10)
	await frames(4)
	var initial_hp=boss.health
	check("King Dodongo's closed armor rejects the sword",not boss.sword_hit() and boss.health==initial_hp)
	boss.projectile_hit("seed",false)
	boss.blast_hit()
	check("Seeds and external blasts cannot skip the swallowing mechanic",boss.health==initial_hp and boss.mode!="stunned")
	await capture("03-armored-king")
