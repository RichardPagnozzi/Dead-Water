Shader "Custom/DredgeStyleOcean"
{
    Properties
    {
        _DeepColor ("Deep Water", Color) = (0.025,0.105,0.125,1)
        _MidColor ("Surface Water", Color) = (0.075,0.205,0.215,1)
        _HighlightColor ("Muted Highlights", Color) = (0.22,0.38,0.37,1)
        _Scale ("Pattern Scale", Range(0.005,0.3)) = 0.035
        _Speed ("Current Speed", Range(0,2)) = 0.15
        _Contrast ("Color Variation", Range(0,1)) = 0.45
        _HighlightAmount ("Highlight Amount", Range(0,0.5)) = 0.09
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            Name "UnlitOcean"
            Tags { "LightMode"="SRPDefaultUnlit" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _DeepColor;
            float4 _MidColor;
            float4 _HighlightColor;
            float _Scale;
            float _Speed;
            float _Contrast;
            float _HighlightAmount;
            CBUFFER_END

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings { float4 positionCS : SV_POSITION; float3 worldPos : TEXCOORD0; };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs pos = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = pos.positionCS;
                OUT.worldPos = pos.positionWS;
                return OUT;
            }

            float hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float valueNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f*f*(3.0-2.0*f);
                return lerp(lerp(hash21(i), hash21(i+float2(1,0)),u.x),
                            lerp(hash21(i+float2(0,1)),hash21(i+float2(1,1)),u.x),u.y);
            }

            float fbm(float2 p)
            {
                float v = 0;
                float a = 0.5;
                [unroll] for (int i=0; i<4; i++)
                {
                    v += a * valueNoise(p);
                    p = mul(float2x2(1.6,-1.2,1.2,1.6),p) + 7.13;
                    a *= 0.5;
                }
                return v;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 p = IN.worldPos.xz * _Scale;
                float t = _Time.y * _Speed;
                float2 warp = float2(fbm(p*0.7 + float2(t*0.14,0)), fbm(p*0.7 + float2(8,-t*0.11)));
                float2 q = p + (warp-0.5)*1.8;
                float large = fbm(q + float2(t*0.22,t*0.08));
                float fine = fbm(q*2.5 + float2(-t*0.28,t*0.18));
                float shade = saturate(0.5 + (large-0.5)*_Contrast*2.0 + (fine-0.5)*_Contrast*0.32);
                float3 color = lerp(_DeepColor.rgb, _MidColor.rgb, shade);
                // Rare broken glints, distorted by broad currents; no repeating grid.
                float streak = smoothstep(0.72,0.86, fine*0.55 + large*0.45);
                streak *= smoothstep(0.42,0.67,large);
                color = lerp(color, _HighlightColor.rgb, streak * _HighlightAmount);
                return half4(color,1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
