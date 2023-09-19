#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"Tag Dialog", revisedtag_dialog()
End

//---------extract data from SutterPatch data structures EBM 12/26/2018-----------------

Macro revisedtag_dialog()
	variable currentsweepnum
	String /G datahookfortags
	String /G tagtext = "test"
	if (DataFolderExists("root:SutterPatch")) //for SutterPatch experiments
		newpanel /N=addtagwindow /W=(300, 100, 540, 180) /K=1
		Button select_data, pos={10, 10}, size={100,30}, proc=select_data_dialog, title="Select Data"
		Button btn_tagnow, pos={120, 10}, size={100,30}, proc=post_tag, title="Log Now"	
		SetVariable tagtextinput, pos={20, 50}, size={200,15}, value=tagtext, title="Tag Text:", live=1
		NewNotebook /N=Log_list /F=1 /W=(20, 140, 220, 500)
	else //for non-SutterPatch experiments
		newpanel /N=addtagwindow /W=(100, 650, 460, 700) /K=1
		Button btn_tagnow, pos={20, 10}, size={100,30}, proc=post_tag, title="Log Now"
		SetVariable tagtextinput, pos={140, 16}, size={200,15}, value=tagtext, title="Tag Text:", live=1
		NewNotebook /N=Log_list /F=1 /W=(360, 460, 560, 730)
		datahookfortags = "root:acquisition:sweep_t"
	endif
End 
	
End	

Function select_data_dialog(ctrlName) : ButtonControl
	String ctrlName 
	Svar datahookfortags
	CreateBrowser /M 
	ModifyBrowser /M showmodalbrowser expand=4
	datahookfortags=S_browserlist
End

Function post_tag(ctrlName) : ButtonControl
	String ctrlName
	Svar tagtext
	Svar datahookfortags
	variable currentsweepnum
	if (DataFolderExists("root:SutterPatch")) //for SutterPatch experiments
		datahookfortags = RemoveEnding(datahookfortags, ";")
		currentsweepnum = dimsize($datahookfortags, 1)
		Notebook Log_list text = "\rSweep "+num2str(currentsweepnum)+": "+tagtext
	else
		variable tag_time
		currentsweepnum = dimsize($datahookfortags, 0)
		duplicate /O $datahookfortags, tempfortagwave
		tag_time = tempfortagwave[currentsweepnum-1]
		Notebook Log_list text = "\rSweep "+num2str(currentsweepnum)+" ("+num2str(tag_time)+"): "+tagtext
		Tag /W=Holding holding_i, currentsweepnum,tagtext
		Killwaves tempfortagwave
	endif
End
	
//--------------------------------------------------------------------------------

