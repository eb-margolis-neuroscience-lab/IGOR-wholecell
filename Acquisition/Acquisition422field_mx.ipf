#pragma rtGlobals=1		// Use modern global access method.

//			NIDAQ Acquisition Software  version 4.21MX 
//
//			for use with IgorPro version 5 and NIDAQtoolsMX
// 			(note: this procedure will not work with legacy versions of NI DAQ drivers.)
//	
//			version 4.10: 		includes automatic series/input resistance measurement.
//			version 4.11:  	fixes bug in calculating sweep length 
//			version 4.12:  	minor changes to AxonTelegraph macro
//			version 4.13:	 	minor changes to Ih test
//			version 4.2:		fixed bugs in IV ramp and Ih test, added measurement of membrane potential in VC
//			version 4.21:		created string variables for NIDAQ device and NIDAQ counter output
//
//			Connect Ctr0out to User1... this provides trigger for master-8
//			Connect Amplifier out to ACH0
//			To acquire membrane holding potential in VC, have secondary output (Membrane Potential 10mv/mv) sent to ACH1
//			Temperature monitor to ACH2
//		

// --------------------------------------------------------User Variables ----------------------------------------------------------------------
Function User_Variables()

// ------  This holds the initial values for global variables  -- default values in {}
	Variable /G root:acquisition:variables:isi = 10						// Interstimulus interval in seconds {10}
	Variable /G root:acquisition:variables:stepsize = 4				// step size in mv for determining input/series R {4}
	Variable /G root:acquisition:variables:sw_length0 = 1			// sweep length (sec) for stimulation
	Variable /G root:acquisition:variables:sw_length1 = 10				// sweep length (sec) for firing rate
	Variable /G root:acquisition:variables:sw_length2 = 1				// sweep length (sec) for Ih test
	Variable /G root:acquisition:variables:sw_length3 = 4				// sweep length (sec) for IV ramp
	Variable /G root:acquisition:variables:kHz = 5					// DAQ sampling frequency in kHz {5}
	Variable /G root:acquisition:variables:voltage_clamp = 1			// 1 for voltage clamp, 0 for current clamp
	Variable /G root:acquisition:variables:user_gain_VC = 10			// user gain in voltage clamp (pA/mV) {10}
	Variable /G root:acquisition:variables:user_gain_CC = 10			// user gain in current clamp (mV/mV) {10}
	Variable /G root:acquisition:variables:channel_gain = 1			// DAQ board gain {1}
	Variable /G root:acquisition:variables:continuous0 = 0				// Continuous input for stimulation experiment
	Variable /G root:acquisition:variables:continuous1 = 1				// Continouus input for frequency experiment
	Variable /G root:acquisition:variables:RS_on = 1
// Initial position (in seconds) for amplitude analysis	
	Variable /G root:acquisition:variables:ampl_1_on = 1				// 1 is on, 2 is off
	Variable /G root:acquisition:variables:ampl_2_on = 0				// 1 is on, 2 is off
	Variable /G root:acquisition:variables:ampl_1_zero =  .42			// ampl 1 baseline	
	Variable /G root:acquisition:variables:ampl_1_peak = .48			// ampl 1 peak
	Variable /G root:acquisition:variables:ampl_2_zero = .66			// ampl 2 baseline	
	Variable /G root:acquisition:variables:ampl_2_peak = .68			// ampl 2 peak	
	Variable /G root:acquisition:variables:ampl_width = .002			// width of analysis period (s) .002 = 2ms
//  Initial values for spike rate analysis
	Variable /G root:acquisition:variables:freq_left = .2
	Variable /G root:acquisition:variables:freq_right = 10
	Variable /G root:acquisition:variables:freq_thresh = 0
//  Initial values for IH test
	Variable /G root:acquisition:variables:starting_v_ih= -60		// initial holding potential for Ih test / IV ramp
	Variable /G root:acquisition:variables:step_v_ih= -120			// initial step to value for single Ih
	Variable /G root:acquisition:variables:IH_meas = 1  			// 0=early; 1=late; 2=difference
