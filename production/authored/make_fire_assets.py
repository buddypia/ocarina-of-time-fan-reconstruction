"""Editable Goron study and volcanic surface maps; no extracted game assets.
Run: blender --background --python production/authored/make_fire_assets.py
Lava appearance reference: USGS / M. Patrick, 2021-10-04. Reference photograph
is not sampled into these authored maps. The character is a reconstruction study.
"""
import bpy, math
import numpy as np
from mathutils import Vector
from pathlib import Path


ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'production/authored/fire-assets'; OUT.mkdir(exist_ok=True)
ASSETS=ROOT/'game/assets/fire'; ASSETS.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def save_map(name, values):
 if values.ndim==2: values=np.repeat(values[:,:,None],3,axis=2)
 rgba=np.concatenate([values,np.ones((*values.shape[:2],1),np.float32)],axis=2).astype(np.float32)
 im=bpy.data.images.new(name,width=values.shape[1],height=values.shape[0],alpha=True)
 im.colorspace_settings.name='Non-Color'
 im.pixels.foreach_set(rgba.ravel());im.filepath_raw=str(ASSETS/name);im.file_format='PNG';im.save()

# Periodic, warped crust plates with wrinkled surface and narrow molten seams.
n=1024
y,x=np.mgrid[0:n,0:n].astype(np.float32)/n
u=x+.013*np.sin(y*math.tau*5)+.008*np.sin((x+y)*math.tau*11)
v=y+.016*np.sin(x*math.tau*3)+.007*np.sin((x-y)*math.tau*9)
rng=np.random.default_rng(830)
d1=np.ones((n,n),np.float32)*9; d2=d1.copy()
for cx,cy in rng.uniform(0,1,(60,2)):
 dx=(u-cx+.5)%1-.5; dy=(v-cy+.5)%1-.5
 d=np.sqrt(dx*dx+dy*dy)
 d2=np.minimum(d2,np.maximum(d1,d)); d1=np.minimum(d1,d)
gap=d2-d1
seam=np.clip((.004-gap)/.004,0,1)**.65
wrinkle=np.sin((u*49+v*24+np.sin(v*31)*.8)*math.tau)*.5+.5
grain=rng.uniform(0,1,(n,n))
h=(1-np.exp(-gap*100))*.30+wrinkle*.023+grain*.012
base=np.clip(.16+wrinkle*.09+grain*.06+.07*np.sin(u*math.tau*7)*np.cos(v*math.tau*6),0,1)
rgb=np.stack([base*.86,base*.92,base],axis=-1)*(1-seam[:,:,None]*.65)
save_map('crust_diff.png',rgb)
save_map('crust_heat.png',seam)
dx=(np.roll(h,-1,1)-np.roll(h,1,1))*10; dy=(np.roll(h,-1,0)-np.roll(h,1,0))*10
normal=np.stack([-dx,dy,np.ones_like(dx)],axis=-1); normal/=np.linalg.norm(normal,axis=-1)[:,:,None]
save_map('crust_normal.png',normal*.5+.5)
save_map('crust_rough.png',np.clip(.60+grain*.16-seam*.25,0,1))

def mat(name,color,rough=.75,metal=0):
 m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1); p.inputs['Roughness'].default_value=rough; p.inputs['Metallic'].default_value=metal
 return m
skin=mat('Ochre mineral skin',(.46,.27,.10),.84)
rock=mat('Weathered dorsal stone',(.24,.17,.095),.93)
dark=mat('Creases',(.075,.031,.012),.92)
eye=mat('Obsidian eyes',(.016,.011,.008),.25)
ivory=mat('Warm sclera',(.64,.52,.34),.5)
skinparts=[]
def sphere(name,at,size,material,merge=False):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=32,location=at)
 o=bpy.context.object; o.name=name; o.scale=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(material)
 for p in o.data.polygons:p.use_smooth=True
 if merge:skinparts.append(o)
 return o
def tube(name,points,r,material):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=24;c.bevel_depth=r;c.bevel_resolution=5
 s=c.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
 for p,co in zip(s.bezier_points,points):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(material);return o

