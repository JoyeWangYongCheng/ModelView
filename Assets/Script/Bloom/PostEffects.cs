using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

namespace Framework
{
    public class PostEffects : MonoBehaviour
    {
        static class Uniforms
        {
            internal static readonly int _BaseTex = Shader.PropertyToID("_BaseTex");
            internal static readonly int _BloomTex = Shader.PropertyToID("_BloomTex");
            internal static readonly int _Threshold = Shader.PropertyToID("_Threshold");
            internal static readonly int _MaskTex = Shader.PropertyToID("_MaskTex");
            internal static readonly int _Curve = Shader.PropertyToID("_Curve");
            internal static readonly int _PrefilterOffs = Shader.PropertyToID("_PrefilterOffs");
            internal static readonly int _SampleScale = Shader.PropertyToID("_SampleScale");
            internal static readonly int _Intensity = Shader.PropertyToID("_Intensity");
            internal static readonly int _BloomParams = Shader.PropertyToID("_BloomParams");
        }
        private const int kMaxPyramidBlurLevel = 3;

        [SerializeField]
        public bool renderSceneBloom = false;

        [SerializeField]
        public bool renderCharBloom = true;

        [System.NonSerialized]
        public float intensity = 1;

        [System.NonSerialized]
        public float threshold = 0.6f;

        public float thresholdLinear
        {
            set { threshold = Mathf.LinearToGammaSpace(value); }
            get
            {
                return Mathf.GammaToLinearSpace(threshold);
            }
        }

        [Range(0f, 1f), Tooltip("Makes transition between under/over-threshold gradual (0 = hard threshold, 1 = soft threshold).")]
        [System.NonSerialized]
        public float softKnee = 1f;

        [Range(1f, 7f), Tooltip("Changes extent of veiling effects in a screen resolution-independent fashion.")]
        [System.NonSerialized]
        public float radius = 4;

        private readonly RenderTexture[] m_BlurBuffer1 = new RenderTexture[kMaxPyramidBlurLevel];
        private readonly RenderTexture[] m_BlurBuffer2 = new RenderTexture[kMaxPyramidBlurLevel];

        private Camera _mainCamera;
        //需要渲染的模型
        private static List<Renderer> _modelRendererList = new List<Renderer>();
        private static Dictionary<Renderer, Material[]> _modelMaterialsList = new Dictionary<Renderer, Material[]>();


        private RenderTexture _maskRenderTex;
        private Material _bloomMaterial;

        [Range(0, 1)]
        public float distorIntensity = 1;
        [Range(50, 150)]
        public float samplingRange = 150;

        [Range(0,3)]
        public float bloomSize = 1.0f;
        [Range(0,10)]
        public float bloomIntensity = 2.5f;

        protected RenderTextureFormat rtFormat;
        private Shader standardShaer;
        private CommandBuffer _drawingCommandBuffer;

        private bool enableBloom
        {
            get
            {
                return true;
            }
        }

        private void GenerateBloomRT()
        {
            if (_maskRenderTex != null)
            {
                RenderTexture.ReleaseTemporary(_maskRenderTex);
                _maskRenderTex = null;
            }

            //申请RT
            _maskRenderTex = RenderTexture.GetTemporary(Screen.width, Screen.height, 16, rtFormat);
            _maskRenderTex.filterMode = FilterMode.Bilinear;
            _maskRenderTex.wrapMode = TextureWrapMode.Clamp;

        }

        public void Reset(Camera mainCamera)
        {
            if (_drawingCommandBuffer != null && _mainCamera != null)
                _mainCamera.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, _drawingCommandBuffer);

            _mainCamera = mainCamera;

            if (_drawingCommandBuffer == null)
            {
                _drawingCommandBuffer = new CommandBuffer()
                {
                    name = "Bloom"
                };
            }
            else
            {
                _drawingCommandBuffer.Clear();
            }

            if (_mainCamera != null)
            {
                _mainCamera.AddCommandBuffer(CameraEvent.BeforeImageEffects, _drawingCommandBuffer);
            }
        }

