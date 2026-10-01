"""Editable authored Master Sword and scabbard. No extracted game assets.
blender --background --python production/authored/make_master_sword.py
"""
import bpy,bmesh,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'production/authored/master-sword';OUT.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def material(name,color,rough,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m
steel=material('Satin polished steel',(.56,.61,.66),.24,1)
edge=material('Honed steel bevel',(.72,.75,.78),.17,1)
purple=material('Indigo enamel on bronze',(.065,.026,.20),.29,.55)
gold=material('Raised brass inlay',(.58,.36,.09),.27,.9)
grip=material('Dark woven grip',(.025,.038,.065),.8)
blue=material('Blue leather scabbard',(.02,.045,.14),.7)
def mesh(name,v,f,mat,bevel=.002):
 m=bpy.data.meshes.new(name);m.from_pydata(v,[],f);m.update();o=bpy.data.objects.new(name,m);bpy.context.collection.objects.link(o);m.materials.append(mat)
 bm=bmesh.new();bm.from_mesh(m);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(m);bm.free()
 if bevel:b=o.modifiers.new('Dressed edges','BEVEL');b.width=bevel;b.segments=4;o.modifiers.new('Face normals','WEIGHTED_NORMAL')
 return o
def path(name,points,r,mat):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=4;s=c.splines.new('POLY');s.points.add(len(points)-1)
 for p,v in zip(s.points,points):p.co=(*v,1)
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);c.materials.append(mat);return o
def cylinder(name,at,r,depth,mat):
 bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=r,depth=depth,location=at);o=bpy.context.object;o.name=name;o.data.materials.append(mat);b=o.modifiers.new('Rounded edge','BEVEL');b.width=.004;b.segments=4;o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');return o
# Grip center is the socket origin; the blade runs in local +Z.
rings=[(.15,.045),(.23,.066),(.34,.059),(.90,.041),(1.04,.030),(1.15,.001)]
v=[]
for z,w in rings:
 for x,y in [(-w,0),(-w*.64,-.010),(0,-.016),(w*.64,-.010),(w,0),(w*.64,.010),(0,.016),(-w*.64,.010)]:v.append((x,y,z))
f=[tuple(reversed(range(8))),tuple((len(rings)-1)*8+i for i in range(8))]
for j in range(len(rings)-1):
 for i in range(8):f.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i))
o=mesh('Fullered tapered sacred blade',v,f,steel,.0008);o.data.materials.append(edge)
for p in o.data.polygons:
 if p.index>=2 and (p.index-2)%8 in [0,3,4,7]:p.material_index=1
# Swept wing guard, closed solid with layered enamel borders.
outline=[(-.31,.074),(-.23,.15),(-.10,.18),(-.066,.137),(0,.126),(.066,.137),(.10,.18),(.23,.15),(.31,.074),(.24,.092),(.10,.119),(.058,.085),(-.058,.085),(-.10,.119),(-.24,.092)]
v=[(x,y,z) for y in [-.028,.028] for x,z in outline];n=len(outline)
f=[tuple(reversed(range(n))),tuple(n+i for i in range(n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
mesh('Swept indigo crossguard',v,f,purple,.007)
for sign in [-1,1]:path('Raised wing molding',[(sign*x,-.031,z) for x,z in [( .065,.123),(.10,.155),(.22,.13),(.28,.088)]],.006,purple)
cylinder('Wrapped grip',(0,0,-.011),.027,.205,grip)
for i in range(14):
 z=-.10+i*.014
 path('Diagonal grip lacing',[(math.sin(a)*.028,math.cos(a)*.028,z+.012*a/math.tau) for a in [j*math.tau/48 for j in range(49)]],.0022,purple)
for z in [-.13,.09]:cylinder('Pommel and collar',(0,0,z),.041,.025,purple)
bpy.ops.mesh.primitive_uv_sphere_add(segments=64,ring_count=32,location=(0,0,-.157));o=bpy.context.object;o.name='Faceted oval pommel';o.scale=(.040,.030,.046);o.data.materials.append(purple)
# Three engraved triangles are geometrically inlaid on both blade faces.
for side in [-1,1]:
 for x,z in [(0,.292),(-.016,.265),(.016,.265)]:
  mesh('Triforce blade inlay',[(x-.015,side*.017,z),(x+.015,side*.017,z),(x,side*.017,z+.026)],[(0,1,2)],gold,0)
sword=list(bpy.context.scene.objects)
def export(name,objects):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'game/assets'/name),export_format='GLB',use_selection=True,export_apply=True)
export('master_sword.glb',sword)
rings=[(.16,.059),(.24,.073),(.36,.066),(.92,.047),(1.08,.034),(1.16,.008)];v=[]
for z,w in rings:
 for x,y in [(-w,-.025),(w,-.025),(w,.025),(-w,.025)]:v.append((x,y,z))
f=[(3,2,1,0),tuple((len(rings)-1)*4+i for i in range(4))]+[(j*4+i,j*4+(i+1)%4,(j+1)*4+(i+1)%4,(j+1)*4+i) for j in range(len(rings)-1) for i in range(4)]
mesh('Blue stitched scabbard',v,f,blue,.005)
for z,w in [(.18,.061),(.40,.064),(.93,.048),(1.10,.029)]:path('Scabbard brass band',[(-w,-.028,z),(w,-.028,z),(w,.028,z),(-w,.028,z),(-w,-.028,z)],.005,gold)
export('master_scabbard.glb',[o for o in bpy.context.scene.objects if o not in sword])
bpy.ops.object.select_all(action='SELECT');bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'master-sword.blend'))
print('Authored sacred sword and scabbard exported')
