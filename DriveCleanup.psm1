# Function to check free space on a specified drive
function Get-FreeSpacePercentage {
    param (
        [string]$DriveLetter
    )
    $drive = Get-PSDrive -Name $DriveLetter
    if ($drive) {
        return ($drive.Free / $drive.Used) * 100
    } else {
        throw "Drive $DriveLetter not found."
    }
}

# Function to clean up Windows Temp folder
function Clear-WindowsTemp {
    Write-Output "Cleaning up C:\Windows\Temp..."
    $tempFolder = "C:\Windows\Temp"
    if (Test-Path $tempFolder) {
        Get-ChildItem -Path $tempFolder -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# Function to clean up user-specific Temp folders
function Clear-UserTemp {
    Write-Output "Cleaning up user temp folders..."
    $userTempFolders = Get-ChildItem "C:\Users" -Directory | ForEach-Object { Join-Path $_.FullName "AppData\Local\Temp" }
    foreach ($folder in $userTempFolders) {
        if (Test-Path $folder) {
            Get-ChildItem -Path $folder -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}

# Function to clear the Recycle Bin
function Clear-RecycleBinContents {
    Write-Output "Cleaning up Recycle Bin..."
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

# Function to perform Windows Update cleanup
function Perform-WindowsUpdateCleanup {
    Write-Output "Performing Windows Update cleanup..."
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow
}

# Main function to execute the cleanup process
function Start-DriveCleanup {
    param (
        [string]$DriveLetter = "C",
        [int]$Threshold = 10,
        [string]$LogFile = "C:\PSLogs\CleanupLog.txt"
    )

    $freeSpacePercentage = Get-FreeSpacePercentage -DriveLetter $DriveLetter
    if ($freeSpacePercentage -lt $Threshold) {
        Write-Output "Free space on ${DriveLetter} is below ${Threshold}%. Initiating cleanup..." | Tee-Object -FilePath $LogFile -Append
        Clear-WindowsTemp
        Clear-UserTemp
        Clear-RecycleBinContents
        Perform-WindowsUpdateCleanup
        $freeSpaceAfterCleanup = Get-FreeSpacePercentage -DriveLetter $DriveLetter
        Write-Output "Cleanup completed. Free space: $([math]::Round($freeSpaceAfterCleanup, 2))%" | Tee-Object -FilePath $LogFile -Append
    } else {
        Write-Output "Free space on ${DriveLetter} is sufficient ($([math]::Round($freeSpacePercentage, 2))%). No cleanup needed." | Tee-Object -FilePath $LogFile -Append
    }
}

# Exporting functions
Export-ModuleMember -Function Get-FreeSpacePercentage, Clear-WindowsTemp, Clear-UserTemp, Clear-RecycleBinContents, Perform-WindowsUpdateCleanup, Start-DriveCleanup
