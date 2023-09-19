#pragma rtGlobals=1		// Use modern global access method.

//			NIDAQ Acquisition Software  version 5.0MX 
//
//			for use with IgorPro version 5 and NIDAQtoolsMX
// 			(note: this procedure will not work with legacy versions of NI DAQ drivers.)
//	
//			version 5.0   introduces Pulse Train Generator, removes automatic series resistance monitoring
//
//			Connect Ctr0out to User1... this provides trigger for master-8
//			Connect DAC0Out to Amplifier command input 
//			Connect Amplifier out to ACH0
//			To acquire membrane holding potential in VC, have secondary output (Membrane Potential 10mv/mv) sent to ACH1
//			Temperature monitor to ACH2
//		

// --------------------------------------------------------User Variables ----------------------------------------------------------------------
Function User_Variables()

// ------  This holds the initial values for global variables  -- default values in {}
	Variable /G root:acquisition:variables:isi = 10					// Interstimulus interval in seconds {10}
	Variable /G root:acquisition:variables:stepsize = 4				// step size in mv for determining input/series R {4}
	Variable /G root:acquisition:variables:sw_length0 = 5			// sweep length (sec) for stimulation
	Variable /G root:acquisition:variables:sw_length1 = 10				// sweep length (sec) for firing rate
	Variable /G root:acquisition:variables:sw_length2 = 1				// sweep length (sec) for Ih test
	Variable /G root:acquisition:variables:sw_length3 = 5				// sweep length (sec) for IV ramp
	Variable /G root:acquisition:variables:kHz = 20					// DAQ sampling frequency in kHz {5}
	Variable /G root:acquisition:variables:voltage_clamp = 1			// 1 for voltage clamp, 0 for current clamp
	Variable /G root:acquisition:variables:user_gain_VC = 5			// user gain in voltage clamp (pA/mV) {10}
	Variable /G root:acquisition:variables:user_gain_CC = 50			// user gain in current clamp (mV/mV) {10}
	Variable /G root:acquisition:variables:channel_gain = 1			// DAQ board gain {1}
	Variable /G root:acquisition:variables:continuous0 = 0				// Continuous input for stimulation experiment
	Variable /G root:acquisition:variables:continuous1 = 1				// Continouus input for frequency experiment
	Variable /G root:acquisition:variables:RS_on = 1
	Variable /G root:acquisition:variables:Ih_test = 0
// Initial position (in seconds) for amplitude analysis	
	Variable /G root:acquisition:variables:ampl_1_on = 1				// 1 is on, 2 is off
	Variable /G root:acquisition:variables:ampl_2_on = 1				// 1 is on, 2 is off
	Variable /G root:acquisition:variables:ampl_1_zero =  .61			// ampl 1 baseline	
	Variable /G root:acquisition:variables:ampl_1_peak = .627			// ampl 1 peak
	Variable /G root:acquisition:variables:ampl_2_zero = .66			// ampl 2 baseline	
	Variable /G root:acquisition:variables:ampl_2_peak = .678			// ampl 2 peak	
	Variable /G root:acquisition:variables:ampl_width = .002			// width of analysis period (s) .002 = 2ms
//  Initial position (in seconds) for resistance analysis
	Variable /G root:acquisition:variables:series_left = .08
	Variable /G root:acquisition:variables:series_right = .12
	Variable /G root:acquisition:variables:input_left = .3
	Variable /G root:acquisition:variables:input_right = .35
//  Initial values for spike rate analysis
	Variable /G root:acquisition:variables:freq_left = .2
	Variable /G root:acquisition:variables:freq_right = 10
	Variable /G root:acquisition:variables:freq_thresh = 0
//  Initial values for IH test
	Variable /G root:acquisition:variables:starting_v_ih= -60		// initial holding potential for Ih test / IV ramp
	Variable /G root:acquisition:variables:step_v_ih= -120			// initial step to value for single Ih
	Variable /G root:acquisition:variables:IH_meas = 1  			// 0=early; 1=late; 2=difference
//  Values for multiclamp   --these values need to be modified if using auto gain control
	Variable /G root:acquisition:variables:multiclampAutoOn = 0  	//only turn on if axontelegraphmonitor.xop is installed
	Variable /G root:acquisition:variables:multiclampID=129541
	Variable /G root:acquisition:variables:multiclampCh=1
//  Variables for NIDAQ
	String /G root:acquisition:variables:NIDAQ_dev = "dev1"
	String /G root:acquisition:variables:NIDAQ_ctr = "/dev1/ctr0out"		// For newer NI boards this may be:   "/dev1/pfi12"
//  Pulse Train Generator
	Variable /G root:acquisition:variables:PTG_ch0 = 1			//Pulse Train Generator Channel 0 (on = 1)
	Variable /G root:acquisition:variables:PTG_ch1 = 1			//Pulse Train Generator Channel 1 (on = 1)
	
end

// --------------------------------------------------------Menu Procedures ----------------------------------------------------------------------
Menu "Ac&quisition" , dynamic			
	MenuSet (1), Initialization()
	"-"
	MenuSet (2), set_user()
	MenuSet (3), set_channel()
	MenuSet (4), setusergainMC()
	"-"
	MenuSet (5), Start_Acquisition("")
	MenuSet (6), Single_sweep(0)
	MenuSet (7), Single_sweep(1)
	MenuSet (8), Susp_save(2)
	"-" 
	MenuSet(9), resetdevice()
	"-"
	"Create Printout", Printout()
	"-"
	"Reanalysis window", analysis_graph()
	"-"
//	"Setup Help", OpenNotebook /R /p=user_procedures "acquisition setup.ifn"
	"Configure User Variables", DisplayProcedure "User_Variables"
	"About version 4.21MX", About_Acquisition()
End


Function /S MenuSet (itemNumber)			// This creates the dynamic menu.
	Variable itemNumber
	String firstitem = StrVarOrDefault("root:acquisition:menus:firstitem","Initialize Experiment")
	String seconditem = StrVarOrDefault("root:acquisition:menus:seconditem","(Set User Gain")
	String thirditem = StrVarOrDefault("root:acquisition:menus:thirditem","(Set Channel Gain")
	String fourthitem = StrVarOrDefault("root:acquisition:menus:fourthitem","(Auto User Gain")
	String fifthitem = StrVarOrDefault("root:acquisition:menus:fifthitem","Start Acquisition")
	String sixthitem = StrVarOrDefault("root:acquisition:menus:sixthitem","(Single Sweep -- no Analysis")
	String seventhitem = StrVarOrDefault("root:acquisition:menus:seventhitem","(Single Sweep -- Analyze and Save")
	String eighthitem = StrVarOrDefault("root:acquisition:menus:eighthitem","(Suspend Save each Sweep")
	String ninthitem = StrVarOrDefault("root:acquisition:menus:ninthitem","(Reset Device")
	if (itemNumber == 1)
		Return firstitem
	endif
	if (itemNumber == 2)
		Return seconditem
	endif
	if (itemNumber == 3)
		Return thirditem
	endif
	if (itemNumber == 4)
		Return fourthitem
	endif
	if (itemNumber == 5)
		Return fifthitem
	endif
	if (itemNumber == 6)
		Return sixthitem
	endif
	if (itemNumber == 7)
		Return seventhitem
	endif
	if (itemNumber == 8)
		Return eighthitem
	endif
	if (itemNumber == 9)
		Return ninthitem
	endif
//	if (itemNumber == 10)
//		Return tenthitem
//	endif
End

Function Menu_initialized()			// changes Menu items after initialization
	NVar mcAutoOn = root:acquisition:variables:multiclampAutoOn
	string /G root:acquisition:menus:seconditem = "Set User Gain"
	string /G root:acquisition:menus:thirditem = "Set Channel Gain"
	if (mcAutoOn)
		string /G root:acquisition:menus:fourthitem = "Auto User Gain"
	else	
		string /G root:acquisition:menus:fourthitem = "(Auto User Gain"
	endif
	string /G root:acquisition:menus:fifthitem = "Start Acquisition"
	string /G root:acquisition:menus:sixthitem =   "Single Sweep -- no Analysis"
	string /G root:acquisition:menus:seventhitem = "Single Sweep -- Analyze and Save"
	string /G root:acquisition:menus:eighthitem = "Suspend Save each Sweep"
	string /G root:acquisition:menus:ninthitem = "Reset Device"
End

Window About_Acquisition() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(273.75,130.25,570,328.25)
	SetDrawLayer UserBack
	SetDrawEnv fname= "Bookman Old Style"
	DrawText 3,192,"For use with Igor Pro 6.1 and NidaqtoolsMX"
	SetDrawEnv linefgc= (65535,65535,65535),fillfgc= (65280,59904,48896)
	DrawRect 32,21,267,109
	SetDrawEnv fname= "Bookman Old Style"
	DrawText 60,87,"Version 4.21MX  --  11/1/2012"
	SetDrawEnv fname= "Bookman Old Style",fsize= 28,fstyle= 1
	DrawText 66,61,"Acquisition"
	Button button0,pos={118,128},size={50,20},proc=Buttonkill_about,title="OK"
EndMacro