//  Initial values for mini analysis
	Variable /G root:acquisition:variables:minianalysis=0			// turns on mini analysis
	Variable /G root:acquisition:variables:mini_direction = -1
	Variable /G root:acquisition:variables:rise_slope_min = 2000
	Variable /G root:acquisition:variables:min_amplitude = 4
	Variable /G root:acquisition:variables:mini_left = .2
	Variable /G root:acquisition:variables:mini_right = 10
//  Values for multiclamp
	Variable /G root:acquisition:variables:multiclampID=129541
	Variable /G root:acquisition:variables:multiclampCh=1
//  Variables for NIDAQ
	String /G root:acquisition:variables:NIDAQ_dev = "dev1"
	String /G root:acquisition:variables:NIDAQ_ctr = "/dev1/ctr0out"
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
	MenuSet(9), Control_output_start()
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
	String fifthitem = StrVarOrDefault("root:acquisition:menus:fifthitem","(Start Acquisition")
	String sixthitem = StrVarOrDefault("root:acquisition:menus:sixthitem","(Single Sweep -- no Analysis")
	String seventhitem = StrVarOrDefault("root:acquisition:menus:seventhitem","(Single Sweep -- Analyze and Save")
	String eighthitem = StrVarOrDefault("root:acquisition:menus:eighthitem","(Suspend Save each Sweep")
	String ninthitem = StrVarOrDefault("root:acquisition:menus:ninthitem","(Igor controls Master-8")
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
	string /G root:acquisition:menus:seconditem = "Set User Gain"
	string /G root:acquisition:menus:thirditem = "Set Channel Gain"
	string /G root:acquisition:menus:fourthitem = "Auto User Gain"
	string /G root:acquisition:menus:fifthitem = "Start Acquisition"
	string /G root:acquisition:menus:sixthitem =   "Single Sweep -- no Analysis"
	string /G root:acquisition:menus:seventhitem = "Single Sweep -- Analyze and Save"
	string /G root:acquisition:menus:eighthitem = "Suspend Save each Sweep"
	string /G root:acquisition:menus:ninthitem = "Igor controls Master-8"
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
	DrawText 60,87,"Version 4.21MX  --  11/1/2011"
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
	Variable /G root:acquisition:variables:minicount = 0
// Calls user-defined variables
	User_Variables()			

// Creates waves
	Make /o /n=0 root:acquisition:ampl
	Make /o /n=0 root:acquisition:run_ampl
	Make /o /n=0 root:acquisition:ampl2
	Make /o /n=0 root:acquisition:inst_freq
	Make /o /n=0 root:acquisition:series_r
	Make /o /n=0 root:acquisition:input_r
	Make /o /n=0 root:acquisition:holding_i
	Make /o /n=0 root:acquisition:membrane_p
	Make /o /n=0 root:acquisition:temperature
	Make /o /n=0 root:acquisition:sweep_t
	Make /o /n=(root:acquisition:variables:sw_length0*root:acquisition:variables:kHz*1000) root:acquisition:input_0 = 0
	Setscale /p x, 0, 0.001/root:acquisition:variables:kHz, "s", root:acquisition:input_0
	Duplicate /o root:acquisition:input_0 root:acquisition:input_f
	Duplicate /o root:acquisition:input_0 root:acquisition:color_0
	Make /o/n=1000 root:acquisition:input_rs = 0
	Make /o /n=0 root:acquisition:miniamps
	Make /o /n=0 root:acquisition:minitimes
	Make /o /n=0 root:acquisition:minifrequency
	Make /o /n=0 root:acquisition:miniamplitude
	
	
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
	DoWindow /k MiniWindow

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
		NewNotebook /f=0 /n=Experiment_Log  /W=(10,320,230,600)
		Notebook Experiment_Log text = "Date:  \r\rCell:  \r\rInitial Resting Potential:  \rInitial Series Resistance:  \r"
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
	if (stringmatch(infostr,"WINDOW:MiniWindow;HCSPEC:MiniWindow;EVENT:activate;MODIFIERS:*;"))
		color_mini("",0,"","")
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

