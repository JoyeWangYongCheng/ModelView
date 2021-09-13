// ==============================================
// Author：qiuyukun
// Date:2019-07-02 16:23:34
// ==============================================

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

/// <summary>
/// 创建模型特效挂点
/// </summary>
public class ModelPointTool
{
    //特效挂点路径
    private const string EFFECT_POINT_PARENT_PATH = "Dummy001/Bip001/Bip001 Pelvis/Bip001 Spine/Bip001 Spine1/Bip001 Spine2/Bip001 Spine3";
    //背饰挂点名称
    private const string BACK_POINT_NAME = "back_point";

    /// <summary>
    /// 创建背饰挂点
    /// </summary>
    [MenuItem("Framework/Streetball2/Create Back Point")]
    private static void CreateBackPoint()
    {
        List<GameObject> selectedList = new List<GameObject>();

        foreach (var each in Selection.gameObjects)
        {
            var tsfm = each.transform;
            var parent = tsfm.Find(EFFECT_POINT_PARENT_PATH);
            if (parent != null)
            {
                var go = new GameObject(BACK_POINT_NAME);
                go.transform.SetParent(parent, false);
                go.transform.localPosition = parent.InverseTransformPoint(Vector3.zero);
                go.transform.localRotation = parent.worldToLocalMatrix.rotation;
                selectedList.Add(go);
            }
        }
        Selection.objects = selectedList.ToArray();
    }
}
