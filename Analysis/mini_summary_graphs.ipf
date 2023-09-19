#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//--------------------------post analysis graph procedures------EBM-----4/13/2020--------------
Menu "Macros"
	"mini event summaries", auto_mini_summ()
End

Macro auto_mini_summ()
	//this version assumes 4 sec of data per sweep, 6 sweeps per minute
	//make timecourse graph of freq with 30 sec bins
	Wavestats /Q mini_times_
	Variable numbins = V_max/(4*3)
	Histogram /B={0,12,numbins} /DEST=mini_freq_timecourse mini_times_
	mini_freq_timecourse = mini_freq_timecourse/12
	SetScale/P x 0,0.5,"", mini_freq_timecourse
	Display mini_freq_timecourse
	ModifyGraph mode=3, marker=16
	SetAxis left 0,*
	Label left "Event Frequency (Hz)"
	Label bottom "Time (min)"
	
	//make graph of amps and times vs event number
	Display /W=(500,0,800,300) mini_amps_
	ModifyGraph mode = 2
	AppendToGraph mini_times_
	Label left "event ampl (pA) and time (s)"
	Label bottom "Event Number"
End