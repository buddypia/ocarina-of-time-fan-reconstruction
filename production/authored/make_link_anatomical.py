"""Build an editable clothed Link study from CC0 anatomical data and authored garments.
Run: blender --background --python production/authored/make_link_anatomical.py
The MakeHuman mesh, morph, skin, eyes, hair and weights retain their provenance.
"""
import bpy, bmesh, math, json, sys
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix, kdtree
ROOT=Path(__file__).resolve().parents[2]
ADULT='--adult' in sys.argv
REF=ROOT/'production/reference-assets'; OUT=ROOT/('production/authored/adult-link-study' if ADULT else 'production/authored/link-study');OUT.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

def obj_data(path):
    vertices=[];uvs=[];faces=[];group=''
    for line in path.read_text().splitlines():
        a=line.split()
        if not a:continue
        if a[0]=='v':vertices.append(Vector(tuple(map(float,a[1:4]))))
        elif a[0]=='vt':uvs.append(tuple(map(float,a[1:3])))
        elif a[0]=='g':group=a[1]
        elif a[0]=='f':faces.append((group,[(int(x.split('/')[0])-1,int(x.split('/')[1])-1 if '/' in x else -1) for x in a[1:]]))
    return vertices,uvs,faces
raw,uvs,all_faces=obj_data(REF/'makehuman-base.obj');neutral=[v.copy() for v in raw]
for name in ['caucasian-male-child.target','universal-male-child-averagemuscle-averageweight.target']:
    for line in (REF/name).read_text().splitlines():
        a=line.split()
        if a and not a[0].startswith('#'):raw[int(a[0])]+=Vector(tuple(map(float,a[1:4])))
body_faces=[f for g,f in all_faces if g=='body'];used={i for f in body_faces for i,_ in f}
base_y=min(raw[i].y for i in used);scale=1.40/(max(raw[i].y for i in used)-base_y)
def convert(v):return Vector((v.x*scale,-v.z*scale,(v.y-base_y)*scale))
vertices=[convert(v) for v in raw]
# Extend the upper ear helix while preserving the CC0 ear's folds and lobe.
for i in used:
    v=vertices[i]
    if 1.265<v.z<1.345 and abs(v.x)>.092:
        amount=min(1,(abs(v.x)-.092)/.035)*min(1,max(0,(v.z-1.265)/.045))
        v.x+=math.copysign(.030*amount,v.x);v.z+=.014*amount

rigdata=json.loads((REF/'default.mhskel').read_text());weightdata=json.loads((REF/'default_weights.mhw').read_text())['weights']
weights=[{} for _ in raw]
for bone,values in weightdata.items():
    for i,w in values:
        if i<len(weights):weights[i][bone]=w
kd=kdtree.KDTree(len(used))
for i in used:kd.insert(vertices[i],i)
kd.balance()
def material(name,color,rough=.8,texture=None):
    mat=bpy.data.materials.new(name);mat.diffuse_color=(*color,1);mat.use_nodes=True
    nodes=mat.node_tree.nodes;p=nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough
    if texture:
        tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(texture),check_existing=True)
        mat.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
    return mat
