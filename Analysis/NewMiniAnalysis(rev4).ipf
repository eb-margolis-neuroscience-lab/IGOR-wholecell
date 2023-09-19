#pragma rtGlobals=1		// Use modern global access method.

//			NIDAQ Mini Analysis Software  version 3.02
//			for use with IgorPro version 5

// ---------------------------------------------edited EBM 1/29/2021--------------------------------------------------------------------
Function Initialize_minisearch()
	Wave current1wave 
	Wave smoothminiwave = smoothminiwave
// Mini detection settings		
	Variable /G samplingHz = 1/deltax(current1wave)
	Variable /G min_amplitude = 2			// detection threshold, pA  (positive number)
	Variable /G rise_slope_min = 0		// detection threshold for the differential (positive number)  ****needs to adjust for sampling Hz?
	
	Variable /G mini_direction = 1			// positive or negative direction (1 or -1)
	
// Other variables
	Variable /G miniposition = 0  			// for finding minis... keeps position in wave 
	Variable /G mini_number = 0			// how many minis have we detected
	Variable /G leftlimit = 0				// for graph	
	Variable /G rightlimit = 0.3				// for graph											 ****needs to adjust for sampling Hz?
	Variable /G toplimit =20				// for graph
	Variable /G bottomlimit = -40			// for graph
	Variable /G lastleftlimit = 0				// for moving graph back to previous position
	Variable /G lastrightlimit = 0.3			// for moving graph back to previous position
	Variable /G mini_start					// baseline position for current mini
	Variable /G last_mini_start				// baseline position for last mini
	Variable /G last_miniposition			// peak position for last mini
	Variable /G last_saved				// remembers if last mini was saved or not
	Variable /G pref_disp_interval = 0.3 //remember the interval the user prefers to have displayed in the window
	
	Duplicate /o current1wave smoothminiwavedifferential
	smooth 10, smoothminiwavedifferential													 //	****needs to adjust for sampling Hz?
	differentiate smoothminiwavedifferential
	Wavestats /Q /Z smoothminiwavedifferential
	rise_slope_min = 2* V_sdev
	Make /o/n=2 shthresh = mini_direction*rise_slope_min
	SetScale/I x 0,rightx(current1wave),"", shthresh
End

Macro Analyze_minis()   //sets up mini analysis, makes the window to look at the trace, and can step you back/forth
	killwaves /z current1wave, smoothminiwavedifferential
	createbrowser prompt="select wave to analyze and click OK:", showwaves=1,showVars=0, showStrs=0, command1="duplicate %s current1wave"
	
	if (V_Flag == 1)
		String /G Mini_amps_name, Mini_times_name
		Mini_amps_name = "mini_amps_"+NameofWave($S_browserlist )
		Mini_times_name = "mini_times_"+NameofWave($S_browserlist )
		if (exists(Mini_amps_name))
			if (PromptUser(Mini_amps_name)==1)
				Make /O/N=0 $(Mini_amps_name)
			else
				print "Procedure cancelled by user"
				return
			endif
		else
			Make /N=0 $(Mini_amps_name)
		endif
		if (exists(Mini_times_name))
			if (PromptUser(Mini_times_name)==1)
				Make /O/N=0 $(Mini_times_name)
			else
				print "Procedure cancelled by user"
				return
			endif
		else	
			Make /N=0 $(Mini_times_name)
		endif
		edit /W=(510,50,750,500) $(Mini_amps_name),$(Mini_times_name) as "Individual Mini Data"
		Initialize_minisearch()
		Mini_analysis_window()
		if (mini_direction == 1)
			popupmenu popup0, mode=1
		else
			popupmenu popup0, mode=2
		endif
//		Find_next_mini("")
	else
		print "Procedure cancelled by user"
	endif
End

Function PromptUser(OverwriteName)
String OverwriteName
Variable overwrite
Prompt overwrite, Overwritename+" exists.  Overwrite?", popup, "Yes;No" 
DoPrompt "Wave Exists", overwrite
Return(overwrite)
End



