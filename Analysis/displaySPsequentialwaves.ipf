#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"Display sequential SP waves", dialogdispSPwaves()
End

//---------------------------------------------------
function dialogdispSPwaves()
	String datahookforwaves
	Variable startindex = 1
	Variable endindex = 10
	CreateBrowser /M 
	ModifyBrowser /M showmodalbrowser expand=4
	datahookforwaves=S_browserlist
	datahookforwaves = RemoveEnding(datahookforwaves, ";")
	Prompt startindex, "Start wave index:"
	Prompt endindex, "End wave index:" 
	DoPrompt "Enter start and end", startindex, endindex
	Display $datahookforwaves[*][startindex]
	Variable i=startindex
	do
		AppendToGraph $datahookforwaves[*][i]
		i+=1
	while(i<endindex+1)
End