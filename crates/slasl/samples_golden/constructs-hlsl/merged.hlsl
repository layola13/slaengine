// SLASL merged output (HLSL)

cbuffer Scene : register(b0)
{
    float3 light_dir;
    float3 light_color;
    float3 cam_pos;
};

cbuffer Params : register(b1)
{
    float4 base_color;
    float metallic;
    float roughness;
};

struct VSIn
{
    float3 position : POSITION;
    float3 normal : NORMAL;
};

struct VSOut
{
    float4 position : SV_Position;
    float3 v_normal : TEXCOORD0;
    float3 v_world : TEXCOORD1;
};
float3 slasl_principled(float3 base_color, float metallic, float roughness, float3 normal, float3 view_dir, float3 light_dir, float3 light_color)
{
    float3 n = normalize(normal);
    float3 v = normalize(view_dir);
    float3 l = normalize(light_dir);
    float3 h = normalize(l + v);
    float ndv = max(dot(n, v), 0.0001);
    float ndl = max(dot(n, l), 0.0);
    float ndh = max(dot(n, h), 0.0);
    float vdh = max(dot(v, h), 0.0);
    float a = max(roughness * roughness, 0.0001);
    float a2 = a * a;
    float denom = ndh * ndh * (a2 - 1.0) + 1.0;
    float nd = a2 / (3.14159265 * denom * denom);
    float3 f0 = lerp(float3(0.04, 0.04, 0.04), base_color, metallic);
    float3 f = f0 + (float3(1.0, 1.0, 1.0) - f0) * pow(1.0 - vdh, 5.0);
    float k = (roughness + 1.0) * (roughness + 1.0) / 8.0;
    float gv = ndv / (ndv * (1.0 - k) + k);
    float gl = ndl / (ndl * (1.0 - k) + k);
    float3 spec = nd * f * (gv * gl) / max(4.0 * ndv * ndl, 0.0001);
    float3 diffuse = base_color * (1.0 - metallic) / 3.14159265;
    return (diffuse + spec) * light_color * ndl;
}


VSOut VSMain(VSIn input)
{
    VSOut output;
    output.v_normal = input.normal;
    output.v_world = input.position;
    output.position = float4(input.position, 1.0);
    return output;
}

float4 PSMain(VSOut input) : SV_Target
{
    float4 frag_color;
    frag_color = float4(lerp(slasl_principled(base_color.rgb, metallic, roughness, input.v_normal, (cam_pos - input.v_world), light_dir, light_color), base_color.rgb, clamp(pow(max(dot(input.v_normal, light_dir), 0.0), 2.0), 0.0, 1.0)), base_color.a);
    return frag_color;
}
