###
### Sub Process.  
### Version 0.0.8a
###
### - Prevent Memory Stack Overflow..
### - Enhance to reduce url requests by includeList
### - 

Set-ExecutionPolicy bypass -Scope Process -Force

# Add Modules Here
try {
    if ($moduleLoaded -eq $null) {

        Get-ChildItem 'C:\Program Files (x86)\Microsoft SDKs\Windows Azure\PowerShell\Azure\*.psd1' | ForEach-Object {Import-Module $_}
        
        $moduleLoaded = $true
    }
}
catch {}


# require "\" at the end of line.
# Devlopment Settings
#$processFolder = "C:\Users\koolala\Desktop\AzureLoader\"
# Production Settings
$processFolder = "d:\inetpub\azure\services\"	# <~~ This file's directory!

$logfolder = "c:\temp\log\"
$loginName = "azure account" # <~~ Login Account Here

$global:passwd = "XXXXXXXXXXXXXXXXXXXXXX" # <~~ Encrypted Password Here

#
#$text1 = 'password'
# Encode Method
#$bytes1 = [System.Text.Encoding]::UTF8.GetBytes($text1);
#$encoded =[System.Convert]::ToBase64String($bytes1);

# Decode Method
#$bytes2 = [System.Convert]::FromBase64String($encoded)
#$text2 = [System.Text.Encoding]::UTF8.GetString($bytes2);


#$loopDelaySeconds = 1800  # 30 mins
#$loopDelaySeconds = 3600  # 60 mins
$loopDelaySeconds = 5400  # 90 mins

#$accountForRemoveServices = "koolala3@hotmail.com"
#$accountForRemoveServices = "eddie_chow@infocan.net"
#$accountForRemoveServices = "i_n_f_o_c_a_n@hotmail.com"
$accountForRemoveServices = $loginName


$ie = $null
$rootWindow = $null
$doc = $null
$sData = $null

$operationLogFile = "data-" + (Get-Date -Format "yyyy-MM-ddTHHmmss") + ".txt"

#
function Get-WebConsole() {
    try {
        $ie.visible = $true
    }
    catch {
        $ie = new-object -ComObject InternetExplorer.Application
        $ie.visible = $true

    }
    finally {
        #$ie.visible = $false
    }
    
    return $ie
}

#
function Set-URL([string] $url, [bool] $match = $true) {
    if ($match -ne $true) {
        if ($ie.LocationURL.indexOf($url) -eq 0) {
            return
        }
    }
    elseif ($ie.LocationURL -eq $url) {
        return
    }

    $ie.navigate($url)
    while ($ie.Busy -eq $true) { Start-Sleep -Milliseconds 500; } 
}

#
function Login($name) {
    
    #if ($global:name -eq $null) {
    #    $global:name = Read-Host 'What is your username?'
    #}
    
    $global:name = $name
    
    #$global:passwd = Read-Host 'What is your password' -AsSecureString
    if ($global:passwd -eq $null) {
        #$password = Read-Host 'What is your password' -AsSecureString
        CLS
        #$global:passwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        #$global:passwd = "XXXXXXXXXXXXXXX"
    }

    return HasLogin
}

function Logout()
{
    try {
        if ($ie -ne $null) { 
            $ie.navigate("http://login.microsoftonline.com/logout.srf")
            while ($ie.Busy -eq $true) { Start-Sleep -Milliseconds 500; } 
            $ie.Quit() 
        }
        
        #Remove-Variable -Name name, passwd -Scope global
        #Remove-Variable -Name doc, ie -Scope global
        $ie = $null
    }
    catch {}
}

function IsRequireLogin([string] $path) {

    if ($path.indexOf('https://login.live.com/login.srf') -eq 0) {
        DoLogin
        return $true
    }
    else {
        return $false
    }
    
}

function HasLogin() {
    if (($global:name -eq $null) -or ($global:passwd -eq $null)) { return $false }
    return $true;
}


function DoLogin() {
    #Set-URL -url 'https://manage.windowsazure.com'
    Set-URL -url 'https://login.live.com/login.srf' -match $false
	
    #do {
    #    $ie.navigate('https://manage.windowsazure.com')
    #    #$ie.navigate('https://login.live.com/login.srf')
    #    while ($ie.Busy -eq $true) { Start-Sleep -Milliseconds 500; } 
    #    
    #    if ($ie.LocationURL.indexOf('https://login.live.com/login.srf') -eq 0) {
    #        break;
    #    }
    #}
    #while($true)
    
    Start-Sleep -Milliseconds 2000;
    while ($ie.Busy -eq $true) { Start-Sleep -Milliseconds 500; } 
    
    $doc = $ie.document
    
    
    $loginName = $doc.getElementsByName("login")
    $loginPassword = $doc.getElementsByName("passwd")
    $loginKMSI = $doc.getElementsByName("KMSI")

    if ($loginName -ne $null) {
        foreach($i in $loginName) {
            $i.value = $name
        }
    }
    
    if ($loginPassword -ne $null) {
        #$pw = Get-EncryptedText -password $global:passwd
        #$pw = $global:passwd
        $bytes2 = [System.Convert]::FromBase64String($global:passwd)
        $pw = [System.Text.Encoding]::UTF8.GetString($bytes2);
        
        foreach($i in $loginPassword) {
            $i.value = $pw
        }
    }

    $loginButton = $doc.getElementById("idSIButton9")
    if ($loginButton -ne $null) {
        $loginButton.click()
    }
    
    while ($ie.Busy -eq $true) { Start-Sleep -Milliseconds 500; }
    
    $a = 1
    
}


