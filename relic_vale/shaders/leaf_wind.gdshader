shader_type spatial;
render_mode cull_disabled;
global uniform vec3 vale_origin;
global uniform float vale_wind;
global uniform float vale_wetness;
uniform vec4 leaf_color : source_color=vec4(.4,.55,.36,1.0);
varying float variation;
void vertex() {
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz+vale_origin;
 float gust=sin(TIME*1.1+p.x*.09817477+p.z*.04908738);
 VERTEX.x+=gust*.024*vale_wind;
 VERTEX.z+=cos(TIME*.8+p.z*.09817477)*.016*vale_wind;
 variation=gust*.025;
}
void fragment(){ ALBEDO=leaf_color.rgb*(1.0+variation-vale_wetness*.12); ROUGHNESS=.87; }
