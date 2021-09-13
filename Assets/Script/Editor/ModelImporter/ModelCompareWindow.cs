// ==============================================
// Author：qiuyukun
// Date:2019-05-27 14:57:28
// ==============================================

using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 模型比较窗口,用于比较模型骨骼是否有变化
/// </summary>
public class ModelCompareWindow : EditorWindow
{
    private class DifferenceBone
    {
        public enum DifferenceType
        {
            Transform,
            Lack,
        }

        public Transform bone1;
        public Transform bone2;
        public DifferenceType type;
    }

    private Transform model1;
    private Transform model2;

    private List<DifferenceBone> _differentList = new List<DifferenceBone>();

    [MenuItem("Framework/Streetball2/Model Compare Window &f")]
    private static void Open()
    {
        ModelCompareWindow wnd = (ModelCompareWindow)EditorWindow.GetWindow(typeof(ModelCompareWindow), false, "模型比较", true);
        wnd.maxSize = new Vector2(500, 800);
        wnd.Show();
    }

    private void OnGUI()
    {
        EditorGUILayout.BeginHorizontal();
        model1 = EditorGUILayout.ObjectField(model1, typeof(Transform), true) as Transform;
        model2 = EditorGUILayout.ObjectField(model2, typeof(Transform), true) as Transform;
        EditorGUILayout.EndHorizontal();

        var style = new GUIStyle();
        style.fixedWidth = 50;
        style.stretchWidth = false;
        foreach (var each in _differentList)
        {
            EditorGUILayout.BeginHorizontal();
            style.normal.textColor = each.type == DifferenceBone.DifferenceType.Transform ? Color.yellow : Color.red;
            EditorGUILayout.LabelField(each.type.ToString(), style);
            EditorGUILayout.ObjectField(each.bone1, typeof(Transform), true);
            EditorGUILayout.ObjectField(each.bone2, typeof(Transform), true);
            EditorGUILayout.EndHorizontal();
        }

        if (GUILayout.Button("检测", new GUILayoutOption[] { GUILayout.Height(50) }))
        {
            _differentList.Clear();
            Check(model1, model2);
        }
    }

    private void Check(Transform lhs, Transform rhs)
    {
        if(lhs == null || rhs == null)
            return;

        if(lhs.localPosition != rhs.localPosition 
            || lhs.localRotation != rhs.localRotation
            || lhs.localScale != rhs.localScale)
        {
            CreateDifferenceBone(lhs, rhs, DifferenceBone.DifferenceType.Transform);
        }

        int count = lhs.childCount;
        for (int i = 0; i < count; ++i)
        {
            var nextLhs = lhs.GetChild(i);
            var nextRhs = rhs.Find(nextLhs.name);
            if (nextRhs == null)
            {
                CreateDifferenceBone(nextLhs, null, DifferenceBone.DifferenceType.Lack);
                continue;
            }
            Check(nextLhs, nextRhs);
        }
    }

    private void CreateDifferenceBone(Transform bone1, Transform bone2, DifferenceBone.DifferenceType type)
    {
         var differenceBone =  new DifferenceBone()
        {
            bone1 = bone1,
            bone2 = bone2,
            type = type,
        };
        _differentList.Add(differenceBone);
    }
}
