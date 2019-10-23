Shader "YZ/pbrHD"
{
	Properties
	{
		_MainTex ("MainTex", 2D) = "white" {}
		_NormalTex("NormalTex", 2D) = "white" {}//Normal Map 是 Bump Map的一种
		_OcclusionTex("OcclusionTex", 2D) = "black" {}//用来管理间接光影响的强度
		_OcclusionColor("OcclusionColor", Color) = (0, 0, 0, 1)//间接光影响的occ颜色
		_DisplacementTex("DisplacementTex", 2D) = "black" {}//移位贴图，用来改变顶点的位置
		_DisplacementAmount("Displacement", Range(0, 3)) = 0.5//移位贴图的强度
		_RoughTex("RoughTex", 2D) = "white" {}//粗糙贴图，越亮，镜面反射程度越强
		_Glossiness("_Glossiness", Range(1, 10)) = 1//反射光的强度
		_SpecularColor("Specular", Color) = (0.2,0.2,0.2)//反射光颜色
	}
	SubShader
	{
		Tags { 
			"RenderType"="Opaque" 
			"LightMode"="ForwardBase"
		}
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"//定义了_LightColor0

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				half3 tspace0 : TEXCOORD1;
				half3 tspace1 : TEXCOORD2;
				half3 tspace2 : TEXCOORD3;
				float3 worldSpaceViewDirection : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			sampler2D _NormalTex;
			sampler2D _DisplacementTex;
			float _DisplacementAmount;
			sampler2D _OcclusionTex;
			float4 _OcclusionColor;
			sampler2D _RoughTex;
			float _Glossiness;
			fixed3 _SpecularColor;

			v2f vert (appdata v)
			{
				v2f o;

				//凹凸贴图
				float d = tex2Dlod(_DisplacementTex, float4(v.uv.xy, 0, 0)).r * _DisplacementAmount;
				float4 vertex = v.vertex;
				vertex.xyz += v.normal * d;

				o.vertex = UnityObjectToClipPos(vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				//计算TBN
				half3 T = UnityObjectToWorldDir(v.tangent.xyz);
				half3 N = UnityObjectToWorldNormal(v.normal.xyz);
				// compute bitangent from cross product of normal and tangent
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 B = cross(T, N) * tangentSign;
				o.tspace0 = half3(T.x, B.x, N.x);
				o.tspace1 = half3(T.y, B.y, N.y);
				o.tspace2 = half3(T.z, B.z, N.z);

				//计算视角方向
				o.worldSpaceViewDirection = UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex).xyz);

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//反照率
				fixed4 albdo = tex2D(_MainTex, i.uv);
				
				//法线从TBN空间转换到World空间
				half3 tnormal = UnpackNormal(tex2D(_NormalTex, i.uv));
				half3 worldNormal;
				worldNormal.x = dot(i.tspace0, tnormal);
				worldNormal.y = dot(i.tspace1, tnormal);
				worldNormal.z = dot(i.tspace2, tnormal);

				//计算漫反射
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float diffuse = dot(worldNormal, lightDir);

				//角落明暗强度
				float occlusion = tex2D(_OcclusionTex, i.uv).r;
				float3 occ = _OcclusionColor * occlusion;

				//镜面反射
				float3 viewDirection = normalize(i.worldSpaceViewDirection);
				float smoothness = tex2D(_RoughTex, i.uv).r;
				float specularReflection = smoothness * pow(max(0.0, dot(reflect(-lightDir, worldNormal), viewDirection)), _Glossiness);
				float3 specularCol = specularReflection * _LightColor0.xyz * _SpecularColor.xyz;

				//环境光
				fixed4 ambientCol = UNITY_LIGHTMODEL_AMBIENT;

				fixed4 col;
				col.xyz = albdo * diffuse * _LightColor0.xyz + occ + specularCol + ambientCol.xyz;
				col.a = 1;

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
