/* SLASL merged output (Blender convention). No #version: the host injects it. */

layout(std140) uniform Params
{
    vec4 tint2;
};

#ifdef GPU_VERTEX_SHADER
layout(location = 0) in vec3 position;

out StageInterface
{
    float v_s;
    float v_t;
} stage_out;

void main()
{
    stage_out.v_s = 2.0;
    stage_out.v_t = (2.0 * 3.0);
    gl_Position = vec4((position * 2.0), 1.0);
}
#endif

#ifdef GPU_FRAGMENT_SHADER
in StageInterface
{
    float v_s;
    float v_t;
} stage_in;

layout(location = 0) out vec4 frag_color;

void main()
{
    frag_color = (tint2 * (stage_in.v_s + stage_in.v_t));
}
#endif
