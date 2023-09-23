#pragma rtGlobals=1		// Use modern global access method.

Macro Voltammetry_setup()
	Make /o/n=500 vt_input = 0
	Make /o/n=(500,150) buffer = 0
	Make /o/n=5000 voltage = 0
	Make /o/n=5000 trigger = 0
	Make /o/n=500 volt_disp = 0
	Make /o/n=500 current = 0
	Make /o/n=150 trial
	Variable /g VGainMx = .05
	Variable /g sweep_number = 0
	Variable /g  trial_number = 0
	Variable /g  stop_code
	Variable /g stop_me = 0
	Variable /g sweep_time_0 = 0
	Variable /g tickfreq =58.83
	Variable /g ox_pot = 0.6
	Variable /g red_pot = -.2
	Variable /g isi = 120  //interstim interval in sec
	Variable /g triangle_on = 0
//  The next two lines give the length of the input trace (set to 10 msec, collecting at 5khz)
	SetScale/I x 0,.1,"s", voltage, trigger
	SetScale/I x 0,.01,"s", vt_input, current, volt_disp
//  This defines the voltage waveform... moves from -.4 up to 1.3 and back down.
	voltage = -.4
	voltage[0,250] = -.4+1.7*p/250
	voltage[250,500] = 1.3 - 1.7*(p-250)/250
	//for the Dagan box, multiply the voltage by 5
	voltage=voltage*5
	volt_disp = voltage 
	//voltage *= 10
	trigger[0,10] = 5
//  Delete old and build the new graph
	DoWindow /k Volt
	Volt()	
//  Resets experiment
	Reset("")	
	sweep_time_0 = (ticks/tickfreq)
End

Proc Start_triangle()
	DAQmx_waveformgen /DEV="Dev1"  /nprd=0 "root:voltage,0;root:trigger,1;"
//	DAQmx_waveformgen /DEV="Dev1" /TRIG={"/dev1/ctr0out"} /nprd=0 "root:voltage,0;"
//	DAQmx_ctr_outputpulse /dev="dev1" /npls=0  /sec={.01,.09} 0
End

Function ButtonProc_3(ctrlName) : ButtonControl
	String ctrlName
	NVar triangle_on
	if (triangle_on)
		fDAQmx_waveformstop("dev1")
		triangle_on = 0
		button button3 title="D", font="Symbol",fSize=20
	else
		DAQmx_waveformgen /DEV="Dev1"  /nprd=0 "root:voltage,0;root:trigger,1;"
		triangle_on = 1
		button button3 title="Stop", font="Arial",fSize=12
	endif
End


Function Stop_triangle()
	 fDAQmx_WaveformStop("dev1")
End


Function Stop_volt_clock ()
// Stops counters
	fDAQmx_CTR_Finished("Dev1", 0)
End


Window Volt() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(456,80.75,885.75,488) vt_input
	AppendToGraph/L=curr/B=volts current vs volt_disp
	AppendToGraph/L=analysis_l/B=analysis_b trial
	ModifyGraph cbRGB=(65280,54528,48896)
	ModifyGraph rgb(vt_input)=(0,0,0),rgb(current)=(0,0,0)
	ModifyGraph nticks(analysis_b)=4
	ModifyGraph fSize=10
	ModifyGraph axOffset(left)=-1.71429
	ModifyGraph gridRGB(left)=(65535,65535,65535),gridRGB(bottom)=(65535,65535,65535)
	ModifyGraph gridRGB(curr)=(65535,65535,65535),gridRGB(volts)=(65535,65535,65535)
	ModifyGraph lblPos(left)=48,lblPos(bottom)=37
	ModifyGraph freePos(curr)=0
	ModifyGraph freePos(volts)=-145
	ModifyGraph freePos(analysis_l)=-130
	ModifyGraph freePos(analysis_b)=-145
	ModifyGraph axisEnab(left)={0,0.35}
	ModifyGraph axisEnab(bottom)={0.01,1}
	ModifyGraph axisEnab(curr)={0.5,1}
	ModifyGraph axisEnab(volts)={0.01,0.3}
	ModifyGraph axisEnab(analysis_l)={0.5,1}
	ModifyGraph axisEnab(analysis_b)={0.4,1}
	SetAxis left -200,200
	SetAxis bottom 0,0.01
	SetAxis curr -200,200
	SetAxis volts -1,1.5
	SetAxis analysis_l -10,10
	SetAxis analysis_b 0,150
	ControlBar 70
	Button button0,pos={20,10},size={50,50},proc=Start_volt,title="Start"
	Button button1,pos={80,10},size={60,20},proc=Reset,title="Reset"
	SetVariable setvar0,pos={156,10},size={120,16},title="Oxidation Pot"
	SetVariable setvar0,limits={-0.4,1,0.01},value= ox_pot
	SetVariable setvar1,pos={299,10},size={120,16},title="Redox Pot"
	SetVariable setvar1,limits={-0.4,1,0.01},value= red_pot
	ValDisplay valdisp0,pos={300,50},size={120,14},title="Sweep Number"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #"sweep_number"
	Button button2,pos={80,40},size={60,20},proc=Collect_volt,title="Single"
	Button button3,pos={470,12},size={50,40},proc=ButtonProc_3,title="D"
	Button button3,font="Symbol",fSize=20
	ValDisplay valdisp1,pos={175,50},size={100,14},title="Trial number"
	ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000},value= #"trial_number"
