function Get-IPrangeStartEnd 
{ 
    <#  
      .SYNOPSIS   
        Get the IP addresses in a range  
      .EXAMPLE  
       Get-IPrangeStartEnd -start 192.168.8.2 -end 192.168.8.20  
      .EXAMPLE  
       Get-IPrangeStartEnd -ip 192.168.8.2 -mask 255.255.255.0  
      .EXAMPLE  
       Get-IPrangeStartEnd -ip 192.168.8.3 -cidr 24  
    #>  
      
    param (  
      [string]$start,  
      [string]$end,  
      [string]$ip,  
      [string]$mask,  
      [int]$cidr  
    )  
      
    function IP-toINT64 () {  
      param ($ip)  
      
      $octets = $ip.split(".")  
      return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3])  
    }  
      
    function INT64-toIP() {  
      param ([int64]$int)  
 
      return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() ) 
    }  
      
    if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)}  
    if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) }  
    if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)}  
    if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)}  
    if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))}  
      
    if ($ip) {  
      $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring  
      $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring  
    } else {  
      $startaddr = IP-toINT64 -ip $start  
      $endaddr = IP-toINT64 -ip $end  
    }  
      
     $temp=""|Select start,end 
     $temp.start=INT64-toIP -int $startaddr 
     $temp.end=INT64-toIP -int $endaddr 
     return $temp 
}


$serviceTags = Get-AzNetworkServiceTag -Location eastus
$adf = $serviceTags.Values| Where-Object { $_.Name -eq "DataFactory.Eastus"}



#Set New Firewall rules to allow all ips in this service tag
$ServerName = 'yoursqlservername'
$ResourceGroupName = 'yourresourcegroup'


foreach( $i in $adf.Properties.AddressPrefixes|Where-Object({$_ -notlike "*:*"})) 
{
    $ip,$cidr= $i.split('/') ; 
    $startend = Get-IPrangeStartEnd -ip $ip -cidr $cidr;
    Write-Output $startend
    New-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -FirewallRuleName "ADF-$($startend.start.ToString())" -StartIpAddress $startend.start -EndIpAddress $startend.end
}

#Remove All FirewallRules for SQL Server
Get-AzSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $ResourceGroupName |Remove-AzSqlServerFirewallRule

