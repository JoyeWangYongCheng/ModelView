using System.Collections;
using System.Collections.Generic;
using UnityEngine.Rendering;
using UnityEngine;

namespace flashyiyi
{
    [ExecuteInEditMode]
    public class GrowEffect : MonoBehaviour
    {
        public Material material;
        public List<MeshFilter> glowTargets;
        public Shader bloomShader;
        private Camera mCamera;

        private Material fastBloomMaterial;

        public int divider = 2;
        public float size = 3f;
        public float intensity = 1.5f;

        public bool enabledStencil = true;
        public bool putToScreen = true;


        void Awake()
        {
            mCamera = GetComponent<Camera>();
            fastBloomMaterial = new Material(bloomShader);
        }

        void OnDestroy()
        {
            DestroyImmediate(fastBloomMaterial);
        }

        private Rect quad = new Rect(0, 0, 1, 1);

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

        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            RenderTexture glow = RenderTexture.GetTemporary(source.width , source.height, 0, RenderTextureFormat.ARGB32);
            glow.filterMode = FilterMode.Bilinear;
            Graphics.SetRenderTarget(glow.colorBuffer, source.depthBuffer);//将绘制目标切换至新RT，但保留原来的深度缓存
            GL.Clear(false, true, Color.clear);

            material.SetPass(0);//设置发光材质
            foreach (MeshFilter r in glowTargets)
            {
                Graphics.DrawMeshNow(r.sharedMesh, r.transform.localToWorldMatrix);//绘制发光物体
            }

            var rtW = source.width / divider;
            var rtH = source.height / divider;

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
            
            fastBloomMaterial.SetVector("_Parameter", new Vector4(size, 0.0f, 0.0f, intensity));
           
            // downsample
            RenderTexture rt = RenderTexture.GetTemporary(rtW, rtH, 0, glow.format);
            rt.filterMode = FilterMode.Bilinear;
            DepthBlit(glow, rt, fastBloomMaterial, 1, stencil);

            // vertical blur
            RenderTexture rt2 = RenderTexture.GetTemporary(rtW, rtH, 0, glow.format);
            rt2.filterMode = FilterMode.Bilinear;
            DepthBlit(rt, rt2, fastBloomMaterial, 2, stencil);
            RenderTexture.ReleaseTemporary(rt);
            rt = rt2;

            // horizontal blur
            rt2 = RenderTexture.GetTemporary(rtW, rtH, 0, glow.format);
            rt2.filterMode = FilterMode.Bilinear;
            DepthBlit(rt, rt2, fastBloomMaterial, 3, stencil);
            RenderTexture.ReleaseTemporary(rt);
            rt = rt2;

            fastBloomMaterial.SetTexture("_Bloom", rt);
            if (putToScreen) Graphics.Blit(source, destination, fastBloomMaterial, 0);

            RenderTexture.ReleaseTemporary(rt);
            RenderTexture.ReleaseTemporary(glow);

            if (stencil != null)
                RenderTexture.ReleaseTemporary(stencil);
        }
    }
}
