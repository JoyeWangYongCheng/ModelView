using UnityEngine;
using UnityEditor;
using System;


public class Lmd_standard_GUI : ShaderGUI
{
    //protected bool isNormalMap = false;
    public enum BlendMode
    {
        Opaque,
        Cutout,
        Transparent, // Physically plausible transparency mode, implemented as alpha pre-multiply
        Custom
    }

    public enum TypeUseMode
    {
        CHAR,
        SCENE
    }

    private static class Styles
    {
        public static GUIContent alphaCutoffText = new GUIContent("Alpha Cutoff", "Threshold for alpha cutoff");
        public static GUIContent depthWriteText = new GUIContent("Depth Write", "Is Depth Write?");
        public static string renderingMode = "Rendering Mode";
        public static string typeUse = "Type";
        public static readonly string[] blendNames = Enum.GetNames(typeof(BlendMode));
        public static readonly string[] typeUseNames = Enum.GetNames(typeof(TypeUseMode));
    }

    MaterialProperty blendMode = null;
    MaterialProperty alphaCutoff = null;
    MaterialProperty depthWrite = null;
    MaterialProperty typeUse = null;
    MaterialEditor m_MaterialEditor;


    bool m_FirstTimeApply = true;
    public void FindProperties(MaterialProperty[] props)
    {
        blendMode = FindProperty("_Mode", props);
        alphaCutoff = FindProperty("_Cutoff", props);
        depthWrite = FindProperty("_ZWrite", props);
        typeUse = FindProperty("_TypeUse", props);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        // render the default gui
        FindProperties(props);
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        //if (m_FirstTimeApply)
        //{
        //    Debug.Log("材质球是否改变01");
        //    MaterialChanged(material);
        //    m_FirstTimeApply = false;
        //}
        ShaderPropertiesGUI(material);

        base.OnGUI(materialEditor, props);

        bool isNormalMap = material.GetTexture("_BumpMap") != null;
        if (isNormalMap)
            material.EnableKeyword("_NORMALMAP");
        else
            material.DisableKeyword("_NORMALMAP");

        if (material.IsKeywordEnabled("_HQCSM_ON_"))
            material.DisableKeyword("_HQCSM_ON_");

        if (material.IsKeywordEnabled("_ZWRITE_ON"))
            material.DisableKeyword("_ZWRITE_ON");

        if (material.IsKeywordEnabled("_SSSENABLE_ON"))
            material.DisableKeyword("_SSSENABLE_ON");

        SetMaterialTypeUse(material, typeUse.floatValue);
    }

    public void ShaderPropertiesGUI(Material material)
    {
        // Detect any changes to the material
        EditorGUI.BeginChangeCheck();
        {
            BlendModePopup();

            TypeUsePopup(material);

            DoAlbedoArea(material);

            EditorGUILayout.Space();
        }
        if (EditorGUI.EndChangeCheck())
        {
            Debug.Log("材质球是否改变02");
            foreach (var obj in blendMode.targets)
                MaterialChanged((Material)obj);
        }

        EditorGUILayout.Space();


        //m_MaterialEditor.EnableInstancingField();
        //m_MaterialEditor.DoubleSidedGIField();
    }
    public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
    {
        base.AssignNewShaderToMaterial(material, oldShader, newShader);
        Debug.Log("材质球是否改变03");
        MaterialChanged(material);
    }
    void BlendModePopup()
    {
        EditorGUI.showMixedValue = blendMode.hasMixedValue;
        var mode = (BlendMode)blendMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (BlendMode)EditorGUILayout.Popup(Styles.renderingMode, (int)mode, Styles.blendNames);
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
            blendMode.floatValue = (float)mode;
        }

        EditorGUI.showMixedValue = false;
    }

    void TypeUsePopup(Material material)
    {
        EditorGUI.showMixedValue = typeUse.hasMixedValue;
        var value = (TypeUseMode)typeUse.floatValue;

        EditorGUI.BeginChangeCheck();
        value = (TypeUseMode)EditorGUILayout.Popup(Styles.typeUse, (int)value, Styles.typeUseNames);
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Type Use Mode");
            typeUse.floatValue = (float)value;
            SetMaterialTypeUse(material, typeUse.floatValue);
        }

        EditorGUI.showMixedValue = false;
    }

    void DoAlbedoArea(Material material)
    {
        if (((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout))
        {
            m_MaterialEditor.ShaderProperty(alphaCutoff, Styles.alphaCutoffText.text, MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);
        }
        if (((BlendMode)material.GetFloat("_Mode") == BlendMode.Transparent))
        {
            m_MaterialEditor.ShaderProperty(depthWrite, Styles.depthWriteText.text, MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);
        }
    }
    public  void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
    {
        Debug.Log("设置材质球混合模式");
        switch (blendMode)
        {
            case BlendMode.Opaque:
                material.SetOverrideTag("RenderType", "");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                material.DisableKeyword("USE_ALPHA_TEST_ON");
                material.DisableKeyword("USE_ALPHA_BLEND_ON");

                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
                break;
            case BlendMode.Cutout:
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                material.EnableKeyword("USE_ALPHA_TEST_ON");
                material.DisableKeyword("USE_ALPHA_BLEND_ON");

                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                break;
            case BlendMode.Transparent:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                //material.SetInt("_ZWrite", 0);
                material.DisableKeyword("USE_ALPHA_TEST_ON");
                material.EnableKeyword("USE_ALPHA_BLEND_ON");

                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.Custom:
                if (material.renderQueue >= 2999)
                {
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    //material.SetInt("_ZWrite", 0);
                    material.DisableKeyword("USE_ALPHA_TEST_ON");
                    material.EnableKeyword("USE_ALPHA_BLEND_ON");
                }
                else if (material.renderQueue >= 2450 && material.renderQueue < 2999)
                {
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.EnableKeyword("USE_ALPHA_TEST_ON");
                    material.DisableKeyword("USE_ALPHA_BLEND_ON");
                }
                else if (material.renderQueue < 2450) {
                    material.SetOverrideTag("RenderType", "");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.DisableKeyword("USE_ALPHA_TEST_ON");
                    material.DisableKeyword("USE_ALPHA_BLEND_ON");
                }
                break;
        }
    }

    protected void SetMaterialTypeUse(Material material, float typeUse)
    {
        if (typeUse== 0)
        {
            material.EnableKeyword("TYPE_CHAR");
            material.DisableKeyword("TYPE_SCENE");
        }
        else
        {
            material.EnableKeyword("TYPE_SCENE");
            material.DisableKeyword("TYPE_CHAR");
        }
    }

    protected void MaterialChanged(Material material)
    {
        SetupMaterialWithBlendMode(material, (BlendMode)material.GetFloat("_Mode"));
        SetMaterialTypeUse(material,material.GetFloat("_TypeUse"));
    }
}
