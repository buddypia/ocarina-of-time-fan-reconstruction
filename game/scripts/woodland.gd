extends RefCounted
const F=preload("res://scripts/forest_temple_art.gd")
const Art=preload("res://scripts/art.gd")
var world:Node3D
var mido_gate:StaticBody3D

func _init(owner_world:Node3D) -> void:
	world=owner_world
	world.overworld.places.merge({"lost_woods":{"name":"Lost Woods","arrival":"Old paths turn around you. Listen for Saria's melody at each crossing.","people":[],"exits":[]},"meadow":{"name":"Sacred Forest Meadow","arrival":"The overgrown path winds toward the temple. A broken stairway lies beyond the clearing.","people":[],"exits":[]}})

func forest_details() -> void:
	world.interactions.append({"id":"wood:enter","position":[23,0,-18],"label":"Enter the Lost Woods"})
	world.overworld.signpost(Vector3(20,0,-16),"Lost Woods")
	if world.state.adult:
		if not world.state.forest_medallion:
			for at in [Vector3(-7,0,-14),Vector3(7,0,-11),Vector3(10,0,0)]: world.spawn_creature("baba",at,"adult_baba")
		else:
			var sprout=Node3D.new();world.landscape.add_child(sprout);sprout.position=Vector3(4,0,-33)
			Art.cylinder(sprout,Vector3(0,.75,0),.22,.14,1.5,Color("75623e"),64)
			for side in [-1,1]:
				var leaf=Art.ellipsoid(sprout,Vector3(side*.55,1.4,0),Vector3(.7,.11,.3),Color("6b824f"));leaf.rotation.z=side*.3
			world.interactions.append({"id":"wood:sprout","position":[4,0,-31.7],"label":"Speak to the Deku Tree sprout"})

func build(place:String) -> void:
	mido_gate=null
	if place=="lost_woods": build_woods()
	else: build_meadow()

func use_at(id:String,at:Vector3,label:String) -> void:
	world.interactions.append({"id":"wood:"+id,"position":[at.x,at.y,at.z],"label":label})

func build_woods() -> void:
	F.chamber(world,Vector2(30,30),true)
	world.player.position=Vector3(0,.1,9)
	var directions={"left":Vector3(-12,0,0),"right":Vector3(12,0,0),"forward":Vector3(0,0,-12),"return":Vector3(0,0,12)}
	for key in directions:
		var at:Vector3=directions[key]
		F.portal(world.landscape,at,atan2(-at.x,-at.z))
		use_at(key,at*.87,"Follow the "+key+" path")
	use_at("listen",Vector3(0,0,5),"Listen for Saria")
	world.overworld.signpost(Vector3(3,0,6),"Listen at the crossing")
	if int(world.state.woods_stage)==2 and world.state.adult and not world.state.woods_mido:
		world.overworld.make_person({"id":"woods_mido","name":"Mido","style":"saria","at":[7,0,0],"lines":["I promised Saria I would guard this path. Only someone who knows her song may pass."]},false)
		mido_gate=Art.collision_box(world.landscape,Vector3(9,1.5,0),Vector3(.5,3,5))
		use_at("mido",Vector3(6,0,1),"Talk to Mido")

func build_meadow() -> void:
	F.chamber(world,Vector2(30,58),true)
	world.player.position=Vector3(0,.1,24)
	use_at("leave",Vector3(0,0,25),"Return to the Lost Woods")
	# Alternating openings make the meadow a traversable hedge maze.
	for i in range(3):
		var z=15-i*9
		var gap=7 if i%2==0 else -7
		for side in [-1,1]:
			var left=-14.0 if side<0 else gap+2.4
			var right=gap-2.4 if side<0 else 14.0
			var hedge=F.block(world.landscape,Vector3((left+right)*.5,1.25,z),Vector3(right-left,2.5,1.4),true)
			hedge.material_override=Art.material(Color("46583c"),.98)
		if world.state.adult and not world.state.forest_medallion: world.forest_temple.spawn("moblin","meadow_guard_"+str(i),Vector3(gap,0,z-2))
	F.block(world.landscape,Vector3(0,2,-24),Vector3(10,4,8),true)
	F.portal(world.landscape,Vector3(0,4,-26))
	use_at("temple",Vector3(0,4,-23.6),"Enter the Forest Temple")
	# This anchor uses the same physical Hookshot contract as the graveyard target.
	F.tree(world.landscape,Vector3(4,4,-23),.42,806)
	world.graveyard.anchor(Vector3(0,7.0,-20.6),Vector3(0,4.35,-21.6))
	world.overworld.make_person({"id":"forest_sheik","name":"Sheik","style":"impa","at":[-4,0,-14],"lines":world.forest_temple.data.sheik},false)
	use_at("sheik",Vector3(-4,0,-12.7),"Talk to Sheik")
	if not world.state.adult:
		use_at("saria",Vector3(-4,0,-10),"Listen to Saria's song")

