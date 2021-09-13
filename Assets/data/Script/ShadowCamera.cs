using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Framework;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

public class ShadowCamera : MonoBehaviour
{
    private static int kCharShadowMap = Shader.PropertyToID("_HQCharShadowmap");
    private static int kCharShadowMapTranparent = Shader.PropertyToID("_HQCharShadowmapTransparent");
    private static int kCharShadowCameraParams = Shader.PropertyToID("_HQCharCameraParams");
    private static int kCharCameraVP = Shader.PropertyToID("_HQCharCameraVP");
    private static int kCharShadowMapSize = Shader.PropertyToID("_HQCharShadowmapSize");
    private static int kLightBias = Shader.PropertyToID("_Bias");
    private static RenderTextureFormat SHADOWMAP_FORMAT = RenderTextureFormat.ARGB32;
    private static int SHADOWMAP_DEPTH_BITS = 16;

    private static ShadowCamera instance
    {
        get
        {
            if (_instance == null && !_shutdone)
            {
                var go = new GameObject("ShadowCamera");
                _instance = go.AddComponent<ShadowCamera>();
            }
            return _instance;
        }
    }

    private static ShadowCamera _instance;
    private static bool _shutdone = false;

    public void OnApplicationQuit()
    {
        _shutdone = true;
    }

    public static bool support
    {
        get
        {
            return true;
        }
    }

    private enum ERenderType
    {
        Opaque,
        Transparent,
    }

    private struct RendererData
    {
        public ERenderType type;
        public Material _material;
        public int _meshIdx;
    }

    public enum ShadowQuality
    {
        LOW = 128,
        MID = 256,
        HIGH = 512,
        VERY_HIGH = 1024,
    }

    public enum DepthBits
    {
        DEPTH_16 = 16,
        DEPTH_24 = 24
    }

    public bool _DEBUG_ON = false;
    public bool m_supportTransparent = false;
    public bool SupportTransparent
    {
        get { return m_supportTransparent; }
        set
        {
            if (m_supportTransparent != value)
            {
                m_supportTransparent = value;
                GenerateShadowTextures();
            }
        }
    }

    public bool Use32BitsDepth
    {
        get { return use32BitsDepth; }
        set
        {
            if (use32BitsDepth != value)
            {
                use32BitsDepth = value;
                GenerateShadowTextures();
            }
        }
    }

    public ShadowQuality CharShadowQuality
    {
        get { return shadowQuality; }
        set
        {
            if (shadowQuality != value)
            {
                shadowQuality = value;
                GenerateShadowTextures();
            }
        }
    }

    public RenderTexture CharShadowMap
    {
        get { return _charShadowMap; }
    }

    public RenderTexture CharShadowMapTranparent
    {
        get { return _charShadowMapTranparent; }
    }

    public bool use32BitsDepth = false;
    public float lightBias = 0.003f;
    public bool fixedFrustum = false;
    public float size = 5;
    public float near = -1;
    public float far = 1;
    public ShadowQuality shadowQuality = ShadowQuality.VERY_HIGH;

    private Camera _mainCamera;
    private Light _mainLight;
    private Camera _lightCamera;
    private RenderTexture _charShadowMap;
    private RenderTexture _charShadowMapTranparent;
    private CommandBuffer _drawingCommandBuffer;
    private Dictionary<Renderer, List<RendererData>> _rendererDataDict = new Dictionary<Renderer, List<RendererData>>();
    private Transform _groundRenderer;
    private float _groundRendererY;
    private Material _shadowMaterial;

    private void OnQualityChanged()
    {
        shadowQuality = ShadowQuality.VERY_HIGH;
    }

