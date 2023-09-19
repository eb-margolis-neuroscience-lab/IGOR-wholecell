#pragma rtGlobals=1		// Use modern global access method.
#include <Power Spectral Density>

Menu "Macros"
	"Whole Expt Firing Analysis", choosewaves()
	"Baseline Firing Analysis and PSD", choosewavesforPSD()
	"Concatenate Sweeps", sweepcount()
	"Create + Export ISI Wave",createisi()
end

//------------------------------------Firing Frequency Analysis Functions--------------EBM 1/3/01-------------------------------

function choosewaves() 
	Variable /G XYplot_on
	NewPanel /W=(350,100,600,280)
	DoWindow /C Choose_Waves
	checkbox checkXYplot, mode=0, proc=checkXYplot, title="Use XY plot", value = 1 ,variable=XYplot_on, pos={20,20}
	Popupmenu popupwaven, proc=assignwavepopup, title="Wave of y values", value=WaveList("*expt*",";","")
//	use the line above with the "concatenate" function.  Otherwise:
//	Popupmenu popupwaven, proc=assignwavepopup, title="Wave of y values", value=WaveList("*",";","")
	popupmenu popupwaven, pos={27,45}, bodywidth=120
	Popupmenu popupxwave, proc=assignwavepopup, title="Wave of x values", value=WaveList("*expt*",";","")
//	use the line above with the "concatenate" function.  Otherwise:
//	Popupmenu popupxwave, proc=assignwavepopup, title="Wave of x values", value=WaveList("*",";","")
	popupmenu popupxwave, pos={0,85}, bodywidth=120
	Button okaybutton, pos={25, 130}, proc=button_okay, title="Okay", size={80, 30}
	Button  closebutton, pos={145, 130}, proc=buttonkill_choosewaves, title="Cancel", size={80,30}
end

function makeanalysisplot() 
	Svar waven
	Svar xwave
	NVar XYplot_on
	variable /G APhigh=0
	variable /G APhigh_on=1
	variable /G APlow=0
	variable /G APlow_on=0
	variable /G wavelength=0
	variable deltatemp=0
	PauseUpdate; Silent 1		// building window...
	Duplicate $waven, workingwave
	if (XYplot_on)
		Duplicate $xwave, timewave
		Display /L=left $waven vs timewave
	else
		Display /L=left $waven 
	endif
	wavelength=numpnts($waven)
	deltatemp=deltax($waven)
	Make/N=(wavelength) tempwave
	setscale /P x 0,deltatemp, tempwave
	tempwave=2
	if (XYplot_on)
		AppendtoGraph/L=freq tempwave vs timewave//$xwave
	else
		AppendtoGraph/L=freq tempwave
	endif 
	Modifygraph height=200
	ModifyGraph freePos(freq)={0,bottom}
	Modifygraph axisEnab(freq)={0,.45}
	Modifygraph axisEnab(left)={.55,1}
	ModifyGraph lblPos(left)=45,lblPos(freq)=45
	Label left, "Potential (mV)"
	Label freq, "Frequency (Hz)"
	Label bottom, "Time (min)"
	DoWindow /C Firing_Analysis
	Showinfo
	ControlBar 80
	Checkbox APhigh_check, title="Use cursor A for depolarization threshold", value=1, pos={30,5}, variable=APhigh_on
	Checkbox APlow_check, title="Use cursor B for recovery hyperpolarization", value=0, pos={30,20}, variable=APlow_on
	Button resetbutton, pos={50,50}, proc=resetplotbutton, title="Reset"
	Button analyzebutton, pos={150,50}, proc=analyzebutton, title="Analyze"
	Button savebutton, pos={250,50}, size={100,20}, proc=saveanalysisbutton, title="Save Analysis"
	Button  closebutton, pos={400, 50}, proc=buttonkill_analysisplot, title="Close"
end

