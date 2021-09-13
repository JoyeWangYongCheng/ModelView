#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using Newtonsoft.Json;
using Framework;

public class ModelViewer : MonoBehaviour
{
    public GUISkin _skin;

    private int _modelRenderWindow = 10000;

    private static string[] _shaderMaskes = new string[] 
    {
        "_ALL_",
        "_Normal_",
        "_Diffuse_", 
        "_Specular_",
        "_Environment_",
        "_SpecularAndEnvironment_",
        "_AOMaskColor_",
        "_MetallicMaskColor_",
        "_RoughnessMaskColor_",
        "_SSSMaskColor_",
        "_AnisotropicMaskColor_",
        "_Emission_",
    };

    private int _shaderMaskSelectIndex = 0;
    private int _modelViewWindow = 10086;
    private int _modelSkinTex = 4;
    private string _filter;
    private int _modelPathIndex = 0;
    // private Dictionary<string, Shader> _shaders = new Dictionary<string, Shader>();
    private Dictionary<string, string> _modelNameToPath = new Dictionary<string, string>();
    private List<string> _modelNames = new List<string>();
    private string _currentModelName;
    private GameObject _currentModel;
    private Dictionary<Material, Material> _modelInstanceMaterial2RawMaterial = new Dictionary<Material, Material>();

    private Vector2 _scrollPosition;
    private string skinColorRootDir = "Assets/data/configmaterial/skin/";
    private string SKIN_JSON_DATA_PATH = "Assets/_Models/skinJsonData.json";
    private Dictionary<string, string> _skinColorDataDict = new Dictionary<string, string>();

    private string buttonName = "显示UI";

    private void OnEnable()
    {
        //读取json文件
        if (!File.Exists(SKIN_JSON_DATA_PATH))
            File.Create(SKIN_JSON_DATA_PATH);
        string jsonText = ReadJsonText(SKIN_JSON_DATA_PATH);
        if (jsonText != null) {
            var skinColorDataDict = JsonConvert.DeserializeObject<Dictionary<string, string>>(jsonText);
            if (skinColorDataDict != null) {
                foreach (var each in skinColorDataDict)
                {
                    if (!_skinColorDataDict.ContainsKey(each.Key))
                        _skinColorDataDict.Add(each.Key, each.Value);
                }
            }
        }

        _modelNameToPath.Clear();

        //新增角色
        var charPaths = Directory.GetDirectories("Assets/data/model/char");
        for (var i = 0; i < charPaths.Length; ++i)
        {
            var path = charPaths[i];
            var name = Path.GetFileNameWithoutExtension(path);
            _modelNames.Add(name);
            _modelNameToPath.Add(name, path);
        }
        //新增部件和套装
        var skinPaths = Directory.GetDirectories("Assets/data/model/skin");
        for (var i = 0; i < skinPaths.Length; ++i)
        {
            var path = skinPaths[i];
            var name = Path.GetFileNameWithoutExtension(path);

            //如果套装里有ABCD 就生成出多套
            var skinFiles = Directory.GetFiles(path, "*.prefab");
            foreach (var skinFile in skinFiles)
            {
                string skinFileName = Path.GetFileNameWithoutExtension(skinFile);
                if (skinFileName.StartsWith("h_"))
                {
                    string[] strs = skinFileName.Split('_');
                    name = name.Split('_')[0] + "_" + strs[strs.Length - 1];
                    if (!_modelNames.Contains(name))
                    {
                        _modelNames.Add(name);
                        _modelNameToPath.Add(name, path);
                    }
                }
            }
        }

    }

    private Transform FindRecursive(Transform trans, string name)
    {
        if (trans.name == name)
        {
            return trans;
        }
        for (int i = 0; i < trans.childCount; i++)
        {
            Transform transform = FindRecursive(trans.GetChild(i), name);
            if (transform != null)
            {
                return transform;
            }
        }
        return null;
    }

