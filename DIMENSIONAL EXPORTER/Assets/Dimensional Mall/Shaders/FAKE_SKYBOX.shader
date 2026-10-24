Shader "Saii/FAKE_SKYBOX"
{
    Properties
    {
        _MainTex ("CubeMap", Cube) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolate
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            samplerCUBE _MainTex;
            float4 _MainTex_ST;

            Interpolate vert (appdata v)
            {
                Interpolate o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // float3 viewDir = -normalize(ObjSpaceViewDir(v.vertex));

                // Calculate view direction , calculate it from local position and get world thing yeah
                o.worldPos =mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float4 frag (Interpolate i) : SV_Target
            {
                // subtract world position from camera position to get view direction
                float3 viewDir = normalize(i.worldPos - _WorldSpaceCameraPos);
                // sample the texture
                float4 col = texCUBE(_MainTex, viewDir);
                return col;
            }
            ENDCG
        }
    }
}
