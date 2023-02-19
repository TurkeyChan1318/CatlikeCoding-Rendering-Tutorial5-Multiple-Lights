// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/ManyLightShader"
{
    Properties//属性面板，用来说明参数属性
    {
        _Tint ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white"{}
        //_SpecularTint ("SpecularColor", Color) = (1, 1, 1, 1) //如果是金属工作流程则不需要高光颜色
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 1

    }
    SubShader
    {
        Pass//基础灯光通道
        {
            Tags{
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM

            #pragma target 3.0

            #pragma multi_compile _ VERTEXLIGHT_ON//启用顶点灯

            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram

            #include "My Lighting.cginc"

            ENDCG
        }

        Pass//其他灯光
        {
            Tags{
                "LightMode" = "ForwardAdd"
            }

            Blend One One
            Zwrite Off

            CGPROGRAM

            #pragma target 3.0

            #pragma multi_compile DIRECTIONAL POINT SPOT

            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram

            #include "My Lighting.cginc"

            ENDCG
        }
    }
}