    private static void CreateInexistentBones(Transform boneRoot, Transform equipRoot)
    {
        if (equipRoot != null)
        {
            for (var i = equipRoot.childCount - 1; i >= 0; --i)
            {
                var equipBone = equipRoot.GetChild(i);
                var childBone = boneRoot.Find(equipBone.name);
                if (childBone == null)
                {
                    var newBone = new GameObject(equipBone.name);
                    newBone.transform.parent = boneRoot;
                    newBone.transform.localPosition = equipBone.localPosition;
                    newBone.transform.localRotation = equipBone.localRotation;
                    newBone.transform.localScale = equipBone.localScale;
                    childBone = newBone.transform;
                }
                CreateInexistentBones(childBone, equipBone);
            }
        }
    }

    private void ReplaceLowMaterials(Renderer _renderer,string skinColorPath,string modelName,string[] strs,string matRootDir) {
        Material[] mats = _renderer.materials;

        for (int t = 0; t < mats.Length; t++)
        {
            if (mats[t].name.Contains("Default-Materia"))
            {
                if (_skinColorDataDict.ContainsKey(_currentModelName))
                {
                    foreach (var each in _skinColorDataDict)
                    {
                        if (each.Key == _currentModelName)
                            skinColorPath = each.Value;
                    }
                }
                else
                {
                    if (modelName.StartsWith("char_"))
                    {
                        skinColorPath = skinColorRootDir + "h_" + strs[strs.Length - 1].Replace("(Clone)", "") + "1_nrp.mat";
                    }
                    else
                    {
                        skinColorPath = skinColorRootDir + "h_" + strs[strs.Length - 2].Replace("(Clone)", "") + "1_nrp.mat";
                    }
                }


            }
            else
            {
                string matWithoutName = mats[t].name.Replace(" (Instance)", "");
                skinColorPath = matRootDir + "h" + matWithoutName.Substring(1, matWithoutName.Length - 1) + ".mat";
            }
            Material skinColor = AssetDatabase.LoadAssetAtPath<Material>(skinColorPath);
            mats[t] = skinColor;
        }
        _renderer.materials = mats;
    }

