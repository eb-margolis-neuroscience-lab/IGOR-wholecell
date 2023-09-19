#pragma rtGlobals=1		// Use modern global access method.
#include <Strings as Lists>

// This procedure file provides code for a reanalysis graph...  version 4.00
// This procedure is backward compatible with earlier versions of 'Acquisition'

Menu "Macros"
	"Reanalysis NIDAQ Data", analysis_graph()
End

Macro analysis_graph()
	createbrowser prompt="Select appropriate data folder"
	string dir=getdatafolder(1)
	newdatafolder /o root:acquisition
	newdatafolder /o/s root:acquisition:reanalysis
	variable /g wave_number = 1
	variable /g wave_time = 0
	variable /g wave_value = 0
	variable baseline_value = 0
	string /g wave_name = "sweep"
	make /o input_re = 0
	make /o/n=0 reanalysis_value, reanalysis_time
	DoWindow /k Reanalysis
	reanalysis()
	if (exists(dir+wave_name + "1")))
		duplicate /o $(dir+wave_name+"1") input_re
		if (strlen(note(input_re)) == 0)
			wave_time = input_re[0]
			input_re[0] =  input_re[1]
		else
			wave_time = str2num(note(input_re))
		endif
		controlinfo check0
		if ( v_value==1)
			baseline_value = input_re[0]
			input_re -= baseline_value
		endif
	else	
		input_re = 0
		wave_number = 0
	endif
	setdatafolder dir
endmacro

Window reanalysis() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:acquisition:reanalysis:
	Display /W=(9.75,40.25,809.75,1200.25) input_re as "Analysis Window"
	AppendToGraph/L=re_left/B=re_bottom reanalysis_value vs reanalysis_time
	SetDataFolder fldrSav
	ModifyGraph mode(reanalysis_value)=3
	ModifyGraph marker(reanalysis_value)=19
	ModifyGraph zero(left)=3
	ModifyGraph standoff(left)=0,standoff(bottom)=0
	ModifyGraph lblPos(left)=54,lblPos(bottom)=37,lblPos(re_left)=46
	ModifyGraph lblLatPos(re_left)=-3
	ModifyGraph freePos(re_left)=0
	ModifyGraph freePos(re_bottom)=-186
	ModifyGraph axisEnab(left)={0,0.6}
	ModifyGraph axisEnab(re_left)={0.75,1}
	SetAxis/A/N=1 left
	SetAxis/A/N=1 re_left
	SetAxis/A re_bottom
	SetAxis/A bottom
	Textbox/N=timestamp/F=0/X=-1.00/Y=38.00 "\\{secs2time(60*root:acquisition:reanalysis:wave_time,3)}"
	Cursor A input_re 200;Cursor B input_re 250
	ShowInfo
	ControlBar 55
	SetVariable setvar0,pos={255,5},size={90,20},proc=ChangeSweep,title="Sweep"
	SetVariable setvar0,fSize=10,limits={1,Inf,1},value= root:acquisition:reanalysis:wave_number
	Button button0,pos={10,5},size={50,40},proc=StartReanalysis,title="Start"
	Button button1,pos={70,5},size={80,20},proc=Switch_Dir,title="New folder"
	Button button2,pos={260,30},size={50,20},proc=Write_update,title="Write"
	SetVariable setvar1,pos={160,5},size={60,20},proc=Switch_Name,title=" ",value= root:acquisition:reanalysis:wave_name
	PopupMenu popup0,pos={65,30},size={180,20},title="Reanalysis Option"
	PopupMenu popup0,mode=1,popvalue="Amplitude",value= #"\"Amplitude;Slope;Peak to Peak;Absolute;PPF;Spike Rate;SDev;Ampl find min\""
	CheckBox check0, title="Zero",pos={350,5},value=1
	ValDisplay valdisp0, pos={320,25}, size={75,25}, value=root:acquisition:reanalysis:wave_value
	ValDisplay valdisp0, fsize=16,  format =  "%.2f"
	Button newgr_button,pos={420,5},size={90,40},proc=makegraph,title="Make Graph"
