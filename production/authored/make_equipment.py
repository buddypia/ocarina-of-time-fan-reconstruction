"""Author editable equipment meshes. Blender + its bundled Python only.
Run from ocarina-of-time/: blender --background --python production/authored/make_equipment.py
Local asset axes: Y up, front +Z after glTF export; sword grip at origin.
"""
import bpy, bmesh, math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'production/authored/equipment';OUT.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

def mat(name,color,rough,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
    return m
steel=mat('Ground steel blade',(.40,.46,.48),.24,.92)
brass=mat('Worn bronze castings',(.32,.21,.08),.37,.80)
leather=mat('Vegetable-tanned leather bindings',(.045,.024,.011),.73)
paint=mat('Iron oxide carved forest crest',(.29,.033,.015),.8)
wood=mat('Vertical-grain linden shield',(.24,.12,.044),.78)
# Authored plank grain: narrow longitudinal fibers follow shield construction.
# A texture preserves that direction in the portable glTF material.
size=512;im=bpy.data.images.new('Linden grain',width=size,height=size);pix=[]
for j in range(size):
    y=j/size
    for i in range(size):
        x=i/size
        warp=x+.011*math.sin(y*8+x*17)+.006*math.sin(y*21+x*37)
        late=math.sin(warp*math.tau*31+.3*math.sin(y*5))
        fiber=math.sin(warp*math.tau*173+y*.8)
        value=.90+.09*late+.025*fiber
        pix.extend((.44*value,.27*value,.115*value,1))
im.pixels=pix;im.filepath_raw=str(OUT/'linden-grain.png');im.file_format='PNG';im.save();im.pack()
n=wood.node_tree.nodes.new('ShaderNodeTexImage');n.image=im;wood.node_tree.links.new(n.outputs['Color'],wood.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])

def mesh(name,verts,faces,material,bevel=0):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);me.materials.append(material)
    uv=me.uv_layers.new()
    for face in me.polygons:
        for loop in face.loop_indices:
            v=me.vertices[me.loops[loop].vertex_index].co
            uv.data[loop].uv=(v.x*1.8+.5,v.z*1.7+.5)
    if bevel:
        mod=ob.modifiers.new('Edge rounding','BEVEL');mod.width=bevel;mod.segments=3
        mod=ob.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
    return ob

def curve(name,coords,r,material,cyclic=False):
    data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.resolution_u=12;data.bevel_depth=r;data.bevel_resolution=4
    sp=data.splines.new('POLY');sp.points.add(len(coords)-1);sp.use_cyclic_u=cyclic
    for p,co in zip(sp.points,coords):p.co=(*co,1)
    ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob);data.materials.append(material)
    return ob

def sphere(name,at,scale,material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=24,location=at)
    ob=bpy.context.object;ob.name=name;ob.scale=scale;ob.data.materials.append(material)
    for p in ob.data.polygons:p.use_smooth=True
    return ob

def cylinder(name,r,depth,at,material):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=r,depth=depth,location=at)
    ob=bpy.context.object;ob.name=name;ob.data.materials.append(material)
    mod=ob.modifiers.new('Rounded edges','BEVEL');mod.width=.002;mod.segments=3
    ob.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    return ob

def export(name,objects):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objects:
        ob.select_set(True)
        if ob.type=='MESH':
            bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'game/assets'/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_apply=True)

# Sword: edge, sloped grind, recessed fuller, shoulder, crossguard and wrapped grip.
verts=[];rings=[(.105,.028),(.16,.029),(.44,.024),(.555,.018),(.625,.0007)]
profile=[(-1,0),(-.72,-.004),(-.2,-.003),(.2,-.003),(.72,-.004),(1,0),(.72,.004),(.2,.003),(-.2,.003),(-.72,.004)]
for z,w in rings:
    for x,y in profile:verts.append((x*w,y,z))
faces=[tuple(reversed(range(10)))]
for j in range(len(rings)-1):
    for i in range(10):faces.append((j*10+i,j*10+(i+1)%10,(j+1)*10+(i+1)%10,(j+1)*10+i))
