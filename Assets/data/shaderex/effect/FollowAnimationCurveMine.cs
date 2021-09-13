using UnityEngine;
using System.Collections;
public class FollowAnimationCurveMine : MonoBehaviour {
	public AnimationCurve curveX;
	public void SetCurves(AnimationCurve tmpCurve)
	{
		curveX = tmpCurve;
	}
	void Update () {
		if(curveX != null)
			transform.position = new Vector3(1f*Time.time, curveX.Evaluate(Time.time) * 0.3f,0);
	}
}