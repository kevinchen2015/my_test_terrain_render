// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "NY/t4m/T4M 4 Textures Test" {
Properties {
	_Color("_Color",Color) = (1,1,1,1)

	_Splat0 ("Layer 1(RGB) Gloss(A) ", 2D) = "white" {}
	_SplatNormal0("Layer 1 Normal", 2D) = "bump" {}

	_Splat1 ("Layer 2 (RGB) Gloss(A)", 2D) = "white" {}
	_SplatNormal1("Layer 2 Normal", 2D) = "bump" {}

	_Splat2 ("Layer 3 (RGB) Gloss(A)", 2D) = "white" {}
	_SplatNormal2("Layer 3 Normal", 2D) = "bump" {}

	_Splat3 ("Layer 4 (RGB) Gloss(A)", 2D) = "white" {}
	_SplatNormal3("Layer 4 Normal", 2D) = "bump" {}

	_Control ("Control (RGBA)", 2D) = "white" {}


	_Gloss("_Gloss", float) = 1    
	_Specular("_Specular", float) = 20
	_SpecColor("_SpecColor",Color) = (1,1,1,1)
	//_MainTex ("Never Used", 2D) = "white" {}


	[Enum(Sunshine,0,Rain,1,Snow,2,Night,3,Sand,4)]_Weather("Weather",Float) = 0

	_WeatherTex("Weather Tex", 2D) = "white" {}

	//rain
	_Frequency("Move Speed", Float) = 0.1
	_RainGloss("Rain Gloss",Float) = 1
	_RainLightDir("RainLight Dirction",Vector) = (-0.05,0.45,-0.8)

	_Snow("Snow Level", Range(0,1)) = 0
	_SnowColor("Snow Color",Color) = (0.5,0.5,0.5,1)
	//_SnowDirection("Snow Direction", Vector) = (0,1,0)
	//_SnowDepth("Snow Depth", Range(0,1)) = 0.1
	_Wetness("Wetness", Range(0, 0.5)) = 0.3
}
                
