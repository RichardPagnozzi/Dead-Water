Shader "Custom/StylizedOcean"
{
 Properties
 {
  _DeepColor("Deep Color", Color) = (0.035,0.13,0.17,1)
  _LightColor("Ripple Color", Color) = (0.13,0.34,0.37,1)
  _RippleScale("Ripple Scale", Range(0.1,10)) = 1.8
  _RippleSpeed("Ripple Speed", Range(0,5)) = 0.45
  _RippleStrength("Ripple Strength", Range(0,1)) = 0.27
 }
 SubShader
 {
  Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
  Pass
  {
   Name "Ocean"
   HLSLPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
   struct Attributes { float4 positionOS : POSITION; };
   struct Varyings { float4 positionCS : SV_POSITION; float3 positionWS : TEXCOORD0; };
   CBUFFER_START(UnityPerMaterial)
   half4 _DeepColor, _LightColor;
   float _RippleScale, _RippleSpeed, _RippleStrength;
   CBUFFER_END
   Varyings vert(Attributes i) { Varyings o; VertexPositionInputs p = GetVertexPositionInputs(i.positionOS.xyz); o.positionCS=p.positionCS; o.positionWS=p.positionWS; return o; }
   half4 frag(Varyings i) : SV_Target
   {
    float2 p=i.positionWS.xz * _RippleScale;
    float t=_Time.y*_RippleSpeed;
    float a=sin(p.x*1.4+p.y*0.45+t);
    float b=sin(p.y*1.2-p.x*0.35-t*0.73);
    float c=sin(length(p+float2(sin(t*0.3),cos(t*0.2)))*1.65-t*1.3);
    float lines=smoothstep(0.67,0.94,0.5+0.5*(a*0.45+b*0.35+c*0.2));
    float variation=0.5+0.5*sin(p.x*0.13+p.y*0.17+t*0.13)*sin(p.y*0.21-t*0.16);
    float mixAmount=saturate(variation*0.18+lines*_RippleStrength);
    return half4(lerp(_DeepColor.rgb,_LightColor.rgb,mixAmount),1);
   }
   ENDHLSL
  }
 }
}
