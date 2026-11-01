Shader "DeadWater/StylizedOceanV2"
{
    Properties
    {
        _DeepColor ("Deep Water", Color) = (0.025, 0.085, 0.095, 1)
        _MidColor ("Mid Water", Color) = (0.055, 0.155, 0.165, 1)
        _LightColor ("Light Water", Color) = (0.105, 0.235, 0.24, 1)
        _HighlightColor ("Wave Highlight", Color) = (0.24, 0.38, 0.39, 1)
        _CellSize ("Facet Size (World Units)", Range(0.5, 30)) = 7
        _Speed ("Drift Speed", Range(0, 2)) = 0.12
        _Contrast ("Facet Contrast", Range(0, 2)) = 1.15
        _HighlightStrength ("Highlight Strength", Range(0, 1)) = 0.24
        _DetailScale ("Detail Scale", Range(0.2, 5)) = 1.6
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            Name "OceanUnlit"
            Tags { "LightMode"="SRPDefaultUnlit" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _DeepColor;
                half4 _MidColor;
                half4 _LightColor;
                half4 _HighlightColor;
                float _CellSize;
                float _Speed;
                float _Contrast;
                float _HighlightStrength;
                float _DetailScale;
            CBUFFER_END

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings { float4 positionCS : SV_POSITION; float3 positionWS : TEXCOORD0; };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs p = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = p.positionCS;
                OUT.positionWS = p.positionWS;
                return OUT;
            }

            float hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float2 hash22(float2 p)
            {
                return float2(hash21(p + 17.17), hash21(p + 53.31));
            }

            // Returns cell identifier and distance to nearest irregular cell boundary.
            float2 voronoi(float2 p)
            {
                float2 cell = floor(p);
                float2 local = frac(p);
                float closest = 100.0;
                float secondClosest = 100.0;
                float id = 0.0;
                [unroll] for (int y = -1; y <= 1; y++)
                {
                    [unroll] for (int x = -1; x <= 1; x++)
                    {
                        float2 neighbor = float2(x, y);
                        float2 cellIndex = cell + neighbor;
                        float2 site = neighbor + 0.15 + 0.7 * hash22(cellIndex);
                        float d = length(site - local);
                        if (d < closest)
                        {
                            secondClosest = closest;
                            closest = d;
                            id = hash21(cellIndex + 9.7);
                        }
                        else if (d < secondClosest)
                        {
                            secondClosest = d;
                        }
                    }
                }
                return float2(id, secondClosest - closest);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 world = IN.positionWS.xz;
                float timeValue = _Time.y * _Speed;
                float2 uv = world / max(_CellSize, 0.01);
                uv += float2(timeValue * 0.31, timeValue * 0.17);
                uv += 0.13 * float2(sin(uv.y * 1.2 + timeValue), cos(uv.x * 1.1 - timeValue));

                float2 big = voronoi(uv);
                float2 small = voronoi(uv * _DetailScale + float2(4.1, 8.7));
                float shade = saturate((big.x * 0.75 + small.x * 0.25 - 0.5) * _Contrast + 0.5);
                // Three distinct water tones, blended just enough to avoid a tiled checkerboard.
                half3 water = lerp(_DeepColor.rgb, _MidColor.rgb, smoothstep(0.12, 0.53, shade));
                water = lerp(water, _LightColor.rgb, smoothstep(0.57, 0.92, shade) * 0.65);

                // Sparse broken edges: subdued highlights rather than bright white outlines.
                float edge = 1.0 - smoothstep(0.035, 0.13, big.y);
                float breakup = hash21(floor(uv * 3.5)) * 0.65 + small.x * 0.35;
                float highlight = edge * smoothstep(0.53, 0.78, breakup) * _HighlightStrength;
                water = lerp(water, _HighlightColor.rgb, saturate(highlight));
                return half4(water, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