skin=material('CC0 skin — MakeHuman young light male',(.68,.45,.33),.53,REF/'makehuman-system/skins/young_caucasian_male/young_lightskinned_male_diffuse.png')
skin.node_tree.nodes.get('Principled BSDF').inputs['Subsurface Weight'].default_value=.05
cloth=material('Dyed forest-green wool',(.034,.093,.021),.91)
cloth.node_tree.nodes.get('Principled BSDF').inputs['Sheen Weight'].default_value=.25
linen=material('Unbleached linen breeches',(.58,.53,.39),.96)
leather=material('Brown vegetable-tanned leather',(.085,.037,.013),.67)
outsole=material('Layered leather sole',(.032,.018,.008),.85)
edge=material('Linen stitching',(.32,.27,.14),.95)
metal=material('Aged brass buckle',(.39,.23,.07),.32);metal.node_tree.nodes.get('Principled BSDF').inputs['Metallic'].default_value=.82
# Tangent-space microstructure follows yarn crossings and leather pores, at garment UV scale.
def micro_normal(name,mat,kind):
    size=1024;y,x=np.mgrid[0:size,0:size].astype(np.float32)
    if kind=='weave':
        u=x/8;v=y/8;over=((np.floor(u)+np.floor(v))%2)*2-1
        h=np.where(over>0,np.cos((u%1-.5)*math.pi),np.cos((v%1-.5)*math.pi))*.15
        h+=.018*np.sin(x*math.pi*.5+y*.18)
    else:
        rng=np.random.default_rng(7331);h=np.zeros((size,size),np.float32)
        for i in range(10):
            a=rng.uniform(0,math.tau);freq=rng.uniform(.10,.40)
            h+=np.sin(x*math.cos(a)*freq+y*math.sin(a)*freq+rng.uniform(0,6))*.018
    dy,dx=np.gradient(h);n=np.dstack((-dx,-dy,np.ones_like(h)));n/=np.linalg.norm(n,axis=2,keepdims=True)
    rgba=np.dstack((n*.5+.5,np.ones_like(h)))
    image=bpy.data.images.new(name,width=size,height=size);image.colorspace_settings.name='Non-Color';image.pixels.foreach_set(rgba.ravel())
    image.filepath_raw=str(OUT/(name+'.png'));image.file_format='PNG';image.save();image.pack()
    nodes=mat.node_tree.nodes;tex=nodes.new('ShaderNodeTexImage');tex.image=image
    normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.60
    mat.node_tree.links.new(tex.outputs['Color'],normal.inputs['Color']);mat.node_tree.links.new(normal.outputs['Normal'],nodes.get('Principled BSDF').inputs['Normal'])
micro_normal('Wool yarn crossings',cloth,'weave')
micro_normal('Fine linen crossings',linen,'weave')
micro_normal('Tanned leather pores',leather,'leather')

hair=material('CC0 short hair',(.44,.24,.07),.58,REF/'makehuman-system/hair/short01/short01_diffuse.png')
# The source hair atlas includes coverage, so strands retain their cutout silhouettes.
hp=hair.node_tree.nodes.get('Principled BSDF');ht=next(n for n in hair.node_tree.nodes if n.type=='TEX_IMAGE')
hair.node_tree.links.new(ht.outputs['Alpha'],hp.inputs['Alpha']);hair.surface_render_method='DITHERED'
for link in list(hp.inputs['Base Color'].links):hair.node_tree.links.remove(link)
hp.inputs['Base Color'].default_value=(.26,.12,.025,1)

eyes=material('CC0 blue iris and sclera',(.8,.8,.8),.17,REF/'makehuman-system/eyes/materials/blue_eye.png')
ep=eyes.node_tree.nodes.get('Principled BSDF');et=next(n for n in eyes.node_tree.nodes if n.type=='TEX_IMAGE')
eyes.node_tree.links.new(et.outputs['Alpha'],ep.inputs['Alpha']);eyes.surface_render_method='DITHERED'


def rigged_mesh(name,points,faces,mat,source_ids=None,face_uvs=None):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(points,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);mesh.materials.append(mat)
    for p in mesh.polygons:p.use_smooth=True
    uv=mesh.uv_layers.new(name='UVMap')
    for p in mesh.polygons:
        for j,loop in enumerate(p.loop_indices):
            v=points[mesh.loops[loop].vertex_index]
            uv.data[loop].uv=face_uvs[p.index][j] if face_uvs and mat not in [cloth,linen,leather] else (v[0]*9,v[2]*9+v[1]*2)
    ids=source_ids if source_ids is not None else [kd.find(Vector(v))[1] for v in points]
    for name in weightdata:o.vertex_groups.new(name=name)
    for i,source in enumerate(ids):
        data=weights[source];total=sum(data.values())
        for bone,w in data.items():
            if w>.001:o.vertex_groups[bone].add([i],w/max(total,.001),'REPLACE')
    return o

def body_region(name,select,mat,inflate=0):
    selected=[f for f in body_faces if select(sum((vertices[i] for i,_ in f),Vector())/len(f))]
    ids=sorted({i for f in selected for i,_ in f});mapping={src:i for i,src in enumerate(ids)}
    points=[vertices[i].copy() for i in ids]
    o=rigged_mesh(name,points,[[mapping[i] for i,_ in f] for f in selected],mat,ids,[[uvs[u] for _,u in f] for f in selected])
    if inflate:
        mesh=o.data
        for v in mesh.vertices:v.co+=v.normal*inflate
    sub=o.modifiers.new('Anatomical surface subdivision','SUBSURF');sub.levels=1;sub.render_levels=2
    return o
