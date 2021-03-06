#can't run two scripts at a time, and it seems to impossible. So that i will leave it here
#my-script---------------------------------------------------------------------------------------------------------------
New-Item c:\test.txt -force
Set-Content c:\test.txt $username, $password -force
#enable winRM
Enable-PsRemoting -Force
Set-Service WinRM -StartMode Automatic
Set-Item wsman:\localhost\client\trustedhosts * -Force
Restart-Service WinRM
Get-Item WSMan:\localhost\Client\TrustedHosts
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
netsh advfirewall firewall add rule name="WinRM-HTTPS-Ansible" dir=in localport=5986 protocol=TCP action=allow
#update PowerShell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/jborean93/ansible-windows/master/scripts/Upgrade-PowerShell.ps1"
$file = "$env:temp\Upgrade-PowerShell.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
&$file -Version 5.1 -Username $username -Password $password -Verbose # Version can be 3.0, 4.0 or 5.1

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force # This isn't needed but is a good security practice to complete
$reg_winlogon_path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $reg_winlogon_path -Name AutoAdminLogon -Value 0
Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultUserName -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultPassword -ErrorAction SilentlyContinue

#install WinRM Memory Hotfix:
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/jborean93/ansible-windows/master/scripts/Install-WMF3Hotfix.ps1"
$file = "$env:temp\Install-WMF3Hotfix.ps1"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file -Verbose

#WinRM Setup
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file
#my-script---------------------------------------------------------------------------------------------------------------

#to run a big raw script form github https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1
$VAR=Invoke-WebRequest https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1
$TEMP=New-TemporaryFile
$FILE=$TEMP.FullName + "foransibleconfig.ps1"
$VAR.Content | Out-File $FILE
&$FILE

#to initialize and format additional attached disk to NFS (PowerShell script) 
$disks = Get-Disk | Where partitionstyle -eq 'raw' | sort number
$letters = 70..89 | ForEach-Object { [char]$_ }
$count = 0
$labels = "data1","data2"

    foreach ($disk in $disks) {
        $driveLetter = $letters[$count].ToString()
        $disk |
        Initialize-Disk -PartitionStyle MBR -PassThru |
        New-Partition -UseMaximumSize -DriveLetter $driveLetter |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel $labels[$count] -Confirm:$false -Force
	$count++
    }
