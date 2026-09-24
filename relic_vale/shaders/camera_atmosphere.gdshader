shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled;

uniform sampler2D scene_color : hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec3 focus_position;
uniform vec4 horizon_color : source_color = vec4(.59,.72,.67,1.0);
uniform vec4 zenith_color : source_color = vec4(.42,.62,.73,1.0);
uniform float fog_end = 56.0;
uniform float fog_start = 24.0;
uniform bool outdoors = true;
uniform float focus_distance = 26.0;
uniform float blur_strength = 1.0;

void vertex() { POSITION=vec4(VERTEX.xy,1.0,1.0); }

void fragment() {
 float depth=texture(scene_depth,SCREEN_UV).r;
 #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
 vec3 ndc=vec3(SCREEN_UV,depth)*2.0-1.0;
 #else
 vec3 ndc=vec3(SCREEN_UV*2.0-1.0,depth);
 #endif
 vec4 view=INV_PROJECTION_MATRIX*vec4(ndc,1.0);
 view.xyz/=view.w;
 vec3 world=(INV_VIEW_MATRIX*vec4(view.xyz,1.0)).xyz;
 vec3 direction=normalize((INV_VIEW_MATRIX*vec4(view.xyz,0.0)).xyz);
 vec3 sky=mix(horizon_color.rgb,zenith_color.rgb,smoothstep(.01,.65,direction.y));
 vec3 color=texture(scene_color,SCREEN_UV).rgb;
 float near_blur=(1.0-smoothstep(focus_distance*.20,focus_distance*.68,-view.z))*blur_strength;
 if(near_blur>.015) {
  // Small Gaussian kernel. Only foreground pixels are mixed, keeping the focus
  // plane and the separate HUD sharp even on OpenGL Compatibility.
  vec2 step_uv=vec2(1.0)/VIEWPORT_SIZE*(near_blur*2.5);
  vec3 soft=vec3(0.0);
  for(int x=-2;x<=2;x++) {
   float wx=x==0 ? 6.0 : (abs(x)==1 ? 4.0 : 1.0);
   for(int y=-2;y<=2;y++) {
    float wy=y==0 ? 6.0 : (abs(y)==1 ? 4.0 : 1.0);
    soft+=texture(scene_color,SCREEN_UV+vec2(float(x),float(y))*step_uv).rgb*wx*wy;
   }
  }
  color=mix(color,soft/256.0,near_blur);
 }
 if(outdoors) {
  // Radius is measured from the traveler to the nearest missing chunk, not
  // from the camera. Fully fogged geometry matches the sky at the same pixel.
  float haze=smoothstep(fog_start,fog_end,length(world.xz-focus_position.xz));
  if(depth<.000001) haze=1.0;
  color=mix(color,sky,haze);
 }
 ALBEDO=color;
 ALPHA=1.0;
}