# Hidden torso and pelvis faces are deliberately omitted from this clothed export.
body_region('Face, neck and hands',lambda v:v.z>1.23 or (v.z>1.13 and abs(v.x)<.089) or (abs(v.x)>.20 and v.z>.74),skin)
trousers=body_region('Fitted linen trousers',lambda v:.285<v.z<.74 and abs(v.x)<.235,linen,.004)
for v in trousers.data.vertices:
    if v.co.z<.365:
        center=math.copysign(.16-(v.co.z-.07)*.1,v.co.x)
        ratio=max(0,min(1,(.365-v.co.z)/.07))*.28
        v.co.x=center+(v.co.x-center)*(1-ratio)
        v.co.y=-.030+(v.co.y+.030)*(1-ratio)

def tube(name,rings,mat,segments=64):
    points=[]
    for z,rx,ry,cy,fold in rings:
        for i in range(segments):
            a=i*math.tau/segments;f=1+fold*math.cos(a*12+.2)+fold*.35*math.sin(a*19+z*15)
            points.append((math.sin(a)*rx*f,cy-math.cos(a)*ry*f,z))
    faces=[]
    for row in range(len(rings)-1):
        for i in range(segments):
            n=(i+1)%segments;faces.append((row*segments+i,row*segments+n,(row+1)*segments+n,(row+1)*segments+i))
    o=rigged_mesh(name,points,faces,mat)
    sub=o.modifiers.new('Sewn cloth curvature','SUBSURF');sub.levels=2
    solid=o.modifiers.new('Cloth thickness','SOLIDIFY');solid.thickness=.0025
    return o
# Tailored silhouette: shoulders, fitted waist and a flared, folded skirt.
# The adapted CC0 garment shell is fitted below after its correspondence data are loaded.
tube('Split tunic skirt',[(.631,.210,.145,-.020,.038),(.637,.210,.145,-.020,.038),(.68,.205,.145,-.020,.027),(.73,.185,.131,-.015,.017),(.79,.164,.112,-.006,.009),(.836,.151,.106,-.006,0)],cloth)
tube('Leather belt',[(.816,.152,.108,-.006,0),(.819,.155,.111,-.006,0),(.847,.155,.111,-.006,0),(.851,.152,.108,-.006,0)],leather)

def proxy(name,folder,stem,mat,min_height=None):
    path=REF/'makehuman-system'/folder;pv,pu,pf=obj_data(path/(stem+'.obj'))
    lines=(path/(stem+'.mhclo')).read_text().splitlines();scales=Vector((1,1,1));refs=[];reading=False
    for line in lines:
        a=line.split()
        if not a or a[0].startswith('#'):continue
        if a[0] in ['x_scale','y_scale','z_scale']:
            axis='xyz'.index(a[0][0]);scales[axis]=abs(raw[int(a[1])][axis]-raw[int(a[2])][axis])/float(a[3])
        elif a[0]=='verts':reading=True
        elif reading:
            try:
                if len(a)==1:refs.append(raw[int(a[0])].copy())
                elif len(a)==9:refs.append(sum((raw[int(a[j])]*float(a[3+j]) for j in range(3)),Vector())+Vector(tuple(float(a[6+j])*scales[j] for j in range(3))))
                else:break
            except ValueError:break
    assert len(refs)==len(pv),(name,len(refs),len(pv))
    points=[convert(v) for v in refs]
    if min_height is not None:pf=[(g,f) for g,f in pf if sum(points[i].z for i,_ in f)/len(f)>min_height]
    used=sorted({i for _,f in pf for i,_ in f});mapping={old:new for new,old in enumerate(used)}
    o=rigged_mesh(name,[points[i] for i in used],[[mapping[i] for i,_ in f] for _,f in pf],mat,face_uvs=[[pu[u] for _,u in f] for _,f in pf])
    if min_height is not None:
        o.modifiers.new('Tailored garment surface','SUBSURF').levels=2
        o.modifiers.new('Turned cloth thickness','SOLIDIFY').thickness=.002
    return o
