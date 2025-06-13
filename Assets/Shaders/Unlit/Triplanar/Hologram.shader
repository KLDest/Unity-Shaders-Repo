Shader "Custom-Shaders/HologramShader"
{
    Properties
    {
        [Header(Main Textures)] 
        _MainTex ("Texture for showing scan lines", 2D) = "white" {}
        _OcclusionMap("Occlusion", 2D) = "white" {}
        /*Main Textures*/

        [Header(Other Parameters)] 
        _Tiling ("Tiling amount for UV's", Float) = 1
        _AnimateXY("animation vector", Vector) = (0,0,0,0)
        /*Other Parameters*/

        [Header(Fresnel Effect outer hologram effect)]    
        _FresnelIntensity("intensity of fresnel", Range(0,10)) = 1
        _FresnelRamp("fresnel ramp", Range(0,20)) = 1
        _FresnelColor("color of fresnel effect", Color) = (1,1,1,1)  
        /*Fresnel Effect */

        [Header(Fresnel Effect inner hologram effect)]   
        _InvFresnelIntensity("inverse intensity of fresnel", Range(0,10)) = 1
        _InvFresnelRamp("inverse fresnel ramp", Range(0,20)) = 1
        _InvFresnelColor("inverse color of fresnel effect", Color) = (1,1,1,1) 
        /*Inverse Fresnel Effect */

        [Header(Distortion Texture)] 
        _DistortionTex("distortion texture", 2D) = "white" {}
        _DistortionIntensity("intensity of distortion", Range(0,10)) = 1
        /*Distortion Effect That plays over all the object, works well with a noise texture*/
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
                float3 coords : TEXCOORD1; // the coordinates of the current texture
                float2 uv : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float4 pos : SV_POSITION;
            };

            

            sampler2D _MainTex, _DistortionTex;
            sampler2D _OcclusionMap;
            float4 _FresnelColor, _InvFresnelColor, _MainTex_ST, _AnimateXY;
            float _FresnelIntensity, _FresnelRamp, _InvFresnelIntensity, _InvFresnelRamp, _DistortionIntensity, _Tiling;



            v2f vert (appdata v, float4 pos : POSITION, float3 normal : NORMAL, float2 uv : TEXCOORD0)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(pos);
                o.coords = pos.xyz * _Tiling; //used to tile the uvs to a certain scale, allows for more uv's or less'
                o.objNormal = normal; // setting the objNormal texcoords to the objects normal map
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex)); // this is normalizing the current viewdirection and putting it into the texcoords of viewDir
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = _AnimateXY.xy * float2(_Time.y,_Time.y); // animated the min texture across the xy axis of the uv
                return o;
            }

            
            
            fixed4 frag (v2f i) : SV_Target
            {
                float2 uvs = i.uv; // just getting the final uvs from v2f

                float distort = tex2D(_DistortionTex, i.uv * _Time.yy); // moving the distiortion texture across the uv 

                /*START - Fresnel Effect code - outer hologram effect*/
                float fresnelAmount = 1 - max(0,dot(i.objNormal, i.viewDir));
                fresnelAmount = pow(fresnelAmount, _FresnelRamp) * _FresnelIntensity;
                float3 fresnelColor = fresnelAmount * _FresnelColor;
                /*END - Fresnel Effect code - outer hologram effect*/

                /*START - Fresnel Effect code - inner hologram effect*/
                float invfresnelAmount = max(0,dot(i.objNormal, i.viewDir));
                invfresnelAmount = pow(invfresnelAmount, _InvFresnelRamp) * _InvFresnelIntensity;
                float3 invfresnelColor = invfresnelAmount * _InvFresnelColor;
                /*END - Fresnel Effect code - inner hologram effect*/

                //float3 finalColor = lerp(fresnelColor, invfresnelColor, invfresnelAmount) + distort; // lerping between the two effects and applying the distortion over the end result
                

                /*START - TRIPLANAR from Unity docs to apply the texture over the whole 3dobject, especially if its a complex one*/
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
                /*END - TRIPLANAR from Unity docs to apply the texture over the whole 3dobject, especially if its a complex one*/

                return fixed4(c + fresnelColor + invfresnelColor,1) * (distort * _DistortionIntensity); // retuns the 
            }
            ENDHLSL
        }
    }
}