SubShader {

	Tags {
		"RenderType" = "Opaque"
	}

	Pass{

	Tags{ "LightMode" = "ForwardBase" }

	CGPROGRAM
	#include "UnityCG.cginc"
	#include "Lighting.cginc" 
	#include "AutoLight.cginc"

	#pragma vertex vert
	#pragma fragment frag
	#pragma multi_compile LIGHTMAP_ON LIGHTMAP_OFF
	#pragma exclude_renderers xbox360 ps3
	#pragma multi_compile_fwdbase
	#pragma multi_compile_fog
		
	sampler2D _Splat0;
	sampler2D _Splat1;
	sampler2D _Splat2;
	sampler2D _Splat3;
	sampler2D _Control;

	float4 _Splat0_ST;
	float4 _Splat1_ST;
	float4 _Splat2_ST;
	float4 _Splat3_ST;
	float4 _Control_ST;

	sampler2D _SplatNormal0;
	sampler2D _SplatNormal1;
	sampler2D _SplatNormal2;
	sampler2D _SplatNormal3;

	float4 _Color;
	float _Gloss;
	float _Specular;

	half _Weather;
	sampler2D _WeatherTex;
	float4 _WeatherTex_ST;

	//rain
	float _Frequency;
	float _RainGloss;
	float3 _RainLightDir;

	float _Snow;
	//float4 _SnowDirection;
	//float _SnowDepth;
	float4 _SnowColor;
	float _Wetness;


	struct v2f {
		float4  pos : SV_POSITION;

		//layer uv
		float4 uvL12: TEXCOORD0;
		float4 uvL34: TEXCOORD1;
		float4 uvCtrAndOther: TEXCOORD2;
		
		//world dir and world pos 
		float4 tSpace0 : TEXCOORD3;
    	float4 tSpace1 : TEXCOORD4;
        float4 tSpace2 : TEXCOORD5;

		//lighting and fog 
		float4  lmap : TEXCOORD6;

		UNITY_SHADOW_COORDS(7)
		UNITY_FOG_COORDS(8)

		#if UNITY_SHOULD_SAMPLE_SH
			half3 sh : TEXCOORD9; // SH
		#endif
	};

	v2f vert(appdata_full  v)
	{
		v2f o;
		UNITY_INITIALIZE_OUTPUT(v2f, o)

		//view pos
		o.pos = UnityObjectToClipPos(v.vertex);
		//uv
		o.uvL12.xy = TRANSFORM_TEX(v.texcoord, _Splat0);
		o.uvL12.zw = TRANSFORM_TEX(v.texcoord, _Splat1);
		o.uvL34.xy = TRANSFORM_TEX(v.texcoord, _Splat2);
		o.uvL34.zw = TRANSFORM_TEX(v.texcoord, _Splat3);
		o.uvCtrAndOther.xy = TRANSFORM_TEX(v.texcoord, _Control);

		o.uvCtrAndOther.zw = TRANSFORM_TEX(v.texcoord, _WeatherTex);

		#ifdef DYNAMICLIGHTMAP_ON
		o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
		#endif

		#ifdef LIGHTMAP_ON
		o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		#endif

		//tangent to world
		float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		float3 worldNormal = (UnityObjectToWorldNormal(v.normal));

		// SH/ambient and vertex lights
		#ifndef LIGHTMAP_ON
		#if UNITY_SHOULD_SAMPLE_SH
		o.sh = 0;
		// Approximated illumination from non-important point lights
		#ifdef VERTEXLIGHT_ON
		o.sh += Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, worldPos, worldNormal);
		#endif
		o.sh = ShadeSHPerVertex(worldNormal, o.sh);
		#endif
		#endif // !LIGHTMAP_ON

		float3 tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
		float3 bitangentDir = normalize(cross(worldNormal, tangentDir) * v.tangent.w);

  		o.tSpace0 = float4(tangentDir.x, bitangentDir.x, worldNormal.x, worldPos.x);
  		o.tSpace1 = float4(tangentDir.y, bitangentDir.y, worldNormal.y, worldPos.y);
  		o.tSpace2 = float4(tangentDir.z, bitangentDir.z, worldNormal.z, worldPos.z);
		
		UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
		UNITY_TRANSFER_FOG(o, o.pos); 
		return o;
	}

	fixed4 frag(v2f i) : COLOR
	{
		fixed4 c = fixed4(0,0,0,0);

		float4 Mask = tex2D(_Control, i.uvCtrAndOther.xy);
		fixed4 lay1 = tex2D(_Splat0, i.uvL12.xy);
		fixed4 lay2 = tex2D(_Splat1, i.uvL12.zw);
		fixed4 lay3 = tex2D(_Splat2, i.uvL34.xy);
		fixed4 lay4 = tex2D(_Splat3, i.uvL34.zw);

		float3 normal1 = UnpackNormal(tex2D(_SplatNormal0, i.uvL12.xy));
		float3 normal2 = UnpackNormal(tex2D(_SplatNormal1, i.uvL12.zw));
		float3 normal3 = UnpackNormal(tex2D(_SplatNormal2, i.uvL34.xy));
		float3 normal4 = UnpackNormal(tex2D(_SplatNormal3, i.uvL34.zw));

		//albedo color blend
		c = (lay1 * Mask.r + lay2 * Mask.g + lay3 * Mask.b + lay4 * Mask.a);
		float gloss = c. a;
		c.a = 1.0;

		float3 tangentDir = float3(i.tSpace0.x, i.tSpace1.x, i.tSpace2.x);
		float3 bitangentDir = float3(i.tSpace0.y, i.tSpace1.y, i.tSpace2.y);
		float3 normalDir = float3(i.tSpace0.z, i.tSpace1.z, i.tSpace2.z);
		normalDir = normalize(normalDir);
		float3x3 tangentTransform = float3x3(tangentDir, bitangentDir, normalDir);

		//tangent normal blend 
		float4 normal;
		normal.rgb = (normal1 * Mask.r + normal2 * Mask.g + normal3 * Mask.b + normal4 * Mask.a);

		//world normal
		float3 normalWorld = normalize(mul(normal.rgb, tangentTransform));


		//world pos
		float3 worldPos = float3(i.tSpace0.w, i.tSpace1.w, i.tSpace2.w);

		//main light dir
		#ifndef USING_DIRECTIONAL_LIGHT
		float3 lightWorldDir = normalize(UnityWorldSpaceLightDir(worldPos));
		#else
		float3 lightWorldDir = normalize(_WorldSpaceLightPos0.xyz);
		#endif
		//view dir
		float3 viewWorldDir = normalize(UnityWorldSpaceViewDir(worldPos));
	
		//------------------------------------------------------------------------
		#ifdef UNITY_COMPILER_HLSL
		SurfaceOutput o = (SurfaceOutput)0;
		#else
		SurfaceOutput o;
		#endif

		// surface
		o.Albedo = 0.0;
		o.Emission = 0.0;
		o.Specular = 0.0;
		o.Alpha = 0.0;

		o.Albedo = c.rgb * _Color.rgb;
		o.Alpha = c.a;
		o.Normal = normalWorld;
		o.Gloss = _Gloss * gloss;
		o.Specular = _Specular;
		
		// compute lighting & shadowing factor
		UNITY_LIGHT_ATTENUATION(atten, i, worldPos)
		
		// Setup lighting environment
		UnityGI gi;
		UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
		gi.indirect.diffuse = 0;
		gi.indirect.specular = 0;
		gi.light.color = _LightColor0.rgb;
		gi.light.dir = lightWorldDir;

		// Call GI (lightmaps/SH/reflections) lighting function
		UnityGIInput giInput;
		UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
		giInput.light = gi.light;
		giInput.worldPos = worldPos;
		giInput.worldViewDir = viewWorldDir;
		giInput.atten = atten;

	#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
		giInput.lightmapUV = i.lmap;
	#else
		giInput.lightmapUV = 0.0;
	#endif
	#if UNITY_SHOULD_SAMPLE_SH
		giInput.ambient = i.sh;
	#else
		giInput.ambient.rgb = 0.0;
	#endif
		giInput.probeHDR[0] = unity_SpecCube0_HDR;
		giInput.probeHDR[1] = unity_SpecCube1_HDR;
	#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
		giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
	#endif
	#ifdef UNITY_SPECCUBE_BOX_PROJECTION
		giInput.boxMax[0] = unity_SpecCube0_BoxMax;
		giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
		giInput.boxMax[1] = unity_SpecCube1_BoxMax;
		giInput.boxMin[1] = unity_SpecCube1_BoxMin;
		giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
	#endif

		LightingBlinnPhong_GI(o, giInput, gi);

		if (_Weather > 3.5)
		{
			//sand
			fixed snowDir = fixed3(0, 1, 0);
			half difference = dot(normalWorld.xyz, snowDir) - lerp(1, -1, _Snow);
			difference = saturate(difference / _Wetness);
			fixed4 SnowColor = tex2D(_WeatherTex, i.uvCtrAndOther.zw);
			o.Albedo = lerp(o.Albedo, SnowColor.rgb*_Color.rgb*_SnowColor.rgb, difference);
		}
		else if (_Weather > 2.5)
		{
			//night nothing
		}
		else if (_Weather > 1.5)
		{
			//snow
			fixed snowDir = fixed3(0, 1, 0);
			half difference = dot(normalWorld.xyz, snowDir) - lerp(1, -1, _Snow);
			difference = saturate(difference / _Wetness);
			fixed4 SnowColor = tex2D(_WeatherTex, i.uvCtrAndOther.zw);
			o.Albedo = lerp(o.Albedo, SnowColor.rgb*_Color.rgb*_SnowColor.rgb, difference);
		}
	
		//if rain light dir same as mainlight,same param can be reused in LighingblinnPhong() 
		c = LightingBlinnPhong(o, viewWorldDir, gi); 
		c.rgb += o.Emission;

		if (_Weather > 0.5)
		{
			//if (_Weather > 0.5)
			{
				//rain
				float4 time = _Time;
				float2 uv_offset =  fixed2(0.01, 0.01) ;
				
				uv_offset = (time.g * _Frequency);
				//uv_offset.x *= sin(time.g * _Frequency) ;
				//uv_offset.y *= cos(time.g * _Frequency) ;
				
				uv_offset += c.rg;

				float2 uv_offset1 = float2(0,0);
				uv_offset1.x = uv_offset.x;
				uv_offset1.y = -uv_offset.y;
				float4 tex = tex2D(_WeatherTex, i.uvCtrAndOther.zw + uv_offset);
				float4 tex1 = tex2D(_WeatherTex, i.uvCtrAndOther.zw - uv_offset1);

				half3 h = normalize(_RainLightDir + viewWorldDir);
				float nh = max(0, dot(normalWorld, h));

				tex = (tex + tex1) / 2;

				c.rgb += tex.rgb * _SpecColor.rgb  * pow(nh, _Specular*2)  * o.Gloss * _RainGloss + tex*_RainGloss*0.03;
			}
		}

		UNITY_APPLY_FOG(i.fogCoord, c);
		UNITY_OPAQUE_ALPHA(c.a);
		return c;
	}
	ENDCG
	}

	
	Pass{
		Name "FORWARD"
		Tags{ "LightMode" = "ForwardAdd" }
		ZWrite Off Blend  One One

		CGPROGRAM
		#include "UnityCG.cginc"
		#include "Lighting.cginc" 
		#include "AutoLight.cginc"

		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile LIGHTMAP_ON LIGHTMAP_OFF
		#pragma exclude_renderers xbox360 ps3
		#pragma multi_compile_fwdadd

		struct v2f 
	    {
			float4  pos : SV_POSITION;
			float3 worldPos : TEXCOORD1;

			fixed3 worldNormal:TEXCOORD2;
		};
		v2f vert(appdata_full  v)
		{
			v2f o = (v2f)0;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			o.worldNormal = UnityObjectToWorldNormal(v.normal);
			return o;
		}
		fixed4 frag(v2f i) : COLOR
		{
			fixed4 c = fixed4(1,0,0,0);
			c = _LightColor0;

			float3 worldPos = i.worldPos;
  			#ifndef USING_DIRECTIONAL_LIGHT
    			fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
  			#else
    			fixed3 lightDir = _WorldSpaceLightPos0.xyz;
  			#endif
  			//fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

			#ifdef UNITY_COMPILER_HLSL
  			SurfaceOutput o = (SurfaceOutput)0;
  			#else
  			SurfaceOutput o;
  			#endif
			
			o.Albedo = c.rgb;
			o.Emission = 0.0;
			o.Specular = 0.0;
			o.Alpha = 0.0;
			o.Gloss = 0.0;

			UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
			o.Normal = i.worldNormal;

			// Setup lighting environment
  			UnityGI gi;
			UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
			gi.indirect.diffuse = 0;
			gi.indirect.specular = 0;
			gi.light.color = _LightColor0.rgb;
			gi.light.dir = lightDir;
			gi.light.color *= atten;

			c = LightingLambert(o,gi);

			c.a = 0.0;

			return c;
		}
		ENDCG
	}
	
}
// Fallback to Diffuse
Fallback "Diffuse"
}
