using UnityEngine;
using System.Collections;

public class DelayEnableAnimatorList : MonoBehaviour
{
    public float _delayTime = 0;
	public string _animationName = null;
	
    void OnEnable()
    {
		StartCoroutine(Show());
    }

    IEnumerator Show()
    {
		var animatorList = GetComponentsInChildren<Animator>();
		for(int i = 0; i < animatorList.Length; ++i)		
		{
			animatorList[i].enabled = false;
		}
		
		yield return new WaitForSeconds(_delayTime);
        
		for(int i = 0; i < animatorList.Length; ++i)		
		{
			animatorList[i].enabled = true;
			if(string.IsNullOrEmpty(_animationName) == false)
			{
				animatorList[i].Play(_animationName);
			}
		}     
    }
}