proxy('Adapted CC0 tunic shoulder shell','clothes/male_casualsuit04','male_casualsuit04',cloth,.84)
proxy('Fitted blue eyes','eyes/high-poly','high-poly',eyes)
proxy('Fitted short hair','hair/short01','short01',hair)
# A sewn stocking cap bends rearward instead of ending in a straight cone.
cap_sections=[((0,0,1.342),.107,.099),((0,.0,1.350),.108,.100),((0,.018,1.401),.095,.086),((0,.061,1.420),.067,.060),((0,.125,1.409),.040,.035),((0,.181,1.370),.021,.019),((0,.205,1.321),.010,.009),((0,.209,1.295),.0005,.0005)]
cap_points=[]
for row,(center,rx,ry) in enumerate(cap_sections):
    center=Vector(center)
    if row==0:axis=Vector((0,0,1))
    else:axis=(Vector(cap_sections[min(row+1,len(cap_sections)-1)][0])-Vector(cap_sections[row-1][0])).normalized()
    across=Vector((1,0,0));depth=axis.cross(across).normalized()
    for i in range(64):
        a=i*math.tau/64;cap_points.append(center+across*(math.sin(a)*rx)+depth*(math.cos(a)*ry))
cap_faces=[(j*64+i,j*64+(i+1)%64,(j+1)*64+(i+1)%64,(j+1)*64+i) for j in range(len(cap_sections)-1) for i in range(64)]
cap=rigged_mesh('Bent sewn stocking cap',cap_points,cap_faces,cloth)
cap.modifiers.new('Soft cap folds','SUBSURF').levels=2
cap.modifiers.new('Wool thickness','SOLIDIFY').thickness=.002
cap.data.polygons.foreach_set('use_smooth',[True]*len(cap.data.polygons))
for v in cap.vertex_groups:v.remove(list(range(len(cap.data.vertices))))
cap.vertex_groups['head'].add(list(range(len(cap.data.vertices))),1,'REPLACE')
# Buckle and stitched trims are shaped curves with physical thickness.
def seam(name,coords,radius,mat):
    curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.bevel_depth=radius;curve.bevel_resolution=3
    spline=curve.splines.new('POLY');spline.points.add(len(coords)-1)
    for p,v in zip(spline.points,coords):p.co=(*v,1)
    o=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(o);o.data.materials.append(mat)
    bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False)
    for bone in weightdata:o.vertex_groups.new(name=bone)
    for vert in o.data.vertices:
        src=kd.find(vert.co)[1]
        for bone,w in weights[src].items():o.vertex_groups[bone].add([vert.index],w,'REPLACE')
    return o
seam('Brass buckle',[(x,-.121,z) for x,z in [(-.021,.819),(.021,.819),(.021,.851),(-.021,.851),(-.021,.819)]],.004,metal)
seam('Buckle tongue',[(0,-.124,.824),(0,-.124,.846)],.002,metal)
for z,rx,ry,cy in [(.646,.212,.145,-.020)]:
    seam('Bound garment edge',[(math.sin(i*math.tau/96)*rx,cy-math.cos(i*math.tau/96)*ry,z) for i in range(97)],.0016,edge)
