using UnityEngine;
using System.Collections;
public class CreateRuntime : MonoBehaviour {
	public AnimationCurve anim = new AnimationCurve();
	void Start() {
		Keyframe[] ks = new Keyframe[3];
		ks[0] = new Keyframe(0, 0);
		ks[0].inTangent = 0;
		ks[1] = new Keyframe(4, 0);
		ks[1].inTangent = 45;
		ks[2] = new Keyframe(8, 0);
		ks[2].inTangent = 90;
		anim = new AnimationCurve(ks);
	}
	void Update() {
		transform.position = new Vector3(Time.time, anim.Evaluate(Time.time), 0);
	}
}