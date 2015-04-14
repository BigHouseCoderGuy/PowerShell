#Build a table of triggered alarms in vCenter and list those that are unacknowledged.

Add-pssnapin VMware.VimAutomation.Core
Set-executionpolicy remotesigned -Confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -Confirm:$false
connect-viserver localhost

$alarms = @()
$alarms += Get-TriggeredAlarms $vCenter

#create table to capture Alarm info
$atable = New-Object system.Data.DataTable "atable"
$col1 = New-Object system.Data.DataColumn Entity,([string])
$col2 = New-Object system.Data.DataColumn Status,([string])
$col3 = New-Object system.Data.DataColumn Alarm,([string])
$col4 = New-Object system.Data.DataColumn Time,([string])
$atable.columns.add($col1)
$atable.columns.add($col2)
$atable.columns.add($col3)
$atable.columns.add($col4)

foreach ($alarm in $alarms) {
	if ($alarm.Acknowledged -like "False") {
	$row = $atable.NewRow()
	$row.Entity = $alarm.Entity
	$row.Status = $alarm.Status
	$row.Alarm = $alarm.Alarm
	$row.Time = $alarm.Time
	$atable.Rows.Add($row)
	}
}

Function Get-TriggeredAlarms {

	$rootFolder = Get-Folder -Server localhost "Datacenters"
 
	foreach ($ta in $rootFolder.ExtensionData.TriggeredAlarmState) {
		$alarm = "" | Select-Object VC, EntityType, Alarm, Entity, Status, Time, Acknowledged, AckBy, AckTime
		$alarm.VC = $vCenter
		$alarm.Alarm = (Get-View -Server $vc $ta.Alarm).Info.Name
		$entity = Get-View -Server $vc $ta.Entity
		$alarm.Entity = (Get-View -Server $vc $ta.Entity).Name
		$alarm.EntityType = (Get-View -Server $vc $ta.Entity).GetType().Name	
		$alarm.Status = $ta.OverallStatus
		$alarm.Time = $ta.Time
		$alarm.Acknowledged = $ta.Acknowledged
		$alarm.AckBy = $ta.AcknowledgedByUser
		$alarm.AckTime = $ta.AcknowledgedTime		
		$alarm
	}

}