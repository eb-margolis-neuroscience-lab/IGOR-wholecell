#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"ISIs from SP", ISI_SP_select()
end

//-----List of ISIs from SutterPatch data-----------------EBM--------------7/9/2023---------------
Function ISI_SP_select()
	if (DataFolderExists("root:SutterPatch"))
		SP_setup_ISI()
	else
		DoAlert 0, "For SutterPatch data only"
	endif
End

Function SP_setup_ISI()
	setdatafolder root:SutterPatch:Data:
	String cmd1 = "String test = GetBrowserSelection(0)"
	CreateBrowser prompt="Select Analysis Wave", executeMode=1, command1=cmd1
	String /G tempwavepointer = removeending(S_browserlist)
	String fullvarname = "root:SutterPatch:Data:myscale"
	variable /g myscale
	myscale = DimDelta($tempwavepointer,0)
	newdatafolder /o/s root:ISIanalysis
	if  (!exists("root:ISIanalysis:myscale"))
		movevariable $fullvarname, root:ISIanalysis:myscale
	endif
	setdatafolder root:ISIanalysis:
	Variable /g maxISIs
	Variable promptinput	//global variables can't be used in prompts
	maxISIs = 100	//target number of ISIs to find
	promptinput = maxISIs
	Prompt promptinput, "Enter desired number of ISIs: "
	DoPrompt "Find ISIs", promptinput
	maxISIs = promptinput
	Make /o /n=(maxISIs) ISIlist	//the wave of ISIs
	ISIlist = 0
	if (V_Flag)
		return -1					// User canceled
	endif
	variable /g threshold = -10
	variable /g numISIs = 0 		//number of ISIs found
	String /G wavepointer = tempwavepointer
	ISIfindergraph(wavepointer) 
End

Function ISIfindergraph(inputfolder)
	String inputfolder
	String wave_name = "sweep"
	variable /g wave_number = 1
	Variable /G maxsweepnum
	Variable /G timescale
	if (DataFolderExists("root:SutterPatch"))
		wave_number = 0
		Duplicate /o /RMD=[][wave_number] $inputfolder input_sweep, tempcolor 
		maxsweepnum = DimSize($inputfolder, 1)
		timescale = DimDelta($inputfolder, 0)
		print timescale
	else
		wave_name = "sweep"
		Duplicate /o $(inputfolder+":"+wave_name+num2str(wave_number)) input_sweep, tempcolor
	endif
	Display /W=(264,50,850,429) /N=ISI_anal_window 
	AppendToGraph /W=ISI_anal_window /B=w_bottom input_sweep
	ControlBar 50
	ShowInfo /W=ISI_anal_window
	ValDisplay valdisp0,pos={170,3},size={110,15},title="ISIs found:"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #"root:ISIanalysis:numISIs"
	TextBox /W=ISI_anal_window /A=RT "Mark x start time with Cursor A" 
	SetVariable setvar0,pos={25,5},size={120,30},proc=ChangeSweepISI,title="Sweep: "
	SetVariable setvar0,fSize=10,limits={1,Inf,1},value = wave_number
	Button button4,pos={320,10},size={60,30},proc=ButtonProc_ISIANALYZE,title="Analyze"
	Button button5,pos={396,10},size={70,30},proc=ButtonProc_ISISAVE,title="Copy"
	Button button6,pos={480,10},size={60,30},proc=ButtonProc_ISICLOSE,title="Close"
End

