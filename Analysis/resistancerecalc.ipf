#pragma rtGlobals=1		// Use modern global access method.
#include <Power Spectral Density>

Menu "Macros"
	"Input Resistance CC", inputresistance()
	"Resistances VC", VCresistances()
end


//---------------------------------Post Experiment Input Resistance Calculation EBM 4/12/06-------------------------------
//edited 12/16/18 EBM

function inputresistance() 
	string foldername
	foldername="root:acquisition"
	if (datafolderexists(foldername))
		setdatafolder root:acquisition:data
	else
		setdatafolder root:wholecell
	endif
	Variable /G anal_length
	anal_length=20
	Variable/G  numsweeps
	String swpname
	Variable sweepexists=1
	Variable /G analyzeall
	variable /G RIstepsize  
	analyzeall=0
	numsweeps=0
	RIstepsize=4
	do
		swpname="sweep"+num2str(numsweeps+1)
		if (! waveexists($swpname))
			sweepexists=0
		endif
		numsweeps+=1
	while (sweepexists > 0)
	numsweeps -=1
	anal_length=numsweeps
	NewPanel /W=(350,100,730,280)
	TabControl Ri_options, pos={5,35}, size={360,20}, tablabel(0)="analyze baseline",value=0
	DoWindow /C Input_R_Options
	TitleBox tb1,title="     For current clamp data only     ",pos={50,5}, size={30, 240}
	setVariable setvar_RIstepsize,pos={20,63}, size ={100,20}, title="Step Size", value=RIstepsize, live=1
	Popupmenu popupstartsweep, proc=IRassignwavepopup, title="First sweep: ", value=WaveList("*",";","")
	Popupmenu popupstartsweep, pos={20,88}
	SetVariable setvar_anal_length,pos={20,115},size={200,20},title="Number of sweeps to analyze"
	SetVariable setvar_anal_length,limits={1,numsweeps,1},value= anal_length
	Button okaybuttonRI, pos={30, 146}, proc=button_okay_RI, title="Okay", size={60, 20}
	Button  closebuttonRI, pos={130, 146}, proc=buttonkill_RI, title="Cancel", size={60,20}
	TabControl Ri_options, pos={5,35}, size={360,20}, proc=Ri_tabs, tablabel(1)="analyze whole experiment"
end

function RIcalcwindow()
	svar startsweep
	duplicate /O $startsweep workingwave2
	Display /w=(150,150,500,400) /N=forRcalc /L=potential /B=stdtime workingwave2
	dowindow /c RI_calc_window
	setaxis stdtime 0, .6
	setaxis potential -100, -40
	Showinfo
	ControlBar 45
	setdrawenv fsize=10 
	drawtext  0.2,.03, "Choose Ri step change with cursor A"
	Button ISIanalyzebutton, pos={60,15}, size={60,20}, proc=Iranalyzebutton, title="Analyze"
	Button  ISIclosebutton, pos={160,15}, size={60,20}, proc=Irbuttonkill, title="Close"
//graph
	ModifyGraph freePos(potential)={0,stdtime}
	Modifygraph axisEnab(potential)={.1,1}
	label potential "Membrane Potential (mV)"
	label stdtime "Time (sec)"
end

function RIcalcwindowall()
	string foldername
	string startsweep
	foldername="root:acquisition"
	if (datafolderexists(foldername))
		if(waveexists(rs1))
			startsweep="rs1"
		else	
			startsweep="sweep1"
		endif
	else
		startsweep="sweep1"
	endif
	duplicate /O $startsweep workingwave2
	Display /w=(150,150,550,400)  /L=potential /B=stdtime workingwave2
	dowindow /c RI_calc_window
	setaxis stdtime 0, .6
	setaxis potential -100, -40
	Showinfo
	ControlBar 45
	setdrawenv fsize=10 
	drawtext  0.2,.03, "Choose Ri step change with cursor A"
	Button ISIanalyzebutton, pos={30,15}, size={60,20}, proc=Iranalyzeallbutton, title="Analyze"
	Button  ISIclosebutton, pos={120,15}, size={60,20}, proc=Irbuttonkill, title="Close"
	Button Ri_graphbutton, pos={220,15}, size={160,20}, proc=Irgraphbutton, title="Graph against sweep_t"
//graph
	ModifyGraph freePos(potential)={0,stdtime}
	Modifygraph axisEnab(potential)={.1,1}
	Modifygraph freePos(stdtime)={-80, potential}
	Modifygraph axisEnab(stdtime)={0.1,1}
	label potential "Membrane Potential (mV)"
	label stdtime "Time (sec)"
end

