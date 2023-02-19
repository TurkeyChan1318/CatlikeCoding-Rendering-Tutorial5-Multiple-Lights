#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

//在属性说明的参数需要在Pass中声明才能使用
float4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST;//用于设置偏移和缩放，ST是Scale和Transform的意思
float _Metallic;
float _Smoothness;

//顶点数据结构
struct VertexData {
    float4 position : POSITION;//POSITION表示对象本地坐标
    float3 normal : NORMAL;//获取法线信息
    float2 uv : TEXCOORD0;//纹理坐标
};

//插值后数据结构
struct Interpolators {
    float4 position : SV_POSITION;//SV_POSITION指系统的坐标，反正就是要加个语义进去才能使用
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;//纹理坐标
    float3 worldPos : TEXCOORD1;//物体的世界坐标，用来获取视方向

    #if defined(VERTEXLIGHT_ON)//顶点光
        float3 vertexLightColor : TEXCOORD2;
    #endif
};

void ComputeVertexLightColor (inout Interpolators i) {
    #if defined(VERTEXLIGHT_ON)
        i.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, i.worldPos, i.normal
		);
    #endif
}

//顶点数据通过顶点程序后进行插值，插值后数据传递给片元程序
Interpolators MyVertexProgram(VertexData v) {
    Interpolators i;
    i.uv = TRANSFORM_TEX(v.uv, _MainTex);
    i.position = UnityObjectToClipPos(v.position);
    i.normal = UnityObjectToWorldNormal(v.normal);//得到法线的世界坐标
    i.worldPos = mul(unity_ObjectToWorld, v.position);
    ComputeVertexLightColor(i);
    return i;
}

UnityLight CreateLight (Interpolators i) {//创建直接光结构，最后渲染结果要用
    UnityLight light;

    #if defined(POINT) || defined(SPOT) //有点光源和聚光灯的情况
        light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
    #else
        light.dir = _WorldSpaceLightPos0.xyz;
    #endif

    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
    light.color = _LightColor0 * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);
    return light;
}

UnityIndirect CreateIndirectLight (Interpolators i) {//创建简介光结构，最后渲染结果要用
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;

    #if defined(VERTEXLIGHT_ON)//有顶点光的话可以把顶点光视为环境光
        indirectLight.diffuse = i.vertexLightColor;
    #endif
    return indirectLight;
}

//片元程序
float4 MyFragmentProgram(Interpolators i) : SV_TARGET{
    i.normal = normalize(i.normal);//在片元程序归一化，避免使用顶点数据

    float3 lightDir = _WorldSpaceLightPos0.xyz;
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

    float3 lightColor = _LightColor0.xyz;
    float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

    //以下是金属工作流程
    float3 specularTint;
    float oneMinusReflectivity;
    albedo = DiffuseAndSpecularFromMetallic(
        albedo, _Metallic, specularTint, oneMinusReflectivity
    );

    //以下是基于物理着色的输出，从金属工作流程升级
    return UNITY_BRDF_PBS(
        albedo, specularTint,
        oneMinusReflectivity, _Smoothness,
        i.normal, viewDir,
        CreateLight(i), CreateIndirectLight(i)
    );
}
#endif