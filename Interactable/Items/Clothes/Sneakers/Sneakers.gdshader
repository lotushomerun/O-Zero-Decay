shader_type canvas_item;

uniform bool is_front = true;

uniform vec4 base_color1 : source_color;
uniform vec4 target_color1 : source_color;

uniform vec4 base_color2 : source_color;
uniform vec4 target_color2 : source_color;

uniform vec4 base_color3 : source_color;
uniform vec4 target_color3 : source_color;

// Wetness
uniform float wetness : hint_range(0.0, 1.0) = 0.0; // Wetness level 0–1
const float MIN_ALPHA = 0.77; // Minimum alpha at max wetness

// Dirt overlay
uniform sampler2D dirt_mask : source_color;
uniform sampler2D dirt_texture : source_color;
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.0; // 0 = clean, 1 = fully dirty

const float TOLERANCE = 1.0;

vec3 rgb_to_hsv(vec3 c) {
	float max_c = max(max(c.r, c.g), c.b);
	float min_c = min(min(c.r, c.g), c.b);
	float delta = max_c - min_c;

	float h = 0.0;
	if (delta > 0.0) {
	    if (max_c == c.r) h = mod((c.g - c.b) / delta, 6.0);
	    else if (max_c == c.g) h = (c.b - c.r) / delta + 2.0;
	    else h = (c.r - c.g) / delta + 4.0;
	    h *= 60.0;
	}

	float s = (max_c == 0.0) ? 0.0 : delta / max_c;
	float v = max_c;
	return vec3(h, s, v);
}

vec3 hsv_to_rgb(vec3 c) {
	float h = c.x / 60.0;
	float s = c.y;
	float v = c.z;

	float c_val = v * s;
	float x = c_val * (1.0 - abs(mod(h, 2.0) - 1.0));
	float m = v - c_val;

	vec3 rgb;

	if (0.0 <= h && h < 1.0) rgb = vec3(c_val, x, 0.0);
	else if (1.0 <= h && h < 2.0) rgb = vec3(x, c_val, 0.0);
	else if (2.0 <= h && h < 3.0) rgb = vec3(0.0, c_val, x);
	else if (3.0 <= h && h < 4.0) rgb = vec3(0.0, x, c_val);
	else if (4.0 <= h && h < 5.0) rgb = vec3(x, 0.0, c_val);
	else rgb = vec3(c_val, 0.0, x);

	return rgb + m;
}

vec3 replace_color(vec3 tex_rgb, vec4 base_color, vec4 target_color) {
	vec3 hsv = rgb_to_hsv(tex_rgb);
	vec3 base_hsv = rgb_to_hsv(base_color.rgb);
	vec3 target_hsv = rgb_to_hsv(target_color.rgb);
	
	float diff = distance(base_hsv, hsv);
	
	if (diff < TOLERANCE) {
	    bool target_is_grey = target_hsv.y < 0.05;
	    if (!target_is_grey) { hsv.x = target_hsv.x; }
	    hsv.z *= target_hsv.z / max(base_hsv.z, 0.001);
	    if (target_is_grey) { hsv.y = 0.0; }
	    return hsv_to_rgb(hsv);
	}
	return tex_rgb;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	tex_color.rgb = replace_color(tex_color.rgb, base_color1, target_color1);
	tex_color.rgb = replace_color(tex_color.rgb, base_color2, target_color2);
	tex_color.rgb = replace_color(tex_color.rgb, base_color3, target_color3);
	
	// Wetness effects: transparency and darkening
	float alpha_factor = mix(1.0, MIN_ALPHA, wetness);
	tex_color.a *= alpha_factor;

	float darkness_factor = mix(1.0, 0.4, wetness); // Darken based on wetness
	tex_color.rgb *= darkness_factor;
	
	// Dirty overlay
	if (dirt_amount > 0.0) {
		vec4 dirt_col = texture(dirt_texture, UV);
		float noise = texture(dirt_mask, UV).r;
		float threshold = 1.2 - dirt_amount;
		float fade = 0.25;
		float dirt_factor = smoothstep(threshold - fade, threshold + fade, noise);
		dirt_col.a = dirt_factor * dirt_amount * tex_color.a;
		tex_color.rgb = mix(tex_color.rgb, dirt_col.rgb, dirt_col.a);
	}
	
	if (!is_front) { tex_color.rgb *= 0.66; }
	COLOR = tex_color;
}
