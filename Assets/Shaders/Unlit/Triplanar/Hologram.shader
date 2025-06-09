Shader "Custom-Shaders/HologramShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tiling ("Tiling", Float) = 1
        _OcclusionMap("Occlusion", 2D) = "white" {}
        
        _AnimateXY("animation vector", Vector) = (0,0,0,0)

        _FresnelIntensity("intensity of fresnel", Range(0,10)) = 0.8
        _FresnelRamp("fresnel ramp", Range(0,20)) = 0.4
        _FresnelColor("color of fresnel effect", Color) = (1,1,1,1)      
        _InvFresnelIntensity("inverse intensity of fresnel", Range(0,10)) = 4
        _InvFresnelRamp("inverse fresnel ramp", Range(0,20)) = 2.5
        _InvFresnelColor("inverse color of fresnel effect", Color) = (1,1,1,1) 
        _DistortionIntensity("inverse intensity of distortion", Range(0,10)) = 2.59
        _DistortionTex("distortion texture", 2D) = "white" {}
    }
    SubShader
    {
        Blend SrcAlpha One
        Pass
        {
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                half3 objNormal : TEXCOORD0;
                float3 coords : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float4 pos : SV_POSITION;
            };

            float _Tiling;

            sampler2D _MainTex, _DistortionTex;
            sampler2D _OcclusionMap;

            float4 _FresnelColor, _InvFresnelColor, _MainTex_ST, _AnimateXY;
            float _FresnelIntensity, _FresnelRamp, _InvFresnelIntensity, _InvFresnelRamp, _DistortionIntensity;

            v2f vert (appdata v, float4 pos : POSITION, float3 normal : NORMAL, float2 uv : TEXCOORD0)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                

                o.pos = UnityObjectToClipPos(pos);
                o.coords = pos.xyz * _Tiling;
                o.objNormal = normal;
                o.uv = uv * _Tiling;
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = _AnimateXY.xy * float2(_Time.y,_Time.y);
                return o;
            }

            
            
            fixed4 frag (v2f i) : SV_Target
            {
                float2 uvs = i.uv;

                float distort = tex2D(_DistortionTex, i.uv * _Time.yy);
                float3 finalNormal = i.objNormal;

                float fresnelAmount = 1 - max(0,dot(i.objNormal, i.viewDir));
                fresnelAmount *= distort * _DistortionIntensity;
                fresnelAmount = pow(fresnelAmount, _FresnelRamp) * _FresnelIntensity;
                float3 fresnelColor = fresnelAmount * _FresnelColor;
                

                float invfresnelAmount = max(0,dot(i.objNormal, i.viewDir));
                fresnelAmount *= distort * _DistortionIntensity;
                invfresnelAmount = pow(invfresnelAmount, _InvFresnelRamp) * _InvFresnelIntensity;
                float3 invfresnelColor = invfresnelAmount * _InvFresnelColor;

                float3 finalColor = lerp(fresnelColor, invfresnelColor, invfresnelAmount) + distort;
                

                


                // use absolute value of normal as texture weights
                half3 blend = abs(i.objNormal);
                // make sure the weights sum up to 1 (divide by sum of x+y+z)
                blend /= dot(blend,1.0);
                // read the three texture projections, for x,y,z axes
                fixed4 cx = tex2D(_MainTex, i.coords.yz + uvs);
                fixed4 cy = tex2D(_MainTex, i.coords.xz + uvs);
                fixed4 cz = tex2D(_MainTex, i.coords.xy + uvs);
                // blend the textures based on weights
                fixed4 c = cx * blend.x + cy * blend.y + cz * blend.z;
                // modulate by regular occlusion map
                c *= tex2D(_OcclusionMap, i.uv);

                

                return fixed4(c + fresnelColor + invfresnelColor,1);
            }
            ENDHLSL
        }
    }
}
