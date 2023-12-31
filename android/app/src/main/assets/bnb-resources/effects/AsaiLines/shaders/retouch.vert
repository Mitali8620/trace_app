#include <bnb/glsl.vert>
#include <bnb/decode_int1010102.glsl>
#include<bnb/matrix_operations.glsl>
#define bnb_IDX_OFFSET 0
#ifdef BNB_VK_1
#ifdef gl_VertexID
#undef gl_VertexID
#endif
#ifdef gl_InstanceID
#undef gl_InstanceID
#endif
#define gl_VertexID gl_VertexIndex
#define gl_InstanceID gl_InstanceIndex
#endif

BNB_LAYOUT_LOCATION(0) BNB_IN vec3 attrib_pos;
BNB_LAYOUT_LOCATION(1) BNB_IN vec3 attrib_pos_static;
BNB_LAYOUT_LOCATION(2) BNB_IN vec2 attrib_uv;
BNB_LAYOUT_LOCATION(3) BNB_IN vec4 attrib_red_mask;


BNB_OUT(0) vec2 var_uv;
BNB_OUT(1) vec2 var_bg_uv;

BNB_OUT(2) mat4 sp;

invariant gl_Position;

const float dx = 1.0 / 960.0;
const float dy = 1.0 / 1280.0;

const float delta = 5.;

const float sOfssetXneg = -delta * dx;
const float sOffsetYneg = -delta * dy;
const float sOffsetXpos = delta * dx;
const float sOffsetYpos = delta * dy;

void main()
{
    gl_Position = bnb_MVP * vec4( attrib_pos, 1. );
    var_uv = attrib_uv;
    var_bg_uv  = (gl_Position.xy / gl_Position.w) * 0.5 + 0.5;
    
    sp[0].xy = var_bg_uv + vec2(sOfssetXneg, sOffsetYneg);
    sp[1].xy = var_bg_uv + vec2(sOfssetXneg, sOffsetYpos);
    sp[2].xy = var_bg_uv + vec2(sOffsetXpos, sOffsetYneg);
    sp[3].xy = var_bg_uv + vec2(sOffsetXpos, sOffsetYpos);
    
    vec2 delta = vec2(dx, dy);
    sp[0].zw = var_bg_uv + vec2(-delta.x, -delta.y);
    sp[1].zw = var_bg_uv + vec2(delta.x, -delta.y);
    sp[2].zw = var_bg_uv + vec2(-delta.x, delta.y);
    sp[3].zw = var_bg_uv + vec2(delta.x, delta.y);

#ifdef BNB_VK_1
    sp[0].y = 1. - sp[0].y;
    sp[1].y = 1. - sp[1].y;
    sp[2].y = 1. - sp[2].y;
    sp[3].y = 1. - sp[3].y;
    sp[0].w = 1. - sp[0].w;
    sp[1].w = 1. - sp[1].w;
    sp[2].w = 1. - sp[2].w;
    sp[3].w = 1. - sp[3].w;
#endif
#ifdef BNB_VK_1
var_bg_uv.y = 1. - var_bg_uv.y;
#endif
}