function RIcalc()
	variable i
	variable currsweepnum
	variable startsweepnum
	nvar anal_length
	variable input_resist
	variable baseline_V
	variable step_V
	variable step_time
	variable start
	variable endtime
	variable IR_from_IH
	svar startsweep
	string swpname
	string foldername
	variable old_new
	variable tab
	nvar RIstepsize
	variable numsweeps
	foldername="root:acquisition"
	if (datafolderexists(foldername))
		if(waveexists(rs1))
			old_new=1
		else	
			old_new=0
		endif
	else
		old_new=0
	endif
	step_time=xcsr(A)
	start=step_time-0.007
	endtime=step_time+0.007
	i=0
	if (stringmatch(startsweep, "sweep*"))
		sscanf startsweep, "sweep%f", startsweepnum
		do
			currsweepnum=i+startsweepnum
			swpname="sweep"+num2str(currsweepnum)
			Duplicate /O $swpname, currentsweep
			baseline_V=mean(currentsweep,0,0.015)
			step_V=mean(currentsweep,start, endtime)
			input_resist=input_resist+abs(baseline_V-step_V)/(10*RIstepsize)
			i+=1
		while(i<anal_length)
	else
		sscanf startsweep, "rs%f", startsweepnum
		do
			currsweepnum=i+startsweepnum
			swpname="rs"+num2str(currsweepnum)
			Duplicate /O $swpname, currentsweep
			baseline_V=mean(currentsweep,0,0.015)
			step_V=mean(currentsweep,start, endtime)
			input_resist=input_resist+abs(baseline_V-step_V)/(10*RIstepsize)
			i+=1
		while(i<anal_length)
	endif
	input_resist=1000*input_resist/anal_length
	print "From Current Clamp: ", input_resist,  " MOhm"	
end

function RIcalcall()
	variable i
	variable currsweepnum
	variable startsweepnum
	nvar anal_length
	variable input_resist
	variable baseline_V
	variable step_V
	variable step_time
	variable start
	variable endtime
	variable IR_from_IH
	svar startsweep
	string swpname
	string foldername
	variable old_new
	variable numsweeps
	nvar RIstepsize
	foldername="root:acquisition"
	if (datafolderexists(foldername))
		if(waveexists(rs1))
			old_new=1
		else	
			old_new=0
		endif
	else
		old_new=0
	endif
	make /O  /N=(anal_length) revisedinputresistance
	step_time=xcsr(A)
	start=step_time-0.007
	endtime=step_time+0.007
	i=0
	startsweepnum=1
	if (old_new==0)
		do
			currsweepnum=i+startsweepnum
			swpname="sweep"+num2str(currsweepnum)
			Duplicate /O $swpname, currentsweep
			baseline_V=mean(currentsweep,0,0.015)
			step_V=mean(currentsweep,start, endtime)
			revisedinputresistance[i]=1000*abs(baseline_V-step_V)/(10*RIstepsize)
			i+=1
		while(i<anal_length)
	else
		do
			currsweepnum=i+startsweepnum
			swpname="rs"+num2str(currsweepnum)
			Duplicate /O $swpname, currentsweep
			baseline_V=mean(currentsweep,0,0.015)
			step_V=mean(currentsweep,start, endtime)
			revisedinputresistance[i]=1000*abs(baseline_V-step_V)/(10*RIstepsize)
			i+=1
		while(i<anal_length)
	endif
end		

function IRassignwavepopup(ctrlname, popnum, popstr) : popupmenucontrol
	string ctrlname
	variable popnum
	string popstr
	String/G startsweep
	startsweep=popstr
end

Function Button_okay_RI(ctrlName) : ButtonControl
	String ctrlName
	variable RIstepsize
	DoWindow /k Input_R_Options
	RIcalcwindow()
End

