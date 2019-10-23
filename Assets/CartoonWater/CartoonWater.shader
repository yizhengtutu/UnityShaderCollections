Shader "Unlit/CartoonWater"
{
	Properties
	{
		_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
		_RippleSpeed("RippleSpeed", Range(0, 2)) = 0.1
		_RippleDensity("RippleDensity", Range(1, 100)) = 6
		_RippleSlimness("RippleConorSharpness", Range(1, 10)) = 3
	}
	SubShader
	{
		Tags { 
			"RenderType"="Transparent" 
			"LightMode" = "ForwardBase"
			"Queue" = "Transparent"
		}
		LOD 100
		Cull Off
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

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

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			
			fixed4 _BaseColor;
			float _RippleSpeed;
			float _RippleDensity;
			float _RippleSlimness;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			float2 random2(float2 p)
			{
				return frac(sin(float2(dot(p, float2(117.12, 341.7)), dot(p, float2(269.5, 123.3))))*43458.5453);
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = _BaseColor;

				float rippleDelta = _Time.y * _RippleSpeed;
				float2 uv = i.uv;
				uv *= _RippleDensity; //Scaling amount (larger number more cells can be seen)
				float2 iuv = floor(uv); //gets integer values no floating point
				float2 fuv = frac(uv); // gets only the fractional part
				float minDist = 1.0;  // minimun distance
				for (int y = -1; y <= 1; y++)
				{
					for (int x = -1; x <= 1; x++)
					{
						// Position of neighbour on the grid
						float2 neighbour = float2(float(x), float(y));
						// Random position from current + neighbour place in the grid
						float2 pointv = random2(iuv + neighbour);
						// Move the point with time
						pointv = 0.5 + 0.5*sin(rippleDelta + 6.2236*pointv);//each point moves in a certain way
																		// Vector between the pixel and the point
						float2 diff = neighbour + pointv - fuv;
						// Distance to the point
						float dist = length(diff);
						// Keep the closer distance
						minDist = min(minDist, dist);
					}
				}
				// Draw the min distance (distance field)
				float scaleMinDist = pow(minDist, _RippleSlimness); // scale it to to make edges look sharper
				col.r += scaleMinDist;
				col.g += scaleMinDist;
				col.b += scaleMinDist;

				return col;
			}


			ENDCG
		}
	}
}
