/***
 * 修改自 http://wiki.unity3d.com/index.php/MirrorReflection4
 */
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// This is in fact just the Water script from Pro Standard Assets,
// just with refraction stuff removed.

public class MirrorReflection : MonoBehaviour
{
    public Camera m_SrcCamera = null;

    private Camera m_ReflectionCamera = null;
    public MeshRenderer m_TargetRender = null;

    public Shader m_ReplacementShader = null;

    public bool m_DisablePixelLights = true;
    public int m_TextureSize = 256;
    public float m_ClipPlaneOffset = 0.07f;
    public LayerMask m_ReflectLayers = -1;

    private RenderTexture m_ReflectionTexture = null;
    private static bool s_InsideRendering = false;

    public bool m_IsUseMeshUpDirAsRefPlaneNormal = false; //是否使用mesh的up方向作为反射平面法线
    public Vector3 m_ReflectionPlaneNormal = Vector3.up;
    
    public static MirrorReflection Instance = null;

    private void Awake()
    {
        if (Instance != null)
        {
            Debug.LogError("MirrorReflection.Awake:存在多个实例");
            Destroy(gameObject);
            return;
        }
        Instance = this;
        
        //
        m_ReflectionTexture = new RenderTexture(m_TextureSize, m_TextureSize, 16);
        m_ReflectionTexture.name = "__MirrorReflection" + GetInstanceID();
        m_ReflectionTexture.isPowerOfTwo = true;
        m_ReflectionTexture.hideFlags = HideFlags.DontSave;

        if (m_TargetRender == null)
        {
            m_TargetRender = GetComponent<MeshRenderer>();
        }

        m_TargetRender.material.SetTexture("_ReflectionTex", m_ReflectionTexture);
    }

    private void Start()
    {
        
    }

    private void OnDestroy()
    {
        if (Instance != this)
        {
            return;
        }

        if (m_ReflectionTexture != null)
        {
            m_ReflectionTexture.Release();
            m_ReflectionTexture = null;
        }

        if (m_ReflectionCamera != null)
        {
            Destroy(m_ReflectionCamera);
            m_ReflectionCamera = null;
        }

        Instance = null;
    }
    
    // This is called when it's known that the object will be rendered by some
    // camera. We render reflections and do other updates here.
    // Because the script executes in edit mode, reflections for the scene view
    // camera will just work!
    private void OnWillRenderObject()
    {
        if (m_SrcCamera == null) m_SrcCamera = Camera.main;
        if (m_SrcCamera == null) return;

        if (m_ReflectionCamera == null)
        {
            m_ReflectionCamera = CreateReflectionCamera(m_SrcCamera);
            m_ReflectionCamera.targetTexture = m_ReflectionTexture;
        }
        
        Camera cam = m_SrcCamera;

        // Safeguard from recursive reflections.        
        if (s_InsideRendering)
            return;
        s_InsideRendering = true;

        Camera reflectionCamera = m_ReflectionCamera;

        // find out the reflection plane: position and normal in world space
        Vector3 pos = transform.position;

        Vector3 normal = m_ReflectionPlaneNormal;
        if (m_IsUseMeshUpDirAsRefPlaneNormal)
        {
            normal = transform.up;
        }

        // Optionally disable pixel lights for reflection
        int oldPixelLightCount = QualitySettings.pixelLightCount;
        if (m_DisablePixelLights)
            QualitySettings.pixelLightCount = 0;
        
        UpdateCameraModes(cam, reflectionCamera);
        reflectionCamera.cullingMask = ~(1 << 4) & m_ReflectLayers.value; // never render water layer

        // Render reflection
        // Reflect camera around reflection plane
        float d = -Vector3.Dot(normal, pos) - m_ClipPlaneOffset;
        Vector4 reflectionPlane = new Vector4(normal.x, normal.y, normal.z, d);

        Matrix4x4 reflection = Matrix4x4.zero;
        CalculateReflectionMatrix(ref reflection, reflectionPlane);
        Vector3 oldpos = cam.transform.position;
        Vector3 newpos = reflection.MultiplyPoint(oldpos);
        reflectionCamera.worldToCameraMatrix = cam.worldToCameraMatrix * reflection;
        
        // Setup oblique projection matrix so that near plane is our reflection
        // plane. This way we clip everything below/above it for free.
        Vector4 clipPlane = CameraSpacePlane(reflectionCamera, pos, normal, 1.0f);
        //Matrix4x4 projection = cam.projectionMatrix;
        //CalculateObliqueMatrix(ref projection, clipPlane);

        Matrix4x4 projection = cam.CalculateObliqueMatrix(clipPlane);
        reflectionCamera.projectionMatrix = projection;

        GL.invertCulling = true;
        reflectionCamera.transform.position = newpos;
        Vector3 euler = cam.transform.eulerAngles;
        reflectionCamera.transform.eulerAngles = new Vector3(0, euler.y, euler.z);
        
        if (m_ReplacementShader != null)
        {
            reflectionCamera.RenderWithShader(m_ReplacementShader, null);
        }
        else
        {
            reflectionCamera.Render();
        }

        GL.invertCulling = false;

        // Restore pixel light count
        if (m_DisablePixelLights)
            QualitySettings.pixelLightCount = oldPixelLightCount;

        s_InsideRendering = false;
    }

