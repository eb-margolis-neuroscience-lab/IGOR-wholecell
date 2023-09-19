#pragma rtGlobals=1		// Use modern global access method.

Menu "Macros"
	"AP intracellular WF",version_setup_spike()
end

Function version_setup_spike()
	String folderID = "root:"
	if (DataFolderExists("root:wholecell"))	
		folderID = "root:wholecell:"
		classic_setup_spike(folderID)
	elseif(DataFolderExists("root:acquisition:data"))
		folderID = "root:acquisition:data"
		classic_setup_spike(folderID)
	elseif(DataFolderExists("root:SutterPatch"))
		SP_setup_spike()
	else
		DoAlert 0, "File structure not recognized"
	endif

End

Function classic_setup_spike(version)
	String version //this is the path to the sweeps passed from version function
	String/G mydatafolder = version
	string /g wave_name = "sweep1"
	setdatafolder mydatafolder
	variable /g myscale
	myscale = deltax($wave_name)
	string fullvarname = mydatafolder+":myscale"
	newdatafolder /o/s root:spikeanalysis
	if  (!exists("root:spikeanalysis:myscale"))
		movevariable $fullvarname, root:spikeanalysis:myscale
	endif
	setdatafolder root:spikeanalysis:
	Make /o /n=500 spike, spikeavg
	Make /o /n=500 guessAP
	guessAP = 0
	spike = 0
	spikeavg = 0
	variable /g step = 0
	variable /g threshold = -10
	variable /g numspikes = 0 
	Spikegraph(mydatafolder)
End

Function Spikegraph(inputfolder)
	String inputfolder
	String wave_name = "sweep"
	variable /g wave_number = 1
	Wave spike, spikeavg
	if (DataFolderExists("root:SutterPatch"))
		wave_number = 0
		Duplicate /o /RMD=[][wave_number] $inputfolder input_sweep, tempcolor 
		input_sweep = input_sweep*1000
	else
		wave_name = "sweep"
		Duplicate /o $(inputfolder+":"+wave_name+num2str(wave_number)) input_sweep, tempcolor
	endif
	tempcolor = 0
	Display /W=(264,50,850,429) /N=AP_anal_window spikeavg,spike 
	AppendToGraph /W=AP_anal_window /B=w_bottom input_sweep
	ModifyGraph lSize(spike)=0
	ModifyGraph rgb(spikeavg)=(0,0,65280)
	ModifyGraph zColor(input_sweep)={root:spikeanalysis:tempcolor,0,1,CyanMagenta}
	ModifyGraph lblPos(bottom)=38,lblPos(w_bottom)=36
	ModifyGraph lblLatPos(w_bottom)=-3
	ModifyGraph freePos(w_bottom)=0
	ModifyGraph axisEnab(bottom)={0,0.3}
	ModifyGraph axisEnab(w_bottom)={0.4,1}
	SetAxis left -80,60
	ControlBar 50
	ValDisplay valdisp0,pos={170,3},size={110,15},title="Spikes averaged:"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #"root:spikeanalysis:numspikes"
	Button button0,pos={80,27},size={30,20},disable=0,proc=ButtonProc_spikeYES,title="Yes"
	Button button1,pos={121,27},size={30,20},disable=0,proc=ButtonProc_spikeNO,title="No"
	Button button2,pos={231,27},size={50,20},proc=ButtonProc_spikeRESET,title="Reset"
	TitleBox title0,pos={13,30},size={55,13},title="Add Spike?",frame=0
	SetVariable setvar0,pos={25,5},size={120,30},proc=ChangeSweepAP,title="Sweep: "
	SetVariable setvar0,fSize=10,limits={1,Inf,1},value = wave_number
	Button button4,pos={320,10},size={60,30},proc=ButtonProc_spikeANALYZE,title="Analyze"
	Button button5,pos={396,10},size={70,30},proc=ButtonProc_spikeDUPLICATE,title="Duplicate"
	Button button6,pos={480,10},size={60,30},proc=ButtonProc_spikeCLOSE,title="Close"
	Findspike()
End

Function SP_setup_spike()
	setdatafolder root:SutterPatch:Data:
	String cmd1 = "String test = GetBrowserSelection(0)"
	CreateBrowser prompt="Select Analysis Wave", executeMode=1, command1=cmd1
	String /G tempwavepointer = removeending(S_browserlist)
	String fullvarname = "root:SutterPatch:Data:myscale"
	variable /g myscale
	myscale = DimDelta($tempwavepointer,0)
	newdatafolder /o/s root:spikeanalysis
	if  (!exists("root:spikeanalysis:myscale"))
		movevariable $fullvarname, root:spikeanalysis:myscale
	endif
	setdatafolder root:spikeanalysis:
	Make /o /n=500 spike, spikeavg
	Make /o /n=500 guessAP
	guessAP = 0
	spike = 0
	spikeavg = 0
	variable /g step = 0
	variable /g threshold = -10
	variable /g numspikes = 0 
	String /G wavepointer = tempwavepointer
	Spikegraph(wavepointer)
End

