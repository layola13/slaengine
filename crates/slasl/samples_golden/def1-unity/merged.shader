Shader "SLASL/Merged"
{
    Properties
    {
        tint2 ("tint2", Color) = (1, 1, 1, 1)
    }
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)
    float4 tint2;
    CBUFFER_END

    struct Attributes
    {
        float3 position : POSITION;
    };

    struct Varyings
    {
        float4 position : SV_POSITION;
        float v_s : TEXCOORD0;
        float v_t : TEXCOORD1;
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
                output.v_s = 2.0;
                output.v_t = (2.0 * 3.0);
                output.position = float4((input.position * 2.0), 1.0);
                return output;
            }

            float4 fragment_main(Varyings input) : SV_Target
            {
                float4 frag_color;
                frag_color = (tint2 * (input.v_s + input.v_t));
                return frag_color;
            }
            ENDHLSL
        }
    }
}
