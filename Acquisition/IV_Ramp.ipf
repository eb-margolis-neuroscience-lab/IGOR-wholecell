#pragma rtGlobals=1		// Use modern global access method.

Menu "Macros"
	"IV Ramp Setup",IV_ramp_setup()
	"IV Ramp Subtraction",IV_Ramp_Subtraction()
end

Macro IV_ramp_setup()
	newdatafolder /o root:IV
	Make /o/n=5000 iv_input = 0
	Make /o/n=100 step = 0
	Make /o/n=100 voltage, current
	current = 0
//  This next line gives the holding potentials for the individual steps
	voltage = p -140
//  The next two lines give the length of the input trace (initially set to 4 second)
	SetScale/I x 0,4,"s", step
	SetScale/I x 0,4,"s", iv_input
//  The next line sets the default holding potential -- can be interactively changed
	variable /g starting_v = -60
	newdatafolder /o root:IV
	DoWindow /k IV_ramp
	IV_ramp()	
End

Window IV_ramp() : Graph
	PauseUpdate; Silent 1		// building window...
	setdatafolder root:wholecell:
	Display /W=(223.5,53.75,493.5,365.75) iv_input
	AppendToGraph/L=curr/B=volts current vs voltage
	ModifyGraph lblPos(left)=48,lblPos(bottom)=37
	ModifyGraph freePos(curr)=0
	ModifyGraph freePos(volts)=-128
	ModifyGraph axisEnab(left)={0,0.4}
	ModifyGraph axisEnab(curr)={0.55,1}
	SetAxis volts -140,-40 
	ControlBar 40
	Button button0,pos={15,15},size={50,20},proc=Start_ivramp,title="Start"
	Button button1,pos={255,15},size={70,20},proc=Start_save,title="Save data"
	SetVariable setvar0,pos={80,15},size={130,18},title="Starting Vm"
	SetVariable setvar0,limits={-100,40,5},value= starting_v
EndMacro

Proc Start_ivramp(ctrlName) : ButtonControl
	string ctrlName
//  This defines the voltage ramp... moves from -40 down to -140
	step[15,90] = (-40 - starting_v) / 20
	step[40,90] -= (p-40)*5/50
	Single_clock()	
	fnidaq_waveformgen(1,"step, 0;",32)
	fnidaq_scanwaves(1,1,"iv_input,0",0)
	iv_input *= 200
	variable step_mean = 0
	current = 0
	do
		current += iv_input[4500-step_mean-25*p]
		step_mean += 1
	while (step_mean < 25)
	current /=25
End

Proc Start_save(ctrlName) : ButtonControl
	string ctrlName
	Copy_ramps()
End

Proc Copy_ramps(new_name)
	string new_name = ""
	prompt new_name, "Prefix for waves:"
	duplicate /o current root:IV:$(new_name+"_i")	//save waves in IV folder EBM 6/7/01
	duplicate /o voltage root:IV:$(new_name+"_v")
	duplicate /o iv_input root:IV:$(new_name+"_input")
End

//---------------------------------Automation of IV comparison and subtration---EBM 6/7/01-----------------

function IV_Ramp_Subtraction()
setdatafolder root:IV:
	string /G controltrace
	string /G effecttrace
	string waveprefix
	variable namelength
	IVRamps_prompt(controltrace,effecttrace)
	print controltrace
	duplicate /O $effecttrace, processedwave
	duplicate /O $effecttrace, temp_effect
	duplicate /O $controltrace, temp_control
	namelength=strlen(effecttrace)
	waveprefix=effecttrace[0,namelength-3]
	processedwave=-(temp_effect-temp_control)
	if (waveexists ($("processed_"+waveprefix)))
		killwaves $("processed_"+waveprefix)
	endif
	movewave processedwave $("processed_"+waveprefix)
	Display /W=(260,400,490,600) $("processed_"+waveprefix) vs $(waveprefix+"_v")
	//Modifygraph height=150, width=150
	ModifyGraph zero(left)=1
	Label left,"Current (pA)"
	Label bottom,"Voltage (mV)"
	DoWindow /C IV_Ramp_DATA
	killwaves temp_effect, temp_control
	setdatafolder root:wholecell
end

function IVRamps_prompt(control_trace_local,effect_trace_local)
	string control_trace_local
	string effect_trace_local
	Svar controltrace
	Svar effecttrace
	prompt control_trace_local, "Choose control current IV ramp trace",popup,Wavelist("*",";","")
	prompt effect_trace_local, "Choose effect current IV ramp trace",popup,Wavelist("*",";","")
	doprompt "choose traces",control_trace_local, effect_trace_local
	controltrace=control_trace_local
	effecttrace=effect_trace_local
	print controltrace
end