Function Buttonkill_about(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k About_Acquisition
End

// --------------------------------------------------------Initialization Routines ------------------------------------------------------
Proc Initialization()							//  Initialization common to all experiments
	Silent 1
	newdatafolder /o/s root:acquisition
	newdatafolder /o root:acquisition:menus
	newdatafolder /o root:acquisition:variables
	newdatafolder /o root:acquisition:data
	
// Common Variables
	Variable /G root:acquisition:variables:tickfreq = 58.83					//  Scaling factor for computer clock
	Variable /G root:acquisition:variables:Continuous = 0					// controls continuous input
	Variable /G root:acquisition:variables:sweep_number = 0				// current sweep	
	Variable /G root:acquisition:variables:stop_code = 1					// associated w/ start/stop button
	Variable /G root:acquisition:variables:sweep_time_0 = (ticks/tickfreq)	// time experiment begins
	Variable /G root:acquisition:variables:suspend_save = 0				// if on, saves once each 20 sweeps
	Variable /G root:acquisition:variables:master8 = 0						// allows igor to control master-8
	Variable /G root:acquisition:variables:WC_tab = 0						// which tab on input graph
	Variable /G root:acquisition:variables:zero_data = 1					// zeros data in stimulation experiments
	Variable /G root:acquisition:variables:tag_number = 0
// Calls user-defined variables
	User_Variables()			

// Creates waves
	Make /o /n=1 root:acquisition:ampl
	Make /o /n=1 root:acquisition:run_ampl
	Make /o /n=1 root:acquisition:ampl2
	Make /o /n=1 root:acquisition:inst_freq
	Make /o /n=1 root:acquisition:series_r
	Make /o /n=1 root:acquisition:input_r
	Make /o /n=1 root:acquisition:holding_i
	Make /o /n=1 root:acquisition:membrane_p
	Make /o /n=1 root:acquisition:temperature
	Make /o /n=1 root:acquisition:sweep_t
	Make /o /n=(root:acquisition:variables:sw_length0*root:acquisition:variables:kHz*1000) root:acquisition:input_0 = 0
	Setscale /p x, 0, 0.001/root:acquisition:variables:kHz, "s", root:acquisition:input_0
	Duplicate /o root:acquisition:input_0 root:acquisition:color_0

// Resets NIDAQ Board
	fDAQmx_ResetDevice(root:acquisition:variables:NIDAQ_dev)
	
// Removes all Panels and Graphs 
	DoWindow /k Resistance
	DoWindow /k WholeCell
	DoWindow /k Analysis
	DoWindow /k Reanalysis
	DoWindow /k Temperature_window
	DoWindow /k Holding
	DoWindow /k Frequency
	DoWindow /k Ih_analysis

//  Sets experiment name
	SaveExperiment 
	
// Create Windows	
	Resistance()
	Frequency()
	Analysis()
	Temperature_window()
	Holding()
	WholeCell()

// Displays initial analysis limits
	color_stim("",0,"","")

//  Opens Notebook
	DoWindow /f Experiment_log
	if (V_flag == 0)
		NewNotebook /f=0 /n=Experiment_Log  /W=(1340,40,1580,300)   
		Notebook Experiment_Log text = "Rig 2 \r\rDate:  \r\rCell:  \r\rInitial Resting Potential:  \rInitial Series Resistance:  \r"
	endif

// Changes menu items -- activates new menu choices
	Menu_initialized()
End

// --------------------------------------------------- Top Window Functions ----------------------------------------
Function topwinpath(infostr)  // this gives changes depending on which analysis window is selected
	String infostr
	if (stringmatch(infostr,"WINDOW:WholeCell;HCSPEC:WholeCell;EVENT:activate;MODIFIERS:*;"))
	endif
	if (stringmatch(infostr,"WINDOW:Analysis;HCSPEC:Analysis;EVENT:activate;MODIFIERS:*;"))
		color_stim("",0,"","")
	endif
	if (stringmatch(infostr,"WINDOW:Frequency;HCSPEC:Frequency;EVENT:activate;MODIFIERS:*;"))
		color_freq("",0,"","")
	endif
	if (stringmatch(infostr,"WINDOW:Resistance;HCSPEC:Resistance;EVENT:activate;MODIFIERS:*;"))
		color_res("",0,"","")
	endif
end

Function color_stim(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Wave color_0 = root:acquisition:color_0
	NVar ampl_1_on = root:acquisition:variables:ampl_1_on
	NVar ampl_2_on = root:acquisition:variables:ampl_2_on
	NVar ampl_1_peak = root:acquisition:variables:ampl_1_peak
	NVar ampl_1_zero = root:acquisition:variables:ampl_1_zero
	NVar ampl_2_peak = root:acquisition:variables:ampl_2_peak
	NVar ampl_2_zero = root:acquisition:variables:ampl_2_zero
	color_0 = 0
		if (ampl_1_on)
			color_0[x2pnt(color_0,ampl_1_zero-.001),x2pnt(color_0,ampl_1_zero+.001)]=2000	
			color_0[x2pnt(color_0,ampl_1_peak-.001),x2pnt(color_0,ampl_1_peak+.001)]=2000
		endif	
		if (ampl_2_on)
			color_0[x2pnt(color_0,ampl_2_zero-.001),x2pnt(color_0,ampl_2_zero+.001)]=2000
			color_0[x2pnt(color_0,ampl_2_peak-.001),x2pnt(color_0,ampl_2_peak+.001)]=2000
		endif
end

Function color_res(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Wave color_0 = root:acquisition:color_0
	NVar series_left = root:acquisition:variables:series_left
	NVar series_right = root:acquisition:variables:series_right
	NVar input_left = root:acquisition:variables:input_left
	NVar input_right = root:acquisition:variables:input_right
	color_0 = 0
	color_0[x2pnt(color_0,series_left),x2pnt(color_0,series_right)]= 2000
	color_0[x2pnt(color_0,input_left),x2pnt(color_0,input_right)]= 2000
end

Function color_freq(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Wave color_0 = root:acquisition:color_0
	NVar freq_left = root:acquisition:variables:freq_left
	NVar freq_right = root:acquisition:variables:freq_right
	NVAr freq_thresh = root:acquisition:variables:freq_thresh
	color_0 = 0
	color_0[x2pnt(color_0,freq_left),x2pnt(color_0,freq_right)]= 1000+freq_thresh
end

// ----------------------------------------------------Data Collection ----------------------------------------------------

Function Resetdevice()
	SVar NIDAQ_dev = root:acquisition:variables:NIDAQ_dev
	 fDAQmx_ResetDevice(NIDAQ_dev)
end


Function  Start_Sweep ()
// Define Variables
	Wave input_0 = root:acquisition:input_0
	Wave PTG_ch0 = root:PTG:PTG_ch0
	NVar continuous = root:acquisition:variables:continuous
	NVar stop_code = root:acquisition:variables:stop_code
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar sweep_time_0 = root:acquisition:variables:sweep_time_0
	NVar user_gain_VC = root:acquisition:variables:user_gain_VC
	NVar user_gain_CC = root:acquisition:variables:user_gain_CC
	NVar voltage_clamp = root:acquisition:variables:voltage_clamp
	NVar tickfreq=root:acquisition:variables:tickfreq
	NVar isi = root:acquisition:variables:isi
	SVar NIDAQ_dev = root:acquisition:variables:NIDAQ_dev
	SVar NIDAQ_ctr = root:acquisition:variables:NIDAQ_ctr
	Variable GainMX	
// Start DAQ
	stop_code = 0	
// Sets gain of input wave
	if (voltage_clamp)
		GainMX = 1000 / user_gain_VC
	else
		GainMX = 1000 / user_gain_CC
	endif
	if (continuous)
		DAQmx_scan /DEV=NIDAQ_dev /BKG=1 /TRIG={NIDAQ_ctr} /EOSH="collect_continuous()" /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE, -10,10,"+num2str(GainMX)+",0;"
		//ADDED TRIGGERED WAVEFORM
		if (datafolderexists("root:PTG"))
			PTG_waveformgen()	
		endif
		if (sweep_number == 0)
			sweep_time_0 = (ticks/tickfreq)
		endif
		DAQmx_ctr_outputpulse /dev=NIDAQ_dev /npls=1  /sec={.01,.01} 0
	else
		DAQmx_scan /DEV=NIDAQ_dev /BKG=1 /TRIG={NIDAQ_ctr} /EOSH="collect_sweep()" /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE, -10,10,"+num2str(GainMX)+",0;"
		//ADDED TRIGGERED WAVEFORM
		if (datafolderexists("root:PTG"))
			PTG_waveformgen()	
		endif
		if (sweep_number == 0)
			sweep_time_0 = (ticks/tickfreq)
		endif
		DAQmx_ctr_outputpulse /dev=NIDAQ_dev /npls=0  /sec={.01,isi-.01} 0
	endif
end

Function Collect_Sweep ()		// This function is called by ScanAsyncStart when it has collected the data.
	Nvar sweep_time_0 = root:acquisition:variables:sweep_time_0
	Nvar channel_gain = root:acquisition:variables:channel_gain
	NVar tickfreq=root:acquisition:variables:tickfreq
	NVar user_gain_VC = root:acquisition:variables:user_gain_VC
	NVar user_gain_CC = root:acquisition:variables:user_gain_CC
	NVar voltage_clamp = root:acquisition:variables:voltage_clamp
	SVar NIDAQ_dev = root:acquisition:variables:NIDAQ_dev
	SVar NIDAQ_ctr = root:acquisition:variables:NIDAQ_ctr

	variable GainMX
// Calls analysis routine and restarts wave scan	
	Analyze_sweep ((ticks/tickfreq) - sweep_time_0,1)
	if (voltage_clamp)
		GainMX = 1000 / user_gain_VC
	else
		GainMX = 1000 / user_gain_CC
	endif
	DAQmx_scan /DEV=NIDAQ_dev /BKG=1 /TRIG={NIDAQ_ctr} /EOSH="collect_sweep()" /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE, -10,10,"+num2str(GainMX)+",0;"
	if (datafolderexists("root:PTG"))
		PTG_waveformgen()	
	endif
end

Function Collect_continuous()		// This function is called by ScanAsyncStart when it has collected the data.
	NVar channel_gain = root:acquisition:variables:channel_gain
	NVar tickfreq = root:acquisition:variables:tickfreq
	NVar sweep_time_0 = root:acquisition:variables:sweep_time_0
	NVar user_gain_VC = root:acquisition:variables:user_gain_VC
	NVar user_gain_CC = root:acquisition:variables:user_gain_CC
	NVar voltage_clamp = root:acquisition:variables:voltage_clamp
	SVar NIDAQ_dev = root:acquisition:variables:NIDAQ_dev
	SVar NIDAQ_ctr = root:acquisition:variables:NIDAQ_ctr
	Variable GainMX
	String endhook = "Collect_continuous()"
// Calls analysis routine and restarts wave scan	
	Analyze_sweep ((ticks/tickfreq) - sweep_time_0,1)
	if (voltage_clamp)
		GainMX = 1000 / user_gain_VC
	else
		GainMX = 1000 / user_gain_CC
	endif
	DAQmx_scan /DEV=NIDAQ_dev /BKG=1 /TRIG={NIDAQ_ctr} /EOSH="collect_continuous()" /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE, -10,10,"+num2str(GainMX)+",0;"
	//ADDED TRIGGERED WAVEFORM  --assumed we want this for continuous collect?
		if (datafolderexists("root:PTG"))
			PTG_waveformgen()	
		endif
	DAQmx_ctr_outputpulse /dev=NIDAQ_dev /npls=1  /sec={.01,.01} 0
End

Function Error_Sweep ()
// This function is called by ScanAsyncStart when it makes an error
	SVar fifthitem = root:acquisition:menus:fifthitem
	SVar sixthitem = root:acquisition:menus:sixthitem
	SVar seventhitem = root:acquisition:menus:seventhitem
	NVar stop_code = root:acquisition:variables:stop_code
	SVar NIDAQ_dev = root:acquisition:variables:NIDAQ_dev
	DoAlert 0, fDAQmx_ErrorString()
	fDAQmx_ResetDevice(NIDAQ_dev)
	DoWindow /f WholeCell
	Button start_btn title="Start"
	fifthitem = "Start Acquisition"
	sixthitem = "Single Sweep -- no Analysis"
	seventhitem = "Single Sweep -- Analyze and Save"
	print "TEST error hook"
	stop_code = 1
end

Function Analyze_sweep(sweep_time,doAn)			// Performs analysis on sweep
	Variable sweep_time
	Variable doAn
// Define Global Variables
	Wave input_0 = root:acquisition:input_0
	Wave sweep_t = root:acquisition:sweep_t
	NVar continuous = root:acquisition:variables:continuous
	NVar suspend_save = root:acquisition:variables:suspend_save
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar user_gain_VC = root:acquisition:variables:user_gain_VC
	NVar user_gain_CC = root:acquisition:variables:user_gain_CC
	NVar voltage_clamp = root:acquisition:variables:voltage_clamp
	NVar zero_data = root:acquisition:variables:zero_data
	NVar ampl_1_on = root:acquisition:variables:ampl_1_on
	NVar ampl_2_on = root:acquisition:variables:ampl_2_on
	NVar WC_tab = root:acquisition:variables:WC_tab
	NVar RS_on = root:acquisition:variables:RS_on
// Define Local Variables	   
	Variable baseline
	Variable W_avg
	String wave_name
// Sets gain of input wave
	if (doAn)
		sweep_number += 1
		redimension /n=(sweep_number+1) sweep_t
		sweep_t [sweep_number] = sweep_time / 60
		wave_name="sweep"+num2str(sweep_number)
		Note /k input_0
		Note input_0, num2str(sweep_time / 60)
		Duplicate /o input_0 root:acquisition:data:$wave_name
	// Calls Analysis functions based on if window is checked
		if (RS_on == 1)
			Analyze_RS()	// series resistance sweep
		endif
		Collect_temperature()
		if (WC_tab == 0)
			if (ampl_1_on)
				Analyze_Ampl ()
			endif
			if (ampl_2_on)
				Analyze_Ampl2 ()
				Analyze_PPF ()
			endif
		// Zeros input wave if box is checked
			if (zero_data)
		 		W_avg = mean(input_0,0,.01)
				input_0 -= W_avg                    
			endif
		else 		// WC_tab = 1
			Analyze_freq()
		endif	
	//  If suspend save is on, does not save
		if (!suspend_save)
			SaveExperiment
		endif
	endif
End

// -------------------------------------------------- Analysis Options --------------------------------------------------------

Function Analyze_Ampl ()
// Define Global Variables
	Wave input_0 = root:acquisition:input_0
	Wave ampl = root:acquisition:ampl
	Wave run_ampl = root:acquisition:run_ampl
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar ampl_1_peak = root:acquisition:variables:ampl_1_peak
	NVar ampl_1_zero = root:acquisition:variables:ampl_1_zero
// Analyze amplitude around cursor A	
	redimension /n=(sweep_number) ampl
	ampl [sweep_number] = mean(input_0,ampl_1_peak-.001,ampl_1_peak+.001)-mean(input_0,ampl_1_zero-.001,ampl_1_zero+.001)
	duplicate /o ampl run_ampl
	smooth /b/e=3  5, run_ampl
End	

Function Analyze_Ampl2 ()
// Define Global Variables
	Wave input_0 = root:acquisition:input_0
	Wave ampl2 = root:acquisition:ampl2
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar ampl_2_peak = root:acquisition:variables:ampl_2_peak
	NVar ampl_2_zero = root:acquisition:variables:ampl_2_zero
// Analyze amplitude around cursor B	
	redimension /n=(sweep_number) ampl2
	ampl2 [sweep_number] = mean(input_0,ampl_2_peak-.001,ampl_2_peak+.001)-mean(input_0,ampl_2_zero-.001,	ampl_2_zero+.001)
End	    

Function Analyze_Slope ()
	Wave input_0 = root:acquisition:input_0
	Wave slope = root:acquisition:slope
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar Slope_Start = root:acquisition:variables:ampl_1_zero
	NVar Slope_End = root:acquisition:variables:ampl_1_peak
	make /o /n=2 W_coef = 0
// Analyze slope
	redimension /n=(sweep_number) slope
	Curvefit /Q line, input_0 (Slope_Start,Slope_End) /D
	slope [sweep_number] = W_Coef [1]
End	

Function Analyze_freq() 				//Calculate the frequency within each sweep
	Wave input_0 = root:acquisition:input_0
	Wave inst_freq = root:acquisition:inst_freq
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar freq_left = root:acquisition:variables:freq_left
	NVar freq_right = root:acquisition:variables:freq_right
	NVar freq_thresh = root:acquisition:variables:freq_thresh
	NVar sampling_rate = root:acquisition:variables:kHz	
	variable i=freq_left*5000										
	variable thresholdcount=0
	do
		if (input_0[i]<=freq_thresh && freq_thresh<input_0[i+1])
			thresholdcount=thresholdcount+1
		endif
		i=i+1
	while (i<freq_right*sampling_rate*1000)		
	redimension /n=(sweep_number) inst_freq
	Inst_freq[sweep_number]=thresholdcount/(freq_right-freq_left)
end	

Function Analyze_PPF () 		// Analyze Paired Pulse
// Define Global Variables
	Wave Ampl = root:acquisition:ampl
	Wave Ampl2 = root:acquisition:ampl2
	Duplicate /o Ampl PPF
	PPF = Ampl2 / Ampl
	smooth 4, ppf
End

Function Collect_temperature()		// Collect single point for temperature off of ACH2
	Wave temperature = root:acquisition:temperature
	NVar sweep_number = root:acquisition:variables:sweep_number
	SVar NIDAQ_dev = root:acquisition:variables:NIDAQ_dev
	redimension /n=(sweep_number) temperature
	temperature [sweep_number] =  fDAQmx_ReadChan(NIDAQ_dev, 2, 0,10,1)*10	
End	

Function Analyze_RS()
// Define Global Variables
	Wave input_0 = root:acquisition:input_0
	Wave series_r = root:acquisition:series_r
	Wave input_r = root:acquisition:input_r
	Wave holding_i = root:acquisition:holding_i
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar stepsize =  root:acquisition:variables:stepsize
	NVar series_left = root:acquisition:variables:series_left
	NVar series_right = root:acquisition:variables:series_right
	NVar input_left = root:acquisition:variables:input_left
	NVar input_right = root:acquisition:variables:input_right
	NVar voltage_clamp = root:acquisition:variables:voltage_clamp

	redimension /n=(sweep_number) input_r	
	redimension /n=(sweep_number) series_r
	redimension /n=(sweep_number) holding_i
// Analyze holding current
	holding_i [sweep_number] = mean(input_0,0.001,0.005)	

	If (voltage_clamp)
	// Analyze series resistance
		Wavestats /Q /R =(series_left,series_right) input_0 
		series_r [sweep_number] =  (1000*stepsize) / (V_max - V_min)
	// Analyze input resistance
		input_r [sweep_number] = abs((1000*stepsize) / (mean(input_0,input_left,input_right)-mean(input_0,0,0.005)))
	else
	// Analyze input resistance
		input_r [sweep_number] =  100*abs((mean(input_0,input_left,input_right)-mean(input_0,0,0.005)) / stepsize)
	endif
End	






// --------------------------------------------------Single Sweep Macro -----------------------------------------------------------------
Proc Single_Sweep (doAnalysis)
	Variable doAnalysis
// This takes a single sweep
	String endhook
	Variable GainMX
	if (doAnalysis)
		endhook = "Collect_single(1)"
	else
		endhook = "Collect_single(0)"
	endif
	if (root:acquisition:variables:voltage_clamp)
		GainMX = 1000 / root:acquisition:variables:user_gain_VC
	else
		GainMX = 1000 / root:acquisition:variables:user_gain_CC
	endif
// Start DAQ	
	DAQmx_scan /DEV=root:acquisition:variables:NIDAQ_dev /BKG=1 /TRIG={root:acquisition:variables:NIDAQ_ctr} /EOSH=endhook /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE, -10,10,"+num2str(GainMX)+",0;"
//  ADDED WAVEFORM GENERATOR
//	if (root:acquisition:variables:command_out)
//		DAQmx_waveformgen /dev=root:acquisition:variables:NIDAQ_dev  /ERRH="error_sweep()" /trig={root:acquisition:variables:NIDAQ_ctr} /nprd=1 "root:acquisition:stepfunction, 0;" 
//	endif
	DAQmx_ctr_outputpulse /dev=root:acquisition:variables:NIDAQ_dev /npls=1  /sec={.01,.01} 0
End

Function Collect_single(doAnalysis)
	variable doAnalysis
	NVar sweep_time_0 = root:acquisition:variables:sweep_time_0
	NVar tickfreq=root:acquisition:variables:tickfreq
	Analyze_sweep ((ticks/tickfreq) - sweep_time_0,doAnalysis)
End




//--------------------------------------------------------Buttons--------------------------------------------------------------------------------
Function Start_Acquisition(ctrlName) : ButtonControl  	//This is the Start/Stop button
	String ctrlName
	NVar stop_code= root:acquisition:variables:stop_code
	SVar fifthitem = root:acquisition:menus:fifthitem
	SVar sixthitem = root:acquisition:menus:sixthitem
	SVar seventhitem = root:acquisition:menus:seventhitem
	DoWindow /f WholeCell
	if (stop_code == 1)
		Button start_btn title="Stop"
		fifthitem = "Stop Acquisition"
		sixthitem = "(Single Sweep -- no Analysis"
		seventhitem = "(Single Sweep -- Analyze and Save"
		Start_Sweep ()
	else	
		Stop_Acquisition("")
	endif
End

Function Stop_Acquisition(ctrlName)	//This stops data acquisition
	String ctrlName
	NVar stop_code= root:acquisition:variables:stop_code
	SVar fifthitem = root:acquisition:menus:fifthitem
	SVar sixthitem = root:acquisition:menus:sixthitem
	SVar seventhitem = root:acquisition:menus:seventhitem	
	SVar NIDAQ_dev = root:acquisition:variables:NIDAQ_dev
	DoWindow /f WholeCell
	fDAQmx_CTR_Finished(NIDAQ_dev, 0)
	fDAQmx_ScanStop (NIDAQ_dev)
	fDAQmx_waveformstop(NIDAQ_dev)
	Button start_btn title="Start"
	fifthitem = "Start Acquisition"
	sixthitem = "Single Sweep -- no Analysis"
	seventhitem = "Single Sweep -- Analyze and Save"
	stop_code = 1
	SaveExperiment
end


Function ButtonProc(ctrlName) : ButtonControl			// This is the set ISI now button
	String ctrlName
	NVar stop_code = root:acquisition:variables:stop_code
	NVar isi = root:acquisition:variables:isi
	SVar NIDAQ_dev = root:acquisition:variables:NIDAQ_dev
	if (stop_code == 0)
		DAQmx_ctr_outputpulse /dev=NIDAQ_dev /npls=0  /sec={.01,isi-.01} 0
	endif
End

Function ButtonProc_1(ctrlName) : ButtonControl			// This is the reset button
	String ctrlName 
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar sweep_time_0 = root:acquisition:variables:sweep_time_0
	NVar tickfreq=root:acquisition:variables:tickfreq
	Wave sweep_t = root:acquisition:sweep_t
	sweep_number = 0
	sweep_time_0 = (ticks/tickfreq)
	Redimension /n=(sweep_number) sweep_t
End

Function Check_VC(ctrlName,checked) : CheckBoxControl		// This switches between VC and CC
	String ctrlName
	Variable checked
	NVar voltage_clamp = root:acquisition:variables:voltage_clamp
	voltage_clamp = checked
	if (checked)
		label /W=Analysis left "pA"
		label /W=Holding left "holding current (pA)"
		label /W=WholeCell left "pA"
	else 
		label /W=Analysis left "mV"
		label /W=Holding  left "V\\Bm\\M (mV)"
		label  /W=WholeCell left "mV"
	endif
End

Proc Set_User(gain)	
variable gain = $(stringfromlist(((root:acquisition:variables:WC_tab<2)*!root:acquisition:variables:voltage_clamp),"root:acquisition:variables:user_gain_VC;root:acquisition:variables:user_gain_CC;"))
	prompt gain, "Enter user gain for "+stringfromlist(((root:acquisition:variables:WC_tab<2)*!root:acquisition:variables:voltage_clamp),"voltage clamp (mV/pA):;current clamp (mV/mV):;")
	if (root:acquisition:variables:voltage_clamp)
		root:acquisition:variables:user_gain_VC = gain
	else
		root:acquisition:variables:user_gain_CC = gain
	endif
end

Proc Set_Channel(gain)
	string gain = num2str(root:acquisition:variables:channel_gain)
	prompt gain "Enter Channel Gain",popup,"0.5;1;5;10;50;100"
	root:acquisition:variables:channel_gain = str2num(gain)
End

Function SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl  //Changes sweep length
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVar sw_length2 = root:acquisition:variables:sw_length2
	NVar kHz = root:acquisition:variables:kHz
	Wave input_0 = root:acquisition:input_0
	Wave color_0 = root:acquisition:color_0
	Redimension /N = (varNum*khz*1000) input_0, color_0
	if (!cmpstr(varName,"sw_length2"))
		color_0 = 0
		color_0[500*sw_length2,1000*sw_length2]=2000
		color_0[3200*sw_length2,3800*sw_length2] = 2000
	endif
End

Function CheckProc_color(ctrlName,checked) : CheckBoxControl  //adds color when ampl1 or 2 is checked
	String ctrlName
	Variable checked
	color_stim("",0,"","")
End

Function reset_A1() : GraphMarquee      				//This is the Set A1 button
	NVar ampl_1_peak = root:acquisition:variables:ampl_1_peak
	NVar ampl_1_zero = root:acquisition:variables:ampl_1_zero
	getmarquee /k bottom
	if (stringmatch(S_marqueeWin,"WholeCell"))
		ampl_1_zero = v_left
		ampl_1_peak = v_right
		color_stim("",0,"","")
	endif
End

Function reset_A2() : GraphMarquee    					//This is the Set A2 button
	NVar ampl_2_peak = root:acquisition:variables:ampl_2_peak
	NVar ampl_2_zero = root:acquisition:variables:ampl_2_zero
	getmarquee /k bottom
	if (stringmatch(S_marqueeWin,"WholeCell"))
		ampl_2_zero = v_left
		ampl_2_peak = v_right
		color_stim("",0,"","")
	endif
End

Function reset_Rs() : GraphMarquee    					//This is the Set Rs button    
	NVar series_left = root:acquisition:variables:series_left
	NVar series_right = root:acquisition:variables:series_right
	getmarquee /k bottom
	if (stringmatch(S_marqueeWin,"WholeCell"))
		series_left = v_left
		series_right = v_right
		color_res("",0,"","")
	endif
End

Function reset_Ri() : GraphMarquee    					//This is the Set Ri button      
	NVar input_left = root:acquisition:variables:input_left
	NVar input_right =root:acquisition:variables:input_right
	getmarquee /k bottom
	if (stringmatch(S_marqueeWin,"WholeCell"))
		input_left = v_left
		input_right = v_right
		color_res("",0,"","")
	endif
End
//----------------------------------------------------------Suspend Save -------------------------------------------------------------------------

Function Susp_save(checked)
	variable checked
	NVar s_save = root:acquisition:variables:suspend_save
	SVar eighthitem = root:acquisition:menus:eighthitem
	If (checked != 0 && s_save == 0)
		s_save = 1
		eighthitem = "!"+num2char(18)+"Suspend Save each Sweep"
	elseif (checked != 1 && s_save == 1)
		s_save = 0
		eighthitem = "Suspend Save each Sweep"
	endif
end

Function CheckProc_CS(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	susp_save(checked)
End



//--------------------------------------------------------------IV functions--------------------------------------------------------------------------------

//  These procedures are for making input-output curves.  You must have  DAC0OUT connected to the External 
//  Command  and the External Command Sensitivity set to 20 mV/V.

Proc Start_Ramp(ctrlName) : ButtonControl
	String ctrlName
	Make /o/n=1000 root:acquisition:ramp = 0
	SetScale/I x 0,root:acquisition:variables:sw_length3,"s", root:acquisition:ramp
	ramp_voltage = (p/2.5) -65
//  The next line sets the default holding potential -- can be interactively changed
//	ramp[150,900] = (-40 - root:acquisition:variables:starting_v_ih) / 20
//	ramp[400,900] -= (p-400)/100
	ramp[100,900] = (p-100)/400
	

//  Input data
	DAQmx_waveformgen /dev=root:acquisition:variables:NIDAQ_dev /ERRH="error_sweep()" /nprd=1 "root:acquisition:ramp, 0;"
	DAQmx_scan /DEV=root:acquisition:variables:NIDAQ_dev /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE;"
	root:acquisition:input_0 *= 1000 / root:acquisition:variables:user_gain_VC
	ramp_input = root:acquisition:input_0
//	ramp_current = ramp_input[root:acquisition:variables:sw_length3*(4500-25*p)]
	ramp_current = ramp_input[p*8+100]
end	

Proc Start_IH(ctrlName) : ButtonControl   //THIS HAS BEEN MODIFIED TO GIVE DEPOLARIZING STEPS IN CC FOR NAc
	String ctrlName
	Variable step_number=0
	Variable delay_ticks=0
	if (root:acquisition:variables:Ih_test == 1)
		Make /o/n=10 root:acquisition:step_ih =0		
		SetScale/I x 0,root:acquisition:variables:sw_length2,"s", root:acquisition:step_ih
		Make /o/n = 8 root:acquisition:voltage_ih, root:acquisition:current_ih
		root:acquisition:current_ih = 0
		root:acquisition:voltage_ih={-200,-100,0,100,200,300,400,500,600}
		Do
			step_ih[2,6] = (root:acquisition:voltage_ih[step_number]) / 4000
			DAQmx_waveformgen /dev=root:acquisition:variables:NIDAQ_dev /ERRH="error_sweep()" /nprd=1 "root:acquisition:step_ih, 0;"
			DAQmx_scan /DEV=root:acquisition:variables:NIDAQ_dev /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE;"
	//	root:acquisition:input_0 *= 1000 / root:acquisition:variables:user_gain_VC
			duplicate /o root:acquisition:input_0 $"ih_"+num2str(step_number)
			root:acquisition:current_ih[step_number] = measure_ih()
			delay_ticks = ticks
			if (step_number == 0)
				DoWindow  /k Ih_analysis
				Ih_analysis()
			else		
				Appendtograph /W=Ih_analysis $"ih_"+num2str(step_number)
			endif
			do
			while(ticks<delay_ticks+(4*root:acquisition:variables:tickfreq)) 	//2 second delay between steps
			step_number += 1
		While (step_number < 9)
	Else
	
		Make /o/n=10 root:acquisition:step_ih =0		
		SetScale/I x 0,root:acquisition:variables:sw_length2,"s", root:acquisition:step_ih
		Make /o/n = 8 root:acquisition:voltage_ih, root:acquisition:current_ih
		root:acquisition:current_ih = 0
		root:acquisition:voltage_ih={-40, -50, -70, -80, -90, -100, -110, -120}
		Do
			step_ih[2,6] = (root:acquisition:voltage_ih[step_number] - root:acquisition:variables:starting_v_ih) / 20
			DAQmx_waveformgen /dev=root:acquisition:variables:NIDAQ_dev /ERRH="error_sweep()" /nprd=1 "root:acquisition:step_ih, 0;"
			DAQmx_scan /DEV=root:acquisition:variables:NIDAQ_dev /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE;"
			root:acquisition:input_0 *= 1000 / root:acquisition:variables:user_gain_VC
			duplicate /o root:acquisition:input_0 $"ih_"+num2str(step_number)
			root:acquisition:current_ih[step_number] = measure_ih()
			delay_ticks = ticks
			if (step_number == 0)
				DoWindow  /k Ih_analysis
				Ih_analysis()
			else		
				Appendtograph /W=Ih_analysis $"ih_"+num2str(step_number)
			endif
			do
			while(ticks<delay_ticks+(2*root:acquisition:variables:tickfreq)) 	//2 second delay between steps
			step_number += 1
		While (step_number < 8)
	Endif
END

Proc single_ih(ctrlName) : ButtonControl
	string ctrlName
	variable step_number=0
	DoWindow  /f Ih_analysis
	if (V_flag == 0)
		Make /o/n = 8 voltage_ih, current_ih
		Duplicate /o root:acquisition:input_0 ih_0
		Ih_analysis()
	endif	
	Make /o/n=10 step_ih	= 0
	SetScale/I x 0,root:acquisition:variables:sw_length2,"s", step_ih
	step_ih[2,6] = (root:acquisition:variables:step_v_ih - root:acquisition:variables:starting_v_ih) / 20
	DAQmx_waveformgen /dev=root:acquisition:variables:NIDAQ_dev /ERRH="error_sweep()" /nprd=1 "root:acquisition:step_ih, 0;"
	DAQmx_scan /DEV=root:acquisition:variables:NIDAQ_dev /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE;"
	root:acquisition:input_0 *= 1000 / root:acquisition:variables:user_gain_VC
	do
		step_number+=1
	while (waveexists($"ih_s"+num2str(step_number)))
	duplicate root:acquisition:input_0 $"ih_s"+num2str(step_number)
	Appendtograph  /W=Ih_analysis /C=(0,0,65280) $"ih_s"+num2str(step_number)
end

Function measure_ih()
Variable Measure
NVar IH_meas = root:acquisition:variables:IH_meas
NVar sw_length2 = root:acquisition:variables:sw_length2
Wave input_0 = root:acquisition:input_0

switch(IH_meas)							// numeric switch
	case 0:
		measure = mean(input_0, sw_length2*.3,sw_length2*.4) - mean(input_0, sw_length2*.1,sw_length2*.2)
		break
	case 1:
		measure	 = mean(input_0, sw_length2*.64,sw_length2*.76) - mean(input_0, sw_length2*.1,sw_length2*.2)
		break
	case 2:
		measure = mean(input_0, sw_length2*.64,sw_length2*.76) - mean(input_0, sw_length2*.3,sw_length2*.4)
		break
endswitch
Return measure
End


Function save_close_ramp(ctrlName) : ButtonControl
	string ctrlName
	string newName
	prompt newName, "Prefix for waves:"
	DoPrompt "Copy data to: ", newName
	Wave ramp_input = ramp_input
	Wave ramp_current = ramp_current
	Wave ramp_voltage = ramp_voltage
	nvar sweep_time_0 = root:acquisition:variables:sweep_time_0
	nvar tickfreq= root:acquisition:variables:tickfreq
	duplicate /o ramp_input  $(newName+"_input")
	Note $(newName+"_input"), num2str(((ticks/tickfreq)-sweep_time_0)/60)
	duplicate /o ramp_current $(newName+"_rampi")
	duplicate /o ramp_voltage $(newName+"_rampv")
End

Function save_close_ih(ctrlName) : ButtonControl
	string ctrlName
	string newName
	prompt newName, "Prefix for waves:"
	DoPrompt "Copy data to: ", newName
	variable step_number=0
	do
		duplicate /o $("ih_"+num2str(step_number)) $(newName+"_ih"+num2str(step_number))
		step_number+=1
	while (waveexists($ "ih_"+num2str(step_number)))
	step_number = 1
	if (waveexists(ih_s1))
		do
			duplicate /o $("ih_s"+num2str(step_number))$(newName+"_ihs"+num2str(step_number))
			step_number+=1
		while (waveexists($ "ih_s"+num2str(step_number)))
	endif
	duplicate /o current_ih $(newName+"_iih")
	duplicate /o voltage_ih $(newName+"_vih")
End

Function clear_ramp(ctrlName) : ButtonControl
	string ctrlName
	Wave current = root:acquisition:ramp_current
	Wave input = root:acquisition:ramp_input
	current = 0
	input = 0
End

Function clear_ih(ctrlName) : ButtonControl
	string ctrlName
	Wave current_ih = root:acquisition:current_ih
	Wave ih_0 = root:acquisition:ih_0
	variable step_number=1
	do
		removefromgraph /w=ih_analysis /z $("ih_"+num2str(step_number))
		killwaves /z $("ih_"+num2str(step_number))
		step_number+=1
	while (waveexists($ "ih_"+num2str(step_number)))
	step_number = 1
	do
		removefromgraph /w=ih_analysis /z $("ih_s"+num2str(step_number))
		killwaves /z $("ih_s"+num2str(step_number))
			step_number+=1
	while (waveexists($ "ih_s"+num2str(step_number)))
	current_ih = 0
	ih_0 = 0
End

Function RadioButtonProc(name,value)
	String name
	Variable value
	Wave color_0 = root:acquisition:color_0
	NVar sw_length2 = root:acquisition:variables:sw_length2
	NVar gRadioVal= root:acquisition:variables:IH_meas
	NVar kHz = root:acquisition:variables:kHz
	color_0 = 0
	strswitch (name)
		case "check0":
			gRadioVal= 0
			color_0[100*kHz*sw_length2,200*kHz*sw_length2]=2000
			color_0[300*kHz*sw_length2,400*kHz*sw_length2] = 2000
			break
		case "check1":
			gRadioVal= 1
			color_0[100*kHz*sw_length2,200*kHz*sw_length2]=2000
			color_0[640*kHz*sw_length2,760*kHz*sw_length2] = 2000
			break
		case "check2":
			gRadioVal= 2
			color_0[300*kHz*sw_length2,400*kHz*sw_length2]=2000
			color_0[640*kHz*sw_length2,760*kHz*sw_length2] = 2000
			break
	endswitch
	CheckBox check0,value= gRadioVal==0
	CheckBox check1,value= gRadioVal==1
	CheckBox check2,value= gRadioVal==2
End

//----------------------------------------------------------Windows -------------------------------------------------------------------------
Window WholeCell() : Graph
	PauseUpdate; Silent 1		// building window...
	//NVar sweep_number = root:acquisition:variables:sweep_number
	Display /W=(10,40,520,490) root:acquisition:color_0, root:acquisition:input_0
	ModifyGraph mode(color_0)=7
	ModifyGraph marker(input_0)=3
	ModifyGraph rgb(color_0)=(60928,60928,60928)
	ModifyGraph hbFill(color_0)=4
	ModifyGraph rgb(color_0)=(34816,34816,34816)
	ModifyGraph offset(color_0)={0,-1000}
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph standoff(bottom)=0
	ModifyGraph axOffset(bottom)=0.625
	ModifyGraph axisEnab(left)={0,0.9}
	Label left "pA"
	SetAxis left -200,100
	TextBox/N=time_stamp/F=0/X=0.90/Y=-4.2 "\\{root:acquisition:variables:sweep_number}  -- \\{secs2time(60*root:acquisition:sweep_t[root:acquisition:variables:sweep_number],3)}"
	//TextBox/N=time_stamp/F=0/X=0.90/Y=-4.2 "\\{root:acquisition:variables:sweep_number}  -- \\{secs2time(60*root:acquisition:sweep_t[sweep_number],3)}"
	ControlBar 100
	CheckBox ampl_1_check,pos={280,60},size={86,14},title="First Amplitude"
	CheckBox ampl_1_check,variable= root:acquisition:variables:ampl_1_on, proc=CheckProc_color
	CheckBox ampl_2_check,pos={280,75},size={104,14},title="Second Amplitude"
	CheckBox ampl_2_check,variable= root:acquisition:variables:ampl_2_on, proc=CheckProc_color
	CheckBox Zero_data,pos={170,75},size={93,14},title="Zero input trace"
	CheckBox Zero_data,variable= root:acquisition:variables:zero_data
	CheckBox VC_check,pos={170,60},size={86,14},proc=Check_VC,title="Voltage Clamp"
	CheckBox VC_check,variable=root:acquisition:variables:voltage_clamp
	Button Start_btn,pos={20,70},size={80,25},proc=Start_Acquisition,title="Start"
	Button reset_btn,pos={100,70},size={35,25},proc=ButtonProc_1,title="Reset"
	Button StartIH_btn,pos={20,60},size={80,35},proc=Start_IH,title="Start Ih", disable = 1
	Button SingleIH_btn,pos={100,60},size={55,35},proc=Single_IH,title="Single Ih", disable = 1
	Button StartRamp_btn,pos={20,60},size={80,35},proc=Start_ramp,title="Start Ramp", disable = 1
	SetVariable isi_set,pos={205,28},size={140,16},title="Sweep interval (s)"
	SetVariable isi_set,limits={0,inf,1},value= root:acquisition:variables:isi
	Button isi_setnow,pos={349,26},size={30,20},proc=ButtonProc,title="Set"
	TabControl tab0,pos={10,2},size={600,20},proc=TabProc,tabLabel(0)="Stimulation "
	TabControl tab0,tabLabel(1)="Firing rate",tabLabel(2)="Ih test"
	TabControl tab0,tabLabel(3)="IV ramp",value= 0
	CheckBox check0,pos={24,50},size={105,14},title="Collect continuous"
	CheckBox check0,variable= root:acquisition:variables:Continuous, proc=CheckProc_CS
	SetVariable length0,pos={25,28},size={150,16},proc=SetVarProc,title="Sweep length (s)"
	SetVariable length0,value= root:acquisition:variables:sw_length0,  limits={0,20,.1}
	SetVariable length1,pos={25,28},size={150,16},proc=SetVarProc,title="Sweep length (s)"
	SetVariable length1,value= root:acquisition:variables:sw_length1,  limits={0,20,.1}, disable = 1
	SetVariable length2,pos={25,28},size={150,16},proc=SetVarProc,title="Sweep length (s)"
	SetVariable length2,value= root:acquisition:variables:sw_length2,  limits={0,20,.1}, disable = 1
	SetVariable length3,pos={25,28},size={150,16},proc=SetVarProc,title="Sweep length (s)"
	SetVariable length3,value= root:acquisition:variables:sw_length3,  limits={0,20,.1}, disable = 1
	SetVariable setvar0_ih,pos={250,28},size={140,18},title="Starting Vm"
	SetVariable setvar0_ih,limits={-100,40,5},value=root:acquisition:variables:starting_v_ih, disable = 1
	SetVariable stepval_ih,pos={250,60},size={140,18},title="Step Vm for single"
	SetVariable stepval_ih,limits={-200,80,10},value=root:acquisition:variables:step_v_ih, disable = 1
	SetWindow kwTopWin,hook=topwinpath
EndMacro

Function TabProc(ctrlName,tabNum) : TabControl
	String ctrlName
	Variable tabNum
	Wave input_0 = root:acquisition:input_0
	Wave color_0 = root:acquisition:color_0
	NVar WC_tab = root:acquisition:variables:WC_tab
	NVar continuous = root:acquisition:variables:continuous
	NVar continuous0 = root:acquisition:variables:continuous0
	NVar continuous1 = root:acquisition:variables:continuous1
	NVAr sw_length0 = root:acquisition:variables:sw_length0
	NVar sw_length1 = root:acquisition:variables:sw_length1
	NVar sw_length2 = root:acquisition:variables:sw_length2
	NVar sw_length3 = root:acquisition:variables:sw_length3
	NVar kHz = root:acquisition:variables:kHz
	NVar IH_meas = root:acquisition:variables:IH_meas
	SVar fifthitem = root:acquisition:menus:fifthitem
	SVar sixthitem = root:acquisition:menus:sixthitem
	SVar seventhitem = root:acquisition:menus:seventhitem
	WC_tab = tabNum
	CheckBox ampl_1_check, disable = (tabnum !=0)
	CheckBox ampl_2_check, disable = (tabnum !=0)
	CheckBox zero_data, disable = (tabnum !=0)
	CheckBox VC_check disable = (tabnum > 1)
	SetVariable isi_set, disable = (tabnum > 1)
	Button isi_setnow, disable = (tabnum > 1)
	SetVariable length0, disable = (tabnum !=0)
	SetVariable length1, disable = (tabnum !=1)
	SetVariable length2, disable = (tabnum !=2)
	SetVariable length3, disable = (tabnum !=3)
	SetVariable setvar0_ih, disable = (tabnum <2)
	SetVariable stepval_ih, disable = (tabnum !=2)
	CheckBox check0, disable = (tabnum > 1)
	Button Start_btn, disable = (tabnum > 1)
	Button Reset_btn, disable = (tabnum > 1)
	Button StartIH_btn, disable = (tabnum !=2)
	Button SingleIH_btn, disable = (tabnum !=2)
	Button StartRamp_btn, disable = (tabnum !=3)
	input_0 = 0
	color_0 = 0
	if (tabnum == 0)
		Check_VC("",1)
		Continuous = continuous0
		Susp_save(continuous0)
		Redimension /N = (sw_length0*kHz*1000), input_0, color_0
		DoWindow /f Analysis 
		DoWindow /b Ih_analysis
		Stop_Acquisition("")
	endif
	if (tabnum == 1)
		Check_VC("",0)
		Continuous = continuous1
		Susp_save(continuous1)
		Redimension /N =  (sw_length1*kHz*1000), input_0, color_0
		DoWindow /f 	Frequency
		DoWindow /b Ih_analysis
		Stop_Acquisition("")
	endif
	if (tabnum == 2)
		Redimension /N =  (sw_length2*kHz*1000), input_0, color_0
		switch(IH_meas)							// numeric switch
			case 0:
				color_0[100*kHz*sw_length2,200*kHz*sw_length2]=2000
				color_0[300*kHz*sw_length2,400*kHz*sw_length2] = 2000
			break
			case 1:
				color_0[100*kHz*sw_length2,200*kHz*sw_length2]=2000
				color_0[640*kHz*sw_length2,760*kHz*sw_length2] = 2000
			break
			case 2:
				color_0[300*kHz*sw_length2,400*kHz*sw_length2]=2000
				color_0[640*kHz*sw_length2,760*kHz*sw_length2] = 2000
			break
		endswitch
		Stop_Acquisition("")
		label /W=WholeCell left "pA"
		SetAxis /A bottom
		DoWindow /f Ih_analysis
		if (V_flag == 0)
			Make /o/n = 8 voltage_ih, current_ih
			Duplicate /o root:acquisition:input_0 ih_0
			Execute "Ih_analysis()"
		endif
		fifthitem = "(Start Acquisition"
		sixthitem = "(Single Sweep -- no Analysis"
		seventhitem = "(Single Sweep -- Analyze and Save"
	endif
	if (tabnum == 3)
		Stop_Acquisition("")
		Redimension /N =  (sw_length3*kHz*1000), input_0, color_0
		DoWindow /f IV_ramp
		if (V_flag == 0)
			Make /o/n=100 ramp_voltage, ramp_current
			Duplicate /o root:acquisition:input_0 ramp_input
			Execute "IV_ramp()"
		endif
		fifthitem = "(Start Acquisition"
		sixthitem = "(Single Sweep -- no Analysis"
		seventhitem = "(Single Sweep -- Analyze and Save"
	endif
End

Window Analysis() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(530,40,1330,300) root:acquisition:ampl vs root:acquisition:sweep_t
	AppendToGraph root:acquisition:ampl2 vs root:acquisition:sweep_t
	AppendToGraph root:acquisition:run_ampl vs root:acquisition:sweep_t
	ModifyGraph mode(ampl)=3,mode(ampl2)=3
	ModifyGraph marker(ampl)=18,marker(ampl2)=8
	ModifyGraph rgb(ampl2)=(0,0,0),rgb(run_ampl)=(0,0,0)
	Label left "pA"
	Label bottom "Time (min)"
	SetAxis bottom 0,30
	SetAxis/A/E=1 left
	ControlBar 50
	SetVariable setvar0,pos={10,5},size={150,16},title="1st Ampl baseline:"
	SetVariable setvar0,value= root:acquisition:variables:ampl_1_zero, limits={0,10,.001}, proc=Color_stim
	SetVariable setvar1,pos={164,5},size={100,16},title="peak:"
	SetVariable setvar1,value= root:acquisition:variables:ampl_1_peak, limits={0,10,.001}, proc=color_stim
	SetVariable setvar2,pos={272,5},size={150,16},title="2nd Ampl baseline:"
	SetVariable setvar2,value= root:acquisition:variables:ampl_2_zero, limits={0,10,.001}, proc=color_stim
	SetVariable setvar3,pos={426,5},size={100,16},title="peak:"
	SetVariable setvar3,value= root:acquisition:variables:ampl_2_peak, limits={0,10,.001}, proc=color_stim
	CheckBox check0, pos={50,30},size={217,14},title="Analyze slope", value = 0, disable=2
	CheckBox check1, pos={180,30}, title="Analyze spontaneous events", disable=2 
	Button button_ampl title="Add tag",size={100,20}, pos={380,25}, proc=Add_tag
	SetWindow kwTopWin,hook=topwinpath
EndMacro

Window Resistance() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(530,540,1330,730) root:acquisition:series_r vs root:acquisition:sweep_t 
	AppendToGraph/L=in_l root:acquisition:input_r vs root:acquisition:sweep_t
	ModifyGraph mode(series_r)=3
	ModifyGraph marker(series_r)=18
	ModifyGraph lblPos(left)=45,lblPos(in_l)=45
	ModifyGraph freePos(in_l)={0,bottom}
	ModifyGraph axisEnab(left)={0,0.45}
	ModifyGraph axisEnab(in_l)={0.55,1}
	Label left "Series (Mohm)"
	Label in_l "Input (Mohm)"
	SetAxis left 0,80
	SetAxis bottom 0,30
	SetAxis in_l 0,500
	ControlBar 32
	SetVariable setvar0,pos={10,5},size={150,16},title="Rs start:"
	SetVariable setvar0,value= root:acquisition:variables:series_left, limits={0,10,.001}, proc=color_res
	SetVariable setvar1,pos={164,5},size={100,16},title="end:"
	SetVariable setvar1,value= root:acquisition:variables:series_right, limits={0,10,.001}, proc=color_res
	SetVariable setvar2,pos={272,5},size={150,16},title="Input start:"
	SetVariable setvar2,value= root:acquisition:variables:input_left, limits={0,10,.001}, proc=color_res
	SetVariable setvar3,pos={426,5},size={100,16},title="end:"
	SetVariable setvar3,value= root:acquisition:variables:input_right, limits={0,10,.001}, proc=color_res
	setwindow Resistance, hook=topwinpath



Window Frequency() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(530,40,1330,300) root:acquisition:inst_freq vs root:acquisition:sweep_t
	ModifyGraph mode=3
	ModifyGraph marker=8
	Label left "Frequency (Hz)"
	Label bottom "Time (min)"
	SetAxis bottom 0,30
	SetAxis/A/E=1 left
	ControlBar 50
	SetVariable freq_thresh_set,pos={25,5},size={175,16},title="Spike threshold: "
	SetVariable freq_thresh_set,limits={-100,200,5},value= root:acquisition:variables:freq_thresh, proc=color_freq
	SetVariable setvar_fl,pos={210,5},size={150,16},title="Analyze period from: "
	SetVariable setvar_fl,value= root:acquisition:variables:freq_left,limits={0,10,.1}, proc=color_freq
	SetVariable setvar_fr,pos={375,5},size={70,16},title="to:"
	SetVariable setvar_fr,value= root:acquisition:variables:freq_right,limits={0,10,.1}, proc=color_freq
	Button button_freq title="Add tag",size={100,20}, pos={380,25}, proc=Add_tag
	SetWindow kwTopWin,hook=topwinpath
EndMacro

Window Temperature_window() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(10,350,330,440) root:acquisition:temperature vs root:acquisition:sweep_t
	Label left "°C"
	Label bottom "Time (min)"
	SetAxis left 24,36
	SetAxis bottom 0,30
EndMacro

Window Holding() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(530,313,1330,520) root:acquisition:holding_i vs root:acquisition:sweep_t
	ModifyGraph mode=6
	if (root:acquisition:variables:voltage_clamp)
		Label left "holding current (pA)"
	else
		Label left "V\\Bm\\M (mV)"
	endif
	SetAxis bottom 0,30
	SetWindow kwTopWin,hook=topwinpath
EndMacro

Window Ih_analysis() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:acquisition:
	Display /W=(360,40,610,380) ih_0
	AppendToGraph/L=current/B=voltage current_ih vs voltage_ih
	SetDataFolder fldrSav0
	ModifyGraph lblPos(left)=54,lblPos(bottom)=37,lblPos(current)=54,lblPos(voltage)=35
	ModifyGraph freePos(current)=0
	ModifyGraph freePos(voltage)={0.54,kwFraction}
	ModifyGraph axisEnab(left)={0,0.4}
	ModifyGraph axisEnab(current)={0.55,1}
	Label left "pA"
	Label current "Current (pA)"
	Label voltage "Voltage (mV)"
	ControlBar 50
	Button buttonsave_ih,pos={30,25},size={100,20},proc=save_close_ih,title="Save copy of data"
	Button buttonclear_ih,pos={200,25},size={100,20},proc=clear_ih,title="Clear data"
	CheckBox check0 title="Early",pos={40,5},mode=1, proc=RadioButtonProc
	CheckBox check1 title="Late",pos={140,5},mode=1, value =1, proc=RadioButtonProc
	CheckBox check2 title="Difference",pos={215,5},mode=1, proc=RadioButtonProc
EndMacro

Window IV_Ramp() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:acquisition:
	Display /W=(360,40,610,380) ramp_input
	AppendToGraph/L=current/B=voltage ramp_current vs ramp_voltage
	SetDataFolder fldrSav0
	ModifyGraph lblPos(left)=54,lblPos(bottom)=37,lblPos(current)=54,lblPos(voltage)=35
	ModifyGraph freePos(current)=0
	ModifyGraph freePos(voltage)={0.54,kwFraction}
	ModifyGraph axisEnab(left)={0,0.4}
	ModifyGraph axisEnab(current)={0.55,1}
	Label left "pA"
	Label current "Current (pA)"
	Label voltage "Voltage (mV)"
	SetAxis voltage -140,-40 
	ControlBar 40
	Button buttonsave_ramp,pos={30,15},size={100,20},proc=save_close_ramp,title="Save copy of data"
	Button buttonclear_ramp,pos={200,15},size={100,20},proc=clear_ramp,title="Clear data"
EndMacro

Function add_tag(ctrlName) : ButtonControl   //Allows to add tags to Ampl or Freq, appends note to notebook
	String ctrlName
	Wave sweep_t = root:acquisition:sweep_t
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar tag_number = root:acquisition:variables:tag_number
	String User_Input
	prompt User_Input, "Tag info:"
	DoPrompt "Enter tag info: ", user_input
	print user_Input
	If (stringmatch(ctrlName,"button_ampl"))
		Tag/C/N=$("text"+num2str(tag_number))/B=(65280,59904,48896) ampl, sweep_number,"\\Z08"+user_input
	else
		Tag/C/N=$("text"+num2str(tag_number))/B=(65280,59904,48896) inst_freq, sweep_number,"\\Z08"+user_input
	endif
	tag_number +=1
	Notebook Experiment_Log selection={endOfFile, endOfFile}
	Notebook Experiment_Log text = "\rSweep "+num2str(sweep_number)+": ("+secs2time(60*sweep_t[sweep_number],5)+" ):  "+user_input
End

Proc Printout()
	killdatafolder /Z root:tmp_PauseForUser
	NewDataFolder/O root:tmp_PauseForUser
	String /g root:tmp_PauseForUser:ExpName = ""
	Make /t/n=8 root:tmp_PauseForUser:GraphList = {"WholeCell","Analysis","Holding","Temperature_window","Frequency","Resistance","Ih_analysis"}
	Make /n=8 root:tmp_PauseForUser:GraphListSel = {1,0,1,0,1,1,1}
	DoWindow /k PrintoutDialog
	NewPanel /W=(415,251,685,525)
	DoWindow /C PrintoutDialog
	SetDrawLayer UserBack
	DrawText 10,70,"Select windows to display:"
	DrawText 10,20,"Enter experiment name:"
	SetVariable setvar1,pos={20,25},size={200,17},limits={-Inf,Inf,1}
	SetVariable setvar1,value= root:tmp_PauseForUser:ExpName
	ListBox list0,pos={60,75},size={150,135},listWave= root:tmp_PauseForUser:GraphList
	ListBox list0,selWave= root:tmp_PauseForUser:GraphListSel,mode= 8
	Button button0,pos={100,225},size={70,40},title="Select"
	Button button0, proc=UserGetInput
	PauseforUser PrintoutDialog
	
	NewLayout /W=(100,40,500,500)
	Textbox /N=text0/F=0/A=LT/X=5/Y=0 "\\Z14"+ root:tmp_PauseForUser:ExpName
	Textbox /N=text1/F=0/A=LT/X=70/Y=0 "\\Z12"+date()
	if (root:tmp_PauseForUser:GraphListSel[0])
			AppendLayoutObject /F=0 /T=1 /R=(72,540,360,720) graph WholeCell
	endif
	if (root:tmp_PauseForUser:GraphListSel[1])
			AppendLayoutObject /F=0 /T=1 /R=(72,75,540,240) graph Analysis
	endif
	if (root:tmp_PauseForUser:GraphListSel[2])
			AppendLayoutObject /F=0 /T=1 /R=(72,240,540,380) graph Holding
	endif
	if (root:tmp_PauseForUser:GraphListSel[3])
			AppendLayoutObject /F=0 /T=0 /R=(72,460,540,540) graph Temperature_window
	endif
	if (root:tmp_PauseForUser:GraphListSel[4])
			AppendLayoutObject /F=0 /T=1 /R=(72,75,540,240) graph Frequency
	endif
	if (root:tmp_PauseForUser:GraphListSel[5])
			AppendLayoutObject /F=0 /T=1 /R=(72,380,540,540) graph Resistance
	endif
	if (root:tmp_PauseForUser:GraphListSel[6])
			AppendLayoutObject /F=0 /T=1 /R=(360,540,540,720) graph Ih_analysis
	endif	
	
	killdatafolder root:tmp_PauseForUser
End	

Function UserGetInput(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K PrintoutDialog		
End





Function SetUserGainMC()
NVar voltage_clamp = root:acquisition:variables:voltage_clamp
NVar multiclampID = root:acquisition:variables:multiclampID
NVar multiclampCh = root:acquisition:variables:multiclampCh
NVar user_gain_VC = root:acquisition:variables:user_gain_VC
NVar user_gain_CC = root:acquisition:variables:user_gain_CC
//Automatically sets user gain from MultiClamp 700B... this requires editing initial variables for each setup 
//Use axontelegraphfindservers to determine multiclamp address, etc.
//Must also have axontelegraphmonitor.xop loaded or macro will not work

//If (voltage_clamp)  // in voltage clamp mode
//	if (axontelegraphgetdatanum(multiclampID,multiclampCh,"OperatingMode")==0)
//		user_gain_VC = axontelegraphgetdatanum(multiclampID,multiclampCh,"ScaleFactor") * axontelegraphgetdatanum(multiclampID,multiclampCh,"Alpha")
//		print num2str(user_gain_VC) +"  mV / pA"
//	else
//		print "Could not set user gain:"
//		print "Multiclamp set to " + axontelegraphgetdatastring(multiclampID,multiclampCh,"OperatingMode", 1)+"; Igor set to V-clamp"
//	endif
//else  // in current clamp mode
//	if (axontelegraphgetdatanum(multiclampID,multiclampCh,"OperatingMode")>0)
//		user_gain_CC = axontelegraphgetdatanum(multiclampID,multiclampCh,"ScaleFactor") * axontelegraphgetdatanum(multiclampID,multiclampCh,"Alpha")
//		print num2str(user_gain_CC) +"  mV/mV"
//	else
//		print "Could not set user gain:"
//		print "Multiclamp set to " + axontelegraphgetdatastring(multiclampID,multiclampCh,"OperatingMode", 1)+"; Igor set to C-clamp (I=0)"
//
//	endif
//endif
//end

// copy
//If (voltage_clamp)  // in voltage clamp mode
//	if (axontelegraphgetdatanum(multiclampID,multiclampCh,"OperatingMode")==0)
//		root:acquisition:variables:user_gain_VC = axontelegraphgetdatanum(multiclampID,multiclampCh,"ScaleFactor") * axontelegraphgetdatanum(multiclampID,multiclampCh,"Alpha")
//		print num2str(root:acquisition:variables:user_gain_VC) +"  mV / pA"
//	else
//		print "Could not set user gain:"
//		print "Multiclamp set to " + axontelegraphgetdatastring(multiclampID,multiclampCh,"OperatingMode", 1)+"; Igor set to V-clamp"
//	endif
//else  // in current clamp mode
//	if (axontelegraphgetdatanum(multiclampID,multiclampCh,"OperatingMode")>0)
//		root:acquisition:variables:user_gain_CC = axontelegraphgetdatanum(multiclampID,multiclampCh,"ScaleFactor") * axontelegraphgetdatanum(multiclampID,multiclampCh,"Alpha")
//		print num2str(root:acquisition:variables:user_gain_CC) +"  mV/mV"
//	else
//		print "Could not set user gain:"
//		print "Multiclamp set to " + axontelegraphgetdatastring(multiclampID,multiclampCh,"OperatingMode", 1)+"; Igor set to C-clamp (I=0)"
//
//	endif
//endif
end


// ----------------------------------------------------------Pulse Train Generator------------------------------------------------------------
// ---- Version 1.0 
////  TO DO LIST:
//  Setup menu:  number of channels
//  Make panel adjustable for 3 or 4 channels
//  Show total number of waves in ring buffer
//  Header for the procedure file
//  Finish CUSTOM design -- auto load custom waves?  (tag PTGc0_1, PTGc1_1 etc)

Function  PTG_waveformgen()
	SVar NIDAQ_dev = root:acquisition:variables:NIDAQ_dev
	SVar NIDAQ_ctr = root:acquisition:variables:NIDAQ_ctr
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar ch0_ring = root:PTG:ch0_ring
	NVar PTG0_on = root:PTG:PTG0_on
	NVar ch1_ring = root:PTG:ch1_ring
	NVar PTG1_on = root:PTG:PTG1_on
	Wave PTG_ch0 = root:PTG:PTG_ch0
	Wave PTG_ch1 = root:PTG:PTG_ch1
	NVar PTG_duration = root:PTG:PTG_duration
	NVar PTG_freq = root:PTG:PTG_freq


		switch (PTG0_on*10+PTG1_on)
				case 1:    //Ch0 off Ch1 on
					Make /o/n=(PTG_freq*PTG_duration) PTG_1 = PTG_ch1[p][mod(sweep_number,ch1_ring)]
					SetScale/I x 0,PTG_duration,"", PTG_1
					DAQmx_waveformgen /dev=NIDAQ_dev /ERRH="error_sweep()" /trig={NIDAQ_ctr} /nprd=1 "PTG_1, 1;" 
					break
				case 10:   //Ch0 on Ch1 off
					Make /o/n=(PTG_freq*PTG_duration) PTG_0 = PTG_ch0[p][mod(sweep_number,ch0_ring)]
					SetScale/I x 0,PTG_duration,"", PTG_0
					DAQmx_waveformgen /dev=NIDAQ_dev /ERRH="error_sweep()" /trig={NIDAQ_ctr} /nprd=1 "PTG_0, 0;" 
					break
				case 11:	    // both on
					Make /o/n=(PTG_freq*PTG_duration) PTG_0 = PTG_ch0[p][mod(sweep_number,ch0_ring)]
					SetScale/I x 0,PTG_duration,"", PTG_0
					Make /o/n=(PTG_freq*PTG_duration) PTG_1 = PTG_ch1[p][mod(sweep_number,ch1_ring)]
					SetScale/I x 0,PTG_duration,"", PTG_1
					DAQmx_waveformgen /dev=NIDAQ_dev /ERRH="error_sweep()" /trig={NIDAQ_ctr} /nprd=1 "PTG_0, 0; PTG_1, 1;" 
					break
			endswitch
end

Menu "Pulse-train" , dynamic			
	"Initialize", Initialize_PTG()
	"-"
	"Output frequency", PTG_set_freq()
	"Output duration", PTG_set_duration()
	"Output gain", PTG_set_gain()
//	"Output channels", PTG_set_channel()
	"-"
	"Save settings", PTG_save()
//	"About version 1.0", About_PTG()
End

Macro Initialize_PTG()
	Silent 1
	String savedDataFolder = GetDataFolder(1)
	Newdatafolder /o/s root:PTG
	
	//Looks to see if settings files exist, loads or creates.
	Getfilefolderinfo /p=igor /q /z "settings_ch0.ibw"
	if (v_flag == 0)
		LoadWave /h/o/q/p=igor "settings_ch0.ibw"
	else
		if (!exists("settings_ch0"))
			Make /N=(8,1) settings_ch0
			settings_ch0 = {50,-3,100,-3,0,-3,1,-.2}
		endif
	endif
	Getfilefolderinfo /p=igor /q /z "settings_ch1.ibw"	
	if (v_flag == 0)
		LoadWave /h/o/q/p=igor "settings_ch1.ibw"
	else
		if (!exists("settings_ch1"))
			Make /N=(8,1) settings_ch1
			settings_ch1 = {200,-3,100,-6,50,-3,1,10}
		endif
	endif
	Variable /g PTG_freq = 10000  //Hz
	Variable /g PTG_duration = .8  //sec
	Variable /g Ch0_ring = dimsize(settings_ch0,1)
	Variable /g Ch1_ring = dimsize(settings_ch1,1)
	Variable /g PTG0_on = 1
	Variable /g PTG1_on = 1
	Variable /g PTG0_gain = 1
	Variable /g PTG1_gain = 1
	DoWindow /k PTG	
	PTG()
	Make /o/n=(PTG_freq*PTG_duration,ch0_ring) PTG_ch0   
	Make /o/n=(PTG_freq*PTG_duration,ch1_ring) PTG_ch1   
	SetScale/I x 0,PTG_duration,"", PTG_ch0,PTG_ch1
	SetDataFolder savedDataFolder
End


Window PTG() : Panel
	SetDataFolder root:PTG
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1050,70,1400,320)
	ModifyPanel cbRGB=(47872,47872,47872)

	SetDrawLayer UserBack
	SetDrawEnv xcoord= rel,ycoord= rel,fsize= 14,textxjust= 1,textyjust= 1
	DrawText 0.175,0.075,"Channel 0"
	SetDrawEnv xcoord= rel,ycoord= rel,fsize= 14,textxjust= 1,textyjust= 1
	DrawText 0.825,0.075,"Channel 1"
	SetDrawEnv xcoord= rel,ycoord= rel, textxjust= 1,textyjust= 1
	DrawLine 0.354,0,0.354,1
	SetDrawEnv xcoord= rel,ycoord= rel
	DrawLine 0.646,0,0.646,1
	SetDrawEnv xcoord= rel,ycoord= rel,fsize= 16,textxjust= 1,textyjust= 1
	DrawText 0.5,0.3,"Duration"
	SetDrawEnv xcoord= rel,ycoord= rel,fsize= 16,textxjust= 1,textyjust= 1
	DrawText 0.5,0.4,"Delay"
	SetDrawEnv xcoord= rel,ycoord= rel,fsize= 16,textxjust= 1,textyjust= 1
	DrawText 0.5, 0.5,"Interval"
	SetDrawEnv xcoord= rel,ycoord= rel,fsize= 16,textxjust= 1,textyjust= 1
	DrawText 0.5,0.6,"Number"
	SetDrawEnv xcoord= rel,ycoord= rel,fsize= 16,textxjust= 1,textyjust= 1
	DrawText 0.5,0.7,"Amplitude"
	SetDrawEnv xcoord= rel,ycoord= rel,fsize= 16,textxjust= 1,textyjust= 1
	DrawText 0.5,0.80,"Ring"
//Channel 0 Buttons and variables
	Button button0_1,pos={40,35},size={40,20},proc=ButtonProc0a,title="ON"
	Button button0_2,pos={5,195},size={40,20},proc=ButtonProc0_1,title="Add"
	Button button0_3,pos={85,195},size={30,20},proc=ButtonProc0_2,title="Del"
	Button button0_4,pos={35,225},size={50,20},title="Custom", proc=ButtonProc0_3
	SetVariable setvar0_1,pos={12,95},size={50,16},proc=SetVarProc0_1,title=" "
	SetVariable setvar0_1,limits={0,inf,10},value= settings_ch0[0][ch0_ring-1]
	SetVariable setvar0_2,pos={12,70},size={50,16},proc=SetVarProc0_1,title=" "
	SetVariable setvar0_2,limits={0,inf,10},value=settings_ch0[2][ch0_ring-1]
	SetVariable setvar0_3,pos={12,120},size={50,16},proc=SetVarProc0_1,title=" "
	SetVariable setvar0_3,limits={0,inf,10},value=settings_ch0[4][ch0_ring-1]
	SetVariable setvar0_4,pos={75,95},size={30,16},proc=SetVarProc0_1,title=" "
	SetVariable setvar0_4,limits={-6,0,1},value= settings_ch0[1][ch0_ring-1]
	SetVariable setvar0_5,pos={75,70},size={30,16},proc=SetVarProc0_1,title=" "
	SetVariable setvar0_5,limits={-6,0,1},value= settings_ch0[3][ch0_ring-1]
	SetVariable setvar0_6,pos={75,120},size={30,16},proc=SetVarProc0_1,title=" "
	SetVariable setvar0_6,limits={-6,0,1},value= settings_ch0[5][ch0_ring-1]
	SetVariable setvar0_7,pos={37,145},size={50,16},proc=SetVarProc0_1,title=" "
	SetVariable setvar0_7,limits={1,inf,1},value= settings_ch0[6][ch0_ring-1]
	SetVariable setvar0_8,pos={37,170},size={50,16},proc=SetVarProc0_1,title=" "
	SetVariable setvar0_8,limits={-10,10,0.1},value= settings_ch0[7][ch0_ring-1]
	SetVariable setvar0_9,pos={49,197},size={30,16},title=" " 
	SetVariable setvar0_9,limits={1,dimsize(settings_ch0,1),1},value= ch0_ring
	SetVariable setvar0_9 proc=SetVarProc0_2
	ValDisplay valdisp0,pos={15,39},size={12,12},disable=2,frame=2
	ValDisplay valdisp0,limits={0,1,0},barmisc={0,0},mode= 1,lowColor= (13056,0,0),zeroColor= (13056,0,0)
	ValDisplay valdisp0,value= #"root:PTG:PTG0_on"

//Channel 1 Buttons and variables
	Button button1_1,pos={270,35},size={40,20},proc=ButtonProc1a,title="ON"
	Button button1_2,pos={231,195},size={40,20},proc=ButtonProc1_1,title="Add"
	Button button1_3,pos={311,195},size={30,20},proc=ButtonProc1_2,title="Del"
	Button button1_4,pos={261,225},size={50,20},title="Custom", proc=ButtonProc1_3
	SetVariable setvar1_1,pos={238,95},size={49,16},proc=SetVarProc1_1,title=" "
	SetVariable setvar1_1,limits={0,inf,10},value= settings_ch1[0][ch1_ring-1]
	SetVariable setvar1_2,pos={238,70},size={50,16},proc=SetVarProc1_1,title=" "
	SetVariable setvar1_2,limits={0,inf,10},value= settings_ch1[2][ch1_ring-1]
	SetVariable setvar1_3,pos={238,120},size={49,16},proc=SetVarProc1_1,title=" "
	SetVariable setvar1_3,limits={0,inf,10},value= settings_ch1[4][ch1_ring-1]
	SetVariable setvar1_4,pos={301,95},size={30,16},proc=SetVarProc1_1,title=" "
	SetVariable setvar1_4,limits={-6,0,1},value= settings_ch1[1][ch1_ring-1]
	SetVariable setvar1_5,pos={301,70},size={30,16},proc=SetVarProc1_1,title=" "
	SetVariable setvar1_5,limits={-6,0,1},value= settings_ch1[3][ch1_ring-1]
	SetVariable setvar1_6,pos={301,120},size={30,16},proc=SetVarProc1_1,title=" "
	SetVariable setvar1_6,limits={-6,0,1},value= settings_ch1[5][ch1_ring-1]
	SetVariable setvar1_7,pos={263,145},size={50,16},proc=SetVarProc1_1,title=" "
	SetVariable setvar1_7,limits={1,inf,1},value= settings_ch1[6][ch1_ring-1]
	SetVariable setvar1_8,pos={263,170},size={50,16},proc=SetVarProc1_1,title=" "
	SetVariable setvar1_8,limits={-10,10,0.1},value= settings_ch1[7][ch1_ring-1]
	SetVariable setvar1_9,pos={275,197},size={30,16},title=" " 
	SetVariable setvar1_9,limits={1,dimsize(settings_ch1,1),1},value= ch1_ring
	SetVariable setvar1_9 proc=SetVarProc1_2
	ValDisplay valdisp1,pos={245,39},size={12,12},disable=2,frame=2
	ValDisplay valdisp1,limits={0,1,0},barmisc={0,0},mode= 1,lowColor= (13056,0,0),zeroColor= (13056,0,0)
	ValDisplay valdisp1,value= #"root:PTG:PTG1_on"

EndMacro

Function PTG_redraw()  // This updates the values when changing the ring buffer
	Wave settings_ch0 = root:PTG:settings_ch0
	Wave settings_ch1 = root:PTG:settings_ch1
	NVar ch0_ring = root:PTG:ch0_ring
	NVar ch1_ring = root:PTG:ch1_ring
//Channel 0: Buttons and variables
	SetVariable setvar0_1,value= settings_ch0[0][ch0_ring-1]
	SetVariable setvar0_2,limits={0,inf,10},value= settings_ch0[2][ch0_ring-1]
	SetVariable setvar0_3,limits={0,inf,10},value= settings_ch0[4][ch0_ring-1]
	SetVariable setvar0_4,limits={-6,0,1},value= settings_ch0[1][ch0_ring-1]
	SetVariable setvar0_5,limits={-6,0,1},value= settings_ch0[3][ch0_ring-1]
	SetVariable setvar0_6,limits={-6,0,1},value= settings_ch0[5][ch0_ring-1]
	SetVariable setvar0_7,limits={1,inf,1},value= settings_ch0[6][ch0_ring-1]
	SetVariable setvar0_8,limits={-10,10,0.1},value= settings_ch0[7][ch0_ring-1]
	SetVariable setvar0_9,limits={1,dimsize(settings_ch0,1),1}
//Channel 1: Buttons and variables
	SetVariable setvar1_1,limits={0,inf,10},value= settings_ch1[0][ch1_ring-1]
	SetVariable setvar1_2,limits={0,inf,10},value= settings_ch1[2][ch1_ring-1]
	SetVariable setvar1_3,limits={0,inf,10},value= settings_ch1[4][ch1_ring-1]
	SetVariable setvar1_4,limits={-6,0,1},value= settings_ch1[1][ch1_ring-1]
	SetVariable setvar1_5,limits={-6,0,1},value= settings_ch1[3][ch1_ring-1]
	SetVariable setvar1_6,limits={-6,0,1},value= settings_ch1[5][ch1_ring-1]
	SetVariable setvar1_7,limits={1,inf,1},value= settings_ch1[6][ch1_ring-1]
	SetVariable setvar1_8,limits={-10,10,0.1},value= settings_ch1[7][ch1_ring-1]
	SetVariable setvar1_9,limits={1,dimsize(settings_ch1,1),1}

EndMacro

Macro PTG_save()   //Saves settings (this does not save custom waves)
	Save/C/P=Igor root:PTG:settings_ch0 as "settings_ch0.ibw"
	Save/C/P=Igor root:PTG:settings_ch1 as "settings_ch1.ibw"
End

Proc PTG_set_freq(freq)
	variable freq = root:PTG:PTG_freq
	prompt freq "Enter output frequency"
	root:PTG:PTG_freq = freq
	Redimension/N=(freq*root:PTG:PTG_duration,-1) root:PTG:PTG_ch0
	Redimension/N=(freq*root:PTG:PTG_duration,-1) root:PTG:PTG_ch1
	SetScale/I x 0,root:PTG:PTG_duration,"", root:PTG:PTG_ch0,root:PTG:PTG_ch1
End

Proc PTG_set_duration(duration)
	variable duration = root:PTG:PTG_duration
	prompt duration "Enter output duration"
	root:PTG:PTG_duration = duration
	Redimension/N=(root:PTG:PTG_freq*root:PTG:PTG_duration,-1) root:PTG:PTG_ch0
	Redimension/N=(root:PTG:PTG_freq*root:PTG:PTG_duration,-1) root:PTG:PTG_ch1
	SetScale/I x 0,root:PTG:PTG_duration,"", root:PTG:PTG_ch0,root:PTG:PTG_ch1
End

Proc PTG_set_gain(gain,channel)	
	variable gain =  1 //$(stringfromlist(root:experiment_type,";root:PTG:PTG0_gain;root:PTG:PTG1_gain"))
	variable channel = 0
	prompt gain, "Enter User Gain"
	prompt channel, "For Channel",popup,"0;1"
	if (channel-1)
		root:PTG:PTG1_gain = gain
	else
		root:PTG:PTG0_gain = gain
	endif
	
end	

if (root:acquisition:variables:voltage_clamp)
		root:PTG:PTG0_gain_VC = gain
	else
		root:PTG:PTG0_gain_CC = gain
	endif
end


Function PTG_output(channel, ring)   //This creates the output wave based on values
	Variable channel
	Variable ring
	Wave settings = root:PTG:$("settings_ch"+num2str(channel))
	Wave m8 = root:PTG:$("PTG_ch"+num2str(channel))
	NVar gain = root:PTG:$("PTG"+num2str(channel)+"_gain")
	Variable delay = settings[0][ring-1]
	Variable delay_exp = settings[1][ring-1]
	Variable duration = settings[2][ring-1]
	Variable duration_exp = settings[3][ring-1]
	Variable interval = settings[4][ring-1]
	Variable interval_exp = settings[5][ring-1]
	Variable m = settings[6][ring-1]
	Variable amp = settings[7][ring-1]
	m8[][ring-1] = 0
	m8[x2pnt(m8,delay*10^(delay_exp)),x2pnt(m8,delay*10^(delay_exp)+duration*10^(duration_exp))-1][ring-1] = 1
	variable step
	for (step=1; step < m; step +=1)
		m8[x2pnt(m8,delay*10^(delay_exp)+step*(interval*10^(interval_exp))),x2pnt(m8,delay*10^(delay_exp)+step*(interval*10^(interval_exp))+duration*10^(duration_exp))-1][ring-1] = 1
	endfor
	m8[][ring-1] *= amp /gain
End

// Button and Variable functions for Channel 0 

Function ButtonProc0a(ba) : ButtonControl  //  On Off button
	STRUCT WMButtonAction &ba
	NVar PTG0_on = root:PTG:PTG0_on
	switch( ba.eventCode )
		case 2: // mouse up
			If (PTG0_on)
				PTG0_on = 0
				Button button0_1,title="OFF"
				
			else
				PTG0_on = 1
				Button button0_1,title="ON"
			endif
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProc0_1(ba) : ButtonControl   //This is the ADD ring for Ch0 button
	STRUCT WMButtonAction &ba
	NVar ring = root:PTG:Ch0_ring
	Wave settings = root:PTG:settings_ch0
	Wave PTG_ch = root:PTG:PTG_ch0

	switch( ba.eventCode )
		case 2: // mouse up
			Insertpoints /m=1	ring, 1, settings, PTG_ch
			if (settings[0][ring-1] > 0)
				settings[][ring] = settings[p][ring-1]
			else
				settings[0][ring] = 100
				settings[1][ring] = -3
				settings[2][ring] = 200
				settings[3][ring] = -6
				settings[4][ring] = 50
				settings[5][ring] = -3
				settings[6][ring] = 1
				settings[7][ring] = 10
			endif
			ring += 1
			execute("PTG_redraw()")
			PTG_output(0,ring)   
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc0_2(ba) : ButtonControl   //this deletes current pattern from the ring
	STRUCT WMButtonAction &ba
	NVar ring = root:PTG:Ch0_ring
	Wave settings = root:PTG:settings_ch0
	Wave PTG_ch = root:PTG:PTG_ch0
	switch( ba.eventCode )
		case 2: // mouse up
			if (dimsize(settings,1) > 1)
				DeletePoints /M=1 (ring-1),1, settings, PTG_ch
				Ring -= 1
				execute("PTG_redraw()")
			else
				Print "Must have at least one wave in buffer"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc0_3(ba) : ButtonControl  //This is the custom button for Ch 0
	STRUCT WMButtonAction &ba
	Wave settings = root:PTG:settings_ch0
	NVar ring = root:PTG:ch0_ring
		switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			// This is for CUSTOM button
			Settings[][ring-1] = -1
			Make /o/n=10000 root:PTG:custom_wave
			SetScale/I x 0,1,"", root:PTG:custom_wave
			DoWindow /k PTG_custom	
			execute("PTG_custom(0)")	
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function SetVarProc0_1(sva) : SetVariableControl  //This updates the PTG wave when changes are made
	STRUCT WMSetVariableAction &sva
	NVar ring = root:PTG:ch0_ring
	switch( sva.eventCode )
		case 1: // mouse up
			PTG_output(0,ring)
		case 2: // Enter key
			PTG_output(0,ring)
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End 

Function SetVarProc0_2(sva) : SetVariableControl   //Updates when you change ring
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
			execute("PTG_redraw()")
			PTG_output(0,1)
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

// Button and Variable functions for Channel 1 

Function ButtonProc1a(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVar PTG1_on = root:PTG:PTG1_on
	switch( ba.eventCode )
		case 2: // mouse up
			If (PTG1_on)
				PTG1_on = 0
				Button button1_1,title="OFF"
			else
				PTG1_on = 1
				Button button1_1,title="ON"
			endif
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProc1b(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			button Button1_0 disable = 0
			button Button1_1 disable = 2
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProc1_1(ba) : ButtonControl   //This is the ADD ring for Ch1 button
	STRUCT WMButtonAction &ba
	NVar ring = root:PTG:Ch1_ring
	Wave settings = root:PTG:settings_ch1
	Wave PTG_ch = root:PTG:PTG_ch1

	switch( ba.eventCode )
		case 2: // mouse up
			Insertpoints /m=1	ring, 1, settings, PTG_ch
			if (settings[0][ring-1] > 0)
				settings[][ring] = settings[p][ring-1]
			else
				settings[0][ring] = 100
				settings[1][ring] = -3
				settings[2][ring] = 200
				settings[3][ring] = -6
				settings[4][ring] = 50
				settings[5][ring] = -3
				settings[6][ring] = 1
				settings[7][ring] = 10
			endif
			ring += 1
			execute("PTG_redraw()")
			PTG_output(1,ring)   
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc1_2(ba) : ButtonControl   //this deletes current pattern from the ring
	STRUCT WMButtonAction &ba
	NVar ring = root:PTG:Ch1_ring
	Wave settings = root:PTG:settings_ch1
	Wave PTG_ch = root:PTG:PTG_ch1
	switch( ba.eventCode )
		case 2: // mouse up
			if (dimsize(settings,1) > 1)
				DeletePoints /M=1 (ring-1),1, settings, PTG_ch
				Ring -= 1
				execute("PTG_redraw()")
			else
				Print "Must have at least one wave in buffer"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc1_3(ba) : ButtonControl  //This is the custom button for Ch 1
	STRUCT WMButtonAction &ba
	Wave settings = root:PTG:settings_ch1
	NVar ring = root:PTG:ch1_ring
		switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			// This is for CUSTOM button
			Settings[][ring-1] = -1
			Make /o/n=10000 custom_wave
			SetScale/I x 0,1,"", custom_wave
			DoWindow /k PTG_custom	
			execute("PTG_custom(1)")	
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function SetVarProc1_1(sva) : SetVariableControl  //This updates the PTG wave when changes are made
	STRUCT WMSetVariableAction &sva
	NVar ring = root:PTG:ch1_ring
	switch( sva.eventCode )
		case 1: // mouse up
			PTG_output(1,ring)
		case 2: // Enter key
			PTG_output(1,ring)
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End 

Function SetVarProc1_2(sva) : SetVariableControl   //Updates when you change ring
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
			execute("PTG_redraw()")
			PTG_output(1,1)
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

//  Custom PTG window

Window PTG_custom(channel) : Graph
	variable channel
	PauseUpdate; Silent 1		// building window...
	Display /W=(36.75,163.25,431.25,371.75) root:PTG:custom_wave
	ControlBar 40
	ShowInfo
	Cursor A custom_wave leftx(root:PTG:custom_wave)
	Cursor B custom_wave rightx(root:PTG:custom_wave)
	
	Button button0,pos={13,8},size={50,20},proc=ButtonProc_c1,title="Load"
	Button button1,pos={73,8},size={70,20},proc=ButtonProc_c2,title="Save Wave"
	if (!channel)
		Button button2,pos={458,9},size={60,20},proc=ButtonProc0_c3,title="Finished"
	else
		Button button2,pos={458,9},size={60,20},proc=ButtonProc1_c3,title="Finished"
	endif
	Button button3,pos={194,8},size={25,20},proc=ButtonProc_c5,title="DC"
	Button button4,pos={228,8},size={25,20},proc=ButtonProc_c6,title="\\W620"
	Button button5,pos={263,8},size={25,20},proc=ButtonProc_c7,title="\\W621"
	Button button6,pos={298,8},size={35,20},proc=ButtonProc_c4,title="clear"
EndMacro


Function ButtonProc_c1(ba) : ButtonControl  //Load custom
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			String savedDataFolder = GetDataFolder(1)
			Setdatafolder root:PTG
			LoadWave /h/o/P=Igor 
			Setdatafolder savedDataFolder
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_c2(ba) : ButtonControl   //Save custom
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			Save/C/P=Igor root:PTG:custom_wave as "PTGcustom.ibw"
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProc0_c3(ba) : ButtonControl  //Copy custom into ring
	STRUCT WMButtonAction &ba
	Wave PTG = root:PTG:PTG_ch0
	Wave Custom_wave = root:PTG:custom_wave
	NVar ring = root:PTG:ch0_ring
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			PTG[][ring-1] = custom_wave[p]
			killwindow PTG_custom
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProc1_c3(ba) : ButtonControl  //Copy custom into ring
	STRUCT WMButtonAction &ba
	Wave PTG = root:PTG:PTG_ch1
	Wave Custom_wave = root:PTG:custom_wave
	NVar ring = root:PTG:ch1_ring
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			PTG[][ring-1] = custom_wave[p]
			killwindow PTG_custom
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProc_c4(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Wave custom_wave = root:PTG:custom_wave
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			custom_wave[pcsr(a),pcsr(b)]  = 0
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_c5(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Wave custom_wave = root:PTG:custom_wave
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			variable shift
			Prompt shift, "DC offset: "
			DoPrompt "Enter DC shift", shift
			custom_wave[pcsr(a),pcsr(b)] += shift
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_c6(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Wave custom_wave = root:PTG:custom_wave
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			variable shift
			Prompt shift, "Ramp up "
			DoPrompt "Enter height of ramp", shift
			custom_wave[pcsr(a),pcsr(b)] += shift*(p-pcsr(a))/(pcsr(b)-pcsr(a))
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_c7(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Wave custom_wave = root:PTG:custom_wave
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			variable shift
			Prompt shift, "Ramp down "
			DoPrompt "Enter height of ramp", shift
			custom_wave[pcsr(a),pcsr(b)] -= shift*(p-pcsr(a))/(pcsr(b)-pcsr(a))
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End