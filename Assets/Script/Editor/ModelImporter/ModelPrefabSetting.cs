// ==============================================
// Author：qiuyukun
// Date:2019-04-28 18:03:55
// ==============================================

using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.IO;
using Framework;
using System.Reflection;

#region 序列化的组件

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Field)]
public class ComponentTypeAttribute : Attribute
{
    public Type cptType;
    public ComponentTypeAttribute(Type cptType)
    {
        this.cptType = cptType;
    }
}

[System.Serializable]
public class ComponentRoot
{
    //组件路径
    public string componentPath;
    public Vector3 localPosition;
    public Quaternion localRotation;
    public Vector3 localScale = Vector3.one;
}

[System.Serializable]
public class SerializationBase : ComponentRoot
{
    public SerializationBase(object src)
    {
        if (src == null) return;

        var cpt = src as Component;
        componentPath = GetTransformPath(cpt);
        localPosition = cpt.transform.localPosition;
        localRotation = cpt.transform.localRotation;
        localScale = cpt.transform.localScale;

        //类型检测
        Type srcType = src.GetType();
        Type type = this.GetType();
        var attributes = type.GetCustomAttributes(typeof(ComponentTypeAttribute), false);
        if (attributes.Length == 0 || ((ComponentTypeAttribute)attributes[0]).cptType != srcType)
        {
            return;
        }

        //设置变量
        var fields = type.GetFields(BindingFlags.Public | BindingFlags.DeclaredOnly | BindingFlags.Instance);
        foreach (var field in fields)
        {
            var srcField = srcType.GetField(field.Name);
            if (srcField == null)
            {
                Debug.LogErrorFormat("找不到对应的数据 : {0}", field.Name);
                continue;
            }
            var value = srcField.GetValue(src);
            SetValue(value, field);
        }
    }

    public virtual void ApplyToPrefab(GameObject root)
    {
        var rootTsfm = root.transform;
        var selfTsfm = GetOrCreateChild(rootTsfm, componentPath);
        selfTsfm.localPosition = localPosition;
        selfTsfm.localScale = localScale;
        selfTsfm.localRotation = localRotation;

        if (selfTsfm == null)
        {
            Debug.LogErrorFormat("找不到节点 {0}", componentPath);
            return;
        }

        var type = GetType();
        var attributes = type.GetCustomAttributes(typeof(ComponentTypeAttribute), false);
        if (attributes.Length == 0) return;

        var componentType = ((ComponentTypeAttribute)attributes[0]).cptType;
        var selfGo = selfTsfm.gameObject;
        var cpt = GetOrAddComponent(selfGo, componentType);
        var cptType = cpt.GetType();
        var fields = type.GetFields(BindingFlags.Instance | BindingFlags.Public | BindingFlags.DeclaredOnly);
        foreach (var field in fields)
        {
            var cptField = cptType.GetField(field.Name);
            if (cptField == null)
            {
                Debug.LogErrorFormat("找不到字段 : {0}", field.Name);
                continue;
            }
            ApplyValue(field, cptField, cpt, rootTsfm);
        }
    }

    private void ApplyValue(FieldInfo valueField, FieldInfo fieldInfo, object inst, Transform rootTsfm)
    {
        var value = valueField.GetValue(this);
        var valueType = valueField.FieldType;
        var fieldType = fieldInfo.FieldType;
        if (valueType == fieldType)
        {
            fieldInfo.SetValue(inst, value);
            return;
        }

        if (!CheckFieldType(valueField, fieldType)) return;

        //List<>
        if (valueType.IsGenericType && valueType.GetGenericTypeDefinition() == typeof(List<>))
        {
            PropertyInfo countPropertyInfo = valueType.GetProperty("Count");
            PropertyInfo thisPropertyInfo = valueType.GetProperty("Item");
            int count = (int)countPropertyInfo.GetValue(value, null);
            var fieldList = Activator.CreateInstance(fieldType);
            var genericType = ModelPrefabSetting.GetGenericType(fieldType);

            for (int i = 0; i < count; ++i)
            {
                var listValue = thisPropertyInfo.GetValue(value, new object[] { i });
                var tsfm = GetOrCreateChild(rootTsfm, listValue as string);
                if (tsfm == null) continue;
                var cpt = GetOrAddComponent(tsfm.gameObject, genericType);
                fieldType.GetMethod("Add").Invoke(fieldList, new object[] { cpt });
            }
            fieldInfo.SetValue(inst, fieldList);
        }
        else
        {
            string path = value as string;
            if (string.IsNullOrEmpty(path)) return;
            var tsfm = GetOrCreateChild(rootTsfm, path);
            if (tsfm == null) return;
            var cpt = GetOrAddComponent(tsfm.gameObject, fieldType);
            fieldInfo.SetValue(inst, cpt);
        }
    }

