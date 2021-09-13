#pragma strict

var mySkin : GUISkin;
var myStyle : GUIStyle;

var targetValue : int = 0;
var smoothValue : float = 0f;


var logo : Texture2D;
var frame : Texture2D;
var frameColor : Color = new Color(0.1, 0.1, 0.1, 1.0);

var bgImgs : Texture2D[];

var matrix : Matrix4x4 = Matrix4x4.identity;
var overlayMatrix : Matrix4x4 = Matrix4x4.identity;
var matrixAngle : float = 0.0;
private var prevMatrixAngle : float;
private var prevScreenWidth : int;

var currentScreen : int = 0;
var screenOffset : Vector2[];
var screenTitle : String[];

var checkbox : boolean = true;
var radiobutton : boolean = true;
var soundSlider : float = 0.5;
var musicSlider : float = 0.3;
var unnamedSlider : float = 0.75;
var namedSlider : float = 0.35;
var onOffSlider : float = 1.0;
var onOffSlider2 : float = 0.0;
var myString : String = "Username";
var myPassword : String = "Password";
var scrollPosition : Vector2 = Vector2.zero;
var windowRect : Rect = new Rect (-5,-113,240,220);
private var windowStartRect : Rect;
var showWindow : boolean = true;
var showPopupWindow : boolean = true;

var hSlider : float = 0.333;

var toolbarInt : int = 0;
private var toolbarStrings : String[] = ["Button 1", "Button 2", "Button 3"];

var timeOffset : float;



function Awake() {

	screenOffset = new Vector2[screenTitle.Length];
		
	RecalculateMatrix();
	windowStartRect = windowRect; 

	if(!frame) { //Create Fader Image from color if no image was given
		frame = new Texture2D(1, 1);
		var fcols : Color[] = frame.GetPixels();
		for(var g : int = 0; g < fcols.Length; ++g) {
			fcols[g] = frameColor;
		}
		frame.SetPixels(fcols);
		frame.Apply();			
	}
	
}

function Update () {
	
	smoothValue = Mathf.Lerp(smoothValue, targetValue, Time.deltaTime * 3f);
	
	if(matrixAngle != prevMatrixAngle || prevScreenWidth != Screen.width) {
		RecalculateMatrix();
	}
		
}

function RecalculateMatrix() {
	prevScreenWidth = Screen.width;
	prevMatrixAngle = matrixAngle;

	var quat : Quaternion = Quaternion.identity;
	
	overlayMatrix.SetTRS(new Vector3(Mathf.Round(Screen.width * 0.5), Mathf.Round(Screen.height * 0.5), 0.0), quat, Vector3.one);	
	
	quat.eulerAngles = Vector3(0.0, 0.0, matrixAngle);
	matrix.SetTRS(new Vector3(Mathf.Round(Screen.width * 0.5), Mathf.Round(Screen.height * 0.5), 0.0), quat, Vector3.one);	
	
	
}