# Performance Issues =.= Too Slow...!
function Get-Usage([string] $href,[string] $target) 
{
    if ($null, "" -contains $href) { return $null }
    if ($null, "" -contains $target) { $target = "default"; }
    
   
    $win = $rootWindow.open("$href", "$target", "", $false)
    #while ($ie.Busy -eq $true) { Start-Sleep -Milliseconds 200; } 

    if ($ie -ne $null) {
        $ie.visible = $true
    }
    
    try {
        while ($win.document -eq $null) { Start-Sleep -Milliseconds 200; }
        $_doc = $win.document
        
        if ($_doc.location.toString() -ne $href) {
            
            throw "Login Fail"
            return $null
        }
        
        
        while (('complete', 'loaded', 'interactive' -notcontains $_doc.readyState) -or ($_doc.body -eq $null) -or ($_doc.body.getElementsByClassName -eq $null)) { Start-Sleep -Milliseconds 200; } 
        #$_doc.execCommand("stop")
        
        $data = $_doc.body;
        
        $subscriptionId = $_doc.getElementById("subscription-guid").innerText
        $subscriptionName = @($data.getElementsByClassName("subscription-friendly-name"))[0].innerText
        $amount = Convert-Str2Dec(@($data.getElementsByClassName("subscription-estimated-cost"))[0].innerText)

        
        $orderId = $_doc.getElementById("subscription-friendly-id").innerText
        $serviceAdministratorEmail = $_doc.getElementById("service-administrator-email").innerText
        
        $editSubscriptionLink = $_doc.getElementById("edit-subscription-details").href
        
        $accountAdministratorEmail = $_doc.getElementById("account-administrator-email").innerText
        
        $subscriptionStatus = $_doc.getElementById("subscription-status").innerText
        $effectiveRange = $_doc.getElementById("subscription-effective-range").innerText
        
        #Write-Host "$subscriptionName`t$amount`t$subscriptionId`t$serviceAdministratorEmai`t$orderId"
        
        try {
            $sDataCount = $sData.Count
            #Write-HistoryLog "[Debug] sData.count: $sDataCount" 
            if ($sData -ne $null -and $count -gt 0) {
            
                $previousData = $sData | Where-Object { ($_.subscriptionId -eq $subscriptionId) -and ($_.accountAdministratorEmail -eq $accountAdministratorEmail) -and ($_.effectiveRange -eq $effectiveRange) | SELECT -FIRST 1 }
                #$previousData = $sData | Where-Object { ($_.subscriptionId -eq $subscriptionId) }
                
                #$previousCount = $previousData.Count
                #Write-HistoryLog "[Debug] previousData.count: $previousCount"
                
                if ($previousData -eq $null) {
                    throw "No Previous Record"
                }
                
                $previousAmount = Convert-Str2Dec -value $previousData.amount
                $previousDateTime = $previousData.currentDateTime
                $previousAmountDifferentPerHour = Convert-Str2Dec -value $previousData.amountDifferentPerHour
                $previousLeaveHour = Convert-Str2Dec -value $previousData.leaveHour
            }
            else {
                throw "No Previous Record"
            }
        }
        catch [Exception] {
        
            Write-HistoryLog $_.Exception.toString()
        
            $previousAmount = $amount
            $previousDateTime = (Get-Date $currentDateTime).AddSeconds(-$loopDelaySeconds)
            $previousAmountDifferentPerHour = 0
            $previousLeaveHour = 99999
        }
        
        #Write-HistoryLog "[Debug] $previousAmount -> $amount , $previousDateTime -> $currentDateTime"
        
        # Formula *************************
        $totalHourDiff = ((Get-Date $currentDateTime) - (Get-Date $previousDateTime)).TotalHours
        
        if ($totalHourDiff -ge 1 -and $totalHourDiff -lt 2) {
            $amountDifferentPerHour = ($amount - $previousAmount)
        }
        else {
            $amountDifferentPerHour = ($amount - $previousAmount) / $totalHourDiff
        }
        
        if ($amountDifferentPerHour -gt 0.0) {
            if ($totalHourDiff -gt 1 -and $previousAmountDifferentPerHour -gt 0 -and $previousAmountDifferentPerHour -ne 99999) {
                $amountDifferentPerHour = (($previousAmountDifferentPerHour + $amountDifferentPerHour) / 2)
                $leaveHour = (50.0 - $amount) / $amountDifferentPerHour
            }
            else {
                # Keep Existing Amount Different Per Hour
                $leaveHour = (50.0 - $amount) / $amountDifferentPerHour
            }
        }
        else {
            if (($amount -ge 50.0) -and ($amount -eq $previousAmount) -and ($previousAmountDifferentPerHour -eq 0.0) -and ($amountDifferentPerHour -eq 0.0)) {
                $leaveHour = 0.0
            }
            else {
                $leaveHour = 99999
            }
        }

        
        $output = @{
            currentDateTime = $currentDateTime
            subscriptionId = $subscriptionId
            subscriptionName =  $subscriptionName
            amount = $amount
            orderId = $orderId
            serviceAdministratorEmail = $serviceAdministratorEmail
            editSubscriptionLink = $editSubscriptionLink
            effectiveRange = $effectiveRange
            accountAdministratorEmail = $accountAdministratorEmail
            subscriptionStatus = $subscriptionStatus

            amountDifferentPerHour = $amountDifferentPerHour
            leaveHour = $leaveHour
            currentUsageRate = -1
            leaveHour2 = -1
        }
        
        try {
            $output.currentUsageRate = Get-ServiceCurrentUsage $output
            
            if ($output.currentUsageRate -gt 0) {
                $output.leaveHour2 = (50 - $amount - ($amountDifferentPerHour * 12)) / $output.currentUsageRate
            }
            elseif ($output.currentUsageRate -eq 0) {
                if ($amount -ge 50 -and $amountDifferentPerHour -eq 0) {
                    $output.leaveHour2 = 0
                }
                else {
                    $output.leaveHour2 = 99999
                }
            }
            
        }
        catch {
            
        }
        
        Write-HistoryLog "-- $subscriptionName -- $subscriptionId -- $amount -- $leaveHour"
        
        New-Object PSObject -Property $output

    }
    catch [exception] {
        #

        #Write-Host "Error" -ForegroundColor red
        #Write-Host $_.Exception.toString() #-ForegroundColor yellow -BackgroundColor black
        #Write-Host "Subscription Name: $subscriptionName" -ForegroundColor red
        
        Write-HistoryLog "Subscription Name: $subscriptionName"
        Write-HistoryLog $_.Exception.toString()
        
        return $null
    }
    finally {
        if ($win -ne $null) {
            $win.close()
        }
        
        #Remove-Variable -Name data, _doc, win, amount, subscriptionId, orderId, serviceAdministratorEmail, editSubscriptionLink    
    }
    
}

