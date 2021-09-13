using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerShaderFixTool : MonoBehaviour
{
    public Material _skinMaterial;
    public Light _mainLight;

    private static List<Color> _tempColor = new List<Color>();

    private List<Material> _materials = new List<Material>();

    private void Start()
    {
        if (_mainLight == null)
        {
            var lights = Resources.FindObjectsOfTypeAll<Light>();
            foreach (var light in lights)
            {
                if (((light.hideFlags & HideFlags.HideInHierarchy) == 0) && light.type == LightType.Directional)
                {
                    _mainLight = light;
                    break;
                }
            }
        }

        Material skinMaterial = null;
        if (_skinMaterial != null)
        {
            skinMaterial = new Material(_skinMaterial);
            var skinShader = PlayerShaderHolder.instance.FindShader("streetball2/model_skin");
            if (skinShader != null)
            {
                skinMaterial.shader = skinShader;
            }
            _materials.Add(skinMaterial);
        }
        var renderers = GetComponentsInChildren<Renderer>(true);
        foreach (var renderer in renderers)
        {
            var material = renderer.sharedMaterial;
            if (material.GetTexture("_MainTex") != null)
            {
                var name = material.shader.name;
                var hair = material.HasProperty("_AnisoEnable") && material.GetFloat("_AnisoEnable") > 0;
                var skin = material.HasProperty("_SSSEnable") && material.GetFloat("_SSSEnable") > 0;
                var fixName = (hair ? "streetball2/model_hair" : (skin ? "streetball2/model_skin" : "streetball2/model"));
                var shader = PlayerShaderHolder.instance.FindShader(fixName);
                if (shader != null)
                {
                    renderer.material = new Material(material);
                    renderer.material.shader = shader;
                }
                _materials.Add(renderer.material);
            }
            if (skinMaterial != null && renderer is SkinnedMeshRenderer)
            {
                if (material.GetTexture("_MainTex") != null)
                {
                    var skinnedMeshRenderer = renderer as SkinnedMeshRenderer;
                    if (skinnedMeshRenderer.sharedMesh.subMeshCount > 1)
                    {
                        var index = skinnedMeshRenderer.sharedMesh.GetIndexStart(0);
                        skinnedMeshRenderer.sharedMesh.GetColors(_tempColor);
                        if (_tempColor[(int)index].r > 0.1f)
                        {
                            renderer.materials = new Material[2] { renderer.material, skinMaterial };
                        }
                        else
                        {
                            renderer.materials = new Material[2] { skinMaterial, renderer.material };
                        }
                    }
                }
                else
                {
                    renderer.material = skinMaterial;
                }
            }
        }
    }

    private void Update()
    {
        if (_mainLight != null)
        {
            foreach (var materil in _materials)
            {
                materil.SetVector("_LightDir", -_mainLight.transform.forward);
                materil.SetColor("_LightColor", _mainLight.color);
            }
        }
    }
}