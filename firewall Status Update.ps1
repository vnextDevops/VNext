$workspaceName = "wvdeus2loganalytics"
$workspaceRG = "wvdeus2"

$WorkspaceID = (Get-AzOperationalInsightsWorkspace -ResourceGroupName $workspaceRG -Name $workspaceName).CustomerId
$query = 'AzureMetrics
| where MetricName contains "FirewallHealth" 
|where Resource contains "WVDCENTRALINDIAFIREWALL" or Resource contains "WVDWESTEUROPEFIREWALL" or Resource contains "WVDEASTASIAFIREWALL"
| top 100 by TimeGenerated
| project TimeGenerated, Resource , MetricName , Average'
$results = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID -Query $query

$results = [System.Linq.Enumerable]::ToArray($results.Results)

$firewall = Get-AzFirewall
$firewall = $firewall.name
$final_Result = @()
foreach($item in $firewall)
{
$final_Result += $results | Where-Object {$_.Resource -eq "$item"} | Select-Object -Unique
}

Foreach($item in $final_Result)
{
$resource_name = $item.Resource
[Int]$Average = $item.Average
if($Average -lt '95')
{Write-Host $resource_name "is Degraded"}
elseif($Average -lt 99)
{Write-Host "$resource_name is Unhealthy"}
else
{Write-Host "$resource_name is healthy"}
}