function Get-UsageByFile($file) 
{
    $content = Import-Csv $file
    
    $returnValue = @()
  
    try {
    
            #if ("Active","活动","作用中" -contains $subscription.subscriptionStatus) {
            #        #$logData += Get-Usage -href $href -target "$subscriptionName$i"
            #        $logLocalData = Get-Usage -href $subscription.href -target "__$i"
            #        if ($logLocalData -eq $null) {
            #            Write-HistoryLog "Subscription Name [$($subscription.subscriptionName)] cannot load any data."
            #        }
            #        else {
            #            $logData += $logLocalData
            #            Write-SubscriptionLog $logLocalData
            #        }
            #    }
            #    else {
            #        Write-HistoryLog  "Subscription Name [$($subscription.subscriptionName)] is skipped. becase it status is [$($subscription.subscriptionStatus)]"
            #    }
    
        $content | Where-Object { ($_ -ne $null) -and ($null, "" -notcontains $_.subscriptionId) } | sort-object -Property subscriptionName | % {

            if ("Active","活动","作用中" -contains $_.subscriptionStatus ) {
                #Write-HistoryLog "Subscription Name [$($subscription.subscriptionName)] cannot load any data."                
                
                $subscriptionId = $_.subscriptionId
                $subscriptionName = $_.subscriptionName
                $amount = Convert-Str2Dec($_.amount)

                $orderId = $_.orderId
                $serviceAdministratorEmail = $_.serviceAdminEmail
                
                $editSubscriptionLink = $_.editSubscriptionHref
                
                $accountAdministratorEmail = $_.accountAdminEmail
                
                $subscriptionStatus = $_.subscriptionStatus
                $effectiveRange = $_.effectiveRange
               
                
                #Write-Host "$subscriptionName`t$amount`t$subscriptionId`t$serviceAdministratorEmai`t$orderId"
                
                try {
                    $sDataCount = $sData.Count
                    #Write-HistoryLog "[Debug] sData.count: $sDataCount" 
                    if ($sData -ne $null -and $count -gt 0) {
                    
                        $previousData = $sData | Where-Object { ($_.subscriptionId -eq $subscriptionId) -and ($_.accountAdministratorEmail -eq $accountAdministratorEmail) -and ($_.effectiveRange -eq $effectiveRange) | SELECT -FIRST 1 }
                        #$previousData = $sData | Where-Object { ($_.subscriptionId -eq $subscriptionId) }
                        
                        #$previousCount = $previousData.Count
                        #Write-HistoryLog "[Debug] previousData.count: $previousCount"
                        
                        if ($previousData -eq $null) {
                            throw "No Previous Record"
                        }
                        
                        $previousAmount = Convert-Str2Dec -value $previousData.amount
                        $previousDateTime = $previousData.currentDateTime
                        $previousAmountDifferentPerHour = Convert-Str2Dec -value $previousData.amountDifferentPerHour
                        $previousLeaveHour = Convert-Str2Dec -value $previousData.leaveHour
                    }
                    else {
                        throw "No Previous Record"
                    }
                }
                catch [Exception] {
                
                    Write-HistoryLog $_.Exception.toString()
                
                    $previousAmount = $amount
                    $previousDateTime = (Get-Date $currentDateTime).AddSeconds(-$loopDelaySeconds)
                    $previousAmountDifferentPerHour = 0
                    $previousLeaveHour = 99999
                }
                
                #Write-HistoryLog "[Debug] $previousAmount -> $amount , $previousDateTime -> $currentDateTime"
                
                # Formula *************************
                $totalHourDiff = ((Get-Date $currentDateTime) - (Get-Date $previousDateTime)).TotalHours
                $amountDifferentPerHour = ($amount - $previousAmount) / $totalHourDiff
                
                if ($amountDifferentPerHour -gt 0.0) {
                    if ($totalHourDiff -gt 1 -and $previousAmountDifferentPerHour -gt 0 -and $previousAmountDifferentPerHour -ne 99999) {
                        $amountDifferentPerHour = (($previousAmountDifferentPerHour + $amountDifferentPerHour) / 2)
                        $leaveHour = (50.0 - $amount) / $amountDifferentPerHour
                    }
                    else {
                        # Keep Existing Amount Different Per Hour
                        $leaveHour = (50.0 - $amount) / $amountDifferentPerHour
                    }
                }
                else {
                    if (($amount -ge 50.0) -and ($amount -eq $previousAmount) -and ($previousAmountDifferentPerHour -eq 0.0) -and ($amountDifferentPerHour -eq 0.0)) {
                        $leaveHour = 0.0
                    }
                    else {
                        $leaveHour = 99999
                    }
                }

                
                $output = @{
                    currentDateTime = $currentDateTime
                    subscriptionId = $subscriptionId
                    subscriptionName =  $subscriptionName
                    amount = $amount
                    orderId = $orderId
                    serviceAdministratorEmail = $serviceAdministratorEmail
                    editSubscriptionLink = $editSubscriptionLink
                    effectiveRange = $effectiveRange
                    accountAdministratorEmail = $accountAdministratorEmail
                    subscriptionStatus = $subscriptionStatus

                    amountDifferentPerHour = $amountDifferentPerHour
                    leaveHour = $leaveHour
                    currentUsageRate = -1
                    leaveHour2 = -1
                }
                
                try {
                    $output.currentUsageRate = Get-ServiceCurrentUsage $output
                    
                    $currentTotalUsage = Get-ServiceCurrentTotalUsage $output
                    
                    if ($output.currentUsageRate -gt 0) {
                        if ($currentTotalUsage -ge 50) {
                            $output.leaveHour2 = 0
                        }
                        else {
                            $output.leaveHour2 = (50 - $amount - ($amountDifferentPerHour * 12)) / $output.currentUsageRate
                        }
                    }
                    elseif ($output.currentUsageRate -eq 0) {
                        $output.leaveHour2 = 99999
                    }
                    
                }
                catch {
                    
                }
                
                Write-HistoryLog "-- $subscriptionName -- $subscriptionId -- $amount -- $leaveHour -- $currentUsageRate"
                
                $temp = New-Object PSObject -Property $output
                
                Write-SubscriptionLog $temp
                
                if ($output -ne $null -and $temp -ne $null) {
                    $returnValue += $temp
                }
                
            }
            else {
                Write-HistoryLog "Subscription Name [$($_.subscriptionName)] is skipped. becase it status is [$($_.subscriptionStatus)]"
                #return
            }
            
        }

    }
    catch [exception] {
        #

        #Write-Host "Error" -ForegroundColor red
        #Write-Host $_.Exception.toString() #-ForegroundColor yellow -BackgroundColor black
        #Write-Host "Subscription Name: $subscriptionName" -ForegroundColor red
        
        Write-HistoryLog "Subscription Name: $subscriptionName"
        Write-HistoryLog $_.Exception.toString()
        
        #return $null
    }
    finally {
    
        return $returnValue
        #Remove-Variable -Name data, _doc, win, amount, subscriptionId, orderId, serviceAdministratorEmail, editSubscriptionLink    
    }
}

function Send-Email() {
    [CmdletBinding()]

    param(
        #[parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $SMTPserver = "10.7.1.12",
        
        #[parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $from = "azure_administrator@infocan.net",
        
        #[parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string[]] $to = @(Get-Content -Path "$($logFolder)_email.txt"),
        
        #[parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [string] $subject = "Message! ",
        
        [string] $emailbody = "",
        [string] $file = $null,

        [int] $priority = 0
    )
    
    begin {
    }
    
    
    process {
    
        try {
       
            $smtpClient = new-object Net.Mail.SMTPclient($SMTPserver)
            #$msg = new-object Net.Mail.MailMessage($from, "", $subject, $emailbody)
            $msg = new-object Net.Mail.MailMessage
            $msg.from = $from
            $msg.subject = $subject
            $msg.body = $emailBody
            
            # http://msdn.microsoft.com/en-us/library/ms223213.aspx
            # Normal | High | Low
            if ($priority -eq 2) {
                $msg.priority = [System.Net.Mail.MailPriority]::High
            }

            $msg.isBodyhtml = $true
            
            #$msg.to.Add("")
            $to | foreach-object { $msg.to.Add($_ ) }
            if ($to.Count -le 0) { 
                $msg.to.Add("eddie_chow@infocan.net")
            }
            
            #
            if (($null, '') -notcontains $file) {
                $attachment = New-Object System.Net.Mail.Attachment –ArgumentList $file, ‘Application/Octet’
                $msg.attachments.add($attachment)
                
                #$today = Get-Date -format "yyyyMMdd"
                #if (Test-Path "$($logfolder)history\history.$($today).txt") {
                #    $msg.attachments.add("$($logfolder)history\history.$($today).txt")
                #}
            }
                   
            $smtpClient.send($msg)
            
            if ($null, '' -notcontains $file) {
                $attachment.Dispose()
            }
        }
        catch [Exception] {
            Write-HistoryLog "Cannot Send Email. `nSubject: '$subject'`n Body: '$emailBody'"
            Write-HistoryLog $_.Exception.toString()
        }
    }
    
    end {
        
    }
}

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

# This Function copied from above.
function Write-OperationLog([string] $message)
{
    try {
        #Add-Content $logfolder"history."$currentDateTimeFileFormat".log" -Value $message -Encoding unicode
        Add-Content "$($logfolder)operation\$($operationLogFile)" -Value "$($message)<br>" -Encoding utf8
    }
    catch {}
}


