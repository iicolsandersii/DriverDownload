#############################################
# GET OS VERSION
#############################################

$unattend = "c:\windows\Panther\unattend.xml"

if (!(Test-Path $unattend))
{
    Write-Host "Can't locate $unattend..."
    exit 57
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

#############################################
# START EXIT CODES
#############################################

$exitcodes = @{}

$exitcodes.Add('50', "Local Driver store directory can't be found.")
$exitcodes.Add('51', "URL incorrect, offline, or file can't be found.")
$exitcodes.Add('52', "Model not configured.")
$exitcodes.Add('53', "CAB did not properly download.")
$exitcodes.Add('54', "CAB did not expand.")
$exitcodes.Add('55', "Drivers already downloaded.")
$exitcodes.Add('56', "Could not create the directory.")
$exitcodes.Add('57', "Could not locate $unattend.")

#############################################
# START VARIABLES
#############################################

#base driver store location
$driverStore = "\\yourserver\Drivers"

#initilize driver download page
$driverURL = ""

#get computer model
$computer = Get-WmiObject Win32_ComputerSystem | Select-object -Property Model,Manufacturer

#initilize full model driver path
$driverStoreModel = ""

#############################################
# START FUNCTIONS
#############################################

#checks valid path
function validPath($path, $childitemscheck)
{
    try
    {
        $pass = Test-Path $path

        if ($pass)
        {
            if ($childitemscheck = "childitemscheck")
            {
                $childitems = Get-ChildItem $path
                
                if (!$childitems)
                {
                    return $false
                }
                else
                {
                    return $true
                }
            }
        }
        else
        {
            return $false
        }
    }
    catch
    {
        Write-Host $_.Exception.Message
    }
}

#checks if the url is valid
function validURL($url)
{
    try
    {
        $request  = [System.Net.WebRequest]::Create($url)

        $response = $request.GetResponse()

        $response.StatusCode.value__

        if (!($response.StatusCode.value__ -eq '200'))
        {
            return $false
        }
        else
        {
            return $true
        }
    }
    catch
    {
        Write-Host $_.Exception.Message
    }
}

function getCAB($comp)
{

    if ($($comp.Manufacturer) -eq "Dell Inc.")
    {
        try
        {
            Write-Host "Downloading $($comp.Model) Drivers..."
            
            #arguments for the download direcory
            $args = "-DownloadFolder " + $driverStore + "\" + $OS + " -TargetModel " + '"' + $($comp.Model) + '"' + " -TargetOS $OS -Verbose"

            #command to download cab file
            Invoke-Expression  "$PSScriptRoot\Download-DellDriverPacks.ps1 $args"

            if (!$?)
            {
                Write-Host $exitcodes."53"
                exit 53
            }

            $shell = New-Object -ComObject Shell.Application

            # get all cab files
            $cabs = Get-ChildItem $driverStoreModel

            foreach ($cab in $cabs)
            {
                Write-Host "Extracting" $comp.Model "CAB file..."
                EXPAND "$driverStoreModel\$cab" -F:* $driverStoreModel | Out-Null
            }

            if (!$?)
            {
                Write-Host $exitcodes."54"
                exit 54
            }

            Remove-Item -Path $driverStoreModel\$cab

            Write-Host "Driver" $($comp.Model) "completed downloading!"
            exit 0
        }
        catch
        {
            Write-Host $_.Exception.Message
        }
    }
    else
    {
        Write-Host $exitcodes."52"
        exit 52
    }   
}

#checks manufactuer, and updates driver URL
function getManufacturerURL($comp)
{
    try
    {
        #update the full driver path for model
        $script:driverStoreModel = $driverStore + "\" + $OS + "\" + $($comp.Model)
        
        #see if the drivers are downloaded, or if it's a blank directory
        if (validPath $driverStoreModel "childitemscheck")
        {
            Write-Host $exitcodes."55"
            exit 55
        }
        else
        {
            New-Item -Path $driverStoreModel -ItemType Directory -Force | Out-Null
        }

        if ($comp.Manufacturer -eq "Dell Inc.")
        {
            getCAB $comp 
        }

        if ($comp.Manufactuer -eq "Hewlett-Packard")
        {
            $script:driverURL = "http://ftp.hp.com/pub/caps-softpaq/cmit/HP_Driverpack_Matrix_x64.html"
        }                      
    }
    catch
    {
        Write-Host $_.Exception.Message
    }
}

#############################################
# FUNCTION CALLS
#############################################

#checking the driver store path
if (!(validPath $driverStore))
{
    Write-Host $exitcodes."50"
    exit 50
}

#get url for computer Manufacturer
getManufacturerURL $computer
