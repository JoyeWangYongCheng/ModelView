using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class Menu 
{
    [MenuItem("test/test")]
    private static void BuildAB()
    {
        BuildPipeline.BuildAssetBundles("Assets/data/runtime", BuildAssetBundleOptions.ChunkBasedCompression, BuildTarget.StandaloneWindows);
    }
}
