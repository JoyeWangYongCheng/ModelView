// ==============================================
// Author：qiuyukun
// Date:2019-04-30 09:46:37
// ==============================================

using Framework;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using UnityEditor;
using UnityEngine;
using Newtonsoft.Json;

public class ModelImportWindow : EditorWindow
{
    //贴图类型
    public enum ETextureType
    {
        _MainTex = 1,
        _NormalMap,
        _MappingTex,
        _AnisoTex,
    }

    //贴图信息
    private class TextureInfo
    {
        public string prefix;
        public string path;
        public ETextureType type;
        public Texture texture;
    }

    public const string modelRootFolder = "Assets/data/model/";
    public const string matRootFolder = "Assets/data/configmaterial/model/";
    public const string normalTexRootFolder = "Assets/data/texture/charadvancetextures/";
    public const string mainTexRootFolder = "Assets/data/charbasetextures/";
    
    public const string PREFAB_EXTENSION = ".prefab";
    //图片类型在名字中的下标
    public const int TEXTURE_TYPE_NAME_INDEX = 7;

    private const string MAT_EXTENSION = ".mat";
    private const string INVENTORY_PATH = "Assets/_Models/inventory.asset";
    private const string MODEL_JSON_DATA_PATH= "Assets/_Models/modelJsonData.json";
    private const string MODEL_ROOT_PATH = "Assets/_Models";
    private const string SOURCE_CHAR_ROOT_PATH = MODEL_ROOT_PATH + "/char";
    private const string SOURCE_SKIN_ROOT_PATH = MODEL_ROOT_PATH + "/skin";


    private ModelInventory _inventory;

    //所有模型目录
    private List<string> _modelFolderList = new List<string>();

    private string exportProjectDir;

    public void Init()
    {
        LoadInventory();
        SelectFolders();
        RefreshDisplayInfo();
    }

    //加载资源清单
    private void LoadInventory()
    {
        if (File.Exists(INVENTORY_PATH))
            _inventory = AssetDatabase.LoadAssetAtPath<ModelInventory>(INVENTORY_PATH);
        else
            _inventory = ScriptableObject.CreateInstance<ModelInventory>();

        //创建json文件
        if (!File.Exists(MODEL_JSON_DATA_PATH))
            File.Create(MODEL_JSON_DATA_PATH);
        string jsonText = ModelJsonData.ReadJsonText(MODEL_JSON_DATA_PATH);
        var modelFolderInfoDict = JsonConvert.DeserializeObject<Dictionary<string, ModelFolderInfo>>(jsonText);
        foreach (var each in modelFolderInfoDict) {
            if(!_inventory.modelFolderInfoDict.ContainsKey(each.Key))
                _inventory.modelFolderInfoDict.Add(each.Key, each.Value);
        }
    }

    private void Test() {

        //Dictionary<string, ModelFolderInfo>  _modelFolderInfoDict= new Dictionary<string, ModelFolderInfo>();
        //ModelFolderInfo _modelFolderInfo = new ModelFolderInfo();
        //_modelFolderInfoDict.Add("111", _modelFolderInfo);
        //ModelInventory _modelInventory = new ModelInventory();
        //_modelInventory.name = "modelinventory";
        //_modelInventory.modelFolderInfoDict = _modelFolderInfoDict;

        //string _json =  JsonConvert.SerializeObject(_modelFolderInfoDict);
        //Debug.Log(_json);

        //foreach (var modelFolderInfo in _inventory.modelFolderInfoDict) {
        //    ModelFolderInfo _modelFolderInfo = modelFolderInfo.Value;
        //    //把对象转换成json
        //    string _json = JsonUtility.ToJson(_modelFolderInfo);
        //    //把json转换成对象
        //    ModelFolderInfo _model = JsonUtility.FromJson(_json,typeof(ModelFolderInfo)) as ModelFolderInfo;
        //    Debug.Log(_json);
        //    Debug.Log(_model.folderName);
        //}
    }

