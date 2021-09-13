using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

public class ReplaceShader  {

	[MenuItem("TA_Tools/ReplaceShader")]
	public static void ReplaceShaderFun(){
		string folderPath = Application.dataPath+"/data/model/char";	
		string[] guids = AssetDatabase.FindAssets("t:"+typeof(Material).Name);
		string shaderPath  = "streetball2/model_skin_runtime";
		string hairShaderPath = "streetball2/model_hair_runtime";
		string glassesShaderPath = "streetball2/model_alpha_runtime";

		foreach(string materialPath in guids){
			string path = AssetDatabase.GUIDToAssetPath(materialPath);
		// 	string path = AssetDatabase.GetAssetPath(material);
		
			if(path.Contains("Assets/data/model/char")){
				Material m = AssetDatabase.LoadAssetAtPath(path,typeof(Material)) as Material;
				if(m.shader.name!="Standard"){
					m.shader = Shader.Find(shaderPath);
				}
			}

			if(path.Contains("hair")){
			  Material m = AssetDatabase.LoadAssetAtPath(path,typeof(Material)) as Material;
			 m.shader = Shader.Find(hairShaderPath);
			}

			if(path.Contains("glasses")){
			  Material m = AssetDatabase.LoadAssetAtPath(path,typeof(Material)) as Material;
			 m.shader = Shader.Find(glassesShaderPath);
			}			


		}

		
		
	}

}