EndMacro

Function ChangeSweep(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVar wave_time = root:acquisition:reanalysis:wave_time
	Wave input_re = root:acquisition:reanalysis:input_re
	NVar wave_value = root:acquisition:reanalysis:wave_value
	SVar wave_name = root:acquisition:reanalysis:wave_name
	variable baseline_value
	if (exists(wave_name+num2str(varNum)))
		duplicate /o $(wave_name+num2str(varNum)) input_re
		if (strlen(note(input_re)) == 0)
			wave_time = input_re[0]
			input_re[0] =  input_re[1]
		else
			wave_time = str2num(note(input_re))
		endif
		controlinfo check0
		if ( v_value==1)
			baseline_value = input_re[1200]
			input_re -= baseline_value
		endif
		Controlinfo popup0  	//v_value gives analysis type
		wave_value = reanalysis_option (v_value)
	else
		input_re = 0
	endif		
End

Function Write_update(ctrlName) : ButtonControl
	String ctrlName
	NVar wave_number = root:acquisition:reanalysis:wave_number
	NVar wave_time = root:acquisition:reanalysis:wave_time
	NVar wave_value = root:acquisition:reanalysis:wave_value
	Wave input_re = root:acquisition:reanalysis:input_re
	Wave reanalysis_time = root:acquisition:reanalysis:reanalysis_time
	Wave reanalysis_value = root:acquisition:reanalysis:reanalysis_value
	Controlinfo popup0  	//v_value gives analysis type
	wave_value = reanalysis_option (v_value)
	if (wave_number > DimSize(reanalysis_value,0))
		redimension /n=(wave_number) reanalysis_time, reanalysis_value
	endif
	reanalysis_time[wave_number-1] = wave_time
	reanalysis_value[wave_number-1] = wave_value
End

Proc Switch_Dir(ctrlName) : ButtonControl
	String ctrlName
	CreateBrowser prompt="Select appropriate data folder"
	root:acquisition:reanalysis:wave_number = 1
	ChangeSweep("",root:acquisition:reanalysis:wave_number,"","")
End

Function Switch_name(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVar wave_number = root:acquisition:reanalysis:wave_number
	wave_number = 1
	ChangeSweep("",1,"","")
End


Function StartReanalysis(ctrlName) : ButtonControl
	String ctrlName
	NVar wave_number = root:acquisition:reanalysis:wave_number
	NVar wave_time = root:acquisition:reanalysis:wave_time
	SVar wave_name = root:acquisition:reanalysis:wave_name
	Wave reanalysis_time = root:acquisition:reanalysis:reanalysis_time
	Wave reanalysis_value = root:acquisition:reanalysis:reanalysis_value
	Wave input_re = root:acquisition:reanalysis:input_re
	variable baseline_value, temp_filler
	Controlinfo popup0  	//v_value gives analysis type
	variable analysis_type = v_value
	///wave_number -= 1
	wave_number = 1
	print "Analyzing "+S_value+" from "+num2str(xcsr(A))+" to " +num2str(xcsr(B))
	RemoveFromGraph /Z fit_input_re
	Do
		wave_number +=1
		duplicate /o $(wave_name+num2str(wave_number)) input_re
		if (strlen(note(input_re)) == 0)
			wave_time = input_re[0]
			input_re[0] =  input_re[1]
		else
			wave_time = str2num(note(input_re))
		endif
		controlinfo check0
		if ( v_value==1)
			baseline_value = input_re[0]
			input_re -= baseline_value
		endif
		redimension /n=(wave_number) reanalysis_time, reanalysis_value
		reanalysis_time[wave_number-1] = wave_time
		temp_filler = Reanalysis_option(analysis_type)
	//	print temp_filler
		reanalysis_value[wave_number-1] = temp_filler
	while(exists(wave_name+num2str(wave_number+1)))
	SetAxis/A  /W=reanalysis re_bottom
End

Function Reanalysis_option(analysis_type)
	variable analysis_type
	variable reanalysis_val
	make /o /n=2 W_coef = 0
	Wave input_re = root:acquisition:reanalysis:input_re
	Wave cv_fit = root:acquisition:wholecell:cv_fit
	DoWindow /f Reanalysis
	if (analysis_type ==1)		//amplitude
	//reanalysis_val = mean(input_re,xcsr(B),xcsr(B)+.001)-mean(input_re,xcsr(A),xcsr(A)+.001)
		reanalysis_val = mean(input_re,xcsr(B)-.001,xcsr(B)+.001)-mean(input_re,xcsr(A)-.0002,xcsr(A)+.0002)
	endif
	if (analysis_type==2)		//slope
		Curvefit /N/Q line, input_re (xcsr(A),xcsr(B)) /D
		reanalysis_val = W_Coef [1]
	endif
	if (analysis_type==3)		//peak amplitude
		Wavestats /Q /R = (xcsr(A),xcsr(B)) input_re
 		reanalysis_val = V_max - V_min
	endif	
	if (analysis_type==4)		//Absolute amplitude
		reanalysis_val = mean(input_re,xcsr(A),xcsr(B))
	endif
// ------------------------------------------Enter User defined functions here---------------------------------------------------------------		
//	if (analysis_type == 5)		// User defined #1 
//		reanalysis_val = mean(input_re,xcsr(B),xcsr(B)+.001) - input_re(xcsr(A))*mean(cv_fit,xcsr(B),xcsr(B)+.001)/(cv_fit(xcsr(A)))
//	endif
	
//	if (analysis_type == 6)		// User defined #1  -- currently set for finding time of something
//		Differentiate input_re
//		Wavestats /Q /R = (xcsr(A),xcsr(B)) input_re
//		if (v_max > 50000)
//			reanalysis_val = V_maxloc
//		else
//			reanalysis_val = 0
//		endif
//	endif
//	
	if (analysis_type == 5)  // calculates PPF after subtracting exponential tail
		reanalysis_val = mean(input_re,xcsr(B)-.001,xcsr(B)+.001)-mean(input_re,xcsr(A)-.001,xcsr(A)+.001)
		CurveFit /N /Q exp input_re(xcsr(b)+.005,xcsr(B)+.035) /D 
		reanalysis_val = (mean(input_re,xcsr(B)+.049,xcsr(B)+.051) - (W_coef[0] + W_coef[1] *exp(-W_coef[2]* (xcsr(B)+.05))))/reanalysis_val
	endif

if (analysis_type == 6)		// determines spike rate
	reanalysis_val = Count_spikes()
endif
if (analysis_type == 7)		// User defined #1  -- currently set for finding time of something
	Wavestats /Q /R = (xcsr(A),xcsr(B)) input_re
	reanalysis_val = V_avg
endif
if (analysis_type ==8)		//amplitude with find minimum peak of the response
	wavestats /Q /R=(xcsr(B)-.0003,xcsr(B)+.0003) input_re
	reanalysis_val = V_min-mean(input_re,xcsr(A)-.0005,xcsr(A)+.0005)
	endif
return reanalysis_val
end

Function count_spikes()
Wave input_re = root:acquisition:reanalysis:input_re
variable step = pcsr(A)
variable laststep = pcsr(B)
variable count = 0
	duplicate /o input_re difwave
	differentiate difwave
	Wavestats /Q /R = (xcsr(A), xcsr(B)) difwave
	variable threshold = 5 * V_sdev
	if (V_max > threshold)
		Do 
			if (difwave[step-1]<threshold && difwave[step] >=threshold)
				count += 1
				step += 20
			endif
			step += 1
		while (step < laststep)
	endif
return (5000*count/V_npnts)
end

Function makegraph(ctrlName) : ButtonControl
	String ctrlName
	Display ::reanalysis:reanalysis_value vs ::reanalysis:reanalysis_time
	ModifyGraph mode=3,marker=19,rgb=(1,16019,65535)
End