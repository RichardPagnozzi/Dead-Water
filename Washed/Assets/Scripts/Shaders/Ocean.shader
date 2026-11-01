Shader "DeadWater/StylizedOcean"
{
    Properties
    {
        _DeepColor ("Deep Water", Color) = (0.025,0.105,0.12,1)
        _MidColor ("Mid Water", Color) = (0.055,0.18,0.19,1)
        _LightColor ("Facet Highlights", Color) = (0.11,0.245,0.25,1)
        _Scale ("Facet Scale", Range(0.2,20)) = 2.8
        _Speed ("Drift Speed", Range(0,2)) = 0.12
        _Contrast ("Facet Contrast", Range(0,2)) = 0.85
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "Unlit"
            Tags { "LightMode"="UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings { float4 positionCS : SV_POSITION; float3 positionWS : TEXCOORD0; };
            CBUFFER_START(UnityPerMaterial)
                half4 _DeepColor, _MidColor, _LightColor;
                float _Scale, _Speed, _Contrast;
            CBUFFER_END
            float2 hash22(float2 p)
            {
                p = float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3)));
                return frac(sin(p)*43758.5453);
            }
            float voronoi(float2 p)
            {
                float2 cell=floor(p), f=frac(p);
                float nearest=10;
                [unroll] for(int y=-1;y<=1;y++)
                [unroll] for(int x=-1;x<=1;x++)
                {
                    float2 offset=float2(x,y);
                    float2 samplePoint=offset + 0.25 + 0.5*hash22(cell+offset);
                    float2 delta=samplePoint-f;
                    nearest=min(nearest,dot(delta,delta));
                }
                return sqrt(nearest);
            }
            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs p=GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS=p.positionCS;
                output.positionWS=p.positionWS;
                return output;
            }
            half4 frag(Varyings input) : SV_Target
            {
                float2 p=input.positionWS.xz / max(_Scale,0.001);
                float2 drift=float2(_Time.y*_Speed, _Time.y*_Speed*0.37);
                float warp=voronoi(p*0.55+drift*0.4);
                p += float2(warp, -warp)*0.38;
                float v=voronoi(p+drift);
                float facet=floor(saturate((1-v)*5.0))/5.0;
                float broad=voronoi(p*0.27-drift*0.3);
                float t=saturate((facet*0.65 + (1-broad)*0.35-0.24)*_Contrast);
                half3 col=lerp(_DeepColor.rgb,_MidColor.rgb,saturate(t*1.7));
                col=lerp(col,_LightColor.rgb,saturate((t-0.53)*0.7));
                return half4(col,1);
            }
            ENDHLSL
        }
    }
}
