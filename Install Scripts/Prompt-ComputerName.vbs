'==========================================================================
' NAME: PromptForSystemName.vbs
'
' AUTHOR: Robert Holbert Previously: Andrew Buford
' DATE  : 9/26/2012
'
' COMMENT: This script will detect if the current assigned value for the computer name 
' begins with MININT, indicating that this image is bare metal image.  It then prompts
' the end-user to enter a new computer name.
'
' VERSION : 1.1
' 1.0 (12/08/2008)- Intial script to check if the computer name begins with 
'  "minint", which indicates the system was booted with CD or PXE.
' 1.1 (06/01/2009)- Added check if the computer name equals "minwinpc", 
'  which indicates the system was booted with USB key
' 1.2 (09/26/2012)- Added restriction that computer name can't be over 13 characters
'==========================================================================

Dim sNewComputerName, oTaskSequence, sTSMachineName, bPromptName, sExpression, sArchitecture
Set oShell = WScript.CreateObject ("WScript.shell")
sArchitecture = oShell.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PROCESSOR_ARCHITECTURE")
If sArchitecture = "AMD64" Then
	sExpression = "move-installationprogress.exe"
ElseIf sArchitecture = "x86" Then
  sExpression = "move-installationprogress_x86.exe"
End If
oShell.Run sExpression

Set oTaskSequence = CreateObject ("Microsoft.SMS.TSEnvironment")
' Get the name the computer is set to receive and truncate to first 6 letters
sTSMachineName = lcase(oTaskSequence("_SMSTSMachineName"))
If left(sTSMachineName,6) = "minint" Then
 bPromptName = True
ElseIf sTSMachineName = "minwinpc" Then
 bPromptName = True
Else
 bPromptName = False
End If
' Note: The wscript.echo commands are logged in SMSTS.log for troubleshooting.  They are not displayed to the end user.
If bPromptName = True Then
 wscript.echo "Detected that the computer name is scheduled to receive a random value.  Prompting user to input a standard name."
 sNewComputerName = InputBox ("Please enter a standard computer name to continue.", "Computer Name",,,4000)
 oTaskSequence("OSDComputerName") = UCase(sNewComputerName)
 wscript.echo "Set Task Sequence variable OSDComputerName to: " & sNewComputerName
Else
 wscript.echo "Computer set to receive the standard name """ & sTSMachineName & """, continuing as is."
End If