EndMacro

Proc Start_volt(ctrlName) : ButtonControl  //This is the stop/start button
	string ctrlName

// Start DAQ			
	if (stop_code == 0)
		stop_code = 1
		button button0 title="Stop"
		DAQmx_scan /DEV="Dev1" /BKG=1 /TRIG={"/dev1/ctr0out"} /EOSH="collect_volt()" /ERRH="error_v()" WAVES="root:vt_input, 0/RSE, -10,10,"+num2str(1000*VGainMX)+",0;"
		DAQmx_ctr_outputpulse /dev="dev1" /npls=0  /sec={.01,isi-.01} 0
	else
		Stop_volt_clock ()
	//	fDAQmx_ResetDevice("Dev1")
		fDAQmx_Scanstop("Dev1")
		fDAQmx_CTR_Finished("Dev1", 0)
	//	DAQmx_AO_SetOutputs /DEV="dev1" "0, 0;"
		button button0 title="Start"
		stop_code = 0
	endif		
End

function error_v()
print fDAQmx_ErrorString()
end

Proc Reset(ctrlName) : ButtonControl
	String ctrlName
	sweep_time_0 = ticks/tickfreq
	sweep_number = 0
	trial_number = 0
// Stops counter 1
	fDAQmx_CTR_Finished("Dev1", 0)
End

		
Function Collect_volt()
//	String ctrlName
	NVar sweep_number = sweep_number
	NVar trial_number = trial_number
	NVar ox_pot = ox_pot
	NVar red_pot = red_pot
	NVar tickfreq = tickfreq
	NVar VGainMX = VGainMX
	NVar sweep_time_0 = sweep_time_0
	Wave vt_input=vt_input
	Wave current = current	
	Wave buffer = buffer
	string wavesave
	Variable get_interval 

//	This pulls out the current vs voltage trace
	current = vt_input[p]
	smooth 5, current
//	This analyzes the peak-oxidative and peak-reductive positions
	buffer[][sweep_number] = vt_input[p]
	sweep_number +=1
//	Start next acquisition
	if (sweep_number <150)
		DAQmx_scan /DEV="Dev1" /BKG=1 /TRIG={"/dev1/pfi0"}   /EOSH="collect_volt()"/ERRH="error_sweep()" WAVES="root:vt_input, 0/RSE, -10,10,"+num2str(1000*VGainMX)+",0;"	
	else
		sweep_number = -1
		wavesave = "trial"+num2str(trial_number)
		Duplicate /o buffer $wavesave
		note $wavesave, num2str(ticks/tickfreq-sweep_time_0)
		Analyze_trial(trial_number)
		trial_number += 1
		DAQmx_scan /DEV="Dev1" /BKG=1 /TRIG={"/dev1/ctr0out"}   /EOSH="collect_volt()"/ERRH="error_sweep()" WAVES="root:vt_input, 0/RSE, -10,10,"+num2str(1000*VGainMX)+",0;"	
	
	endif
End

Function Analyze_trial(trialnum)
variable trialnum
Wave trial = trial
String trial_name = "trial"+num2str(trialnum)
Make/N=(1,500)/O oxidation = 0
Make /n=500 /o baseline
oxidation[0][190,192] = .25
oxidation[0][193] = .125
oxidation[0][189] = .125
matrixmultiply $trial_name /t, oxidation /t
Wave M_product
trial = M_product[p][0]
variable base = mean(trial,30,40)
trial -= base
trial[0] = 0
duplicate /o $trial_name da_subt
baseline = da_subt[p][30]
da_subt -= baseline[p]
da_subt[][0]=0
MatrixTranspose da_subt
End

