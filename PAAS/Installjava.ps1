Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Start-BitsTransfer -Source "https://csgdfe49495dc73x47efxabf.blob.core.windows.net/grt/jre-8u191-windows-x64.exe" -Destination "D:\"

$path = "C:\Program Files\Java"


 
 $Exe = "D:\jre-8u191-windows-x64.exe"
$ExeArgs = @(
   "INSTALL_SILENT=1"
   "STATIC=0"
   "AUTO_UPDATE=0"
   "WEB_JAVA=1"
   "WEB_JAVA_SECURITY_LEVEL=H"
   "WEB_ANALYTICS=0"
   "EULA=0"
   "REBOOT=1"
   "NOSTARTMENU=0"
   "SPONSORS=0"
)
Start-Process $Exe -ArgumentList $ExeArgs -NoNewWindow -Wait 
Start-Sleep 120
