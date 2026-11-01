Shader "DeadWater/WakeFoam"
{
    Properties
    {
        _BaseMap ("Foam Texture (RGBA)", 2D) = "white" {}
        _BaseColor ("Foam Tint", Color) = (0.65,0.78,0.78,0.8)
        _Cutoff ("Alpha Cutoff", Range(0,1)) = 0.18
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        Pass
        {
            Name "Foam"
            Tags { "LightMode"="UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; half4 color : COLOR; };
            struct Varyings { float4 positionCS : SV_POSITION; float2 uv : TEXCOORD0; half4 color : COLOR; };
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                float _Cutoff;
            CBUFFER_END
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS=TransformObjectToHClip(input.positionOS.xyz);
                output.uv=TRANSFORM_TEX(input.uv,_BaseMap);
                output.color=input.color;
                return output;
            }
            half4 frag(Varyings input) : SV_Target
            {
                half4 tex=SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,input.uv);
                half alpha=tex.a*_BaseColor.a*input.color.a;
                alpha *= smoothstep(_Cutoff, _Cutoff+0.12, tex.a);
                return half4(tex.rgb*_BaseColor.rgb*input.color.rgb,alpha);
            }
            ENDHLSL
        }
    }
}
