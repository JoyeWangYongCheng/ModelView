#pragma strict

///////////////////////////////////////////////
//// 			BlackishGUI.js             ////
//// copyright (c) 2010-13 by Markus Hofer ////
////          for GameAssets.net           ////
///////////////////////////////////////////////

class BlackishGUI extends MonoBehaviour {

	//OnOff Slider Switch
	static function OnOffSwitch(pos : Vector2, onOff : float, style : GUIStyle, thumbStyle : GUIStyle) { return OnOffSwitch(pos, onOff, style, thumbStyle, 1.0); }
	static function OnOffSwitch(pos : Vector2, onOff : float, style : GUIStyle, thumbStyle : GUIStyle, factor: float) {
		return OnOffSwitch(new Rect(pos.x, pos.y, 121 * factor, 42 * factor), onOff, style, thumbStyle);	
	}
	
	
	static function OnOffSwitch(screenRect : Rect, onOff : float, style : GUIStyle, thumbStyle : GUIStyle) {
		onOff = GUI.HorizontalSlider(screenRect, onOff, 0.0, 1.0, style, thumbStyle);
		if(Input.GetMouseButtonUp(0)) {
			if(onOff > 0.5) onOff = 1.0;
			else onOff = 0.0;
		}
		return onOff;
	}
	
	
	//OnOff Slider Switch with Label
	static function OnOffSwitchWithLabel(screenRect : Rect, onOff : float, labelText : String, style : GUIStyle, thumbStyle : GUIStyle, labelStyle : GUIStyle) { return OnOffSwitchWithLabel(screenRect, onOff, labelText, style, thumbStyle, labelStyle, 1.0); }
	static function OnOffSwitchWithLabel(screenRect : Rect, onOff : float, labelText : String, style : GUIStyle, thumbStyle : GUIStyle, labelStyle : GUIStyle, factor : float) {
	
		GUI.Label(new Rect(screenRect.x, screenRect.y, screenRect.width - (121 * factor) + (3 * factor), screenRect.height), labelText, labelStyle);
		onOff = OnOffSwitch(new Vector2(screenRect.x + screenRect.width - (121 * factor), screenRect.y), onOff, style, thumbStyle, factor);
		return onOff;
	}
	
	
	//Horizontal Slider with Label

	static function HorizontalSliderWithLabel(screenRect : Rect, labelWidth : float, value: float, from : float, to : float, labelText : String) { return HorizontalSliderWithLabel(screenRect, labelWidth, value, from, to, labelText, GUI.skin.GetStyle("musicSlider"), GUI.skin.GetStyle("onOffSliderThumb"), GUI.skin.GetStyle("SliderLabel"), 1.0); }
	static function HorizontalSliderWithLabel(screenRect : Rect, labelWidth : float, value: float, labelText) { return HorizontalSliderWithLabel(screenRect, labelWidth, value, 0.0, 1.0, labelText, GUI.skin.GetStyle("musicSlider"), GUI.skin.GetStyle("onOffSliderThumb"), GUI.skin.GetStyle("SliderLabel"), 1.0); }
	static function HorizontalSliderWithLabel(screenRect : Rect, labelWidth : float, value : float, labelText : String, style : GUIStyle, thumbStyle : GUIStyle, labelStyle : GUIStyle) { return HorizontalSliderWithLabel(screenRect, labelWidth, value, 0.0, 1.0, labelText, style, thumbStyle, labelStyle, 1.0); }
	static function HorizontalSliderWithLabel(screenRect : Rect, labelWidth : float, value : float, labelText : String, style : GUIStyle, thumbStyle : GUIStyle, labelStyle : GUIStyle, factor : float) { return HorizontalSliderWithLabel(screenRect, labelWidth, value, 0.0, 1.0, labelText, style, thumbStyle, labelStyle, 1.0); }
	static function HorizontalSliderWithLabel(screenRect : Rect, labelWidth : float, value : float, from : float, to : float, labelText : String, style : GUIStyle, thumbStyle : GUIStyle, labelStyle : GUIStyle, factor : float) {
		GUI.Label(new Rect(screenRect.x, screenRect.y, (labelWidth + 3) * factor, screenRect.height), labelText, labelStyle);
		return GUI.HorizontalSlider(new Rect(screenRect.x + labelWidth * factor, screenRect.y, screenRect.width - labelWidth * factor, screenRect.height), value, from, to, style, thumbStyle);
	}
	
	
	
	//TextFields
	static function TextFieldWithX(screenRect : Rect, nameString : String, flen : int, pw : boolean, maskChar : char, fieldName : String) {
		if(GUI.Button(new Rect(screenRect.x + screenRect.width - 29, screenRect.y + 12, 19, 19), "", GUI.skin.GetStyle("xButton"))) {
			nameString = "";
			GUI.FocusControl (fieldName);
		} //THIS IS A HACK - we have to draw the button below the text field as well, because the one on top doesn't register when clicked
		GUI.SetNextControlName (fieldName);
		if(pw) nameString = GUI.PasswordField(screenRect, nameString, maskChar, flen, GUI.skin.GetStyle("TextFieldWithX"));
		else nameString = GUI.TextArea(screenRect, nameString, flen, GUI.skin.GetStyle("TextFieldWithX")); //This should really be a TextField, but if I make it a TextField it behaves like a TextArea. Weird stuff...
		if(GUI.Button(new Rect(screenRect.x + screenRect.width - 29, screenRect.y + 12, 19, 19), "", GUI.skin.GetStyle("xButton"))) {
			nameString = "";
			GUI.FocusControl (fieldName);
		} //HACK: we still need the one on top to show the highlight, though...
		return nameString;
	}

