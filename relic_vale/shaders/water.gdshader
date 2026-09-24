shader_type spatial;
render_mode cull_disabled;
varying vec3 world_pos;
global uniform vec3 vale_origin;
global uniform float vale_quality;
global uniform float vale_wetness;
varying float depth;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz+vale_origin; depth=COLOR.r; }
void fragment() {
	vec2 p=world_pos.xz*.00613592315;
	float ripples=sin(p.x*624.0+TIME*.65+sin(p.y*320.0))*sin(p.y*816.0-TIME*.45);
	float broad=sin(p.x*80.0+TIME*.25)*cos(p.y*96.0-TIME*.2);
	float light_band=smoothstep(.79,.97,ripples);
	vec3 deep=mix(vec3(.12,.31,.34),vec3(.24,.46,.44),broad*.12+.5);
	ALBEDO=mix(vec3(.40,.55,.44),deep,smoothstep(.0,.8,depth));
	ALBEDO+=light_band*.055*min(vale_quality,1.0);
	if(vale_quality>1.5){
	 float shore=(1.0-smoothstep(.0,.25,depth))*smoothstep(-.15,.5,ripples);
	 ALBEDO=mix(ALBEDO,vec3(.70,.75,.61),shore*.34);
	 NORMAL=normalize(NORMAL+vec3(cos(p.x*624.0+TIME*.65)*.08,0.0,sin(p.y*816.0-TIME*.45)*.08));
	 ALBEDO+=vale_wetness*pow(max(0.0,ripples),18.0)*.09;
	}
	ROUGHNESS=vale_quality<1.0 ? .65 : .28;
	METALLIC=.08;
}
