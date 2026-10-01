extends CharacterBody3D
const Art=preload("res://scripts/art.gd")
const G=preload("res://scripts/grave_art.gd")
const Fire=preload("res://scripts/fire_art.gd")
var world:Node3D
var mode:="rolling"
var kind:="rolling_goron"
var surrendered:=false
var angle:=0.0
var ball:Node3D
var standing:Node3D

func _ready() -> void:
	set_meta("animated",true)
	collision_layer=2;collision_mask=1
	var shape=CollisionShape3D.new();var body=SphereShape3D.new();body.radius=.70;shape.shape=body;shape.position.y=.72;add_child(shape)
	ball=Node3D.new();add_child(ball);ball.position.y=.75
	var mesh=G.sphere(ball,Vector3.ZERO,Vector3.ONE*.72,Color("8d713c"))
	mesh.material_override=Fire.basalt().duplicate();mesh.material_override.albedo_color=Color("b5986b")
	for i in range(16):
		var a=i*TAU/16
		G.sphere(ball,Vector3(sin(a)*.55,cos(a)*.55,0),Vector3(.24,.18,.65),Color("756141"))
	standing=Fire.goron(self,Vector3.ZERO,.72);standing.hide()
	for child in standing.find_children("*","StaticBody3D",true,false): child.collision_layer=0
	if world.state.goron_stopped: stop(false)
	else: position=Vector3(9,0,5)

func _physics_process(delta:float) -> void:
	if not world.player.enabled: return
	if mode=="rolling":
		angle+=delta*.55
		var target=Vector3(cos(angle)*9,0,5+sin(angle)*6)
		velocity=(target-position)/maxf(delta,.001)
		move_and_slide()
		ball.rotation.z-=delta*5.8
		if position.distance_to(world.player.position)<1.1: world.damage_player(1,position,false)
	else:
		standing.rotation.y=lerp_angle(standing.rotation.y,atan2(world.player.position.x-position.x,world.player.position.z-position.z),delta*2)
		for item in world.interactions:
			if item.id=="fire:son": item.position=[position.x,position.y,position.z]

func aim_point() -> Vector3: return global_position+Vector3.UP*.8
func arrow_aim_point(origin:Vector3,speed:float) -> Vector3:
	if mode!="rolling": return aim_point()
	var at=aim_point()
	for step in range(3):
		var arrival=angle+origin.distance_to(at)/speed*.55
		at=Vector3(cos(arrival)*9,.8,5+sin(arrival)*6)
	return at
func can_focus() -> bool: return mode=="rolling"
func sword_hit() -> void: world.tell("Navi","He is frightened. Try stopping his roll from a safe distance.")
func hook_hit() -> void: world.chime(260,.1)
func blast_hit() -> void: stop()
func projectile_hit(projectile:String,_reflected:bool=false) -> void:
	if projectile in ["arrow","fire_arrow"]: stop()

func stop(notify:bool=true) -> void:
	if mode=="stopped": return
	mode="stopped";surrendered=true;world.state.goron_stopped=true;velocity=Vector3.ZERO
	ball.hide();standing.show()
	world.interactions.append({"id":"fire:son","position":[position.x,position.y,position.z],"label":"Speak to Darunia's son"})
	if notify: world.tell("A frightened Goron","The young Goron stops rolling. Lower your weapon and speak with him.")
