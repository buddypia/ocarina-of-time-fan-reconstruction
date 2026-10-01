"""Authored Hookshot mechanism and Hylian Shield; editable Blender source.
Photographic construction reference: Met cranequin 1986.205 (public domain).
The fictional shapes are authored here; no ROM or extracted game assets.
"""
import bpy, bmesh, math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'production/authored/graveyard-equipment'; OUT.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def mat(name,color,rough,metal=0):
 m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1); p.inputs['Roughness'].default_value=rough; p.inputs['Metallic'].default_value=metal
 return m
steel=mat('Tempered steel',(.31,.35,.38),.29,1)
brass=mat('Oiled brass',(.42,.26,.085),.32,.92)
blue=mat('Indigo enamel',(.023,.055,.18),.38,.35)
leather=mat('Wrapped leather',(.085,.042,.021),.77)
red=mat('Vermilion raised crest',(.43,.022,.014),.41,.2)
def mesh(name,v,f,m,bevel=.003):
 d=bpy.data.meshes.new(name); d.from_pydata(v,[],f); d.update()
 o=bpy.data.objects.new(name,d); bpy.context.collection.objects.link(o); d.materials.append(m)
 bm=bmesh.new(); bm.from_mesh(d); bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(d); bm.free()
 if bevel: b=o.modifiers.new('Rounded forged edges','BEVEL'); b.width=bevel; b.segments=4; o.modifiers.new('Normals','WEIGHTED_NORMAL')
 return o
def cylinder(name,a,b,r,m,vertices=96):
 a=Vector(a); b=Vector(b)
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=(b-a).length,location=(a+b)/2)
 o=bpy.context.object; o.name=name; o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler(); o.data.materials.append(m)
 bevel=o.modifiers.new('Machined radius','BEVEL'); bevel.width=.003; bevel.segments=3; o.modifiers.new('Normals','WEIGHTED_NORMAL')
 return o
def path(name,points,r,m):
 c=bpy.data.curves.new(name,'CURVE'); c.dimensions='3D'; c.bevel_depth=r; c.bevel_resolution=4; s=c.splines.new('POLY'); s.points.add(len(points)-1)
 for p,v in zip(s.points,points): p.co=(*v,1)
 o=bpy.data.objects.new(name,c); bpy.context.collection.objects.link(o); c.materials.append(m); return o
def ring(name,z,r,t,m):
 return path(name,[(math.cos(a)*r,math.sin(a)*r,z) for a in [i*math.tau/96 for i in range(97)]],t,m)
def export(name,objects):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects: o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'game/assets'/name),export_format='GLB',use_selection=True,export_apply=True)
# The barrel is an open tube: visible inner bore, collars, reel supports and fasteners.
v=[]
for z,r in [(-.10,.086),(.28,.086),(.28,.063),(-.10,.063)]:
 for i in range(96): a=i*math.tau/96; v.append((math.cos(a)*r,math.sin(a)*r,z))
f=[(j*96+i,j*96+(i+1)%96,((j+1)%4)*96+(i+1)%96,((j+1)%4)*96+i) for j in range(4) for i in range(96)]
mesh('Hollow barrel with visible bore',v,f,steel,.002)
for z in [-.08,.08,.25]: ring('Brass barrel collar',z,.092,.01,brass)
cylinder('Leather pistol grip',(0,-.07,-.065),(0,-.25,-.095),.032,leather)
for i in range(10):
 y=-.085-i*.015
 path('Grip binding',[(math.cos(a)*.033,y+.007*a/math.tau,-.078+math.sin(a)*.033) for a in [j*math.tau/48 for j in range(49)]],.002,brass)