Function Findspike()
	Wave input_sweep = root:spikeanalysis:input_sweep
	Wave tempcolor = root:spikeanalysis:tempcolor
	Wave spike = spike
	Wave spikeavg = spikeavg
	Nvar myscale = myscale
	SetScale/P x 0,myscale,"", spikeavg
	SetScale/P x 0,myscale,"", spike
	NVar step = step
	NVar numspikes = numspikes
	NVar threshold = root:spikeanalysis:threshold
	variable sweeptime = numpnts(input_sweep)
	Do
		if (input_sweep[step] > threshold)
			wavestats /Q /P /R=[step-10,step+50] input_sweep
			step = V_maxRowLoc
			spike[] = input_sweep[p+step-100]
			tempcolor = 0
			tempcolor[step-100,step+200] = 1
			return step
		endif
		step =step + 1
	While (step<sweeptime)
	if (step > sweeptime - 10)
		step = 0
	endif
	ModifyGraph lstyle(spikeavg)=0
	ModifyGraph lsize(spike)=0
End

Function ButtonProc_spikeYES(ctrlName) : ButtonControl
	String ctrlName
	wave spike=spike
	wave spikeavg=spikeavg
	NVar step = step
	NVar numspikes = numspikes
	Nvar myscale = myscale
	spikeavg *= numspikes
	spikeavg += spike
	numspikes +=1
	spikeavg /= numspikes
	step = step + .004/myscale
	Findspike()
End

Function ButtonProc_spikeNO(ctrlName) : ButtonControl
	String ctrlName
	// NO button
	NVar step = step
	Nvar myscale = myscale
	step = step +.004/myscale	
	Findspike()
End

Function ButtonProc_spikeRESET(ctrlName) : ButtonControl
	String ctrlName
	// RESET button
	Wave spike=spike
	Wave spikeavg = spikeavg
	Wave guessAP = guessAP
	Wave tempcolor = tempcolor
	NVar numspikes = numspikes
	NVar step = step
	spike=0
	spikeavg =0
	numspikes=0
	step = 0
	guessAP = 0
	tempcolor = 0
End

Function ButtonProc_spikeCLOSE(ctrlName) : ButtonControl
	String ctrlName
	KillWindow /Z AP_anal_window 
	Killwaves /Z guessAP, input_sweep, spike, tempcolor
	Killvariables /Z myscale, numspikes, step, threshold, wave_number
	Killstrings /Z mydatafolder, wave_name
End

Proc ChangeSweepAP(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	changesweepfunc(varNum)
End

Function changesweepfunc(varNum)
	Variable varNum
	Nvar step = step
	Wave input_sweep
//	Svar mydatafolder = mydatafolder
//	Svar wave_name = wave_name
	String folderID
	String full_wave_name
	if (DataFolderExists("root:SutterPatch"))
		Svar wavepointer
		Duplicate /o /RMD=[][varNum] $wavepointer input_sweep
		input_sweep = input_sweep*1000
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
	step = 0
	Findspike()	
End

Proc ButtonProc_spikeDUPLICATE(ctrlName) : ButtonControl
	String ctrlName
	Copy_spikewave()
End

Proc Copy_spikewave(newname)
	string newName
	prompt newName, "Name of wave?"
	Duplicate /o spikeavg, $newname
End

Function ButtonProc_spikeANALYZE(ctrlName) : ButtonControl
	String ctrlName
	wave input_aps = root:spikeanalysis:spikeavg
	variable /g APstartpoint
	variable /g APstartpointV
	variable /g AP_peakV 
	variable /g AP_maxAHPV
	variable /g AP_maxAHPtime
	variable /g APduration
	variable tempa
	variable tempb
	variable slope
	variable intercept
	duplicate /o input_aps diff_aps
	differentiate diff_aps
	variable step = 0
	Nvar myscale = myscale
//AP threshold, when slope exceeds 5 V/s for 5KHz or less data or 10V/s in other conditions
// ie, 10KHZ data 5/19/11
	if (myscale <= 0.0002)
		do
			step +=1
		while(diff_aps[step]<5000)
	else
		do
			step +=1
		while(diff_aps[step]<10000)
	endif
	APstartpoint = step
	APstartpointV = input_aps[step]
//AP duration at onset
	do 
		step+=1
	while(input_aps[step]>APstartpointV)
	slope=(input_aps[step]-input_aps[step-1])
	tempa=input_aps[step]-slope*step
	tempb=(APstartpointV-tempa)/slope
	APduration=tempb-APstartpoint	
//AP peak
	wavestats /q   input_aps
	AP_peakV = V_max
//find AHP minimum
	AP_maxAHPV =V_min
	AP_maxAHPtime =(V_minloc/myscale-APstartpoint)
//find AHP slope
	Duplicate/O diff_aps,diff_aps_smth
	Smooth 10, diff_aps_smth
	wavestats /q /r=(V_minloc, .2) diff_aps_smth
//make AP plot and phase plot, add measurements
	Display /W=(264,300,850,629) /N=APresults input_aps
	AppendToGraph /W=APresults /B=w_bottom /L=r_axis diff_aps vs input_aps
	ModifyGraph axisEnab(bottom)={0,0.45}
	ModifyGraph axisEnab(w_bottom)={0.5,1}
	ModifyGraph freePos(r_axis)=-230
	DrawText 0.15, 0.1, "Thresh (mV): "+num2str(APstartpointV)
	DrawText 0.15, 0.16, "Peak (mV): "+num2str(AP_peakV)
	DrawText 0.15, 0.22, "Duration (ms): "+num2str(APduration*myscale*1000)
	DrawText 0.15, 0.28, "AHP min (mV) = " +num2str(AP_maxAHPV)
	DrawText 0.15, 0.34, "t to AHP min (ms) = " +num2str(AP_maxAHPtime * myscale*1000)
	DrawText 0.15, 0.40, "AHP max slope = " +num2str(V_max)
End