# A fused skin surface connects abdomen, chest, neck, shoulders, palms and feet.
sphere('Abdomen',(0,0,1.02),(.73,.52,.78),skin,True)
sphere('Chest',(0,.04,1.55),(.68,.43,.49),skin,True)
sphere('Neck',(0,0,1.88),(.36,.32,.26),skin,True)
sphere('Cranium',(0,-.07,2.11),(.43,.35,.40),skin,True)
sphere('Jaw',(0,-.22,1.92),(.38,.28,.23),skin,True)
sphere('Muzzle',(0,-.38,2.0),(.29,.16,.15),skin,True)
sphere('Nose',(0,-.42,2.13),(.15,.14,.09),skin,True)
for sign in [-1,1]:
 sphere('Shoulder',(sign*.64,.005,1.59),(.34,.34,.39),skin,True)
 o=sphere('Upper arm',(sign*.84,.025,1.34),(.28,.29,.40),skin,True);o.rotation_euler.y=sign*.25
 sphere('Forearm',(sign*.98,-.04,.97),(.24,.25,.36),skin,True)
 sphere('Palm',(sign*1.02,-.15,.72),(.26,.20,.24),skin,True)
 for j in range(4):
  sphere('Finger',(sign*(.84+j*.115),-.24,.57),(.065,.09,.17-.02*abs(j-1)),skin,True)
 sphere('Thumb',(sign*.78,-.21,.76),(.09,.105,.16),skin,True)
 sphere('Thigh',(sign*.40,.025,.54),(.32,.35,.41),skin,True)
 sphere('Ankle',(sign*.43,0,.27),(.25,.27,.25),skin,True)
 sphere('Foot',(sign*.43,-.14,.135),(.29,.40,.135),skin,True)
 for j in range(3):sphere('Toe',(sign*(.23+j*.18),-.42,.10),(.10,.13,.09),skin,True)
 sphere('Ear',(sign*.41,-.04,2.12),(.09,.10,.15),skin,True)
 sphere('Cheek',(sign*.26,-.31,2.06),(.18,.15,.16),skin,True)
 brow=sphere('Heavy brow',(sign*.19,-.35,2.29),(.24,.14,.085),skin,True);brow.rotation_euler.y=sign*.15
 sphere('Eye',(sign*.19,-.381,2.215),(.086,.036,.047),ivory)
 sphere('Pupil',(sign*.19,-.413,2.216),(.029,.015,.033),eye)
 sphere('Nostril',(sign*.082,-.524,2.105),(.031,.016,.019),dark)
tube('Mouth',[(-.24,-.445,1.951),(0,-.522,1.93),(.24,-.445,1.951)],.011,dark)
for z,r in [(1.12,.55),(.91,.59)]:
 tube('Belly fold',[(-r*.8,-.38,z),(0,-.516,z-.018),(r*.8,-.38,z)],.009,dark)
# Fuse the skin construction and smooth junctions; retain semantic sculpt objects in Blender history source.
bpy.ops.object.select_all(action='DESELECT')
for o in skinparts:o.select_set(True)
bpy.context.view_layer.objects.active=skinparts[0];bpy.ops.object.join()
body=bpy.context.object;body.name='Continuous skin sculpt'
mod=body.modifiers.new('Fused anatomy','REMESH');mod.mode='VOXEL';mod.voxel_size=.018;mod.use_smooth_shade=True
bpy.ops.object.modifier_apply(modifier=mod.name)
mod=body.modifiers.new('Skin relaxation','SMOOTH');mod.factor=.55;mod.iterations=5;bpy.ops.object.modifier_apply(modifier=mod.name)
# Vertex colors survive GLB export and vary across skin at physical, not UV, scale.
colors=body.data.color_attributes.new(name='Mineral pigmentation',type='FLOAT_COLOR',domain='POINT')
for i,vertex in enumerate(body.data.vertices):
 co=body.matrix_world@vertex.co
 noise=.94+.045*math.sin(co.x*63+math.sin(co.z*39))+.025*math.cos(co.y*137+co.z*81)
 colors.data[i].color=(noise*.46,noise*.27,noise*.10,1)
node=skin.node_tree.nodes.new('ShaderNodeVertexColor');node.layer_name=colors.name
skin.node_tree.links.new(node.outputs['Color'],skin.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
for row in range(4):
 for j in range(5):
  a=(j-2)*.40;z=.95+row*.26; xx=math.sin(a)*.55; yy=.39+math.cos(a)*.18
  o=sphere('Dorsal plate',(xx,yy,z),(.22,.105,.19),rock)
  for vtx in o.data.vertices:
   vtx.co*=1+.06*math.sin(vtx.co.x*38+row)*math.sin(vtx.co.z*43+j)
  o.rotation_euler.y=-a*.4
for j in range(5):
 o=sphere('Crown ridge',((j-2)*.12,.02,2.43-abs(j-2)*.04),(.095,.13,.13),rock)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'goron-study.blend'))
bpy.ops.export_scene.gltf(filepath=str(ASSETS/'goron.glb'),export_format='GLB',export_yup=True,export_animations=False)
print('Authored volcanic textures and editable Goron study exported')
