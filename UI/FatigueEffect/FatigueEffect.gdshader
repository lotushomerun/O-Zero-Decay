shader_type canvas_item;

uniform float effect_intensity : hint_range(0.0, 1.0) = 0.0;

// Maximum effect values
uniform float max_fisheye_strength : hint_range(0.0, 1.0) = 0.5;
uniform float max_sharpen_strength : hint_range(0.0, 3.0) = 1.0;
uniform float min_sharpen_radius : hint_range(0.001, 0.01) = 0.001;
uniform float max_sharpen_radius : hint_range(0.001, 0.01) = 0.004;

// Vignette
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.9; // max darkening
uniform float vignette_radius_min : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_radius_max : hint_range(0.0, 1.0) = 0.9;
uniform float vignette_softness : hint_range(0.01, 1.0) = 0.35;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	float fisheye_strength = max_fisheye_strength * effect_intensity;
	float sharpen_strength = max_sharpen_strength * effect_intensity;
	float sharpen_radius = mix(min_sharpen_radius, max_sharpen_radius, effect_intensity);

	// Fisheye
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float k = fisheye_strength;
	float distorted_r = r + (r - r*r) * k; // inverted fisheye

	vec2 distorted_uv = uv * (distorted_r / max(r, 0.0001));
	distorted_uv = distorted_uv * 0.5 + 0.5;

	if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 ||
	    distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
	    COLOR = vec4(0.0);
	    discard;
	}

	// Sharpen
	vec2 step = vec2(sharpen_radius);
	vec4 color = texture(SCREEN_TEXTURE, distorted_uv);

	vec4 blur =
	    texture(SCREEN_TEXTURE, distorted_uv + vec2(step.x, 0.0)) +
	    texture(SCREEN_TEXTURE, distorted_uv + vec2(-step.x, 0.0)) +
	    texture(SCREEN_TEXTURE, distorted_uv + vec2(0.0, step.y)) +
	    texture(SCREEN_TEXTURE, distorted_uv + vec2(0.0, -step.y));

	blur *= 0.25;
	vec4 sharp = color + (color - blur) * sharpen_strength;

	// Vignette
	float d = distance(distorted_uv, vec2(0.5));
	float vignette_radius = mix(vignette_radius_max, vignette_radius_min, effect_intensity);
	float v = smoothstep(vignette_radius, vignette_radius + vignette_softness, d);
	v *= vignette_strength * effect_intensity;
	sharp.rgb *= (1.0 - v);

	COLOR = sharp;
}
