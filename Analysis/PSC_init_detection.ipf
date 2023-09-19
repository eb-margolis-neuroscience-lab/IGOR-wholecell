#pragma rtGlobals=1		// Use modern global access method.
#include <Strings as Lists>

Menu "Macros"
	"PSC initiation time", FindPSC_init()
End

//------------------------------------------------------------	
//configured for SutterPatch only, EBM 8/7/2020 

Function FindPSC_init()
	variable points
	String/G avename = "PSC_init_ave"
	String/G semname = "PSC_init_sem"
	Variable/G anal_type = 1
	Variable/G makeavesemgraph
	if (DataFolderExists("root:acquisition:data"))		
		setdatafolder root:acquisition:data
	elseif (DataFolderExists("root:wholecell"))
		setdatafolder root:wholecell
	elseif (DataFolderExists("root:SutterPatch"))
		String datahookforsweeps
		CreateBrowser /M 
		ModifyBrowser /M showmodalbrowser expand=4
		datahookforsweeps=S_browserlist
	endif
	String traces, temp
	Variable startwavenum, endwavenum
	Prompt startwavenum, "Starting sweep number: "
	Prompt endwavenum, "Last sweep number: "
	DoPrompt "Enter start and end sweep numbers", startwavenum, endwavenum
	Variable j = 1
	Variable k = startwavenum + 1
	String thisTrace
	String inputname = "sweep" //assuming a wave prefix
	if (DataFolderExists("root:SutterPatch"))
		datahookforsweeps = RemoveEnding(datahookforsweeps, ";")
		temp = inputname + num2str(startwavenum)
		do 
			traces = AddListItem(inputname + num2istr(k), temp, ";", 999)
			temp = traces
			thisTrace = GetStrFromList(traces, j, ";")
			if (j == 1)
				Display $datahookforsweeps[*][k]
				SetAxis bottom 0.79, 0.815
			else
				AppendToGraph $datahookforsweeps[*][k]
			endif
			Duplicate/O /RMD=[][j] $datahookforsweeps $thisTrace
			j += 1
			k += 1
		while(k <= endwavenum)		
	endif
	Variable prefixLen=strlen(inputname)
	Variable i=0
	Variable length=0
	String sweepname
	j = 1
	temp = inputname + num2str(startwavenum)
	k = startwavenum + 1
	do 
		sweepname = inputname + num2istr(k)
		traces = AddListItem(sweepname, temp, ";", 999)
		temp = traces
		if (j == 1 && DataFolderExists("root:SutterPatch")==0)
				Display $sweepname
		elseif (DataFolderExists("root:SutterPatch")==0)
				AppendToGraph $sweepname
		endif
		j += 1
		k += 1
	while(k <= endwavenum)
	//make the average graph
	avgfromlist_PSCinit(traces)
	Display /W=(50, 50, 400, 400) $avename
	ModifyGraph rgb=(0,0,0)
	ErrorBars $avename SHADE= {0,0,(0,43690,65535,32768),(0,0,0,0)},wave=($semname, $semname)
	//add the derivative
	String diffname = avename + "dif"
	Differentiate $avename/D=$diffname
	AppendtoGraph /R $diffname
	//add the cursors and legend
	ShowInfo
	Cursor A, $avename, 0.8 
	Legend/C/N=text0/A=MC /Y=40
	//fix axes ranges
	SetAxis bottom 0.79, 0.815
	Wavestats /Q /R=(0.72, 0.9) $avename
	SetAxis Left V_min, V_max
	Wavestats /Q /R=(0.72, 0.9) $diffname
	SetAxis Right V_min, V_max
End

function avgfromlist_PSCinit(listnames)
	String listnames
	print listnames
	String traces = listnames
	String theTrace="alpha"//placeholder
	String wNm
	Svar avename
	Svar semname
	String inputname = "sweep" //assumed sweeps
	Variable prefixLen=strlen(inputname)
	Variable i=0
	Variable length=0
	Variable templength = 0
	do
   		theTrace = GetStrFromList(traces, i, ";")
      	if (strlen(theTrace) == 0)
			break
		endif
		if (strlen(theTrace)>0)
			templength = max(numpnts($theTrace),length)
			length = templength
		endif
		i += 1
	while(1)
	theTrace = GetStrFromList(traces, 1, ";")
	Make/o/n=(length) Ave_W, SEM_W, num_w
	setscale /p x, leftx($theTrace),deltax($theTrace), Ave_W, SEM_W, num_w
	Ave_W = 0
	SEM_W = 0
	num_w = 0
	i=0
	do
      	theTrace = GetStrFromList(traces, i, ";")
		if (strlen(theTrace) == 0)
			break
		endif
		Wave w = $theTrace
		wNm = NameOfWave(w)
		if (cmpstr(wNm[0,prefixLen-1], inputname)==0)
			Ave_W [0,numpnts(w)-1]  += w
			num_w [0,numpnts(w)-1] += 1
			SEM_W [0,numpnts(w)-1] += w^2
		endif
		i += 1
	while(1)
	SEM_W -= (Ave_W^2)/num_w
	Ave_W /= num_w
	SEM_W /= (num_w-1)
	SEM_W = sqrt(SEM_W)
	SEM_W /= sqrt(num_w)
	Duplicate /O Ave_W $avename
	Duplicate /O SEM_W $semname
	Killwaves/Z Ave_W, SEM_W
end