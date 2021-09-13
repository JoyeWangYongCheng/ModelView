// ==============================================
// Author：qiuyukun
// Date:2019-04-28 18:03:55
// ==============================================

using Framework;
using System.IO;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 图片导入设置
/// </summary>
public class ModelImportSetting : AssetPostprocessor
{
    //纹理导入之前调用
    public void OnPreprocessTexture()
    {
        //只处理这两个目录下的贴图
        var path = assetPath;
        if (!path.StartsWith(ModelImportWindow.mainTexRootFolder)
            && !path.StartsWith(ModelImportWindow.normalTexRootFolder))
        {
            return;
        }

        var importer = assetImporter as TextureImporter;
        importer.mipmapEnabled = false;

        //设置图片格式
        bool hasAlpha = importer.DoesSourceTextureHaveAlpha();
        if (path.StartsWith(ModelImportWindow.normalTexRootFolder))
        {
            //var format = hasAlpha ? TextureImporterFormat.RGBA16 : TextureImporterFormat.RGB16;
            importer.SetPlatformTextureSettings(new TextureImporterPlatformSettings() { name = "Standalone", overridden = true, maxTextureSize = 512 });
            importer.SetPlatformTextureSettings(new TextureImporterPlatformSettings() { name = "iPhone", overridden = true, maxTextureSize = 512 });
            importer.SetPlatformTextureSettings(new TextureImporterPlatformSettings() { name = "Android", overridden = true, maxTextureSize = 512 });
        }
        else
        {
            importer.SetPlatformTextureSettings(new TextureImporterPlatformSettings() { name = "Standalone", overridden = false, maxTextureSize = 512 });
            importer.SetPlatformTextureSettings(new TextureImporterPlatformSettings() { name = "iPhone", overridden = false, maxTextureSize = 512 });
            importer.SetPlatformTextureSettings(new TextureImporterPlatformSettings() { name = "Android", overridden = false, maxTextureSize = 512 });
        }
    }

    //模型导入之前调用
    public void OnPostprocessModel(GameObject go)
    {
        //只处理这两个目录下的模型
        var path = assetPath;
        if (!path.StartsWith(ModelImportWindow.modelRootFolder))
        {
            return;
        }

        var modelImporter = assetImporter as ModelImporter;
        modelImporter.importMaterials = false;
        //AssetDatabase.Refresh();
    }
}
