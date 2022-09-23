Shader "Unlit/RaymarchUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
          

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
                float3 cameraOrigin : TEXCOORD1; // ray origin
                float3 hitPosition : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.cameraOrigin = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                o.hitPosition = v.vertex;
                return o;
            }

            // Distance to the scene (depth)

            float GetDistance(float3 rayPosition)
            {
                // for sphere
                float distance = length(rayPosition) - .5;
                // torus
                distance = length(float2(length(rayPosition.xz) - 0.5, rayPosition.y)) - 0.1;
                
                return distance;
            }

            float3 GetNormal(float3 rayPoint)
            {
                float2 e = float2(1e-2, 0);
                float3 normal = GetDistance(rayPoint) - float3(
                    GetDistance(rayPoint - e.xyy),
                    GetDistance(rayPoint - e.yxy),
                    GetDistance(rayPoint - e.yyx)
                );
                return normalize(normal);
            }
            
            float Raymarch(float3 rayOrigin, float3 rayDirection)
            {
                float marchedDistance = 0; // we change this step by step / distance from origin
                float distanceToScene = 0;

                const int MAX_STEPS = 50;
                const int MAX_DISTANCE = 100;
                const int SURF_DISTANCE = 1e-3;
                
                for(int i = 0; i < MAX_STEPS; i++)
                {
                    float3 rayPosition = rayOrigin + marchedDistance * rayDirection;
                    distanceToScene = GetDistance(rayPosition);
                    marchedDistance += distanceToScene;
                    if(distanceToScene < SURF_DISTANCE || marchedDistance > MAX_DISTANCE)
                    {
                        break;
                    }
                }
                return marchedDistance;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv - 0.5;
                float3 rayOrigin = i.cameraOrigin;
                float3 rayDirection = normalize(i.hitPosition - rayOrigin); 

                float distance = Raymarch(rayOrigin, rayDirection);
                fixed4 col = 0;
                fixed4 tex = tex2D(_MainTex, i.uv);
                float mask = dot(uv, uv);
                float smoothedMask = smoothstep(0, .25, mask);
                if(distance < 100)
                {
                    float3 rayPoint = rayOrigin + rayDirection * distance;
                    float3 normal = GetNormal(rayPoint);
                    col.rgb = normal;
                }
                else if(smoothedMask < 0.9)
                {
                    discard;
                }

                col = lerp(col, tex, smoothedMask);
                
                return col;
            }
            ENDCG
        }
    }
}
