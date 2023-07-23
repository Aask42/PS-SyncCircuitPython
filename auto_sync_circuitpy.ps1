param (
    [string]$config_root = ".\",
    [string]$config_filename = "config.ini",
    [switch]$import_only = $false,
    [switch]$as_job = $false
)

# If you want to force mount your pico every run, here ya go, otherwise comment this out
#new-psdrive -root /Users/aask/testSync -Name CIRCUITPY -PSProvider filesystem

if($(Get-ExecutionPolicy) -ne "Bypass"){
    Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
}

function read_config($config_root,$config_filename) 
{
    # Fetch all the info from our config file and return it in a hashtable
    $config_root = $(Get-ChildItem $config_root)[-1].DirectoryName
    Push-Location $config_root
    
    $config_file = Get-ChildItem .\$config_filename
    
    if ($config_file.Count -lt 1) {
        Write-Host 'Unable to find config.ini!!!'
        return 0
    } else {
        $settings = Get-IniContent .\$config_filename
    }
    
    return $settings
}

function run_daemon()
{
    param (
        [string]$config_root,
        [string]$config_filename
        )
    
    $config = read_config -config_root $config_root -config_filename $config_filename

    $main_file_list = @{}



    $config.Keys | ForEach-Object {

        $root= $config.$_.config_root_folder
        $drive = $config.$_.device_drive
        $ignore = $config.$_.ignore.Split(",")
        
        if (!(Test-Path $root)) {
            Write-Host "Unable to find $root...Skipping..."
        }else{
            # Get a list of all the files in our root
            $file_list = Get-ChildItem $root -Recurse -File -Exclude $ignore
            $file_name_list = @{}
            $file_list | % {
                $file_name_list += @{
                    "$($_.FullName)" = @{
                        "prev_file_info" = Get-ChildItem $_.FullName;
                        "file_info" = Get-ChildItem $_.FullName;
                    }
                }
            }
            

            $main_file_list += @{
                "$($_)" = @{
                    "config_root_folder" = $root;
                    "file_list" = $file_name_list;
                    "device_drive" = $drive
                    "name" = $_
                }
            }
        }
    }    
    
    while($true) {
        foreach($item in $main_file_list.Keys){

            $main_c_root = $main_file_list.$item

            Push-Location $main_c_root.config_root_folder
            
            $drive = $main_c_root.device_drive
            foreach($file in $main_c_root.file_list.Keys | Sort-Object){
            #$main_c_root.file_list.Keys | % {
                #$fullName = $main_c_root.file_list.$file.file_info.FullName
                $main_file_list.$item.file_list.$file.file_info = Get-ChildItem $file
                $new_write_time = $main_file_list.$item.file_list.$file.file_info.LastWriteTime
                $old_write_time = $main_file_list.$item.file_list.$file.prev_file_info.LastWriteTime
                $parent_directory = $main_file_list.$item.file_list.$file.file_info.DirectoryName
                
                $copy_to_drive = $(Get-PSDrive -Name $drive).Root

                if(!(Get-PSDrive -Name $drive -ErrorAction SilentlyContinue)){
                    Write-Host "Could not find drive $drive, exiting!!!!"
                    Exit
                }
                if(!$copy_to_drive){
                    Write-Host "Unable to find $drive path!"
                    Exit
                }

                $file_prefix_directory = $($file).Replace("$root","")
                $new_folder_path = "$copy_to_drive$new_parent_directory"

                $new_parent_directory = $parent_directory.Replace("$root","")
                $new_file_path = "$copy_to_drive$file_prefix_directory"
                
                if($new_write_time -gt $old_write_time -or !$(Test-Path $new_file_path)) {
                    
                    Write-Host "Found changes to $file, uploading to $copy_to_drive"
                    Write-Host "Uploading $file to $copy_to_drive..."

                    $directory = $(Test-Path $new_parent_directory)
                    if(!$directory){
                        Write-Host "Making new folder $new_folder_path..."
                        New-Item $copy_to_drive$new_parent_directory -ItemType Directory -Force
                    }

                    $command = "Copy-Item -Force $file $new_file_path"
                    Write-Host "$command"
                    Invoke-Expression "$command"
                    
                    Write-Host "Successfully wrote $new_file_path to CircuitPy ^_^" -BackgroundColor Green -ForegroundColor White
                    
                    
                    $main_file_list.$item.file_list.$file.prev_file_info = $main_file_list.$item.file_list.$file.file_info
    
                }
            }
            # Return to our original root
            Pop-Location
        }
        Write-Host "Waiting for changes to files in the $($main_c_root.config_root_folder) folder..."
        Start-Sleep 5
    }
}

function Get-IniContent ($filePath)
{
    $ini = @{}
    switch -regex -file $FilePath
    {
        "^\[(.+)\]" # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^(;.*)$" # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = “Comment” + $CommentCount
            $ini[$section][$name] = $value
        }
        "(.+?)\s*=(.*)" # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

if ($import_only) {
    Write-Host "Successfully imported functions!!!"
} elseif ($as_job) {
    $filepath = $(Get-ChildItem .\auto_make.ps1).DirectoryName

    Write-Host "Starting the Drinkbot CI Daemon..."
    
    $job = Start-Job -ArgumentList $filepath -ScriptBlock {
        Set-Location $args[0]
        powershell .\auto_make.ps1 | Out-File .\auto_make.log -Append
    } 
    Write-Host "To end this daemon, please run: `n
    Stop-Job -Id $($job.Id)`n"
} else {
    Write-Host "Daemon starting up..."
    run_daemon -config_root $config_root -config_filename $config_filename
}
