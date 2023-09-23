#pragma rtGlobals=1		// Use modern global access method.

Menu "Macros"
	"Intracellular AP measures",setup_spike()
end

Macro Setup_spike()
string foldername
	foldername="root:acquisition"
	if (datafolderexists(foldername))
		setdatafolder root:acquisition:data
	else
		setdatafolder root:wholecell
	endif
variable /g scale
scale = deltax(sweep1)
newdatafolder /o/s root:spikeanalysis
if  (!exists("scale"))
	if (datafolderexists(foldername))
		movevariable root:acquisition:data:scale, root:spikeanalysis:scale
	else
		movevariable root:wholecell:scale, root:spikeanalysis:scale
	endif
endif
Make /o /n=(.5/scale) spike, spikeavg
Make /o tempwave, tempcolor
tempwave = 0 
tempcolor = 0
spike = 0
spikeavg = 0
SetScale/P x 0,scale,"s", spike,spikeavg
variable /g step =0
variable /g threshold =-10
variable /g numspikes = 0 
Spikegraph()
End

Function Addspikes(sweep)
string sweep  
Nvar scale = scale
Wave spike = spike
Wave spikeavg = spikeavg
NVar step = step
NVar numspikes = numspikes
NVar threshold = threshold
variable /g sweeptime = numpnts($sweep)
Duplicate /o $sweep tempwave, tempcolor
tempcolor = 0
ModifyGraph lstyle(spikeavg)=1
ModifyGraph lsize(spike)=1
step = 0
Do
	if (tempwave[step] > threshold)
		spike[] = tempwave[p+step-100]
		tempcolor[step-100,step+400] = 1
		Button button0 disable=0
		Button button1 disable=0
		return step
	endif
	step +=1
While (step<sweeptime)
Button button0 disable=2
Button button1 disable=2
Button button3 disable=0
ModifyGraph lstyle(spikeavg)=0
ModifyGraph lsize(spike)=0
End

Function Findspike()
Wave tempwave = root:spikeanalysis:tempwave
Wave tempcolor = root:spikeanalysis:tempcolor
Wave spike = spike
Wave spikeavg = spikeavg
NVar step = step
NVar numspikes = numspikes
NVar threshold = threshold
Nvar scale = scale
variable sweeptime = numpnts(tempwave)
Do
	if (tempwave[step] > threshold)
		spike[] = tempwave[p+step-100]
		tempcolor = 0
		tempcolor[step-100,step+400] = 1
		return step
	endif
	step +=1
While (step<sweeptime)
Button button0 disable=2
Button button1 disable=2
Button button3 disable=0
ModifyGraph lstyle(spikeavg)=0
ModifyGraph lsize(spike)=0
End


Function ButtonProc_spike(ctrlName) : ButtonControl
	String ctrlName
// YES button
wave spike=spike
wave spikeavg=spikeavg
NVar step = step
NVar numspikes = numspikes
Nvar scale = scale
spikeavg *= numspikes
spikeavg += spike
numspikes +=1
spikeavg /= numspikes
step +=.004/scale
Findspike()
End

Function ButtonProc_1spike(ctrlName) : ButtonControl
	String ctrlName
// NO button
NVar step = step
Nvar scale = scale
step +=.004/scale	
Findspike()
End

Window Spikegraph() : Graph
	PauseUpdate; Silent 1		// building window...
	SetDataFolder root:spikeanalysis:
	Display /W=(264,50,650.25,329.75) spikeavg,spike
	AppendToGraph/B=w_bottom tempwave
	ModifyGraph lSize(spike)=0
	ModifyGraph rgb(spikeavg)=(0,0,65280)
	ModifyGraph zColor(tempwave)={root:spikeanalysis:tempcolor,0,1,Rainbow}
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
	Button button0,pos={80,27},size={30,20},disable=2,proc=ButtonProc_spike,title="Yes"
	Button button1,pos={121,27},size={30,20},disable=2,proc=ButtonProc_1spike,title="No"
	Button button2,pos={231,27},size={50,20},proc=ButtonProc_2spike,title="Reset"
	TitleBox title0,pos={13,30},size={55,13},title="Add Spike?",frame=0
	Button button3,pos={112,3},size={40,20},proc=ButtonProc_3spike
	TitleBox title1,pos={2,5},size={104,13},title="Add spikes from wave",frame=0
	Button button4,pos={320,10},size={60,30},proc=ButtonProc5_spike,title="Analyze"
	Button button5,pos={396,10},size={70,30},proc=ButtonProc4_spike,title="Duplicate"
EndMacro

Function ButtonProc_2spike(ctrlName) : ButtonControl
	String ctrlName
// RESET button
Wave spike=spike
Wave spikeavg = spikeavg
Wave tempwave = tempwave
Wave tempcolor = tempcolor
NVar numspikes = numspikes
NVar step = step
spike=0
spikeavg =0
numspikes=0
step = 0
tempwave = 0
tempcolor = 0
Button button0 disable=2
Button button1 disable=2
Button button3 disable=0
End

Proc ButtonProc_3spike(ctrlName) : ButtonControl
	String ctrlName
	createbrowser prompt="Select sweep"
	Button button3 disable=2
	print S_browserlist
	addspikes(removeending(S_browserlist))
End

Proc ButtonProc4_spike(ctrlName) : ButtonControl
	String ctrlName
	Copy_spikewave()
End

Proc Copy_spikewave(newname)
	string newName
	prompt newName, "Name of wave?"
	Duplicate /o spikeavg, $newname
End

Function ButtonProc5_spike(ctrlName) : ButtonControl
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
	Nvar scale = scale
//AP threshold, when slope exceeds 5 V/s for 5KHz or less data or 10V/s in other conditions
// ie, 10KHZ data 5/19/11
	if (scale <= 0.0002)
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
	AP_maxAHPtime =(V_minloc/scale-APstartpoint)

//find AHP slope - simple
//	Duplicate/O diff_aps,diff_aps_smth
//	Smooth 10, diff_aps_smth
//	print V_minloc
//	wavestats /q /r=(V_minloc, .2) diff_aps_smth
//find AHP slope - from smoothed
	Duplicate/O diff_aps,diff_aps_smth
	Smooth 10, diff_aps_smth
	wavestats /q /r=(V_minloc, .1) diff_aps_smth //have to change .2 for higher firing rates (~above 4Hz)
	maxslope=V_max
	wavestats/q  /r=(V_maxloc, .1) diff_aps_smth
	tempa=V_minloc
	print input_aps(V_minloc), V_minloc
	if ((V_min<-30) && (input_aps(AP_maxAHPtime) < input_aps(AP_maxAHPtime+.03)-3))	 //if there is a second dip, skip the first minimum and recalculate (not 0 because noise in differential sweep)
		wavestats /q /r=(tempa, .2) diff_aps_smth
		maxslope=V_max	//slope
		wavestats /q /r=(tempa, 0.2) input_aps
		AP_maxAHPV=V_min
		AP_maxAHPtime=(V_minloc/scale-APstartpoint)
	endif
	
Print "Action Potential measurements:"
Print ""
Print "Action potential threshold (mV) = " +num2str(APstartpointV)
Print "Action potential duration (msec) = "+num2str(APduration*scale*1000)
Print "Action potential height (mV) = " +num2str(AP_peakV)
Print "AHP value (mV) = " +num2str(AP_maxAHPV)
Print "AHP time to min (ms) = " +num2str(AP_maxAHPtime * scale*1000)
Print "AHP value at 50 ms = " +num2str(input_aps[APstartpoint+50/scale*1000])
Print "AHP max slope = " +num2str(V_max)
Print ""
End