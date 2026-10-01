shader_type spatial;
uniform sampler2D crust : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D relief : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap, repeat_enable;
uniform sampler2D heat : filter_linear_mipmap, repeat_enable;
uniform float clock = 0.0;
varying vec3 local_position;
void vertex() {
 local_position=VERTEX;
 VERTEX.y+=.018*sin(VERTEX.x*.6+clock*.3)*cos(VERTEX.z*.7-clock*.2);
}
void fragment() {
 vec2 uv=local_position.xz*.085+vec2(clock*.0008,clock*.0003);
 ALBEDO=texture(crust,uv).rgb;
 NORMAL_MAP=texture(relief,uv).rgb;
 NORMAL_MAP_DEPTH=.30;
 ROUGHNESS=texture(roughness_map,uv).r;
 float seam=texture(heat,uv).r;
 EMISSION=mix(vec3(1.0,.018,.001),vec3(1.0,.18,.015),seam)*pow(seam,1.8)*(.90+.12*sin(clock*.65));
}