Function color_mini(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Wave color_0 = root:acquisition:color_0
	NVar mini_direction = root:acquisition:variables:mini_direction
	NVar min_amplitude = root:acquisition:variables:min_amplitude
	NVar mini_left = root:acquisition:variables:mini_left
	NVar mini_right = root:acquisition:variables:mini_right
	color_0 = 0
	color_0[x2pnt(color_0,mini_left),x2pnt(color_0,mini_right)]=1000+mini_direction*min_amplitude
end

// ----------------------------------------------------Data Collection ----------------------------------------------------

Function  Start_Sweep ()
// Define Variables
	Wave input_0 = root:acquisition:input_0
//	Wave input_f = root:acquisition:input_f
	NVar continuous = root:acquisition:variables:continuous
	NVar stop_code = root:acquisition:variables:stop_code
	NVar sweep_number = root:acquisition:variables:sweep_number1
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
		if (sweep_number == 0)
			sweep_time_0 = (ticks/tickfreq)
		endif
		DAQmx_ctr_outputpulse /dev=NIDAQ_dev /npls=1  /sec={.01,.01} 0
	else
		DAQmx_scan /DEV=NIDAQ_dev /BKG=1 /TRIG={NIDAQ_ctr} /EOSH="collect_sweep()" /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE, -10,10,"+num2str(GainMX)+",0;root:acquisition:input_f, 3/RSE, -10,10,1000,0;"
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
	DAQmx_scan /DEV=NIDAQ_dev /BKG=1 /TRIG={NIDAQ_ctr} /EOSH="collect_sweep()" /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE, -10,10,"+num2str(GainMX)+",0;root:acquisition:input_f, 3/RSE, -10,10,1000,0;"
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
	stop_code = 1
end

Function Analyze_sweep(sweep_time,doAn)			// Performs analysis on sweep
	Variable sweep_time
	Variable doAn
// Define Global Variables
	Wave input_0 = root:acquisition:input_0
	Wave input_f = root:acquisition:input_f
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
	NVar minianalysis = root:acquisition:variables:minianalysis
	NVar RS_on = root:acquisition:variables:RS_on
// Define Local Variables	   
	Variable baseline
	Variable W_avg
	String wave_name, wave_name1
// Sets gain of input wave
	if (doAn)
		sweep_number += 1
		redimension /n=(sweep_number) sweep_t
		Sweep_t [sweep_number] = sweep_time / 60
		wave_name="sweep"+num2str(sweep_number)
		wave_name1 = "field"+num2str(sweep_number)
		Note /k input_0
		Note input_0, num2str(sweep_time / 60)
		Duplicate /o input_0 root:acquisition:data:$wave_name
		Duplicate /o input_f root:acquisition:data:$wave_name1
	// Calls Analysis functions based on if window is checked
		if (RS_on == 1)
			Collect_RS() 		// automatic resistance sweep, previous called: Analyze_Res()
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
			if (minianalysis)
				Mini_analysis(sweep_time)
			endif
		// Zeros input wave if box is checked
			if (zero_data)
		 		W_avg = mean(input_0,0,.01)
 				input_0 -= W_avg                    
			endif
		else 		// WC_tab = 1
			Analyze_freq()
		endif	
	// Saves experiment (if suspend save is on, then saves after 20 sweeps)
		if (!(mod(sweep_number,20)*suspend_save))    
			SaveExperiment
		endif
	 // this controls the output of DAC0Out or VDTWrite
		 Controloutput()
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
	variable i=freq_left*5000										
	variable thresholdcount=0
	do
		if (input_0[i]<=freq_thresh && freq_thresh<input_0[i+1])
			thresholdcount=thresholdcount+1
		endif
		i=i+1
	while (i<freq_right*5000)		
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

Function collect_RS()   // New function for directly collecting series/input resistance data
	Wave input_rs = root:acquisition:input_rs
	Wave series_r = root:acquisition:series_r
	Wave input_r = root:acquisition:input_r
	Wave holding_i = root:acquisition:holding_i
	Wave membrane_p = root:acquisition:membrane_p
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar stepsize =  root:acquisition:variables:stepsize   //4mV in VC, 
	NVar voltage_clamp = root:acquisition:variables:voltage_clamp
	NVar user_gain_VC =  root:acquisition:variables:user_gain_VC
	NVar user_gain_CC =  root:acquisition:variables:user_gain_CC
	NVar sweep_number = root:acquisition:variables:sweep_number
	SVar NIDAQ_dev = root:acquisition:variables:NIDAQ_dev
	variable step_number=0
// Collect RS data
	Make /o/n=10 step_rs	= 0
	SetScale/I x 0,.2,"s", step_rs, input_Rs
	step_rs[2,6] = -1*stepsize/20
	DAQmx_waveformgen /dev=NIDAQ_dev /ERRH="error_sweep()" /nprd=1 "root:acquisition:step_rs, 0;"
	DAQmx_scan /DEV=NIDAQ_dev /ERRH="error_sweep()" WAVES="root:acquisition:input_rs, 0/RSE;"
	if (voltage_clamp)
		input_rs *= 1000 / user_gain_VC
	else			 //current clamp
		input_rs *= 1000 / user_gain_CC	
	endif	
	duplicate /o root:acquisition:input_rs  root:acquisition:data:$"rs"+num2str(sweep_number)
	redimension /n=(sweep_number) input_r	
	redimension /n=(sweep_number) series_r
	redimension /n=(sweep_number) holding_i
	redimension /n=(sweep_number) membrane_p
// Analyze holding current
	holding_i [sweep_number] = mean(input_rs,0.001,0.005)  //points 5,25	

	If (voltage_clamp)
	// Analyze series resistance
		Wavestats /Q /R =[150,280] input_rs 
		series_r [sweep_number] =  (1000*stepsize) / (V_max - V_min)
	// Analyze input resistance
		input_r [sweep_number] = abs((1000*stepsize) / (mean(input_rs,.12,.14)-mean(input_rs,0,0.005)))
	// Collect membrane potential
		membrane_p [sweep_number] = fDAQmx_ReadChan(NIDAQ_dev,1,-5,5,1)*100   // mV
	else
	// Analyze input resistance
		input_r [sweep_number] =  1000*abs((mean(input_rs,.12,.14)-mean(input_rs,0,0.005)) / (20*stepsize))
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
	DAQmx_scan /DEV=root:acquisition:variables:NIDAQ_dev /BKG=1 /TRIG={root:acquisition:variables:NIDAQ_ctr} /EOSH=endhook /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE, -10,10,"+num2str(GainMX)+",0;root:acquisition:input_f, 3/RSE, -10,10,1000,0;"
	DAQmx_ctr_outputpulse /dev=root:acquisition:variables:NIDAQ_dev /npls=1  /sec={.01,.01} 0
End

Function Collect_single(doAnalysis)
	variable doAnalysis
	NVar Sweep_time_0 = root:acquisition:variables:sweep_time_0
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
	NVar mini_count = root:acquisition:variables:mini_count
	NVar sweep_time_0 = root:acquisition:variables:sweep_time_0
	NVar tickfreq=root:acquisition:variables:tickfreq
	Wave sweep_t = root:acquisition:sweep_t
	sweep_number = 0
	mini_count = 0
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
//  This next line gives the holding potentials for the individual steps
	ramp_voltage = p -140
//  The next line sets the default holding potential -- can be interactively changed
	ramp[150,900] = (-40 - root:acquisition:variables:starting_v_ih) / 20
	ramp[400,900] -= (p-400)/100
//  Input data
	DAQmx_waveformgen /dev=root:acquisition:variables:NIDAQ_dev /ERRH="error_sweep()" /nprd=1 "root:acquisition:ramp, 0;"
	DAQmx_scan /DEV=root:acquisition:variables:NIDAQ_dev /ERRH="error_sweep()" WAVES="root:acquisition:input_0, 0/RSE;"
	root:acquisition:input_0 *= 1000 / root:acquisition:variables:user_gain_VC
	ramp_input = root:acquisition:input_0
	ramp_current = ramp_input[root:acquisition:variables:sw_length3*(4500-25*p)]
end	

Proc Start_IH(ctrlName) : ButtonControl
	String ctrlName
	Variable step_number=0
	Variable delay_ticks=0
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
End

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
	duplicate /o ramp_input  $(newName+"_input")
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
	Display /W=(10,40,330,320) root:acquisition:color_0, root:acquisition:input_0
	ModifyGraph mode(color_0)=7
	ModifyGraph marker(input_0)=3
	ModifyGraph rgb(color_0)=(60928,60928,60928)
	ModifyGraph hbFill(color_0)=4
	ModifyGraph plusRGB(color_0)=(52224,52224,52224)
	ModifyGraph negRGB(color_0)=(47872,47872,47872)
	ModifyGraph offset(color_0)={0,-1000}
	ModifyGraph lblMargin(bottom)=6
	ModifyGraph standoff(bottom)=0
	ModifyGraph axOffset(bottom)=0.625
	ModifyGraph axisEnab(left)={0,0.9}
	Label left "pA"
	SetAxis left -200,100
	TextBox/N=time_stamp/F=0/X=0.95/Y=-5.71 "\\{root:acquisition:variables:sweep_number}  -- \\{secs2time(60*root:acquisition:sweep_t[root:acquisition:variables:sweep_number],3)}"
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
	TabControl tab0,pos={10,2},size={390,20},proc=TabProc,tabLabel(0)="Stimulation "
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
	NVar minianalysis = root:acquisition:variables:minianalysis
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
		if (minianalysis)
			DoWindow /f MiniWindow
			if (V_flag == 0)
				Execute "MiniWindow()"
			endif
		endif
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
	Display /W=(360,40,760,240) root:acquisition:ampl vs root:acquisition:sweep_t
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
	CheckBox check1, variable=root:acquisition:variables:minianalysis, proc=CheckProc_mini
	Button button_ampl title="Add tag",size={100,20}, pos={380,25}, proc=Add_tag
	SetWindow kwTopWin,hook=topwinpath
EndMacro

Window Resistance() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(360,440,760,640) root:acquisition:series_r vs root:acquisition:sweep_t 
	AppendToGraph/L=in_l root:acquisition:input_r vs root:acquisition:sweep_t
	AppendToGraph/L=rs/B=i_rs root:acquisition:input_rs
	ModifyGraph mode(series_r)=3
	ModifyGraph marker(series_r)=18
	ModifyGraph lblPos(left)=45,lblPos(bottom)=41,lblPos(in_l)=45,lblPos(i_rs)=35
	ModifyGraph freePos(in_l)={0,bottom}
	ModifyGraph freePos(rs)={0.74,kwFraction}
	ModifyGraph freePos(i_rs)=0
	ModifyGraph axisEnab(left)={0,0.45}
	ModifyGraph axisEnab(bottom)={0,0.6}
	ModifyGraph axisEnab(in_l)={0.55,1}
	ModifyGraph axisEnab(i_rs)={0.75,1}
	Label left "Series (Mohm)"
	Label in_l "Input (Mohm)"
	SetAxis left 0,80
	SetAxis bottom 0,30
	SetAxis in_l 0,500
	setwindow Resistance, hook=topwinpath
EndMacro

Window Frequency() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(360,40,760,240) root:acquisition:inst_freq vs root:acquisition:sweep_t
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
	Display /W=(360,270,760,410) root:acquisition:holding_i vs root:acquisition:sweep_t
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

Window MiniWindow() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:acquisition:
	Display /W=(360.75,263,755.25,471.5) miniamps vs minitimes
	AppendToGraph miniamplitude vs sweep_t
	AppendToGraph/L=left_freq minifrequency vs sweep_t
	SetDataFolder fldrSav0
	ModifyGraph mode(miniamps)=3,mode(miniamplitude)=3
	ModifyGraph marker(miniamps)=18,marker(miniamplitude)=16
	ModifyGraph msize(miniamps)=1
	ModifyGraph lblPos(left)=57,lblPos(left_freq)=55
	ModifyGraph freePos(left_freq)=0
	ModifyGraph axisEnab(left)={0,0.5}
	ModifyGraph axisEnab(left_freq)={0.6,1}
	Label left "pA"
	Label bottom "Time (min)"
	Label left_freq "Hz"
	SetAxis/A/E=1 left
	SetAxis/A/E=1 left_freq
	ControlBar 30
	SetVariable setvar_fl,pos={20,7},size={160,16},proc=color_mini,title="Analyze period from: "
	SetVariable setvar_fl,limits={0,10,0.1},value= root:acquisition:variables:mini_left
	SetVariable setvar_fr,pos={195,7},size={70,16},proc=color_mini,title="to:"
	SetVariable setvar_fr,limits={0,10,0.1},value= root:acquisition:variables:mini_right
	SetVariable setvar0,pos={310,7},size={100,16},title="Min Ampl"
	SetVariable setvar0,limits={0,50,0.5},value= root:acquisition:variables:min_amplitude, proc=color_mini
	SetVariable setvar1,pos={420,7},size={90,16},title="Direction"
	SetVariable setvar1,limits={-1,1,2},value= root:acquisition:variables:mini_direction, proc=color_mini
	SetWindow kwTopWin,hook=topwinpath
EndMacro
// --------------------------------------------------Control Output Functions -----------------------------------------------------------------
Function Control_output_start()
	SVar menu_item = root:acquisition:menus:ninthitem
	NVar master8 = root:acquisition:variables:master8
	NVar sweep_number = root:acquisition:variables:sweep_number
	If (master8)
		master8 = 0
		menu_item = "Igor controls Master-8"
	else
		master8 = 1
		Variable /G root:acquisition:variables:initial_sweep = sweep_number
		menu_item = "Igor controls Master-8"
		menu_item = "!"+num2char(18)+"Igor controls Master-8"
		VDToperationsport2 com6
	endif
End

Function Controloutput()
	NVar sweep_number = root:acquisition:variables:sweep_number
	NVar initial_sweep = root:acquisition:variables:initial_sweep
	NVar master8 = root:acquisition:variables:master8
	If (master8)
		variable remain = 2*(sweep_number / 2 - trunc(sweep_number / 2))
		if (round(remain) == 0)
			VDTWrite2 "x 4 3 e x x 4 2 e"
		endif
		if (round(remain) == 1)
			VDTWrite2 "x 4 2 e x x 4 3 e"
		endif
	endif
//	If (master8)
//	variable remain = 4*(sweep_number / 4 - trunc(sweep_number / 4))
//	if (round(remain) == 0)
//		execute /Z "VDTWrite \"L 2 6 8 0 E 3 E\" "
//	endif
//	if (round(remain) == 1)
//		execute /Z "VDTWrite \"L 2 7 8 0 E 3 E\""
//	endif
//	if (round(remain) == 2)
//		execute /Z "VDTWrite \"L 2 9 8 0 E 3 E\""
//	endif
//	if (round(remain) == 3)
//		execute /Z "VDTWrite \"L 2 1 3 8 0 E 3 E\""
//	endif
//endif

end

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



Proc CheckProc_mini(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	if (checked)
		MiniWindow()
	else
		DoWindow /k MiniWindow
	endif
End


Function Mini_analysis(sweep_time)
Variable sweep_time
Wave input_0 = root:acquisition:input_0
wave miniamps = root:acquisition:miniamps 
wave minitimes = root:acquisition:minitimes
wave minifrequency = root:acquisition:minifrequency
wave miniamplitude = root:acquisition:miniamplitude
Nvar minicount = root:acquisition:variables:minicount
Nvar mini_direction = 	 root:acquisition:variables:mini_direction
Nvar rise_slope_min = root:acquisition:variables:rise_slope_min
Nvar min_amplitude = root:acquisition:variables:min_amplitude
NVar sweep_number = root:acquisition:variables:sweep_number
NVar mini_left = root:acquisition:variables:mini_left
NVar mini_right = root:acquisition:variables:mini_right
NVar kHz =  root:acquisition:variables:kHz
Variable ministart = 0
Variable miniposition = mini_left * 1000 * kHz
Variable endpoint =mini_right * 1000 * kHz
Variable this_mini_amp = 0
variable prevcount = minicount
duplicate /o input_0 tempdiff
smooth 10, tempdiff
differentiate tempdiff
do
	do					//to get when the mini risetime starts
		miniposition += 1
		if (mini_direction * tempdiff[miniposition] > rise_slope_min)  //looking for change in slope
			break
		endif	
	while (miniposition < endpoint)
	ministart = miniposition   // might want to have mini_start = miniposition - 1  
	do
		miniposition +=1
		if (mini_direction * tempdiff[miniposition] < 0)  //peak of mini
			break
		endif	
	while (miniposition < endpoint)
	this_mini_amp = mean(input_0, pnt2x(input_0,miniposition-2), pnt2x(input_0,miniposition+2)) - mean(input_0, pnt2x(input_0,ministart-4), pnt2x(input_0,ministart))
	if (mini_direction * this_mini_amp > min_amplitude) 
		minicount += 1
		redimension /n=(minicount) miniamps, minitimes
		minitimes[minicount] = (sweep_time + pnt2x(input_0,ministart))/60
		miniamps[minicount] = this_mini_amp
	endif	
while (miniposition < endpoint)
redimension /n=(sweep_number) miniamplitude, minifrequency
minifrequency[sweep_number] = (minicount - prevcount) / (mini_right- mini_left)
miniamplitude[sweep_number] =  mean(miniamps, prevcount, minicount)

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

If (voltage_clamp)  // in voltage clamp mode
	if (axontelegraphgetdatanum(multiclampID,multiclampCh,"OperatingMode")==0)
		user_gain_VC = axontelegraphgetdatanum(multiclampID,multiclampCh,"ScaleFactor") * axontelegraphgetdatanum(multiclampID,multiclampCh,"Alpha")
		print num2str(user_gain_VC) +"  mV / pA"
	else
		print "Could not set user gain:"
		print "Multiclamp set to " + axontelegraphgetdatastring(multiclampID,multiclampCh,"OperatingMode", 1)+"; Igor set to V-clamp"
	endif
else  // in current clamp mode
	if (axontelegraphgetdatanum(multiclampID,multiclampCh,"OperatingMode")>0)
		user_gain_CC = axontelegraphgetdatanum(multiclampID,multiclampCh,"ScaleFactor") * axontelegraphgetdatanum(multiclampID,multiclampCh,"Alpha")
		print num2str(user_gain_CC) +"  mV/mV"
	else
		print "Could not set user gain:"
		print "Multiclamp set to " + axontelegraphgetdatastring(multiclampID,multiclampCh,"OperatingMode", 1)+"; Igor set to C-clamp (I=0)"

	endif
endif
end

// copy
If (voltage_clamp)  // in voltage clamp mode
	if (axontelegraphgetdatanum(multiclampID,multiclampCh,"OperatingMode")==0)
		root:acquisition:variables:user_gain_VC = axontelegraphgetdatanum(multiclampID,multiclampCh,"ScaleFactor") * axontelegraphgetdatanum(multiclampID,multiclampCh,"Alpha")
		print num2str(root:acquisition:variables:user_gain_VC) +"  mV / pA"
	else
		print "Could not set user gain:"
		print "Multiclamp set to " + axontelegraphgetdatastring(multiclampID,multiclampCh,"OperatingMode", 1)+"; Igor set to V-clamp"
	endif
else  // in current clamp mode
	if (axontelegraphgetdatanum(multiclampID,multiclampCh,"OperatingMode")>0)
		root:acquisition:variables:user_gain_CC = axontelegraphgetdatanum(multiclampID,multiclampCh,"ScaleFactor") * axontelegraphgetdatanum(multiclampID,multiclampCh,"Alpha")
		print num2str(root:acquisition:variables:user_gain_CC) +"  mV/mV"
	else
		print "Could not set user gain:"
		print "Multiclamp set to " + axontelegraphgetdatastring(multiclampID,multiclampCh,"OperatingMode", 1)+"; Igor set to C-clamp (I=0)"

	endif
endif
end