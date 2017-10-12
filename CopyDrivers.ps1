# Decription: Checks computer model and downloads the approporiate drivers

$unattend = "c:\windows\Panther\unattend.xml"

if (!(Test-Path $unattend))
{
    Write-Host "Can't locate $unattend..."
    exit 2
}
   
[xml]$xml = Get-Content -Path $unattend

# if unattend has windows 7 or windows 10 in the catalog line change the driver path accordingly
if ($xml.unattend.LastChild.source.ToString() -like "*windows 7*")
{
    $OS = "Windows_7_x64"
}
ElseIf ($xml.unattend.LastChild.source.ToString() -like "*windows 10*")
{
    $OS = "Windows_10_x64"
}

# UNC to Driver Store
$uncPath = "\\servername\Drivers\$OS\"

# Get a list of all the Driver folders in the Driver Store
$driverFolderList = Get-ChildItem -Path $uncPath | where {$_.PSIsContainer}

# Store Computer Model
$computerModel = Get-WmiObject Win32_ComputerSystem | Select Model

#foreach model in the drivers share check of the model of the computer matches
foreach ($item in $driverFolderList)
{
    if ($item.Name -eq $computerModel.Model)
    {    
        $fullPath =  $uncPath + $computerModel.Model + '\'
       
        Copy-Item -Path "$fullpath" -Destination "C:\Drivers" -Recurse
    }
}
