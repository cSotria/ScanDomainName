#---------------------------------- Functions --------------------------------------------#
# Inline if condition
Function IIf($If, $Right, $Wrong) {If ($If) {$Right} Else {$Wrong}}

# Check if url is timeout
Function urlRequest($siteURL){
try{
$r= Invoke-WebRequest $siteURL -TimeoutSec 3 
    if ($r.statusCode -le 210 )
    {
        "Available"
        $r.BaseResponse.Server
    }
    else{
        return "$r.StatusCode"
    }
}
catch [System.Net.WebException] {
  if($_.Exception.Status -eq 'Timeout'){
    return "TimedOut"
  }

}
}


#---------------------------------- Initialization --------------------------------------------#

$file = "C:\Scripts\Powershell\IPa.txt" # File with all domains
$csv = "C:\Scripts\Powershell\out.csv"

$Array = @()
$fileLen = (Get-Content $file).Length
$i = 1


#---------------------------------- Convert Data --------------------------------------------#



foreach($name in Get-Content $file) {
    $i = $i +1
    $ii = [math]::Round($i/$fileLen*100)
    Write-Progress -Activity "Scan in Progress" -Status "$name is currently Scanned ________ $i/$fileLen ________ $ii%   " -PercentComplete ($i/$fileLen*100)
    Start-Sleep -Milliseconds 250
    $ARecord = Resolve-DnsName -Name $name -Type A -ErrorAction SilentlyContinue -ErrorVariable flag 
    $NSRecord = Resolve-DnsName -Name $name -Type NS -ErrorAction SilentlyContinue -ErrorVariable flag 
    $Minformation = Resolve-DnsName -Name $name -Type MINFO -ErrorAction SilentlyContinue -ErrorVariable flag 

    if (-Not $flag){
        $Row = "" | Select Domain,Status,NSRecord,PrimaryServer, ARecord,ServerVersion,StatusCode
        $Row.Domain = $name
        $Row.Status = "Available"
        $Row.NSRecord = $Minformation.NameAdministrator
        $Row.ARecord = $ARecord.IPAddress
        $Row.PrimaryServer = $Minformation.PrimaryServer
        $req = urlRequest("https://$name")
        if ($req){
        $Row.StatusCode = $req[0]
        $Row.ServerVersion = $req[1]
        }
        $Array += $Row
    }
    else{
        $Row = "" | Select Domain,Status,NSRecord,PrimaryServer, ARecord,ServerVersion,StatusCode
        $Row.Domain = $name
        $Row.Status = "Not responding"
         $Array += $Row
    }

    


    
}
#$hash.GetEnumerator() | Sort Value | Export-CSV -Path C:\Scripts\Powershell\output.csv



$Array | Export-CSV -Path $csv
Write-Host "[0] - Done!"
