#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//-----------------------reanalyze sweeps to graph timecourse of mean per sweep--------------- 8/19/2016-----EBM-------
//Revised 10/09/2022----EBM-----

Menu "Macros"
	"Timecourse of sweep means", sweepmeantimecourse()
End

function sweepmeantimecourse()  		//Assumes first sweep is numbered "1", and 
													//no sweep numbers are missing.	
	Variable exptlength			
	Variable numsweeps=0
	String swpname
	Variable sweepexists=1
	Wave holding_i
	Wave sweep_t
	Variable i = 1												
	String SPwarning = "Not configured for SutterPatch"
	if (DataFolderExists("root:acquisition:data"))						
		setdatafolder root:acquisition:data
		exptlength=numpnts(root:acquisition:holding_i)
	elseif (DataFolderExists("root:wholecell"))
		setdatafolder root:wholecell
		exptlength = numpnts(root:wholecell:holding_i)
	elseif (DataFolderExists("root:SutterPatch"))
		DoAlert /T="warning" 0, SPwarning
		Abort
	endif
	Make /O /N=(exptlength) revisedtimecourse
	do
		swpname="sweep"+num2istr(i)
		Duplicate /O $swpname, currentsweep
		wavestats /Q currentsweep
		revisedtimecourse[i] = V_avg
		i+=1
	while (i<exptlength)
	Killwaves currentsweep
	if (DataFolderExists("root:acquisition:data"))		
		if (WaveExists(root:acquisition:revisedtimecourse))
			KillWaves root:acquisition:revisedtimecourse
		endif		
		MoveWave revisedtimecourse, root:acquisition:
		setdatafolder root:acquisition:
	elseif (DataFolderExists("root:wholecell"))
		if (WaveExists(root:revisedtimecourse))
			KillWaves root:revisedtimecourse 
		endif	
		MoveWave revisedtimecourse, root:
		setdatafolder root:
	endif
	displayrevisedtimecoursegraph()
	saveexperiment
end

function displayrevisedtimecoursegraph()
	Wave revisedtimecourse, sweep_t
	Display revisedtimecourse vs sweep_t
	Label left, "Holding Potential (mV)"
	Label bottom, "Time (min)"
end