	static function TextFieldWithX(screenRect : Rect, nameString : String) { return TextFieldWithX(screenRect, nameString, 255, false, "*"[0], "Field" + screenRect.x + "" + screenRect.y); }
	static function TextFieldWithX(screenRect : Rect, nameString : String, flen : int) { return TextFieldWithX(screenRect, nameString, flen, false, "*"[0], "Field" + screenRect.x + "" + screenRect.y); }

	static function TextFieldWithX(screenRect : Rect, nameString : String, fieldName : String) { return TextFieldWithX(screenRect, nameString, 255, false, "*"[0], fieldName); }
	static function TextFieldWithX(screenRect : Rect, nameString : String, flen : int, fieldName : String) { return TextFieldWithX(screenRect, nameString, flen, false, "*"[0], fieldName); }

	static function PasswordFieldWithX(screenRect : Rect, nameString : String) { return TextFieldWithX(screenRect, nameString, 255, true, "*"[0], "Field" + screenRect.x + "" + screenRect.y); }
	static function PasswordFieldWithX(screenRect : Rect, nameString : String, flen : int) { return TextFieldWithX(screenRect, nameString, flen, true, "*"[0], "Field" + screenRect.x + "" + screenRect.y); }
	static function PasswordFieldWithX(screenRect : Rect, nameString : String, maskChar : char) { return TextFieldWithX(screenRect, nameString, 255, true, maskChar, "Field" + screenRect.x + "" + screenRect.y); }
	static function PasswordFieldWithX(screenRect : Rect, nameString : String, maskChar : char, flen : int) { return TextFieldWithX(screenRect, nameString, flen, true, maskChar, "Field" + screenRect.x + "" + screenRect.y); }

	static function PasswordFieldWithX(screenRect : Rect, nameString : String, fieldName : String) { return TextFieldWithX(screenRect, nameString, 255, true, "*"[0], fieldName); }
	static function PasswordFieldWithX(screenRect : Rect, nameString : String, flen : int, fieldName : String) { return TextFieldWithX(screenRect, nameString, flen, true, "*"[0], fieldName); }
	static function PasswordFieldWithX(screenRect : Rect, nameString : String, maskChar : char, fieldName : String) { return TextFieldWithX(screenRect, nameString, 255, true, maskChar, fieldName); }
	static function PasswordFieldWithX(screenRect : Rect, nameString : String, maskChar : char, flen : int, fieldName : String) { return TextFieldWithX(screenRect, nameString, flen, true, maskChar, fieldName); }


	static function Dots(centerPos : Vector2, dotAmount : int, currentPosition : int) { Dots(centerPos, new int[dotAmount], currentPosition, 1.0); }
	static function Dots(centerPos : Vector2, dotAmount : int, currentPosition : int, guiStyle : GUIStyle) { Dots(centerPos, new int[dotAmount], currentPosition, 1.0, guiStyle); }
	static function Dots(centerPos : Vector2, dotAmount : int, currentPosition : int, factor : float) { Dots(centerPos, new int[dotAmount], currentPosition, factor, GUI.skin.GetStyle("Dot")); }
	static function Dots(centerPos : Vector2, dotAmount : int, currentPosition : int, factor : float, guiStyle : GUIStyle) { Dots(centerPos, new int[dotAmount], currentPosition, factor, guiStyle); }
	static function Dots(centerPos : Vector2, dotStatusArray : int[], currentPosition : int) { Dots(centerPos, dotStatusArray, currentPosition, 1.0); }
	static function Dots(centerPos : Vector2, dotStatusArray : int[], currentPosition : int, guiStyle : GUIStyle) { Dots(centerPos, dotStatusArray, currentPosition, 1.0, guiStyle); }
	static function Dots(centerPos : Vector2, dotStatusArray : int[], currentPosition : int, factor : float) { Dots(centerPos, dotStatusArray, currentPosition, factor, GUI.skin.GetStyle("Dot")); }
	static function Dots(centerPos : Vector2, dotStatusArray : int[], currentPosition : int, factor : float, guiStyle : GUIStyle) {
		for(var i = 0; i < dotStatusArray.Length; i++) {
			var activeOrNot : boolean = false;
			if(i == currentPosition) activeOrNot = true; 
			else if(dotStatusArray[i] == -1) GUI.enabled = false;
			//GUI.DrawTexture(new Rect(Mathf.Round(centerPos.x - (dotStatusArray.Length * 16 * factor * 0.5) + (i * 16 * factor)), Mathf.Round(centerPos.y - (16 * factor * 0.5)), 16 * factor, 16 * factor), GUI.skin.GetStyle("Dot").onNormal.background);
			//GUI.Toggle(new Rect(Mathf.Round(centerPos.x - (dotStatusArray.Length * 13 * factor * 0.5) + (i * 13 * factor)), Mathf.Round(centerPos.y - (13 * factor * 0.5)), 13 * factor, 13 * factor), activeOrNot, GUIContent.none, GUI.skin.GetStyle("Dot"));	
			GUI.Toggle(new Rect((centerPos.x - (dotStatusArray.Length * 13 * factor * 0.5) + (i * 13 * factor)), (centerPos.y - (13 * factor * 0.5)), 13 * factor, 13 * factor), activeOrNot, GUIContent.none, guiStyle);	
			if(dotStatusArray[i] == -1) GUI.enabled = true;
		}
	}



}