path('Trigger guard',[(0,-.08,.08),(0,-.17,.08),(0,-.185,-.035),(0,-.10,-.04)],.008,brass)
path('Curved trigger',[(0,-.075,.055),(0,-.13,.045),(0,-.145,.02)],.007,steel)
for x in [-.10,.10]:
 cylinder('Reel flange',(x-.008,.01,-.09),(x+.008,.01,-.09),.114,blue)
 cylinder('Reel axle',(x-.015,.01,-.09),(x+.016,.01,-.09),.021,brass)
 for i in range(8):
  a=i*math.tau/8
  cylinder('Reel rivet',(x-.013,.01+math.sin(a)*.09,-.09+math.cos(a)*.09),(x+.013,.01+math.sin(a)*.09,-.09+math.cos(a)*.09),.005,steel,32)
for i in range(16):
 x=-.084+i*.011
 path('Coiled cable',[(x,.01+math.sin(a)*.077,-.09+math.cos(a)*.077) for a in [j*math.tau/80 for j in range(81)]],.004,steel)
path('Winding crank',[(.13,.01,-.09),(.145,.01,-.09),(.145,-.063,-.14),(.185,-.063,-.14)],.01,steel)
cylinder('Horn crank knob',(.18,-.063,-.14),(.225,-.063,-.14),.017,leather)
gun=list(bpy.context.scene.objects); export('hookshot.glb',gun)
cylinder('Hook shaft',(0,0,-.08),(0,0,.17),.020,steel)
for a in [0,math.tau/3,2*math.tau/3]:
 points=[(.02,-.06),(.082,.05),(.072,.15),(.008,.25)]
 path('Swept grappling talon',[(math.cos(a)*r,math.sin(a)*r,z) for r,z in points],.014,steel)
ring('Hook retaining collar',-.04,.025,.009,brass)
head=[o for o in bpy.context.scene.objects if o not in gun]; export('hookshot_head.glb',head)
# Shield: gently convex steel core with a rolled perimeter and strapped rear.
before=list(bpy.context.scene.objects)
outline=[(-.31,.34),(-.23,.42),(0,.45),(.23,.42),(.31,.34),(.30,-.06),(.21,-.24),(0,-.43),(-.21,-.24),(-.30,-.06)]
v=[(0,-.065,0)]+[(x,-.015,z) for x,z in outline]+[(x,.025,z) for x,z in outline]+[(0,.005,0)]
n=len(outline); f=[]
for i in range(n):
 j=(i+1)%n
 f += [(0,i+1,j+1),(2*n+1,n+j+1,n+i+1),(i+1,n+i+1,n+j+1,j+1)]
mesh('Convex shield face',v,f,blue,.004)
path('Rolled steel perimeter',[(x,-.02,z) for x,z in outline+[outline[0]]],.021,steel)
for x,z in outline:
 cylinder('Shield rim rivet',(x*.91,-.035,z*.92),(x*.91,-.048,z*.92),.009,steel,32)
for x,z in [(0,.23),(-.053,.138),(.053,.138)]:
 mesh('Triforce inlay',[(x-.05,-.078,z),(x+.05,-.078,z),(x,-.078,z+.088)],[(0,1,2)],brass,0)
crest=[(-.02,.05),(-.08,-.06),(-.24,.025),(-.17,-.105),(-.075,-.16),(0,-.32),(.075,-.16),(.17,-.105),(.24,.025),(.08,-.06),(.02,.05)]
mesh('Raised bird crest',[(x,-.076,z) for x,z in crest],[tuple(range(len(crest)))],red,.002)
for x in [-.13,.13]:
 path('Leather arm strap',[(x,.035,.16),(x,.15,.10),(x,.17,-.04),(x,.035,-.15)],.025,leather)
 for z in [-.15,.16]: cylinder('Strap mounting stud',(x,.03,z),(x,.052,z),.019,brass)
export('hylian_shield.glb',[o for o in bpy.context.scene.objects if o not in before])
bpy.ops.object.select_all(action='SELECT'); bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'equipment.blend'))
print('Authored Hookshot, grappling head and Hylian Shield exported')