function OnGUI () {
	
	GUI.skin = mySkin;
	GUI.matrix = matrix;
	var offset : Vector2 = Vector2.zero;	

	currentScreen = Mathf.Round(smoothValue);
	
	offset = new Vector2(screenOffset[currentScreen].x - (smoothValue - currentScreen) * 480 * 2, screenOffset[currentScreen].y);
	
	if(currentScreen == 0) {

		GUI.DrawTexture(new Rect(offset.x-logo.width * 0.5, offset.y-logo.height * 0.5, logo.width, logo.height), logo);

	} else if(currentScreen == 1) {
		
		GUI.Button(new Rect(offset.x-220, offset.y-98, 140, 28), "Tiny Button", mySkin.GetStyle("ButtonTiny"));
		GUI.Button(new Rect(offset.x-220 + 150, offset.y-98, 140, 40), "Button");
		GUI.Button(new Rect(offset.x-220 + 300, offset.y-98, 140, 52), "Big Button", mySkin.GetStyle("ButtonBig"));	
		
		checkbox = GUI.Toggle(new Rect(offset.x -220, offset.y -40, 140, 26), checkbox, "Checkbox");
		radiobutton = GUI.Toggle(new Rect(offset.x -220 + 150, offset.y -40, 170, 26), radiobutton, "Radio Button", mySkin.GetStyle("RadioButton"));
		
		GUI.Label(new Rect(offset.x-220, offset.y+2, 215, 42), "Label"); GUI.Label(new Rect(offset.x+5, offset.y+2, 215, 42), "SliderLabel", mySkin.GetStyle("SliderLabel"));
		
		myString = BlackishGUI.TextFieldWithX(new Rect(offset.x-220, offset.y+52, 215, 42), myString);
		myPassword = BlackishGUI.PasswordFieldWithX(new Rect(offset.x+5, offset.y+52, 215, 42), myPassword);
		
	
	} else if(currentScreen == 2) {
		onOffSlider = BlackishGUI.OnOffSwitchWithLabel(new Rect(offset.x-220, offset.y-98, 215, 42), onOffSlider, "Toggle", mySkin.GetStyle("onOffSlider"), mySkin.GetStyle("onOffSliderThumb"), mySkin.GetStyle("SliderLabel"));
		onOffSlider2 = BlackishGUI.OnOffSwitchWithLabel(new Rect(offset.x+5, offset.y-98, 215, 42), onOffSlider2, "Toggle", mySkin.GetStyle("onOffSlider"), mySkin.GetStyle("onOffSliderThumb"), mySkin.GetStyle("SliderLabel"));
		namedSlider = BlackishGUI.HorizontalSliderWithLabel(new Rect(offset.x-220, offset.y-48, 440, 42), 150, namedSlider, "Slider", mySkin.GetStyle("musicSlider"), mySkin.GetStyle("onOffSliderThumb"), mySkin.GetStyle("SliderLabel"));
		musicSlider = GUI.HorizontalSlider(new Rect(offset.x - 220, offset.y+2, 440, 42), musicSlider, 0.0, 1.0, mySkin.GetStyle("musicSlider"), mySkin.GetStyle("musicSliderThumb"));
		soundSlider = GUI.HorizontalSlider(new Rect(offset.x - 220, offset.y+52, 440, 42), soundSlider, 0.0, 1.0, mySkin.GetStyle("musicSlider"), mySkin.GetStyle("soundSliderThumb"));
		
	} else if(currentScreen == 3) {
		GUI.Box (Rect(offset.x-220, offset.y-98, 215, 190), "Box");
		if(smoothValue < 2.999 || smoothValue > 3.001) windowRect = new Rect(offset.x + windowStartRect.x, offset.y + windowStartRect.y, windowStartRect.width, windowStartRect.height);
		if(showWindow) windowRect = GUI.Window (0, windowRect, DoWindow, "WINDOW");
		else if(GUI.Button(Rect(offset.x+25, offset.y-20, 190, 42), "Show Window")) {
			windowRect = new Rect(offset.x + windowStartRect.x, offset.y + windowStartRect.y, windowStartRect.width, windowStartRect.height);
			showWindow = true;
		}

	} else if(currentScreen == 4) {


		if(showPopupWindow) GUI.Window(1, Rect(offset.x-190, offset.y-78, 400, 156), DoPopup, "This is a popup window!", mySkin.GetStyle("PopupWindow"));
		else if(GUI.Button(new Rect(offset.x -85, offset.y-20, 170, 42), "Open Popup")) showPopupWindow = true;
		
	} else if(currentScreen == 5) {
		
		soundSlider = GUI.HorizontalSlider(new Rect(offset.x - 220, offset.y - 98, 440 -100 - Mathf.Sin(Time.realtimeSinceStartup) * 100, 42), soundSlider, 0.0, 1.0, mySkin.GetStyle("musicSlider"), mySkin.GetStyle("soundSliderThumb"));
		onOffSlider = BlackishGUI.OnOffSwitchWithLabel(new Rect(offset.x - 220, offset.y - 48, 440 -100 - Mathf.Sin(Time.realtimeSinceStartup + 0.25) * 100, 42), onOffSlider, "Toggle", mySkin.GetStyle("onOffSlider"), mySkin.GetStyle("onOffSliderThumb"), mySkin.GetStyle("SliderLabel"));
		GUI.Button(new Rect(offset.x - 220, offset.y +2, 440 -100 - Mathf.Sin(Time.realtimeSinceStartup + 0.5) * 100, 42), "Button");
		myPassword = BlackishGUI.PasswordFieldWithX(new Rect(offset.x-220, offset.y+52, 440-100-Mathf.Sin(Time.realtimeSinceStartup + 0.75) * 100, 42), myPassword);
				
		
	} else if(currentScreen == 6) {

		if(smoothValue < 5.999 || smoothValue > 6.001) timeOffset = Time.time;
		
		var val : float = -0.5 + Mathf.Repeat((Time.time - timeOffset) *0.2, bgImgs.Length);
		GUI.color.a = Mathf.PingPong((Time.time - timeOffset)*0.4, 1.0);
		GUI.DrawTexture(new Rect(offset.x-256, offset.y-256, 512, 512), bgImgs[Mathf.Clamp(Mathf.Round(val), 0, bgImgs.Length)]);
		GUI.color.a = 1.0;

		toolbarInt = GUI.Toolbar (Rect (offset.x-220, offset.y-98, 440, 40), toolbarInt, toolbarStrings);
		namedSlider = BlackishGUI.HorizontalSliderWithLabel(new Rect(offset.x-220, offset.y-48, 440, 42), 150, namedSlider, "Slider", mySkin.GetStyle("musicSlider"), mySkin.GetStyle("onOffSliderThumb"), mySkin.GetStyle("SliderLabel"));
		
		checkbox = GUI.Toggle(new Rect(offset.x -220, offset.y +10, 140, 27), checkbox, "Checkbox");
		radiobutton = GUI.Toggle(new Rect(offset.x -220 + 145, offset.y +10, 170, 27), radiobutton, "Radio Button", mySkin.GetStyle("RadioButton"));
		hSlider = GUI.HorizontalSlider(new Rect(offset.x -220 + 317, offset.y+14, 120, 26), hSlider, 0.0, 1.0);
		
		myString = BlackishGUI.TextFieldWithX(new Rect(offset.x-220, offset.y+52, 215, 42), myString);
		myPassword = BlackishGUI.PasswordFieldWithX(new Rect(offset.x+5, offset.y+52, 215, 42), myPassword);
		
	} else if(currentScreen == 7) {
		
		if(GUI.Button(new Rect(offset.x - 220, offset.y + 52, 215, 42), "GameAssets.net")) Application.OpenURL("http://GameAssets.net");
		GUI.backgroundColor = Color.yellow;
		if(GUI.Button(new Rect(offset.x + 5, offset.y + 52, 215, 42), "Buy GUISkin001")) Application.OpenURL("https://sites.fastspring.com/blackishgames/instant/guiskin001");
		GUI.backgroundColor = Color.white;
		
				
	}

	GUI.color.a = 1.0;	
	GUI.matrix = overlayMatrix;
	
	GUI.Box(new Rect(-300, -160-260, 600, 305), GUIContent.none);
	GUI.Box(new Rect(-300, 110, 600, 320), GUIContent.none);
	
	var title : String = "";
	if(screenTitle.Length > currentScreen) title = screenTitle[currentScreen];
	else title = "";

	GUI.Label(new Rect(offset.x - 220, offset.y -160, 440, 42), title, myStyle);

	if(targetValue <= 0) GUI.enabled = false;
	if(GUI.Button(new Rect (-220, 123, 60, 28), "Prev", mySkin.GetStyle("ButtonTiny"))) {
		targetValue --; // currentScreen--;
		//PageChange();
	}
	GUI.enabled = true;
	if(targetValue >= screenTitle.Length - 1) GUI.enabled = false;
	if(GUI.Button(new Rect (160, 123, 60, 28), "Next", mySkin.GetStyle("ButtonTiny"))) {
		 targetValue ++; //currentScreen++;
		 //PageChange();
	}
	GUI.enabled = true;
	BlackishGUI.Dots(Vector2(0, 138), screenOffset.Length, targetValue);
	

	//FRAME
	
	if(Screen.width != 480) {
		GUI.DrawTexture(new Rect(-Screen.width * 0.5, -Screen.height * 0.5, Screen.width, Screen.height * 0.5 - 160), frame);
		GUI.DrawTexture(new Rect(-Screen.width * 0.5, 160, Screen.width, Screen.height * 0.5 - 160), frame);
		GUI.DrawTexture(new Rect(-Screen.width * 0.5, -160, Screen.width * 0.5-240, 320), frame);
		GUI.DrawTexture(new Rect(240, -160, Screen.width * 0.5-240, 320), frame);
	}

	
}


function DoWindow (windowID : int) {
	
	if(GUI.Button(new Rect(240-43, 24, 30, 30), "", GUI.skin.GetStyle("xButton"))) showWindow = false;

	scrollPosition = GUI.BeginScrollView (Rect(25, 55, 240-45, 220-80), scrollPosition, Rect(0,0,350,300));
	    GUI.Box (Rect(20, 100, 300, 100), "A Box within a ScrollView");
    GUI.EndScrollView ();
	
	GUI.DragWindow ();
	
}


function DoPopup () {

	if(GUI.Button(new Rect(200-60, 96, 120, 42), "Okay")) {
		showPopupWindow = false;	
	}

//	if(GUI.Button(new Rect(70, 98, 120, 40), "No")) {
//		
//	}
//
//	if(GUI.Button(new Rect(210, 98, 120, 40), "Yes")) {
//		
//	}
	
}