Window Mini_analysis_window() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(10,70,500,400) /L=i current1wave as "Mini analysis"
	appendtograph /R=diff smoothminiwavedifferential
	appendtograph /R=diff shthresh
	ModifyGraph rgb(smoothminiwavedifferential)=(16384,48896,65280)
	ModifyGraph freePos(diff)={100,bottom}
	ModifyGraph freePos(i)={0,bottom}
	ModifyGraph axisEnab(i)={0.4,1}
	ModifyGraph axisEnab(bottom)={0.05,0.95}
	ModifyGraph axisEnab(diff)={0,0.4}
	ModifyGraph lblPos(i)=45
	ModifyGraph lblPos(diff)=48
	Cursor A current1wave 0.0001;Cursor B current1wave 0.0008
	SetAxis bottom leftlimit,rightlimit
	SetAxis diff  (-2*rise_slope_min), (rise_slope_min)
	ModifyGraph lstyle(shthresh)=1,rgb(shthresh)=(0,0,0)
	ShowInfo
	ControlBar 120
	Button get_mini_amp,pos={400,35},size={120,30},proc=get_mini_amp,title="Accept"
	Button find_next_mini,pos={400,75},size={120,30},proc=find_next_mini,title="Reject"
	Button move_window_forward,pos={545,90},size={100,20},proc=window_forward,title="Move >>>"
	Button move_window_backward,pos={10,90},size={100,20},proc=window_backward,title="<<< Move"
	Button move_window_up,pos={130,35},size={80,30},proc=window_up, title="Move Up"
	Button move_window_down,pos={130,75},size={80,30},proc=window_Down, title="Move Down"
	Button go_to_last_mini,pos={250,35},size={100,20},proc=go_to_last_mini, title="Last Mini"
	Button take_extra_mini,pos={250,85},size={100,20},proc=take_extra_mini, title="Take Extra Mini"
	Button get_mini_data, pos={540,35}, size={100,30},proc=mini_data, title="Make Histogram"
	SetVariable set_thresh,pos={200,5},size={170,20},title="Threshold"
	SetVariable set_thresh,limits={-Inf,Inf,500},value= rise_slope_min,  proc=showthresh
	SetVariable mini_look,pos={400,5},size={170,20},title="Detected"
	SetVariable mini_look,limits={-Inf,Inf,1},value= mini_number
	PopupMenu popup0,pos={25,5},size={158,21},title="Mini Direction", proc=PopMenuProc
	PopupMenu popup0,mode=2,value= #"\"Positive;Negative\""
EndMacro