function Write-SubscriptionLog()
{
    param([object] $subscription)
    
    process {
    
        try {
            if ($subscription -ne $null -and $subscription.subscriptionId -ne $null) {
                $subscriptionFilePath = "$($logfolder)subscriptions\$($subscription.subscriptionId).txt"
                if ((Test-Path -Path $subscriptionFilePath) -eq $false) {
                    Add-Content $subscriptionFilePath -Value "amount`tcurrentDatetime`teffectiveRange`tserviceAdministratorEmail`tsubscriptionStatus`tcurrentUsageRate`tleaveHour`tleaveHour2" -Encoding utf8    
                }
                $today = Get-Date -format "yyyyMMdd"
                $message = "$($subscription.amount)`t$($subscription.currentDatetime)`t$($subscription.effectiveRange)`t$($subscription.serviceAdministratorEmail)`t$($subscription.subscriptionStatus)`t$($subscription.currentUsageRate)`t$($subscription.leaveHour)`t$($subscription.leaveHour2)"
                Add-Content $subscriptionFilePath -Value $message -Encoding utf8
            }
        }
        catch [exception] {
            Write-HistoryLog $_.Exception.toString()
        }
        
    }
}


function Update-SubscriptionAccount([string]$subscriptionEditLink, [string]$subscriptionName = $null, [string]$serviceAdministratorEmail = $null) {
    
    $target = Get-Date -format "_ddHHmmssffff"
    
    if ($null, "" -contains $subscriptionEditLink) { return $null; }
    if ($null, "" -contains $target) { $target = "default"; }
    
    if ($subscriptionEditLink -like "/*") {
        $subscriptionEditLink = "https://account.windowsazure.com$($subscriptionEditLink)" 
    }
    
    & {    
        $win = $rootWindow.open("$subscriptionEditLink", "$target", "", $false)
        if ($ie -ne $null) {
            $ie.visible = $false
        }
        
        try {
            while ($win.document -eq $null) { Start-Sleep -Milliseconds 250; }
            $_doc = $win.document
            
            $retryTimes = 0
            
            while ($_doc.location.toString() -ne $subscriptionEditLink) {
                
                if (IsRequireLogin($_doc.location.toString())) {
                    
                    if ($win -ne $null) {
                        $win.close()
                    }
                    $win = $rootWindow.open("$subscriptionEditLink", "$target", "", $false)
                    if ($ie -ne $null) {
                        $ie.visible = $false
                    }
                    
                    while ($win.document -eq $null) { Start-Sleep -Milliseconds 250; }
                    $_doc = $win.document
                    #return Update-SubscriptionAccount($subscriptionEditLink, $subscriptionName, $serviceAdministratorEmail)

                    if ($retryTimes -gt 3) {
                        Send-Email -subject "Azure Exception Report" -emailbody "Cannot update Subscription Account because login failure. [$subscriptionEditLink]<br/>" -priority 2
                        throw "Login Fail"
                        return;
                    }

                }
                else {
                    throw "Login Fail"
                    return $null
                }
                
            }
            
            while (($_doc.readyState -ne 'complete') -or ($_doc.body -eq $null) -or ($_doc.body.getElementsByClassName -eq $null)) { Start-Sleep -Milliseconds 250; } 
            $_doc.execCommand("stop")
            
            $data = $_doc.body;
            
            $_origianlSubsccriptionName = $_doc.getElementById("FriendlyName").value
            if ($null, "" -notcontains $subscriptionName) {
                $_doc.getElementById("FriendlyName").value = $subscriptionName
            }
            
            $_origianserviceAdministratorEmail = $_doc.getElementById("ServiceAdminEmail").value
            if ($null, "" -notcontains $serviceAdministratorEmail) {
                $_doc.getElementById("EditSubscriptionServiceAdminModel_ServiceAdminEmail").value = $serviceAdministratorEmail
            }
            
            #Write-Host "$subscriptionName`t$amount`t$subscriptionId`t$serviceAdministratorEmai`t$orderId"

            $_doc.getElementById("save-button").click()

            $updateDateTime = Get-Date -f "yyyy-MM-dd HH:mm:ss"
            
            #Add-Content $logfolder"history."$currentDateTimeFileFormat".log" -Value "$updateDateTime`t$_origianlSubsccriptionName`t$_origianserviceAdministratorEmail`t$subscriptionName`t$serviceAdministratorEmail`t$subscriptionEditLink" -Encoding unicode
            Write-HistoryLog -message "$updateDateTime`t$_origianlSubsccriptionName`t$_origianserviceAdministratorEmail`t$subscriptionName`t$serviceAdministratorEmail`t$subscriptionEditLink"
            Write-OperationLog -message "Update Subscription`t$_origianlSubsccriptionName ($_origianserviceAdministratorEmail) -> $subscriptionName ($serviceAdministratorEmail)`tSuccess<br/>"
        }
        catch [exception] {
            #

            #Write-Host "Error" -ForegroundColor red
            #Write-Host $_.Exception.toString() -ForegroundColor yellow -BackgroundColor black
            
            Write-HistoryLog "Error"
            Write-HistoryLog $_.Exception.toString()
            
            Send-Email -subject "Azure Exception Report" -emailbody "Cannot update Subscription Account because login failure. [$subscriptionEditLink]<br/>" -priority 2
            
            return $null
        }
        finally {
        
            if ($win -ne $null) {
                $win.close()
            }
            
            #Remove-Variable -Name data, _doc, win, amount, subscriptionId, orderId, serviceAdministratorEmail, editSubscriptionLink    
        }

    }
    
}

function Load-SubscriptionData() {
    param(
        [string]$file
    )
    
    begin {
    }
    
    process {
        #return Import-CSV "$file" -delimiter "`t"
        return Import-CSV "$file"
    }
    
    end {
    }
}