    //类型检测
    private bool CheckFieldType(FieldInfo field, Type type)
    {
        var attribute = ModelPrefabSetting.GetAttribute<ComponentTypeAttribute>(field);
        if (attribute == null || attribute.cptType != type)
        {
            Debug.LogErrorFormat("字段类型错误 {0}", field.Name);
            return false;
        }
        return true;
    }

    protected Component GetOrAddComponent(GameObject go, Type type)
    {
        var cpt = go.GetComponent(type);
        if (cpt == null)
            cpt = go.AddComponent(type);
        return cpt;
    }

    protected Transform GetOrCreateChild(Transform tsfm, string path)
    {
        var result = tsfm.Find(path);
        if (result == null)
        {
            //如果能找到父节点,则创建新的节点
            string parentPath = Path.GetDirectoryName(path);
            var parent = tsfm.Find(parentPath);
            if (parent == null)
                Debug.LogErrorFormat("找不到节点 {0}", path);
            else
            {
                string childName = Path.GetFileName(path);
                GameObject go = new GameObject(childName);
                result = go.transform;
                result.SetParent(parent, false);
            }
        }
        return result;
    }

    protected void SetValue(object value, FieldInfo field)
    {
        var valueType = value.GetType();
        var fieldType = field.FieldType;
        if (fieldType == valueType)
        {
            field.SetValue(this, value);
            return;
        }

        if (!CheckFieldType(field, valueType)) return;

        //List<>
        if (valueType.IsGenericType && valueType.GetGenericTypeDefinition() == typeof(List<>))
        {
            PropertyInfo countPropertyInfo = valueType.GetProperty("Count");
            PropertyInfo thisPropertyInfo = valueType.GetProperty("Item");
            int count = (int)countPropertyInfo.GetValue(value, null);
            var fieldList = field.GetValue(this);
            for (int i = 0; i < count; ++i)
            {
                var listValue = thisPropertyInfo.GetValue(value, new object[] { i });
                string path = GetTransformPath(listValue as Component);
                fieldType.GetMethod("Add").Invoke(fieldList, new object[] { path });
            }
        }
        else
        {
            string path = GetTransformPath(value as Component);
            field.SetValue(this, path);
        }
    }

    //向上查找组件在Transform中的路径
    protected string GetTransformPath(Component component, string path = null)
    {
        if (component == null) return path;
        var tsfm = component.transform;
        if (tsfm.root == tsfm.parent)
            return string.Format("{0}/{1}", tsfm.name, path);
        if (path != null)
            path = string.Format("{0}/{1}", tsfm.name, path);
        else
            path = tsfm.name;
        return GetTransformPath(tsfm.parent, path);
    }
}

[ComponentType(typeof(DynamicBoneCollider))]
[System.Serializable]
public class DynamicBoneColliderSetting : SerializationBase
{
    public DynamicBoneColliderSetting(object src) : base(src) { }

    public Vector3 m_Center = Vector3.zero;
    public float m_Radius = 0.5f;
    public float m_Height = 0;
    public DynamicBoneCollider.Direction m_Direction = DynamicBoneCollider.Direction.X;
    public DynamicBoneCollider.Bound m_Bound = DynamicBoneCollider.Bound.Outside;
}

[ComponentType(typeof(DynamicBone))]
[System.Serializable]
public class DynamicBoneSetting : SerializationBase
{
    public DynamicBoneSetting(object src) : base(src) { }

    [ComponentType(typeof(Transform))]
    public string m_Root = null;
    public float m_UpdateRate = 60.0f;
    [Range(0, 1)]
    public float m_Damping = 0.1f;
    public AnimationCurve m_DampingDistrib = null;
    [Range(0, 1)]
    public float m_Elasticity = 0.1f;
    public AnimationCurve m_ElasticityDistrib = null;
    [Range(0, 1)]
    public float m_Stiffness = 0.1f;
    public AnimationCurve m_StiffnessDistrib = null;
    [Range(0, 1)]
    public float m_Inert = 0;
    public AnimationCurve m_InertDistrib = null;
    public float m_Radius = 0;
    public AnimationCurve m_RadiusDistrib = null;

