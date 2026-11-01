/* SLASL merged output (Blender convention). No #version: the host injects it. */

layout(std140) uniform Scene
{
    vec3 light_dir;
    vec3 light_color;
    vec3 cam_pos;
};

layout(std140) uniform Params
{
    vec4 base_color;
    float metallic;
    float roughness;
};

vec3 slasl_principled(vec3 base_color, float metallic, float roughness, vec3 normal, vec3 view_dir, vec3 light_dir, vec3 light_color)
{
    vec3 n = normalize(normal);
    vec3 v = normalize(view_dir);
    vec3 l = normalize(light_dir);
    vec3 h = normalize(l + v);
    float ndv = max(dot(n, v), 0.0001);
    float ndl = max(dot(n, l), 0.0);
    float ndh = max(dot(n, h), 0.0);
    float vdh = max(dot(v, h), 0.0);
    float a = max(roughness * roughness, 0.0001);
    float a2 = a * a;
    float denom = ndh * ndh * (a2 - 1.0) + 1.0;
    float nd = a2 / (3.14159265 * denom * denom);
    vec3 f0 = mix(vec3(0.04, 0.04, 0.04), base_color, metallic);
    vec3 f = f0 + (vec3(1.0, 1.0, 1.0) - f0) * pow(1.0 - vdh, 5.0);
    float k = (roughness + 1.0) * (roughness + 1.0) / 8.0;
    float gv = ndv / (ndv * (1.0 - k) + k);
    float gl = ndl / (ndl * (1.0 - k) + k);
    vec3 spec = nd * f * (gv * gl) / max(4.0 * ndv * ndl, 0.0001);
    vec3 diffuse = base_color * (1.0 - metallic) / 3.14159265;
    return (diffuse + spec) * light_color * ndl;
}

vec3 slasl_agx(vec3 color)
{
    vec3 c = max(color, vec3(0.0001, 0.0001, 0.0001));
    vec3 x = clamp((log2(c) + 6.0) / 12.0, 0.0, 1.0);
    vec3 xp = pow(x, vec3(2.4, 2.4, 2.4));
    vec3 nxp = pow(vec3(1.0, 1.0, 1.0) - x, vec3(2.4, 2.4, 2.4));
    vec3 y = xp / (xp + nxp);
    float lum = dot(y, vec3(0.2126, 0.7152, 0.0722));
    vec3 outc = mix(vec3(lum, lum, lum), y, 1.0 - 0.4 * lum * lum);
    return clamp(outc, 0.0, 1.0);
}

#ifdef GPU_VERTEX_SHADER
layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;

out StageInterface
{
    vec3 v_normal;
    vec3 v_world;
} stage_out;

void main()
{
    stage_out.v_normal = normal;
    stage_out.v_world = position;
    gl_Position = vec4(position, 1.0);
}
#endif

#ifdef GPU_FRAGMENT_SHADER
in StageInterface
{
    vec3 v_normal;
    vec3 v_world;
} stage_in;

layout(location = 0) out vec4 frag_color;

void main()
{
    frag_color = vec4(slasl_agx(slasl_principled(base_color.rgb, metallic, roughness, stage_in.v_normal, (cam_pos - stage_in.v_world), light_dir, light_color)), base_color.a);
}
#endif