Function doanalysis()
	Nvar APhigh
	Nvar APhigh_on
	Nvar APlow
	Nvar APlow_on
	Nvar wavelength 
	Nvar XYplot_on
	Variable i,k
	Variable newstartmark=0
	Variable laststartmark=0
	Variable instantfreq=0
	Variable deltatemp=0
	Variable hypvalpassed=0
	Wave workingwave
	Wave tempwave
	Wave timewave
	deltatemp=deltax(workingwave)
	if (deltatemp>.0008)			//use delta to see if file is in sec or min (delta=.00083).  No other scales will be handled accurately here
		deltatemp=deltatemp*60
	endif
	if (APhigh_on)
		APhigh=vcsr(A)
	endif
	if (APlow_on)
		APlow=vcsr(B)
	endif
	if (APhigh_on && APlow_on==0)	//analysis with only the high threshold set
		 i=1
		 do
		 	if (workingwave[i-1]<APhigh && workingwave[i]>APhigh)
		 		newstartmark=i
		 		if (XYplot_on)
		 			instantfreq=1/(60*(timewave[newstartmark]-timewave[laststartmark]))
		 		else
		 			instantfreq=1/((newstartmark-laststartmark)*deltatemp)
		 		endif
		 		if (instantfreq<0)
		 			print timewave[newstartmark], timewave[laststartmark]
		 		endif
		 		k=laststartmark
		 		do
		 			tempwave[k]=instantfreq
		 			k+=1
		 		while (k<=i)
		 		laststartmark=newstartmark
		 	endif	
		 	i += 1
		 while (i<=wavelength-1)
	elseif (APhigh_on==0 && APlow)	//analysis with only the low threshold set
		i=1
		do
			if(workingwave[i-1]>=APlow && workingwave[i]<APlow)
				newstartmark=i
				if (XYplot_on)
		 			instantfreq=1/(60*(timewave[newstartmark]-timewave[laststartmark]))
		 		else
		 			instantfreq=1/((newstartmark-laststartmark)*deltatemp)
		 		endif
				k=laststartmark
				do
					tempwave[k]=instantfreq
					k+=1
				while (k<=i)
				laststartmark=newstartmark
			endif
			i+=1
		while (i<=wavelength-1)
	elseif (APhigh_on && APlow_on)	//analysis with both high and low thresholds set
		i=1
		do
			if (workingwave[i-1]<APhigh && workingwave[i]>APhigh && hypvalpassed==0)
				newstartmark=i
			endif
			if (workingwave[i-1]<APlow && workingwave[i]>APlow)
				hypvalpassed=1
			endif
			if (workingwave[i-1]<APhigh && workingwave[i]>APhigh && hypvalpassed)
				if (XYplot_on)
		 			instantfreq=1/(60*(timewave[newstartmark]-timewave[laststartmark]))
		 		else
		 			instantfreq=1/((newstartmark-laststartmark)*deltatemp)
		 		endif
				k=laststartmark
				do
					tempwave[k]=instantfreq
					k+=1
				while (k<=i)
				laststartmark=newstartmark
				hypvalpassed=0
			endif
			i+=1
		while (i<=wavelength-1)
	endif	 
end

// ------buttons, etc-------

Function resetplotbutton(ctrlName) : ButtonControl
	string ctrlName
	Cursor /K /W=Firing_Analysis A
	Cursor /K /W=Firing_Analysis B
end

Function analyzebutton(ctrlName) : ButtonControl
	string ctrlName
	doanalysis()
end

Function saveanalysisbutton(ctrlname) : ButtonControl
	string ctrlName
	string wavesave
	Nvar wavelength
	wave tempwave
	Nvar APhigh_on
	Nvar APlow_on
	variable depthresh
	variable hypthresh
	if (APhigh_on)			//  Notes include a record of the potentials used in the calculations
		Note tempwave, "Depol. threshold:"
		Note tempwave, num2str(vcsr(A))
	endif
	if (APlow_on)
		Note tempwave, "Hyp. threshhold:"
		Note tempwave,  num2str(vcsr(B))
	endif
	prompt wavesave, "Name analysis wave"
	DoPrompt "Name analysis wave", wavesave
	Rename tempwave,$wavesave; 
	saveexperiment 
end