Function FindISIs()
	wave input_sweep
	wave ISIlist
	Nvar maxISIs
	Nvar wave_number
	Nvar maxsweepnum
	Nvar numISIs
	Variable threshold		
	Variable xstartpt		//where to start looking for APs in each wave
	Variable thisAPtime = 0
	Variable lastAPtime = 0
	xstartpt=x2pnt(input_sweep,xcsr(A))
	Wavestats /Q input_sweep
	Variable wavemean = V_avg
	Variable waveSD = V_sdev
	Variable endwavept = V_npnts - 1
	Variable maxval = V_max
	Variable minval = V_min
	String temp = waveinfo(input_sweep, 0)
	// Get the type of units for this dataset; 
	// if A, assume peaks are negative from wave mean, 
	//if V, assume peaks are positive from wave mean
	String yunits = StringByKey("DUNITS", temp)
	Variable pointnum = xstartpt
	if (StringMatch(yunits,"A"))
		threshold = wavemean - 4 * waveSD
		do
			pointnum = pointnum + 1
		while(input_sweep[pointnum] > threshold && pointnum <= endwavept)
		lastAPtime = pointnum
		pointnum = pointnum + 10
		do
			if (input_sweep[pointnum] < threshold)
				thisAPtime = pointnum
				ISIlist[numISIs] = thisAPtime - lastAPtime
				numISIs = numISIs + 1
				lastAPtime = thisAPtime
				pointnum = pointnum + 10
			endif
			pointnum = pointnum + 1
			if (numISIs >= maxISIs)
				analyzeISIs()
				break
			endif
		while (pointnum <= endwavept)
		if (numISIs < maxISIs && maxsweepnum > wave_number)
			wave_number = wave_number + 1
			ISIchangesweepfunc(wave_number)
			FindISIs()
		elseif (numISIs < maxISIs && maxsweepnum == wave_number)
			print "not enough data"
			printf "%g intervals found \r", numISIs
		endif
	elseif (StringMatch(yunits,"V"))
		threshold = wavemean + 4 * waveSD
		do
			pointnum = pointnum + 1
		while(input_sweep[pointnum] < threshold && pointnum <= endwavept)
		lastAPtime = pointnum
		pointnum = pointnum + 10
		do
			if (input_sweep[pointnum] > threshold)
				thisAPtime = pointnum
				ISIlist[numISIs] = thisAPtime - lastAPtime
				numISIs = numISIs + 1
				lastAPtime = thisAPtime
				pointnum = pointnum + 10
			endif
			pointnum = pointnum + 1
			if (numISIs >= maxISIs)
				analyzeISIs()
				break
			endif
		while (pointnum <= endwavept)
		if (numISIs < maxISIs && maxsweepnum > wave_number)
			wave_number = wave_number + 1
			ISIchangesweepfunc(wave_number)
			FindISIs()
		elseif (numISIs < maxISIs && maxsweepnum == wave_number)
			print "not enough data"
			printf "%g intervals found \r", numISIs
		endif
	endif
End

Function analyzeISIs()
	wave ISIlist
	Nvar timescale
	ISIlist = ISIlist*timescale
	wavestats /Q ISIlist
	Make /O/N=100 ISIhistout
	Histogram ISIlist, ISIhistout
	Display ISIhistout
	ModifyGraph mode=5,hbFill=2,useBarStrokeRGB=1
	DrawText 0.08, 0.1, "Mean (sec): "+num2str(V_avg)
	DrawText 0.08, 0.18, "St Dev: "+num2str(V_sdev)
	DrawText 0.08, 0.26, "CV: "+num2str(V_sdev/V_avg)
	DrawText 0.08, 0.34, "Skew: " +num2str(V_skew)
End


Function ButtonProc_ISIANALYZE(ctrlName) : ButtonControl
	String ctrlName
	FindISIs()
End

Proc ChangeSweepISI(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	ISIchangesweepfunc(varNum)
End

Function ISIchangesweepfunc(varNum)
	Variable varNum
	Nvar step = step
	Wave input_sweep
	String folderID
	String full_wave_name
	if (DataFolderExists("root:SutterPatch"))
		Svar wavepointer
		Duplicate /o /RMD=[][varNum] $wavepointer input_sweep
		input_sweep = input_sweep
	elseif (DataFolderExists("root:wholecell"))	
		folderID = "root:wholecell:"
		full_wave_name = folderID+":sweep"
		if (exists(full_wave_name+num2str(varNum)))
			duplicate /o $(full_wave_name+num2str(varNum)) input_sweep
		endif
	elseif (DataFolderExists("root:acquisition:data"))
		folderID = "root:acquisition:data"
		full_wave_name = folderID+":sweep"
		if (exists(full_wave_name+num2str(varNum)))
			duplicate /o $(full_wave_name+num2str(varNum)) input_sweep
		endif
	endif	
End

Function ButtonProc_ISIRESET(ctrlName) : ButtonControl
	String ctrlName
	// RESET button
	wave ISIlist
	ISIlist = 0
End

Function ButtonProc_ISICLOSE(ctrlName) : ButtonControl
	String ctrlName
	KillWindow /Z ISI_anal_window 
	Killwaves /Z input_sweep
	Killvariables /Z myscale, numISIs, threshold, wave_number
	Killstrings /Z mydatafolder, wave_name
End

Proc ButtonProc_ISISAVE(ctrlName) : ButtonControl
	String ctrlName
	Copy_ISIwave()
End

Proc Copy_ISIwave(newname)
	string newName
	wave ISIlist
	prompt newName, "Name of wave?"
	Duplicate /o ISIlist, $newname
End