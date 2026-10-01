"""Authored Fairy Bow, arrow, bone warrior study and forest bark maps.
Uses the already credited adult armature and authored animations for the Stalfos study.
No extracted game data. Run with Blender from any working directory.
"""
import bpy, math, bmesh
import numpy as np
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'production/authored/forest-equipment';OUT.mkdir(exist_ok=True)
ASSETS=ROOT/'game/assets/forest';ASSETS.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,color,rough=.6,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m
wood=mat('Yew heartwood',(.25,.10,.035),.67);purple=mat('Indigo lacquer',(.055,.025,.14),.39);gold=mat('Brass fittings',(.47,.28,.065),.29,.86);leather=mat('Dark grip wrap',(.07,.035,.015),.86);steel=mat('Arrow steel',(.37,.40,.43),.25,1);feather=mat('Cream fletching',(.70,.66,.48),.96)
def tube(name,points,r,m):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=24;c.bevel_depth=r;c.bevel_resolution=6;s=c.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
 for p,co in zip(s.bezier_points,points):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);c.materials.append(m);return o
def cylinder(name,a,b,r,m):
 a=Vector(a);b=Vector(b);bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=r,depth=(b-a).length,location=(a+b)*.5);o=bpy.context.object;o.name=name;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(m);mod=o.modifiers.new('Edge radius','BEVEL');mod.width=min(.003,r*.2);mod.segments=4;o.modifiers.new('Normals','WEIGHTED_NORMAL');return o
def export(name,items,anim=False):
 bpy.ops.object.select_all(action='DESELECT')
 for o in items:o.select_set(True)
 bpy.context.view_layer.objects.active=items[0]
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'game/assets'/name),export_format='GLB',use_selection=True,export_apply=True,export_animations=anim)
# Recurved limbs are solid laminated profiles, not flat cutouts.
for sign in [-1,1]:
 pts=[(0,0,0),(0,-.045,sign*.20),(0,-.13,sign*.43),(0,-.08,sign*.62),(0,.045,sign*.72)]
 tube('Recurved yew limb',pts,.023,wood)
 tube('Lacquered limb backing',[(.018,y,z) for x,y,z in pts],.009,purple)
 tube('Raised brass edge',[(x-.019,y-.008,z) for x,y,z in pts],.0035,gold)
 cylinder('Brass limb socket',(0,0,sign*.09),(0,-.018,sign*.15),.032,gold)
 tube('String nock',[(0,.036,sign*.695),(0,.058,sign*.725)],.005,gold)
cylinder('Contoured leather grip',(0,0,-.10),(0,0,.10),.030,leather)
for i in range(12):
 z=-.09+i*.016
 tube('Grip lacing',[(math.cos(a)*.031,math.sin(a)*.031,z+.012*a/math.tau) for a in np.linspace(0,math.tau,25)],.002,purple)
tube('Bowstring',[(0,.05,-.725),(0,.05,.725)],.0022,leather)
bow=list(bpy.context.scene.objects);export('fairy_bow.glb',bow)
cylinder('Cedar arrow shaft',(0,0,-.32),(0,0,.35),.005,wood)
bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=.023,radius2=0,depth=.08,location=(0,0,.39));bpy.context.object.name='Forged broadhead';bpy.context.object.data.materials.append(steel)
for a in [0,math.tau/3,2*math.tau/3]:
 v=[(0,0,-.32),(.035*math.cos(a),.035*math.sin(a),-.28),(.028*math.cos(a),.028*math.sin(a),-.18),(0,0,-.16)]
 d=bpy.data.meshes.new('Feather');d.from_pydata(v,[],[(0,1,2,3)]);d.materials.append(feather);o=bpy.data.objects.new('Arrow fletching',d);bpy.context.collection.objects.link(o);mod=o.modifiers.new('Feather thickness','SOLIDIFY');mod.thickness=.001
export('arrow.glb',[o for o in bpy.context.scene.objects if o not in bow]);bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'bow-and-arrow.blend'))
# Authored bark: long furrows vary with height, lateral pores and raised plates.
N=1024;y,x=np.mgrid[0:N,0:N]/N;rng=np.random.default_rng(931)
warp=x+.012*np.sin(y*math.tau*3)+.006*np.sin(y*math.tau*11+x*15)
ridge=(.5+.5*np.sin(warp*math.tau*23))**.65
fine=np.sin(warp*math.tau*71+y*3)*.06+rng.normal(0,.022,(N,N))
h=np.clip(ridge*.6+fine+.11*np.sin(y*31+x*18),0,1)
base=np.clip(.27+h*.30,0,1);color=np.stack([base*.94,base*.78,base*.57],-1)
dy,dx=np.gradient(h);norm=np.stack([-dx*11,-dy*11,np.ones_like(h)],-1);norm/=np.linalg.norm(norm,axis=-1,keepdims=True)
for name,pixels in [('bark_diff',color),('bark_nor_gl',norm*.5+.5),('bark_rough',np.repeat((.87+h*.08)[:,:,None],3,axis=2))]:
 im=bpy.data.images.new(name,width=N,height=N,alpha=False);rgba=np.ones((N,N,4),dtype=np.float32);rgba[:,:,:3]=pixels;im.pixels.foreach_set(rgba.ravel());im.filepath_raw=str(ASSETS/(name+'.png'));im.file_format='PNG';im.save()
