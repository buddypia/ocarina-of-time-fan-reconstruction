extends "res://tests/forest_playthrough.gd"

func run(target:Node3D) -> void:
	world=target
	if OS.has_environment("OOT_EVIDENCE_DIRECTORY"): output=OS.get_environment("OOT_EVIDENCE_DIRECTORY")
	headless=DisplayServer.get_name()=="headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	world.save_path=output+"/test-save.json"
	await frames(25);world.start_game()
	scope="Explicit adult, post-Forest equipment fixture: bow, Hookshot, bombs, bracelet, songs, 12 health. Input-driven adult Goron City, crater and first three Fire Temple cells; target selection is assisted. Upper temple and final visual quality are incomplete."
	for key in ["sword","shield","ocarina","ocarina_of_time","adult","master_sword","light_medallion","castle_escape","emerald","ruby","sapphire","zelda_letter","mountain_pass","hookshot","hylian_shield","stones_placed","door_of_time","sword_inspected","bracelet","bomb_bag","bow","forest_medallion"]: world.state[key]=true
	world.state.songs=["lullaby","saria","epona","time","minuet","prelude"]
	world.state.arrows=30;world.state.bomb_count=20;world.state.max_health=12;world.state.health=12
	if OS.has_environment("OOT_FIRE_SAVE"):
		world.save_path=OS.get_environment("OOT_FIRE_SAVE");world.load_game();world.save_path=output+"/test-save.json"
		scope+=" Resume source: "+OS.get_environment("OOT_FIRE_SAVE")
	world.apply_state()
	if "--capture-only" in OS.get_cmdline_user_args():
		world.state.goron_tunic=true
		world.overworld.enter("crater")
		await seconds(1);await capture("100-crater-arrival")
		await crater_crossing()
		await first_cell()
		await finish();return
	if OS.get_environment("OOT_FIRE_STAGE")=="contracts":
		await fire_contracts();await finish();return
	if OS.get_environment("OOT_FIRE_STAGE")=="art":
		await fire_views();await finish();return
	await city_route()
	await crater_crossing()
	await first_cell()
	await side_cells()
	await press("save")
	var original=world.state.duplicate(true)
	world.state.fire_keys=99;world.state.goron_tunic=false;world.load_game()
	check("Save restores three rescues, two remaining keys and tunic",world.state.fire_keys==2 and world.state.fire_rescued.size()==3 and world.state.goron_tunic and world.state.fire_chests==original.fire_chests)
	await play_notes(["down","a","down","a","right","down","right","down"])
	check("Bolero returns from the temple to the crater circle",world.area=="crater" and world.player.position.z< -8)
	await capture("109-crater-return")
	await press("save")
	await finish()

func city_route() -> void:
	world.overworld.enter("goron")
	await seconds(.4)
	var rolling_at=world.fire_quest.son.ball.global_position
	await seconds(.4);await capture("100-empty-goron-city")
	check("Rolling visual stays attached and is excluded from static batching",world.fire_quest.son.ball.global_position.distance_to(rolling_at)>.5 and world.fire_quest.son.ball.get_child(0).is_visible_in_tree())
	check("Adult Goron City excludes the child residents",not world.npc_nodes.has("darunia") and not world.npc_nodes.has("goron_elder"))
	await walk(Vector3(0,0,6))
	for attempt in range(12):
		if world.state.goron_stopped: break
		await shoot(world.fire_quest.son,"bow",.10)
	check("An actual arrow stops the rolling Goron",world.state.goron_stopped)
	check("The curled form disappears when the Goron stands up",not world.fire_quest.son.ball.is_visible_in_tree() and world.fire_quest.son.standing.is_visible_in_tree())
	if not world.state.goron_stopped: await finish();return
	var at=world.fire_quest.son.position
	world.player.lock_target=null
	await approach_use("fire:son",at+Vector3(0,0,1.5))
	await press("interact");await press("interact")
	check("Three conversations earn the Goron Tunic",world.state.goron_tunic and world.state.goron_son_stage==3)
	check("Receiving the tunic keeps the speaker in place and opens the gate",is_instance_valid(world.fire_quest.son) and world.fire_quest.son.position.distance_to(at)<.01 and not world.fire_quest.city_gate.visible)
	await capture("101-goron-tunic")
	await walk(Vector3(0,0,-10))
	await walk(Vector3(0,0,-18))
	await approach_use("fire:statue",Vector3(0,0,-21))
	check("Pulling the statue begins a physical movement",world.fire_quest.statue_time>0)
	check("Moving statue cannot be saved",not world.save_game())
	await seconds(2)
	check("The statue clears the crater passage",world.state.goron_statue and world.fire_quest.statue.position.x>3.9)
	await walk(Vector3(0,0,-23.8));await press("interact")
	check("The hidden passage reaches the crater",world.area=="crater")
	await capture("102-crater-arrival")

