shader_type spatial;
global uniform vec3 vale_origin;
global uniform float vale_wetness;
global uniform float vale_quality;
varying vec3 ground;
varying vec4 terrain_color;
void vertex() { ground=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz+vale_origin; terrain_color=COLOR; }
void fragment() {
 vec2 p=ground.xz*0.00613592315;
 float macro=sin(p.x*24.0+sin(p.y*16.0))*cos(p.y*32.0);
 float grain=sin(p.x*2304.0)*sin(p.y*2048.0+cos(p.x*256.0));
 float slope=1.0-clamp(NORMAL.y,0.0,1.0);
 ALBEDO=terrain_color.rgb*(0.97+macro*0.075+grain*0.026*min(vale_quality,1.0));
 ALBEDO=mix(ALBEDO,ALBEDO*vec3(.81,.86,.83),vale_wetness*.65);
 ROUGHNESS=mix(.94,.58,vale_wetness);
 SPECULAR=.25;
}
