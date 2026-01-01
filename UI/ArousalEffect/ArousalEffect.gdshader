shader_type canvas_item;

uniform float effect_intensity : hint_range(0.0, 1.0) = 1.0;
uniform float radius : hint_range(0.0, 1.0) = 0.75;
uniform float softness : hint_range(0.01, 1.0) = 0.35;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec2 uv = UV;
    float d = distance(uv, vec2(0.5));

    float v = smoothstep(radius, radius + softness, d);
    v *= effect_intensity;

    COLOR = vec4(vignette_color.rgb, vignette_color.a * v);
}