func crater_crossing() -> void:
	await walk(Vector3(0,0,5))
	await shoot(world.graveyard.targets[0],"hookshot")
	await seconds(2)
	check("Hookshot crosses the broken bridge using real collision",world.player.position.z< -2 and world.player.position.y>-.1)
	world.player.lock_target=null
	await capture("103-crater-bridge-crossed")
	await approach_use("fire:sheik",Vector3(-3,0,-4))
	check("Sheik teaches Bolero of Fire",world.state.songs.has("bolero"))
	await walk(Vector3(0,0,-10))
	await walk(Vector3(0,0,-22.9));await press("interact")
	check("Crater descent enters Fire Temple",world.area=="fire_foyer")
	await capture("104-fire-foyer")

func fire_door(next:String) -> void:
	var old=world.area
	for entry in world.fire_temple.data.rooms[world.fire_temple.room].exits:
		if entry.to!=next: continue
		var at=world.vec(entry.at);var inward=Vector3(-at.x,0,-at.z).normalized()
		await approach_use("fire_t:door:"+next,at+inward*1.5)
		check("Fire passage "+old+" to "+next,world.area=="fire_"+next)
		return

func first_cell() -> void:
	await fire_door("near")
	await approach_use("fire_t:darunia",Vector3(2,0,10.5));await press("interact")
	check("Darunia entrusts the prisoners to Link",world.state.fire_darunia_stage==2)
	await capture("105-darunia-crossing")
	await walk(Vector3(0,0,7));await walk(Vector3(-8,0,3));await walk(Vector3(-8,0,-4.5));await seconds(.2)
	check("Standing on the switch opens the first cell",world.state.fire_rescued.has("near"))
	var bars=world.fire_temple.cages.near.get_node("Bars")
	check("Cell bars visibly rise while the collision body moves",bars is AnimatableBody3D and bars.position.y>0 and bars.position.y<3.4 and bars.is_visible_in_tree())
	check("A moving cell cannot be saved",not world.save_game())
	await press("pause");var stopped_y=bars.position.y;await seconds(.5)
	check("Pause holds the cell gate in place",is_equal_approx(bars.position.y,stopped_y))
	await capture("105a-cell-opening")
	await press("pause");await seconds(1.8)
	check("The raised gate leaves a clear passage",is_equal_approx(bars.position.y,3.4) and world.fire_temple.lifting.is_empty())
	await approach_use("fire_t:prisoner:near",Vector3(-8.8,0,-7.9))
	await approach_use("fire_t:chest:near",Vector3(-7,0,-8))
	check("First rescue earns a Small Key",world.state.fire_keys==1)
	await capture("106-first-goron-rescue")
	await walk(Vector3(-8,0,-4));await walk(Vector3(-8,0,3));await walk(Vector3(0,0,7))
	await fire_door("foyer")

func side_cells() -> void:
	await fire_door("lava")
	check("Eastern door consumes exactly one key",world.state.fire_keys==0 and world.state.fire_doors==["entrance_east"])
	await walk(Vector3(0,0,0));await fire_door("curved")
	await walk(Vector3(-3,0,-1));await seconds(.2)
	check("Western cell opens from its own switch",world.state.fire_rescued.has("curved"))
	await approach_use("fire_t:chest:curved",Vector3(1,0,-4.8))
	await fire_door("lava")
	await walk(Vector3(0,0,0));await walk(Vector3(8.6,0,0))
	world.player.yaw=-PI/2;world.player.visual.rotation.y=-PI/2
	await press("bomb");await seconds(.15);await press("bomb")
	await walk(Vector3(4,0,0));await seconds(4)
	check("A thrown bomb opens the concealed eastern cell",world.state.fire_walls.has("cell_wall"))
	await capture("107-lava-bridge")
	await fire_door("blocked")
	await walk(Vector3(-3,0,-1));await seconds(.2)
	await approach_use("fire_t:prisoner:blocked",Vector3(-.8,0,-4.9))
	await approach_use("fire_t:chest:blocked",Vector3(1,0,-4.8))
	check("Three distinct prisoners yield three distinct keys",world.state.fire_rescued.size()==3 and world.state.fire_chests.size()==3 and world.state.fire_keys==2)
	await press("interact")
	check("The same chest cannot yield another key",world.state.fire_keys==2)
	await capture("108-third-goron-rescue")