function Init() {
    param()
    
    begin {}
    
    process {

        #Measure-Command {
        
        if (Test-Path "$($logfolder)operation\$($operationLogFile)") {
            Remove-Item "$($logfolder)operation\$($operationLogFile)"
        }

        #
        $ie = Get-WebConsole

        $ie.navigate("https://account.windowsazure.com/Subscriptions"); 
        while ($ie.Busy -eq $true) { Start-Sleep -Milliseconds 500; } 
        
		$loginRepeatCount = 0
		
        while ($ie.LocationURL -notlike "https://account.windowsazure.com/Subscriptions*") {
			$loginRepeatCount++
			if ($loginRepeatCount -gt 3) {
				Logout
				Write-HistoryLog "Cannot login to Azure. Try to restart on next hours."
				#throw "Cannot login to Azure. Try to restart on next hours."
				return
			}
		
            Write-HistoryLog "Request Login"
            
            Login($loginName)
            DoLogin
            
            $ie.navigate("https://account.windowsazure.com/Subscriptions"); 
            while ($ie.Busy -eq $true) { Start-Sleep -Milliseconds 500; } 
			
			Start-Sleep -Milliseconds 2000;
        }
        
        Write-HistoryLog "Login Success"
        
        $doc = $ie.document
        $rootWindow = $doc.parentWindow
        #$doc.execCommand("stop")
        
        #
        $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $currentDateTimeFileFormat = Get-Date -Format "yyyy-MM-ddTHHmmss"
        
        Write-HistoryLog "Current Time: $currentDateTime"


        # Load Previous Record
        $lastDataLogFile = Get-LastLogFile
        Write-HistoryLog "Last Data Log File: [$lastDataLogFile]"
        if ("", $null -notcontains $lastDataLogFile) {
            $sData = Load-SubscriptionData -file $lastDataLogFile
            $count = $sData.Count
            Write-HistoryLog "Number Of Records: [$count]" 
        }
       
        
        $logData = @()
        $i = 0
        $subscriptions = @()
        
        while ($ie.Busy -eq $true) { Start-Sleep -Milliseconds 1000; } 
        while (('complete', 'loaded', 'interactive' -notcontains $doc.readyState) -or ($doc.body -eq $null) -or ($doc.body.getElementsByClassName -eq $null)) { Start-Sleep -Milliseconds 200; $doc = $ie.document } 

        try {
            # Speed Up
            
            try {
                #$subscriptions = $doc.body.getElementsByClassName("subscription-item") | foreach-object {
                #$body = @($ie.document.documentelement.getelementsbytagname('body'))[0]
                $list = $doc.body.getElementsByClassName('subscription-item')
                
                Write-HistoryLog "Read Subscription List::: $($list.Count)"
                
                $list | WHERE-OBJECT { $_ -ne $null -and $_.href -ne $null } | foreach-object {
                    [string] $href = $_.href
                    [string] $search = $_.search
                    [string] $subscriptionName = @($_.getElementsByClassName("name"))[0].innerText
                    [string] $subscriptionStatus = @($_.getElementsByClassName("status"))[0].innerText
                    
                    $subscriptions += @{
                        href = $href
                        search = $search
                        subscriptionName = $subscriptionName
                        subscriptionStatus = $subscriptionStatus
                    }
                    
                }
                
                Write-HistoryLog "Read Subscription List::: $($subscriptions.Count)"
                
            }
            catch {
                Write-Host $_.Exception.toString()
                throw "Cannot read subscription list from Azure Portal."
            }
			
			## Get Subscription List for Report
			$includeList = Import-CSV -Path "$($logfolder)_subscriptionList.txt" -Delimiter `t
            $includeListItems = $includeList | Where-Object { $null, "" -notcontains $_.subscriptionId } | % { $_.subscriptionId }
			$includeListItemsNames = $includeList | Where-Object { $null, "" -notcontains $_.subscriptionName } | % { $_.subscriptionName }
			
			$includeListAsString = "var includeList = [""" + [string]::join(""",""", $includeListItemsNames) + """];"
			
            ## Inject ajax request on the azure page. and write data to "records\"
            $scriptContent = Get-Content "$($processFolder)loader.js"
			$scriptContent = $includeListAsString + $scriptContent
            $ie.document.parentWindow.ExecScript($scriptContent, "javascript")
			
            Start-Sleep -Seconds 15
            
			$jsLoaderStartTime = Get-Date
			$jsLoaderContext = $doc.getElementById("resultObj").innerText
            while ($null, "" -contains $jsLoaderContext) {
				if (((Get-Date) - $jsLoaderStartTime).TotalMinutes -ge 20) { throw "Cannot read subscription list from Azure Portal. Timeout"; break; }
                if ($doc.getElementById("resultObj") -eq $null) {
                    throw "Cannot read subscription list from Azure Portal."
                    break;
                }
				
				$jsLoaderContext = $doc.getElementById("resultObj").innerText
                Start-Sleep -Seconds 15
            }
            
            $tempFile = "$($logFolder)records\$($currentDateTimeFileFormat).csv"
            if (Test-Path $tempFile) {
                Clear-Content $tempFile
            }
            Add-Content $tempFile -value "subscriptionId,subscriptionName,amount,orderid,serviceAdminEmail,accountAdminEmail,subscriptionStatus,effectiveRange,editSubscriptionHref" -Encoding utf8
            Add-Content $tempFile -value "$jsLoaderContext" -Encoding utf8
            
			
            $logData = Get-UsageByFile $tempFile
			Write-HistoryLog "Read Subscription Data::: $($logData.Count)"

            #Write-HistoryLog "Read Subscription Data:::"
            #Foreach($subscription in $subscriptions) {
            #    $i++
            #    
            #    if ("Active","活动","作用中" -contains $subscription.subscriptionStatus) {
            #        #$logData += Get-Usage -href $href -target "$subscriptionName$i"
            #        $logLocalData = Get-Usage -href $subscription.href -target "__$i"
            #        if ($logLocalData -eq $null) {
            #            Write-HistoryLog "Subscription Name [$($subscription.subscriptionName)] cannot load any data."
            #        }
            #        else {
            #            $logData += $logLocalData
            #            Write-SubscriptionLog $logLocalData
            #        }
            #    }
            #    else {
            #        Write-HistoryLog  "Subscription Name [$($subscription.subscriptionName)] is skipped. becase it status is [$($subscription.subscriptionStatus)]"
            #    }
            #    
            #}
            
            
            
            #$logData = $logData | WHERE-Object { ($_ -ne $null) -and ($_.subscriptionId -ne [DBNull]::Value) }
            
            $filePath = "$($logfolder)reports\$($currentDateTimeFileFormat).csv"
            if ($logData -ne $null -and $logData.Count -gt 0) {
                #$logData | Export-Csv $filePath -encoding utf8 -NoTypeInformation -Force -Delimiter `t
                $logData | Sort-Object -property subscriptionName | Export-Csv -Path $filePath -encoding utf8 -NoTypeInformation -Force
                
                Start-Sleep -Seconds 10
                ##
                $filePath = "$($logfolder)operation\$($currentDateTimeFileFormat).csv"
                $logData | Where-Object { ($includeListItems.Count -eq 0) -or ($includeListItems -contains $_.subscriptionId) } | Select-Object subscriptionName, amountDifferentPerHour, leaveHour, amount, orderId, subscriptionId, serviceAdministratorEmail, effectiveRange, currentUsageRate, leaveHour2 | Sort-Object -property subscriptionName | Export-CSV -Path $filePath -encoding utf8 -NoTypeInformation -Force
				#$logData | Where-Object { ($includeListItems.Count -eq 0) -or ($includeListItems -contains $_.subscriptionId) } | Select-Object subscriptionName, amount, currentUsageRate, leaveHour2 | Sort-Object -property subscriptionName | Export-CSV -Path $filePath -encoding utf8 -NoTypeInformation -Force
                
                Write-HistoryLog "Export CSV Log File ::: $filePath"
            }
            else {
                Write-HistoryLog "No Records Loaded"
                # May Need to Send Exception Message?!
            }
            
            Start-Sleep -Seconds 10

            
            # Start Reclaim Subscription Account
            Write-HistoryLog "Start to reclaim subscription account to [$accountForRemoveServices]"
            # -and ($accountForRemoveServices -ne $_.serviceAdministratorEmail)
            $logData | WHERE-OBJECT { ($_ -ne $null) -and ($_.leaveHour -ne 0) -and ($_.amount -ge 33.5 -and ($_.leaveHour -lt 13 -or $_.amount -ge 42)) -and ($accountForRemoveServices -ne $_.serviceAdministratorEmail) } | foreach-object {
            
                Update-SubscriptionAccount -subscriptionEditLink $_.editSubscriptionLink -serviceAdministratorEmail $accountForRemoveServices
                $_.serviceAdministratorEmail = $accountForRemoveServices
                #Update-SubscriptionAccount -subscriptionEditLink "https://account.windowsazure.com/Subscriptions/EditDetails?subscriptionId=%2BLOyKgAAAAAAADcA&returnUrl=https%253a%252f%252faccount.windowsazure.com%252fSubscriptions%252fStatement%253fsubscriptionId%253d%25252BLOyKgAAAAAAADcA&friendlyName=Pay-As-You-Go-Account-52&serviceAdminEmail=koolala3%40hotmail.com" -serviceAdministratorEmail "eddie_chow@infocan.net"
            }
           
            # Update Publishing Settings. 
            Write-HistoryLog "Update Publishing Settings"
            Update-PublishSetting $logData

            # Remove Services
            #  -and ($accountForRemoveServices -eq $_.serviceAdministratorEmail)
            #$removeServiceList = @($logData | WHERE-OBJECT { ($_ -ne $null) -and ($_.amount -ge 33) -and ( (($_.leaveHour -ne 0) -and ($_.leaveHour -lt 13) -and ($_.amountDifferentPerHour -ne 0)) -or (($_.currentUsageRate -gt 0) -and ($_.amount -ge 50)) ) })
            $removeServiceList = @($logData | WHERE-OBJECT { ($_ -ne $null) -and ($_.amount -ge 33) -and ( (($_.leaveHour -ne 0) -and (($_.leaveHour -lt 12.5 -and $_.currentUsageRate -ge 1.2) -or ($_.leaveHour -lt 11.5 -and $_.currentUsageRate -lt 1.2)) -and ($_.amountDifferentPerHour -gt 0)) -or ($_.leaveHour2 -le 0 -and $_.leaveHour2 -ne -1 ) -or (($_.currentUsageRate -gt 0) -and ($_.amount -ge 50)) ) })
            if ($removeServiceList.Count -gt 0) {
                Write-HistoryLog "Start to remove Services"
                
                Remove-Service $removeServiceList
            }
            
            Write-HistoryLog "End Process ======"
            
            Start-Sleep -Seconds 10
            
            $emailBody = ""
            $emailDataPath = "$($logfolder)operation\$($operationLogFile)"
            if (Test-Path $emailDataPath) {
                try {
                    $emailBody = [Io.File]::ReadAllText($emailDataPath) 
                }
                catch {}
            }
            
			#$emailBody += & { (Import-CSV $filePath) | ConvertTo-Html }
            $emailBody += & { (Import-CSV $filePath) | Select-Object subscriptionName, amount, currentUsageRate, leaveHour2 | ConvertTo-Html }
            
            Send-Email -emailbody $emailBody -subject "Azure Usage Report!" -file $filePath -priority 0
            
        }
        catch [exception] { 
        
            $errMsg = $_.Exception.toString()
            if ($errMsg -like '*Cannot read subscription list from Azure Portal*') {
                Send-Email -emailbody "Found error and try to restart now:`n<br>$($errMsg)" -subject "Azure Exception Report!" -priority 2
                throw $errMsg
            }
            elseif ($errMsg -like '*System.Reflection.TargetInvocationException*') {
                Send-Email -emailbody "Found error and try to restart now:`n<br>$($errMsg)" -subject "Azure Exception Report!" -priority 2
                throw $errMsg
            }
            else {
                #Write-Host $errMsg -ForegroundColor red -BackgroundColor black
                Write-HistoryLog $errMsg
                
                Send-Email -emailbody $errMsg -subject "Azure Exception Report!" -priority 2
            }
            
        }
        finally {
            Logout
            
            Start-Sleep -Seconds 200
            
            #if (Test-Path "$($logfolder)operation\$($operationLogFile)") {
            #    Remove-Item "$($logfolder)operation\$($operationLogFile)"
            #}
        }

        #}

        #$req = [System.Net.HttpWebRequest]::Create("http://www.infocan.net")
        #$req.GetResponse()
    
    }
    
    end {
        
    }
}