func interact(id:String) -> bool:
	if not id.begins_with("wood:"): return false
	var action=id.trim_prefix("wood:")
	match action:
		"enter": world.state.woods_stage=0;world.overworld.enter("lost_woods")
		"return": world.state.woods_stage=0;world.return_forest();world.player.position=Vector3(21,.1,-18);world.player.update_camera(1)
		"leave": world.state.woods_stage=0;world.overworld.enter("lost_woods")
		"listen": world.tell("Navi",world.forest_temple.data.woods.hints[int(world.state.woods_stage)])
		"mido": world.tell("Mido","I promised Saria I would guard this path. That melody you shared with her... do you still remember it?")
		"left","right","forward":
			var step=int(world.state.woods_stage)
			if step==2 and world.state.adult and not world.state.woods_mido:
				world.tell("Mido","I will only open the path for someone who knows Saria's song.");return true
			if action!=world.forest_temple.data.woods.sequence[step]:
				world.state.woods_stage=0;world.return_forest();world.player.position=Vector3(21,.1,-18);world.player.update_camera(1)
				world.tell("Lost Woods","The path curls back to Kokiri Forest. Listen at the crossing before choosing another way.")
			else:
				world.state.woods_stage+=1
				if world.state.woods_stage>=7: world.state.woods_stage=0;world.overworld.enter("meadow")
				else: world.overworld.enter("lost_woods");world.tell("Saria's melody",world.forest_temple.data.woods.hints[int(world.state.woods_stage)])
		"sheik":
			if not world.state.adult: world.tell("The clearing","Saria's melody lingers beneath the trees.");return true
			world.tell("Sheik",world.forest_temple.data.sheik[1])
			if not "minuet" in world.state.songs: world.state.songs.append("minuet")
		"saria":
			if not "saria" in world.state.songs: world.state.songs.append("saria")
			world.tell("Saria","When you want to speak to me, play this tune: K L U K L U. The forest will carry it.")
		"temple":
			if world.state.adult and world.state.hookshot: world.forest_temple.enter("trees","meadow")
			else: world.tell("Broken stairway","The entrance is too high. A tool that grips the old branch could reach it.")
		"sprout":
			var lines=world.forest_temple.data.sprout
			var index=mini(int(world.state.forest_sprout_stage),lines.size()-1)
			world.tell("Deku Tree sprout",lines[index])
			world.state.forest_sprout_stage=mini(index+1,lines.size())
	return true

func on_song(id:String) -> bool:
	if id=="saria" and world.area=="lost_woods" and int(world.state.woods_stage)==2:
		world.state.woods_mido=true
		if is_instance_valid(mido_gate): mido_gate.collision_layer=0
		world.tell("Mido","That song... Saria taught it to you. Go on. Tell her I kept my promise.")
		return true
	if id=="minuet" and "minuet" in world.state.songs:
		world.overworld.enter("meadow")
		world.player.position=Vector3(0,.1,-13)
		world.player.update_camera(1)
		world.tell("Minuet of Forest","The melody returns you to the Sacred Forest Meadow.")
		return true
	return false

func objective() -> String:
	if world.area=="lost_woods": return "LOST WOODS · "+world.forest_temple.data.woods.hints[int(world.state.woods_stage)]
	if world.area=="meadow": return "SACRED FOREST MEADOW · Speak with Sheik; Hookshot the branch above the ruined steps"
	if world.area=="forest" and world.state.adult:
		if not world.state.forest_medallion: return "KOKIRI FOREST · The Lost Woods lie in the northeast; find Saria in the Forest Temple"
		if world.state.forest_sprout_stage<world.forest_temple.data.sprout.size(): return "KOKIRI FOREST · The Deku Tree sprout waits near the old tree"
		return "FOREST RESTORED · Return to Sheik at the Temple of Time"
	return ""
