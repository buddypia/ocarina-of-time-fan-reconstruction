shader_type spatial;
render_mode cull_disabled;
uniform vec4 tissue:source_color=vec4(.46,.24,.25,1.);
uniform float wetness=.46;
uniform float pulse=0.;
varying vec3 local;
float hash(vec3 p){p=fract(p*.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z);}
float noise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){local=VERTEX;}
void fragment(){
 float broad=noise3(local*1.3),detail=noise3(local*28.);
 float vein=pow(1.-abs(sin(local.y*3.1+local.x*.7+noise3(local*1.9)*6.)),24.);
 ALBEDO=tissue.rgb*(.78+broad*.36+detail*.08)*(1.-vein*.20);
 ROUGHNESS=clamp(wetness+detail*.12-broad*.1,.16,.7);
 SPECULAR=.48;
 NORMAL_MAP=normalize(vec3(dFdx(broad)*.015,dFdy(broad)*.015,1.))*.5+.5;
 EMISSION=tissue.rgb*.015*(1.+sin(pulse)*.2);
}