Function Buttonkill_analysisplot(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k  Firing_Analysis
	if (waveexists(tempwave))
		Killwaves tempwave
	endif
	killwaves workingwave
	if (waveexists(timewave))
		killwaves timewave
	endif
	Killstrings /Z waven, xwave
End

function checkXYplot(name, value)
	string name
	Variable value
	Nvar XYplot_on
	if (value)
		Popupmenu popupxwave, proc=assignwavepopup, title="Wave of x values", value=WaveList("*",";","")
		popupmenu popupxwave, pos={0,85}, win=Choose_Waves, disable=0
		XYplot_on=1
	else
		Popupmenu popupxwave, noproc, title="Wave of x values", value=WaveList("*",";","")
		popupmenu popupxwave, pos={0,85}, disable=2, win=Choose_Waves
		XYplot_on=0
	endif
end

function assignwavepopup(ctrlname, popnum, popstr) : popupmenucontrol
	string ctrlname
	variable popnum
	string popstr
	String/G waven
	String/G xwave
	if (stringmatch(ctrlname,"popupwaven"))
		waven=popstr
	elseif (stringmatch(ctrlname,"popupxwave"))
		xwave=popstr
	endif
end

Function Button_okay(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k  Choose_Waves
	makeanalysisplot()
End

Function Buttonkill_choosewaves(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k  Choose_Waves
	Killstrings /Z waven, xwave
End

//-------------------------------------Concatenate Sweeps Functions-----------------------EBM 1/3/01--------------------------
//these functions will take all of the "sweeps" in the experiment and make 2 waves from them--
	//"expttime"-experimental time measured from the beginning of the experiment in minutes
	//"wholeexpt"-corresponding potential or current values for the time values in "expttime"
//In addition, the function displays wholeexpt vs expttime when finished, and saves the experiment 
//(and therefore the new waves and graph).
//It will work assuming the notes are time from start of experiment in minutes 
//and the sweeps are called "sweep#"
//It will also overwrite waves called expttime, wholeexpt, or currentsweep without warning the user.

function sweepcount()  		//count up number of sweeps.  Assumes first sweep is numbered "1", and 
							//no sweep numbers are missing.
	setdatafolder root:acquisition:data
	Variable numsweeps=0
	String swpname
	Variable sweepexists=1
	do
		swpname="sweep"+num2str(numsweeps+1)
		if (! waveexists($swpname))
			sweepexists=0
		endif
		numsweeps+=1
	while (sweepexists > 0)
	numsweeps -=1
	//print numsweeps
	concatsweeps(numsweeps)
end

function concatsweeps(numsweeps)
	variable numsweeps
	variable deltatime
	variable starttime
	variable wavelength
	String swpname
	variable totalpts
	variable i=1		//index for sweep number
	variable k=0		//index for position in one sweep
	variable j=0		//index for position in concatenated wave
	wavelength=numpnts(sweep1)
	totalpts=numsweeps*wavelength
	Make /O /N=(totalpts) expttime
	Make /O /N=(totalpts) wholeexpt
	copyscales /P sweep1, wholeexpt
	do
		swpname="sweep"+num2str(i)
		Duplicate /O $swpname, currentsweep
		deltatime=deltax(currentsweep)
		starttime=str2num(note(currentsweep))
		k=0
		do 
			expttime[j]=starttime+k*deltatime/60	//convert times to minutes from expt start
			wholeexpt[j]=currentsweep[k]
			k =k+1
			j =j+1
		while (k<=wavelength-1)
		i+=1
	while (i<=numsweeps)
	Killwaves currentsweep
	//SetScale/P x 0,0.0002,"", wholeexpt
	
	Display wholeexpt vs expttime
	Label left, "Holding Potential (mV)"
	Label bottom, "Time (min)"
	saveexperiment
end

//---------------------------------Analysis of Baseline Firing for Spectral Power----------------11/26/01---EBM-------------------
//modified 1/30/04 EBM
//This function will allow the user to choose the voltage (and time) wave to analyze, the starting point for the 
//window, and the number of AP intervals to measure.  It will put this information into a wave, display this wave,
//FFT(PSD) the wave, and normalize it, according to methods of M. DiMascio and E. Esposito Nueroscience
// 79(4), 957-961, 1997.

function choosewavesforPSD() 
	Variable /G XYPSDplot_on=1
	variable /g countspikes_on
	variable /g anal_length=700
	NewPanel /W=(350,100,600,380)
	DoWindow /C Choose_Waves_PSD
	checkbox checkXYplot, mode=0, proc=checkXYPSDplot, title="Use XY plot", value = 1
	checkbox checkXYplot, variable=XYPSDplot_on, pos={20,20}
	Popupmenu popupwavenPSD, proc=assignwavePSDpopup, title="Wave of y values", value=WaveList("*",";","")
	popupmenu popupwavenPSD, pos={27,45}, bodywidth=120
	Popupmenu popupxwavePSD, proc=assignwavePSDpopup, title="Wave of x values", value=WaveList("*",";","")
	popupmenu popupxwavePSD, pos={0,85}, bodywidth=120
	checkbox radiobut_countspikes, mode=1, proc=radiobut_PSDchange, title="Analyze a set number of spikes"
	checkbox radiobut_countspikes, variable=countspikes_on, pos={20,135}, value=1
	checkbox radiobut_counttime, mode=1, proc=radiobut_PSDchange, title="Analyze a specific length of time"
	checkbox radiobut_counttime, pos={20,155}, value=0
	SetVariable setvar_anal_length,pos={20,180},size={200,20},title="Number of Spikes to analyze"
	SetVariable setvar_anal_length,limits={200,2000,100},value= anal_length
	Button okaybutton, pos={25, 230}, proc=PSDbutton_okay, title="Okay", size={80, 30}
	Button  closebutton, pos={145, 230}, proc=PSDbuttonkill_choosewaves, title="Cancel", size={80,30}
end

function PSDanalysiswindow()
	Svar wavenPSD
	Svar xwavePSD
	NVar XYPSDplot_on
	Nvar anal_length
	variable /G APPSDhigh=0
	variable /G wavelength=0
	variable deltatemp=0
	PauseUpdate; Silent 1		// building window...
	Duplicate $wavenPSD, workingwave
	if (XYPSDplot_on)
		Duplicate $xwavePSD, timewave
		Display /w=(150,150,700,900) /L=potential /B=stdtime $wavenPSD vs timewave
		setaxis potential -70,0
	else
		Display /w=(150,150,700,900)  /L=potential /B=stdtime $wavenPSD 
		setaxis potential -70,0
	endif
	wavelength=numpnts($wavenPSD)
	deltatemp=deltax($wavenPSD)
	Make/N=(anal_length) tempwave
	tempwave=2000
	if (XYPSDplot_on)
		AppendtoGraph/L=freq /B=newbottom tempwave 
		setaxis freq 0, 5000
	else
		AppendtoGraph/L=freq /B=newbottom tempwave
		setaxis freq 0, 5000
	endif 
	Make/N=2000 histtempwave
	histtempwave=5
	Modifygraph height=400
	ModifyGraph freePos(potential)={0,stdtime}
	Modifygraph axisEnab(potential)={.55,1}
	Modifygraph axisEnab(freq)={0.1,.4}
	Modifygraph axisEnab(newbottom)={0.05,.3}
	Modifygraph freePos(stdtime)={-100, potential}
	Modifygraph axisEnab(stdtime)={.05,1}
	Modifygraph freePos(newbottom)={0,freq}
	Modifygraph freePos(freq)={0,newbottom}
	ModifyGraph lblPos(potential)=45,lblPos(freq)=45,lblPos(stdtime)=32,lblPos(newbottom)=32
	AppendtoGraph/L=histleft /B=histbottom histtempwave
	// fix styles for graphs
	Modifygraph axisEnab(histbottom)={.37,.6}
	Modifygraph axisEnab(histleft)={.1,.4}
	Modifygraph freePos(histbottom)={0,histleft}
	Modifygraph freePos(histleft)={0,histbottom}
	Modifygraph lblPos(histbottom)=35, lblPos(histleft)=35
	setaxis histbottom 0, 4000
	Label histbottom, "ISI bin"
	Label histleft, "Histogram"
	Label potential, "Potential (mV)"
	Label freq, "delta T (ms)"
	Label stdtime, "Time (min)"
	Label newbottom, "nth Time Interval"
	DoWindow /C Baseline_Firing_Analysis
	Showinfo
	ControlBar 40
	setdrawenv /w=Baseline_Firing_Analysis fsize=10 
	drawtext /w=Baseline_Firing_Analysis 0.1,.05, "Choose starting peak with cursor A"
	Button resetbutton, pos={50,15}, proc=resetPSDplotbutton, title="Reset"
	Button analyzebutton, pos={150,15}, proc=analyzePSDbutton, title="Analyze"
	Button savebutton, pos={250,15}, size={100,20}, proc=savePSDanalysisbutton, title="Save Analysis"
	Button  closebutton, pos={400, 15}, proc=buttonkill_PSDanalysisplot, title="Close"
end

Function doPSDanalysis()
	Nvar APPSDhigh
	Nvar wavelength 
	Nvar XYPSDplot_on
	nvar countspikes_on
	nvar anal_length
	Variable i,k
	Variable newstartmark=0
	Variable laststartmark=0
	Variable instantinterval=0
	Variable deltatemp=0
	Variable hypvalpassed=0
	variable maxtimeanal=0
	variable /g avginterval
	variable /g histogram_peak
	variable /g interval_SD
	variable isi_summed=0
	variable psi_factor
	variable xstartpt
	variable isi_skew
	string isi_string
	string sd_string
	string hist_peak_string
	string psi_text
	string PSD_text
	string isi_skew_text
	Wave workingwave
	Wave tempwave
	Wave timewave
	wave histtempwave
	deltatemp=deltax(workingwave)
	if (deltatemp>.0008)			//use delta to see if file is in sec or min (delta=.00083).  No other scales will be handled accurately here
		deltatemp=deltatemp*60
	endif
	APPSDhigh=vcsr(A)
	xstartpt=x2pnt(workingwave,xcsr(A))
// get the wave of interspike intervals here
	if (countspikes_on) 
		i=xstartpt
		//print i, xstartpt, APPSDhigh, XYPSDplot_on
		laststartmark=i
		k=0   //k is the index of the wave that lists the inter-spike intervals
		do
			if (workingwave[i-1]<APPSDhigh && workingwave[i]>APPSDhigh)
		 		newstartmark=i
		 		if (XYPSDplot_on)
		 			instantinterval=60*(timewave[newstartmark]-timewave[laststartmark])
		 		else
		 			instantinterval=(newstartmark-laststartmark)*deltatemp
		 		endif
		 		tempwave[k]=instantinterval*1000
		 		isi_summed=isi_summed+tempwave[k]
		 		k+=1
		 		laststartmark=newstartmark
		 	endif	
		 	i += 1
		while (k<=anal_length)
	else  //need to fix this part of the routine**************************************************
		if (XYPSDplot_on)      //check this with print, should be an index for the while loop, not a time
			maxtimeanal=xcsr(A)+anal_length
		elseif (countspikes_on==0)
			maxtimeanal=xcsr(A)+anal_length
		endif
		i=1
		k=0
		do
			if (workingwave[i-1]<APPSDhigh && workingwave[i]>APPSDhigh)
		 		newstartmark=i
		 		if (XYPSDplot_on)
		 			instantinterval=1/(60*(timewave[newstartmark]-timewave[laststartmark]))
		 		else
		 			instantinterval=1/((newstartmark-laststartmark)*deltatemp)
		 		endif
		 		tempwave[k]=instantinterval*1000  
		 		k+=1
		 		laststartmark=newstartmark
		 		isi_summed=isi_summed+tempwave[k]
		 	endif	
		 	i += 1
		while (timewave[i]/60<=(anal_length+xcsr(A)))
	endif	 
//histogram the interspike intervals
	Histogram/B={0,50,2000} tempwave,histtempwave
//mean, SD, and peak for ISI
	wavestats /Q tempwave
	avginterval=V_avg
	isi_skew=v_skew
	interval_SD=V_sdev  //this is not really right, though.  It is going to be skewed by the data.  I think I just want the approximate
	//SD around the peak in the histogram, not of all of the data.
	wavestats /Q histtempwave
	histogram_peak=V_maxloc
//display the mean, sd, and peak
	isi_string="Firing Rate: Hz"
	isi_string[12]=num2str(1000/avginterval)
	setdrawlayer /k/w=baseline_firing_analysis UserFront 
	setdrawlayer /w=baseline_firing_analysis UserFront
	setdrawenv /w=baseline_firing_analysis fsize=10
	drawtext /w=Baseline_Firing_Analysis 0.43,0.59, isi_string
	sd_string="ISI SDev: ms"
	sd_String[9]=num2str(interval_SD)
	setdrawenv /w=baseline_firing_analysis fsize=10
	drawtext /W=Baseline_Firing_Analysis 0.43, 0.62, sd_string
	hist_peak_string="ISI Hist. Peak: ms"
	hist_peak_string[15]=num2str(histogram_peak)
	setdrawenv /w=baseline_firing_analysis fsize=10
	drawtext /W=Baseline_Firing_Analysis 0.43, 0.65, hist_peak_string
	isi_skew_text="ISI Skew: "
	isi_skew_text[11]=num2str(isi_skew)
	setdrawenv /w=baseline_firing_analysis fsize=10
	drawtext /w=baseline_firing_analysis 0.43, 0.68, isi_skew_text 
//calculate the FFT of the ISI wave
	duplicate /O/D tempwave FFT_Wave
	FFT FFT_Wave
//call a macro that just does the psd so that the quotes for the string do not get in the way
	execute "my_psd_macro()"
//	Execute "PSD(wavepointer,1,2)"
	//sum and scale the transformed wave to get the psi factor according to Di Mascio and Esposito, 1997
	k=0
	i=0
	if (countspikes_on) 
		do
			psi_factor=psi_factor+abs(FFT_Wave[k])/isi_summed
			k+=1
		while (k<=anal_length)
		
	else
		do
			psi_factor=psi_factor+abs(FFT_Wave[k])/isi_summed
			k+=1
		while (timewave[i]/60<=(anal_length+xcsr(A)))
	endif
	//print isi_summed, "isi summed"
//add graph to window
	AppendtoGraph/W=Baseline_Firing_Analysis /L=psileft /B=psibottom tempwave_psd
// fix styles for graphs
	Modifygraph/W=Baseline_Firing_Analysis axisEnab(psibottom)={.68,1}
	Modifygraph/W=Baseline_Firing_Analysis axisEnab(psileft)={.1,.4}
	Modifygraph/W=Baseline_Firing_Analysis freePos(psibottom)={0,psileft}
	Modifygraph/W=Baseline_Firing_Analysis freePos(psileft)={0,psibottom}
	Modifygraph/W=Baseline_Firing_Analysis lblPos(psibottom)=35, lblPos(histleft)=35
	ModifyGraph/W=baseline_firing_analysis log(psileft)=1
//add psi_factor and PSD peak to window
	wavestats /Q/R=[5,130] tempwave_psd
	psi_text="Psi = "
	psi_text[7]=num2str(psi_factor)
	setdrawenv /w=baseline_firing_analysis fsize=10
	drawtext /W=Baseline_Firing_Analysis 0.70, 0.59, psi_text
	PSD_text="Peak of PSD = "
	PSD_text[14]=num2str(V_max)
	setdrawenv /w=baseline_firing_analysis fsize=10
	drawtext /w=baseline_firing_analysis 0.7, 0.62, PSD_text
end

macro my_psd_macro()
	PSD("tempwave",1,2)
end
	

//-----------Buttons, etc.----------------
function checkXYPSDplot(name, value)
	string name
	Variable value
	Nvar XYPSDplot_on
	if (value)
		Popupmenu popupxwavePSD, proc=assignwavepopup, title="Wave of x values", value=WaveList("*",";","")
		popupmenu popupxwavePSD, pos={0,85}, win=Choose_Waves_PSD, disable=0
		XYPSDplot_on=1
	else
		Popupmenu popupxwavePSD, noproc, title="Wave of x values", value=WaveList("*",";","")
		popupmenu popupxwavePSD, pos={0,85}, disable=2, win=Choose_Waves_PSD
		XYPSDplot_on=0
	endif
end

function assignwavePSDpopup(ctrlname, popnum, popstr) : popupmenucontrol
	string ctrlname
	variable popnum
	string popstr
	String/G wavenPSD
	String/G xwavePSD
	if (stringmatch(ctrlname,"popupwavenPSD"))
		wavenPSD=popstr
	elseif (stringmatch(ctrlname,"popupxwavePSD"))
		xwavePSD=popstr
	endif
end

Function PSDButton_okay(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k  Choose_Waves_PSD
	PSDanalysiswindow()
End

Function PSDButtonkill_choosewaves(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k  Choose_Waves_PSD
	Killstrings /Z wavenPSD, xwavePSD
End

function radiobut_PSDchange(name, value)
	string name
	variable value
	nvar countspikes_on
	nvar anal_length
	strswitch(name)
		case"radiobut_countspikes":
			countspikes_on=1
			SetVariable setvar_anal_length,title="Number of Spikes to analyze",limits={200,2000,100}
			anal_length=500
			break
		case"radiobut_counttime":
			countspikes_on=0
			SetVariable setvar_anal_length,title="Minutes of data to analyze",limits={0,60,5}
			anal_length=10
			break
	endswitch
	checkbox radiobut_countspikes,value= countspikes_on==1
	checkbox radiobut_counttime,value=countspikes_on==0
end

Function Buttonkill_PSDanalysisplot(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k  Baseline_Firing_Analysis
	if (waveexists(tempwave))
		Killwaves tempwave
	endif
	if (waveexists(histtempwave))
		Killwaves histtempwave
	endif
	if (waveexists(FFT_Wave))
		Killwaves FFT_Wave
	endif
	if (waveexists(tempwave_PSD))
		Killwaves tempwave_psd
	endif
	//kill variables, including wavestats vars
	killwaves workingwave
	if (waveexists(timewave))
		killwaves timewave
	endif
	Killstrings /Z wavenPSD, xwavePSD
End

Function resetPSDplotbutton(ctrlName) : ButtonControl
	string ctrlName
	wave tempwave
	wave histtempwave
	Cursor /K /W=Baseline_Firing_Analysis A
	Cursor /K /W=Baseline_Firing_Analysis B
	tempwave=2
	histtempwave=0
	//clear fft waves, too
end

Function analyzePSDbutton(ctrlName) : ButtonControl
	string ctrlName
	doPSDanalysis()
end

Function savePSDanalysisbutton(ctrlname) : ButtonControl
	string ctrlName
	string wavesave
	Nvar anal_length
	Nvar countspikes_on
	wave tempwave
	Note tempwave, "Depol. threshold:"
	Note tempwave, num2str(vcsr(A))
	Note tempwave,"Start time of analysis:"
	Note tempwave, num2str(xcsr(A)) //check this, may need if/else for xy plot
	if (countspikes_on)
		Note tempwave, "Number of Spikes in analysis:"
		Note tempwave, num2str(anal_length)
	else
		Note tempwave, "Length of time analyzed:"
		Note tempwave, num2str(anal_length)
	endif
	prompt wavesave, "Name analysis wave"
	DoPrompt "Name analysis wave", wavesave
	Rename tempwave,$wavesave; 
	saveexperiment 
end



//--------------------Create/Export ISI Wave-------------EBM--------1/24/05-------------------------------------------

//This macro automatically takes as input the concatenated sweeps (or will concatenate the sweeps itself if 
//"wholeexpt" does not exist as a wave), displays this wave, and then allows the user to create a wave of 
//interspike intervals.  
//The number of ISIs and where the calculation begins can be set interactively in the
//display and analysis can be re-executed until the user is satisfied and saves/exports the displayed result.
//The exported wave is a text file that can be directly imported into other programs such as Matlab. 

function createisi()
	setdatafolder root:wholecell:
	//initialize variables
	Make/o isitempwave
	variable/g ISInumtot=700

//does the concatenated wave exist?  if not, create
	if (waveexists(wholeexpt)==0)
		sweepcount()
	endif
	isitempwave=2
//build panel
	Display /w=(150,150,550,550)  /L=potential /B=stdtime wholeexpt vs expttime
	dowindow/c ISI_window
	//ISInumtot=700
//buttons and options
	Showinfo
	ControlBar 45
	setdrawenv fsize=10 
	drawtext  0.1,.02, "Choose starting peak with cursor A"
	SetVariable ISI_number,pos={10,15},size={220,16},title="Number of Interspike Intervals: "
	SetVariable ISI_number,limits={0,2000,50},value=ISInumtot
	Button ISIanalyzebutton, pos={250,15}, size={60,20}, proc=ISIanalyzebutton, title="Analyze"
	Button ISIsavebutton, pos={315,15}, size={60,20}, proc=ISIsavebutton, title="Save"
	Button  ISIexportbutton, pos={380, 15}, size={60,20}, proc=ISIexportbutton, title="Export"
	Button  ISIclosebutton, pos={455,15}, size={60,20}, proc=ISIbuttonkill, title="Close"
//graphs: concatenated sweeps and ISI temp wave
	AppendtoGraph/L=freq /B=newbottom isitempwave
	ModifyGraph freePos(potential)={0,stdtime}
	Modifygraph axisEnab(potential)={.6,1}
	Modifygraph axisEnab(freq)={0.1,.45}
	Modifygraph freePos(stdtime)={-80, potential}
	Modifygraph axisEnab(stdtime)={0.1,1}
	Modifygraph axisEnab(newbottom)={0.1,1}
	Modifygraph freePos(freq)={0,newbottom}
	Modifygraph freePos(newbottom)={0,freq}
	label potential "Membrane Potential (mV)"
	label stdtime "Time (min)"
	label freq "ISI length (msec)"
	label newbottom "ISI index"
	ModifyGraph lblPos(potential)=45,lblPos(freq)=45,lblPos(stdtime)=37,lblPos(newbottom)=37
end

//actual computation function for interspike intervals  ********
Function isianalfxn()
	variable deltatemp
	variable APPSDhigh
	variable xstartpt
	variable instantinterval
	variable newstartmark
	variable laststartmark
	nvar ISInumtot
	variable i
	variable k
	variable isimean
	variable isiskew
	variable psi_factor
	variable isistdev
	variable j
	variable isi_summed=0
	wave wholeexpt

	make /o /n=(isinumtot) isitempwave
	make /o /n=(isinumtot) isitimewave
	
	deltatemp=0.0002 	//this currently assumes the collection rate is 5KHz
	APPSDhigh=vcsr(A)
	xstartpt=x2pnt(wholeexpt,xcsr(A))
	i=xstartpt
	laststartmark=i
	k=0   	//k is the index of the wave that lists the inter-spike intervals
	do
		if (wholeexpt[i-1]<APPSDhigh && wholeexpt[i]>APPSDhigh)
		 	newstartmark=i
		 	instantinterval=deltatemp*1000*(newstartmark-laststartmark)
			isitempwave[k]=instantinterval
			isitimewave[k]=laststartmark/300000
		 	isi_summed=isi_summed+isitempwave[k]
			k+=1
	 		laststartmark=newstartmark
	 	endif	
	 	i += 1
	while (k<=ISInumtot)
	wavestats /q isitempwave
	isimean=V_avg
	isistdev=V_sdev
	isiskew=V_skew
	print "ISI mean: " , isimean
	print "ISI skew: " , isiskew
	print "ISI stdev: '" , isistdev
	duplicate /O/D isitempwave FFT_Wave
	FFT FFT_Wave
	j=0
	do
		psi_factor=psi_factor+abs(FFT_Wave[j])/isi_summed
		j+=1
	while (j<=ISInumtot)
	print "psi factor: ", psi_factor
end

//button functions

Function ISIanalyzebutton(ctrlname) : ButtonControl
	string ctrlName
	isianalfxn()
end

Function ISIsavebutton(ctrlname) : ButtonControl
	string ctrlName
	string wavesave
	wave tempwave
	prompt wavesave, "Name ISI wave"
	DoPrompt "Name ISI wave", wavesave
	duplicate isitempwave,$wavesave+"_isi"; 
	duplicate isitimewave, $wavesave+"_time"
	saveexperiment 
end

Function ISIexportbutton(ctrlname) : ButtonControl
	string ctrlName
	wave isitempwave
	save/j/m="\r\n" isitempwave
	save/j/m="\r\n" isitimewave
//	saveexperiment 
end

Function ISIbuttonkill(ctrlname) : ButtonControl
	string ctrlName
	dowindow /k ISI_window
	killwaves isitempwave
	killvariables /z isinumtot
//	saveexperiment 
end

//------------------Calculate Short Firing Rates (within a sweep)----------EBM-----------12/30/2016-----------

Function ap_count()
	variable ap_counted = 0
	String waveCursorAIsOn = CsrWave(A)
	variable startloc =x2pnt($waveCursorAIsOn, xcsr(A))
	variable endloc = x2pnt($waveCursorAIsOn, xcsr(B))
	variable starttime = xcsr(A)
	variable endtime = xcsr(B)
	//variable vertloc = vcsr(A)
 	variable vertloc = 0
 	variable i = startloc
 	Make /o analsweep
 	Duplicate /o $waveCursorAIsOn, analsweep
	do
		if (analsweep[i] > vertloc)
			//print vertloc, analsweep[i], i
			ap_counted+=1
			i+=200
	 	endif	
	 	i += 1
	while (i < endloc)
	print "testing" , ap_counted
	print "time" ,  endtime - starttime
	print "Frequency " , ap_counted/(endtime - starttime)
	killwaves analsweep
end

