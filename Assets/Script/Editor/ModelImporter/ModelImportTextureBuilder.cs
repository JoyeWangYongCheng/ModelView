// ==============================================
// Author：qiuyukun
// Date:2019-05-05 17:55:11
// ==============================================

using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class ModelImportTextureBuilder
{
    //key: 贴图名字 key2 贴图类型
    public Dictionary<string, TextureFileInfo> textureFileInfoDict = new Dictionary<string, TextureFileInfo>();
    
    private OutputReference outputReference;

    public ModelImportTextureBuilder(string srcPath, OutputReference outputPath)
    {
        outputReference = outputPath;

        foreach (var folder in Directory.GetDirectories(srcPath))
        {
            InitFolderTextures(folder);
        }
    }
    //遍历所有贴图，把高模贴图添加进去
    private void InitFolderTextures(string folder)
    {
        string[] tgaFiles = Directory.GetFiles(folder, "*" + ModelInventory.TGA_EXTENSION, SearchOption.TopDirectoryOnly);
        int count = tgaFiles.Length;
        for (int i = 0; i < count; ++i)
        {
            var tgaFile = tgaFiles[i].Replace("\\","/");
            EditorUtility.DisplayProgressBar("导入贴图", tgaFile, (float)i / (count - 1));
            string texName = Path.GetFileName(tgaFile);
            if (texName.StartsWith("h_"))
            {
                string texNameWithout = Path.GetFileNameWithoutExtension(tgaFile);
                string texPartName = texNameWithout.Split('_')[1];
                var textureFileInfo = new TextureFileInfo();
                textureFileInfo.texName = texNameWithout;
                textureFileInfo.srcTexPath = tgaFile;
                textureFileInfo.texFolderName = Directory.GetParent(tgaFile).Name;
                //设置贴图类型
                int index = texNameWithout.LastIndexOf('_');
                string type = texNameWithout.Substring(index + 1).ToLower();
                switch (type)
                {
                    case "d":
                        textureFileInfo.texType = "_MainTex";
                        foreach (var mainTexFolder in outputReference.mainTexFolderPath)
                        {
                            if (Path.GetFileName(mainTexFolder).Split('_')[2] ==(texPartName))
                            {
                                textureFileInfo.destTexPath = mainTexFolder + "/" + texName;
                            }
                        }
                        break;
                    case "m":
                        textureFileInfo.texType = "_MappingTex";
                        foreach (var mainTexFolder in outputReference.mainTexFolderPath)
                        {
                            if (Path.GetFileName(mainTexFolder).Split('_')[2]==(texPartName))
                            {
                                textureFileInfo.destTexPath = mainTexFolder + "/" + texName;
                            }
                        }
                        break;
                    case "n":
                        textureFileInfo.texType = "_BumpMap";
                        textureFileInfo.destTexPath = outputReference.normalTexFolderPath + "/" + texName;
                        break;
                    case "aniso":
                        textureFileInfo.texType = "_AnisoTex";
                        textureFileInfo.destTexPath = outputReference.normalTexFolderPath + "/" + texName;
                        break;

                }

                if (!textureFileInfoDict.ContainsKey(texNameWithout))
                    textureFileInfoDict.Add(texNameWithout, textureFileInfo);
            }
        }
    }
}
