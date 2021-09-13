using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using UnityEditor;

public static class ModelJsonData  {

    public static string ReadJsonText(string _jsonFilePath) {
        //获取Resources文件夹下名为_dataName的文本文件
        TextAsset jsonTextAsset = AssetDatabase.LoadAssetAtPath<TextAsset>(_jsonFilePath);
        if (jsonTextAsset != null)
        {
            //返回文本文件内容
            return jsonTextAsset.text;
        }
        return null;
    }

    public static void WriteJsonText(string _jsonFilePath,string _jsonText) {
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
