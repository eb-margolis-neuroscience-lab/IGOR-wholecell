#pragma rtGlobals=1		// Use modern global access method.
#include <Strings as Lists>

Menu "Macros"
	"Average + SEM", CalculateAveSEM()
End

//------------------------------------------------------------	

Macro CalculateAveSEM ()
	variable points
	string/g ave_name = "mydata"
	Variable/G anal_type = 1
	Variable/G makeavesemgraph
	newpanel /N=mean_sem_window /W=(300, 100, 540, 280) /K=1
	CheckBox radiobutgraph,pos={32,25},size={78,15},title="Waves From Graph",value= 1, mode=1,proc=analyze_select
	CheckBox radiobutseq,pos={32,45},size={78,15},title="Select Sequential Waves",value= 0, mode=1,proc=analyze_select
	CheckBox makegraphchkbox,pos={32,75},size={78,15},title="Display graph of results",value= 1, live=1, variable = makeavesemgraph
	SetVariable outputprefixinput, pos={15, 105}, size={200,15}, value=ave_name, title="Prefix for output:", live=1
	Button avesemgo_button, pos={30, 140}, size={80,20}, proc=startavesemanal, title="Do it"
	Button avesemcancel_button, pos={120, 140}, size={80,20}, proc=cancelavesemanal, title="Cancel"
endmacro  

Function names_from_graph()  	
	String theTrace
	String traces=TraceNameList("", ";", 1)    		// makes string that contains all wavenames
	NVar makeavesemgraph
	Svar ave_name
	theTrace = GetStrFromList(traces, 1, ";")
	if (waveexists($theTrace)==0)
		String folderwarning = "Change active folder and try again"
		DoAlert /T="warning" 0, folderwarning
		KillWindow mean_sem_window
		Killwaves/Z Ave_W, SEM_W
		Killvariables/Z anal_type, makeavesemgraph
		Killstrings/Z ave_name
		Abort
	elseif (DataFolderExists("root:SutterPatch"))
		String SPwarning = "Not configured for SutterPatch"
		Setdatafolder root:SutterPatch:Data
		DoAlert /T="warning" 0, SPwarning
		Abort
	endif
	ave_sem_fromlist(traces)
end

function names_seq_waves()
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
			else
				AppendToGraph $datahookforsweeps[*][k]
			endif
			Duplicate/O /RMD=[][k] $datahookforsweeps $thisTrace
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
	ave_sem_fromlist(traces)
end

function ave_sem_fromlist(listnames)
	String listnames
	String traces = listnames
	String theTrace="alpha"//placeholder
	String wNm
	Svar ave_name
	Nvar gSelectedRadioButton
	String avetemp = ave_name + "_ave"
	String semtemp = ave_name + "_sem"
	String inputname
	if (gSelectedRadioButton == 1)
		inputname = "" //from graph
	else
		inputname = "sweep" //assumed sweeps
	endif
	Variable prefixLen=strlen(inputname)
	Variable i=0
	Variable length=0
	Variable templength = 0
	NVAR makeavesemgraph
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
	Duplicate /O Ave_W $avetemp
	Duplicate /O SEM_W $semtemp
	Killwaves/Z Ave_W, SEM_W
	Killvariables/Z anal_type, makeavesemgraph
	Killstrings/Z ave_name
	if (makeavesemgraph == 1)
		make_avesem_graph(avetemp, semtemp)
	endif
end

Function analyze_select(cb) : CheckBoxControl
	STRUCT WMCheckboxAction& cb
	
	switch(cb.eventCode)
		case 2:		// Mouse up
			HandleRadioButtonClick(cb.ctrlName)
			break
	endswitch

	return 0
End

static Function HandleRadioButtonClick(controlName)
	String controlName
	NVAR anal_type

	strswitch(controlName)
		case "radiobutgraph":
			anal_type = 1
			break
		case "radiobutseq":
			anal_type = 2
			break
	endswitch
	CheckBox radiobutgraph, value = anal_type==1
	CheckBox radiobutseq, value = anal_type==2
End

function setanalsource(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	Nvar anal_type
	if (popNum == 1)
		anal_type = 1
	else
		anal_type = 2
	endif
End

function startavesemanal(ctrlName) : ButtonControl
	String ctrlName 
	NVAR anal_type 
	if (anal_type == 1)
		names_from_graph()
	else
		names_seq_waves()
	endif
	KillWindow mean_sem_window
end

function cancelavesemanal(ctrlName) : ButtonControl
	String ctrlName 
	KillWindow mean_sem_window
end

function make_avesem_graph(ave_name, sem_name)
	String ave_name
	String sem_name
	Display $ave_name
	ModifyGraph rgb=(0,0,0)
	ErrorBars $ave_name SHADE= {0,0,(0,43690,65535,32768),(0,0,0,0)},wave=($sem_name, $sem_name)
end