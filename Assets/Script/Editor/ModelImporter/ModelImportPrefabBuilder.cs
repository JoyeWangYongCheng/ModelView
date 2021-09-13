// ==============================================
// Author：qiuyukun
// Date:2019-05-05 17:54:53
// ==============================================

using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class ModelImportPrefabBuilder
{
    public const string PREFAB_EXTENSION = ".prefab";
    private const string MAT_EXTENSION = ".mat";
    private const string FBX_EXTENSION = ".FBX";

    private string srcPath;
    private OutputReference outputreference;
    private ModelImportTextureBuilder textureBuilder;
    public Dictionary<string, PrefabInfo> prefabInfoDict = new Dictionary<string, PrefabInfo>();

    public ModelImportPrefabBuilder(string _srcPath,OutputReference _outputReference, ModelImportTextureBuilder _textureBuilder)
    {
        srcPath = _srcPath;
        outputreference = _outputReference;
        textureBuilder = _textureBuilder;
        CreateModels();
        //删除没用的prefab

    }
    private void DeleteNoUsePrefab(OutputReference _outputReference,ModelImportPrefabBuilder _prefabBuilder) {
        string[] modelFiles = Directory.GetFiles(_outputReference.modelFolderPath, "*.prefab", SearchOption.TopDirectoryOnly);
        List<string> noUsePrefabList = new List<string>();  
        //1.把所有prefab加入到集合里
        foreach (var modelFile in modelFiles)
        {
            noUsePrefabList.Add(modelFile);
        }
        //2.对比2个list 移除包含的prfab
        foreach (var modelFile in modelFiles)
        {
            foreach (var prefabFile in _prefabBuilder.prefabInfoDict) {
                if (modelFile== prefabFile.Value.prefabPath) {
                    noUsePrefabList.Remove(modelFile);
                }
            }
        }
        //3.删除多余的prefab
        foreach (var noUsePrefab in noUsePrefabList)
        {
            File.Delete(noUsePrefab);
        }
    }

    private void CreatePrefabInfo(string prefabName,string matName,string[] matFiles, GameObject fbx,FBXFileInfo fbxFileInfo) {
        PrefabInfo prefabInfo = new PrefabInfo();
        
        string prefabPath = outputreference.modelFolderPath + "/" + prefabName + PREFAB_EXTENSION;
        //3.创建材质球
        //设置贴图
        List<TextureFileInfo> texFileInfoList = new List<TextureFileInfo>();
        List<string> matPathList = new List<string>();

        //4.创建prefab
        Material mat = CreateMats(matFiles, matName, prefabPath, matPathList, texFileInfoList);
        prefabInfo.matsPath = matPathList;

        string settingFile = string.Format("{0}\\{1}{2}", srcPath, prefabName, ModelInventory.MODEL_PREFAB_SETTING_EXTENSION);
        GameObject prefab = CreatePrefab(fbx, mat, settingFile, prefabPath);
        prefabInfo.prefabName = prefabName;
        prefabInfo.prefabPath = prefabPath;
        prefabInfo.fbxFileInfo = fbxFileInfo;
        prefabInfo.textureFileInfoList = texFileInfoList;
        prefabInfoDict.Add(prefabName, prefabInfo);
    }
    //创建模型
    private void CreateModels()
    {
        var watch = new System.Diagnostics.Stopwatch();
        watch.Start();
        string[] fbxFiles = Directory.GetFiles(srcPath, "*" + FBX_EXTENSION, SearchOption.TopDirectoryOnly);
        string[] matFiles = Directory.GetFiles(outputreference.matFolderPath, "*"+ MAT_EXTENSION, SearchOption.TopDirectoryOnly);
        string[] texFolders = Directory.GetDirectories(srcPath);

        int count = fbxFiles.Length;
        for (int i = 0; i < count; ++i)
        {
            string fbxFile = fbxFiles[i].Replace("\\","/");
            EditorUtility.DisplayProgressBar("导入模型", fbxFile, (float)i / (count - 1));
            
            //1.复制模型
            FBXFileInfo fbxFileInfo = new FBXFileInfo();
            string fbxName = Path.GetFileName(fbxFile);
            string fbxWithoutName = Path.GetFileNameWithoutExtension(fbxName);
            string fbxDir = outputreference.modelFolderPath + "/fbx/";
            if (!Directory.Exists(fbxDir))
                Directory.CreateDirectory(fbxDir);

            string fbxDestPath = fbxDir + fbxName;
            var fbx = ModelImportWindow.CopyAndLoad<GameObject>(fbxFile, fbxDestPath);
            fbxFileInfo.fileName = fbxWithoutName;
            fbxFileInfo.srcFilePath = fbxFile;
            fbxFileInfo.destFilePath = fbxDestPath;

            //2.复制贴图
            //遍历贴图文件夹，和模型文件夹，如果没有模型没有这个贴图，添加到需要创建的集合里。
            string[] modelPartsName = fbxWithoutName.Split('_');
            string fbxPartName = modelPartsName[1];
            foreach (var each in textureBuilder.textureFileInfoDict) {
                if (each.Key.StartsWith("h_"+fbxPartName+"_"))
                {
                    if (fbxWithoutName.StartsWith("h_")&& each.Value.destTexPath!=null)
                        ModelImportWindow.CopyAndLoad<Texture>(each.Value.srcTexPath, each.Value.destTexPath);
                }
            }

            //3.根据多套贴图文件夹生成多套prefab
            foreach (var texFolder in texFolders)
            {
                string texFolderName = Path.GetFileName(texFolder);
                string prefabName = fbxWithoutName + "_" + texFolderName;
                string matName = modelPartsName[0] + "_" + fbxPartName + "_" + texFolderName;
                CreatePrefabInfo(prefabName, matName, matFiles, fbx, fbxFileInfo);
            }
        }
        watch.Stop();
        Debug.Log(watch.ElapsedMilliseconds);
    }
    #region 材质球设置
    private static void SetSSSAndAniso(Material mat)
    {

        if (mat.name.Contains("hair"))
        {
            mat.SetFloat("USE_ANISOTROPY", 1.0f);
            mat.EnableKeyword("USE_ANISOTROPY_ON");

        }
        else if (mat.name.Contains("head"))
        {
            mat.SetFloat("USE_SSSENABLE", 1.0f);
            mat.EnableKeyword("USE_SSSENABLE_ON");
        }
        else
        {
            mat.SetFloat("USE_ANISOTROPY", 0.0f);
            mat.SetFloat("USE_SSSENABLE", 0.0f);
            mat.DisableKeyword("USE_ANISOTROPY_ON");
            mat.DisableKeyword("USE_SSSENABLE_ON");

        }
    }

    private void MaterialBlendMode(Material _material) {
        _material.SetOverrideTag("RenderType", "");
        _material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
        _material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
        _material.SetInt("_ZWrite", 1);
        _material.DisableKeyword("USE_ALPHA_TEST_ON");
        _material.DisableKeyword("USE_ALPHA_BLEND_ON");

        _material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
    }

    private void MaterialsSetting(string matName, Material material)
    {
        //衣服材质球设
        if (matName.Contains("h_"))
        {
            if (matName.Contains("_nrp"))
            {
                material.SetFloat("USE_NRP", 1.0f);
                material.SetFloat("USE_SELFSHADOW", 1.0f);
                SetSSSAndAniso(material);
                material.SetFloat("_NON_USE_PBR_GLOSSY", 0.0f);

                material.EnableKeyword("USE_NRP_ON");
                material.EnableKeyword("USE_SELFSHADOW_ON");
                material.DisableKeyword("_NON_USE_PBR_GLOSSY_ON");
            }
            else
            {
                material.SetFloat("USE_NRP", 0.0f);
                material.SetFloat("USE_SELFSHADOW", 0.0f);
                SetSSSAndAniso(material);
                material.SetFloat("_NON_USE_PBR_GLOSSY", 0.0f);

                material.DisableKeyword("USE_NRP_ON");
                material.DisableKeyword("USE_SELFSHADOW_ON");
                material.DisableKeyword("_NON_USE_PBR_GLOSSY_ON");
            }
        }
        if (matName.Contains("m_"))
        {
            if (matName.Contains("_nrp"))
            {
                material.SetFloat("USE_NRP", 1.0f);
                material.SetFloat("USE_SELFSHADOW", 1.0f);
                SetSSSAndAniso(material);
                material.SetFloat("_NON_USE_PBR_GLOSSY", 0.0f);

                material.EnableKeyword("USE_NRP_ON");
                material.EnableKeyword("USE_SELFSHADOW_ON");
                material.DisableKeyword("_NON_USE_PBR_GLOSSY_ON");
            }
            else
            {
                material.SetFloat("USE_NRP", 0.0f);
                material.SetFloat("USE_SELFSHADOW", 0.0f);
                material.SetFloat("USE_ANISOTROPY", 0.0f);
                material.SetFloat("USE_SSSENABLE", 0.0f);
                material.SetFloat("_NON_USE_PBR_GLOSSY", 1.0f);

                material.DisableKeyword("USE_NRP_ON");
                material.DisableKeyword("USE_SELFSHADOW_ON");
                material.DisableKeyword("USE_ANISOTROPY_ON");
                material.DisableKeyword("USE_ANISOTROPY_ON");
                material.EnableKeyword("_NON_USE_PBR_GLOSSY_ON");
            }
        }
        if (matName.Contains("l_"))
        {
            if (matName.Contains("_nrp"))
            {
                material.SetFloat("USE_NRP", 1.0f);
                material.SetFloat("USE_SELFSHADOW", 1.0f);
                SetSSSAndAniso(material);
                material.SetFloat("_NON_USE_PBR_GLOSSY", 1.0f);

                material.EnableKeyword("USE_NRP_ON");
                material.EnableKeyword("USE_SELFSHADOW_ON");
                material.EnableKeyword("_NON_USE_PBR_GLOSSY_ON");
            }
            else
            {
                material.SetFloat("USE_NRP", 0.0f);
                material.SetFloat("USE_SELFSHADOW", 0.0f);
                material.SetFloat("USE_ANISOTROPY", 0.0f);
                material.SetFloat("USE_SSSENABLE", 0.0f);
                material.SetFloat("_NON_USE_PBR_GLOSSY", 1.0f);
                
                material.DisableKeyword("USE_NRP_ON");
                material.DisableKeyword("USE_SELFSHADOW_ON");
                material.DisableKeyword("USE_ANISOTROPY_ON");
                material.DisableKeyword("USE_ANISOTROPY_ON");
                material.EnableKeyword("_NON_USE_PBR_GLOSSY_ON");
            }
        }
        //公共设置
        material.SetFloat("USE_AO", 1.0f);
        material.SetFloat("NEED_ENV", 1.0f);
        material.EnableKeyword("USE_AO_ON");
        material.EnableKeyword("NEED_ENV_ON");

        material.SetFloat("USE_TATTOO_TEX", 0.0f);
        material.DisableKeyword("USE_TATTOO_TEX_ON");

        material.SetFloat("NON_USE_FOG", 1.0f);
        material.EnableKeyword("NON_USE_FOG_ON");

        Texture envTex = AssetDatabase.LoadAssetAtPath<Texture>("Assets/data/scene/env2.dds");
        material.SetTexture("_EnvCubeMap", envTex);
        MaterialBlendMode(material);
    }
    #endregion
    private Material CreateMats(string[] matFiles,string prefabName,string prefabPath, List<string> matPathList, List<TextureFileInfo> texFileInfoList)
    {
        //新建材质球路径 高模带_nrp 低模不带_nrp
        string l_matPath = "";
        string m_matPath = "";
        string h_matPath = "";
        string subFileName = "";
        if (prefabName.StartsWith("h_"))
            subFileName = prefabName.Substring(1, prefabName.Length - 1) + "_nrp";
        else
           subFileName = prefabName.Substring(1, prefabName.Length - 1);

        h_matPath = outputreference.matFolderPath + "/h" + subFileName + MAT_EXTENSION;
        m_matPath = outputreference.matFolderPath + "/m" + subFileName + MAT_EXTENSION;
        l_matPath = outputreference.matFolderPath + "/l" + subFileName + MAT_EXTENSION;

        Material l_mat=null;
        Material m_mat=null;
        Material h_mat=null;

        //如果prefab存在 则引用老的材质球
        if (File.Exists(prefabPath))
        {
            string[] fileDepends = AssetDatabase.GetDependencies(prefabPath, false);
            foreach (string dependFilePath in fileDepends)
            {
                if (dependFilePath.EndsWith(".mat", System.StringComparison.OrdinalIgnoreCase))
                {
                    //如果是皮肤材质球不改贴图名字
                    string skinFolder = "Assets/data/configmaterial/skin";
                    if (dependFilePath.Contains(skinFolder))
                    {
                        break;
                    }
                    string matFolderPath = Path.GetDirectoryName(dependFilePath);
                    string matName = Path.GetFileName(dependFilePath);
                    string subMatName = matName.Substring(1, matName.Length - 1);
                    l_matPath = dependFilePath;
                    m_matPath = matFolderPath + "/m" + subMatName;
                    h_matPath = matFolderPath + "/h" + subMatName;

                    l_mat = AssetDatabase.LoadAssetAtPath<Material>(l_matPath);
                    m_mat = AssetDatabase.LoadAssetAtPath<Material>(m_matPath);
                    h_mat = AssetDatabase.LoadAssetAtPath<Material>(h_matPath);
                }
            }
        }

        //否则prefab不存在， 创建新的材质球
        if (l_mat == null) {
            l_mat = new Material(Shader.Find("lmd_standard_ModelView"));
            m_mat = new Material(Shader.Find("lmd_standard_ModelView"));
            h_mat = new Material(Shader.Find("lmd_standard_ModelView"));
            Debug.Log("创建新的材质球");
            //如果材质球存在不创建新的材质球，直接加载
            if (File.Exists(l_matPath)) {
                l_mat = AssetDatabase.LoadAssetAtPath<Material>(l_matPath);
                m_mat = AssetDatabase.LoadAssetAtPath<Material>(m_matPath);
                h_mat = AssetDatabase.LoadAssetAtPath<Material>(h_matPath);
            }
            else
            {
                AssetDatabase.CreateAsset(l_mat, l_matPath);
                AssetDatabase.CreateAsset(m_mat, m_matPath);
                AssetDatabase.CreateAsset(h_mat, h_matPath);
            }

            //设置材质球
            MaterialsSetting(Path.GetFileNameWithoutExtension(l_matPath), l_mat);
            MaterialsSetting(Path.GetFileNameWithoutExtension(m_matPath), m_mat);
            MaterialsSetting(Path.GetFileNameWithoutExtension(h_matPath), h_mat);
        }
        //设置贴图
        foreach (var each in textureBuilder.textureFileInfoDict)
        {
            var texFileInfo = each.Value;
            string texPartName = each.Key.Split('_')[1];
            if (prefabName.Contains(texFileInfo.texFolderName)&&prefabName.Contains(texPartName)) {
                Texture tex = AssetDatabase.LoadAssetAtPath<Texture>(texFileInfo.destTexPath);
                l_mat.SetTexture(texFileInfo.texType, tex);
                m_mat.SetTexture(texFileInfo.texType, tex);
                h_mat.SetTexture(texFileInfo.texType, tex);

                texFileInfoList.Add(each.Value);
            }
        }

        if (prefabName.StartsWith("l_"))
            l_mat.SetTexture("_BumpMap", null);

        matPathList.Add(l_matPath);
        matPathList.Add(m_matPath);
        matPathList.Add(h_matPath);
        return l_mat;
    }

    private GameObject CreatePrefab(GameObject fbx, Material mat, string settingFilePath, string outputFilePath)
    {
        if (File.Exists(outputFilePath))
            File.Delete(outputFilePath);

        //创建预制件
        GameObject inst = GameObject.Instantiate(fbx as GameObject);
        ApplyPrefabSetting(settingFilePath, inst, outputFilePath);
        Component.DestroyImmediate(inst.GetComponent<Animator>());

        //删除空白材质球
        Material[] mats = inst.GetComponentInChildren<Renderer>().sharedMaterials;
        for (int t = 0; t < mats.Length; t++)
        {
            if (t == 0)
                mats[t] = mat;
            else
                mats[t] = null;
        }
        inst.GetComponentInChildren<Renderer>().sharedMaterials = mats;

        GameObject prefab = PrefabUtility.CreatePrefab(outputFilePath, inst);
        GameObject.DestroyImmediate(inst);
        Debug.LogFormat("创建预制件 : {0}", outputFilePath);
        return prefab;
    }

    //应用预制件设置
    private void ApplyPrefabSetting(string filePath, GameObject go, string prefabPath)
    {
        if (!File.Exists(filePath)) return;
        var setting = AssetDatabase.LoadAssetAtPath<ModelPrefabSetting>(filePath);
        setting.ApplyToPrefab(go);
    }
}
