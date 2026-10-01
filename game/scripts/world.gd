extends Node3D

const Art = preload("res://scripts/art.gd")
const PlayerScript = preload("res://scripts/player.gd")
const CreatureScript=preload("res://scripts/creature.gd")
const BombScript=preload("res://scripts/bomb.gd")
const ReptileScript=preload("res://scripts/reptile.gd")
const DodongoScript=preload("res://scripts/dodongo_dungeon.gd")
const JabuScript=preload("res://scripts/jabu_dungeon.gd")
const JabuEnemyScript=preload("res://scripts/jabu_enemy.gd")
const BoomerangScript=preload("res://scripts/boomerang.gd")
const ZoraScript=preload("res://scripts/zora.gd")
const MountainScript=preload("res://scripts/mountain.gd")
const ProjectileScript=preload("res://scripts/projectile.gd")
const OverworldScript=preload("res://scripts/overworld.gd")
const DungeonScript=preload("res://scripts/deku_dungeon.gd")
var player: CharacterBody3D
var landscape: Node3D
var hud: CanvasLayer
var status_label: Label
var objective_label: Label
var prompt_label: Label
var message_label: Label
var message_panel: PanelContainer
var title: PanelContainer
var interactions: Array = []
var rupees: Array = []
var gate: StaticBody3D
var fairy: Node3D
var chest_nodes: Dictionary = {}
var npc_nodes: Dictionary = {}
var started := false
var message_time := 0.0
var elapsed := 0.0
var nearest := ""
var area := "forest"
var state := {"sword":false,"shield":false,"mido":false,"rupees":0,"saria":false,"slingshot":false,"switches":[],"deku_entered":false,"collected":[],"health":6,"max_health":6,"seeds":0,"web_broken":false,"web_burned":false,"ladder_down":false,"scrubs_solved":false,"gohma":false,"emerald":false,"ocarina":false,"time_of_day":.36,"day":1,"egg":false,"egg_day":0,"talon_awake":false,"zelda_letter":false,"songs":[],"conversations":{},"bottle":false,"milk":0,"epona_friend":false,"mountain_pass":false,"darunia_door":false,"bracelet":false,"cavern_open":false,"bomb_bag":false,"bomb_count":0,"dodongo_stairs":false,"dodongo_duel":false,"dodongo_eyes":[],"dodongo_switches":[],"king_dodongo":false,"ruby":false,"world_collected":[],"cuccos":[],"cucco_reward":false,"river_open":false,"waterfall_open":false,"diving_won":false,"silver_scale":false,"ruto_letter":false,"letter_delivered":false,"letter_bottle":false,"fish":false,"jabu_open":false,"ruto_met":false,"ruto_rescued":false,"boomerang":false,"jabu_switches":[],"jabu_tentacles":[],"big_octo":false,"barinade":false,"sapphire":false,"ruto_room":"water","ruto_position":[-4,0,2],"ruto_altar":false,"jabu_map":false,"jabu_compass":false,"jabu_lift_lowered":false,"castle_escape":false,"ocarina_of_time":false,"stones_placed":false,"door_of_time":false,"master_sword":false,"adult":false,"light_medallion":false,"forest_medallion":false,"sword_inspected":false}
var state_defaults:Dictionary
var data: Dictionary
var save_path := "user://journey.json"
var verify_mode := false
var samples: Array[float] = []
var wall_samples: Array[float] = []
var area_samples:Dictionary={}
var previous_frame_usec := 0
var sound: AudioStreamPlayer
var creatures: Array = []
var dungeon:RefCounted
var overworld:RefCounted
var dodongo:RefCounted
var mountain:RefCounted
var zora:RefCounted
var jabu:RefCounted
var time_quest:RefCounted
var graveyard:RefCounted
var forest_temple:RefCounted
var woodland:RefCounted
var fire_quest:RefCounted
var fire_temple:RefCounted
var bow_draw:=0.0
var active_hook:Node3D
var water_zones:Array=[]
var carried_person:Node3D
var active_boomerang:Node3D
var bombs:Array=[]
var held_bomb:CharacterBody3D
var blast_targets:Array=[]
var bomb_flowers:Array=[]
var logic_time:=0.0
var instrument_open:=false
var played_notes:Array=[]
var muted:=false
var song_patterns:Dictionary={}
var ladders:Array=[]
var checkpoint:Dictionary={"area":"forest","position":Vector3(0,.3,14)}
var stats:Dictionary={"damage_taken":0,"blocks":0,"reflections":0,"sword_hits":0,"stuns":0,"eye_hits":0,"shots":0,"web_breaks":0,"deaths":0,"guard_catches":0,"songs_played":0,"bombs_thrown":0,"explosions":0,"bombs_swallowed":0,"rocks_broken":0}
var torch_time:=0.0
var shot_cooldown:=0.0
var attack_cooldown:=0.0
var target_marker:Label3D
var boss_label:Label
var world_environment:WorldEnvironment
var sunlight:DirectionalLight3D
var music:AudioStreamPlayer
var music_theme:=""
var hurt_flash:ColorRect
var quitting:=false
var controls_label:Label

func _ready() -> void:
	state.merge({"opened_graves":[],"royal_tomb_open":false,"hylian_shield":false,"hookshot":false,"dampe_won":false,"race_time_block":false,"race_best":-1.0,"race_heart":false,"heart_pieces":0,"grave_heart_revealed":false,"grave_heart":false,"windmill_heart":false})
	state.merge(preload("res://scripts/forest_temple.gd").defaults())
	state.merge(preload("res://scripts/fire_quest.gd").defaults())
	state_defaults=state.duplicate(true)
	get_tree().auto_accept_quit=false
	verify_mode = "--verify" in OS.get_cmdline_user_args()
	if OS.has_environment("OOT_SAVE_PATH"): save_path=OS.get_environment("OOT_SAVE_PATH")
	if verify_mode: save_path = "res://../evidence/authored-test-save.json"
	setup_inputs()
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/kokiri.json"))
	dungeon=DungeonScript.new(self)
	overworld=OverworldScript.new(self)
	mountain=MountainScript.new(self)
	dodongo=DodongoScript.new(self)
	zora=ZoraScript.new(self)
	jabu=JabuScript.new(self)
	time_quest=preload("res://scripts/time_quest.gd").new(self)
	graveyard=preload("res://scripts/graveyard.gd").new(self)
	forest_temple=preload("res://scripts/forest_temple.gd").new(self)
	woodland=preload("res://scripts/woodland.gd").new(self)
	fire_quest=preload("res://scripts/fire_quest.gd").new(self)
	fire_temple=preload("res://scripts/fire_temple.gd").new(self)
	song_patterns=JSON.parse_string(FileAccess.get_file_as_string("res://data/songs.json"))
	setup_environment()
	landscape = Node3D.new()
	add_child(landscape)
	build_forest()
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(0,.25,14)
	add_child(player)
	player.enabled = false
	player.equip(false,false)
	fairy = Node3D.new()
	add_child(fairy)
	var glow = Art.ellipsoid(fairy,Vector3.ZERO,Vector3.ONE*.055,Color("a8e3fa"))
	var fm = StandardMaterial3D.new()
	fm.albedo_color=Color("d2f3ff")
	fm.emission_enabled=true
	fm.emission=Color("8dcde5")
	glow.material_override=fm
	for side in [-1,1]:
		var wing=Art.ellipsoid(fairy,Vector3(side*.1,.07,0),Vector3(.055,.12,.018),Color("e3eee5"))
		wing.rotation.z=-side*.55
	setup_hud()
	setup_sound()
	target_marker=Label3D.new()
	target_marker.text="▼"
	target_marker.font_size=48
	target_marker.modulate=Color("f1cf66")
	target_marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	target_marker.pixel_size=.008
	add_child(target_marker)
	target_marker.hide()
	if verify_mode:
		var test_path="res://tests/dungeon_playthrough.gd" if "--dungeon" in OS.get_cmdline_user_args() else "res://tests/playthrough.gd"
		if "--combat" in OS.get_cmdline_user_args(): test_path="res://tests/combat_contract.gd"
		if "--world" in OS.get_cmdline_user_args(): test_path="res://tests/world_playthrough.gd"
		if "--mountain" in OS.get_cmdline_user_args(): test_path="res://tests/mountain_playthrough.gd"
		if "--zora" in OS.get_cmdline_user_args(): test_path="res://tests/zora_playthrough.gd"
		if "--jabu" in OS.get_cmdline_user_args(): test_path="res://tests/jabu_playthrough.gd"
		if "--time-quest" in OS.get_cmdline_user_args(): test_path="res://tests/time_playthrough.gd"
		if "--graveyard" in OS.get_cmdline_user_args(): test_path="res://tests/graveyard_playthrough.gd"
		if "--forest-temple" in OS.get_cmdline_user_args(): test_path="res://tests/forest_playthrough.gd"
		if "--fire-mountain" in OS.get_cmdline_user_args(): test_path="res://tests/fire_playthrough.gd"
		if "--bomb-test" in OS.get_cmdline_user_args(): test_path="res://tests/bomb_combat.gd"
		var runner = load(test_path).new()
		add_child(runner)
		runner.call_deferred("run",self)