    public float m_EndLength = 0;
    public Vector3 m_EndOffset = Vector3.zero;
    public Vector3 m_Gravity = Vector3.zero;
    public Vector3 m_Force = Vector3.zero;
    [ComponentType(typeof(List<DynamicBoneCollider>))]
    public List<string> m_Colliders = new List<string>();
    [ComponentType(typeof(List<Transform>))]
    public List<string> m_Exclusions = new List<string>();

    public DynamicBone.FreezeAxis m_FreezeAxis = DynamicBone.FreezeAxis.None;
    public bool m_DistantDisable = false;
    [ComponentType(typeof(Transform))]
    public string m_ReferenceObject = null;
    public float m_DistanceToObject = 20;
}

#endregion

[CreateAssetMenu(fileName = "ModelPrefabSetting", menuName = "Create Model Setting")]
public class ModelPrefabSetting : ScriptableObject
{
    private const string MODEL_CHAR_PATH = "Assets/_Models/char/";
    private const string MODEL_SKIN_PATH = "Assets/_Models/skin/";
    //背饰挂点路径
    private const string BACK_POINT_PATH = "Dummy001/Bip001/Bip001 Pelvis/Bip001 Spine/Bip001 Spine1/Bip001 Spine2/Bip001 Spine3/back_point";
    //上衣预制件名字
    private const string JACKET_NAME = "jacket";

    public List<DynamicBoneSetting> dynamicBoneSettingList = new List<DynamicBoneSetting>();
    public List<DynamicBoneColliderSetting> dynamicBoneColliderSettingList = new List<DynamicBoneColliderSetting>();
    public List<ComponentRoot> pointList = new List<ComponentRoot>();

    //设置Prefab
    public void ApplyToPrefab(GameObject prefab)
    {
        var type = GetType();
        var fields = type.GetFields(BindingFlags.Instance | BindingFlags.Public);
        foreach(var field in fields)
        {
            var fieldType = field.FieldType;
            if (fieldType.IsGenericType)
            {
                var genericType = GetGenericType(field.FieldType);
                if (GetAttribute<ComponentTypeAttribute>(genericType) == null) continue;
                var applyMethod = genericType.GetMethod("ApplyToPrefab");
                var fieldValue = field.GetValue(this);
                PropertyInfo countPropertyInfo = fieldType.GetProperty("Count");
                PropertyInfo thisPropertyInfo = fieldType.GetProperty("Item");
                int count = (int)countPropertyInfo.GetValue(fieldValue, null);
                for (int i = 0; i < count; ++i)
                {
                    var item = thisPropertyInfo.GetValue(fieldValue, new object[] { i });
                    applyMethod.Invoke(item, new object[] { prefab });
                }
            }
        }

        //单独处理挂点
        var tsfm = prefab.transform;
        foreach (var each in pointList)
        {
            var path = each.componentPath;
            string pointParentPath = Path.GetDirectoryName(path);
            string pointName = Path.GetFileName(path);
            var parent = tsfm.Find(pointParentPath);
            if (parent == null)
            {
                Debug.LogErrorFormat("找不到挂点父节点 {0}", pointParentPath);
                return;
            }

            var point = parent.Find(pointName);
            if (point == null)
            {
                point = new GameObject(pointName).transform;
                point.SetParent(parent, false);
            }
                
            point.localPosition = each.localPosition;
            point.localRotation = each.localRotation;
            point.localScale = each.localScale;
        }
    }

    #region static

    //获取泛型类型
    public static Type GetGenericType(Type generic)
    {
        if (!generic.IsGenericType) return null;
        var types = generic.GetGenericArguments();
        if (types.Length == 1) return types[0];
        return null;
    }

    public static T GetAttribute<T>(MemberInfo member) where T : Attribute
    {
        var attributes = member.GetCustomAttributes(typeof(T), false);
        if (attributes.Length > 0)
            return attributes[0] as T;
        return null;
    }

