Shader "SLASL/Merged"
{
    Properties
    {
        base_color ("base_color", Color) = (1, 1, 1, 1)
        tex ("tex", 2D) = "white" {}
        tint ("tint", Color) = (1, 1, 1, 1)
    }
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)
    float4 base_color;
    float4 tint;
    CBUFFER_END

    cbuffer Camera
    {
        float4x4 view_proj;
    };

    TEXTURE2D(tex);
    SAMPLER(samplertex);

    struct Attributes
    {
        float3 position : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct Varyings
    {
        float4 position : SV_POSITION;
        float2 v_uv : TEXCOORD0;
    };
    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vertex_main
            #pragma fragment fragment_main
            #pragma target 3.5

            Varyings vertex_main(Attributes input)
            {
                Varyings output;
                output.v_uv = input.uv;
                output.position = mul(view_proj, float4(input.position, 1.0));
                return output;
            }

            float4 fragment_main(Varyings input) : SV_Target
            {
                float4 frag_color;
                float4 tint_boost;
                float4 tint_pre;
                tint_boost = (tint * 0.5);
                tint_pre = (tint_boost + tint);
                frag_color = (SAMPLE_TEXTURE2D(tex, samplertex, input.v_uv) * base_color);
                frag_color = (frag_color * tint_pre);
                return frag_color;
            }
            ENDHLSL
        }
    }
}
