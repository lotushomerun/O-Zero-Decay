shader_type canvas_item;

// Color replacement
uniform bool is_front = true;
uniform float skin_tone : hint_range(0.0, 100.0) = 0.0;
const vec3 BROWN_SKIN = vec3(0.45, 0.37, 0.35);

// Dirt
uniform sampler2D dirt_mask : source_color;
uniform sampler2D dirt_texture : source_color;
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.0;
uniform float dirt_max_alpha : hint_range(0.0, 1.0) = 0.5;

vec3 apply_skin_tone(vec3 color, float tone)
{
	float t = tone / 100.0;
	vec3 mul_color = mix(vec3(1.0), BROWN_SKIN, t);
	return color * mul_color;
}

void fragment()
{
	vec4 tex_color = texture(TEXTURE, UV);
	if (skin_tone > 0.0) tex_color.rgb = apply_skin_tone(tex_color.rgb, skin_tone);

	// Dirt
	if (dirt_amount > 0.0)
	{
		vec4 dirt_col = texture(dirt_texture, UV);
		float noise = texture(dirt_mask, UV).r;
		float threshold = 0.5 - dirt_amount / 6.66;
		float fade = 0.25;
		float dirt_factor = smoothstep(threshold - fade, threshold + fade, noise);
		dirt_col.a = dirt_factor * dirt_amount * dirt_max_alpha;
		tex_color.rgb = mix(tex_color.rgb, dirt_col.rgb, dirt_col.a);
	}

	if (!is_front) { tex_color.rgb *= 0.66; }
	COLOR = tex_color;
}
