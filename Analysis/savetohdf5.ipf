#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"Export to HDF5", grapheddatatohdf5()
	"Export to TXT", grapheddatatotxt()
End

Function grapheddatatohdf5()
	//HDF5 file of each wave in the active graph will be generated in the 
	//same directory as the current pxp file
	//Add NWB type information to the metadata
	//Get list of waves in the graph
	string mywavelist = tracenamelist("",";", 1)
	//can set a different directory with the following:
	//NewPath /O currentpath, "Macintosh HD:Users:elyssamargolis:Desktop:"
	variable nwaves = ItemsInList(mywavelist)
	variable i
	for (i=0;i<nwaves;i+=1)
		Variable fileID
		String thiswavetemp = GetWavesDataFolder(WaveRefIndexed("", i, 1), 2) 
		String thiswavename = StringFromList(i, mywavelist)
		String savefilename = IgorInfo(1) + thiswavename + ".h5"
		HDF5CreateFile /O/P=home fileID as savefilename
   	duplicate /O $thiswavetemp thiswave
   	HDF5saveData /A="" /IGOR=-1 thiswave, fileID
   	HDF5closeFile fileID
   endfor
End

Function grapheddatatotxt()
	//generate simple .txt file, wave to list, in the 
	//same directory as the current pxp file
	//No metadata included in this format
	//Get list of waves in the graph
	string mywavelist = tracenamelist("",";", 1)
	//can set a different directory with the following:
	//NewPath /O currentpath, "Macintosh HD:Users:elyssamargolis:Desktop:"
	variable nwaves = ItemsInList(mywavelist)
	variable i
	for (i=0;i<nwaves;i+=1)
		Variable fileID
		String thiswavetemp = GetWavesDataFolder(WaveRefIndexed("", i, 1), 2) 
		String thiswavename = StringFromList(i, mywavelist)
		String savefilename = IgorInfo(1) + thiswavename + ".txt"
   	duplicate /O $thiswavetemp thiswave
   	Save/O/G/M="\n"/DLIM=","/W /P=home thiswave as savefilename
   endfor
End