func setup_inputs() -> void:
	var bindings = {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"interact":KEY_E,"attack":KEY_F,"shoot":KEY_R,"roll":KEY_SPACE,"shield":KEY_SHIFT,"camera_left":KEY_LEFT,"camera_right":KEY_RIGHT,"save":KEY_F5,"pause":KEY_ESCAPE,"target":KEY_Q,"ocarina":KEY_1,"note_a":KEY_J,"note_down":KEY_K,"note_right":KEY_L,"note_left":KEY_U,"note_up":KEY_I,"milk":KEY_B,"mute":KEY_M,"bomb":KEY_C,"boomerang":KEY_T,"bottle":KEY_V,"tool":KEY_X}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var event=InputEventKey.new()
		event.physical_keycode=bindings[action]
		InputMap.action_add_event(action,event)

func setup_environment() -> void:
	var env := Environment.new()
	env.background_mode=Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("5f897d")
	sky_mat.sky_horizon_color=Color("c5cc9f")
	sky_mat.ground_bottom_color=Color("31452a")
	sky_mat.ground_horizon_color=Color("c5cc9f")
	sky.sky_material=sky_mat
	env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("c5d5bd")
	env.ambient_light_energy=.38
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.fog_enabled=true
	env.fog_light_color=Color("869d79")
	env.fog_density=.007
	var world_env := WorldEnvironment.new()
	world_env.environment=env
	add_child(world_env)
	world_environment=world_env
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-32,0)
	sun.light_color=Color("fff2d7")
	sun.light_energy=.72
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=65
	add_child(sun)
	sunlight=sun

func vec(a: Array) -> Vector3:
	return Vector3(a[0],a[1],a[2])

func build_forest() -> void:
	area="forest"
	Art.box(landscape,Vector3(0,-.25,-7),Vector3(60,.5,90),Color("53613b"),true)
	# The walkway opens from Link's house to the village, shop and forest guardian.
	for z in range(-36,21,2):
		var path=Art.cylinder(landscape,Vector3(sin(z*.08)*1.4,.014,z),2.15,2.15,.028,Color("a79765"),14)
		path.scale.z=1.4
	for x in range(-18,15,2):
		Art.cylinder(landscape,Vector3(x,.014,-10),1.6,1.6,.028,Color("a79765"),12)
	for house in data.houses:
		Art.house(landscape,vec(house.position),house.scale,house.angle)
	Art.deku(landscape,Vector3(0,0,-44))
	var rng:=RandomNumberGenerator.new()
	rng.seed=924
	for i in range(44):
		var a = i*TAU/44.0
		var at=Vector3(sin(a)*rng.randf_range(24,31),0,cos(a)*rng.randf_range(33,42)-9)
		Art.tree(landscape,at,rng.randf_range(1.1,1.8),i)
	for at in [Vector3(-18,0,10),Vector3(20,0,1),Vector3(-7,0,-15),Vector3(8,0,-20),Vector3(-11,0,20)]:
		Art.tree(landscape,at,.8,int(at.x+60))
	# A small spring, stones and a wooden bridge frame the eastern route.
	Art.ellipsoid(landscape,Vector3(7,-.08,2),Vector3(4,.15,5),Color("537f7b"))
	for i in range(14):
		var a=i*TAU/14.0
		Art.ellipsoid(landscape,Vector3(7+cos(a)*4,.15,2+sin(a)*5),Vector3(.6,.4,.45),Color("8b9270"))
	for i in range(11):
		Art.box(landscape,Vector3(7,.20,-.5+i*.46),Vector3(1.9,.22,.4),Color("826442"),true)
	for x in [6.0,8.0]:
		Art.beam(landscape,Vector3(x,.8,-.6),Vector3(x,.8,4.2),.065,Color("5e4832"))
		for z in [-.5,1.8,4.0]: Art.beam(landscape,Vector3(x,0,z),Vector3(x,1,z),.09,Color("5e4832"))
	for i in range(180):
		var at=Vector3(rng.randf_range(-23,23),.02,rng.randf_range(-28,23))
		if absf(at.x)<3.4 or absf(at.z+10)<2.0 or at.distance_to(Vector3(7,0,2))<5.6: continue
		var leaf=Art.cylinder(landscape,at+Vector3.UP*.18,.15,0,.36,Color("526a37"),4)
		leaf.rotation.y=rng.randf()*TAU
		if i%6==0:
			Art.ellipsoid(landscape,at+Vector3.UP*.27,Vector3(.12,.065,.12),Color("ddd2a0"))
	# Sword clearing has a visible entrance and low maze walls, rather than an invisible reward.
	for p in [Vector3(-22,.55,-14),Vector3(-18,.55,-22),Vector3(-12,.55,-19)]:
		Art.box(landscape,p,Vector3(1.0,1.1,6.0) if p.x!=-18 else Vector3(8,1.1,1),Color("77775a"),true)
	interactions=data.interactions.duplicate(true)
	if state.adult: interactions=interactions.filter(func(item): return not item.id in ["saria","mido"])
	for item in interactions:
		var at=vec(item.position)
		if item.kind=="chest": chest_nodes[item.id]=Art.chest(landscape,at)
		if item.kind=="npc": make_npc(at,item.id)
		if item.kind=="shop":
			Art.box(landscape,at+Vector3(0,.5,-.9),Vector3(1.8,1,.5),Color("765336"),true)
			var shield=Art.cylinder(landscape,at+Vector3(0,1.3,-.8),.3,.3,.06,Color("a46938"),8)
			shield.rotation.x=PI/2
	for i in range(data.rupees.size()):
		var at=data.rupees[i]
		var node=Art.rupee(landscape,vec(at)+Vector3.UP*.65)
		var taken=i in state.collected
		node.visible=not taken
		rupees.append({"id":i,"position":vec(at),"node":node,"taken":taken})
	gate=Art.collision_box(landscape,Vector3(0,1,-25),Vector3(8,2,1))
	for x in [-6,6]: Art.tree(landscape,Vector3(x,0,-25),1.0,int(x+30))
	for side in [-1,1]:
		Art.ellipsoid(landscape,Vector3(side*17,1.0,-28),Vector3(13,3,3.5),Color("516341"))
		Art.collision_box(landscape,Vector3(side*17,1.5,-28),Vector3(24,3,3))
	# Physical world boundary, shaped by the outer forest wall.
	for x in [-29,29]: Art.collision_box(landscape,Vector3(x,3,-8),Vector3(1,6,89))
	Art.collision_box(landscape,Vector3(0,3,30),Vector3(60,6,1))
	Art.collision_box(landscape,Vector3(0,3,-50),Vector3(60,6,1))
	interactions.append({"id":"leave_forest","position":[-24,0,7],"label":"Leave for Hyrule Field"})
	Art.beam(landscape,Vector3(-26,0,4.7),Vector3(-26,4,4.7),.65,Color("66533c"))
	Art.beam(landscape,Vector3(-26,0,9.3),Vector3(-26,4,9.3),.65,Color("66533c"))
	Art.beam(landscape,Vector3(-26,3.7,4.7),Vector3(-26,3.7,9.3),.75,Color("66533c"))
	overworld.scene=landscape
	overworld.signpost(Vector3(-21,0,5),"Hyrule Field")
	woodland.forest_details()
	Art.batch_static(landscape)