    [MenuItem("Framework/Streetball2/Create Model Prefab Setting &s")]
    public static void CreateModelPrefabSetting()
    {
        var objs = Selection.objects;
        if (objs.Length == 0)
        {
            Debug.LogError("未选中任何预制件");
            return;
        }

        foreach (var obj in objs)
        {
            var path = AssetDatabase.GetAssetPath(obj.GetInstanceID());
            var setting = CopyFromPrefab(path);
            if (setting != null)
            {
                string fileName = Path.GetFileNameWithoutExtension(path);
                string fullDir = Path.GetDirectoryName(path);
                string dirName = Path.GetFileName(fullDir);
                bool isChar = path.StartsWith(ModelImportWindow.modelRootFolder+"char");
                string rootPath = isChar ? MODEL_CHAR_PATH : MODEL_SKIN_PATH;
                if (isChar)
                {
                    int index = dirName.IndexOf('_');
                    dirName = dirName.Substring(index + 1);
                }
                else
                    dirName = dirName.Replace('_', '/');

                string modelPath = rootPath+dirName;
                if (!Directory.Exists(modelPath))
                {
                    Debug.LogErrorFormat("找不到模型配置输出路径 : {0}", modelPath);
                    return;
                }

                modelPath = string.Format("{0}/{1}{2}", modelPath,
                    fileName, ModelInventory.MODEL_PREFAB_SETTING_EXTENSION);
                AssetDatabase.CreateAsset(setting, modelPath);
                Debug.LogFormat("生成配置文件 : {0}", modelPath);
            }
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    //从一个预制件中生成对应的配置文件
    public static ModelPrefabSetting CopyFromPrefab(string prefabPath)
    {
        if (!CheckPrefabPath(prefabPath)) return null;

        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
        List<Type> typeList = GetSettingTypes();
        List<Component> componentList = FindComponents(prefab, typeList);
        //组件设置
        ModelPrefabSetting setting = CreateInstance<ModelPrefabSetting>();
        foreach (var each in componentList)
        {
            AddComponentSetting(each, setting);
        }

        //背饰挂点设置
        if (prefab.name.Contains(JACKET_NAME))
        {
            SetPointSetting(prefab, BACK_POINT_PATH, setting);
        }
        return setting;
    }

    //设置挂点
    private static void SetPointSetting(GameObject prefab, string path, ModelPrefabSetting setting)
    {
        var tsfm = prefab.transform;
        string pointParentPath = Path.GetDirectoryName(path);
        string pointName = Path.GetFileName(path);
        var parent = tsfm.Find(pointParentPath);
        if (parent == null)
        {
            Debug.LogErrorFormat("找不到挂点父节点 {0}", pointParentPath);
            return;
        }

        var cptRoot = new ComponentRoot();
        cptRoot.componentPath = path;
        var point = parent.Find(pointName);
        if (point != null)
        {
            cptRoot.localPosition = point.localPosition;
            cptRoot.localRotation = point.localRotation;
            cptRoot.localScale = point.localScale;
        }
        else
        {
            cptRoot.localPosition = parent.InverseTransformPoint(Vector3.zero);
            cptRoot.localRotation = parent.worldToLocalMatrix.rotation;
        }
        setting.pointList.Add(cptRoot);
    }

    //添加一个组件配置
    private static void AddComponentSetting(Component cpt, ModelPrefabSetting setting)
    {
        Type settingType = setting.GetType();
        Type cptType = cpt.GetType();
        var fields = settingType.GetFields(BindingFlags.Instance | BindingFlags.Public);
        foreach (var field in fields)
        {
            var fieldType = field.FieldType;
            var genericType = GetGenericType(fieldType);
            if (genericType == null) continue;
            var attribute = GetAttribute<ComponentTypeAttribute>(genericType);
            if (attribute != null && fieldType.IsGenericType && attribute.cptType == cptType)
            {
                //构造函数中会做相应处理
                var value = Activator.CreateInstance(genericType, new object[] { cpt });
                fieldType.GetMethod("Add").Invoke(field.GetValue(setting), new object[] { value });
            }
        }
    }

    //获取程序集中所有配置类型
    private static List<Type> GetSettingTypes()
    {
        var list = new List<Type>();
        var assembly = Assembly.GetExecutingAssembly();
        var types = assembly.GetTypes();
        foreach (var type in types)
        {
            var att = GetAttribute<ComponentTypeAttribute>(type);
            if (att != null)
                list.Add(att.cptType);
        }
        return list;
    }

    private static List<Component> FindComponents(GameObject root, List<Type> componentList)
    {
        var results = new List<Component>();
        foreach (var each in componentList)
        {
            results.AddRange(root.GetComponentsInChildren(each));
        }
        return results;
    }

    //检测预制件路径
    private static bool CheckPrefabPath(string prefabPath)
    {
        if (!prefabPath.EndsWith(ModelImportWindow.PREFAB_EXTENSION))
        {
            Debug.LogErrorFormat("不是预制件 {0}", prefabPath);
            return false;
        }

        if (!File.Exists(prefabPath))
        {
            Debug.LogErrorFormat("找不到预制件 {0}", prefabPath);
            return false;
        }
        return true;
    }
    #endregion
}