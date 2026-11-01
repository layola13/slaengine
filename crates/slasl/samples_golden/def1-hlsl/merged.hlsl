// SLASL merged output (HLSL)

cbuffer Params : register(b0)
{
    float4 tint2;
};

struct VSIn
{
    float3 position : POSITION;
};

struct VSOut
{
    float4 position : SV_Position;
    float v_s : TEXCOORD0;
    float v_t : TEXCOORD1;
};

VSOut VSMain(VSIn input)
{
    VSOut output;
    output.v_s = 2.0;
    output.v_t = (2.0 * 3.0);
    output.position = float4((input.position * 2.0), 1.0);
    return output;
}

float4 PSMain(VSOut input) : SV_Target
{
    float4 frag_color;
    frag_color = (tint2 * (input.v_s + input.v_t));
    return frag_color;
}
