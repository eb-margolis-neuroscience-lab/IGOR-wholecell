#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"Smart Squirt Controller", Squirtcontroller()
End


Window Squirtcontroller() : Panel
	VDTGetPortList2 /SCAN
	String /G datahookfortags
	variable currentsweepnum
	String /G mycommport = "COM5"
	String /G restxt1 = "none"
	String /G restxt2 = "none"
	String /G restxt3 = "none"
	String /G restxt4 = "none"
	String /G restxt5 = "none"
	String /G restxt6 = "none"
	String /G restxt7 = "none"
	String /G restxt8 = "aCSF"
	Variable /G duration = 60
	PauseUpdate; Silent 1			// building window...
	NewPanel /W=(150,50,350,390) /K=1 /N=SmartSquirtControls 
	//Set popvalue to the default com port for the BLE device so it doesn't usually need to be changed
	String /G commlist = S_VDT
	String /G defaultcomm = "COM5"
	Button select_data, pos={10, 10}, size={100,30}, proc=select_data_dialogSS, title="Select Data"
	PopupMenu popupchoosecomm,pos={12,55},size={180,20},title="Port Selection"
	PopupMenu popupchoosecomm,mode=1,popvalue=defaultcomm,value=commlist, proc=changecommport
	Button connectebut,pos={12,77},size={70,20},proc=SSconnectfunc,title="Connect"
	SetDrawLayer UserBack
	DrawLine /W=SmartSquirtControls 10, 104, 180, 104
	SetVariable durationtxt, pos={4, 115}, size={125,15}, value=duration, title="Duration (sec):", live=1
	Button durationupdate,pos={130,114},size={60,20},proc=durupdatefunc,title="Update"
	Button resevoir1,pos={12,148},size={70,20},proc=SSbutfunc,title="Eject 1"
	SetVariable resevoir1txt, pos={90, 148}, size={100,15}, value=restxt1, title="Drug:", live=1
	Button resevoir2,pos={12,168},size={70,20},proc=SSbutfunc,title="Eject 2"
	SetVariable resevoir2txt, pos={90, 168}, size={100,15}, value=restxt2, title="Drug:", live=1
	Button resevoir3,pos={12,188},size={70,20},proc=SSbutfunc,title="Eject 3"
	SetVariable resevoir3txt, pos={90, 188}, size={100,15}, value=restxt3, title="Drug:", live=1
	Button resevoir4,pos={12,208},size={70,20},proc=SSbutfunc,title="Eject 4"
	SetVariable resevoir4txt, pos={90, 208}, size={100,15}, value=restxt4, title="Drug:", live=1
	Button resevoir5,pos={12,228},size={70,20},proc=SSbutfunc,title="Eject 5"
	SetVariable resevoir5txt, pos={90, 228}, size={100,15}, value=restxt5, title="Drug:", live=1
	Button resevoir6,pos={12,248},size={70,20},proc=SSbutfunc,title="Eject 6"
	SetVariable resevoir6txt, pos={90, 248}, size={100,15}, value=restxt6, title="Drug:", live=1
	Button resevoir7,pos={12,268},size={70,20},proc=SSbutfunc,title="Eject 7"
	SetVariable resevoir7txt, pos={90, 268}, size={100,15}, value=restxt7, title="Drug:", live=1
	Button resevoir8,pos={12,288},size={70,20},proc=SSbutfunc,title="Eject 8"
	SetVariable resevoir8txt, pos={90, 288}, size={100,15}, value=restxt8, title="Drug:", live=1
	Button closebut,pos={12,312},size={70,20},proc=SSclosefunc,title="Close"
	NewNotebook /N=Squirt_list /F=1 /W=(320, 140, 570, 500)
	if (DataFolderExists("root:acquisition")) //for SutterPatch experiments
		datahookfortags = "root:acquisition:sweep_t"
		Button select_data d=2
	endif
EndMacro

Function select_data_dialogSS(ctrlName) : ButtonControl
	String ctrlName 
	Svar datahookfortags = root:datahookfortags
	CreateBrowser /M 
	ModifyBrowser /M showmodalbrowser expand=4
	datahookfortags=S_browserlist
End

