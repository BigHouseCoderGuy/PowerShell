# Find AD users with passwords expiring soon and notify them. 
# $urgenttable lists users with passwords expiring on the day the script is run can be sent to IT staff.

$notificationstartday = 3           
$sendermailaddress = "no-reply@contoso.com"            
$SMTPserver = "smtp.contoso.com"           
$DN = "DC=contoso,DC=com"

foreach ($user in (Get-ADUser -SearchBase $DN -Filter * -properties mail,passwordneverexpires,enabled))            
{            
    $samaccountname = $user.samaccountname            
    $PSO= Get-ADUserResultantPasswordPolicy -Identity $samaccountname            
    if(-NOT $user.passwordneverexpires -AND $user.enabled)            
        {            
		$pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties pwdLastSet).pwdLastSet)            
		$expirydate = ($pwdlastset).AddDays($defaultdomainpolicyMaxPasswordAge)            
		$delta = ($expirydate - (Get-Date)).Days            
		$comparionresults = (($expirydate - (Get-Date)).Days -le $notificationstartday -and $delta -gt -1)  
		$deadlinedate = $expirydate.ToShortDateString()
		$deadlinetime = $expirydate.ToShortTimeString()
			
		if ($comparionresults)            
            {            
			$mailBody = "Dear " + $user.GivenName + ",`r`n`r`n" 
			$mailBody += "This is an automated notification.`r`n`r`n"				
			$delta = ($expirydate - (Get-Date)).Days            
			$mailBody += "The password for account " + $samaccountname.ToUpper() + " will expire on " + $deadlinedate + " at " + $deadlinetime +". Please change your password at your earliest convenience. If your password expires you will not be able to log in and your email will stop working. If you have any questions or concerns please contact IT via email at itworkorder@biltmore.com or phone at 225-6717.`r`n`r`n"     
			$usermailaddress = $user.mail  
			if ((get-date).date.toshortdatestring() -eq $deadlinedate)
			{
				$urgent = 1
				$row = $urgenttable.NewRow()
				$row.User = $samaccountname.ToUpper()
				$row.ExpireDate = $expirydate
				$urgenttable.Rows.Add($row)
				$urgentcount++		
			}
			else {$urgent = 0}
            SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody $urgent    
            }            
        }                  
}

function SendMail ($SMTPserver,$sendermailaddress,$usermailaddress,$mailBody,$urgent)            
{            
    $smtpServer = $SMTPserver            
    $msg = new-object Net.Mail.MailMessage            
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)            
    $msg.From = $sendermailaddress            
    $msg.To.Add($usermailaddress)
	if($urgent -eq "1"){$msg.Subject = "URGENT: Your password expires today!"}
	else {$msg.Subject = "Your password expires soon."}
    $msg.Body = $mailBody            
    $smtp.Send($msg)  
}            
