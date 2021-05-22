<#
Script that queries a domain controller for machines 
and generates an ansible hosts file based on if port 22 for ssh is open
#>
param (
    [parameter(Mandatory=$true)][string]$domain, #specify the domain to search in
    [parameter(Mandatory=$false)][string]$outfile=".\hosts" #defaults output to a file called hosts in pwd if not otherwise specified
)
Import-Module ActiveDirectory #used to interact with computer objects

#get computers in domain
$computers = Get-ADComputer -Filter * -Properties * # | Select -Property Name,DNSHostName,Enabled,LastLogonDate
$ansibleGroups = [ordered]@{} #stores the computer groups and OUs for creating ansible groups

#checks if port 22 is open for ssh
function sshCheck{
param (
        [parameter()][string]$pc
    )
    if(((New-Object System.Net.Sockets.TCPClient).BeginConnect( $pc, 22, $Null, $Null )).AsyncWaitHandle.WaitOne(300)){ #check for port 22 for ssh and assume linux if its open
        return $true
    }else{
       return $false
    }

}

#adds a computer to the ansiblegroups ditctionary
function addComputer{
    param (
        [parameter()][string]$pc,
        [parameter()][string]$grp
    )
    

    $grp = (Get-ADGroup $grp).name.Replace(" ", "_")
    #if group doesn't exist in $ansiblegroups, add it with the pc name as the first index of the value array, an argument exception is thrown when the key already exists
    try{
        $dictVal = New-Object -TypeName 'System.Collections.ArrayList'
        $dictVal.Add($pc)
        $ansibleGroups.Add($grp, $dictVal )
    }catch { #if group does exist concatenate the pc name onto its value array
        $ansibleGroups[$grp].Add($pc)
    }

}

#iterate through pcs
foreach ($pc in $computers){
    #get the dns name
    $name = ($pc | Select-Object -ExpandProperty DNSHostName) 
    if (-not $name.EndsWith($domain)){ #fix name if dnsname doesn't end with the domain, take the first index of the split on periods
        $name=$name.Split(".")[0]
        $name="$name.$domain"
    }
    if ((sshCheck -pc $name)){ #check if the machine is linux before adding it to ansible list
        #get the groups the pc is in
        $groups = $pc.MemberOf
        #loop through to get each common name
        foreach ($group in $groups){       
            addComputer -pc $name -grp $group
        }
    }
}

if((Test-Path -Path $outfile -PathType Leaf)){ #check if the output file exists, if it does clear it out
    Clear-Content $outfile
}else{ #if it doesn't create it 
    New-Item -ItemType File -Path $outfile -Force
}


#write to output file
foreach ($g in $ansibleGroups.GetEnumerator()){
    "[$($g.Name)]" | Out-File -FilePath $outfile -Append
    foreach ($pc in $($g.Value)){
        $pc  | Out-File -FilePath $outfile -Append
    }
    " " | Out-File -FilePath $outfile -Append
}