    private void SaveModelsInfo() {
        SelectFolders();
        foreach (var folder in _modelFolderList) {
            ModelFolderInfo m_modelFolderInfo = new ModelFolderInfo();
            string folderName = Directory.GetParent(folder).Name + "_" + Path.GetFileName(folder);
            m_modelFolderInfo.folderName = folderName;
            m_modelFolderInfo.folderPath = folder;

            //获取文件夹
            OutputReference _outputPathFolder = CreateOutputFolder(m_modelFolderInfo);
            m_modelFolderInfo.outputReference = _outputPathFolder;
            List<PrefabInfo> _prefabInfoList = new List<PrefabInfo>();
            string[] prefabFiles = Directory.GetFiles(_outputPathFolder.modelFolderPath, "*.prefab", SearchOption.AllDirectories);
            foreach (var prefabFile in prefabFiles) {
                PrefabInfo _prefabInfo = new PrefabInfo();
                FBXFileInfo _fbxFileInfo = new FBXFileInfo();
                List<string> _matList = new List<string>();
                List<TextureFileInfo> _texFileInfoList = new List<TextureFileInfo>();

                string prefabPath = prefabFile.Replace("\\", "/");
                string prefabName = Path.GetFileNameWithoutExtension(prefabPath);

                string[] fileDepends = AssetDatabase.GetDependencies(prefabPath, false);
                foreach (string dependFilePath in fileDepends) {
                    if (dependFilePath.EndsWith(".fbx", System.StringComparison.OrdinalIgnoreCase))
                    {
                        string fbxName = Path.GetFileNameWithoutExtension(dependFilePath);
                        _fbxFileInfo.fileName = fbxName;
                        _fbxFileInfo.destFilePath = dependFilePath;
                    }
                    else if (dependFilePath.EndsWith(".mat", System.StringComparison.OrdinalIgnoreCase)) {
                        //如果是皮肤材质球不改贴图名字
                        string skinFolder = "Assets/data/configmaterial/skin";
                        if (dependFilePath.Contains(skinFolder))
                        {
                            break;
                        }
                        //材质球数据
                        string l_matPath = dependFilePath;
                        string m_matPath = dependFilePath.Replace("l_", "m_");
                        string h_matPath = dependFilePath.Replace("l_", "h_");
                        _matList.Add(l_matPath);
                        _matList.Add(m_matPath);
                        _matList.Add(h_matPath);
                        //贴图数据
                        if (prefabName.StartsWith("h_")) {
                            Material mat = AssetDatabase.LoadAssetAtPath(dependFilePath, typeof(Material)) as Material;
                            Texture mainTex = mat.GetTexture("_MainTex");
                            string mainTexPath = AssetDatabase.GetAssetPath(mainTex);
                            Texture mappingTex = mat.GetTexture("_MappingTex");
                            string mappingTexPath = AssetDatabase.GetAssetPath(mappingTex);
                            Texture bumpTex = mat.GetTexture("_BumpMap");
                            string bumpTexPath = AssetDatabase.GetAssetPath(bumpTex);

                            Texture anisoTex = mat.GetTexture("_AnisoTex");
                            string anisoTexPath = AssetDatabase.GetAssetPath(anisoTex);

                            TextureFileInfo _mainTexFileInfo = new TextureFileInfo();
                            _mainTexFileInfo.texName = Path.GetFileNameWithoutExtension(mainTexPath);
                            _mainTexFileInfo.texType = "_MainTex";
                            _mainTexFileInfo.destTexPath = mainTexPath;
                            TextureFileInfo _mappingTexFileInfo = new TextureFileInfo();
                            _mappingTexFileInfo.texName = Path.GetFileNameWithoutExtension(mappingTexPath);
                            _mappingTexFileInfo.texType = "_MappingTex";
                            _mappingTexFileInfo.destTexPath = mappingTexPath;
                            TextureFileInfo _bumpTexFileInfo = new TextureFileInfo();
                            _bumpTexFileInfo.texName = Path.GetFileNameWithoutExtension(bumpTexPath);
                            _bumpTexFileInfo.texType = "_BumpMap";
                            _bumpTexFileInfo.destTexPath = bumpTexPath;
                            TextureFileInfo _anisoTexFileInfo = new TextureFileInfo();
                            _anisoTexFileInfo.texName = Path.GetFileNameWithoutExtension(anisoTexPath);
                            _anisoTexFileInfo.texType = "_AnisoTex";
                            _anisoTexFileInfo.destTexPath = anisoTexPath;

                            _texFileInfoList.Add(_mainTexFileInfo);
                            _texFileInfoList.Add(_mappingTexFileInfo);
                            _texFileInfoList.Add(_bumpTexFileInfo);
                            _texFileInfoList.Add(_anisoTexFileInfo);
                        }
                        
                        string matFolderPath = Path.GetDirectoryName(dependFilePath);
                        string matName = Path.GetFileNameWithoutExtension(dependFilePath);
                        //Debug.Log(prefabName+"  "+matName);
                    }
                }

                _prefabInfo.prefabName = prefabName;
                _prefabInfo.prefabPath = prefabPath;
                _prefabInfo.fbxFileInfo = _fbxFileInfo;
                _prefabInfo.matsPath = _matList;
                _prefabInfo.textureFileInfoList = _texFileInfoList;

                m_modelFolderInfo.prefabInfoDict.Add(prefabName,_prefabInfo);
            }
            if (_inventory != null)
            {
                if (_inventory.modelFolderInfoDict.ContainsKey(folderName))
                    _inventory.modelFolderInfoDict.Remove(folderName);
                _inventory.modelFolderInfoDict.Add(folderName, m_modelFolderInfo);
            }
            else
                Debug.Log("重新打开工具");
        }

        string jsonText = JsonConvert.SerializeObject(_inventory.modelFolderInfoDict);
        ModelJsonData.WriteJsonText(MODEL_JSON_DATA_PATH, jsonText);
    }

