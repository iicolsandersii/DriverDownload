# DriverDownload

Run this script in a WinPE enviornment.  

The script will scan the Dell device after the .WIM image is applied, check to see if the drivers are already on a UNC path to use, or it will automatically download and extract to the driver UNC path.

*To take advantage of this script, make sure your image has the an addtional drivers location to scan added to the registry*
<https://technet.microsoft.com/en-us/library/cc753716(v=ws.11).aspx>

  - Run DriverDownload.ps1
    - Checks c:\windows\Panther\Unattend.xml" for OS that was installed
    - Checks UNC driver path for drivers folder
    - Gets model number of device
    - Downloads, and extracts .CAB file of missing from UNC driver path

  - Run CopyDrivers.ps1
    - Gets Model of Dell Device
    - Copies Drivers to c:\Drivers
    
 On next reboot, the system will use all drivers copied earlier during Windows setup.

**Future Version**
* Will re-write to include other hardware vendors (Lenovo, HP, Apple Boot Camp)
