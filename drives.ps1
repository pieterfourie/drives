<#
We want to be notified when a drive in our home network is running low on space.
The script will check the desired drive for free space,
and send a Telegram notification if it is below 20%.
All actions should be logged.
The script should support scanning a drive the user specifies.
The script should support both linux and windows.
#>

<#
Supports logging
Checks desired drive for free space
Lets user specify drive
Supports Windows and Linux
Sends Telegram notification 
($a = Find-Module -Tag Telegram)($a.Description)(Install-Module PoshGram)
(Get-Command -Module PoshGram)(Get-Help Send-TelegramTextMessage -Examples)
(Copy example code and paste here below)
#>

# Give user ability to specify drive
param (
    [Parameter(Mandatory =$True)]
    [string]
    $drive
)


# log directory

if ($PSVersionTable.Platform -eq 'Unix') {
    $logPath = './temp'
}
else {
    $logPath = 'C:\logs'
}

$logFile = "$logPath/driveCheck.log" #logFile


# verify if log directory exists

try {
    if (-not (Test-Path -Path $logPath -ErrorAction stop)) {
        # output dir is not found. Create dir
        New-Item -ItemType Directory -Path $logPath -ErrorAction Stop | Out-Null
        New-Item -ItemType File -Path $logFile -ErrorAction Stop | Out-Null
    }
}
catch {
    throw
}

Add-Content -Path $logFile -Value "[INFO] Running $PSCommandPath"


# verify that poshgram is installed

if (-not (Get-Module -name PoshGram -ListAvailable)) {
    Add-Content -Path $logFile -Value "[ERROR] PoshGram is not installed."
    throw
}
else {
    Add-Content -Path $logFile -Value "[INFO] PoshGram is installed."
}


# get hard drive information
try {
    
    if ($PSVersionTable.Platform -eq 'Unix') {
        # used
        # free
        $volume = Get-PSDrive -Name $drive
        # verify volume actually exists
        if ($volume) {
            $total = $volume.Used + $volume.free
            $percentFree = [int](($volume.Free / $total) * 100)
            Add-Content -Path $logFile -Value "[INFO] Percent Free: $percentFree%."
        }
        else {
            Add-Content -Path $logFile -Value "[ERROR] $drive was not found."
            throw
        }
}
    else {
        $volume = Get-Volume -ErrorAction Stop | Where-Object {$_.DriveLetter -eq $drive}
        if ($volume) {
            $total = $volume.Size
            $percentFree = [int](($volume.SizeRemaining / $total) * 100)
            Add-Content -Path $logFile -Value "[INFO] Percent Free: $percentFree%."
        }
        else {
            Add-Content -Path $logFile -Value "[ERROR] $drive was not found."
            throw
        }
    }
}
catch {
    Add-Content -Path $logFile -Value "[ERROR] Unable to retrieve volume information."
    Add-Content -Path $logFile -Value $_
    throw
}


# send telegram message if drive is low

if ($percentFree -le 20) {
    try {
        Import-Module -Name PoshGram -ErrorAction Stop
        Add-Content -Path $logFile -Value "[INFO] Imported PoshGram succesfully."
    }
    catch {
        Add-Content -Path $logFile -Value "[ERROR] PoshGram could not be imported."
        Add-Content -Path $logFile -Value $_
    }

    Add-Content -Path $logFile -Value "[INFO] Sending Telegram notification."

    $sendTelegramMessageSplat = @{
        Message     = "[LOW SPACE] Drive at $percentFree%"
        ChatID      = "###########"
        BotToken    = "##################################"
        ErrorAction = 'Stop'
    }
    try {
     Send-TelegramTextMessage @sendTelegramMessageSplat
     Add-Content -Path $logFile -Value "[INFO] Message sent succesfully."   
    }
    catch {
        Add-Content -Path $logFile -Value "[ERROR] Error ecnountered sending message."
        Add-Content -Path $logFile -Value $_
        throw
    }
}
