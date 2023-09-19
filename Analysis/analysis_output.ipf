#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"Output Graphs Cclamp", autographs_cclamp()
	"Output Graphs Vclamp", autographs_vclamp()
	"Output Graphs Synaptic", autographs_synaptic()
	"Output Graphs Iontophoresis", autographs_ionto()
//	"Ih Graph", easyIh_disp()
End

//---------extract cclamp data from SutterPatch data structures EBM 12/26/2018-----------------

Macro autographs_cclamp()
	setdatafolder root:SutterPatch:Data:Analysis
	String cmd1 = "String test = GetBrowserSelection(0)"
	CreateBrowser prompt="Select Analysis Wave", executeMode=1, command1=cmd1
	Duplicate /o $test mydata
	//make time wave, in min
	Duplicate /O /RMD=[][0] mydata, root:sweep_t
	root:sweep_t = root:sweep_t/60 //transform from sec to minutes
	//make membrane potential wave, in mV
	Duplicate /O /RMD=[][3] mydata, root:membrane_potential
	root:membrane_potential = root:membrane_potential*1000 //transform from V to mV
	//make R_input wave in MOhm
	Duplicate /O /RMD=[][5] mydata, root:R_input
	//make firing rate wave in Hz
	Duplicate /O /RMD=[][1] mydata, root:firing_rate
	
	//Make Graphs
	SetDataFolder root:
	Display /W=(900,70,1300,200) firing_rate vs sweep_t
	Label left "Firing Rate (Hz)";DelayUpdate
	Label bottom "Time (min)"
	Display /W=(900,220,1300,350) membrane_potential vs sweep_t
	Label left "Vm (mV)";DelayUpdate
	Label bottom "Time (min)"
	Display /W=(900,370,1300,500) R_input vs sweep_t
	Label left "Input R (MOhm)";DelayUpdate
	Label bottom "Time (min)"
End	

//---------extract vclamp data from SutterPatch data structures EBM 5/18/2019-----------------

Macro autographs_vclamp()
	setdatafolder root:SutterPatch:Data:Analysis
	String cmd1 = "String test = GetBrowserSelection(0)"
	CreateBrowser prompt="Select Analysis Wave", executeMode=1, command1=cmd1
	Duplicate /o $test mydata
	//make time wave, in min
	Duplicate /O /RMD=[][0] mydata, root:sweep_t
	root:sweep_t = root:sweep_t/60 //transform from sec to minutes
	//check if data includes synaptic data or not
	if (mydata[1][7] < 12 || mydata[1][7] > 12)
		//make membrane holding current wave, in pA
		Duplicate /O /RMD=[][9] mydata, root:holding_I
		root:holding_I = root:holding_I*1000000000000 //transform from A to pA
		//make R_series wave in MOhm
		Duplicate /O /RMD=[][5] mydata, root:R_series
		root:R_series = root:R_series/1000000
		//make R_input wave in MOhm
		Duplicate /O /RMD=[][7] mydata, root:R_input
		root:R_input = root:R_input/1000000
	else
		//make membrane holding current wave, in pA
		Duplicate /O /RMD=[][1] mydata, root:holding_I
		root:holding_I = root:holding_I*1000000000000 //transform from A to pA
		//make R_series wave in MOhm
		Duplicate /O /RMD=[][5] mydata, root:R_series
		root:R_series = root:R_series/1000000
		//make R_input wave in MOhm
		Duplicate /O /RMD=[][3] mydata, root:R_input
		root:R_input = root:R_input/1000000
		print "in the clamp only"
	endif
	//Make Graphs
	SetDataFolder root:
	Display /W=(900,70,1300,200) holding_I vs sweep_t
	Label left "I_holding (pA)";DelayUpdate
	Label bottom "Time (min)"
	Display /W=(900,220,1300,350) R_series vs sweep_t
	Label left "R series (MOhm)";DelayUpdate
	Label bottom "Time (min)"
	Display /W=(900,370,1300,500) R_input vs sweep_t
	Label left "R input (MOhm)";DelayUpdate
	Label bottom "Time (min)"
End	

//---------extract synaptic data from SutterPatch data structures EBM 5/18/2019-----------------

