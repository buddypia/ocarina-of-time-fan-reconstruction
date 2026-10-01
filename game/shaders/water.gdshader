shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled;
uniform vec4 water_color : source_color = vec4(0.16,0.44,0.48,0.40);
varying vec3 surface_position;
void vertex() {
	surface_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	vec2 p=surface_position.xz;
	float wave=sin(p.x*2.8+p.y*1.1+TIME*1.3)*sin(p.y*3.1-p.x*.6-TIME*.9);
	float glint=smoothstep(.82,.99,wave);
	ALBEDO=water_color.rgb+vec3(.13,.20,.17)*glint;
	ROUGHNESS=.34;
	METALLIC=.15;
	ALPHA=water_color.a;
	NORMAL=normalize(NORMAL+vec3(sin(p.x*3.0+TIME)*.035,0.0,cos(p.y*2.3-TIME)*.035));
}