for sign,label in [(-1,'R'),(1,'L')]:
    pts=[]
    last=[(.065,.002,.002,.043),(.055,.043,.043,.051),(.025,.048,.050,.055),(-.035,.052,.053,.058),(-.10,.060,.041,.047),(-.17,.061,.034,.041),(-.205,.044,.027,.035),(-.221,.002,.005,.03)]
    for y,rx,rz,z in last:
        for i in range(48):
            a=i*math.tau/48;pts.append((sign*.16+math.sin(a)*rx,y,z+math.cos(a)*rz))
    fs=[(j*48+i,j*48+(i+1)%48,(j+1)*48+(i+1)%48,(j+1)*48+i) for j in range(len(last)-1) for i in range(48)]
    boot=rigged_mesh('Leather shoe last '+label,pts,fs,leather)
    boot.modifiers.new('Rounded toe and heel','SUBSURF').levels=2
    shaft=tube('Boot shaft '+label,[(.070,.051,.057,-.018,0),(.10,.053,.061,-.022,.015),(.17,.061,.063,-.025,.018),(.27,.067,.067,-.030,.01),(.335,.074,.072,-.030,0),(.343,.075,.073,-.030,0)],leather)
    for vert in shaft.data.vertices:vert.co.x+=sign*(.16-(vert.co.z-.07)*.1)
    # Moving a generated garment requires reassigning its nearest anatomical weights.
    for group in shaft.vertex_groups:group.remove(list(range(len(shaft.data.vertices))))
    for vert in shaft.data.vertices:
        for bone,w in weights[kd.find(vert.co)[1]].items():shaft.vertex_groups[bone].add([vert.index],w,'REPLACE')
    sole_points=[]
    for z,multiplier in [(.003,.97),(.010,1.0),(.024,.98)]:
        for i in range(96):
            angle=i*math.tau/96
            width=.057+.006*max(0,-math.cos(angle))
            sole_points.append((sign*.16+math.sin(angle)*width*multiplier,-.079+math.cos(angle)*.145*multiplier,z))
    sole_faces=[tuple(reversed(range(96))),tuple(192+i for i in range(96))]
    sole_faces += [(j*96+i,j*96+(i+1)%96,(j+1)*96+(i+1)%96,(j+1)*96+i) for j in range(2) for i in range(96)]
    sole=rigged_mesh('Layered flat sole '+label,sole_points,sole_faces,outsole)
    for face in sole.data.polygons:face.use_smooth=len(face.vertices)==4
    bevel=sole.modifiers.new('Worn sole edge','BEVEL');bevel.width=.002;bevel.segments=3
    seam('Boot welt '+label,[(sign*.16+math.sin(i*math.tau/64)*.063,-.079+math.cos(i*math.tau/64)*.134,.017) for i in range(65)],.004,leather)
    # The opening has a rolled rim; a back joining seam and welt join the upper to the sole.
    seam('Rolled boot opening '+label,[(sign*.132+math.sin(i*math.tau/80)*.074,-.030+math.cos(i*math.tau/80)*.072,.338) for i in range(81)],.0025,leather)
    seam('Boot rear joining seam '+label,[(sign*(.16-(z-.07)*.1),.039,z) for z in [.085,.14,.20,.26,.33]],.0018,edge)


# Adult anatomy uses the pinned young-male morph, rather than uniform child scaling.
# The child-tailored cloth is refitted through the corresponding CC0 body cage.
# Every body vertex has the same source identity in the two age targets.
def age_fit(point):
    if not ADULT:return Vector(point)
    neighbours=child_cage.find_n(Vector(point),8)
    if neighbours[0][2]<1e-6:return Vector(point)+adult_vertices[neighbours[0][1]]-child_vertices[neighbours[0][1]]
    numerator=Vector();denominator=0
    for co,idx,distance in neighbours:
        w=1/max(distance,.001)**4
        numerator+=(adult_vertices[idx]-child_vertices[idx])*w;denominator+=w
    return Vector(point)+numerator/denominator
if ADULT:
    adult_raw=[v.copy() for v in neutral]
    for name in ['caucasian-male-young.target','universal-male-young-averagemuscle-averageweight.target']:
        for line in (REF/name).read_text().splitlines():
            a=line.split()
            if a and not a[0].startswith('#'):adult_raw[int(a[0])]+=Vector(tuple(map(float,a[1:4])))
    adult_base=min(adult_raw[i].y for i in used);adult_scale=1.73/(max(adult_raw[i].y for i in used)-adult_base)
    adult_vertices=[Vector((v.x*adult_scale,-v.z*adult_scale,(v.y-adult_base)*adult_scale)) for v in adult_raw]
    child_vertices=[v.copy() for v in vertices]
    child_cage=kdtree.KDTree(len(used))
    for i in used:
        child_cage.insert(child_vertices[i],i)
        # Preserve the authored ear extension in its corresponding adult helix.
        original=convert(raw[i]);extension=child_vertices[i]-original
        adult_vertices[i]+=extension
    child_cage.balance()
    for o in list(bpy.context.scene.objects):
        if o.type!='MESH':continue
        for v in o.data.vertices:v.co=age_fit(v.co)
    # The cap is tailored closer to the adult crown after the body-cage fit.
    # Keep the hanging tail, but seat the opening against the hairline.
    for v in cap.data.vertices:
        v.co.x*=.92;v.co.y-=.025;v.co.z-=.035
    vertices=adult_vertices
    print('Adult CC0 morphology fitted to 1.73 m; child garments refitted via body correspondence.')

