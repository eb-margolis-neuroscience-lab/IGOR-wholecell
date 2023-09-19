#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"Ih Graph", easyIh_disp()
End

//--------------------------------------------------------------------------------
function easyIh_disp()
	Wave SPa = $"root:SutterPatch:Data:R1_S1_IV"
	Wave SPb = $"root:SutterPatch:Data:R2_S1_IV"
	if (DataFolderExists("root:acquisition:data"))		
		Display /W=(650,70,880,250) root:acquisition:ih_0
		AppendToGraph root:acquisition:ih_1
		AppendToGraph root:acquisition:ih_2
		AppendToGraph root:acquisition:ih_3
		AppendToGraph root:acquisition:ih_4
		AppendToGraph root:acquisition:ih_5
		AppendToGraph root:acquisition:ih_6
		AppendToGraph root:acquisition:ih_7
	elseif (DataFolderExists("root:wholecell"))
		Display /W=(650,70,880,250) root:IH:control_ih0
		AppendToGraph root:IH:control_ih1
		AppendToGraph root:IH:control_ih2
		AppendToGraph root:IH:control_ih3
		AppendToGraph root:IH:control_ih4
		AppendToGraph root:IH:control_ih5
		AppendToGraph root:IH:control_ih6
		AppendToGraph root:IH:control_ih7
	elseif (WaveExists(SPa))
		Display /W=(650,70,880,250) root:SutterPatch:Data:R1_S1_IV[][2]
		AppendToGraph root:SutterPatch:Data:R1_S1_IV[][3]
		AppendToGraph root:SutterPatch:Data:R1_S1_IV[][4]
		AppendToGraph root:SutterPatch:Data:R1_S1_IV[][5]
		AppendToGraph root:SutterPatch:Data:R1_S1_IV[][6]
		AppendToGraph root:SutterPatch:Data:R1_S1_IV[][7]
		AppendToGraph root:SutterPatch:Data:R1_S1_IV[][8]
		AppendToGraph root:SutterPatch:Data:R1_S1_IV[][9]
	elseif (WaveExists(SPb))
		Display /W=(650,70,880,250) root:SutterPatch:Data:R2_S1_IV[][0]
		AppendToGraph root:SutterPatch:Data:R2_S1_IV[][1]
		AppendToGraph root:SutterPatch:Data:R2_S1_IV[][2]
		AppendToGraph root:SutterPatch:Data:R2_S1_IV[][3]
		AppendToGraph root:SutterPatch:Data:R2_S1_IV[][4]
		AppendToGraph root:SutterPatch:Data:R2_S1_IV[][5]
		AppendToGraph root:SutterPatch:Data:R2_S1_IV[][6]
	endif
	ShowInfo
End