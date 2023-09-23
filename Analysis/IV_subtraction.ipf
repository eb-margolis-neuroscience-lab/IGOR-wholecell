#pragma rtGlobals=1		// Use modern global access method.
//process IV data and create plots from ramp data collected with Acquisition 4
//EBM 5/21/11

Menu "Macros"
	"IV Ramp Setup 4",IVSub4()
end

function IVSub4()
setdatafolder root:acquisition:data:
	string /G controltrace
	string /G effecttrace
	string waveprefix_base
	variable namelength_base
	string waveprefix_drug
	variable namelength_drug
	variable namelength
	IVRamps_promptnew(controltrace,effecttrace)
	duplicate /O $effecttrace, diffwave
	duplicate /O $effecttrace, temp_effect
	duplicate /O $controltrace, temp_control
	duplicate /O temp_effect, V_for_ramp
	deletepoints 0,32000, diffwave, temp_effect, temp_control
	deletepoints 40000, 8000, diffwave, temp_effect, temp_control
	diffwave=temp_effect-temp_control
	duplicate /O temp_effect, V_for_ramp
	//V_for_ramp = p/62
	V_for_ramp = -40
	V_for_ramp -= p*(100/numpnts(diffwave))
	namelength_drug=strlen(effecttrace)
	namelength_base=strlen(controltrace)
	waveprefix_drug=effecttrace[0,namelength_drug-7]
	waveprefix_base=controltrace[0,namelength_base-7]
	if (waveexists ($("processed_"+waveprefix_base)))
		killwaves $("processed_"+waveprefix_base)
	endif
	if (waveexists ($("processed_"+waveprefix_drug)))
		killwaves $("processed_"+waveprefix_drug)
	endif
	if (waveexists ($("diff_"+waveprefix_drug)))
		killwaves $("diff_"+waveprefix_drug)
	endif
	movewave temp_control $("processed_"+waveprefix_base)
	movewave temp_effect $("processed_"+waveprefix_drug)
	Display /W=(260,400,490,600) $("processed_"+waveprefix_base) vs V_for_ramp; AppendtoGraph $("processed_"+waveprefix_drug) vs V_for_ramp
	ModifyGraph zero(left)=1
	Label left,"Current (pA)"
	Label bottom,"Voltage (mV)"
	ModifyGraph rgb($("processed_"+waveprefix_drug))=(1,12815,52428)
	//Legend/C/N=text0/J/F=0/A=MC "\\s($("processed_"+waveprefix_base)) baseline\r\\s($("processed_"+waveprefix_drug)) drug"
	//DoWindow /C IV_Ramp_DATA
	movewave diffwave $("diff_"+waveprefix_drug)
	Display /W=(160,400,390,600) $("diff_")+waveprefix_drug vs V_for_ramp
	ModifyGraph zero(left)=1
	Label left,"Current (pA)"
	Label bottom,"Voltage (mV)"
end

function IVRamps_promptnew(control_trace_local,effect_trace_local)
	string control_trace_local
	string effect_trace_local
	Svar controltrace
	Svar effecttrace
	prompt control_trace_local, "Choose control current IV ramp trace",popup,Wavelist("*",";","")
	prompt effect_trace_local, "Choose effect current IV ramp trace",popup,Wavelist("*",";","")
	doprompt "choose traces",control_trace_local, effect_trace_local
	controltrace=control_trace_local
	effecttrace=effect_trace_local
end