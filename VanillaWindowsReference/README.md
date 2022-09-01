# VanillaWindowsReference Scripts

This is just a subfolder to backup scripts that I use to generate data for the [VanillaWindowsReference](https://github.com/AndrewRathbun/VanillaWindowsReference) repository.

## WVR PowerShell Command

All credit to Nasreddine Bencherchali for this!

```cmd
C:\PsExec_IgnoreThisFile_ResearchTool.exe -accepteula -i -s cmd.exe /c powershell.exe "Get-ChildItem -Recurse 'C:\' | Where-Object { ! $_.PSIsContainer } | Select-Object DirectoryName, Name, FullName, Length, @{ N = 'CreationTimeUtc'; E = { (Get-Date -Format 's' $_.CreationTimeUtc).Replace('T', ' ') } }, @{ N = 'LastAccessTimeUtc'; E = { (Get-Date -Format 's' $_.LastAccessTimeUtc).Replace('T', ' ') } }, @{ N = 'LastWriteTimeUtc'; E = { (Get-Date -Format 's' $_.LastWriteTimeUtc).Replace('T', ' ') } }, Attributes, @{ N = 'MD5'; E = { (Get-FileHash $_.FullName -Algorithm MD5).Hash } }, @{ N = 'SHA1'; E = { (Get-FileHash $_.FullName -Algorithm SHA1).Hash } }, @{ N = 'SHA256'; E = { (Get-FileHash $_.FullName -Algorithm SHA256).Hash } }, @{ N = 'Sddl'; E = { (Get-Acl $_.FullName).Sddl } } | Export-Csv C:\test.csv -NoTypeInformation; systeminfo > C:\SystemInfo_.txt"
```
