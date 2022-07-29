Get-ChildItem -Path $PSScriptRoot\ -Filter WEPExplore_v1.2.zip | Expand-Archive -DestinationPath $PSScriptRoot\ -Force
cd $PSScriptRoot
.\"Autosofted_Auto_Keyboard_Presser_1.9.exe"
cd $PSScriptRoot
.\Explorer.exe