        private void Awake()
        {
            _mainCamera = GetComponent<Camera>();
            GenerateBloomRT();
            Reset(_mainCamera);
            rtFormat = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RGB565) ? RenderTextureFormat.RGB565 : RenderTextureFormat.Default;
            ClearRenderer();
        }

        private void Update()
        {
            if (_modelRendererList.Count == 0 || !enableBloom) {
                return;
            }

            GenerateBloomRT();

            _drawingCommandBuffer.Clear();
            
            //Reset(_mainCamera);
            //设置Command Buffer渲染目标为申请的RT
            _drawingCommandBuffer.SetRenderTarget(_maskRenderTex);
            //初始颜色设置为灰色
            _drawingCommandBuffer.ClearRenderTarget(true, true, Color.black);
            //申请RT
            foreach (Renderer render in _modelRendererList)
            { 
                if (render != null)
                {
                    Material[] materials = null;
                    materials = _modelMaterialsList[render];
                    if (_modelMaterialsList.TryGetValue(render, out materials))
                    {
                        for (int i = 0; i < materials.Length; i++)
                        {
                            if (materials[i] != null)
                            {
                                var p = materials[i].FindPass("BLOOM");
                                if (p >= 0)
                                {
                                    _drawingCommandBuffer.DrawRenderer(render, render.materials[i], i, p);
                                }
                                if (materials[i].shader.name == "streetball2/MeshEmission")
                                {
                                    _drawingCommandBuffer.DrawRenderer(render, render.materials[i], i, 0);
                                }
                            }
                        }
                    }
                }   
            }
        }


        private void OnEnable()
        {
            if (!enableBloom)
                return;
            var shader = Shader.Find("streetball2/bloom");
            _bloomMaterial = new Material(shader);
            _bloomMaterial.SetVector(Uniforms._BloomParams, new Vector4(bloomSize, bloomIntensity, 0, 0));
        }

        public static void AddRenderer(Renderer renderer)
        {
            if (_modelRendererList.Contains(renderer))
            {
                UpdateRender(renderer);
                return;
            }
            _modelRendererList.Add(renderer);
            _modelMaterialsList.Add(renderer, renderer.sharedMaterials);
        }

        public void RemoveRenderer(Renderer renderer)
        {
            if (_modelRendererList.Contains(renderer))
            {
                _modelRendererList.Remove(renderer);
                _modelMaterialsList.Remove(renderer);
            } 
        }

        public static void UpdateRender(Renderer renderer)
        {
            if (_modelMaterialsList.ContainsKey(renderer))
            {
                _modelMaterialsList[renderer] = renderer.sharedMaterials;
            }
        }

        public static void ClearRenderer()
        {
            if (_modelRendererList!= null)
            {
                _modelRendererList.Clear();
            }
            if (_modelMaterialsList != null)
            {
                _modelMaterialsList.Clear();
            }
        }

        private void OnDisable()
        {
            //移除事件，清理资源
            if (_drawingCommandBuffer != null && _mainCamera != null)
            {
                _mainCamera.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, _drawingCommandBuffer);
                _drawingCommandBuffer.Clear();
            }

            if (_maskRenderTex != null)
            {
                RenderTexture.ReleaseTemporary(_maskRenderTex);
                _maskRenderTex = null;
            }
        }

        private void OnDestroy()
        {
            if (_bloomMaterial != null)
            {
                DestroyImmediate(_bloomMaterial);
                _bloomMaterial = null;
            }
            if (_drawingCommandBuffer != null && _mainCamera != null)
            {
                _mainCamera.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, _drawingCommandBuffer);
                _drawingCommandBuffer = null;
            }
        }

        //bloom
        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            if (!enableBloom || _maskRenderTex == null)
            {
                // TODO 优化 Blit
                Graphics.Blit(source, destination);
                return;
            }

            _bloomMaterial.SetVector(Uniforms._BloomParams, new Vector4(bloomSize, bloomIntensity, 0, 0));
            var tw = Screen.width / 2;
            var th = Screen.height / 2;

            _bloomMaterial.SetFloat(Uniforms._Intensity, intensity);

            float logh = Mathf.Log(th, 2f) + radius - 8f;
            int logh_i = (int)logh;

            int iterations = Mathf.Clamp(logh_i, 1, kMaxPyramidBlurLevel);  //迭代次数

            float sampleScale = 0.5f + logh - logh_i;
            // _bloomMaterial.SetTexture(Uniforms._MaskTex, _maskRenderTex);  //设置遮罩图
            _bloomMaterial.SetFloat(Uniforms._SampleScale, sampleScale);  //采样缩放
            //新建一张rendertexture , 并将当前摄像机渲染的图像  经过第一个pss 复制到 rendertexture 上。

            var last = _maskRenderTex;
            //降采样
            for (int level = 0; level < iterations; level++)
            {
                //第二个pass 把 提取的亮度图 等比例缩小
                m_BlurBuffer1[level] = RenderTexture.GetTemporary(last.width / 2, last.height / 2, 0, RenderTextureFormat.ARGB32);
                m_BlurBuffer1[level].filterMode = FilterMode.Bilinear;
                int pass = (level == 0) ? 1 : 2;
                Graphics.Blit(last, m_BlurBuffer1[level], _bloomMaterial, 0);
                last = m_BlurBuffer1[level];
            }


            //高斯
            RenderTexture temp = RenderTexture.GetTemporary(last.width, last.height, 0);
            Graphics.Blit(last, temp, _bloomMaterial, 1);
            Graphics.Blit(temp, last, _bloomMaterial, 2);
            RenderTexture.ReleaseTemporary(temp);

            //升采样
            for (int level = iterations - 1; level >= 0; level--)
            {

                var baseTex = last;
                _bloomMaterial.SetTexture(Uniforms._BaseTex, m_BlurBuffer1[level]);
                m_BlurBuffer2[level] = RenderTexture.GetTemporary(m_BlurBuffer1[level].width, m_BlurBuffer1[level].height, 0, rtFormat);
                Graphics.Blit(last, m_BlurBuffer2[level], _bloomMaterial, 3);
                last = m_BlurBuffer2[level];
            }

            var bloomTex = last;
            //释放RT
            for (int i = 0; i < kMaxPyramidBlurLevel; i++)
            {
                if (m_BlurBuffer1[i] != null)
                    RenderTexture.ReleaseTemporary(m_BlurBuffer1[i]);

                if (m_BlurBuffer2[i] != null && m_BlurBuffer2[i] != bloomTex)
                    RenderTexture.ReleaseTemporary(m_BlurBuffer2[i]);

                m_BlurBuffer1[i] = null;
                m_BlurBuffer2[i] = null;
            }

            _bloomMaterial.SetTexture(Uniforms._BloomTex, bloomTex);
            Graphics.Blit(source, destination, _bloomMaterial, 4);
            RenderTexture.ReleaseTemporary(bloomTex);
        }
    }
}