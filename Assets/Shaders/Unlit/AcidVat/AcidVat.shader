Shader "Custom-Shaders/AcidVat"
{
    Properties
    {
        _xAxisTexture ("Texture that will be used to modify the x axis to only show this effect on that channel", 2D) = "white" {}
        _bubbleTexture ("Texture for the bubbles that pop up", 2D) = "white"  {}

        _topAcidColor ("Color of the top layer of acid", Color) = (1,1,1,1)
        _bottomAcidColor ("Color of the bottom layer of acid", Color) = (1,1,1,1)

        _Tiling ("Tiling mulitiplier of the whole uv's'", float) = 1

        _xWaveAmount ("amount the sine wave effects the x axis of the uv", float) = 1
        _yWaveAmount ("amount the sine wave effects the y axis of the uv", float) = 1
        _overallWaveHeight ("the amount that both axis get divided by to hieghten or lower the wave height, higher number = less height, lower number = more hieght", float) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
                

            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 coords : TEXCOORD1;
                
            };

            sampler2D _xAxisTexture;
            float4 _xAxisTexture_ST, _topAcidColor, _bottomAcidColor, _bubbleTexture;
            float _xWaveAmount, _yWaveAmount, _overallWaveHeight, _Tiling;

            v2f vert (appdata v,float4 vertex : POSITION, float2 uv : TEXCOORD0)
            {
                v2f o;
                o.uv = v.uv;
                o.coords = vertex.xy * _Tiling;
                o.uv = o.uv * 2 - 1; // different space 
                float xAxisTextureModifier = tex2Dlod(_xAxisTexture, float4(o.uv.xy,0,1)); // this is the texture to input so that this sine wave effect only effects that channle of a texture
                xAxisTextureModifier = xAxisTextureModifier * 2 - 1;
                o.uv.x = sin(/* v.uv.x */ xAxisTextureModifier * _xWaveAmount + _Time.y) * cos(o.uv.y * _yWaveAmount + _Time.y);
                
                

                float3 vert = v.vertex;
                vert.y = o.uv.x / _overallWaveHeight;
                o.vertex = UnityObjectToClipPos(vert);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 lerpColor = lerp(_topAcidColor, _bottomAcidColor, i.uv.x);
                //fixed4 stepOutput = step(lerpColor, 0);
                fixed4 bubbleColor = _bubbleTexture;
                return fixed4(lerpColor + _bubbleTexture);
            }
            ENDHLSL
        }
    }
}