    private void LoadModel(string modelName)
    {
        var target = GameObject.Find("@SceneConfig").transform;
        var meshFiles = Directory.GetFiles(_modelNameToPath[modelName], "*.prefab");

        if (_currentModel != null)
        {
            GameObject.Destroy(_currentModel);
            _currentModel = null;
        }

        _currentModel = new GameObject(modelName);
        _currentModel.transform.parent = transform;
        _currentModel.transform.localPosition = Vector3.zero;
        _currentModel.transform.localRotation = Quaternion.identity;
        _currentModel.transform.localScale = Vector3.one;

        bool isContainMan = false;
        int bodyNumber = 9;
        var prefabDict = new Dictionary<string,string>();
        foreach (var meshFile in meshFiles)
        {
            string fileName = Path.GetFileNameWithoutExtension(meshFile);
            if (fileName.StartsWith("h_"))
            {
                //不加载Base
                if (fileName.Contains("base"))
                    continue;
                //套装处理
                if (meshFile.StartsWith("Assets/data/model/skin"))
                {
                    string[] strs = fileName.Split('_');
                    int number = int.Parse(strs[2].Substring(1));
                    if (strs[2].Contains("m"))
                    {
                        isContainMan = true;
                        if (number < bodyNumber)
                        {
                            bodyNumber = number;
                        }
                    }

                    //男女-体型—套装-部件   
                    if (!fileName.Contains("basketball"))
                        fileName = strs[2] + "_" + bodyNumber + "_" + strs[3] + "_" + strs[1];
                    //Debug.Log(" 新文件名称 :" + fileName);
                }
                if(!prefabDict.ContainsKey(fileName))
                    prefabDict.Add(fileName, meshFile);
            }
        }

        var meshes = new List<GameObject>();
        foreach (var prefabEach in prefabDict)
        {
            string prefabName = prefabEach.Key;
            string prefabPath = prefabEach.Value;
            string suitName = modelName.Split('_')[1];
            if (prefabPath.StartsWith("Assets/data/model/skin"))
            {
                string[] strs = prefabName.Split('_');

                //加入篮球
                if (prefabName.Contains("basketball"))
                {
                    meshes.Add(AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath));
                }
                else {
                    //区分男女 如果包含男的就只显示男的
                    if (isContainMan)
                    {
                        if (strs[0].Contains("m"))
                        {
                            //区分体型（只显示m0体型）  区分套装
                            if (strs[0].Contains(strs[1]) && suitName == strs[2])
                            {
                                meshes.Add(AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath));
                            }
                        }
                    }
                    else
                    {
                        if(suitName == strs[2])
                            meshes.Add(AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath));
                    }
                }
            }
            else {
                meshes.Add(AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath));
            }

        }

        if (meshes.Count > 0)
        {
            _modelInstanceMaterial2RawMaterial.Clear();

            for (var i = 0; i < meshes.Count; ++i)
            {
                string matRootDir = Path.GetDirectoryName(AssetDatabase.GetAssetPath(meshes[i])).Replace("/data/model/", "/data/configmaterial/model/")+"/";
                //实例化模型
                var mesh = Instantiate(meshes[i], _currentModel.transform) as GameObject;

                string[] strs = mesh.name.Split('_');
                //默认1号肤色
                string skinColorPath = "";

                var skinned = mesh.GetComponentInChildren<SkinnedMeshRenderer>();
                if (skinned != null)
                {
                    ReplaceLowMaterials(skinned, skinColorPath, modelName, strs, matRootDir);
                }
                else
                {
                    var renderer = mesh.GetComponentInChildren<MeshRenderer>();
                    if (renderer != null)
                    {
                        ReplaceLowMaterials(renderer, skinColorPath, modelName, strs, matRootDir);
                    }
                }

                //SwitchModelRender(_shaderMaskSelectIndex);
                //添加阴影
                var prefabRenderer = mesh.GetComponentInChildren<Renderer>();
                ShadowCamera.AddRenderer(prefabRenderer);
                PostEffects.AddRenderer(prefabRenderer);

            }
        }
    }

    private void UdpateSkinnedMaterialFloat(Renderer skin, string k, float v)
    {
        var rawMaterial = _modelInstanceMaterial2RawMaterial[skin.material];
        rawMaterial.SetFloat(k, v);
        skin.material = rawMaterial;
        // var shader = "streetball2/model_" + _shaderMaskes[_shaderMaskSelectIndex].Replace(" ", "").ToLower();
        // skin.material.shader = _shaders[shader];
        _modelInstanceMaterial2RawMaterial[skin.material] = rawMaterial;
    }

    private void UdpateSkinnedMaterialColor(Renderer skin, string k, Color v)
    {
        var rawMaterial = _modelInstanceMaterial2RawMaterial[skin.material];
        rawMaterial.SetColor(k, v);
        skin.material = rawMaterial;
        // var shader = "streetball2/model_" + _shaderMaskes[_shaderMaskSelectIndex].Replace(" ", "").ToLower();
        // skin.material.shader = _shaders[shader];
        _modelInstanceMaterial2RawMaterial[skin.material] = rawMaterial;
    }
    private void SwitchModelRender(int _shaderMaskSelectIndex){
        // Debug.Log("_shaderMaskSelectIndex:"+_shaderMaskSelectIndex);
        // Debug.Log("_shaderMaskes: "+ _shaderMaskes[_shaderMaskSelectIndex]);
        var skinnes = _currentModel.GetComponentsInChildren<Renderer>();
        foreach (var skin in skinnes){
            for(int i=0;i<_shaderMaskes.Length;i++){
                if(i!=_shaderMaskSelectIndex){
                    foreach (var mat in skin.sharedMaterials) 
                        mat.DisableKeyword("SHOW" + _shaderMaskes[i].ToUpper() + "ON");
                }else{
                    Debug.Log("SHOW"+_shaderMaskes[i].ToUpper()+"ON");
                    foreach (var mat in skin.sharedMaterials)
                        mat.EnableKeyword("SHOW" + _shaderMaskes[_shaderMaskSelectIndex].ToUpper() + "ON");
                }
            }
        }
    }

    private void DrawTexture(Texture texture, float width, float height)
    {
        var rect = GUILayoutUtility.GetRect(width, height, GUILayout.Width(width), GUILayout.Height(height));
        rect.width -= 4;
        rect.height -= 4;
        rect.x += 2;
        rect.y += 2;
        if(texture!=null)
            GUI.DrawTexture(rect, texture);
    }

    private void OnGUI()
    {
        if (GUILayout.Button(buttonName)) {
            if (buttonName == "显示UI")
            {
                buttonName = "隐藏UI";
            }
            else {
                buttonName = "显示UI";
            }
        }

        if (buttonName == "显示UI") {
            GUI.skin = _skin;
            GUI.Window(_modelRenderWindow, new Rect(0, 100, Screen.width / 4, Screen.height / 1.5f), OnWindow, "ModelRender");
            GUI.Window(_modelViewWindow, new Rect(Screen.width / 4 * 3, 0, Screen.width / 4, Screen.height), OnWindow, "ModelViewer");
            GUI.Window(_modelSkinTex, new Rect(Screen.width / 6 * 3, 0, 500, 180), OnWindow, "Select Skin");
        }

    }

    private void OnWindow(int id)
    {
        if (_modelRenderWindow == id)
        {
            var index = GUILayout.SelectionGrid(_shaderMaskSelectIndex, _shaderMaskes, 1);

            if (index != _shaderMaskSelectIndex)
            {
                _shaderMaskSelectIndex = index;
                if (_currentModelName != null)
                {
                    SwitchModelRender(_shaderMaskSelectIndex);
                }
            }
        }
        else if (_modelViewWindow == id)
        {
            _filter = GUILayout.TextField(_filter);
            _scrollPosition = GUILayout.BeginScrollView(_scrollPosition);
            {
                for (var i = 0; i < _modelNames.Count; ++i)
                {
                    if (!string.IsNullOrEmpty(_filter) && !_modelNames[i].Contains(_filter))
                    {
                        continue;
                    }

                    if (GUILayout.Button(_modelNames[i]))
                    {
                        _modelPathIndex = i;
                    }

                    if (_currentModelName != _modelNames[_modelPathIndex])
                    {
                        _currentModelName = _modelNames[_modelPathIndex];
                        LoadModel(_currentModelName);
                    }

                    if (_modelPathIndex == i)
                    {
                        GUILayout.BeginVertical(GUI.skin.box);
                        {
                            var skinnes = _currentModel.GetComponentsInChildren<Renderer>();
                            foreach (var skin in skinnes)
                            {
                                GUILayout.BeginVertical();
                                {
                                    GUILayout.Label(skin.name);

                                    GUILayout.BeginHorizontal();
                                    {
                                        DrawTexture(skin.sharedMaterial.GetTexture("_MainTex"), 64, 64);
                                        DrawTexture(skin.sharedMaterial.GetTexture("_BumpMap"), 64, 64);
                                        DrawTexture(skin.sharedMaterial.GetTexture("_MappingTex"), 64, 64);
                                    }
                                    GUILayout.EndHorizontal();
                                }
                                GUILayout.EndVertical();

                                ////关闭自阴影
                                //foreach (var mat in skin.materials) {
                                //    mat.DisableKeyword("USE_SELFSHADOW_ON");
                                //}
                            }
                        }
                        GUILayout.EndVertical();
                    }
                }
            }
            GUILayout.EndScrollView();
        }
        else if (_modelSkinTex == id) {

            if (_currentModelName.Contains("char")) {

                //获取皮肤名字后缀
                var renderers = _currentModel.GetComponentsInChildren<Renderer>();
                string renderType = renderers[0].GetType().Name;
                string skinMeshSuffix = "";
                if (renderType == "MeshRenderer")
                    skinMeshSuffix = renderers[0].name;
                else if(renderType == "SkinnedMeshRenderer")
                    skinMeshSuffix = renderers[0].transform.parent.name;
                string[] strs = skinMeshSuffix.Split('_');
                string skinName = strs[strs.Length - 1].Replace("(Clone)", "");

                var skinColorsPath = Directory.GetFiles(skinColorRootDir, "*.mat");
                GUILayout.BeginHorizontal();
                foreach (var skinColor in skinColorsPath)
                {
                    var skinColorName = Path.GetFileNameWithoutExtension(skinColor);
                    if (skinColorName.StartsWith("h_" + skinName) && skinColorName.EndsWith("_nrp"))
                    {
                        string skinPartName = skinColorName.Replace("_nrp", "").Replace("h_", "");
                        GUILayout.BeginVertical();
                        if (GUILayout.Button(skinPartName))
                        {
                            //给render换肤色
                            string curentSkinColorPath = skinColorRootDir + "h_" + skinPartName + "_nrp.mat";
                            foreach (var renderer in renderers)
                            {
                                Material[] mats = renderer.materials;
                                for (var i = 0; i < mats.Length; i++)
                                {
                                    if (mats[i].name.StartsWith("h_m") || mats[i].name.StartsWith("h_f"))
                                    {
                                        var skinMat = AssetDatabase.LoadAssetAtPath<Material>(curentSkinColorPath);
                                        mats[i] = skinMat;
                                    }
                                }
                                renderer.materials = mats;
                            }
                            Debug.Log("记录一下皮肤数据");
                            if (_skinColorDataDict.ContainsKey(_currentModelName))
                                _skinColorDataDict.Remove(_currentModelName);
                            _skinColorDataDict.Add(_currentModelName, curentSkinColorPath);
                            string jsonText = JsonConvert.SerializeObject(_skinColorDataDict);
                            WriteJsonText(SKIN_JSON_DATA_PATH, jsonText);
                            AssetDatabase.SaveAssets();
                            AssetDatabase.Refresh();
                        }
                        //显示各种类别肤色的贴图
                        GUILayout.BeginHorizontal();
                        GUILayout.Space(10);
                        Material mat = AssetDatabase.LoadAssetAtPath<Material>(skinColor);
                        Texture tex = mat.GetTexture("_MainTex");
                        DrawTexture(tex, 64, 64);
                        GUILayout.EndHorizontal();
                        GUILayout.EndVertical();
                    }
                }
                GUILayout.EndHorizontal();
            }
        }
    }

    private void Update()
    {
        if (_currentModel != null)
        {
            var validRenderers = _currentModel.GetComponentsInChildren<Renderer>(false);
            var mainLight = GameObject.Find("@PlayerNode/@LightPosition/@MainLight");

            for (var i = 0; i < validRenderers.Length; ++i)
            {
                if (mainLight != null)
                {
                    validRenderers[i].material.SetVector("_LightDir", -mainLight.transform.forward);
                }
                if (mainLight != null)
                {
                    validRenderers[i].material.SetColor("_LightColor", mainLight.GetComponent<Light>().color);
                }
            }
        }
    }

    public  string ReadJsonText(string _jsonFilePath)
    {
        //获取Resources文件夹下名为_dataName的文本文件
        TextAsset jsonTextAsset = AssetDatabase.LoadAssetAtPath<TextAsset>(_jsonFilePath);
        if (jsonTextAsset != null)
        {
            //返回文本文件内容
            return jsonTextAsset.text;
        }
        return null;
    }

    public  void WriteJsonText(string _jsonFilePath, string _jsonText)
    {
        StreamWriter writer = null;
        //得到文件信息
        FileInfo flagFile = new FileInfo(_jsonFilePath);
        //清空文件内容
        File.WriteAllText(_jsonFilePath, string.Empty);
        //得到写入流
        if (flagFile.Exists)
        {
            writer = flagFile.AppendText();
        }
        else
        {
            writer = flagFile.CreateText();
        }
        //向流里写入数据。
        writer.Write(_jsonText);
        writer.Flush();
        writer.Dispose();
        writer.Close();
    }
}


#endif