Function showthresh(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Wave shthresh = shthresh
	NVar mini_direction = mini_direction
	SetAxis diff  (-2*varnum), (varnum)
	shthresh = mini_direction*varnum
End

Function get_mini_amp(ctrlName): ButtonControl  //takes amplitude of cursor-selected mini, adds it to miniamps
	string ctrlName
	string thiswavename
	NVar mini_number=mini_number
	NVar last_saved = last_saved
	SVar mini_amps_name = mini_amps_name
	SVar mini_times_name = mini_times_name
	NVar leftlimit=leftlimit
	NVar pref_disp_interval=pref_disp_interval
	NVar rightlimit=rightlimit
	Wave mini_amps = $(mini_amps_name)
	Wave mini_times = $(mini_times_name)

	Variable minibase=xcsr(a)
	Variable minipeak=xcsr(b)
	
	GetAxis /Q bottom
	leftlimit = V_min
	rightlimit = V_max
	pref_disp_interval = V_max - V_min
	mini_number +=1
	insertpoints mini_number, 1, mini_amps, mini_times
	mini_amps[mini_number] = mean(current1wave, minipeak-0.0005, minipeak+0.0005) - mean(current1wave, minibase - 0.001, minibase)
 	mini_times[mini_number] = minibase 
	last_saved = 1
	Find_mini()
End


Macro Get_all_minis()
Variable wavelength = dimsize(current1wave,0)
Do
	Get_mini_amp("Get all")
While (miniposition < wavelength)
Average_mini()
End


Function go_to_last_mini(ctrlName): ButtonControl   //puts cursors back on the last mini, removes from data if accepted
	string ctrlName
	string thiswavename

	NVar mini_start = mini_start
	NVar miniposition = miniposition
	NVar last_timelock = last_timelock
	NVar mini_number=mini_number
	NVar last_mini_start = last_mini_start
	NVar last_miniposition = last_miniposition
	NVar leftlimit=leftlimit
	NVar pref_disp_interval=pref_disp_interval
	NVar rightlimit=rightlimit
	NVar lastleftlimit=lastleftlimit
	NVar lastrightlimit=leftrightlimit
	NVar last_saved = last_saved
	SVar mini_amps_name = mini_amps_name
	SVar mini_times_name = mini_times_name
	Wave mini_amps = $(mini_amps_name)
	Wave mini_times = $(mini_times_name)

	GetAxis /Q bottom
	leftlimit = V_min
	rightlimit = V_max
	pref_disp_interval = V_max - V_min
	mini_start = last_mini_start
	miniposition = last_miniposition

	leftlimit = lastleftlimit
	rightlimit = lastrightlimit
	rightlimit = leftlimit+pref_disp_interval
	WaveStats /Q/R=(leftlimit, rightlimit) current1wave 
	SetAxis i, V_min-10, V_max+10

	Cursor /P A current1wave mini_start;Cursor /P B current1wave miniposition
	SetAxis bottom leftlimit, rightlimit
	If (last_saved == 1)
		mini_number -= 1
		deletepoints mini_number, 1, mini_amps, mini_times
		last_saved = 0
	Endif
End	


Function take_extra_mini(ctrlName): ButtonControl  //takes amplitude of cursor-selected mini, adds it to miniamps
	string ctrlName
	string thiswavename
	NVar mini_start = mini_start
	NVar mini_number=mini_number
	NVar miniposition = miniposition
	NVar leftlimit = leftlimit
	NVar pref_disp_interval=pref_disp_interval
	NVar rightlimit = rightlimit
	NVar last_saved = last_saved
	SVar mini_amps_name = mini_amps_name
	SVar mini_times_name = mini_times_name
	Wave mini_amps = $(mini_amps_name)
	Wave mini_times = $(mini_times_name)

	Variable minibase=xcsr(a)
	Variable minipeak=xcsr(b)
	
	GetAxis /Q bottom
	leftlimit = V_min
	rightlimit = V_max
	pref_disp_interval = V_max - V_min
	mini_number +=1
	rightlimit = leftlimit+pref_disp_interval
	insertpoints mini_number, 1, mini_amps, mini_times
	mini_amps[mini_number] = mean(current1wave, minipeak-0.0005, minipeak+0.0005) - mean(current1wave, minibase - 0.001, minibase)
	mini_times[mini_number] = minibase  
	Cursor /P A current1wave mini_start;Cursor /P B current1wave miniposition
	SetAxis bottom leftlimit, rightlimit
	last_saved = 0
End


Function window_forward(ctrlName): ButtonControl
	string ctrlName
	NVar leftlimit=leftlimit
	NVar pref_disp_interval=pref_disp_interval
	NVar rightlimit=rightlimit
	
	WaveStats /Q/R=(leftlimit, rightlimit) current1wave 
	SetAxis i, V_min-10, V_max+10
	leftlimit += 0.1
	rightlimit = leftlimit + pref_disp_interval
	SetAxis bottom leftlimit, rightlimit
End


Function window_backward(ctrlName): ButtonControl
	string ctrlName
	NVar leftlimit=leftlimit
	NVar pref_disp_interval=pref_disp_interval
	NVar rightlimit=rightlimit

	WaveStats /Q/R=(leftlimit, rightlimit) current1wave 
	SetAxis i, V_min-10, V_max+10
	rightlimit -= 0.1
	leftlimit = rightlimit - pref_disp_interval
	SetAxis bottom leftlimit, rightlimit
End


Function window_up(ctrlName): ButtonControl
	string ctrlName
	NVar toplimit=toplimit
	NVar bottomlimit=bottomlimit
	
	toplimit += 10
	bottomlimit += 10
	SetAxis i bottomlimit, toplimit
End


Function window_down(ctrlName): ButtonControl
	string ctrlName
	NVar toplimit=toplimit
	NVar bottomlimit=bottomlimit
	
	toplimit -= 10
	bottomlimit -= 10
	SetAxis i bottomlimit, toplimit
End


Function find_next_mini(ctrlName) // From Reject button
	string ctrlName
	string thiswavename
	NVar last_saved = last_saved
	last_saved = 0	
	find_mini()
End


Function find_mini()   // goes through the differential wave, looking for candidate minis by finding bits with steep risetimes
	Wave smoothminiwavedifferential = smoothminiwavedifferential
	Wave current1wave = current1wave
	NVar mini_direction = mini_direction
	NVar miniposition = miniposition
	NVar mini_start = mini_start
	NVar rise_slope_min = rise_slope_min
	NVar rise_time_min = rise_time_min
	NVar min_amplitude = min_amplitude		
	NVar leftlimit=leftlimit
	NVar pref_disp_interval=pref_disp_interval
	NVar rightlimit=rightlimit
	NVar lastleftlimit=lastleftlimit
	NVar lastrightlimit=lastrightlimit
	NVar toplimit=toplimit
	NVar bottomlimit=bottomlimit
	NVar last_mini_start = last_mini_start
	NVar last_miniposition = last_miniposition
	NVar last_timelock = last_timelock
	Variable detection = 0
	Variable wavelength = dimsize(current1wave,0)
	Variable this_mini_amp = 0
	
	WaveStats /Q/R=(leftlimit, rightlimit) current1wave 
	SetAxis i, V_min-10, V_max+10
	last_mini_start = mini_start
	last_miniposition = miniposition
	
	do
		do					//to get when the mini risetime starts
			miniposition += 1
			if (mini_direction * smoothminiwavedifferential[miniposition] > rise_slope_min)  //looking for change in slope
				break
			endif	
		while (miniposition < wavelength)
		mini_start = miniposition   // might want to have mini_start = miniposition - 1  
		do
			miniposition +=1
			if (mini_direction * smoothminiwavedifferential[miniposition] < 0)  //peak of mini
				break
			endif	
		while (miniposition < wavelength)
		this_mini_amp = mean(current1wave, pnt2x(current1wave,miniposition-2), pnt2x(current1wave,miniposition+2)) - mean(current1wave, pnt2x(current1wave,mini_start-4), pnt2x(current1wave,mini_start))
		if (mini_direction * this_mini_amp > min_amplitude) 
			detection = 1
			break
		endif	
	while (miniposition < wavelength)

//puts cursors on the mini and moves the graph to center it
	
	lastleftlimit = leftlimit           //keeps track of where window was in case I need to go back
	lastrightlimit = rightlimit

	Cursor /P A current1wave mini_start;Cursor /P B current1wave miniposition
	
	Variable mini_start_time = mini_start * dimdelta(current1wave,0)
	if (mini_start_time > (rightlimit))   //moves window over to keep up with the current trace
		leftlimit = mini_start_time -0.05
		rightlimit = leftlimit + pref_disp_interval
		SetAxis bottom leftlimit, rightlimit
	endif
	//print current1wave[mini_start]
	if (current1wave[mini_start] > (toplimit -12.5))   //moves window up to keep up with the current trace
		toplimit += 25
		bottomlimit += 25
		SetAxis i bottomlimit, toplimit
	endif
	
	if (current1wave[mini_start] < (bottomlimit +20))   //moves window down to keep up with the current trace
		toplimit -= 25
		bottomlimit -= 25
		SetAxis i bottomlimit, toplimit
	endif
	
End

Function PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVar mini_direction = mini_direction
	if (popNum==1)
		mini_direction = 1
	else
		mini_direction = -1
	endif
End

Proc Mini_data(ctrlName): ButtonControl  //makes a histogram of the mini distribution, and gives a data summary
	String ctrlName
//	SVar mini_amps_name = mini_amps_name
//	NVar miniposition = miniposition
//	Wave current1wave = current1wave
	
	Wavestats /Q $mini_amps_name
	make /O/N=100 hist
	if (mini_direction==-1)
	Histogram/B={-100, 2, 50} $mini_amps_name,hist
	else
	Histogram/B={0, 2, 50} $mini_amps_name,hist
	endif
	PauseUpdate; Silent 1		// building window...
	Display /W=(10,40,500,400)/L=num hist as "Mini Amplitude Histogram"
	ModifyGraph axOffset(bottom)=0.1875
	ModifyGraph lblPos(num)=45
	ModifyGraph freePos(num)=0
	ModifyGraph axisEnab(num)={0,0.9}
	ModifyGraph axisEnab(bottom)={0.1,1}
	ModifyGraph freePos(num)={0,bottom}
	ModifyGraph mode=5
	ModifyGraph nticks(bottom)=10
	Label num "Number of Events"
	if (mini_direction == -1)
		Setaxis /A/R bottom 
	endif
	SetAxis /A/E=1 num 
	

	Variable time_in_secs = miniposition * dimdelta(current1wave,0)
	DrawText 0.44, 0.3, "Time analysed = " + num2str(time_in_secs) + " secs.  (File  = "+num2str(dimsize(current1wave,0)*dimdelta(current1wave,0))+" s)"
	DrawText 0.44,0.36, "Number of minis detected = " + num2str(V_npnts) + "."
	DrawText 0.44,0.42, "Mini Frequency = "+ num2str(V_npnts / time_in_secs) + " Hz."
	DrawText 0.44,0.48,  "Average Mini Amplitude = " + num2str(V_avg) + " pA."
	DrawText 0.44,0.54, "Standard Deviation of Mini Amplitude = " + num2str(V_sdev)

	Average_mini()

End	


Proc Average_mini()
	variable counter = 0
	variable number_of_minis = dimsize($mini_times_name,0)
//	prompt counter, "Average minis beginning with mini number: "
//	prompt number_of_minis, "How many minis to average: "
	Make /o/n=(.1*samplingHz) averaged_mini   = 0            //a 60msec average is 300 points @ 5khz
	SetScale/P x 0,dimdelta(current1wave,0), averaged_mini
	counter -= 1
	variable pre_mini_baseline = .02 		// in sec
	variable baselineoffset1=0
	
	do
		counter+=1
		averaged_mini[] += current1wave[p+(($mini_times_name[counter]-pre_mini_baseline)*samplingHz)]
	while (counter < number_of_minis)	
	averaged_mini /= number_of_minis
	
// Zeroing the mini to its baseline
	baselineoffset1 = mean(averaged_mini,0,.007)
	averaged_mini  -= baselineoffset1

// Display average mini
	display  /W=(510,40,700,220)averaged_mini as "Average Mini"
	
end	

Macro Average2_mini()
	doWindow /f mini_analysis_window
	variable counter = 0
	FindLevel  /q $mini_times_name xcsr(A)
	if (V_flag==0)
		counter = ceil(V_levelX)
	endif
	variable number_of_minis = dimsize($mini_times_name,0) -counter
	FindLevel  /q $mini_times_name xcsr(B)
	if (V_flag == 0)
		number_of_minis = ceil(V_LevelX)-counter
	endif
	Make /o/n=(.1*samplingHz) averaged_mini2   = 0           //a 60msec average is 300 points
	SetScale/P x 0,dimdelta(current1wave,0), averaged_mini2
	variable step = counter 
	variable pre_mini_baseline = .02 		// in sec
	variable baselineoffset1=0
	
	do
//		print step, $mini_times_name[step]
		averaged_mini2[] += current1wave[p+(($mini_times_name[step]-pre_mini_baseline)*samplingHz)]
		step += 1
	while (step < counter + number_of_minis)	
	averaged_mini2 /= number_of_minis
	print "number of minis averaged:  "+num2str(number_of_minis)
	
// Zeroing the mini to its baseline
	baselineoffset1 = mean(averaged_mini2,0,.007)
	averaged_mini2  -= baselineoffset1

// Display average mini
	display  /W=(510,40,700,220)averaged_mini2 as "Average Mini"
	
end	