function button_anayzeall_RI(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k Input_R_Options
	RIcalcwindowall()
End

function Iranalyzebutton(ctrlName) : ButtonControl
	string ctrlName
	RIcalc()
end

function Iranalyzeallbutton(ctrlName) : ButtonControl
	string ctrlName
	RIcalcall()
end

Function Buttonkill_RI(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k  Input_R_Options
	killwaves /z currentsweep
End

function Ri_tabs(name,tab)
	String name
	Variable tab
	Variable analyzeall
	SetVariable setvar_anal_length, disable=(tab!=0)
	Popupmenu popupstartsweep, disable=(tab!=0)
	Button okaybuttonRI,disable=(tab!=0)
	Button analyzeallbuttonRI, pos={30, 146}, proc=button_anayzeall_RI, title="Okay", size={60, 20} 
	Button analyzeallbuttonRI, disable=(tab!=1)
End

Function Irbuttonkill(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k  RI_calc_window
	Killwaves /Z workingwave2
End

Function Irgraphbutton(ctrlName) : ButtonControl
	String ctrlName
	wave revisedinputresistance
	string foldername
	foldername="root:acquisition"
	if (datafolderexists(foldername))
			display /L=rinlbl /B=expttimelbl revisedinputresistance vs root:acquisition:sweep_t
	else
		display /L=rinlbl /B=expttimelbl revisedinputresistance vs root:sweep_t
	endif
	ModifyGraph freePos(rinlbl)={0,expttimelbl}
	Modifygraph axisEnab(rinlbl)={.1,1}
	Modifygraph freePos(expttimelbl)={-80, rinlbl}
	Modifygraph axisEnab(expttimelbl)={0.1,1}
	label rinlbl "Rin (MOhm)"
	label expttimelbl "Time (min)"
End

//---------reanalyze series resistance and input resistance in voltage clamp experiments------
//edited------EBM---12/16/2018-----

function VCresistances()
	variable /G Rstepsize  
	Rstepsize=4
	NewPanel /W=(350,100,530,180)
	DoWindow /C VC_R_Options
	setVariable setvar_RIstepsize,pos={30,15}, size ={120,20}, title="Step Size (mV)", value=Rstepsize, live=1
	Button okaybuttonRI, pos={20, 46}, proc=button_okay_VCR, title="Okay", size={60, 20}
	Button  closebuttonRI, pos={100, 46}, proc=buttonkill_VCR, title="Cancel", size={60,20}
end

function VCresistancecalc()
	variable i, j
	variable currsweepnum
	variable old_new
	nvar Rstepsize
	variable is_step_separate
	Variable  numsweeps
	String swpname
	Variable sweepexists=1
	variable RSpointnum
	variable RIpointnum
	variable BASEpointnum
	variable pointval
	variable threshloctemp
	variable x_scale
	variable baseline_I
	variable step_I
	
	//go to data folder; figure out if step is in the main sweep
	string foldername		
	foldername="root:acquisition"
	if (datafolderexists(foldername))
		setdatafolder root:acquisition:data
		old_new=1
		//if rs is separate sweep, is_step_separate = 1
		swpname="rs1"
		if (! waveexists($swpname))
			is_step_separate = 1
		endif
		is_step_separate = 0
	else
		setdatafolder root:wholecell
		is_step_separate = 0
		old_new=0
	endif
	
	//count the number of sweeps in the experiment
	do
		swpname="sweep"+num2str(numsweeps+1)
		if (! waveexists($swpname))
			sweepexists=0
		endif
		numsweeps+=1
	while (sweepexists > 0)
	numsweeps -=1
	make /O  /N=(numsweeps) revisedseriesresistance
	make /O  /N=(numsweeps) revisedinputresistance
	SetScale/P x 0,x_scale,"", revisedseriesresistance

	//find step start
	Duplicate/O sweep5,sweep5_smth
	Smooth 4, sweep5_smth
	Differentiate sweep5_smth /D=sweep5_DIF
	i=0
	threshloctemp=0
	do
		pointval = sweep5_DIF[i]
		if (pointval < -300000)	//adjust for lower sampling rates?
			threshloctemp = i	
		endif
		i+=1
	while (threshloctemp == 0)	
	threshloctemp = threshloctemp - 5
	BASEpointnum = threshloctemp - 50
	Duplicate /O sweep1, currentsweep
	pointval = currentsweep[threshloctemp]
	j = 0
	do
		if (currentsweep[threshloctemp + j] < pointval)
			RSpointnum = threshloctemp + j
			pointval =  currentsweep[threshloctemp + j]
		endif
		j += 1
	while (j < 20)
	
	//find step end
	i = RSpointnum + 100
	RIpointnum = RSpointnum
	do
		pointval = sweep5_DIF[i]
		if (pointval > 300000)	//adjust for lower sampling rates? *****
			RIpointnum = i	
		endif
		i+=1
	while (RSpointnum == RIpointnum)	
	
	//recalc the resistances into new waves
	x_scale = deltax(currentsweep)
	i = 1
	do
		swpname="sweep"+num2str(i) //fix for if step is separate wave? *****
		Duplicate /O $swpname, currentsweep
		baseline_I=mean(currentsweep,BASEpointnum*x_scale,(BASEpointnum + 40)*x_scale)
		pointval= currentsweep[RSpointnum]
		revisedseriesresistance[i-1] = 1000*Rstepsize/(baseline_I - pointval)
		step_I = mean(currentsweep, (RSpointnum + 100)*x_scale, (RIpointnum-10)*x_scale)
		revisedinputresistance[i-1] = 1000*Rstepsize/(baseline_I - step_I)
		i+=1
	while(i<numsweeps)
	display /W=(550,10,1000,200) revisedseriesresistance vs root:acquisition:sweep_t
	wavestats /Q revisedseriesresistance
	ModifyGraph mode=4,marker=16
	SetAxis left 0,V_max
	Label left "Rs (MOhm)"
	Label bottom "Time (min)"
	display /W=(550,280,1000,470) revisedinputresistance vs root:acquisition:sweep_t
	wavestats /Q revisedinputresistance
	ModifyGraph mode=4,marker=16
	SetAxis left 0,2*V_avg
	Label left "Ri (MOhm)"
	Label bottom "Time (min)"
	
	killwaves sweep1_DIF, currentsweep
	killvariables Rstepsize  
end		

Function Button_okay_VCR(ctrlName) : ButtonControl
	String ctrlName
	variable RIstepsize
	DoWindow /k VC_R_Options
	VCresistancecalc()
End

Function Buttonkill_VCR(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k  VC_R_Options
	killwaves /z currentsweep
End