shader_type spatial;
render_mode cull_disabled;
uniform sampler2D blade_texture : source_color, filter_linear_mipmap;
global uniform vec3 vale_origin;
global uniform vec3 vale_player;
global uniform float vale_wind;
global uniform float vale_wetness;
varying vec3 tint;
void vertex() {
 vec3 world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 float bend = max(VERTEX.y,0.0);
 vec3 p=world+vale_origin;
 VERTEX.x += sin(TIME*1.4 + p.x*.6872234 + p.z*.3436117)*bend*.075*vale_wind;
 VERTEX.z += cos(TIME*1.1 + p.x*.3926991)*bend*.04*vale_wind;
 vec2 away=world.xz-vale_player.xz;
 float nearby=1.0-smoothstep(.1,1.2,length(away));
 VERTEX.xz+=normalize(away+vec2(.001))*nearby*bend*.16;
 tint = INSTANCE_CUSTOM.rgb;
}
void fragment() {
 vec4 blade = texture(blade_texture,UV);
 ALBEDO = blade.rgb * tint*(1.0-vale_wetness*.12);
 ALPHA = blade.a;
 ALPHA_SCISSOR_THRESHOLD = .45;
 ROUGHNESS = 1.0;
}
