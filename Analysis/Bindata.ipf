#pragma rtGlobals=1		// Use modern global access method.

//-----------------------Bin one wave---------------
//Revised 5/19/2020----EBM-----

Menu "Macros"
	"Bin data", BinData()
End

Macro BinData()
	if (DataFolderExists("root:acquisition:data"))						
		setdatafolder root:acquisition:
	endif
	if (DataFolderExists("root:wholecell"))
		setdatafolder root:
	endif
	if (DataFolderExists("root:SutterPatch"))
			setdatafolder root:
	endif
	string datahookforbins
	Variable orig_scaling
	string/G newwavename=""
	variable/G ptsperbin=3
	if (DataFolderExists("root:SutterPatch"))
		if (WaveExists(root:Sweep_t) == 0)
			DoAlert /T="warning" 0, "Run 'Output Graphs' Macro first"
			Abort
		endif
	endif
	CreateBrowser /M 
	ModifyBrowser /M showmodalbrowser expand=4
	datahookforbins=S_browserlist
	datahookforbins = RemoveEnding(datahookforbins, ";")
	getbinconfigvals()
	make /o/n=(round(dimsize($datahookforbins,0)/ptsperbin)) $newwavename
	duplicate /O $datahookforbins temp_wave
	$newwavename = 0
	variable step = 0
	do
		$newwavename += temp_wave[ptsperbin*p+step]
		step += 1
	while (step < ptsperbin)
	$newwavename /= ptsperbin
	orig_scaling = getorigwavescaling() 
	SetScale /P x 0,orig_scaling*ptsperbin, "", $newwavename
	killwaves temp_wave
	Display $newwavename
end

function getbinconfigvals()
	Nvar ptsperbin
	Svar newwavename
	variable num_temp = 3
	String string_temp
	Prompt num_temp, "Number of points per bin: "
	Prompt string_temp, "Save wave as: "
	DoPrompt "Bin wave variables", num_temp, string_temp
	ptsperbin = num_temp
	newwavename = string_temp
end

function getorigwavescaling()
	Variable tempintervals
	Variable i
	Variable exptlength
	Wave sweep_t
	Variable orig_scaling
	if (DataFolderExists("root:acquisition:data"))						
		setdatafolder root:acquisition:
		tempintervals = sweep_t[21] - sweep_t[2]   //calc scaling based on sweep_t wave
		orig_scaling=tempintervals/18
	elseif (DataFolderExists("root:wholecell"))
		setdatafolder root:
		tempintervals = sweep_t[21] - sweep_t[2]   //calc scaling based on sweep_t wave
		orig_scaling=tempintervals/18
	elseif (DataFolderExists("root:SutterPatch"))
			setdatafolder root:
			tempintervals = sweep_t[21] - sweep_t[2]   //calc scaling based on sweep_t wave
			orig_scaling=tempintervals/18
	endif
	return orig_scaling
end	