func make_npc(at: Vector3, id: String) -> void:
	var npc:Node3D=load("res://assets/link.glb").instantiate()
	landscape.add_child(npc)
	npc_nodes[id]=npc
	npc.set_meta("animated",true)
	npc.position=at
	npc.rotation.y=PI if id=="saria" else 0.0
	for mesh in npc.find_children("*","MeshInstance3D",true,false):
		if "Cap" in mesh.name or "cap" in mesh.name: mesh.visible=false
		if "Hair" in mesh.name:
			mesh.material_override=Art.material(Color("2e6b41") if id=="saria" else Color("a8632d"))
	Art.collision_box(npc,Vector3.UP*.55,Vector3(.55,1.1,.55))

func setup_hud() -> void:
	hud=CanvasLayer.new()
	add_child(hud)
	hurt_flash=ColorRect.new()
	hurt_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hurt_flash.color=Color(.65,.06,.025,.22)
	hurt_flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hurt_flash.modulate.a=0
	hud.add_child(hurt_flash)
	var top=MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.add_theme_constant_override("margin_left",32)
	top.add_theme_constant_override("margin_top",25)
	hud.add_child(top)
	var column=VBoxContainer.new()
	top.add_child(column)
	status_label=label("♥ ♥ ♥    ◆ 0",26,Color("f0dfb2"))
	column.add_child(status_label)
	objective_label=label("KOKIRI FOREST",17,Color("e6dfc2"))
	column.add_child(objective_label)
	var bottom=VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top=-96
	bottom.offset_bottom=-22
	hud.add_child(bottom)
	prompt_label=label("",20,Color("f9e5ac"))
	prompt_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(prompt_label)
	var controls=label("WASD  Move     ← →  Camera     E  Use     Q  Focus     R  Slingshot     T  Boomerang     C  Bomb     F  Sword     Space  Roll / Dive     Shift  Guard     1  Ocarina     V  Bottle     B  Milk     M  Sound     F5  Save",12,Color("eee7ca"))
	controls_label=controls
	controls.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(controls)
	boss_label=label("",18,Color("dfbe8d"))
	boss_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	boss_label.position=Vector2(-350,104)
	boss_label.size=Vector2(315,55)
	boss_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(boss_label)
	message_panel=PanelContainer.new()
	message_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	message_panel.position=Vector2(-350,-224)
	message_panel.size=Vector2(700,100)
	message_panel.add_theme_stylebox_override("panel",panel_style())
	hud.add_child(message_panel)
	message_label=label("",20,Color("f0e5c3"))
	message_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size=Vector2(652,76)
	message_panel.add_child(message_label)
	message_panel.hide()
	title=PanelContainer.new()
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title.position=Vector2(-270,-175)
	title.size=Vector2(540,350)
	title.add_theme_stylebox_override("panel",panel_style())
	hud.add_child(title)
	var stack=VBoxContainer.new()
	stack.add_theme_constant_override("separation",12)
	title.add_child(stack)
	var small=label("THE LEGEND OF ZELDA",16,Color("c9b77a"))
	small.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(small)
	var heading=label("Ocarina of Time",38,Color("f4e9bd"))
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(heading)
	var subtitle=label("Authored Fan Reconstruction · Kokiri Forest",16,Color("c5caae"))
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(subtitle)
	var begin=Button.new()
	begin.text="Begin journey"
	begin.custom_minimum_size=Vector2(430,45)
	begin.pressed.connect(start_game)
	stack.add_child(begin)
	var resume=Button.new()
	resume.text="Continue saved journey"
	resume.disabled=not FileAccess.file_exists(save_path)
	resume.custom_minimum_size.y=40
	resume.pressed.connect(load_game)
	stack.add_child(resume)
	var disclaimer=label("Unofficial fan reconstruction · No ROMs included · Use at your own risk\nNot affiliated with or endorsed by Nintendo Co., Ltd.",11,Color("a6aa93"))
	disclaimer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(disclaimer)
	begin.grab_focus()

