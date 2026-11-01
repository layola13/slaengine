// SLASL merged output (HLSL)

cbuffer Camera : register(b0)
{
    float4x4 view_proj;
};

cbuffer Params : register(b1)
{
    float4 base_color;
    float4 tint;
};

Texture2D tex : register(t0);
SamplerState tex_sampler : register(s0);

struct VSIn
{
    float3 position : POSITION;
    float2 uv : TEXCOORD0;
};

struct VSOut
{
    float4 position : SV_Position;
    float2 v_uv : TEXCOORD0;
};

VSOut VSMain(VSIn input)
{
    VSOut output;
    output.v_uv = input.uv;
    output.position = mul(view_proj, float4(input.position, 1.0));
    return output;
}

float4 PSMain(VSOut input) : SV_Target
{
    float4 tint_boost;
    float4 tint_pre;
    float4 frag_color;
    tint_boost = (tint * 0.5);
    tint_pre = (tint_boost + tint);
    frag_color = (tex.Sample(tex_sampler, input.v_uv) * base_color);
    frag_color = (frag_color * tint_pre);
    return frag_color;
}