function Convert-Str2Dec([string] $value) {

    & {
        try {
            return [decimal]::parse($value, [System.Globalization.NumberStyles]::Currency)
        }
        catch [Exception] {
            $tempValue = $value.Split('$')
            if ($tempValue.Count -gt 0) {
                return [decimal]::parse($tempValue[$tempValue.Count-1])
            }
            else {
                throw "Format Exception"
            }
        }
    }
}

function Update-PublishSetting() {
    ## Generate publsing settings file (Contents)
    ## Import the generate file
    
    param($subscriptions)
    
    $fileName = "$($logFolder)publishsettings/infocan$($currentDateTimeFileFormat).publishsettings"
    
    $prefix = 
'<?xml version="1.0" encoding="utf-8"?>
<PublishData>
  <PublishProfile
    PublishMethod="AzureServiceManagementAPI"
    Url="https://management.core.windows.net/"
    ManagementCertificate="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">'
 
    $subfix = 
'</PublishProfile>
</PublishData>'

    
    Add-Content $fileName -Value $prefix # -Encoding unicode

    $subscriptions | WHERE-OBJECT { $_ -ne $null -and $_.subscriptionId -ne "" -and $_.subscriptionName -ne ""} | foreach-object {
        
        $body = "    <Subscription
      Id=`"$($_.subscriptionId)`" 
      Name=`"$($_.subscriptionName)`" />"
        
        Add-Content $fileName -Value $body # -Encoding unicode
      
    }
    
    Add-Content $fileName -Value $subfix # -Encoding unicode
    
    try {
        Import-AzurePublishSettingsFile -PublishSettingsFile $fileName
    }
    catch [Exception] {
        Write-HistoryLog $_.Exception.toString()
    }
    
}

