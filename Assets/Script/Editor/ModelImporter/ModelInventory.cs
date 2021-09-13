// ==============================================
// Author：qiuyukun
// Date:2019-04-29 20:42:00
// ==============================================

using System.Collections.Generic;
using System.IO;
using UnityEngine;
using System.Linq;
using Framework;

//文件信息
[System.Serializable]
public struct FBXFileInfo
{
    public string fileName;
    public string srcFilePath;
    public string destFilePath;
}
[System.Serializable]
public struct TextureFileInfo
{
    public string texName;
    public string texFolderName;
    public string texType;
    public string srcTexPath;
    public string destTexPath;
}
[System.Serializable]
public struct PrefabInfo
{
    //模型后缀
    public string prefabName;
    //预制件路径
    public string prefabPath;
    //材质球路径
    public List<string> matsPath;
    public FBXFileInfo fbxFileInfo;
    public List<TextureFileInfo> textureFileInfoList;
}
[System.Serializable]
public struct OutputReference
{
    public string modelFolderPath;
    public string matFolderPath;
    public List<string> mainTexFolderPath;
    public string normalTexFolderPath;
}
//模型文件夹信息
[System.Serializable]
public class ModelFolderInfo : ISerializationCallbackReceiver
{
    public string folderName;
    public string folderPath;

    public Dictionary<string, PrefabInfo> prefabInfoDict = new Dictionary<string, PrefabInfo>();

    [SerializeField]
    private List<PrefabInfo> prefabInfoList = new List<PrefabInfo>();
    [SerializeField]
    public OutputReference outputReference = new OutputReference();

    public void OnBeforeSerialize()
    {
        prefabInfoList.Clear();
        foreach (var each in prefabInfoDict)
        {
            if(!prefabInfoList.Contains(each.Value))
                prefabInfoList.Add(each.Value);
        }
    }

    public void OnAfterDeserialize()
    {
        prefabInfoDict.Clear();
        foreach (var each in prefabInfoList)
        {
            if (!prefabInfoDict.ContainsKey(each.prefabName))
                prefabInfoDict.Add(each.prefabName, each);
        }
    }
}

[CreateAssetMenu(fileName = "ModelInventory", menuName = "Create Model Inventory")]
public class ModelInventory : ScriptableObject, ISerializationCallbackReceiver
{
    public const string TGA_EXTENSION = ".tga";
    public const string FBX_EXTENSION = ".FBX";
    public const string MODEL_PREFAB_SETTING_EXTENSION = ".asset";

    public Dictionary<string, ModelFolderInfo> modelFolderInfoDict = new Dictionary<string, ModelFolderInfo>();
    [SerializeField]
    private List<ModelFolderInfo> modelFolderInfoList = new List<ModelFolderInfo>();

    public void OnBeforeSerialize()
    {
        modelFolderInfoList.Clear();
        foreach (var each in modelFolderInfoDict)
        {
            modelFolderInfoList.Add(each.Value);
        }
    }

    public void OnAfterDeserialize()
    {
        modelFolderInfoDict.Clear();
        foreach (var each in modelFolderInfoList)
        {
            if (!modelFolderInfoDict.ContainsKey(each.folderName))
                modelFolderInfoDict.Add(each.folderName, each);
        }
    }
}
