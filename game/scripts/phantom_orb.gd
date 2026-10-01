extends Node3D
var world:Node3D
var boss:CharacterBody3D
var destination:=Vector3.ZERO
var returning:=false
var rallies:=0
var speed:=8.5
var age:=0.0

func _ready() -> void:
	var ball=preload("res://scripts/grave_art.gd").sphere(self,Vector3.ZERO,Vector3.ONE*.22,Color("ffdc83"))
	var mat=ball.material_override.duplicate()
	mat.emission_enabled=true
	mat.emission=Color("ffe7a6")
	ball.material_override=mat
	var light=OmniLight3D.new()
	light.light_color=Color("ffc777")
	light.light_energy=1
	light.omni_range=5
	add_child(light)
	destination=world.player.position+Vector3.UP*1.05

func _physics_process(delta:float) -> void:
	if not is_instance_valid(boss) or boss.mode=="dead":
		queue_free()
		return
	if not world.player.enabled: return
	age+=delta
	if age>12:
		boss.orb_finished(false)
		queue_free()
		return
	if not returning and world.player.attacking>0 and position.distance_to(world.player.position+Vector3.UP*1.05)<2.0:
		var offset=position-world.player.position
		if (-world.player.visual.basis.z).dot(offset.normalized())>.15:
			returning=true
			rallies+=1
			speed=minf(23,speed+2.5)
			destination=boss.aim_point()
			world.stats["phantom_returns"]=world.stats.get("phantom_returns",0)+1
			world.chime(700,.12)
	position=position.move_toward(destination,delta*speed)
	if position.distance_to(destination)<.25:
		if returning:
			if rallies>=boss.required_rallies:
				boss.orb_finished(true)
				queue_free()
			else:
				returning=false
				destination=world.player.position+Vector3.UP*1.05
		else:
			if position.distance_to(world.player.position+Vector3.UP*1.05)<1.3: world.damage_player(2,position,false)
			boss.orb_finished(false)
			queue_free()
