extends CharacterBody3D

var world:Node3D
var held:=false
var fuse:=3.8
var spent:=false
var shell:MeshInstance3D
var spark:MeshInstance3D

func _ready() -> void:
	collision_layer=16
	collision_mask=3
	add_collision_exception_with(world.player)
	var col=CollisionShape3D.new()
	var shape=SphereShape3D.new()
	shape.radius=.2
	col.shape=shape
	add_child(col)
	shell=ForestArt.ellipsoid(self,Vector3.ZERO,Vector3.ONE*.23,Color("243958"))
	ForestArt.beam(self,Vector3(0,.19,0),Vector3(.08,.35,0),.025,Color("a58a53"))
	spark=ForestArt.ellipsoid(self,Vector3(.08,.36,0),Vector3.ONE*.055,Color("f9c368"))

func _physics_process(delta:float) -> void:
	if not world.player.enabled or spent: return
	fuse-=delta
	if fuse<=0:
		detonate()
		return
	shell.material_override=ForestArt.material(Color("bc6740") if fuse<1.2 and int(fuse*14)%2==0 else Color("243958"))
	spark.scale=Vector3.ONE*.055*(1+sin(fuse*40)*.3)
	if held:
		global_position=world.player.carried_item_position()
		return
	for enemy in world.creatures:
		if is_instance_valid(enemy) and enemy.has_method("try_swallow") and enemy.try_swallow(self):
			consume()
			return
	velocity.y-=18*delta
	var hit=move_and_collide(velocity*delta)
	if hit:
		velocity=velocity.bounce(hit.get_normal())*.35
		if hit.get_normal().y>.6:
			velocity.x=move_toward(velocity.x,0,delta*20)
			velocity.z=move_toward(velocity.z,0,delta*20)
	if global_position.y < -20: consume()

func throw_forward(drop:bool=false) -> void:
	held=false
	world.held_bomb=null
	var forward=-world.player.visual.basis.z
	global_position=world.player.global_position+Vector3.UP*(.30 if drop else 1.25)+forward*(.75 if drop else .60)
	velocity=forward*(.2 if drop else 7.0)+Vector3.UP*(0 if drop else 3.8)
	world.stats.bombs_thrown+=1

func consume() -> void:
	spent=true
	if world.held_bomb==self: world.held_bomb=null
	world.bombs.erase(self)
	queue_free()

func detonate() -> void:
	if spent: return
	var at=global_position
	consume()
	world.blast(at)
