Shader "SysFont/Unlit Transparent" 
{
  Properties 
  {
    _Color ("Text Color", Color) = (1,1,1,1)    
    _MainTex ("Base (RGB), Alpha (A)", 2D) = "white" {}
  }

  SubShader
  {
    Tags
    {
      "Queue" = "Transparent"
      "IgnoreProjector" = "True"
      "RenderType" = "Transparent"
    }

    Pass 
    {
      Cull Off
      Lighting Off
      ZWrite Off
      Fog { Mode Off }
      AlphaTest Off
      Blend One OneMinusSrcAlpha

      CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"

        struct appdata_t {
          float4 vertex : POSITION;
          fixed4 color : COLOR;
          fixed2 texcoord : TEXCOORD0;
        };

        struct v2f {
          float4 vertex : POSITION;
          fixed4 color : COLOR;
          fixed2 texcoord : TEXCOORD0;
        };

        sampler2D _MainTex;
        uniform float4 _MainTex_ST;
        uniform float4 _Color;

        v2f vert (appdata_t v)
        {
          v2f o;
          o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
          o.color = v.color;
          o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
          return o;
        }

        fixed4 frag (v2f i) : COLOR
        {
          fixed4 texColor = tex2D(_MainTex, i.texcoord);
          fixed4 output = texColor;
          output.rgb = texColor.rgb * _Color.rgb * _Color.a;
          output.a = texColor.a * _Color.a;
          return output;
        }
      ENDCG
    }
  }
}
