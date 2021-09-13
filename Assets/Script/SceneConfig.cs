using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Framework
{
    public class SceneConfig : MonoBehaviour
    {
        public Light _mainLight;
        public Transform _lightRoot;
        public Material _planeShadowMaterial;
        public bool _enableDynamicShadow = false;
        public Transform _dynamicShadowRender;
        public Transform _playerNode;
        public Transform _root;
        public bool useRT = false;
        public Camera _mainCamera;
        public Camera _fogCamera;
        public float _cameraAspect = 1;// Screen.width / Screen.height;
        public bool _resetParentToNull = true;
        public float _defaultShadowY = 0.01f;

        public GameObject _animSkinBallNet = null; //动画·篮球网节点
        public GameObject _physicsBallNet = null; //物理·篮球网节点
        public Transform _physicsBallNetParent = null; //物理篮球网父节点，篮球网动态挂到此节点下

        private static List<SceneConfig> _sceneConfigs = new List<SceneConfig>();
        private RenderTexture _renderTexture;

        private void Start()
        {
            ShadowCamera.Reset(_mainLight, _mainCamera, _dynamicShadowRender, 0);
        }

    }
}