    private void GenerateShadowTextures()
    {
        if (_charShadowMapTranparent != null)
        {
            RenderTexture.ReleaseTemporary(_charShadowMapTranparent);
            _charShadowMapTranparent = null;
        }

        if (_charShadowMap != null)
        {
            RenderTexture.ReleaseTemporary(_charShadowMap);
            _charShadowMap = null;
        }

        int SHADOWMAP_SIZE = (int)shadowQuality;
        if (m_supportTransparent)
        {
            _charShadowMapTranparent = RenderTexture.GetTemporary(SHADOWMAP_SIZE, SHADOWMAP_SIZE, SHADOWMAP_DEPTH_BITS, SHADOWMAP_FORMAT);
            _charShadowMapTranparent.wrapMode = TextureWrapMode.Clamp;
            _charShadowMapTranparent.filterMode = FilterMode.Point;
            _charShadowMapTranparent.autoGenerateMips = false;
            Shader.SetGlobalTexture(kCharShadowMapTranparent, _charShadowMapTranparent);
            Shader.EnableKeyword("_HQCSM_SUPPORT_TRANSPARENT_");
        }
        else
        {
            Shader.DisableKeyword("_HQCSM_SUPPORT_TRANSPARENT_");
        }


        if (use32BitsDepth)
        {
            _charShadowMap = RenderTexture.GetTemporary(SHADOWMAP_SIZE, SHADOWMAP_SIZE, SHADOWMAP_DEPTH_BITS, SHADOWMAP_FORMAT);
            Shader.DisableKeyword("_HQCSM_USE_NATIVE_DEPTH_");
        }
        else
        {
            _charShadowMap = RenderTexture.GetTemporary(SHADOWMAP_SIZE, SHADOWMAP_SIZE, SHADOWMAP_DEPTH_BITS, RenderTextureFormat.Depth);
            Shader.EnableKeyword("_HQCSM_USE_NATIVE_DEPTH_");
        }

        _charShadowMap.wrapMode = TextureWrapMode.Clamp;
        _charShadowMap.filterMode = FilterMode.Point;
        _charShadowMap.autoGenerateMips = false;
        Shader.SetGlobalTexture(kCharShadowMap, _charShadowMap);
        Shader.SetGlobalFloat(kCharShadowMapSize, _charShadowMap.width);
    }

    private void Awake()
    {
        Shader.EnableKeyword("_HQCSM_ON_");
        GenerateShadowTextures();
        _shadowMaterial = new Material(Shader.Find("DynamicShadow/ShadowDepth"));
    }

    private void OnEnable()
    {
        OnQualityChanged();
    }

    public static void ResetGroundRendererY(float groundRendererY)
    {
        if (instance != null)
        {
            instance._groundRendererY = groundRendererY;
        }
    }

    public static void Reset(Light light, Camera mainCamera, Transform groundRenderer, float groundRender)
    {
        if (instance != null)
        {
            instance._Reset(light, mainCamera, groundRenderer, groundRender);
        }
    }

    public static void ClearSet()
    {
        if (instance != null)
        {
            instance._lightCamera = null;
            instance._mainLight = null;
            instance._mainCamera = null;
            instance._groundRenderer = null;
        }
    }

    private void _Reset(Light light, Camera mainCamera, Transform groundRenderer, float groundRendererY)
    {
        _groundRenderer = groundRenderer;
        if (_groundRenderer != null)
        {
            _groundRenderer.gameObject.SetActive(false);
        }
        _groundRendererY = groundRendererY;
        if (_drawingCommandBuffer != null && _mainCamera != null)
            _mainCamera.RemoveCommandBuffer(CameraEvent.BeforeForwardOpaque, _drawingCommandBuffer);
        _mainLight = light;
        _mainCamera = mainCamera;
        if (_mainLight == null) return;
        _lightCamera = _mainLight.GetComponent<Camera>();
        if (_lightCamera == null) return;
        if (_drawingCommandBuffer == null)
        {
            _drawingCommandBuffer = new CommandBuffer()
            {
                name = "HQ Char Shadow"
            };
        }
        else
        {
            _drawingCommandBuffer.Clear();
        }
        // 去除forward轴向旋转，简化后面的计算
        var lightAngles = _lightCamera.transform.eulerAngles;
        lightAngles.z = 0;
        _lightCamera.transform.rotation = Quaternion.Euler(lightAngles);

        if (_mainCamera != null)
        {
            _mainCamera.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, _drawingCommandBuffer);
        }

