"""Authored weathered grave marker, carved lettering and stone surface maps.
Reference: Jason Church / NPS headstone photograph (reference only).
blender --background --python production/authored/make_gravestone.py
"""
import bpy, bmesh, math, random
import numpy as np
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'production/authored/grave-marker'; OUT.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
N=1024; rng=np.random.default_rng(9273); y,x=np.mgrid[0:N,0:N]/N
field=np.zeros((N,N))
for n,weight in [(4,.34),(11,.20),(27,.11),(77,.055)]:
 for i in range(8):
  a=rng.uniform(0,math.tau); phase=rng.uniform(0,math.tau)
  field+=np.sin((x*math.cos(a)+y*math.sin(a))*n*math.tau+phase)*weight/8
grain=rng.normal(0,.023,(N,N)); pores=(rng.random((N,N))>.996)*rng.uniform(.1,.3,(N,N))
streak=(np.sin(x*73)+np.sin(x*141+.6))*.02*(.4+.6*y)
weather=np.clip(.73+field+grain-pores-streak,0,1)
color=np.stack([weather*.96,weather*.96,weather*.89],-1)
def image(name,pixels):
 im=bpy.data.images.new(name,width=N,height=N,alpha=False)
 rgba=np.ones((N,N,4),dtype=np.float32); rgba[:,:,:3]=pixels
 im.pixels.foreach_set(rgba.ravel()); im.filepath_raw=str(OUT/(name+'.png')); im.file_format='PNG'; im.save(); return im
diff=image('weathered-limestone',color)
rough=image('stone-roughness',np.repeat(np.clip(.87+field*.16,0,1)[:,:,None],3,axis=2))
m=bpy.data.materials.new('Aged matte limestone');m.use_nodes=True
nodes=m.node_tree.nodes;links=m.node_tree.links;p=nodes.get('Principled BSDF')
tex=nodes.new('ShaderNodeTexImage');tex.image=diff;links.new(tex.outputs['Color'],p.inputs['Base Color'])
r=nodes.new('ShaderNodeTexImage');r.image=rough;r.image.colorspace_settings.name='Non-Color';links.new(r.outputs['Color'],p.inputs['Roughness'])
p.inputs['Specular IOR Level'].default_value=.28
def finish(o,name,bevel):
 o.name=name;o.data.materials.append(m)
 if bevel:
  mod=o.modifiers.new('Weathered arris','BEVEL');mod.width=bevel;mod.segments=5
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 o.modifiers.new('Weighted surface normals','WEIGHTED_NORMAL')
 bpy.context.view_layer.objects.active=o;bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
 return o
def block(name,at,size,bevel):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,name,bevel)
block('Dressed foundation',(0,0,.10),(1.50,.84,.20),.035)
block('Chamfered plinth',(0,0,.26),(1.27,.65,.13),.023)
# Vertical tablet with curved shoulder; the front faces Blender -Y.
outline=[(-.51,.33),(.51,.33),(.51,1.19)]
outline += [(math.cos(a)*.51,1.19+math.sin(a)*.31) for a in np.linspace(0,math.pi,65)]
v=[(x,y,z) for y in [-.145,.145] for x,z in outline];n=len(outline)
faces=[tuple(reversed(range(n))),tuple(n+i for i in range(n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
d=bpy.data.meshes.new('Tablet');d.from_pydata(v,[],faces);d.update();o=bpy.data.objects.new('Tablet',d);bpy.context.collection.objects.link(o)
bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
o=finish(o,'Worn arched limestone tablet',.014)
# Boolean-carved lettering has real depth and catches grazing light.
for caption,z,size in [('REST',1.11,.14),('IN PEACE',.88,.105),('HYRULE',.60,.105)]:
 c=bpy.data.curves.new('Carved '+caption,'FONT');c.body=caption;c.align_x='CENTER';c.size=size;c.extrude=.017;c.bevel_depth=.001;c.bevel_resolution=2
 t=bpy.data.objects.new('Letter cutters',c);bpy.context.collection.objects.link(t);t.location=(0,-.153,z);t.rotation_euler=(math.pi/2,0,0)
 bpy.context.view_layer.objects.active=t;t.select_set(True);o.select_set(False);bpy.ops.object.convert(target='MESH');t=bpy.context.object
 mod=o.modifiers.new('Incised '+caption,'BOOLEAN');mod.operation='DIFFERENCE';mod.object=t;mod.solver='EXACT';bpy.context.view_layer.objects.active=o
 bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(t,do_unlink=True)
# Fine raised molding follows the shoulder and separates it from the face.
c=bpy.data.curves.new('Molded shoulder','CURVE');c.dimensions='3D';c.bevel_depth=.009;c.bevel_resolution=5;s=c.splines.new('POLY')
points=[(-.445,-.151,.42),(-.445,-.151,1.17)]+[(math.cos(a)*.445,-.151,1.17+math.sin(a)*.26) for a in np.linspace(math.pi,0,65)]+[(.445,-.151,.42)]
s.points.add(len(points)-1)
for p,co in zip(s.points,points):p.co=(*co,1)
t=bpy.data.objects.new('Rounded tablet molding',c);bpy.context.collection.objects.link(t);c.materials.append(m)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(ROOT/'game/assets/gravestone.glb'),export_format='GLB',export_apply=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'gravestone.blend'))
print('Carved marker and editable source exported')
