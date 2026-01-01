shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.1, 0.2, 0.4, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform vec4 time_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float horizon_glow = 0.4;
uniform float vignette_strength = 0.25;
uniform float gradient_curve = 1.2;

void fragment() {
	vec2 uv = UV;
	
	float t = pow(uv.y, gradient_curve);
	vec4 sky_color = mix(top_color, bottom_color, t);
	
	float glow = exp(-abs(uv.y - 0.0) * (5.0 - horizon_glow * 4.0));
	sky_color.rgb += glow * horizon_glow;
	
	float dist = distance(uv, vec2(0.5, 0.5));
	float vign = smoothstep(0.9, 0.3, dist);
	sky_color.rgb *= mix(1.0, vign, vignette_strength);
	sky_color.rgb *= time_tint.rgb;
	
	COLOR = sky_color;
}
