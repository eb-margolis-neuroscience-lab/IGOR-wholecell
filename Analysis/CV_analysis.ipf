#pragma rtGlobals=1		// Use modern global access method.

Menu "Macros"
	"ISI CV", ISIcv()
end


Macro CVAnalysis(in_wave,startsweep, numsweeps)
                  string in_wave="ampl"
                  variable startsweep = 0
                  variable numsweeps = 20
                  prompt in_wave, "Analyze which wave?"
                  prompt startsweep, "first sweep number"
                  prompt numsweeps, "number of sweeps to analyze"
                  Curvefit  /q line  $in_wave[startsweep, startsweep+numsweeps] /D
                  Wavestats /q/r=(startsweep, startsweep+numsweeps) $in_wave
                  print "Drift = "+num2str(abs(2000*W_coef[1]/W_coef[0])) +" %"
                  Print "CV = "+num2str(V_sdev / V_avg)
                  Print "Quantal content ~ "+num2str(V_avg^2/V_sdev^2)
                  Print "Quantal amplitude ~ "+num2str(V_sdev^2 / V_avg)
end

Macro ISIcv()
	//setdatafolder root:acquisition:data
	Variable /G anal_length
	anal_length=100
	NewPanel /W=(350,100,600,200)
	DoWindow /C ISIcv_Options
	Popupmenu popupstartsweep, proc=ISIcvassignwavepopup, title="First sweep: ", value=WaveList("*",";","")
	Popupmenu popupstartsweep, pos={20,10}
	Button okaybuttonISIcv, pos={30, 70}, proc=button_okay_ISIcv, title="Okay", size={60, 20}
	Button  closebuttonISIcv, pos={130, 70}, proc=buttonkill_ISIcv, title="Cancel", size={60,20}
end	
	
function ISIcv_calc()
	variable i //ISI calc wave index
	variable j //index for scanning each sweep
	variable k  //index for sweep numbers
	variable scale
	variable currsweepnum
	variable startsweepnum
	nvar anal_length
	variable input_resist
	variable baseline_V
	variable start
	variable endtime
	variable sweeppts
	variable sd_wave
	variable avg_wave
	variable temp_avg
	variable temp_sd
	variable stop
	anal_length=100
	stop=0
	svar startsweep
	string swpname
	Make /O /N=100 ISIwave
	i=0
	sscanf startsweep, "sweep%f", startsweepnum
	k=startsweepnum
	swpname="sweep"+num2str(k)
	Duplicate /O $swpname, currentsweep
	scale= deltax(sweep1) 
	wavestats /Q currentsweep
	sd_wave=V_sdev
	avg_wave=V_avg
	sweeppts=V_npnts
	j=0
	do
		j+=1
	while (currentsweep[j]<4*sd_wave+avg_wave)
	wavestats /Q /R=[j-10,j+20] currentsweep //find start of lSI
	start=V_maxloc
	j+=20 //test this
	do
		do
			j+=1
		while (currentsweep[j]<(V_max-10) && j<=sweeppts)
		if ( j<sweeppts)
			wavestats /Q /R=[j-10,j+20] currentsweep  //find end of ISI
			endtime=V_maxloc		
			j+=20  //test this
			ISIwave[i]=endtime-start
			i+=1
			start=endtime
		else
			k+=1
			swpname = "sweep"+num2str(k)
			Duplicate /O $swpname, currentsweep
			wavestats /Q currentsweep
			sd_wave=V_Sdev
			avg_wave =V_avg
			sweeppts=V_npnts
			j=0
			do
				j+=1
			while (currentsweep[j]<4*sd_wave+avg_wave && j<=sweeppts)
			wavestats /Q /R=[j-10,j+20] currentsweep //find start of lSI
			start=V_maxloc
			j+=20 //test this
			do
				j+=1
				if (j>=sweeppts)
					stop=1
					break
				endif
			while (currentsweep[j]<4*sd_wave+avg_wave)
			if (stop==1)
				break
			endif
		endif
		if (stop==1)
			break
		endif
	while(i<anal_length)	
	if (i<100)
		print "only ",i," ISis detected"
	endif
	//print results
	wavestats /Q /R=[0, 19] ISiwave
	temp_avg=V_avg
	temp_sd=V_sdev
	print "cv for 20 ISis=á", temp_sd/temp_avg
	wavestats /Q /R=[0,49] ISiwave
	temp_avg=V_avg
	temp_sd=V_sdev
	print "cv for SO ISis=á", temp_sd/temp_avg
	wavestats /Q ISiwave
	temp_avg=V_avg
	temp_sd=V_sdev
	print "cv for ",i," ISis=á", temp_sd/temp_avg


end	

function ISIcvassignwavepopup(ctrlname, popnum, popstr) : popupmenucontrol
	string ctrlname
	variable popnum
	string popstr
	String/G startsweep
	startsweep=popstr
end

Function Button_okay_ISIcv(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k ISIcv_Options
	ISIcv_calc()
End	

Function Buttonkill_ISIcv(ctrlName) : ButtonControl
	String ctrlName
	DoWindow /k  ISIcv_Options
End