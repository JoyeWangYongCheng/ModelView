using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace Framework
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class PostEffects_Stencil : MonoBehaviour
    {
        static class Uniforms
        {
            internal static readonly int _BaseTex = Shader.PropertyToID("_BaseTex");
            internal static readonly int _BloomTex = Shader.PropertyToID("_BloomTex");
            internal static readonly int _Threshold = Shader.PropertyToID("_Threshold");
            internal static readonly int _Curve = Shader.PropertyToID("_Curve");
            internal static readonly int _PrefilterOffs = Shader.PropertyToID("_PrefilterOffs");
            internal static readonly int _SampleScale = Shader.PropertyToID("_SampleScale");
            internal static readonly int _Intensity = Shader.PropertyToID("_Intensity");
        }

        public Shader _shader;

        [System.NonSerialized]
        public float intensity = 1;

        [System.NonSerialized]
        public float threshold = 0.6f;

        public float thresholdLinear
        {
            set { threshold = Mathf.LinearToGammaSpace(value); }
            get {
                Debug.Log(Mathf.GammaToLinearSpace(threshold)); 
                return Mathf.GammaToLinearSpace(threshold); }
        }

        [Range(0f, 1f), Tooltip("Makes transition between under/over-threshold gradual (0 = hard threshold, 1 = soft threshold).")]
        [System.NonSerialized]
        public float softKnee = 1f;

        [Range(1f, 7f), Tooltip("Changes extent of veiling effects in a screen resolution-independent fashion.")]
        [System.NonSerialized]
        public float radius = 4;

        // private
        private Camera _camera;
        private CommandBuffer _screenCopyBuffer;
        private Material _bloomMaterial;

        private const int kMaxPyramidBlurLevel = 4;
        private readonly RenderTexture[] m_BlurBuffer1 = new RenderTexture[kMaxPyramidBlurLevel];
        private readonly RenderTexture[] m_BlurBuffer2 = new RenderTexture[kMaxPyramidBlurLevel];


// 用另外一个摄像机渲染 RenderTex 遮罩

// //渲染遮罩的相机和shader
//         public Camera maskCamera;
//         public Shader replaceShader;

//         private RenderTexture maskRenderTex;

// private void Start() {
//         // maskCamera = GetComponent<Camera>();
//         //摄像机背景要设置为黑色
//         maskCamera.enabled = false;
//         maskCamera.clearFlags = CameraClearFlags.SolidColor;
//         maskCamera.backgroundColor = Color.black;
// 		// maskCamera.cullingMask = 1<<9;

//         UpdateCamera();
//         UpdateCameraSetting();
// }

// private void LateUpdate() {
//          UpdateCamera();
//         // 调用渲染   用shader 类型 的方式 来渲染同类型 物体 
//         maskCamera.RenderWithShader(replaceShader, "RenderType");   
// }

//     void UpdateCamera()
//     {
//         maskCamera.transform.position = gameObject.transform.position;
//         maskCamera.transform.rotation = gameObject.transform.rotation;
//     }
//     void UpdateCameraSetting()
//     {

// //调用渲染        
// //设置相机和主相机一样
//         maskCamera.orthographic = gameObject.GetComponent<Camera>().orthographic;
//         maskCamera.orthographicSize = gameObject.GetComponent<Camera>().orthographicSize;
//         maskCamera.nearClipPlane = gameObject.GetComponent<Camera>().nearClipPlane;
//         maskCamera.farClipPlane = gameObject.GetComponent<Camera>().farClipPlane;
//         maskCamera.fieldOfView = gameObject.GetComponent<Camera>().fieldOfView;
// 		RenderTexture renderTex = new RenderTexture(Screen.width/2,Screen.height/2,2,RenderTextureFormat.ARGB32,RenderTextureReadWrite.sRGB);
// 		maskCamera.targetTexture = renderTex;

// 		//把这张副摄像机渲染局部物体的renderTex赋给主摄像机
// 		maskRenderTex = maskCamera.targetTexture;
//     }



//用 stencil模板 渲染遮罩

public Material material;
public List<MeshFilter> glowTargets;
public bool enabledStencil = true;
        private void DepthBlit(RenderTexture source, RenderTexture destination, Material mat, int pass, RenderTexture depth)
        {
            if (depth == null)
            {
                Graphics.Blit(source, destination, mat, pass);
                return;
            }
            Graphics.SetRenderTarget(destination.colorBuffer, depth.depthBuffer);
            GL.PushMatrix();
            GL.LoadOrtho();
            mat.mainTexture = source;
            mat.SetPass(pass);
            GL.Begin(GL.QUADS);
            GL.TexCoord2(0.0f, 1.0f); GL.Vertex3(0.0f, 1.0f, 0.1f);
            GL.TexCoord2(1.0f, 1.0f); GL.Vertex3(1.0f, 1.0f, 0.1f);
            GL.TexCoord2(1.0f, 0.0f); GL.Vertex3(1.0f, 0.0f, 0.1f);
            GL.TexCoord2(0.0f, 0.0f); GL.Vertex3(0.0f, 0.0f, 0.1f);
            GL.End();
            GL.PopMatrix();
        }


        private void OnDestroy()
        {
            if (_bloomMaterial != null)
            {
                DestroyImmediate(_bloomMaterial);
                _bloomMaterial = null;
            }
        }
        

        // bloom
        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
      
//  Graphics.Blit(maskRenderTex, destination);

            // if (_camera == null)
            // {
            //     _camera = GetComponent<Camera>();
            // }
            // if (_bloomMaterial == null)
            // {
            //     _bloomMaterial = new Material(_shader);
            // }

            // if (!_camera.allowHDR)
            // {
            //     _camera.allowHDR = true;
            // }

            RenderTexture glow = RenderTexture.GetTemporary(source.width , source.height, 0, RenderTextureFormat.ARGB32);
            glow.filterMode = FilterMode.Bilinear;
            Graphics.SetRenderTarget(glow.colorBuffer, source.depthBuffer);//将绘制目标切换至新RT，但保留原来的深度缓存
            GL.Clear(false, true, Color.clear);

            // material.SetPass(0);//设置发光材质
            // foreach (MeshFilter r in glowTargets)
            // {
            //     Graphics.DrawMeshNow(r.sharedMesh, r.transform.localToWorldMatrix);//绘制发光物体
            // }

            var rtW = source.width / 2;
            var rtH = source.height / 2;

            RenderTexture stencil = null;
            if (enabledStencil)
            {
                stencil = RenderTexture.GetTemporary(rtW, rtH, 24, RenderTextureFormat.Depth);
                Graphics.SetRenderTarget(stencil);
                GL.Clear(true, true, Color.clear);
                material.SetPass(1);//设置标记材质
                foreach (MeshFilter r in glowTargets)
                {
                    Graphics.DrawMeshNow(r.sharedMesh, r.transform.localToWorldMatrix);//绘制标记
                }
            }
            
            // fastBloomMaterial.SetVector("_Parameter", new Vector4(size, 0.0f, 0.0f, intensity));
           
            // // downsample
            // RenderTexture rt = RenderTexture.GetTemporary(rtW, rtH, 0, glow.format);
            // rt.filterMode = FilterMode.Bilinear;
            // DepthBlit(glow, rt, fastBloomMaterial, 1, stencil);

            // // vertical blur
            // RenderTexture rt2 = RenderTexture.GetTemporary(rtW, rtH, 0, glow.format);
            // rt2.filterMode = FilterMode.Bilinear;
            // DepthBlit(rt, rt2, fastBloomMaterial, 2, stencil);
            // RenderTexture.ReleaseTemporary(rt);
            // rt = rt2;

            // // horizontal blur
            // rt2 = RenderTexture.GetTemporary(rtW, rtH, 0, glow.format);
            // rt2.filterMode = FilterMode.Bilinear;
            // DepthBlit(rt, rt2, fastBloomMaterial, 3, stencil);
            // RenderTexture.ReleaseTemporary(rt);
            // rt = rt2;

            // fastBloomMaterial.SetTexture("_Bloom", rt);
            // if (putToScreen) Graphics.Blit(source, destination, fastBloomMaterial, 0);

            // RenderTexture.ReleaseTemporary(rt);
            // RenderTexture.ReleaseTemporary(glow);

            // if (stencil != null)
            //     RenderTexture.ReleaseTemporary(stencil);







            // var tw = Screen.width / 2;
            // var th = Screen.height / 2;

            // _bloomMaterial.SetFloat(Uniforms._Intensity, intensity);

            // float logh = Mathf.Log(th, 2f) + radius - 8f;
            // int logh_i = (int)logh;

            // int iterations = Mathf.Clamp(logh_i, 1, kMaxPyramidBlurLevel);  //迭代次数

            // float lthresh = thresholdLinear;  // 线性阈值
            // _bloomMaterial.SetFloat(Uniforms._Threshold, lthresh);

            // //float knee = lthresh * softKnee + 1e-5f;
            // //var curve = new Vector3(lthresh - knee, knee * 2f, 0.25f / knee);
            // //_bloomMaterial.SetVector(Uniforms._Curve, curve);

            // _bloomMaterial.SetFloat(Uniforms._PrefilterOffs, 0); //过滤器

            // float sampleScale = 0.5f + logh - logh_i;
            // _bloomMaterial.SetFloat(Uniforms._SampleScale, sampleScale);  //采样缩放
            // //新建一张rendertexture , 并将当前摄像机渲染的图像  经过第一个pss 复制到 rendertexture 上。
            // //第一个pass的操作是提取 人物需要亮的地方。 其他地方都是黑色
            // var prefiltered = RenderTexture.GetTemporary(tw, th, 0, RenderTextureFormat.ARGB32); 
            // // Graphics.Blit(source, prefiltered, _bloomMaterial, 0);
            // DepthBlit(glow, prefiltered, _bloomMaterial, 0, stencil);

            // var last = prefiltered;
             
            // for (int level = 0; level < iterations; level++)
            // {
            //     //第二个pass 把 提取的亮度图 等比例缩小
            //     m_BlurBuffer1[level] = RenderTexture.GetTemporary(last.width / 2, last.height / 2, 0, RenderTextureFormat.ARGB32);
            //     int pass = (level == 0) ? 1 : 2;
            //     Graphics.Blit(last, m_BlurBuffer1[level], _bloomMaterial, pass);
            //     last = m_BlurBuffer1[level];
            // }

            // for (int level = iterations - 2; level >= 0; level--)
            // {
            //     var baseTex = m_BlurBuffer1[level];
            //     _bloomMaterial.SetTexture(Uniforms._BaseTex, baseTex);
            //     m_BlurBuffer2[level] = RenderTexture.GetTemporary(baseTex.width, baseTex.height, 0, RenderTextureFormat.ARGB32);
            //     Graphics.Blit(last, m_BlurBuffer2[level], _bloomMaterial, 3);
            //     last = m_BlurBuffer2[level];
            // }

            // var bloomTex = last;

            // for (int i = 0; i < kMaxPyramidBlurLevel; i++)
            // {
            //     if (m_BlurBuffer1[i] != null)
            //         RenderTexture.ReleaseTemporary(m_BlurBuffer1[i]);

            //     if (m_BlurBuffer2[i] != null && m_BlurBuffer2[i] != bloomTex)
            //         RenderTexture.ReleaseTemporary(m_BlurBuffer2[i]);

            //     m_BlurBuffer1[i] = null;
            //     m_BlurBuffer2[i] = null;
            // }
            // RenderTexture.ReleaseTemporary(prefiltered);
            // prefiltered = null;

            // _bloomMaterial.SetTexture(Uniforms._BloomTex, bloomTex);
            // Graphics.Blit(source, destination, _bloomMaterial, 4);
            // RenderTexture.ReleaseTemporary(bloomTex);
        }
    }
}