Function changecommport(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	String mycommport
	//eventCode 2 is mouse up
	if (PU_Struct.eventCode == 2)
		mycommport = PU_Struct.popStr
		print mycommport
	Endif
End

Function SSconnectfunc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	String mycommport
	//eventCode 2 is mouse up
	if (B_Struct.eventcode == 2)
		VDTOpenPort2 mycommport
		Print "updated"
	Endif
End	

Function durupdatefunc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	//eventCode 2 is mouse up
	if (B_Struct.eventcode == 2)
		Variable updatedurationval
		updatedurationval = B_Struct.ctrlName
		String sendmystring = num2str(updatedurationval) + "\n"
		VDTWrite2 /O=1 sendmystring
	Endif
End

Function SSbutfunc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	//eventCode 2 is mouse up
	if (B_Struct.eventcode == 2)
		Variable selectedresnum = 0
		variable currentsweepnum = 0
		variable currenttime = 0
		Svar datahookfortags = root:datahookfortags
		Svar restxt1 = root:restxt1
		Svar restxt2 = root:restxt2
		Svar restxt3 = root:restxt3
		Svar restxt4 = root:restxt4
		Svar restxt5 = root:restxt5
		Svar restxt6 = root:restxt6
		Svar restxt7 = root:restxt7
		Svar restxt8 = root:restxt8
		selectedresnum = str2num(ReplaceString("resevoir", B_Struct.ctrlName, ""))
		String sendmystring = num2str(selectedresnum) + "\n"
		VDTWrite2 /O=1 sendmystring
		if (DataFolderExists("root:SutterPatch")) //for SutterPatch experiments
			datahookfortags = RemoveEnding(datahookfortags, ";")
			currentsweepnum = dimsize($datahookfortags, 1)
			currenttime = SutterPatch#Paradigm_GetTimer()/60
			if (selectedresnum == 1)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) + ": ("+ num2str(currenttime) +"):" + restxt1
			elseif (selectedresnum == 2)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) + ": ("+ num2str(currenttime) +"):" + restxt2
			elseif (selectedresnum == 3)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) + ": ("+ num2str(currenttime) +"):" + restxt3
			elseif (selectedresnum == 4)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) + ": ("+ num2str(currenttime) +"):" + restxt4
			elseif (selectedresnum == 5)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) + ": ("+ num2str(currenttime) +"):" + restxt5
			elseif (selectedresnum == 6)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) + ": ("+ num2str(currenttime) +"):" + restxt6
			elseif (selectedresnum == 7)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) + ": ("+ num2str(currenttime) +"):" + restxt7
			elseif (selectedresnum == 8)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) + ": ("+ num2str(currenttime) +"):" + restxt8
			endif
		else
			variable tag_time
			currentsweepnum = dimsize($datahookfortags, 0)
			duplicate /O $datahookfortags, tempfortagwave
			tag_time = tempfortagwave[currentsweepnum-1]
			if (selectedresnum == 1)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) +" ("+num2str(tag_time)+"): " + restxt1
			elseif (selectedresnum == 2)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) +" ("+num2str(tag_time)+"): " + restxt2
			elseif (selectedresnum == 3)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) +" ("+num2str(tag_time)+"): " + restxt3
			elseif (selectedresnum == 4)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) +" ("+num2str(tag_time)+"): " + restxt4
			elseif (selectedresnum == 5)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum)+" ("+num2str(tag_time)+"): " + restxt5
			elseif (selectedresnum == 6)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) +" ("+num2str(tag_time)+"): " + restxt6
			elseif (selectedresnum == 7)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) +" ("+num2str(tag_time)+"): " + restxt7
			elseif (selectedresnum == 8)
				Notebook Squirt_list text = "\rSweep "+num2str(currentsweepnum) +" ("+num2str(tag_time)+"): " + restxt8
			endif
			Tag /W=Holding /F=0 holding_i, currentsweepnum,restxt8
			Killwaves tempfortagwave
		endif
	Endif
End

Proc SSclosefunc(ctrlName) : ButtonControl
	String ctrlName
	Dowindow /K SmartSquirtControls
End

//get exact experiment time for NIDAQ experiments