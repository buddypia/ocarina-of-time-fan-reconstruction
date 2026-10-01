shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;
uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec3 absorption = vec3(0.115, 0.035, 0.022);
varying vec3 water_world;
void vertex() {
	water_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	vec2 p=water_world.xz;
	float a=dot(p,vec2(.9,.35))*2.1+TIME*.8;
	float b=dot(p,vec2(-.4,.8))*3.8-TIME*.65;
	VERTEX.y+=sin(a)*.018+sin(b)*.009;
	NORMAL=normalize(vec3(-cos(a)*.034+cos(b)*.014,1.0,-cos(a)*.013-cos(b)*.027));
}
void fragment() {
	vec2 p=water_world.xz;
	float a=dot(p,vec2(.9,.35))*2.1+TIME*.8;
	float b=dot(p,vec2(-.4,.8))*3.8-TIME*.65;
	float c=dot(p,vec2(.7,-.65))*15.0+TIME*1.4;
	vec3 ripple=normalize(vec3(-cos(a)*.034+cos(b)*.014-cos(c)*.008,1.0,-cos(a)*.013-cos(b)*.027+cos(c)*.007));
	NORMAL=normalize((VIEW_MATRIX*vec4(ripple,0.0)).xyz);

	float depth=texture(scene_depth,SCREEN_UV).r;
	vec3 ndc=vec3(SCREEN_UV*2.0-1.0,depth);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	ndc.z=depth*2.0-1.0;
#endif
	vec4 floor_view=INV_PROJECTION_MATRIX*vec4(ndc,1.0);
	floor_view.xyz/=floor_view.w;
	float thickness=max(0.0,-floor_view.z+VERTEX.z);
	vec3 transmittance=exp(-absorption*min(thickness,18.0));
	vec2 shift=NORMAL.xy*.012*clamp(thickness*.5,0.0,1.0);
	vec3 under=textureLod(scene_color,SCREEN_UV+shift,.0).rgb;
	float fresnel=.0204+.9796*pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),5.0);
	vec3 scatter=vec3(.005,.032,.029)*(vec3(1.0)-transmittance);
	ALBEDO=scatter*.25;
	EMISSION=under*transmittance*(1.0-fresnel)+scatter*.24;
	METALLIC=0.0;
	ROUGHNESS=.075;
	SPECULAR=.5;
	ALPHA=1.0;
}
