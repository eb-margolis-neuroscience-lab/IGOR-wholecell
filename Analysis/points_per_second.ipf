#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"Timecourse point per sec", pps_function()
End

function pps_function()  		//Assumes first sweep is numbered "1", and 
													//no sweep numbers are missing												
	Variable numsweeps=0
	String swpname
	Variable exptlength	//number of sweeps collected
	Variable pointspersweep
	Variable samplingrate
	Variable secs_per_sweep
	Variable sweepexists=1
	Variable interval_start
	Variable interval_end
	Variable pps_index = 0
//	Wave holding_i
//	Wave sweep_t
	Variable i = 0
	if (DataFolderExists("root:acquisition:data"))						
//		setdatafolder root:acquisition:data
//		exptlength=numpnts(holding_i)
	elseif (DataFolderExists("root:wholecell"))
//		setdatafolder root:wholecell
//		exptlength = numpnts(root:wholecell:holding_i)
	elseif (DataFolderExists("root:SutterPatch"))
		String datahookforwaves
		String promptstr = "choose raw data wave"
		CreateBrowser /M prompt=promptstr
		ModifyBrowser /M showmodalbrowser expand=4
		datahookforwaves=S_browserlist
		datahookforwaves = RemoveEnding(datahookforwaves, ";")
		pointspersweep = DimSize($datahookforwaves, 0)
		exptlength = DimSize($datahookforwaves, 1)
		samplingrate = 1/DimDelta($datahookforwaves, 0)
		secs_per_sweep = pointspersweep/samplingrate
		String datahookfortimestamps
		String promptstr2 = "choose analysis wave for time data"
		CreateBrowser /M prompt=promptstr2
		ModifyBrowser /M showmodalbrowser expand=4
		datahookfortimestamps=S_browserlist
		datahookfortimestamps = RemoveEnding(datahookfortimestamps, ";")
	endif
//for SutterPatch
	Make /O /N=(exptlength*secs_per_sweep, 2) pointpersec_wave    //first column is time, second column is value
	Duplicate /O /RMD=[][0] $datahookfortimestamps, sweep_t_temp
	Variable current_time_val
	do
		Variable j=0
		do
			interval_start = j*samplingrate+1
			j+=1
			interval_end = j*samplingrate
			current_time_val = sweep_t_temp[i]+j*0.01667
			duplicate /O /R=[interval_start,interval_end][i] $datahookforwaves, currentdatasnip
			wavestats /Q currentdatasnip
			pointpersec_wave[pps_index][1] = current_time_val
			pointpersec_wave[pps_index][0] = V_avg
			pps_index+=1
		while (j < secs_per_sweep)
		i+=1
	while (i < exptlength)
	KillWaves currentdatasnip, sweep_t_temp
	Display pointpersec_wave[][0] vs pointpersec_wave[][1]
	Label left, "Holding, point per sec"
	Label bottom, "Time (min)"
	saveexperiment 
end