# Skeleton study, bound to the existing credited adult armature.
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'production/authored/adult-link-study/link-adult.blend'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
for o in list(bpy.context.scene.objects):
 if o!=rig:bpy.data.objects.remove(o,do_unlink=True)
bone_mat=mat('Weathered ivory bone',(.55,.50,.38),.87)
dark=mat('Deep bone cavities',(.028,.023,.017),.96)
def bind(o,bone):
 bpy.context.view_layer.objects.active=o
 if o.type!='MESH':bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.ops.object.convert(target='MESH');o=bpy.context.object
 group=o.vertex_groups.new(name=bone);group.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Bone articulation','ARMATURE');mod.object=rig;return o
def sphere(name,at,size,m,bone):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=64,ring_count=32,location=at);o=bpy.context.object;o.name=name;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 for p in o.data.polygons:p.use_smooth=True
 return bind(o,bone)
for side in ['L','R']:
 for name,r in [('upperleg01',.034),('upperleg02',.034),('lowerleg01',.023),('lowerleg02',.023),('upperarm01',.022),('upperarm02',.022),('lowerarm01',.018),('lowerarm02',.018)]:
  key=name+'.'+side;b=rig.data.bones[key];a=rig.matrix_world@b.head_local;c=rig.matrix_world@b.tail_local
  bind(cylinder(key+' bone',a,c,r,bone_mat),key)
  for p in [a,c]:sphere('Joint condyle',p,(r*1.5,r*1.25,r*1.25),bone_mat,key)
 for key in ['wrist.'+side,'foot.'+side]:
  if key not in rig.data.bones:continue
  b=rig.data.bones[key];sphere('Extremity',rig.matrix_world@b.head_local,(.045,.095,.035),bone_mat,key)
for name in ['spine05','spine04','spine03','spine02','spine01','neck01','neck02','neck03']:
 if name not in rig.data.bones:continue
 b=rig.data.bones[name];a=rig.matrix_world@b.head_local;c=rig.matrix_world@b.tail_local
 for i in range(4):sphere('Vertebra',a.lerp(c,i/4),(.042,.032,.028),bone_mat,name)
chest=rig.matrix_world@rig.data.bones['spine01'].head_local
for i in range(12):
 z=chest.z-.16+i*.026;radius=.12+.065*math.sin((i+1)*math.pi/13)
 for sign in [-1,1]:
  pts=[(chest.x+sign*math.sin(a)*radius,chest.y-math.cos(a)*.095,z+.01*math.sin(a)) for a in np.linspace(.12,math.pi-.1,20)]
  bind(tube('Curved rib',pts,.008,bone_mat),'spine03' if z<1.146 else 'spine02' if z<1.283 else 'spine01')
head=rig.matrix_world@rig.data.bones['head'].head_local
skull=sphere('Cranium',head+Vector((0,-.015,.105)),(.109,.102,.131),bone_mat,'head')
for sign in [-1,1]:
 sphere('Eye socket',head+Vector((sign*.043,-.106,.115)),(.033,.018,.039),dark,'head')
 sphere('Cheek arch',head+Vector((sign*.072,-.071,.057)),(.044,.036,.03),bone_mat,'head')
sphere('Nasal cavity',head+Vector((0,-.110,.065)),(.018,.012,.027),dark,'head')
bind(tube('Mandible',[(head.x+x,head.y+y,head.z+z) for x,y,z in [(-.079,-.035,.06),(-.070,-.085,.007),(0,-.11,-.008),(.070,-.085,.007),(.079,-.035,.06)]],.013,bone_mat),'head')
for i in range(10):sphere('Tooth',head+Vector((-.055+i*.012,-.106,.035)),(.005,.009,.010),bone_mat,'head')
# Shoulder girdle and sternum join the arms to the rib cage.
for side in ['L','R']:
 sign=1 if side=='L' else -1
 b=rig.data.bones['upperarm01.'+side]
 endpoint=rig.matrix_world@b.head_local
 bind(tube('Clavicle',[(sign*.018,-.10,1.40),(sign*.10,-.055,1.43),tuple(endpoint)],.012,bone_mat),'clavicle.'+side)
 sphere('Scapula',(sign*.10,.075,1.34),(.067,.016,.087),bone_mat,'spine01')
bind(tube('Sternum',[(0,-.095,1.16),(0,-.11,1.28),(0,-.10,1.40)],.018,bone_mat),'spine01')
hip=rig.matrix_world@rig.data.bones['spine05'].head_local
for sign in [-1,1]:sphere('Pelvic wing',hip+Vector((sign*.09,0,-.055)),(.09,.064,.075),bone_mat,'pelvis.L' if sign>0 else 'pelvis.R')
export('stalfos.glb',list(bpy.context.scene.objects),True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'stalfos-study.blend'))
print('Forest equipment, bark and articulated bone study exported')