func fire_contracts() -> void:
	scope="Isolated boundary fixtures: room entries, inventory, health and near-expiry heat are set explicitly. These checks do not establish ordinary acquisition."
	world.fire_temple.enter("foyer")
	await fire_door_refused()
	world.state.goron_tunic=true
	world.overworld.enter("crater")
	await walk(Vector3(0,0,5))
	var health=world.state.health
	Input.action_press("right");await seconds(.75);Input.action_release("right")
	await seconds(2)
	check("Lava burns through the tunic and restores a ledge",world.state.health<health and world.player.position.y>-.5)
	world.state.goron_tunic=false
	world.state.fire_heat_elapsed=world.fire_quest.heat_limit()-.4
	await press("pause");var before=world.state.fire_heat_elapsed;await seconds(1)
	check("Heat pauses with gameplay",world.state.fire_heat_elapsed==before)
	await press("pause");await seconds(.8)
	check("Unprotected heat causes damage",world.state.fire_heat_elapsed<2)
	world.state.goron_tunic=true;await seconds(.1)
	check("Wearing the tunic clears ambient heat",world.state.fire_heat_elapsed==0)
	world.learn_song("bolero")
	await press("ocarina");await press("note_down");await press("note_down")
	check("An invalid melody prefix resets without warping",world.instrument_open and world.played_notes.is_empty())
	for note in ["down","a","down","a","right","down","right","down"]: await press("note_"+note)
	await seconds(.2)
	check("Eight notes can be retried without reopening the ocarina",not world.instrument_open and world.player.position.z< -8)
	check("Bolero sets the retry point on the safe warp circle",world.checkpoint.area=="crater" and world.checkpoint.position.z< -8)
	world.learn_song("sun");world.learn_song("storms")
	await press("ocarina");await capture("110-nine-song-instrument");await press("ocarina")
	world.state.adult=false;world.apply_state()
	await play_notes(["down","a","down","a","right","down","right","down"])
	await approach_use("fire:temple",Vector3(0,0,-22.9))
	check("Childhood cannot enter the adult Fire Temple",world.area=="crater")
	world.overworld.enter("goron")
	check("Childhood still builds Darunia and the old residents",world.npc_nodes.has("darunia") and world.npc_nodes.has("goron_elder"))
	world.state.adult=true;world.state.goron_stopped=false
	world.overworld.enter("goron");await seconds(.1)
	# Explicitly placed short-fuse bomb isolates explosion delivery to this new actor.
	world.spawn_bomb(world.fire_quest.son.position+Vector3.UP*.2,false,.05)
	await seconds(.2)
	check("A physical bomb explosion also stops the rolling Goron",world.state.goron_stopped)
	world.state.fire_keys=1
	world.fire_temple.enter("foyer")
	await fire_door("lava");await fire_door("foyer")
	check("Returning through an unlocked door does not spend another key",world.state.fire_keys==0 and world.state.fire_doors.size()==1)
	world.state.fire_darunia_stage=2;world.state.fire_rescued=["near"];world.state.fire_chests=["near"]
	world.fire_temple.enter("near");await seconds(.2)
	check("Darunia's completed conversation leaves no empty prompt",not world.interactions.any(func(item): return item.id=="fire_t:darunia"))
	world.state.health=1;world.player.invulnerable=0;world.damage_player(2,world.player.position-Vector3.UP,false)
	await press("interact");await seconds(.2)
	check("Death retries the Fire Temple room with earned progress",world.area=="fire_near" and world.state.health==world.state.max_health and world.state.fire_chests==["near"] and is_equal_approx(world.fire_temple.cages.near.get_node("Bars").position.y,3.4))

func fire_views() -> void:
	scope="Fire chapter rendering fixture with prepared tunic and opened first cell. Three Goron angles and the crater silhouette; quality is assessed from images, not check counts."
	world.state.goron_tunic=true;world.state.fire_rescued=["near"];world.state.fire_darunia_stage=2
	world.fire_temple.enter("near")
	await seconds(.3);await press("pause");world.message_panel.hide()
	var resident=world.fire_temple.prisoners.near
	var camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.fov=45
	for view in [["111-goron-front",Vector3(2.2,1.6,3.6),Vector3(0,1.05,0)],["112-goron-back",Vector3(-2.2,1.6,-3.1),Vector3(0,1.05,0)],["113-goron-face",Vector3(.45,1.7,1.6),Vector3(0,1.68,0)]]:
		camera.position=resident.position+view[1];camera.look_at(resident.position+view[2]);await capture(view[0])
	for mesh in resident.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var mat=mesh.get_active_material(i)
			if mat is StandardMaterial3D and mat.resource_name=="Ochre mineral skin":
				check("Goron skin uses authored vertex pigmentation",mat.vertex_color_use_as_albedo)
	await press("pause");world.overworld.enter("crater");await seconds(.3)
	camera.position=Vector3(18,12,20);camera.look_at(Vector3(0,-1,0));world.message_panel.hide();await capture("114-crater-overview")
	world.player.camera.current=true;camera.queue_free()

func fire_door_refused() -> void:
	await approach_use("fire_t:door:lava",Vector3(8.5,0,0))
	check("The east door rejects a player with no Fire Temple key",world.area=="fire_foyer" and world.state.fire_doors.is_empty())