func panel_style() -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(.055,.105,.08,.95)
	style.border_color=Color("a6945d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left=24
	style.content_margin_right=24
	style.content_margin_top=18
	style.content_margin_bottom=18
	return style

func label(text: String, size: int, color: Color) -> Label:
	var out=Label.new()
	out.text=text
	out.add_theme_font_size_override("font_size",size)
	out.add_theme_color_override("font_color",color)
	out.add_theme_color_override("font_shadow_color",Color(0,0,0,.85))
	out.add_theme_constant_override("shadow_offset_y",2)
	return out

func start_game() -> void:
	title.hide()
	started=true
	player.enabled=true
	tell("Navi", "Link! The Great Deku Tree has summoned you. Saria is waiting by the path.")

func tell(speaker: String, text: String) -> void:
	message_label.text=speaker+"\n"+text
	message_time=7.0
	message_panel.show()
	message_panel.reset_size()
	chime(620,.13)

func _process(delta: float) -> void:
	var frame_usec=Time.get_ticks_usec()
	if started and previous_frame_usec>0:
		var interval=(frame_usec-previous_frame_usec)/1000000.0
		wall_samples.append(interval)
		if not area_samples.has(area): area_samples[area]=[]
		area_samples[area].append(interval)
		if area_samples[area].size()>3600: area_samples[area].pop_front()
	previous_frame_usec=frame_usec
	if wall_samples.size()>3600: wall_samples.pop_front()
	elapsed+=delta
	hurt_flash.modulate.a=move_toward(hurt_flash.modulate.a,0,delta*4)
	if started: samples.append(delta)
	if samples.size()>3600: samples.pop_front()
	message_panel.position.y=get_viewport().get_visible_rect().size.y-message_panel.size.y-120
	message_time-=delta
	if message_time<=0: message_panel.hide()
	fairy.position=player.position+Vector3(.6+sin(elapsed*1.9)*.12,1.6+sin(elapsed*2.8)*.09,0)
	if not time_quest.sequence.is_empty():
		objective_label.text=current_objective()
		status_label.text="SEVEN YEARS LATER · MASTER SWORD" if state.adult else "LINK · THREE SPIRITUAL STONES"
		time_quest.tick_sequence(delta)
		return
	if player.enabled:
		logic_time+=delta
		for flower in bomb_flowers:
			flower.cooldown=maxf(0,flower.cooldown-delta)
			flower.node.visible=flower.cooldown<=0
		torch_time=maxf(0,torch_time-delta)
		shot_cooldown=maxf(0,shot_cooldown-delta)
		attack_cooldown=maxf(0,attack_cooldown-delta)
		fire_quest.tick(delta)
		if area.begins_with("fire_"): fire_temple.tick(delta)
		elif area.begins_with("ft_"): forest_temple.tick(delta)
		elif area.begins_with("jabu_"): jabu.tick(delta)
		elif area.begins_with("dodongo_"): dodongo.tick(delta)
		elif area.begins_with("deku_"): dungeon.tick(delta)
		elif overworld.places.has(area): overworld.tick(delta)
	player.stick.visible=torch_time>0
	player.sling.visible=shot_cooldown>.25 and not state.adult
	player.hook_gun.visible=is_instance_valid(active_hook)
	player.bow.visible=state.adult and (bow_draw>0 or (state.adult_tool=="bow" and shot_cooldown>.1))
	if is_instance_valid(player.lock_target):
		target_marker.show()
		target_marker.position=aim_point(player.lock_target)+Vector3.UP*.55
	else: target_marker.hide()
	boss_label.text=""
	for enemy in creatures:
		if is_instance_valid(enemy) and enemy.kind in ["gohma","king_dodongo","barinade","big_octo","phantom"] and enemy.mode!="dead":
			var total=enemy.max_health if enemy.kind in ["barinade","big_octo","phantom"] else (12 if enemy.kind=="king_dodongo" else 9)
			var filled=ceili(clampf(float(enemy.health)/total,0,1)*12)
			boss_label.text=enemy.kind.replace("_"," ").to_upper()+"  "+str(enemy.health)+" / "+str(total)+"\n"+"▰".repeat(filled)+"▱".repeat(12-filled)
	for pickup in rupees:
		if pickup.taken: continue
		pickup.node.rotation.y=elapsed*1.3
		pickup.node.position.y=pickup.position.y+.65+sin(elapsed*2)*.06
		if started and player.enabled and player.position.distance_to(pickup.position)<.75:
			pickup.taken=true
			pickup.node.hide()
			if pickup.get("scope", "forest")=="forest": state.collected.append(pickup.id)
			elif pickup.scope=="world": state.world_collected.append(pickup.id)
			state.rupees=mini(99,int(state.rupees)+int(pickup.get("value",5)))
			chime(900,.12)
	nearest=""
	var best=2.05
	for item in interactions:
		if item.id=="ruto_carry" and is_instance_valid(carried_person): continue
		if item.id=="ruto_first" and state.ruto_met: continue
		var distance=player.position.distance_to(vec(item.position))
		if is_instance_valid(carried_person) and item.id.begins_with("jabu:") and distance>1.3: continue
		if distance<best:
			best=distance
			nearest=item.id
			prompt_label.text="E   "+item.label
	if nearest.is_empty(): prompt_label.text=""
	var hearts="♥ ".repeat(int(state.health/2))+("◐ " if int(state.health)%2 else "")+"♡ ".repeat(int((state.max_health-state.health)/2))
	status_label.text=hearts+"   ◆ %02d  • %02d    %s  %s" % [state.rupees,state.seeds,("MASTER SWORD" if state.master_sword else "") if state.adult else ("SWORD" if state.sword else ""), "SHIELD" if (state.hylian_shield if state.adult else state.shield) else ""]
	if state.adult and state.bow: status_label.text+="   ARROWS %02d  %s" % [state.arrows,state.adult_tool.to_upper()]
	if player.swimming: status_label.text+="   AIR %.1f" % player.air
	if state.bomb_bag: status_label.text+="   BOMBS %02d" % state.bomb_count
	if is_instance_valid(held_bomb): prompt_label.text="C  Throw bomb     E  Put down     Fuse %.1f" % held_bomb.fuse
	if is_instance_valid(carried_person): prompt_label.text="E  Put Ruto down / Use nearby passage     T  Throw Ruto"
	objective_label.text=current_objective()
	if not started: return
	update_music()
	if Input.is_action_just_pressed("mute"):
		muted=not muted
		AudioServer.set_bus_mute(0,muted)
		tell("Sound", "Muted. M turns sound on." if muted else "Sound on. M mutes sound.")
	if instrument_open:
		process_instrument()
		return
	if state.health<=0:
		prompt_label.text="E   Retry from the room entrance"
		if Input.is_action_just_pressed("interact"): retry_checkpoint()
		return
	if player.swimming and nearest.is_empty(): prompt_label.text="Space  Hold to dive · Release to surface"
	if player.climbing: prompt_label.text="W / S  Climb     Space  Let go"
	if Input.is_action_just_pressed("interact") and player.enabled:
		if is_instance_valid(held_bomb): held_bomb.throw_forward(true)
		elif is_instance_valid(carried_person) and not nearest.begins_with("jabu:") and nearest!="ruto_altar": jabu.put_ruto(false)
		else: interact(nearest)
	if Input.is_action_just_pressed("save"): save_game()
	if Input.is_action_just_pressed("pause"):
		player.enabled=not player.enabled
		tell("Paused" if not player.enabled else "Journey resumed", "Esc to return. F5 saves your journey.")
	if Input.is_action_just_pressed("attack") and player.enabled:
		if state.sword: swing_sword()
		else: tell("Navi", "Find the Kokiri Sword in the clearing to the west.")
	if player.enabled:
		if Input.is_action_just_pressed("tool") and state.adult and state.bow and not is_instance_valid(active_hook):
			bow_draw=0
			state.adult_tool="hookshot" if state.adult_tool=="bow" else "bow"
			chime(520,.1)
		if state.adult and state.adult_tool=="bow":
			if Input.is_action_pressed("shoot") and state.bow: bow_draw=minf(1.2,bow_draw+delta)
			if Input.is_action_just_released("shoot") and bow_draw>0:
				fire_arrow()
				bow_draw=0
		elif Input.is_action_just_pressed("shoot"): shoot_seed()
	if Input.is_action_just_pressed("target") and player.enabled:
		focus_target()
	if Input.is_action_just_pressed("ocarina") and player.enabled:
		if state.ocarina: open_instrument()
		else: tell("Navi", "You have not received an ocarina yet.")
	if Input.is_action_just_pressed("milk") and player.enabled: drink_milk()
	if Input.is_action_just_pressed("bomb") and player.enabled: use_bomb()
	if Input.is_action_just_pressed("boomerang") and player.enabled:
		if is_instance_valid(carried_person): jabu.put_ruto(true)
		else: throw_boomerang()
	if Input.is_action_just_pressed("bottle") and player.enabled: zora.use_bottle()

func current_objective() -> String:
	var fire_objective=fire_quest.objective()
	if not fire_objective.is_empty(): return fire_objective
	if area.begins_with("fire_"): return fire_temple.objective()
	var forest_objective=forest_temple.objective()
	if not forest_objective.is_empty(): return forest_objective
	var woods_objective=woodland.objective()
	if not woods_objective.is_empty(): return woods_objective
	var grave_objective=graveyard.objective()
	if not grave_objective.is_empty(): return grave_objective
	var time_objective=time_quest.objective()
	if not time_objective.is_empty(): return time_objective
	if area.begins_with("jabu_"): return jabu.objective()
	if area.begins_with("dodongo_"): return dodongo.objective()
	if overworld.places.has(area): return overworld.objective()
	if area.begins_with("deku_"): return dungeon.objective()
	if state.emerald: return "KOKIRI FOREST · Speak with Saria, then leave by the western forest tunnel"
	if not state.saria: return "KOKIRI FOREST · Speak to Saria by the path"
	if not state.sword: return "KOKIRI FOREST · Find the sword in the western clearing"
	if not state.shield: return "KOKIRI FOREST · Gather 40 rupees and visit the shop"
	if not state.mido: return "KOKIRI FOREST · Show Mido your sword and shield"
	return "KOKIRI FOREST · Enter the Great Deku Tree"

func interact(id: String) -> void:
	if not player.enabled: return
	if is_instance_valid(active_hook): return
	if fire_quest.interact(id): return
	if fire_temple.interact(id): return
	if forest_temple.interact(id): return
	if woodland.interact(id): return
	if graveyard.interact(id): return
	if time_quest.interact(id): return
	if id.begins_with("flower:"):
		pick_bomb_flower(id.trim_prefix("flower:"))
		return
	if area.begins_with("jabu_") and jabu.interact(id): return
	if area.begins_with("dodongo_") and dodongo.interact(id): return
	if overworld.places.has(area) and zora.interact(id): return
	if overworld.places.has(area) and mountain.interact(id): return
	if overworld.places.has(area) and overworld.interact(id): return
	if id.begins_with("room:"):
		var next=id.trim_prefix("room:")
		if dungeon.can_enter(next): dungeon.enter(next,dungeon.room)
		return
	if id.begins_with("climb:"):
		for route in ladders:
			if route.id==id.trim_prefix("climb:"): player.start_climbing(route.base,route.top)
		return
	if id.begins_with("scrub_"):
		dungeon.speak_scrub(id)
		return
	match id:
		"leave_forest":
			if not state.emerald: tell("Navi", "The Great Deku Tree needs us. We cannot leave the forest before lifting his curse.")
			elif not state.ocarina: tell("Navi", "Saria is waiting by the path. Say goodbye before setting out.")
			else: overworld.enter("field","forest")
		"saria":
			state.saria=true
			if state.zelda_letter:
				learn_song("saria")
				tell("Saria", "The forest still remembers your footsteps. Learn my song: down, right, left; down, right, left. Even far away, we can listen for one another.")
			elif state.emerald:
				state.ocarina=true
				tell("Saria", "Take my ocarina, Link. Whenever you play it, remember your friends in the forest. The princess may know what the emerald means.")
			else: tell("Saria", "A fairy! I'm so happy for you, Link. Find a sword in the western clearing, then buy a shield at the shop.")
		"sword":
			if state.sword: tell("Kokiri Sword", "The chest is empty. Your sword is equipped. Press F to swing.")
			else:
				state.sword=true
				open_chest("sword")
				player.equip(state.sword,state.shield)
				tell("Kokiri Sword", "You found the Kokiri Sword! F swings your sword. Gather blue rupees along the path for a shield.")
		"shop":
			if state.shield: tell("Kokiri Shop", "Your Deku Shield is ready. Hold Shift to guard.")
			elif state.rupees<40: tell("Kokiri Shop", "A Deku Shield costs 40 rupees. You need %d more." % (40-state.rupees))
			else:
				state.rupees-=40
				state.shield=true
				player.equip(state.sword,state.shield)
				tell("Deku Shield", "You bought the Deku Shield! Hold Shift to guard. Show Mido that you are ready.")
		"mido":
			if state.sword and state.shield:
				state.mido=true
				gate.collision_layer=0
				create_tween().tween_property(npc_nodes.mido,"position:x",1.8,.65)
				tell("Mido", "You actually found a sword and shield? All right, go ahead. The Great Deku Tree is waiting.")
			else: tell("Mido", "You need a sword AND a shield before I can let you through.")
		"deku":
			if state.mido: enter_deku()
			else: tell("Navi", "Prepare a sword and shield before going into the Great Deku Tree.")
		"slingshot":
			if not state.slingshot: state.seeds=30
			state.slingshot=true
			open_chest("slingshot")
			tell("Fairy Slingshot", "You found the Fairy Slingshot! Q focuses an enemy or eye switch. R fires a seed. Find seed pots when you run low.")
		"seeds":
			state.seeds=30
			tell("Deku Seeds", "Your seed bag is full: 30 seeds.")
		"light_stick":
			torch_time=12
			tell("Deku Stick", "The stick is burning. Carry it to the web before the flame dies!")
		"deku_complete":
			if not state.emerald:
				state.emerald=true
				state.max_health+=2
			state.health=state.max_health
			return_forest()
			tell("Great Deku Tree", "The curse was the work of a man from the desert. Carry the Kokiri Emerald to Princess Zelda. Protect this land, Link.")
		"exit": return_forest()

func open_chest(id: String) -> void:
	if chest_nodes.has(id): create_tween().tween_property(chest_nodes[id].get_node("Lid"),"rotation:x",-1.15,.5)
	chime(1046,.5)

func clear_landscape() -> void:
	if is_instance_valid(active_hook): active_hook.cancel()
	if graveyard: graveyard.reset()
	if forest_temple: forest_temple.reset()
	if fire_quest: fire_quest.reset()
	if fire_temple: fire_temple.reset()
	bow_draw=0
	water_zones=[]
	carried_person=null
	active_boomerang=null
	if is_instance_valid(player):
		player.swimming=false
		player.forced_surface=false
		player.air=8
	held_bomb=null
	bombs=[]
	blast_targets=[]
	bomb_flowers=[]
	if is_instance_valid(player): player.lock_target=null
	creatures=[]
	ladders=[]
	remove_child(landscape)
	landscape.queue_free()
	landscape=Node3D.new()
	add_child(landscape)
	interactions=[]
	rupees=[]
	chest_nodes={}
	npc_nodes={}

func enter_deku() -> void:
	dungeon.enter("lobby")

func return_forest() -> void:
	clear_landscape()
	build_forest()
	set_ambience(false)
	apply_state()
	player.position=Vector3(0,.3,-33)
	player.yaw=PI
	player.update_camera(1.0)
	checkpoint={"area":"forest","position":player.position}

func save_game() -> bool:
	if fire_quest.statue_time>0 or not fire_temple.lifting.is_empty() or ((area=="crater" or area.begins_with("fire_")) and not player.is_on_floor()):
		tell("Action in progress","Reach a safe ledge and let moving stone settle before saving.")
		return false
	if not forest_temple.moving.is_empty() or forest_temple.amy_time>0 or forest_temple.rotation_time>0:
		tell("Puzzle in progress","Finish the moving block or timed portrait before saving.")
		return false
	if is_instance_valid(active_hook) or graveyard.race=="running":
		tell("Action in progress","Finish the Hookshot movement or the gravekeeper's race before saving.")
		return false
	if not time_quest.sequence.is_empty():
		tell("Scene in progress","Finish this scene before saving your journey.")
		return false
	var payload={"version":1,"state":state,"position":[player.position.x,player.position.y,player.position.z],"area":area,"collected":[]}
	for i in range(rupees.size()):
		if rupees[i].taken: payload.collected.append(i)
	var temporary=save_path+".tmp"
	var f=FileAccess.open(temporary,FileAccess.WRITE)
	if f==null:
		tell("Save failed", "Your journey could not be saved. Keep this window open.")
		return false
	f.store_string(JSON.stringify(payload,"  "))
	f.close()
	var result=DirAccess.rename_absolute(temporary,save_path)
	if result!=OK:
		tell("Save failed", "The previous save is intact. Your new progress could not be saved.")
		return false
	tell("Journey saved", "Your equipment, rupees and current location have been saved.")
	return true

func load_game() -> void:
	if not FileAccess.file_exists(save_path): return
	var payload=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not payload is Dictionary or payload.get("version")!=1 or not payload.get("state") is Dictionary: return
	carried_person=null
	time_quest.sequence=""
	time_quest.sequence_paused=false
	state=state_defaults.duplicate(true)
	state.merge(payload.state,true)
	state.collected=state.collected.map(func(value): return int(value))
	if overworld.places.has(str(payload.get("area",""))): overworld.enter(str(payload.area))
	elif str(payload.get("area","")).begins_with("fire_"): fire_temple.enter(str(payload.area).trim_prefix("fire_"))
	elif str(payload.get("area","")).begins_with("ft_"): forest_temple.enter(str(payload.area).trim_prefix("ft_"))
	elif str(payload.get("area","")).begins_with("jabu_"): jabu.enter(str(payload.area).trim_prefix("jabu_"))
	elif str(payload.get("area","")).begins_with("dodongo_"): dodongo.enter(str(payload.area).trim_prefix("dodongo_"))
	elif str(payload.get("area","")).begins_with("deku_"): dungeon.enter(str(payload.area).trim_prefix("deku_"))
	elif payload.get("area")=="deku": enter_deku()
	else:
		clear_landscape()
		build_forest()
		set_ambience(false)
		for index in payload.get("collected",[]):
			if int(index)>=0 and int(index)<rupees.size():
				rupees[int(index)].taken=true
				rupees[int(index)].node.hide()
	apply_state()
	var p=payload.get("position",[0,.3,14])
	if p is Array and p.size()==3: player.position=vec(p)
	if area=="dampe_race" and not state.dampe_won: player.position=Vector3(0,.1,10)
	player.update_camera(1.0)
	start_game()
	tell("Journey resumed", "Your saved equipment and location have been restored.")

func apply_state() -> void:
	player.set_age(state.adult)
	fire_quest.apply_tunic()
	player.equip(state.master_sword if state.adult else state.sword,state.hylian_shield if state.adult else state.shield)
	player.arm_band.visible=state.bracelet and not state.adult
	if is_instance_valid(controls_label):
		controls_label.text="WASD Move    ← → Camera    E Use    Q Focus    R Bow / Hookshot    X Tool    F Sword    Shift Guard    Space Roll    C Bomb    1 Ocarina    B Milk    M Sound    F5 Save" if state.adult else "WASD Move    ← → Camera    E Use    Q Focus    R Slingshot    T Boomerang    C Bomb    F Sword    Space Roll / Dive    Shift Guard    1 Ocarina    V Bottle    B Milk    M Sound    F5 Save"
	if area=="forest":
		gate.collision_layer=0 if state.mido or state.adult else 1
		if state.mido and npc_nodes.has("mido"): npc_nodes.mido.position.x=1.8
		if state.sword: chest_nodes.sword.get_node("Lid").rotation.x=-1.15
	if chest_nodes.has("slingshot") and state.slingshot: chest_nodes.slingshot.get_node("Lid").rotation.x=-1.15

func setup_sound() -> void:
	sound=AudioStreamPlayer.new()
	sound.volume_db=-9
	add_child(sound)
	music=AudioStreamPlayer.new()
	music.volume_db=-5
	add_child(music)

func update_music() -> void:
	var theme="forest"
	if area.begins_with("ft_"): theme="boss" if area=="ft_boss" and not state.phantom_ganon else "hollow"
	elif area.begins_with("jabu_"): theme="boss" if area=="jabu_barinade" and not state.barinade else "hollow"
	elif area.begins_with("dodongo_"): theme="boss" if area=="dodongo_king" and not state.king_dodongo else "hollow"
	elif area in ["domain","fountain","temple"]: theme="hollow"
	elif area in ["river","lake"]: theme="field"
	elif area=="goron": theme="hollow"
	elif area in ["kakariko","trail"]: theme="field"
	elif area in ["graveyard","dampe_race","royal_tomb","heart_grave","shield_grave"] or (area=="market" and state.adult): theme="hollow"
	elif area.begins_with("deku_"): theme="boss" if area=="deku_gohma" and not state.gohma else "hollow"
	elif area=="field": theme="field"
	elif area=="ranch": theme="ranch"
	elif area in ["market","castle"]: theme="town"
	if theme==music_theme: return
	music_theme=theme
	var track:AudioStreamWAV=load("res://assets/music_"+theme+".wav").duplicate()
	track.loop_mode=AudioStreamWAV.LOOP_FORWARD
	track.loop_begin=0
	track.loop_end=int(track.get_length()*track.mix_rate)
	music.stream=track
	music.play()

func chime(frequency: float, _duration: float) -> void:
	if not is_instance_valid(sound): return
	var effect="treasure" if frequency>=1000 else ("rupee" if frequency>=850 else ("talk" if frequency>=500 else "sword"))
	sound.stream=load("res://assets/"+effect+".wav")
	sound.play()

func _notification(what:int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: quit_cleanly()

func quit_cleanly(code:int=0) -> void:
	if quitting: return
	quitting=true
	preload("res://scripts/natural_art.gd").release_resources()
	preload("res://scripts/time_temple_art.gd").surfaces.clear()
	preload("res://scripts/forest_temple_art.gd").materials.clear()
	preload("res://scripts/fire_art.gd").materials.clear()
	player.enabled=false
	for stream in [sound,music]:
		stream.stop()
		stream.stream=null
	# Allow the audio mixer to release its last WAV playback before the tree exits.
	await get_tree().create_timer(.12).timeout
	get_tree().quit(code)

func _exit_tree() -> void:
	if is_instance_valid(sound):
		sound.stop()
		sound.stream=null
	if is_instance_valid(music):
		music.stop()
		music.stream=null

func set_ambience(inside:bool) -> void:
	var env=world_environment.environment
	env.ssao_enabled=false
	env.ssr_enabled=false
	var sky=env.sky.sky_material
	sky.sky_top_color=Color("5f897d")
	sky.sky_horizon_color=Color("c5cc9f")
	sky.ground_horizon_color=Color("c5cc9f")
	env.ambient_light_color=Color("aebdaa") if inside else Color("c5d5bd")
	env.ambient_light_energy=.30 if inside else .38
	env.fog_light_color=Color("3d5145") if inside else Color("869d79")
	env.fog_density=.012 if inside else .007
	sunlight.light_energy=.24 if inside else .72

func spawn_creature(kind:String, at:Vector3, id:String) -> CharacterBody3D:
	var enemy=CharacterBody3D.new()
	enemy.set_script(JabuEnemyScript if kind in ["stinger","biri","shabom","tentacle","big_octo","barinade"] else ReptileScript if kind in ["king_dodongo","dodongo","lizalfos"] else CreatureScript)
	enemy.world=self
	enemy.kind=kind
	enemy.enemy_id=id
	enemy.position=at
	landscape.add_child(enemy)
	creatures.append(enemy)
	return enemy

func spawn_projectile(creator:CollisionObject3D, at:Vector3, velocity:Vector3, kind:String="seed") -> Node3D:
	var projectile=Node3D.new()
	projectile.set_script(ProjectileScript)
	projectile.world=self
	projectile.creator=creator
	projectile.kind=kind
	projectile.velocity=velocity
	landscape.add_child(projectile)
	projectile.global_position=at
	return projectile

func aim_point(target:Node3D) -> Vector3:
	return target.aim_point() if target.has_method("aim_point") else target.global_position

func focus_target() -> void:
	if is_instance_valid(player.lock_target):
		player.lock_target=null
		return
	var targets:Array=[]
	if state.adult and state.hookshot: targets.append_array(graveyard.targets)
	for target in forest_temple.targets.values():
		if is_instance_valid(target) and target.active and not target.spent: targets.append(target)
	for enemy in creatures:
		if is_instance_valid(enemy) and enemy.mode!="dead" and not enemy.surrendered:
			if enemy.has_method("can_focus") and not enemy.can_focus(): continue
			targets.append(enemy)
	if area.begins_with("jabu_"):
		for target in jabu.targets.values():
			if is_instance_valid(target) and not target.spent: targets.append(target)
	if area.begins_with("deku_"): targets.append_array(dungeon.eye_nodes.values())
	if area.begins_with("dodongo_"): targets.append_array(dodongo.eye_nodes.values())
	var best=1000.0
	for target in targets:
		if not is_instance_valid(target): continue
		var offset:Vector3=aim_point(target)-(player.position+Vector3.UP)
		var distance=offset.length()
		if distance>18: continue
		var angle=(-player.visual.basis.z).dot(offset.normalized())
		var score=distance+(1-angle)*10
		if score<best:
			best=score
			player.lock_target=target
	if not is_instance_valid(player.lock_target): player.yaw=player.visual.rotation.y

func shoot_seed() -> void:
	if state.adult:
		if state.adult_tool=="bow": fire_arrow()
		else: fire_hookshot()
		return
	if is_instance_valid(held_bomb) or is_instance_valid(carried_person) or player.climbing or player.swimming: return
	if not state.slingshot:
		tell("Navi", "Find the Fairy Slingshot in the eastern chamber.")
		return
	if shot_cooldown>0: return
	if state.seeds<=0:
		tell("Navi", "Your seed bag is empty. Look for a seed pot.")
		return
	var start=player.global_position+Vector3.UP*.95-player.visual.basis.z*.35
	var direction=-player.visual.basis.z
	if is_instance_valid(player.lock_target): direction=(aim_point(player.lock_target)-start).normalized()
	spawn_projectile(player,start,direction*20)
	state.seeds-=1
	stats.shots+=1
	shot_cooldown=.5
	chime(180,.09)

func fire_hookshot() -> void:
	if not state.hookshot:
		tell("Adult equipment","Seek the gravekeeper's legacy in Kakariko's graveyard. Your childhood slingshot cannot be used as an adult.")
		return
	if is_instance_valid(active_hook):
		active_hook.cancel()
		return
	if is_instance_valid(held_bomb) or is_instance_valid(carried_person) or player.climbing or player.swimming or player.rolling>0: return
	var start=player.global_position+Vector3.UP*1.20-player.visual.basis.z*.40
	var direction=-player.visual.basis.z
	if is_instance_valid(player.lock_target): direction=(aim_point(player.lock_target)-start).normalized()
	var hook=Node3D.new()
	hook.set_script(preload("res://scripts/hookshot.gd"))
	hook.world=self
	hook.position=start
	hook.direction=direction
	hook.origin=start
	active_hook=hook
	landscape.add_child(hook)
	chime(220,.12)

func swing_sword() -> void:
	if is_instance_valid(active_hook): return
	if attack_cooldown>0 or player.climbing or player.swimming or is_instance_valid(carried_person) or is_instance_valid(held_bomb): return
	message_panel.hide()
	attack_cooldown=.48
	player.attacking=.4
	torch_time=0
	chime(180,.09)
	for enemy in creatures:
		if not is_instance_valid(enemy) or enemy.mode=="dead": continue
		var offset:Vector3=enemy.global_position-player.global_position
		if offset.length()>(3.0 if enemy.kind in ["gohma","king_dodongo","big_octo","barinade"] else 1.9): continue
		if (-player.visual.basis.z).dot(offset.normalized())<.15: continue
		var query=PhysicsRayQueryParameters3D.create(player.position+Vector3.UP*.8,enemy.aim_point(),1)
		query.exclude=[player.get_rid()]
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): enemy.sword_hit()

func can_block(source:Vector3) -> bool:
	if not (state.hylian_shield if state.adult else state.shield) or is_instance_valid(active_hook) or not Input.is_action_pressed("shield") or player.rolling>0 or is_instance_valid(held_bomb) or is_instance_valid(carried_person): return false
	var offset=source-player.global_position
	offset.y=0
	return (-player.visual.basis.z).dot(offset.normalized())>.5

func damage_player(amount:int, source:Vector3, blockable:bool=true) -> void:
	if state.health<=0 or player.invulnerable>0 or player.rolling>.28: return
	var away=player.position-source
	away.y=0
	if blockable and can_block(source):
		stats.blocks+=1
		player.knockback=away.normalized()*3
		player.invulnerable=.35
		chime(900,.12)
		return
	hurt_flash.modulate.a=1
	if is_instance_valid(active_hook): active_hook.cancel()
	state.health=maxi(0,int(state.health)-amount)
	stats.damage_taken+=amount
	player.knockback=away.normalized()*5
	player.invulnerable=1.1
	chime(180,.1)
	if state.health<=0:
		stats.deaths+=1
		player.enabled=false
		player.visual.rotation.z=-1.2
		tell("Journey interrupted", "Press E to retry from the entrance. Your equipment and solved passages are kept.")

func retry_checkpoint() -> void:
	var point=checkpoint.duplicate()
	state.health=state.max_health
	if state.bow: state.arrows=maxi(int(state.arrows),10)
	if state.slingshot: state.seeds=maxi(int(state.seeds),15)
	if state.bomb_bag: state.bomb_count=maxi(int(state.bomb_count),5)
	player.enabled=true
	player.visual.rotation.z=0
	player.invulnerable=2
	if str(point.area).begins_with("fire_"): fire_temple.enter(str(point.area).trim_prefix("fire_"))
	elif str(point.area).begins_with("ft_"): forest_temple.enter(str(point.area).trim_prefix("ft_"))
	elif str(point.area).begins_with("jabu_"): jabu.enter(str(point.area).trim_prefix("jabu_"))
	elif str(point.area).begins_with("dodongo_"): dodongo.enter(str(point.area).trim_prefix("dodongo_"))
	elif str(point.area).begins_with("deku_"): dungeon.enter(str(point.area).trim_prefix("deku_"))
	elif overworld.places.has(str(point.area)): overworld.enter(str(point.area))
	else: return_forest()
	player.position=point.position
	player.update_camera(1.0)
	tell("Try again", "Watch the warning, choose when to guard or roll, then strike an opening.")

func fall_recover() -> void:
	damage_player(1,player.position+Vector3.UP)
	if state.health>0:
		var remaining=state.health
		retry_checkpoint()
		state.health=remaining

func creature_defeated(enemy:Node3D) -> void:
	if player.lock_target==enemy: player.lock_target=null
	if enemy.kind=="king_dodongo":
		state.king_dodongo=true
		state.health=state.max_health
		dodongo.rewards()
	elif enemy.kind=="gohma":
		state.gohma=true
		state.health=state.max_health
		dungeon.rewards()
	else:
		if area.begins_with("jabu_"): jabu.enemy_defeated(enemy)
		if area.begins_with("dodongo_"): dodongo.enemy_defeated(enemy)
		add_rupee(enemy.position,"drop_"+str(enemy.get_instance_id()),2,false)
		state.seeds=mini(30,int(state.seeds)+5) if state.slingshot else state.seeds
		state.health=mini(int(state.max_health),int(state.health)+1)
		chime(1046,.5)

func learn_song(id:String) -> void:
	if id not in state.songs: state.songs.append(id)

func open_instrument() -> void:
	if player.swimming or is_instance_valid(carried_person):
		tell("Navi", "Find dry ground and free your hands before playing.")
		return
	if is_instance_valid(held_bomb):
		tell("Navi", "Put down or throw the lit bomb before playing your ocarina.")
		return
	instrument_open=true
	player.enabled=false
	played_notes=[]
	instrument_prompt()

func instrument_prompt() -> void:
	var known=[]
	for id in state.songs:
		if song_patterns.has(id): known.append(song_patterns[id].name+"  "+song_patterns[id].hint)
	message_label.text=("Ocarina of Time" if state.ocarina_of_time else "Fairy Ocarina")+" · 1 / Esc to put away\nJ  A     K  ↓     L  →     U  ←     I  ↑\n"+"   ".join(played_notes)+"\n"+"\n".join(known)
	message_time=30
	message_panel.show()

func process_instrument() -> void:
	prompt_label.text="Play a melody you have learned. J K L U I are the five notes."
	if Input.is_action_just_pressed("ocarina") or Input.is_action_just_pressed("pause"):
		instrument_open=false
		player.enabled=true
		message_panel.hide()
		return
	for note in ["a","down","right","left","up"]:
		if not Input.is_action_just_pressed("note_"+note): continue
		played_notes.append(note)
		sound.stream=load("res://assets/note_"+note+".wav")
		sound.play()
		instrument_prompt()
		var matched=""
		var possible=false
		for id in state.songs:
			if not song_patterns.has(id): continue
			var notes:Array=song_patterns[id].notes
			if played_notes.size()<=notes.size() and notes.slice(0,played_notes.size())==played_notes:
				possible=true
				if played_notes.size()==notes.size(): matched=id
		if not matched.is_empty():
			played_notes=[]
			instrument_open=false
			player.enabled=true
			play_song(matched)
		elif not possible:
			played_notes=[]
			message_label.text+="\nThe melody fades. Start again with a song you know."

func play_song(id:String) -> void:
	stats.songs_played+=1
	if fire_quest.on_song(id): return
	if forest_temple.on_song(id): return
	if woodland.on_song(id): return
	if graveyard.on_song(id): return
	if time_quest.on_song(id): return
	if zora.on_song(id): return
	if mountain.on_song(id): return
	match id:
		"epona":
			if area=="ranch":
				state.epona_friend=true
				tell("Epona", "The filly lifts her head. She knows Malon's melody, and walks toward you.")
			else: tell(song_patterns[id].name, "The tune carries across the grass, but Epona is still at the ranch.")
		"saria": tell("Saria", "I can hear you, Link. The forest is quiet again. Listen to the people you meet; sometimes kindness opens a path a sword cannot.")
		"lullaby": tell(song_patterns[id].name, "The royal melody lingers. Remember it when you stand before a crest of the royal family.")
		"sun":
			state.time_of_day=.30 if overworld.is_night() else .81
			tell(song_patterns[id].name, "The sky answers the ancient melody.")
		_: tell(song_patterns[id].name, "The melody echoes through the air.")

func drink_milk() -> void:
	if state.milk<=0:
		tell("Bottle", "You have no milk to drink.")
		return
	if state.health==state.max_health:
		tell("Lon Lon Milk", "Your hearts are full. Keep the milk for the road ahead.")
		return
	state.milk-=1
	state.health=mini(int(state.max_health),int(state.health)+10)
	tell("Lon Lon Milk", "The milk restores your hearts. "+str(state.milk)+" drink remains.")

func add_rupee(at:Vector3, id:String, value:int=5, persistent:bool=true) -> void:
	var taken=persistent and id in state.world_collected
	var node=Art.rupee(landscape,at+Vector3.UP*.65)
	node.visible=not taken
	rupees.append({"id":id,"position":at,"node":node,"taken":taken,"value":value,"scope":"world" if persistent else "drop"})

func add_bomb_flower(at:Vector3, id:String) -> void:
	var root=Node3D.new()
	root.set_meta("animated",true)
	root.position=at
	landscape.add_child(root)
	for i in range(5):
		var leaf=Art.ellipsoid(root,Vector3(sin(i)*.3,.1,cos(i)*.3),Vector3(.40,.08,.14),Color("476c42"))
		leaf.rotation.y=-i
	Art.ellipsoid(root,Vector3(0,.35,0),Vector3.ONE*.28,Color("354055"))
	Art.beam(root,Vector3(0,.6,0),Vector3(.1,.78,0),.035,Color("a38d50"))
	bomb_flowers.append({"id":id,"position":at,"node":root,"cooldown":0.0})
	interactions.append({"id":"flower:"+id,"position":[at.x,at.y,at.z],"label":"Pick a Bomb Flower"})

func pick_bomb_flower(id:String) -> void:
	if not state.bracelet:
		tell("Navi", "This flower is too heavy. The Gorons may know how to lift it.")
		return
	for flower in bomb_flowers:
		if flower.id!=id: continue
		if flower.cooldown>0:
			tell("Bomb Flower", "A new bud is growing. Give it a moment.")
			return
		flower.cooldown=7
		held_bomb=spawn_bomb(player.position+Vector3.UP*1.6,true)
		tell("Bomb Flower", "The fuse is lit! C throws it; E puts it down. Step away before it bursts.")

func use_bomb() -> void:
	if player.swimming or is_instance_valid(carried_person): return
	if is_instance_valid(held_bomb):
		message_panel.hide()
		held_bomb.throw_forward()
		return
	if not state.bomb_bag:
		tell("Navi", "You need a Bomb Bag to carry bombs. With the Goron's Bracelet, you can pick Bomb Flowers using E.")
		return
	if state.bomb_count<=0:
		tell("Bomb Bag", "Your bag is empty. Look for a supply jar or a Bomb Flower.")
		return
	state.bomb_count-=1
	held_bomb=spawn_bomb(player.position+Vector3.UP*1.6,true)

func spawn_bomb(at:Vector3, carry:bool=false, fuse:float=3.8) -> CharacterBody3D:
	var bomb=CharacterBody3D.new()
	bomb.set_script(BombScript)
	bomb.world=self
	bomb.held=carry
	bomb.fuse=fuse
	bomb.position=at
	landscape.add_child(bomb)
	bombs.append(bomb)
	return bomb

func blast(at:Vector3) -> void:
	stats.explosions+=1
	blast_visual(at,2.8)
	for target in blast_targets:
		if target.get("spent",false) or not is_instance_valid(target.node): continue
		if at.distance_to(target.position)>2.8+float(target.get("radius",.5)): continue
		var ray=PhysicsRayQueryParameters3D.create(at,target.position,1)
		ray.exclude=[player.get_rid()]
		var hit=get_world_3d().direct_space_state.intersect_ray(ray)
		if hit and not target.node.is_ancestor_of(hit.collider) and hit.collider!=target.node: continue
		target.spent=true
		if target.id=="river_rock": zora.open_river(target.node)
		elif target.id=="quarry_rock": mountain.open_quarry(target.node)
		elif str(target.id).begins_with("fire:"): fire_temple.blast_wall(target.id,target.node)
		else: dodongo.blast_hit(target.id,target.node)
	for enemy in creatures:
		if not is_instance_valid(enemy) or enemy.mode=="dead" or at.distance_to(enemy.aim_point())>3.2: continue
		var ray=PhysicsRayQueryParameters3D.create(at,enemy.aim_point(),1)
		ray.exclude=[player.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		if enemy.has_method("blast_hit"): enemy.blast_hit()
		else: enemy.sword_hit()
	if at.distance_to(player.position+Vector3.UP*.65)<2.8:
		var ray=PhysicsRayQueryParameters3D.create(at,player.position+Vector3.UP*.65,1)
		ray.exclude=[player.get_rid()]
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): damage_player(2,at,false)

func blast_visual(at:Vector3, radius:float) -> void:
	var effect=Node3D.new()
	effect.position=at
	landscape.add_child(effect)
	for i in range(7):
		var p=Vector3(sin(i)*.4,.15+cos(i*1.7)*.3,cos(i)*.4)
		var puff=Art.ellipsoid(effect,p,Vector3.ONE*.25,Color("dc8742") if i%2 else Color("f1bd67"))
		var tween=create_tween()
		tween.tween_property(puff,"position",p*radius+Vector3.UP*.45,.32)
		tween.parallel().tween_property(puff,"scale",Vector3.ONE*.45,.32)
		tween.tween_property(puff,"scale",Vector3.ZERO,.25)
	var light=OmniLight3D.new()
	light.light_color=Color("ffa054")
	light.light_energy=2.5
	light.omni_range=radius*2.5
	effect.add_child(light)
	create_tween().tween_property(light,"light_energy",0.0,.45)
	get_tree().create_timer(.65).timeout.connect(effect.queue_free)
	chime(160,.3)

func hide_breakable(node:Node3D) -> void:
	node.hide()
	for child in node.find_children("*","CollisionObject3D",true,false): child.set_deferred("collision_layer",0)

func water_at(at:Vector3) -> Dictionary:
	for volume in water_zones:
		if volume.bounds.has_point(Vector2(at.x,at.z)) and at.y<float(volume.height)+.4 and at.y>float(volume.bottom)-1:
			return volume
	return {}

func add_water(bounds:Rect2, height:float, bottom:float, current:Vector3=Vector3.ZERO) -> void:
	water_zones.append({"bounds":bounds,"height":height,"bottom":bottom,"current":current})
	var surface=MeshInstance3D.new()
	var mesh=PlaneMesh.new()
	mesh.size=bounds.size
	mesh.subdivide_width=64
	mesh.subdivide_depth=64
	surface.mesh=mesh
	surface.position=Vector3(bounds.get_center().x,height,bounds.get_center().y)
	surface.set_meta("animated",true)
	var material=ShaderMaterial.new()
	material.shader=preload("res://shaders/water_realistic.gdshader") if area=="domain" else preload("res://shaders/water.gdshader")
	surface.material_override=material
	landscape.add_child(surface)

func throw_boomerang() -> void:
	if state.adult:
		tell("Equipment","The boomerang is a childhood weapon. Your new journey calls for different tools.")
		return
	if not state.boomerang:
		tell("Navi","The returning weapon is hidden inside Lord Jabu-Jabu.")
		return
	if is_instance_valid(active_boomerang) or is_instance_valid(held_bomb) or is_instance_valid(carried_person) or player.climbing or player.swimming: return
	var boomerang=Node3D.new()
	boomerang.set_script(BoomerangScript)
	boomerang.world=self
	boomerang.target=player.lock_target
	boomerang.position=player.position+Vector3.UP*1.0-player.visual.basis.z*.45
	landscape.add_child(boomerang)
	active_boomerang=boomerang
	chime(180,.1)

func fire_arrow() -> void:
	if not state.adult or not state.bow or shot_cooldown>0: return
	if is_instance_valid(active_hook) or is_instance_valid(held_bomb) or is_instance_valid(carried_person) or player.climbing or player.swimming or player.rolling>0: return
	if state.arrows<=0:
		tell("Empty quiver","Look for supply jars to replenish your arrows.")
		return
	var start=player.position+Vector3.UP*1.30-player.visual.basis.z*.45
	var direction=-player.visual.basis.z
	if is_instance_valid(player.lock_target):
		var at=aim_point(player.lock_target)
		if player.lock_target.has_method("arrow_aim_point"): at=player.lock_target.arrow_aim_point(start,25.0)
		var flight=start.distance_to(at)/25
		at.y+=1.5*flight*flight
		direction=(at-start).normalized()
	var arrow=Node3D.new()
	arrow.set_script(preload("res://scripts/arrow.gd"))
	arrow.world=self;arrow.position=start;arrow.velocity=direction*25
	landscape.add_child(arrow)
	state.arrows-=1
	stats.shots+=1
	shot_cooldown=.55
	chime(180,.12)

func _physics_process(delta:float) -> void:
	if is_instance_valid(player) and player.enabled: fire_quest.physics_tick(delta)
	if is_instance_valid(player) and player.enabled and area.begins_with("fire_"): fire_temple.physics_tick(delta)
	if is_instance_valid(player) and player.enabled and area.begins_with("ft_"): forest_temple.physics_tick(delta)
