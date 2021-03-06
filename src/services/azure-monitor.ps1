###
### Main Process. Background Task and Schedule Work.
### Remarks: The settings need to sync with"process.ps1
###

Set-ExecutionPolicy bypass -Scope Process -Force

# require "\" at the end of line.
$logfolder = "c:\temp\log\"
# require "\" at the end of line.
# Devlopment Settings
#$processFolder = "C:\Users\koolala\Desktop\AzureLoader\"
# Production Settings
$processFolder = "d:\inetpub\azure\services\"


#$loopDelaySeconds = 1800  # 30 mins
#$loopDelaySeconds = 3600  # 60 mins
$loopDelaySeconds = 5400  # 90 mins

$ie = $null
$rootWindow = $null
$doc = $null
$sData = $null

# Remark: The Function Should be clone a set to Remove Service
function Write-HistoryLog([string] $message)
{
    try {
        #Add-Content $logfolder"history."$currentDateTimeFileFormat".log" -Value $message -Encoding unicode
        $today = Get-Date -format "yyyyMMdd"
        Add-Content "$($logfolder)history\history.$($today).txt" -Value $message -Encoding utf8
    }
    catch {}
}
# This Function copied from above.
function Write-ErrorLog([string] $message)
{
    try {
        #Add-Content $logfolder"history."$currentDateTimeFileFormat".log" -Value $message -Encoding unicode
        $today = Get-Date -format "yyyyMMdd"
        Add-Content "$($logfolder)error.txt" -Value $message -Encoding utf8
    }
    catch {}
}


# [Main]
do {
    $p = $null
    try {
        Write-HistoryLog "=================== Start =================="
        $usedTime = Measure-Command {
            #Start-Job -Name "SubProcess" -FilePath "$processFolder\process.ps1" | Wait-Job | Receive-Job
            $p = Start-Process $PSHome\powershell.exe -ArgumentList "-sta", "-windowstyle hidden", "-command `"$processFolder\process.ps1`"" -WAIT -PassThru
            # -Wait
            
            Wait-Process $p.id -ErrorAction silentlycontinue
        }
        
        $nextTime = ($loopDelaySeconds - $usedTime.TotalSeconds) + 300
        if($nextTime -lt 0) {
             $nextTime = 10
        }
        
    }
    catch [Exception] {
        # Send Exception Reports
        
        $errMsg = $_.Exception.toString()
        if (($errMsg -like '*Cannot read subscription list from Azure Portal*') -or ($errMsg -like '*System.Reflection.TargetInvocationException*')) {
            #Write-Host $errMsg -ForegroundColor red -BackgroundColor black
            Write-HistoryLog $errMsg
            
            $nextTime = 60
        }
        else {
            #Write-Host $errMsg -ForegroundColor red -BackgroundColor black
            Write-HistoryLog $errMsg
           
            $nextTime = 900
        }
        
    }
    finally {
        #Remove-Job *
        if ($p -ne $null -and $p.id -ne $null) {
            Stop-Process $p.id -ErrorAction silentlycontinue
        }
    
        Write-HistoryLog "=================== End =================="
        Start-Sleep -Seconds $nextTime
    }

} while($true)