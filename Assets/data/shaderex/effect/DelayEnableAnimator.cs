using UnityEngine;
using System.Collections;

public class DelayEnableAnimator : MonoBehaviour
{
    public float _delayTime = 0;
	public string _animationName = null;
	
    void OnEnable()
    {
		StartCoroutine(Show());
    }

    IEnumerator Show()
    {
		var animator = GetComponent<Animator>();
        if (animator != null)
        {
            animator.enabled = false;
        }
		var renderer = GetComponent<Renderer>();
		if (renderer != null)
		{
			renderer.enabled = false;
		}
		
		yield return new WaitForSeconds(_delayTime);
        
        if (animator != null)
        {
            animator.enabled = true;
			if(string.IsNullOrEmpty(_animationName) == false)
			{
				animator.Play(_animationName);
			}
        }
		if (renderer != null)
		{
			renderer.enabled = true;
		}
        
    }
}