Shader "SLASL/Merged"
{
    Properties
    {
        env ("env", 2D) = "white" {}
        irr ("irr", 2D) = "white" {}
    }
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    TEXTURE2D(env);
    SAMPLER(samplerenv);

    struct Attributes
    {
        float3 position : POSITION;
        float3 normal : NORMAL;
    };

    struct Varyings
    {
        float4 position : SV_POSITION;
        float3 v_normal : TEXCOORD0;
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

float4 slasl_probe_sphere(Texture2D env, SamplerState samplerenv, float3 dir)
{
    float3 d = normalize(dir);
    float2 uv = float2(atan2(d.z, d.x) * 0.15915494 + 0.5, acos(clamp(d.y, -1.0, 1.0)) * 0.31830989);
    return SAMPLE_TEXTURE2D(env, samplerenv, uv);
}

            Varyings vertex_main(Attributes input)
            {
                Varyings output;
                output.v_normal = input.normal;
                output.position = float4(input.position, 1.0);
                return output;
            }

            float4 fragment_main(Varyings input) : SV_Target
            {
                float4 frag_color;
                frag_color = slasl_probe_sphere(env, samplerenv, input.v_normal);
                return frag_color;
            }
            ENDHLSL
        }
    }
}