function Get-ServiceCurrentTotalUsage() {
    param($subscription)
    
    process {
        $data = 0
        try {
            $data =  (Import-csv "$($logfolder)subscriptions\$($subscription.subscriptionId).txt" -delimiter `t | Where-Object { ( [decimal]::parse( $_.currentUsageRate, [System.Globalization.NumberStyles]::Currency) -gt 0) -and (((Get-Date) - (Get-Date $_.currentDatetime)).TotalHours -le 12) } | Measure-Object currentUsageRate -Sum).Sum * 1.5
			# + $subscription.currentUsageRate
			Write-HistoryLog "[TEST ONLY] Dummy Current Amount: $($logfolder)subscriptions\$($subscription.subscriptionId).txt -- $data"
			$data = $data + $subscription.amount;
        }
        catch [exception] {

        }
        
        #return $data * 1.0119
        return $data
    }
}


function Get-ServiceCurrentUsage() {
    param($subscription)
    
    process {
        Set-ExecutionPolicy bypass -Scope Process -Force
        
        [decimal] $usagePerHour = 0
    
        try {
            Select-AzureSubscription -SubscriptionName "$($subscription.subscriptionName)" -ErrorAction silentlycontinue
        }
        catch [Exception] {
            Write-HistoryLog "Select azure subscription failure"
            $usagePerHour = -1
        }
    
        if ((Get-AzureSubscription -Current -ErrorAction silentlycontinue).subscriptionId -eq $subscription.subscriptionId) {
        
            $services = Get-AzureService -ErrorAction silentlycontinue
            
            $services | WHERE-OBJECT { $_ -ne $null -and ($null, "") -notcontains $_.serviceName } | % {
                
                Write-HistoryLog "$($subscription.subscriptionId) -- $($subscription.subscriptionName) -- $($_.serviceName)"
                
                $vm = Get-AzureVM -ServiceName "$($_.serviceName)" -ErrorAction silentlycontinue
                if ($vm -ne $null) {
                    Write-HistoryLog "VM: -- $($vm.InstanceSize)"
                    switch ($vm.InstanceSize) {
                        "ExtraSmall" {
                            $usagePerHour += 0.03875
                        }
                        "Small" {
                            $usagePerHour += 0.08
                        }
                        "Medium" {
                            $usagePerHour += 0.16
                        }
                        "Large" {
                            $usagePerHour += 0.32
                        }
                        "ExtraLarge" {
                            $usagePerHour += 0.64
                        }
                        default {
                            $usagePerHour += 0.32
                        }
                    }
                }
                else {
                    $vm = Get-AzureDeployment -ServiceName "$($_.serviceName)" -ErrorAction silentlycontinue
                    $vm | WHERE-OBJECT { $_ -ne $null -and $_.RoleInstanceList -ne $null } | % {
						Write-HistoryLog "VM Deployment: -- $($_.RoleInstanceList.InstanceSiz)"
                        switch ($_.RoleInstanceList.InstanceSize) {
                            "ExtraSmall" {
                                $usagePerHour += 0.03875
                            }
                            "Small" {
                                $usagePerHour += 0.08
                            }
                            "Medium" {
                                $usagePerHour += 0.16
                            }
                            "Large" {
                                $usagePerHour += 0.32
                            }
                            "ExtraLarge" {
                                $usagePerHour += 0.64
                            }
                            default {
                                $usagePerHour += 0.32
                            }
                        }
                    }
                }
                
            }
            
            #$spaceSize = Get-AzureDisk -Confirm:$true -Verbose:$false -ErrorAction silentlycontinue
            $spaceSize = Get-AzureDisk -ErrorAction silentlycontinue
            $spaceSize | Where-Object { $_ -ne $null -and $_.DiskName -ne $null } | % {
                
                Write-HistoryLog "Disk: -- $($_.DiskName) -- $($_.OS) -- $($_.DiskSizeInGB)"
                #if ($_.OS -eq "") {
                    $usagePerHour += ([decimal]::parse($_.DiskSizeInGB) * 0.125) / 30 / 16
                    #$usagePerHour += ([decimal]::parse($_.DiskSizeInGB) * 0.093) / 30 / 16
                #}
                
            }
            
            #Write-HistoryLog "Usage Per Hour: -- $usagePerHour"
        }
        else {
            $usagePerHour = -1
            Write-HistoryLog "Warning! Cannot read $($subscription.subscriptionName) -- $($subscription.subscriptionId)"
            if (($subscription.amount -gt 0) -and ($subscription.amount -lt 50) -and ((0, 99999) -notcontains $subscription.amountDifferentPerHour)) {
                Write-ErrorLog "Warning! Cannot read $($subscription.subscriptionName) -- $($subscription.subscriptionId)"
            }
        }
        
        return $usagePerHour
    }

}


function Remove-Service() {

    param($subscriptions)
    
    process {
    
        if (Test-Path "$($logfolder)error.txt") {
            Remove-Item "$($logfolder)error.txt"
        }

        $subscriptions | WHERE-OBJECT { $_ -ne $null -and $_.subscriptionName -ne $null -and (($_.leaveHour -lt 15 -and ($_.currentUsageRate -gt 0)) -or ($_.leaveHour2 -lt 2 -and $_.leaveHour2 -ne -1 )) } | Sort-Object -Property amount -Descending | % {
        
            $ScriptBlock = {
                param([object] $subscription, [string] $operationLogFile)
                
                process {
                    $logfolder = "c:\temp\log\"
                    
                    # Add Modules Here
                    try {
                        if ($moduleLoaded -eq $null) {
                            Get-ChildItem 'C:\Program Files (x86)\Microsoft SDKs\Windows Azure\PowerShell\Azure\*.psd1' | ForEach-Object {Import-Module $_}
                            $moduleLoaded = $true
                        }
                    }
                    catch {}
                    
                    # This Function copied from above.
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
                    
                    # This Function copied from above.
                    function Write-OperationLog([string] $message)
                    {
                        try {
                            #Add-Content $logfolder"history."$currentDateTimeFileFormat".log" -Value $message -Encoding unicode
                            Add-Content "$($logfolder)operation\$($operationLogFile)" -Value "$($message)<br/>" -Encoding utf8
                        }
                        catch {}
                    }
                    
                    
                    if ($subscription.subscriptionName -eq "") { return; }
                    Write-HistoryLog -message "Processing '$($subscription.subscriptionId)' --  $($subscription.subscriptionName)"
                    
                    # Run Azure cmdlet Now!
                    
                    try {
                        Select-AzureSubscription -SubscriptionName "$($subscription.subscriptionName)" -ErrorAction SilentlyContinue
                    }
                    catch [Exception] {
                        Write-HistoryLog "Select azure subscription failure"
                        Write-ErrorLog "$($subscription.subscriptionId)`t$($subscription.subscriptionName)`t$($subscription.subscriptionName)`tSelect Subscription"
                        # return
                    }
                    
                    if ((Get-AzureSubscription -Current -ErrorAction SilentlyContinue).SubscriptionId -eq $subscription.subscriptionId) {
                        $services = Get-AzureService -ErrorAction silentlycontinue
                        try {
                            $services | WHERE-OBJECT { $_ -ne $null -and ($null, "") -notcontains $_.serviceName } | foreach-object {
                                try {
                                    Get-AzureDeployment –ServiceName "$($_.serviceName)" | Remove-AzureDeployment -Force
                                    Remove-AzureService -ServiceName "$($_.serviceName)" -Force
                                    
                                    Write-HistoryLog "Removed Azure Service: $($_.serviceName) - $($subscription.subscriptionId)' --  $($subscription.subscriptionName)"
                                }
                                catch [Exception] {
                                    Write-HistoryLog $_.Exception.toString()
                                    Write-ErrorLog "$($subscription.subscriptionId)`t$($subscription.subscriptionName)`t$($subscription.subscriptionName)`tRemove-AzureDeployment`t$($_.serviceName)"
                                }

                            }
                        }
                        catch [Exception] {
                            Write-HistoryLog $_.Exception.toString()
                        }

                        # Remove VM
                        #try {
                        #    $vms = Get-AzureVM
                        #    $vms | foreach-object {
                        #        try {
                        #            Remove-AzureVM -name "$($_.name)"
                        #            Write-HistoryLog "Removed Azure VM: $($_.name)"
                        #        }
                        #        catch [Exception] {
                        #            Write-HistoryLog $_.Exception.toString()
                        #            Write-ErrorLog "$($subscription.subscriptionId)`t$($subscription.subscriptionName)`t$($subscription.subscriptionName)`tRemove-AzureVM`t$($_.name)"
                        #        }
                        #    }
                        #}
                        #catch [Exception] {
                        #    Write-HistoryLog $_.Exception.toString()
                        #}
                        
                        # Remove VHD
                        try {
                            $vhds = Get-AzureDisk -ErrorAction silentlycontinue
                            $vhds | WHERE-OBJECT { $_ -ne $null -and ($null, "") -notcontains $_.DiskName } | foreach-object {
                                try {
                                    Remove-AzureDisk -DiskName "$($_.DiskName)"
                                    Write-HistoryLog "Removed Azure Disk: $($_.DiskName) - $($subscription.subscriptionId)' --  $($subscription.subscriptionName)"
                                }
                                catch [Exception] {
                                    Write-HistoryLog $_.Exception.toString()
                                    Write-ErrorLog "$($subscription.subscriptionId)`t$($subscription.subscriptionName)`t$($subscription.subscriptionName)`tRemove-AzureDisk`t$($_.DiskName)"
                                }
                            }
                        }
                        catch [Exception] {
                            Write-HistoryLog $_.Exception.toString()
                        }
                        
                        
                        # Remove Network
                        try {
                            $storages = Get-AzureStorageAccount -ErrorAction silentlycontinue
                            $storages | WHERE-OBJECT { $_ -ne $null -and ($null, "") -notcontains $_.StorageAccountName } | % {
                                try {
                                    Remove-AzureStorageAccount -StorageAccountName "$($_.StorageAccountName)"
                                    Write-HistoryLog "Removed Azure Storage Account: $($_.StorageAccountName) - $($subscription.subscriptionId)' --  $($subscription.subscriptionName)"
                                }
                                catch [Exception] {
                                    Write-HistoryLog $_.Exception.toString()
                                    Write-ErrorLog "$($subscription.subscriptionId)`t$($subscription.subscriptionName)`t$($subscription.subscriptionName)`tRemove-AzureStorageAccount`t$($_.StorageAccountName)"
                                }
                            }
                        }
                        catch [Exception] {
                            Write-HistoryLog $_.Exception.toString()
                        }
                        
                        # Remove Affinity Group
                        try {
                            Get-AzureAffinityGroup | WHERE-OBJECT { $_ -ne $null -and ($null, "") -notcontains $_.Name } | % {
                                try {
                                    Remove-AzureAffinityGroup -Name "$($_.Name)"
                                    Write-HistoryLog "Removed Azure Affinity Group: $($_.Name) - $($subscription.subscriptionId)' --  $($subscription.subscriptionName)"
                                }
                                catch [Exception] {
                                    Write-HistoryLog $_.Exception.toString()
                                    Write-ErrorLog "$($subscription.subscriptionId)`t$($subscription.subscriptionName)`t$($subscription.subscriptionName)`tRemove-AzureAffinityGroup`t$($_.Name)"
                                }
                            }
                        }
                        catch [Exception] {
                            Write-HistoryLog $_.Exception.toString()
                        }
                        
                        # Remove VNetConfig
                        try {
                            Remove-AzureVNetConfig
                            #Write-HistoryLog "Removed Azure VNetConfig"
                        }
                        catch [Exception] {
                            Write-HistoryLog $_.Exception.toString()
                            Write-ErrorLog "$($subscription.subscriptionId)`t$($subscription.subscriptionName)`t$($subscription.subscriptionName)`tRemove-AzureVNetConfig`t"
                        }
                        
                        # Remove Azure SQL Database Server
                        try {
                            try {
                                Get-AzureSqlDatabaseServer | Remove-AzureSqlDatabaseServer -Force
                                #Write-HistoryLog "Removed Azure Azure Sql Database Server - $($subscription.subscriptionId)' --  $($subscription.subscriptionName)"
                            }
                            catch [Exception] {
                                Write-HistoryLog $_.Exception.toString()
                                Write-ErrorLog "$($subscription.subscriptionId)`t$($subscription.subscriptionName)`t$($subscription.subscriptionName)`tRemove-AzureSqlDatabaseServer`t"
                            }
                        }
                        catch [Exception] {
                            Write-HistoryLog $_.Exception.toString()
                        }
                        
                        # Remove Certificate
                        try {
                            $services | WHERE-OBJECT { $_ -ne $null -and ($null, "") -notcontains $_.serviceName } | foreach-object {
                                try {
                                    Get-AzureCertificate -ServiceName "$($_.serviceName)" | Remove-AzureCertificate
                                    Write-HistoryLog "Removed Azure Certificate: $($_.serviceName) - $($subscription.subscriptionId)' --  $($subscription.subscriptionName)"
                                }
                                catch [Exception] {
                                    Write-HistoryLog $_.Exception.toString()
                                    Write-ErrorLog "$($subscription.subscriptionId)`t$($subscription.subscriptionName)`t$($subscription.subscriptionName)`tRemove-AzureCertificate`t"
                                }
                            }
                        }
                        catch [Exception] {
                            Write-HistoryLog $_.Exception.toString()
                        }
                        
                        // # Remove Subscription Settings
                        try {
                            Remove-AzureSubscription -SubscriptionName $subscription.subscriptionName
                        }
                        catch [Exception] {
                            Write-HistoryLog $_.Exception.toString()
                        }
                        
                        Write-OperationLog -message "Remove Subscription Service`t$($subscription.subscriptionId) $($subscription.subscriptionName)`tSuccess"
                        
                    }
                    else {
                        Write-OperationLog -message "Remove Subscription Service`t$($subscription.subscriptionId) $($subscription.subscriptionName)`tFail"
                        
                        Write-HistoryLog "Subscription Name Not Found or Cannot be select. Please try to update publishingsettings file. -  - $($subscription.subscriptionId)' --  $($subscription.subscriptionName)"
                        Write-ErrorLog "$($subscription.subscriptionId)`t$($subscription.subscriptionName)`t$($subscription.subscriptionName)`tSubscription Not Found or Cannot be select. Please try to update publishingsettings file.`t"
                    }
                    
                    Start-Sleep -Seconds 5
                }
            }
            
            $path = "$($logfolder)removedServices\$($_.subscriptionId)"
            if (Test-Path $path) {
                return;
            }
            else {
            
                Start-Job -ScriptBlock $ScriptBlock -ArgumentList $_, $operationLogFile
                
                try {
                    #Add-Content $logfolder"history."$currentDateTimeFileFormat".log" -Value $message -Encoding unicode
                    #$today = Get-Date -format "yyyyMMdd"
                    #Add-Content "$path" -Value "$($_.subscriptionName)" -Encoding unicode
                }
                catch {}
                
                
                # ...In Serials
                # Wait for all to complete
                While (Get-Job -State "Running") { Start-Sleep 2 }

                # Display output from all jobs
                Get-Job | Receive-Job

                # Cleanup
                Remove-Job *
            
            }
            
        }
        
        # In Parallel
        # Wait for all to complete
        While (Get-Job -State "Running") { Start-Sleep 2 }

        # Display output from all jobs
        Get-Job | Receive-Job

        # Cleanup
        Remove-Job *
        
        #
        if (Test-Path "$($logfolder)error.txt") {
            Send-Email -subject "Exception Report!" -file "$($logfolder)error.txt" -priority 2
        }
    
    }
    
}


# 
function Get-LastLogFile() {
    [string] $returnValue = $null
    
    try {
        $today = Get-Date
        # GCI ==> Get-ChildItem
        #$returnValue = (GCI "$($logfolder)reports\" -recurse -include "*.csv" | sort LastWriteTime -desc | select -first 1).FullName
        #$returnValue = (GCI "$logfolder" -recurse -include "*.csv" | select -last 1).FullName
        $returnValue = (GCI "$($logfolder)reports\" -recurse -include "*.csv" | WHERE-OBJECT { $timeDiff = ($today - $_.LastWriteTime).TotalHours; return $timeDiff -gt 1 -and $timeDiff -lt 3 } | sort Name -desc | select -first 1).FullName
        if ("", $null -contains $returnValue) {
            $returnValue = (GCI "$($logfolder)reports\" -recurse -include "*.csv" | sort Name -desc | select -first 1).FullName
        }
    }
    catch [Exception] {
        $returnValue = $null
    }
    
    return $returnValue
}


# [Main]
INIT
#exit