# Load the CC0 anatomical rig and transfer weights to each independently authored garment.
arm=bpy.data.armatures.new('Anatomical skeleton');rig=bpy.data.objects.new('LinkRig',arm);bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig
rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for name,data in rigdata['bones'].items():
    bone=arm.edit_bones.new(name)
    for target in ['head','tail']:
        ids=rigdata['joints'][data[target]];setattr(bone,target,sum((vertices[i] for i in ids),Vector())/len(ids))
    if (bone.tail-bone.head).length<.0001:bone.tail.z+=.002
    bone.align_roll(Vector((0,-1,0)))
for name,data in rigdata['bones'].items():
    if data['parent']:arm.edit_bones[name].parent=arm.edit_bones[data['parent']]
bpy.ops.object.mode_set(mode='OBJECT')
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
for o in meshes:
    # Apply surface detail before skeletal deformation so both share one set of weights.
    bpy.context.view_layer.objects.active=o
    for mod in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=o.modifiers.new('Anatomical deformation','ARMATURE');mod.object=rig;o.parent=rig

def pose_world(name,rx=0,ry=0,rz=0):
    bone=rig.pose.bones[name];rest=bone.bone.matrix_local.to_3x3()
    rot=Matrix.Rotation(rx,3,'X')@Matrix.Rotation(ry,3,'Y')@Matrix.Rotation(rz,3,'Z')
    bone.rotation_mode='QUATERNION';bone.rotation_quaternion=(rest.inverted()@rot@rest).to_quaternion()
def reach_hand(label,target):
    # Analytic two-joint reach over the rig's paired upper/lower arm segments.
    upper=rig.pose.bones['upperarm01.'+label];lower=rig.pose.bones['lowerarm01.'+label]
    start=upper.bone.head_local;elbow=lower.bone.head_local;hand=rig.pose.bones['wrist.'+label].bone.head_local
    target=age_fit(target);line=target-start;distance=min(line.length,(elbow-start).length+(hand-elbow).length-.001);direction=line.normalized()
    l1=(elbow-start).length;l2=(hand-elbow).length
    reach=(l1*l1-l2*l2+distance*distance)/(2*distance)
    pole=Vector((1 if label=='L' else -1,.15,0));pole=(pole-direction*pole.dot(direction)).normalized()
    bent=start+direction*reach+pole*math.sqrt(max(0,l1*l1-reach*reach))
    q=(elbow-start).rotation_difference(bent-start)
    rest=upper.bone.matrix_local.to_3x3();upper.rotation_quaternion=(rest.inverted()@q.to_matrix()@rest).to_quaternion()
    correction=(q@(hand-elbow)).rotation_difference(target-bent)
    rest=lower.bone.matrix_local.to_3x3();lower.rotation_quaternion=(rest.inverted()@q.inverted().to_matrix()@correction.to_matrix()@q.to_matrix()@rest).to_quaternion()

