shader_type canvas_item;
void fragment() {
	vec2 uv = UV*2.0-1.0;
	float edge = smoothstep(.38,1.4,length(uv*vec2(.72,1.0)));
	COLOR = vec4(.04,.09,.10,edge*.23);
}