    #region 模型资源导入
    private void ImportModels()
    {
        try
        {
            SelectFolders();
            if (_modelFolderList.Count == 0) {
                Debug.Log("请选中需要导出的文件夹");
            }
            foreach (var folder in _modelFolderList)
            {
                ModelFolderInfo m_modelFolderInfo = new ModelFolderInfo();
                string folderName = Directory.GetParent(folder).Name + "_" + Path.GetFileName(folder);
                m_modelFolderInfo.folderName = folderName;
                m_modelFolderInfo.folderPath = folder;

                //创建文件夹
                OutputReference outputPathFolder = CreateOutputFolder(m_modelFolderInfo);

                //删除MD5码文件
                DeleteMD5File(outputPathFolder);
                m_modelFolderInfo.outputReference = outputPathFolder;

                var textureBuilder = new ModelImportTextureBuilder(folder,outputPathFolder);

                var prefabBuilder = new ModelImportPrefabBuilder(folder, outputPathFolder, textureBuilder);
                m_modelFolderInfo.prefabInfoDict = prefabBuilder.prefabInfoDict;

                if (_inventory != null)
                {
                    if (_inventory.modelFolderInfoDict.ContainsKey(folderName))
                        _inventory.modelFolderInfoDict.Remove(folderName);
                    _inventory.modelFolderInfoDict.Add(folderName, m_modelFolderInfo);
                }
                else {
                    Debug.Log("需要重新打开");
                }
            }
            string jsonText = JsonConvert.SerializeObject(_inventory.modelFolderInfoDict);
            ModelJsonData.WriteJsonText(MODEL_JSON_DATA_PATH, jsonText);
        }
        catch (System.Exception ex)
        {
            Debug.LogError(ex);
        }
        finally
        {
            RefreshDisplayInfo();
            EditorUtility.ClearProgressBar();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
    }

    private void ReplaceDataFolderTexture() {

        var selectObjects = Selection.objects;
        foreach (var obj in selectObjects) {
            string objPath = AssetDatabase.GetAssetPath(obj);
            if (objPath.Contains(".tga")) {
                string texName = Path.GetFileNameWithoutExtension(objPath);
                string folderDir = Path.GetDirectoryName(objPath);
                string texFolderPath = Directory.GetParent(folderDir).FullName;
                string modelFolderName = Directory.GetParent(texFolderPath).Name;
                string folderName = modelFolderName + "_" + Path.GetFileName(texFolderPath);

                if (_inventory.modelFolderInfoDict != null)
                {
                    foreach (var modelFolderInfo in _inventory.modelFolderInfoDict)
                    {
                        if (modelFolderInfo.Key == folderName)
                        {
                            foreach (var prefabInfo in modelFolderInfo.Value.prefabInfoDict)
                            {
                                if (prefabInfo.Key.StartsWith("h_" + texName.Split('_')[1] + "_"))
                                {
                                    foreach (var texFileInfo in prefabInfo.Value.textureFileInfoList)
                                    {
                                        if (texFileInfo.texName == texName)
                                        {
                                            ModelImportWindow.CopyAndLoad<Texture>(texFileInfo.srcTexPath, texFileInfo.destTexPath);
                                            Debug.Log(texFileInfo.destTexPath);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    Debug.Log("数据为空，请重新打开工具");
                }
            }
        }
    }

    private bool FileNameIsContainsMD5(string fileName) {

        bool isContainsMD5 = true;
        if (fileName.Contains("l_") || fileName.Contains("h_")) {
            isContainsMD5 = false;
        }
        return isContainsMD5;
    }
    //删除md5码模型和贴图
    private void DeleteMD5File(OutputReference _outputReference)
    {
        string[] modelFiles = Directory.GetFiles(_outputReference.modelFolderPath, "*.FBX", SearchOption.AllDirectories);
        foreach (var modelFile in modelFiles)
        {
            File.Delete(modelFile);
        }

        string[] normalFiles = Directory.GetFiles(_outputReference.normalTexFolderPath, "*.*", SearchOption.TopDirectoryOnly);
        foreach (var normalFile in normalFiles)
        {
            File.Delete(normalFile);
        }

        foreach (var mainTexFolder in _outputReference.mainTexFolderPath)
        {
            string[] mainTexFiles = Directory.GetFiles(mainTexFolder, "*.*", SearchOption.TopDirectoryOnly);
            foreach (var mainTexFile in mainTexFiles) {
                File.Delete(mainTexFile);
            }
        }
    }
    //获取tga文件或fbx文件的前缀名
    public static string GetPrefixFromFileName(string fileName)
    {
        string file = Path.GetFileNameWithoutExtension(fileName);
        int index = file.IndexOf('_', 2);
        if (index < 0)
            return file;
        return file.Substring(0, index);
    }

    //复制和加载资源
    public static T CopyAndLoad<T>(string sourcePath, string destPath) where T : UnityEngine.Object
    {
        if (string.IsNullOrEmpty(sourcePath) || !File.Exists(sourcePath))
        {
            Debug.LogErrorFormat("路径错误 : {0}", sourcePath);
            return null;
        }
        if (File.Exists(destPath))
            File.Delete(destPath);

        Debug.LogFormat("创建资源 {0}", destPath);
        File.Copy(sourcePath, destPath);
        AssetDatabase.Refresh(ImportAssetOptions.Default);
        return AssetDatabase.LoadAssetAtPath<T>(destPath);
    }


    //创建输出目录
    private OutputReference CreateOutputFolder(ModelFolderInfo _modelFolderInfo)
    {
        OutputReference m_outputReference = new OutputReference();
        string modelCategory="";
        string folderName = _modelFolderInfo.folderName;
        if (folderName.Contains("char"))
            modelCategory = "char/";
        else
            modelCategory = "skin/";
        string modelFolderPath = modelRootFolder + modelCategory + folderName;
        m_outputReference.modelFolderPath = modelFolderPath;
        if (!Directory.Exists(modelFolderPath))
            Directory.CreateDirectory(modelFolderPath);

        string matFolderPath = matRootFolder + modelCategory + folderName;
        m_outputReference.matFolderPath = matFolderPath;
        if (!Directory.Exists(matFolderPath))
            Directory.CreateDirectory(matFolderPath);

        string normalTexFolderPath = normalTexRootFolder + folderName;
        m_outputReference.normalTexFolderPath = normalTexFolderPath;
        if (!Directory.Exists(normalTexFolderPath))
            Directory.CreateDirectory(normalTexFolderPath);

        List<string> mainTexFolderList = new List<string>();
        string[] files = Directory.GetFiles(_modelFolderInfo.folderPath, "*.*", SearchOption.TopDirectoryOnly);
        foreach (var file in files) {
            string fileName = Path.GetFileName(file);
            if (fileName.StartsWith("h_")&& fileName.EndsWith(".fbx",StringComparison.CurrentCultureIgnoreCase)) {
                string partName = Path.GetFileNameWithoutExtension(fileName).Split('_')[1];
                string mainTexFolderPath = mainTexRootFolder + folderName + "_" + partName;
                mainTexFolderList.Add(mainTexFolderPath);
                if (!Directory.Exists(mainTexFolderPath))
                    Directory.CreateDirectory(mainTexFolderPath);
            }
        }

        m_outputReference.mainTexFolderPath = mainTexFolderList;

        return m_outputReference;
    }
    #endregion

    private void CreateDestFolderAndCopyFile(string srcFolderPath)
    {
        string destFolderPath = exportProjectDir + "/" + srcFolderPath;
        //删除文件
        if (Directory.Exists(destFolderPath))
        {
            string[] destFiles = Directory.GetFiles(destFolderPath, "*.*", SearchOption.AllDirectories);
            foreach (var file in destFiles)
            {
                File.Delete(file.Replace("\\", "/"));
            }
        }
        else
        {
            Directory.CreateDirectory(destFolderPath);
        }
        //拷贝文件
        string[] srcFiles = Directory.GetFiles(srcFolderPath, "*.*", SearchOption.AllDirectories);
        foreach (var file in srcFiles)
        {
            if (Path.HasExtension(file)) {
                string filePath = file.Replace("\\", "/");
                string srcFilePath = Application.dataPath.Replace("Assets", "") + filePath;
                string destFilePath = exportProjectDir + "/" + filePath;
                string fbxFolder = Path.GetDirectoryName(destFilePath);
                Debug.Log("fbx文件夹信息 ："+fbxFolder);
                if (!Directory.Exists(fbxFolder)) {
                    Directory.CreateDirectory(fbxFolder);
                }
                Debug.Log(srcFilePath + "    " + destFilePath);
                File.Copy(srcFilePath, destFilePath);
            }
        }

        //递归子目录
        string[] folders = Directory.GetDirectories(srcFolderPath);
        foreach (var folder in folders)
        {
            CreateDestFolderAndCopyFile(folder.Replace("\\", "/"));
        }
    }
    private void AutoExportProject() {
        Debug.Log("自动导出到工程");
        SelectFolders();
        foreach (var folder in _modelFolderList)
        {
            OutputReference outputPathFolder = new OutputReference();
            string folderName = Directory.GetParent(folder).Name + "_" + Path.GetFileName(folder);
            foreach (var modelFolderInfo in _inventory.modelFolderInfoDict)
            {
                if (modelFolderInfo.Key == folderName)
                {
                    outputPathFolder = modelFolderInfo.Value.outputReference;
                }
            }

            CreateDestFolderAndCopyFile(outputPathFolder.modelFolderPath);
            CreateDestFolderAndCopyFile(outputPathFolder.matFolderPath);
            CreateDestFolderAndCopyFile(outputPathFolder.normalTexFolderPath);
            foreach (var mainFolder in outputPathFolder.mainTexFolderPath) {
                CreateDestFolderAndCopyFile(mainFolder);
            }
        }
        if (_modelFolderList.Count == 0) {
            Debug.Log("请选中文件");
        }
    }


    #region Windows

    private class DisplayFileInfo
    {
        public string fileName;
        public UnityEngine.Object obj;
    }

    //文件夹展示信息
    private class DisplayFolderInfo
    {
        public string folderPath;
        public List<DisplayFileInfo> newList = new List<DisplayFileInfo>();
        public List<DisplayFileInfo> modifiedList = new List<DisplayFileInfo>();
        public List<string> deletedList = new List<string>();
    }

    private Vector2 _scrollViewPos;
    private List<DisplayFolderInfo> _displayFolderInfoList = new List<DisplayFolderInfo>();


    [MenuItem("Framework/Streetball2/Model Import Window &x")]
    private static void Open()
    {
        ModelImportWindow wnd = (ModelImportWindow)EditorWindow.GetWindow(typeof(ModelImportWindow), false, "模型导入", true);
        wnd.maxSize = new Vector2(500, 800);
        wnd.Init();
        wnd.Show();
    }

    //清理文件信息,以及对应导出的文件夹
    private void ClearFolderInfo()
    {
        //foreach(var folder in _modelFolderList)
        //{
        //    _inventory.RemoveFolderInfo(folder);
        //    var outputPath = GetOutputFolder(folder);
        //    if (Directory.Exists(outputPath))
        //    {
        //        Directory.Delete(outputPath, true);
        //        Debug.LogFormat("删除目录 {0}", outputPath);
        //    }
        //}
        //RefreshDisplayInfo();
        //AssetDatabase.SaveAssets();
        //AssetDatabase.Refresh();
    }

    private bool CheckFolder(string folder)
    {
        if (folder.StartsWith(SOURCE_CHAR_ROOT_PATH) || folder.StartsWith(SOURCE_SKIN_ROOT_PATH))
        {
            string parentName = Directory.GetParent(folder).Name;
            string pParentName = Directory.GetParent(folder).Parent.Name;
            if (parentName == "char" || pParentName == "skin")
                return true;
        }
        return false;
    }

    private void SelectFolders()
    {
        _modelFolderList.Clear();
        foreach (var each in Selection.assetGUIDs)
        {
            var folder = AssetDatabase.GUIDToAssetPath(each);
            if (CheckFolder(folder))
            {
                _modelFolderList.Add(folder);
            }
        }
    }

    private void RefreshDisplayInfo()
    {
        _displayFolderInfoList.Clear();
        foreach (var each in _modelFolderList)
        {
            _displayFolderInfoList.Add(GetDisplayFolderInfo(each));
        }
    }

    //获取文件夹显示信息
    private DisplayFolderInfo GetDisplayFolderInfo(string path)
    {
        //var displayFolderInfo = new DisplayFolderInfo();
        //displayFolderInfo.folderPath = path;
        //var folderInfo = _inventory.GetFolderInfo(path);

        ////新增文件
        //foreach (var newFile in folderInfo.GetNewFileList())
        //{
        //    string fileName = Path.GetFileName(newFile);
        //    var obj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(newFile);
        //    var info = new DisplayFileInfo()
        //    {
        //        fileName = fileName,
        //        obj = obj,
        //    };
        //    displayFolderInfo.newList.Add(info);
        //}

        ////有修改的文件
        //foreach (var modifiedFile in folderInfo.GetModifiedFileList())
        //{
        //    string fileName = Path.GetFileName(modifiedFile);
        //    var obj = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(modifiedFile);
        //    var info = new DisplayFileInfo()
        //    {
        //        fileName = fileName,
        //        obj = obj,
        //    };
        //    displayFolderInfo.modifiedList.Add(info);
        //}

        ////删除的文件
        //foreach (var deletedFile in folderInfo.GetDeletedFileList())
        //{
        //    string fileName = Path.GetFileName(deletedFile.filePath);
        //    displayFolderInfo.deletedList.Add(deletedFile.filePath);
        //}
        //return displayFolderInfo;
        return null;
    }


    private void OnGUI()
    {
        var style = new GUIStyle();
        
        _scrollViewPos = EditorGUILayout.BeginScrollView(_scrollViewPos, false, true);

        //foreach (var folderInfo in _displayFolderInfoList)
        //{
        //    if (folderInfo.newList.Count == 0 && folderInfo.modifiedList.Count == 0 && folderInfo.deletedList.Count == 0)
        //    {
        //        continue;
        //    }

        //    EditorGUILayout.LabelField(folderInfo.folderPath);
        //    style.normal.textColor = Color.green;
        //    foreach (var each in folderInfo.newList)
        //    {
        //        EditorGUILayout.BeginHorizontal();
        //        EditorGUILayout.LabelField(each.fileName, style);
        //        EditorGUILayout.ObjectField(each.obj, each.obj.GetType(), false);
        //        EditorGUILayout.EndHorizontal();
        //    }

        //    style.normal.textColor = Color.yellow;
        //    foreach (var each in folderInfo.modifiedList)
        //    {
        //        EditorGUILayout.BeginHorizontal();
        //        EditorGUILayout.LabelField(each.fileName, style);
        //        EditorGUILayout.ObjectField(each.obj, each.obj.GetType(), false);
        //        EditorGUILayout.EndHorizontal();
        //    }

        //    style.normal.textColor = Color.red;
        //    foreach (var each in folderInfo.deletedList)
        //    {
        //        EditorGUILayout.LabelField(each, style);
        //    }
        //}

        EditorGUILayout.EndScrollView();

        if (GUILayout.Button("刷新", new GUILayoutOption[] { GUILayout.Height(50) }))
        {
            SelectFolders();
            RefreshDisplayInfo();
        }
        if (GUILayout.Button("清除文件信息", new GUILayoutOption[] { GUILayout.Height(50) }))
        {
            SelectFolders();
            ClearFolderInfo();
        }
        if (GUILayout.Button("保存模型信息", new GUILayoutOption[] { GUILayout.Height(50) }))
            SaveModelsInfo();

        if (GUILayout.Button("开始导入模型", new GUILayoutOption[] { GUILayout.Height(50) }))
            ImportModels();

        if (GUILayout.Button("替换data文件夹贴图", new GUILayoutOption[] { GUILayout.Height(50) }))
            ReplaceDataFolderTexture();

        GUILayout.Space(30);
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("选择目标工程路径：")) {
            exportProjectDir = EditorUtility.OpenFolderPanel("", "", "");
        }
        exportProjectDir =EditorGUILayout.TextField(exportProjectDir);
        EditorGUILayout.EndHorizontal();
        GUILayout.Space(10);
        if (GUILayout.Button("导出文件到目标工程", new GUILayoutOption[] { GUILayout.Height(50) }))
            AutoExportProject();

        //if (GUILayout.Button("Test", new GUILayoutOption[] { GUILayout.Height(50) }))
        //    Test();

    }

    #endregion
}
