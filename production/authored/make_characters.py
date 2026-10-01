"""Editable, independently modeled child characters; run with Blender --background --python."""
import bpy
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'game/assets'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, rgb, roughness=.8, metallic=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*rgb,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*rgb,1)
    p.inputs['Roughness'].default_value=roughness; p.inputs['Metallic'].default_value=metallic
    return m

skin=material('Warm skin',(.72,.47,.29)); green=material('Forest tunic',(.15,.32,.055))
hatmat=material('Cap green',(.25,.42,.07)); leather=material('Worn leather',(.20,.095,.035))
cream=material('Linen',(.75,.69,.50)); hair=material('Honey hair',(.60,.35,.055))
eye=material('Eyes',(.035,.08,.105),.35); white=material('Eye white',(.86,.85,.69))
metal=material('Buckle',(.7,.46,.12),.3,.65)

def node(name,loc,parent=None):
    o=bpy.data.objects.new(name,None); bpy.context.collection.objects.link(o); o.location=loc; o.parent=parent;return o

def sphere(name,loc,scale,mat,parent):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8)
    o=bpy.context.object;o.name=name;o.parent=parent;o.location=loc;o.scale=scale;o.data.materials.append(mat)
    for p in o.data.polygons:p.use_smooth=True
    return o

def cone(name,loc,r1,r2,depth,mat,parent,verts=10):
    bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=depth)
    o=bpy.context.object;o.name=name;o.parent=parent;o.location=loc;o.data.materials.append(mat)
    mod=o.modifiers.new('Soft sewn edges','BEVEL');mod.width=.018;mod.segments=2
    o.modifiers.new('Weighted highlights','WEIGHTED_NORMAL')
    return o

root=node('Link',(0,0,0))
cone('Tunic',(0,0,.77),.21,.18,.35,green,root)
cone('Tunic hem',(0,0,.56),.25,.185,.17,green,root)
cone('Belt',(0,0,.655),.205,.205,.045,leather,root)
sphere('Buckle',(0,-.197,.655),(.052,.018,.04),metal,root)
head=node('Head',(0,0,1.06),root)
sphere('Face',(0,-.015,.075),(.175,.15,.205),skin,head)
sphere('Hair',(0,.025,.16),(.184,.14,.145),hair,head)
for side in (-1,1):
    ear=cone('Pointed ear',(.18*side,0,.085),.068,.004,.18,skin,head,5)
    ear.rotation_euler[1]=math.pi/2*side
    sphere('Eye white',(.068*side,-.145,.10),(.04,.012,.055),white,head)
    sphere('Blue eye',(.068*side,-.156,.10),(.022,.01,.036),eye,head)
    fringe=cone('Hair fringe',(.10*side,-.095,.22),.01,.065,.20,hair,head,5)
    fringe.rotation_euler[1]=-.35*side
    arm=node('LeftArm' if side<0 else 'RightArm',(side*.225,0,.88),root)
    sphere('Sleeve',(side*.016,0,-.055),(.105,.10,.13),green,arm)
    sphere('Forearm',(side*.02,-.012,-.20),(.065,.068,.135),skin,arm)
    sphere('Glove',(side*.022,-.025,-.31),(.075,.075,.077),leather,arm)
    leg=node('LeftLeg' if side<0 else 'RightLeg',(side*.10,0,.53),root)
    sphere('Leg',(0,0,-.115),(.079,.08,.18),cream,leg)
    sphere('Boot',(0,-.025,-.365),(.10,.15,.115),leather,leg)
    cone('Boot cuff',(0,0,-.26),.084,.106,.12,leather,leg)
sphere('Nose',(0,-.169,.06),(.032,.043,.036),skin,head)
sphere('Cap base',(0,.034,.245),(.188,.16,.075),hatmat,head)
cap=cone('Long pointed cap',(0,.19,.215),.15,.005,.42,hatmat,head)
cap.rotation_euler[0]=math.radians(-65)
# Small leather pouch gives the back a readable asymmetry.
sphere('Belt pouch',(.18,.11,.64),(.09,.085,.10),leather,root)

bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'production/authored/characters.blend'))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(OUT/'link.glb'),export_format='GLB',use_selection=True)
print('Authored character:',OUT/'link.glb')
