/* SLASL merged output (Blender convention). No #version: the host injects it. */

layout(std140) uniform Camera
{
    mat4 view_proj;
};

layout(std140) uniform Params
{
    vec4 base_color;
    vec4 tint;
};

uniform sampler2D tex;

#ifdef GPU_VERTEX_SHADER
layout(location = 0) in vec3 position;
layout(location = 1) in vec2 uv;

out StageInterface
{
    vec2 v_uv;
} stage_out;

void main()
{
    stage_out.v_uv = uv;
    gl_Position = (view_proj * vec4(position, 1.0));
}
#endif

#ifdef GPU_FRAGMENT_SHADER
in StageInterface
{
    vec2 v_uv;
} stage_in;

layout(location = 0) out vec4 frag_color;

void main()
{
    vec4 tint_boost;
    vec4 tint_pre;
    tint_boost = (tint * 0.5);
    tint_pre = (tint_boost + tint);
    frag_color = (texture(tex, stage_in.v_uv) * base_color);
    frag_color = (frag_color * tint_pre);
}
#endif