Macro autographs_synaptic()
	setdatafolder root:SutterPatch:Data:Analysis
	String cmd1 = "String test = GetBrowserSelection(0)"
	CreateBrowser prompt="Select Analysis Wave", executeMode=1, command1=cmd1
	Duplicate /o $test mydata
	//make time wave, in min
	Duplicate /O /RMD=[][0] mydata, root:sweep_t
	root:sweep_t = root:sweep_t/60 //transform from sec to minutes
	//make amplitude 1 wave in pA
	Duplicate /O /RMD=[][1] mydata, root:ampl1
	root:ampl1 = root:ampl1*1000000000000 //transform from A to pA
	//make amplitude 2 wave in pA
	Duplicate /O /RMD=[][3] mydata, root:ampl2
	root:ampl2 = root:ampl2*1000000000000 //transform from A to pA
	
	//Make Graphs
	SetDataFolder root:
	Display /W=(900,70,1300,200) ampl1 vs sweep_t
	ModifyGraph rgb(ampl1)=(1,4,52428)
	AppendToGraph ampl2 vs sweep_t
	ModifyGraph mode=3, marker=19
	Legend/C/N=text0/A=MC
	Label left "Evoked Postsynaptic Current (pA)";DelayUpdate
	Label bottom "Time (min)"
	
End	

//---------extract iontophoresis amplitude data from SutterPatch data structures EBM 3/15/2020-----------------

Macro autographs_ionto()
	setdatafolder root:SutterPatch:Data:Analysis
	String cmd1 = "String test = GetBrowserSelection(0)"
	CreateBrowser prompt="Select Analysis Wave", executeMode=1, command1=cmd1
	Duplicate /o $test mydata
	//make time wave, in min
	Duplicate /O /RMD=[][0] mydata, root:sweep_t
	root:sweep_t = root:sweep_t/60 //transform from sec to minutes
	//make ionto amplitude wave in pA
	Duplicate /O /RMD=[][1] mydata, root:iontoampl
	root:iontoampl = root:iontoampl*1000000000000 //transform from A to pA
	//make membrane holding current wave, in pA
	Duplicate /O /RMD=[][3] mydata, root:holding_I
	root:holding_I = root:holding_I*1000000000000 //transform from A to pA
	//make R_series wave in MOhm
	Duplicate /O /RMD=[][5] mydata, root:R_series
	root:R_series = root:R_series/1000000
	//make R_input wave in MOhm
	Duplicate /O /RMD=[][7] mydata, root:R_input
	root:R_input = root:R_input/1000000
	//Make Graphs
	SetDataFolder root:
	Display /W=(900,70,1300,200) iontoampl vs sweep_t
	ModifyGraph rgb(iontoampl)=(1,4,52428)
	ModifyGraph mode=3, marker=19
	Legend/C/N=text0/A=MC
	Label left "Iontophoresis Postsynaptic Current (pA)";DelayUpdate
	Label bottom "Time (min)"
	Display /W=(900,220,1300,350) holding_I vs sweep_t
	Label left "I_holding (pA)";DelayUpdate
	Label bottom "Time (min)"
	Display /W=(900,370,1300,500) R_series vs sweep_t
	Label left "R series (MOhm)";DelayUpdate
	Label bottom "Time (min)"
	Display /W=(900,520,1300,650) R_input vs sweep_t
	Label left "R input (MOhm)";DelayUpdate
	Label bottom "Time (min)"
	
End	

//--------------------------------------------------------------------------------
//Macro easyIh_disp()
//	Display /W=(650,70,880,250) root:SutterPatch:Data:R1_S1_IV[][2]
//	AppendToGraph root:SutterPatch:Data:R1_S1_IV[][3]
//	AppendToGraph root:SutterPatch:Data:R1_S1_IV[][4]
//	AppendToGraph root:SutterPatch:Data:R1_S1_IV[][5]
//	AppendToGraph root:SutterPatch:Data:R1_S1_IV[][6]
//	AppendToGraph root:SutterPatch:Data:R1_S1_IV[][7]
//	AppendToGraph root:SutterPatch:Data:R1_S1_IV[][8]
//	AppendToGraph root:SutterPatch:Data:R1_S1_IV[][9]
//End

//--------------------------------------------------------------------------------