faces.append(tuple((len(rings)-1)*10+i for i in range(10)))
mesh('Tapered steel with recessed fuller',verts,faces,steel,.0005)
curve('Swept bronze crossguard',[(-.115,0,.078),(-.11,0,.094),(-.075,0,.113),(0,0,.121),(.075,0,.113),(.11,0,.094),(.115,0,.078)],.013,brass)
cylinder('Leather grip core',.016,.15,(0,0,.013),leather)
curve('Spiral grip binding',[(.017*math.cos(i*.14),.017*math.sin(i*.14),-.060+i*.00045) for i in range(334)],.0012,leather)
for z in [-.066,.092]:cylinder('Grip collar',.019,.011,(0,0,z),brass)
sphere('Oval pommel',(0,0,-.084),(.025,.017,.024),brass)
export('kokiri_sword',list(bpy.context.scene.objects))
sword_objects=list(bpy.context.scene.objects)
# Curved wooden shield, made of five tapered planks, a rolled rim and back straps.
# Negative Blender Y is its front, exported as Godot +Z.
def width(z):
    t=max(0,min(1,(z+.32)/.62))
    return .245*(math.sin(math.pi*t)**.60)*(.84+.20*t)
def surface_y(x):return -.042*(1-(x/.255)**2)
for plank in range(5):
    points=[];faces=[];rows=48
    for row in range(rows+1):
        z=-.314+row*.606/rows;w=width(z)
        left=-w+2*w*plank/5+.001
        right=-w+2*w*(plank+1)/5-.001
        for yoff in [-.011,.011]:
            for x in [left,right]:points.append((x,surface_y(x)+yoff,z))
    for row in range(rows):
        a=row*4;b=(row+1)*4
        for q in [(0,1,1,0),(2,3,3,2),(0,2,2,0),(1,3,3,1)]:faces.append((a+q[0],a+q[1],b+q[2],b+q[3]))
    faces.extend([(0,2,3,1),(rows*4,rows*4+1,rows*4+3,rows*4+2)])
    mesh('Linden shield plank '+str(plank+1),points,faces,wood,.002)
outline=[]
for side,steps in [(-1,range(65)),(1,range(64,-1,-1))]:
    for i in steps:
        z=-.32+i*.62/64;x=side*width(z);outline.append((x,surface_y(x),z))
curve('Bound bronze shield rim',outline,.010,brass,True)
for x in [-.08,.08]:
    curve('Riveted leather back strap',[(x,.012,-.14),(x,.068,-.09),(x,.077,.07),(x,.010,.14)],.013,leather)
    for z in [-.15,.15]:sphere('Rounded rim rivet',(x,surface_y(x)-.019,z),(.006,.003,.006),brass)
# An engraved, branching spiral recalls the forest motif; it is not a pasted decal.
crest=[(-.01,-.15),(-.10,-.025),(-.08,.10),(.025,.17),(.12,.09),(.08,-.005),(-.015,.015),(-.035,.07),(.025,.095),(.06,.055)]
curve('Carved red forest spiral',[(x,surface_y(x)-.015,z) for x,z in crest],.008,paint)
curve('Lower forest stem',[(x,surface_y(x)-.015,z) for x,z in [(0,-.23),(0,-.15),(.07,-.08)]],.007,paint)
export('deku_shield',[o for o in bpy.context.scene.objects if o not in sword_objects])
previous=list(bpy.context.scene.objects)
points=[]
for z,w in [(.118,.034),(.46,.029),(.59,.021),(.638,.008)]:
    for x,y in [(-w,-.012),(w,-.012),(w,.012),(-w,.012)]:points.append((x,y,z))
faces=[(0,3,2,1),(12,13,14,15)]
for j in range(3):
    for i in range(4):faces.append((j*4+i,j*4+(i+1)%4,(j+1)*4+(i+1)%4,(j+1)*4+i))
mesh('Stitched leather scabbard',points,faces,leather,.004)
for z,w in [(.128,.035),(.608,.018)]:
    curve('Scabbard bronze band',[(-w,-.012,z),(w,-.012,z),(w,.012,z),(-w,.012,z)],.003,brass,True)
curve('Scabbard longitudinal seam',[(-.033,0,.14),(-.028,0,.46),(-.020,0,.59),(-.007,0,.63)],.001,brass)
export('kokiri_scabbard',[o for o in bpy.context.scene.objects if o not in previous])
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'equipment.blend'))
print('Authored sword and curved plank shield saved with editable source.')
