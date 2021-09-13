using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerShaderHolder : MonoBehaviour
{

    public static PlayerShaderHolder _instance;
    public Shader[] _shaders;

    public static PlayerShaderHolder instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = (new GameObject("Holder")).AddComponent<PlayerShaderHolder>();
            }
            return _instance;
        }
    }

    public Shader FindShader(string name)
    {
        foreach (var shader in _shaders)
        {
            if (shader.name == name)
            {
                return shader;
            }
            if (shader.name == name + "_runtime")
            {
                return shader;
            }
        }
        return Shader.Find(name);
    }

    private void Awake()
    {
        _instance = this;
        var ab = AssetBundle.LoadFromFile("Assets/Script/pcr.bytes");
        _shaders = ab.LoadAllAssets<Shader>();
        ab.Unload(false);
    }

    private void OnDestroy()
    {
        _instance = null;
    }
}
