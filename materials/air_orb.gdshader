shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_alpha_prepass;

uniform vec4 glow_color : source_color = vec4(0.4, 0.8, 1.0, 0.7);
uniform float fresnel_power = 2.4;
uniform float noise_scale = 2.0;
uniform float noise_speed = 0.8;

float hash(vec3 p){ return fract(sin(dot(p, vec3(27.1,61.7,12.4))) * 43758.5453); }

void fragment() {
	float fresnel = pow(1.0 - dot(normalize(NORMAL), normalize(VIEW)), fresnel_power);
	float n = hash(vec3(UV * noise_scale, TIME * noise_speed));
	ALBEDO = glow_color.rgb * (0.3 + fresnel * 0.7);
	EMISSION = glow_color.rgb * (fresnel + n * 0.4) * 1.8;
	ALPHA = clamp(0.2 + fresnel * 0.6 + n * 0.15, 0.0, 0.95);
}
