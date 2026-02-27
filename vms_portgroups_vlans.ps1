Get-VM -name "*MIG*" | ForEach-Object {

    $vm = $_

    Get-NetworkAdapter -VM $vm | ForEach-Object {
        $nic = $_
        $pgName = $nic.NetworkName
        $pg = Get-VDPortGroup -Name $pgName 
        if ($pg) {
          
        if ($pg.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId -is [int]) {
            $vlan = ($pg.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId)
        }
        else {
            $vlan = $pg.VlanConfiguration.Ranges
        }
    } else { 
        $pg = Get-VirtualPortGroup -Name $pgName
        $vlan = $pg.VlanId
    }
        #Write-Host $vm $nic $pgName $vlan $switch
        [PSCustomObject]@{
            VMName         = $vm.Name
            NetworkAdapter = $nic.Name
            Portgroup      = $pgName
            VlanId         = $vlan
        }
    }
} | export-csv -Path C:\sb\vm_nic_vlans.csv -NoTypeInformation -Encoding unicode

