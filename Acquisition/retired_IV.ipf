#pragma rtGlobals=1		// Use modern global access method.
//  This is a procedure to do input-output curves.  You must have  DAC0OUT connected to the External 
//  Command on the back of your  Axopatch and the External Command Sensitivity Switch set to 20 mv/V
//  See remarks below for configuring step size, etc.
//  The macro copy_waves duplicates all waves to a new prefix so you can save multiple IV curves

//Updated 2/8/01	EBM
//added	single/manual sweeps
//		save and close button
//		save in IV data folder

Macro IV_setup()
	Make /o/n=1000 iv_0 = 0
	Make /o/n=10 step
	Make /o/n=8 voltage, current
	current = 0
//  This next line gives the holding potentials for the individual steps
	voltage = {-120,-110,-100,-90,-80,-70,-60,-40}
//  The next two lines give the length of the input trace (initially set to 2 seconds)
	SetScale/I x 0,3,"s", step
	SetScale/I x 0,3,"s", iv_0
	//duplicate /o iv_0 iv_1 iv_2, iv_3, iv_4, iv_5, iv_6, iv_7
//  The next line sets the default holding potential -- can be interactively changed
	variable /g starting_v = -75
	variable /g step_v=-130
	newdatafolder /o root:IV
	DoWindow /k IV_curve
	IV_curve()	
End

Window IV_curve() : Graph
	PauseUpdate; Silent 1		// building window...
	setdatafolder root:wholecell:
	Display /W=(223.5,53.75,493.5,365.75) iv_0 //, iv_1, iv_2, iv_3, iv_4, iv_5, iv_6, iv_7
	AppendToGraph/L=curr/B=volts current vs voltage
	ModifyGraph lblPos(left)=48,lblPos(bottom)=37
	ModifyGraph freePos(curr)=0
	ModifyGraph freePos(volts)=-128
	ModifyGraph axisEnab(left)={0,0.4}
	ModifyGraph axisEnab(curr)={0.55,1}
	ControlBar 80
	Button button0,pos={15,15},size={70,20},proc=Start_iv,title="Start"
	Button buttonsingle,pos={12,45},size={80,20},proc=single_iv,title="Single step"
	SetVariable setvar0,pos={100,18},size={140,18},title="Starting Vm"
	SetVariable setvar0,limits={-100,40,5},value= starting_v
	SetVariable individstepval,pos={100,38},size={140,18},title="Step Vm for single"
	setvariable individstepval,limits={-200,80,10},value=step_v
	button buttonsaveclose,pos={253,15},size={100,40},proc=save_close,title="Save & Close"
EndMacro

Proc Start_iv(ctrlName) : ButtonControl
	string ctrlName
	string input_string
	string input_string_too
	variable step_number = 0
	variable delay_ticks=0
	Do
		if(step_number>0)
			input_String_too="iv_"+num2str(step_number)
			duplicate /o iv_0 $input_String_too
			Appendtograph $input_String_too
		endif
		input_string = "iv_"+num2str(step_number)+",0,1;"
		step[1,6] = (voltage[step_number] - starting_v) / 20	
		fnidaq_waveformgen(1,"step, 0;",32)
		fnidaq_scanwaves(1,1,input_string,0)
		$("iv_"+num2str(step_number)) *= 100
		current[step_number] = mean($("iv_"+num2str(step_number)), 1,1.2) - mean($("iv_"+num2str(step_number)), 0.1,0.2)
		delay_ticks = ticks
		do
		while(ticks<delay_ticks+240)
		step_number += 1
	While (step_number < 8)
End

Proc single_iv(ctrlName) : ButtonControl
	string ctrlName
	string input_string
	string input_String_too
	variable step_number=0
	do
		input_string_too = "iv_"+num2str(step_number)
		step_number+=1
	while (waveexists($input_string_too))
	step_number-=1
	input_string_too = "iv_"+num2str(step_number)
	duplicate /o iv_0 $input_string_too
	input_string = "iv_"+num2str(step_number)+",0,1;"
	step[1,6] = (step_v - starting_v) / 20	
	fnidaq_waveformgen(1,"step, 0;",32)
	fnidaq_scanwaves(1,1,input_string,0)
	$(input_String_too)*= 100
	current[step_number] = mean($("iv_"+num2str(step_number)), 1,1.2) - mean($("iv_"+num2str(step_number)), 0.1,0.3)
	step_number += 1
	Appendtograph $input_string_too
end

Proc save_close(ctrlName) : ButtonControl
	string ctrlName
	variable step_number=0
	string input_String_too
	copy_waves()
	DoWindow /k Iv_curve 
end

Macro Copy_waves(new_name)
	string new_name = ""
	prompt new_name, "Prefix for waves:"
	variable step_number = 0
	string input_string_too
	input_string_too="iv_"+num2str(step_number)
	do
		movewave $("iv_"+num2str(step_number)) root:IV:$(new_name+"_iv"+num2str(step_number))
		step_number += 1
		input_string_too="iv_"+num2str(step_number)
	while (waveexists($input_String_too))
	movewave current root:IV:$(new_name+"_i")
	movewave voltage root:IV:$(new_name+"_v")
End