        SetupCamera();
    }

    private void OnDestroy()
    {
        if (_shadowMaterial != null)
        {
            Destroy(_shadowMaterial);
            _shadowMaterial = null;
        }
        if (_charShadowMapTranparent != null)
        {
            RenderTexture.ReleaseTemporary(_charShadowMapTranparent);
            _charShadowMapTranparent = null;
        }
        if (_charShadowMap != null)
        {
            RenderTexture.ReleaseTemporary(_charShadowMap);
            _charShadowMap = null;
        }
        if (_drawingCommandBuffer != null && _mainCamera != null)
        {
            _mainCamera.RemoveCommandBuffer(CameraEvent.BeforeForwardOpaque, _drawingCommandBuffer);
            _drawingCommandBuffer = null;
        }
        Shader.DisableKeyword("_HQCSM_ON_");
        _instance = null;
    }

    public static void ClearRenderer()
    {
        if (instance != null && instance._rendererDataDict != null)
        {
            instance._rendererDataDict.Clear();
        }
    }

    public static void AddRenderer(Renderer renderer)
    {
        if (instance != null)
        {
            instance._AddRenderer(renderer);
        }
    }

    private void _AddRenderer(Renderer renderer)
    {
        if (_rendererDataDict.ContainsKey(renderer))
            return;

        Material[] mats = renderer.sharedMaterials;
        if (mats.Length > 0)
        {
            List<RendererData> dataList = new List<RendererData>(mats.Length);
            for (int i = 0; i < mats.Length; i++)
            {
                var mat = mats[i];

                if (mat == null)
                    continue;

                mat.EnableKeyword("_HQCSM_ON_");
                ERenderType type;
                if (mat.GetTag("RenderType", false) == ERenderType.Opaque.ToString())
                    type = ERenderType.Opaque;
                else if (mat.GetTag("RenderType", false) == ERenderType.Transparent.ToString())
                    type = ERenderType.Transparent;
                else
                    continue;
                RendererData data = new RendererData();
                data._material = _shadowMaterial;
                data._meshIdx = i;
                data.type = type;
                dataList.Add(data);
            }
            if (dataList.Count > 0) _rendererDataDict.Add(renderer, dataList);
        }
    }

    public static void RemoveRenderer(Renderer renderer)
    {
        if (instance != null)
        {
            instance._RemoveRenderer(renderer);
        }
    }

    private void _RemoveRenderer(Renderer renderer)
    {
        if (_rendererDataDict.ContainsKey(renderer)) _rendererDataDict.Remove(renderer);
    }

    void SetupCamera()
    {
        _lightCamera.orthographic = true;
        _lightCamera.enabled = false;
        _lightCamera.backgroundColor = Color.clear;
        _lightCamera.clearFlags = CameraClearFlags.SolidColor;
        _lightCamera.useOcclusionCulling = false;
        _lightCamera.allowHDR = false;
        _lightCamera.allowMSAA = false;
    }
    public static void SetCameraOrient(Vector3 forward)
    {
        if (instance != null && instance._lightCamera != null)
        {
            instance._lightCamera.transform.forward = forward;
        }
    }


    // Update is called once per frame
    Vector3[] points = new Vector3[8];
    Vector3[] obbpoints = new Vector3[8];

    void Update()
    {
        if (_lightCamera == null || _rendererDataDict.Count == 0)
        {
            return;
        }

        GenerateShadowTextures();

        if (fixedFrustum)
        {
            _lightCamera.aspect = 1;
            _lightCamera.orthographicSize = size;
            _lightCamera.farClipPlane = far;
            _lightCamera.nearClipPlane = near;
            _lightCamera.orthographic = true;
        }
        else
        {
            Vector3 min = Vector3.positiveInfinity;
            Vector3 max = Vector3.negativeInfinity;
            min = Vector3.positiveInfinity;
            max = Vector3.negativeInfinity;

            var hasValidRenderer = false;

            foreach (var each in _rendererDataDict.Keys)
            {
                var renderer = each;

                if (renderer == null)
                {
                    continue;
                }
                if (renderer.transform.lossyScale == Vector3.zero)
                {
                    continue;
                }

                Matrix4x4 MV = _lightCamera.transform.worldToLocalMatrix;

                Bounds aabb;
                aabb = renderer.bounds;

                if (_groundRenderer != null && aabb.max.y < _groundRenderer.transform.position.y)
                {
                    continue;
                }

                hasValidRenderer = true;

                points[0] = aabb.center + new Vector3(-aabb.extents.x, -aabb.extents.y, aabb.extents.z);
                points[1] = aabb.center + new Vector3(-aabb.extents.x, -aabb.extents.y, -aabb.extents.z);
                points[2] = aabb.center + new Vector3(aabb.extents.x, -aabb.extents.y, -aabb.extents.z);
                points[3] = aabb.center + new Vector3(aabb.extents.x, -aabb.extents.y, aabb.extents.z);
                points[4] = aabb.center + new Vector3(-aabb.extents.x, aabb.extents.y, aabb.extents.z);
                points[5] = aabb.center + new Vector3(-aabb.extents.x, aabb.extents.y, -aabb.extents.z);
                points[6] = aabb.center + new Vector3(aabb.extents.x, aabb.extents.y, -aabb.extents.z);
                points[7] = aabb.center + new Vector3(aabb.extents.x, aabb.extents.y, aabb.extents.z);

                if (_DEBUG_ON)
                {
                    for (int ii = 0; ii < 8; ii++)
                    {
                        obbpoints[ii] = (points[ii]);
                    }

                    Debug.DrawLine(obbpoints[0], obbpoints[1], Color.magenta);
                    Debug.DrawLine(obbpoints[0], obbpoints[3], Color.magenta);
                    Debug.DrawLine(obbpoints[2], obbpoints[1], Color.magenta);
                    Debug.DrawLine(obbpoints[2], obbpoints[3], Color.magenta);

                    Debug.DrawLine(obbpoints[4], obbpoints[5], Color.magenta);
                    Debug.DrawLine(obbpoints[4], obbpoints[7], Color.magenta);
                    Debug.DrawLine(obbpoints[6], obbpoints[5], Color.magenta);
                    Debug.DrawLine(obbpoints[6], obbpoints[7], Color.magenta);

                    Debug.DrawLine(obbpoints[0], obbpoints[4], Color.magenta);
                    Debug.DrawLine(obbpoints[1], obbpoints[5], Color.magenta);
                    Debug.DrawLine(obbpoints[2], obbpoints[6], Color.magenta);
                    Debug.DrawLine(obbpoints[3], obbpoints[7], Color.magenta);
                    //                    return;

                }
                else
                {
                    for (int ii = 0; ii < 8; ii++)
                    {
                        obbpoints[ii] = MV.MultiplyPoint(points[ii]);
                    }

                }

                for (int pi = 0; pi < 8; pi++)
                {
                    if (_DEBUG_ON)
                    {
                        obbpoints[pi] = MV.MultiplyPoint(obbpoints[pi]);
                        //                    Debug.DrawLine(trans.position,obbpoints[pi],Color.red);
                        // obbpoints[pi] = transform.InverseTransformPoint(obbpoints[pi]);
                    }

                    min = Vector3.Min(min, obbpoints[pi]);
                    max = Vector3.Max(max, obbpoints[pi]);
                }
            }

            if (_DEBUG_ON)
            {

                //Point in camera space  
                Vector3 center = (min + max) * 0.5f;
                Bounds g_bounds = new Bounds(center, max - min);

                points[0] = g_bounds.center + new Vector3(-g_bounds.extents.x, -g_bounds.extents.y, g_bounds.extents.z);
                points[1] = g_bounds.center +
                            new Vector3(-g_bounds.extents.x, -g_bounds.extents.y, -g_bounds.extents.z);
                points[2] = g_bounds.center + new Vector3(g_bounds.extents.x, -g_bounds.extents.y, -g_bounds.extents.z);
                points[3] = g_bounds.center + new Vector3(g_bounds.extents.x, -g_bounds.extents.y, g_bounds.extents.z);
                points[4] = g_bounds.center + new Vector3(-g_bounds.extents.x, g_bounds.extents.y, g_bounds.extents.z);
                points[5] = g_bounds.center + new Vector3(-g_bounds.extents.x, g_bounds.extents.y, -g_bounds.extents.z);
                points[6] = g_bounds.center + new Vector3(g_bounds.extents.x, g_bounds.extents.y, -g_bounds.extents.z);
                points[7] = g_bounds.center + new Vector3(g_bounds.extents.x, g_bounds.extents.y, g_bounds.extents.z);

                Vector3[] frustumCS = new Vector3[8];
                for (int i = 0; i < 8; i++)
                {
                    frustumCS[i] = transform.TransformPoint(points[i]);
                }

                Debug.DrawLine(frustumCS[0], frustumCS[1], Color.cyan);
                Debug.DrawLine(frustumCS[0], frustumCS[3], Color.cyan);
                Debug.DrawLine(frustumCS[2], frustumCS[1], Color.cyan);
                Debug.DrawLine(frustumCS[2], frustumCS[3], Color.cyan);

                Debug.DrawLine(frustumCS[4], frustumCS[5], Color.cyan);
                Debug.DrawLine(frustumCS[4], frustumCS[7], Color.cyan);
                Debug.DrawLine(frustumCS[6], frustumCS[5], Color.cyan);
                Debug.DrawLine(frustumCS[6], frustumCS[7], Color.cyan);

                Debug.DrawLine(frustumCS[0], frustumCS[4], Color.cyan);
                Debug.DrawLine(frustumCS[1], frustumCS[5], Color.cyan);
                Debug.DrawLine(frustumCS[2], frustumCS[6], Color.cyan);
                Debug.DrawLine(frustumCS[3], frustumCS[7], Color.cyan);
            }

            Vector3 d = max - min;

            _lightCamera.orthographicSize = Mathf.Max(d.x, d.y) * 0.5f + 0.005f;
            _lightCamera.aspect = 1;

            _lightCamera.farClipPlane = d.z * 0.5f + _lightCamera.orthographicSize + 2.5f;
            _lightCamera.nearClipPlane = -d.z * 0.5f + _lightCamera.orthographicSize - 0.1f;
            _lightCamera.orthographic = true;

            min = _lightCamera.transform.TransformPoint(min);
            max = _lightCamera.transform.TransformPoint(max);

            if (!float.IsNaN(min.x)) {
                _lightCamera.transform.position = (max + min) * 0.5f - _lightCamera.transform.forward * _lightCamera.orthographicSize;
                if (_groundRenderer != null)
                {
                    if (hasValidRenderer)
                    {
                        _groundRenderer.rotation = Quaternion.LookRotation(Vector3.down, _lightCamera.transform.forward);
                        _groundRenderer.transform.localScale = new Vector3(_lightCamera.orthographicSize * 2,
                            _lightCamera.orthographicSize * 2 / Vector3.Dot(_lightCamera.transform.forward.normalized, _lightCamera.transform.up), 0);
                        var rendererPosition = _lightCamera.transform.position +
                                  -_lightCamera.transform.transform.forward * (_lightCamera.transform.position.y - _groundRendererY) /
                                  Vector3.Dot(-_lightCamera.transform.forward, Vector3.down);
                        rendererPosition.y = _groundRendererY + 0.002f;
                        _groundRenderer.transform.position = rendererPosition;
                    }
                    else
                    {
                        // TODO
                    }
                    if (!_groundRenderer.gameObject.activeSelf)
                    {
                        // 关闭shadowmap
                        _groundRenderer.gameObject.SetActive(false);
                    }
                }
            }
        }

        if (_DEBUG_ON)
        {
            Debug.DrawLine(transform.position, transform.position + transform.forward * 3, Color.blue);
            Vector3[] neraFrustumCorners = new Vector3[4];
            Vector3[] farFrustumCorners = new Vector3[4];
            _lightCamera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), _lightCamera.nearClipPlane, Camera.MonoOrStereoscopicEye.Mono, neraFrustumCorners);
            _lightCamera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), _lightCamera.farClipPlane, Camera.MonoOrStereoscopicEye.Mono, farFrustumCorners);

            for (int i = 0; i < 4; i++)
            {
                neraFrustumCorners[i] = _lightCamera.transform.TransformPoint(neraFrustumCorners[i]);
                farFrustumCorners[i] = _lightCamera.transform.TransformPoint(farFrustumCorners[i]);
            }
            Debug.DrawLine(neraFrustumCorners[0], farFrustumCorners[2], Color.red);
            Debug.DrawLine(neraFrustumCorners[1], farFrustumCorners[3], Color.red);
            Debug.DrawLine(neraFrustumCorners[2], farFrustumCorners[0], Color.red);
            Debug.DrawLine(neraFrustumCorners[3], farFrustumCorners[1], Color.red);

            Debug.DrawLine(neraFrustumCorners[0], neraFrustumCorners[1], Color.blue);
            Debug.DrawLine(neraFrustumCorners[1], neraFrustumCorners[2], Color.blue);
            Debug.DrawLine(neraFrustumCorners[2], neraFrustumCorners[3], Color.blue);
            Debug.DrawLine(neraFrustumCorners[3], neraFrustumCorners[0], Color.blue);

            Debug.DrawLine(farFrustumCorners[0], farFrustumCorners[1], Color.green);
            Debug.DrawLine(farFrustumCorners[1], farFrustumCorners[2], Color.green);
            Debug.DrawLine(farFrustumCorners[2], farFrustumCorners[3], Color.green);
            Debug.DrawLine(farFrustumCorners[3], farFrustumCorners[0], Color.green);

        }

        _drawingCommandBuffer.Clear();
        _drawingCommandBuffer.SetRenderTarget(_charShadowMap);
        _drawingCommandBuffer.ClearRenderTarget(true, true, Color.clear);

        var lightViewProjection =
            GL.GetGPUProjectionMatrix(_lightCamera.projectionMatrix, false) * _lightCamera.worldToCameraMatrix;
        _drawingCommandBuffer.SetViewProjectionMatrices(_lightCamera.worldToCameraMatrix, _lightCamera.projectionMatrix);

        _drawingCommandBuffer.SetGlobalVector(kCharShadowCameraParams, new Vector4(_lightCamera.orthographicSize, _lightCamera.nearClipPlane, 1.0f / _lightCamera.farClipPlane));
        _drawingCommandBuffer.SetGlobalFloat(kLightBias, lightBias);
        _drawingCommandBuffer.SetGlobalMatrix(kCharCameraVP, lightViewProjection);

        //  m_drawingCommandBuffer.EnableShaderKeyword("_OUTPUT_DEPTH_16");

        if (use32BitsDepth)
        {
            _drawingCommandBuffer.EnableShaderKeyword("_OUTPUT_DEPTH_32");
        }
        else
        {
            _drawingCommandBuffer.EnableShaderKeyword("_OUTPUT_DEPTH_16");
            //       m_drawingCommandBuffer.DisableShaderKeyword("_OUTPUT_DEPTH_32");    
        }

        foreach (var each in _rendererDataDict)
        {
            var dataList = each.Value;
            var renderer = each.Key;
            if (renderer == null)
            {
                continue;
            }
            foreach (var data in dataList)
            {
                if (data.type == ERenderType.Opaque)
                    _drawingCommandBuffer.DrawRenderer(renderer, data._material, data._meshIdx);
            }
        }

        //暂时屏蔽透明物体阴影
        //_drawingCommandBuffer.SetRenderTarget(_charShadowMapTranparent);
        //_drawingCommandBuffer.ClearRenderTarget(true, true, Color.clear);

        //foreach (var each in _rendererDataList)
        //{
        //    var dataList = each.Value;
        //    var renderer = each.Key;
        //    foreach (var data in dataList)
        //    {
        //        if (data.type == ERenderType.Transparent)
        //            _drawingCommandBuffer.DrawRenderer(renderer, data._material, data._meshIdx);
        //    }
        //}

        _drawingCommandBuffer.DisableShaderKeyword("_OUTPUT_DEPTH_16");
        _drawingCommandBuffer.DisableShaderKeyword("_OUTPUT_DEPTH_32");
    }
}