# Resting arms follow the sides; a small elbow bend keeps hands clear of the tunic.
for label,sign in [('L',1),('R',-1)]:pose_world('upperarm01.'+label,0,sign*.43,0)
scene=bpy.context.scene;scene.render.fps=30
for clip,length in [('Idle',60),('Walk',30),('Swim',48),('Climb',40),('Carry',40),('CarryIdle',40),('Attack',16),('Shield',40),('Roll',30),('Shoot',30)]:
    rig.animation_data_create();action=bpy.data.actions.new(clip);rig.animation_data.action=action
    for frame in range(1,length+2,2):
        t=(frame-1)/length*math.tau
        for bone in rig.pose.bones:bone.rotation_mode='QUATERNION';bone.rotation_quaternion=(1,0,0,0)
        for label,sign in [('L',1),('R',-1)]:
            phase=t+(0 if sign==1 else math.pi);s=math.sin(phase)
            pose_world('upperarm01.'+label,(-s*.32 if clip=='Walk' else .015*math.sin(t)), sign*.43)
            if clip in ['Walk','Carry']:
                pose_world('upperleg01.'+label,s*.45)
                pose_world('lowerleg01.'+label,max(0,s)*.6)
                pose_world('foot.'+label,-s*.12)
            if clip=='Swim':
                pose_world('upperarm01.'+label,-1.8+math.cos(phase)*.85,-sign*(.2+.8*(1+math.sin(phase))*.5))
                pose_world('lowerarm01.'+label,-.25*(1+math.sin(phase)))
                pose_world('upperleg01.'+label,s*.22);pose_world('lowerleg01.'+label,max(0,s)*.3)
            if clip=='Climb':
                pose_world('upperarm01.'+label,-2.25+s*.4,-sign*.2)
                pose_world('upperleg01.'+label,-.5+s*.35);pose_world('lowerleg01.'+label,.9-s*.3)
            if clip in ['Carry','CarryIdle']:reach_hand(label,(sign*.14,-.18,1.39))
            if clip=='Attack' and label=='R':
                pose_world('upperarm01.R',-1.2*math.sin(min(math.pi,t*.5)),.35,math.sin(t)*.45)
                pose_world('lowerarm01.R',-.35)
            if clip=='Shield' and label=='L':
                pose_world('upperarm01.L',-.55,.20,-.30)
                pose_world('lowerarm01.L',-.60,0,-.20)
            if clip=='Shoot':
                reach_hand(label,(.17,-.36,1.04) if label=='L' else (-.08,-.08,1.20))
            if clip=='Roll':
                pose_world('upperleg01.'+label,-1.15)
                pose_world('lowerleg01.'+label,1.65)
                pose_world('upperarm01.'+label,-1.1,-sign*.15)
                pose_world('lowerarm01.'+label,-1.1)
            if clip in ['Attack','Shield','Shoot','Carry','CarryIdle','Climb']:
                # Fingers curl around the held grip or ledge, in their own bone axes.
                for finger in range(2,6):
                    for joint in range(1,4):
                        bone=rig.pose.bones[f'finger{finger}-{joint}.{label}']
                        bone.rotation_quaternion=Matrix.Rotation(.6 if joint>1 else .3,3,'X').to_quaternion()
        pose_world('spine02',.015*math.sin(t))
        for bone in rig.pose.bones:bone.keyframe_insert('rotation_quaternion',frame=frame,group=bone.name)
    track=rig.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,1,action);strip.action_frame_end=length+1;track.mute=True
rig.animation_data.action=bpy.data.actions['Idle'];scene.frame_set(1)
# Retain only the playable, clothed asset in the exported scene.
for o in scene.objects:o.select_set(o.type in ['MESH','ARMATURE'])
bpy.context.view_layer.objects.active=rig
for image in bpy.data.images:
    if image.source=='FILE':image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/('link-adult.blend' if ADULT else 'link-anatomical.blend')))
bpy.ops.export_scene.gltf(filepath=str(OUT/('link-adult.glb' if ADULT else 'link-anatomical.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_skins=True)
if '--no-render' in sys.argv:
    print('Saved character, rig and ten actions without study renders')
    sys.exit(0)
# Multi-angle, normally lit study renders. They are observations, not final acceptance.
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.world.color=(.3,.3,.3)
for at,power,size in [((2,-3,4),200,3),((-2,-1,2),90,2),((1,2,3),160,2)]:
    bpy.ops.object.light_add(type='AREA',location=at);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,.8))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera;camera.data.lens=65
scene.render.resolution_x=1000;scene.render.resolution_y=1300;scene.render.resolution_percentage=100
for label,at,look in [('front',(1.9,-3.3,1.65),(0,0,.76)),('back',(-1.9,3.3,1.65),(0,0,.76)),('face',(.6,-1.4,1.50),(0,-.01,1.23))]:
    camera.location=at;camera.rotation_euler=(Vector(look)-camera.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(OUT/(label+'.png'));bpy.ops.render.render(write_still=True)
print('Saved clothed model, rig, ten animation studies and editable source to',OUT)
