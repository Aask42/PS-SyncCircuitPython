# CI for ~~The Hackaday~~ Circuitpython

## Preface 

Welcome to the repository for a basic Continuous Integration/Continuous Development tool which was built for the Circuitpython platform. 

## Introduction

This tool will sync a target folder in the INI file with a target filesystem. GLHF. 

Compatability: PowerShell on Windows 10, 11 and on MacOSX. It should also work on any Linux distro with PowerShell Core installed

## How to use this CI (Continuous Integration) tool

Or better titled, **Automated FileCopy Stack**

### Initial Setup

1. Open a PowerShell console and set your desired application repository as root
2. Clone this repository in the desired location and set the new directory as root
```powershell
git clone https://github.com/Aask42/PSSyncCircuitPython
cd PSSyncCircuitPython
```
1. Plug in CircuitPython device and identify which letter drive is auto-assigned on initial mounting of the drive 
   1. Note: It's untested but this script SHOULD support syncing to multiple circuitpython drives simultaneously
2. Open "config.ini" in your text editor of choice and add your application details  
**Example Config:**
    ```ini
        [SPACEFORCE]
        app_root_folder=/User/username/project_folder
        device_drive=CIRCUITPY
        ignore=*.pyc,*.vscode*,*.stl,*.scad

        [AQUAFORCE]
        app_root_folder=/User/username/other_project_folder
        device_drive=CIRCUITPY_SECOND_DEVICE_DRIVE
        ignore=*.pyc,*.vscode*,*.stl,*.scad
    ```  

### Operating the agent

1. Open a console with "PSSyncCircuitPython" as root directory
2. Run the auto_make daemon from the console
    ```powershell
    powershell .\auto_sync_circuitpy.ps1
    ```
   - This will monitor **ALL FILES IN THE APP_ROOT_FOLDER** for changes 
   - Once changes are **saved** to **ANY FILE** in the app_root_folder, if it is not on the ignore list the daemon will execute all the steps listed in the [Manual Process Stack](#Manual-Process-Stack) using PowerShell/CLI tools
   - **Any errors in copying will print out on this PowerShell console, and will serve as your "fast-feedback-loop" for continuously integrating and developing whatever code on which you are working**
     - If you would like to run this daemon in the background and write the output to a log, run the following command instead
        ```powershell
        .\auto_make.ps1 -as_job
        ```
   - Feel free to edit the loop time, 5 seconds was an arbitrary choice
3. Press **"CTRL + C"** to exit when you're done or kill your background process

## Manual Process Stack

This is the process chain that really made me want to automate this stack:

Process Step | How to execute | Other Notes
-|-|-
Plug in Circuitpython device | Determine which Drive the device is using | This is the simple name Windows gives the drive, same with Mac and Linux. You may have to use New-PSDrive with persistence to mount the drive in Linux/MacOS
Open PowerShell console with the target project directory to sync as your root | Shift-Right-Click in the explorer window to open a new CMD, then just type "powershell" and hit enter. On MacOS and Linux just open up a pwsh console | 
Debugging | Watch the PowerShell console for errors from the make command | Step through debugging with VSCode