    private void UpdateCameraModes(Camera src, Camera dest)
    {
        if (dest == null)
            return;
        // set camera to clear the same way as current camera
        dest.clearFlags = src.clearFlags;
        dest.backgroundColor = src.backgroundColor;
        if (src.clearFlags == CameraClearFlags.Skybox)
        {
            Skybox sky = src.GetComponent(typeof(Skybox)) as Skybox;
            Skybox mysky = dest.GetComponent(typeof(Skybox)) as Skybox;
            if (!sky || !sky.material)
            {
                mysky.enabled = false;
            }
            else
            {
                mysky.enabled = true;
                mysky.material = sky.material;
            }
        }
        // update other values to match current camera.
        // even if we are supplying custom camera&projection matrices,
        // some of values are used elsewhere (e.g. skybox uses far plane)
        dest.farClipPlane = src.farClipPlane;
        dest.nearClipPlane = src.nearClipPlane;
        dest.orthographic = src.orthographic;
        dest.fieldOfView = src.fieldOfView;
        dest.aspect = src.aspect;
        dest.orthographicSize = src.orthographicSize;
    }
    
    // On-demand create any objects we need
    private Camera CreateReflectionCamera(Camera currentCamera)
    {
        GameObject go = new GameObject("Mirror Refl Camera id" + GetInstanceID() + " for " + currentCamera.GetInstanceID(), typeof(Camera), typeof(Skybox));
        Camera reflectionCamera = go.GetComponent<Camera>();
        reflectionCamera.enabled = false;
        reflectionCamera.transform.position = transform.position;
        reflectionCamera.transform.rotation = transform.rotation;
        //reflectionCamera.gameObject.AddComponent<FlareLayer>();
        //go.hideFlags = HideFlags.HideAndDontSave;
        reflectionCamera.cullingMask = ~(1 << 4) & m_ReflectLayers.value; // never render water layer

        return reflectionCamera;
    }

    // Extended sign: returns -1, 0 or 1 based on sign of a
    private static float sgn(float a)
    {
        if (a > 0.0f) return 1.0f;
        if (a < 0.0f) return -1.0f;
        return 0.0f;
    }

    // Given position/normal of the plane, calculates plane in camera space.
    private Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign)
    {
        Vector3 offsetPos = pos + normal * m_ClipPlaneOffset;
        Matrix4x4 m = cam.worldToCameraMatrix;
        Vector3 cpos = m.MultiplyPoint(offsetPos);
        Vector3 cnormal = m.MultiplyVector(normal).normalized * sideSign;
        return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
    }

    // 调整给定的投影矩阵，所以近平面就是剪切平面。（Adjusts the given projection matrix so that near plane is the given clipPlane）
    // 剪切平面在相机空间里给出了，具体可以参考《游戏编程精粹5》中的一篇文章。（clipPlane is given in camera space. See article in Game Programming Gems 5.）
    private static void CalculateObliqueMatrix(ref Matrix4x4 projection, Vector4 clipPlane)
    {
        Vector4 q = projection.inverse * new Vector4
        (sgn(clipPlane.x),
            sgn(clipPlane.y),
            1.0f,
            1.0f);

        Vector4 c = clipPlane * (2.0F / (Vector4.Dot(clipPlane, q)));
        // 第三行=剪切平面-第四行（third row = clip plane - fourth row）
        projection[2] = c.x - projection[3];
        projection[6] = c.y - projection[7];
        projection[10] = c.z - projection[11];
        projection[14] = c.w - projection[15];
    }

    // Calculates reflection matrix around the given plane
    private static void CalculateReflectionMatrix(ref Matrix4x4 reflectionMat, Vector4 plane)
    {
        reflectionMat.m00 = (1F - 2F * plane[0] * plane[0]);
        reflectionMat.m01 = (-2F * plane[0] * plane[1]);
        reflectionMat.m02 = (-2F * plane[0] * plane[2]);
        reflectionMat.m03 = (-2F * plane[3] * plane[0]);

        reflectionMat.m10 = (-2F * plane[1] * plane[0]);
        reflectionMat.m11 = (1F - 2F * plane[1] * plane[1]);
        reflectionMat.m12 = (-2F * plane[1] * plane[2]);
        reflectionMat.m13 = (-2F * plane[3] * plane[1]);

        reflectionMat.m20 = (-2F * plane[2] * plane[0]);
        reflectionMat.m21 = (-2F * plane[2] * plane[1]);
        reflectionMat.m22 = (1F - 2F * plane[2] * plane[2]);
        reflectionMat.m23 = (-2F * plane[3] * plane[2]);

        reflectionMat.m30 = 0F;
        reflectionMat.m31 = 0F;
        reflectionMat.m32 = 0F;
        reflectionMat.m33 = 1F;
    }

    public void SetSrcCamera(Camera cam)
    {
        m_SrcCamera = cam;
    }
}