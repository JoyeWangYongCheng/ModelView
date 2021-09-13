using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShadowCameraGUI : MonoBehaviour
{

	private ShadowCamera m_shadowcamera;

	private bool m_ShowDepthTextures = false;

	private int m_selRes = 0;
	
	private string[] m_textureSizeStr = new string[]{ "LOW : 128x128", "MID : 256x256", "HIGH : 512x512", "VERY_HIGH : 1024x1024" } ;
	
	// Use this for initialization
	void Start ()
	{
		m_shadowcamera = GetComponent<ShadowCamera>();
		//ShadowCamera.ShadowQuality sq = m_shadowcamera.m_shadowQuality;

		//switch (sq)
		//{
		//	case ShadowCamera.ShadowQuality.LOW:
		//		m_selRes = 0;
		//		break;
		//	case ShadowCamera.ShadowQuality.MID:
		//		m_selRes = 1;
		//		break;
		//	case ShadowCamera.ShadowQuality.HIGH:
		//		m_selRes = 2;
		//		break;
		//	case ShadowCamera.ShadowQuality.VERY_HIGH:
		//		m_selRes = 3;
		//		break;
		//}
	}
	
	// Update is called once per frame
	void Update () {
		
	}

	private void OnGUI()
	{

		if (GUI.Button(new Rect(0, 0, 150, 50), String.Format("启用阴影：{0}", m_shadowcamera.enabled ? "ON" : "OFF")))
		{
			m_shadowcamera.enabled = !m_shadowcamera.enabled;
		}

		if (GUI.Button(new Rect(0, 55, 150, 50), String.Format("启用半透明阴影：{0}", m_shadowcamera.SupportTransparent ? "ON" : "OFF")))
		{
			m_shadowcamera.SupportTransparent = !m_shadowcamera.SupportTransparent;
		}

		if (GUI.Button(new Rect(0, 110, 150, 50), String.Format("32BITS_DEPTH：{0}", m_shadowcamera.Use32BitsDepth ? "ON" : "OFF")))
		{
			m_shadowcamera.Use32BitsDepth = !m_shadowcamera.Use32BitsDepth;
		}
		
		if (GUI.Button(new Rect(0, 165, 150, 50), String.Format("显示深度纹理：{0}", m_ShowDepthTextures ? "ON" : "OFF")))
		{
			m_ShowDepthTextures = !m_ShowDepthTextures;
		}
		if (m_ShowDepthTextures)
		{
			if (m_shadowcamera.CharShadowMap)
			{
				GUI.DrawTexture(new Rect(0,Screen.height-200,200,200),m_shadowcamera.CharShadowMap,ScaleMode.StretchToFill,false,0);	
			}

			if (m_shadowcamera.CharShadowMapTranparent)
			{
				GUI.DrawTexture(new Rect(210,Screen.height-200,200,200),m_shadowcamera.CharShadowMapTranparent,ScaleMode.StretchToFill,false,0);	
			}
			
		}
	//	GUI.DrawTexture(new Rect(0,100,100,100),m_shadowcamera.m_charShadowMap,ScaleMode.StretchToFill,false,1);

	    m_selRes = GUI.Toolbar(new Rect(Screen.width - 700, 0, 700, 50), m_selRes, m_textureSizeStr);
		
	    switch (m_selRes)
	    {
		    case 0:
			    m_shadowcamera.CharShadowQuality = ShadowCamera.ShadowQuality.LOW;
			    break;
		    case 1:
			    m_shadowcamera.CharShadowQuality = ShadowCamera.ShadowQuality.MID;
			    break;
		    case 2:
			    m_shadowcamera.CharShadowQuality = ShadowCamera.ShadowQuality.HIGH;
			    break;
		    case 3:
			    m_shadowcamera.CharShadowQuality = ShadowCamera.ShadowQuality.VERY_HIGH;
			    break;
	    } 
	    
	}
}
