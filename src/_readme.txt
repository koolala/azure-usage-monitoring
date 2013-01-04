Perpose:
- Check and remove services (VM,Disk,Cloud Services,SQL Database) when over a budget (Such as US$100).

This program limitation:
- Azure Portal site revamped or any update. The program may fault.
- Do not support 120 subscriptions monitoring. (Azure Portal will block your account to get a http request)
- There are 12 hours delay on billing reports from azure portal site. And no ways to collect and count number of the network usages in last 12 hours. 
  So, the remove services time is not too accuracy. (The final amount may stop between US$90 and US$120)


Requirement:
Platform: Windows Server 2008 / Windows 7
PowerShell with Azure SDK


/services
   /azure-monitor.ps1		# Require to create run once and non-stop Schedule Task to mount the powershell script
   /process.ps1			# Sub script

/log				# 
   /_email.txt			# Email List for Notification Mail.
   /_subscriptionList.txt	# Subscription List for Monitoring
   /_generateSubscriptionList.txt	# javascript. Run by console on azure subscription main page. 


Setup:
1. Copy and two folder to server.
2. Create Task Schedule to run azure-monitor.ps1.   (Run once non-stop.)
3. Config .ps1 settings
   Such as: Folder directory, Number of miniutes to execute the script.
4. Config /log/*.txt file settings
   Such as: Who will receive email notification and normal report.
            Which subscriptions need to monitoring.
