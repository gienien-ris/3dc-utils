Get-VM -name "*stefan*" | ForEach-Object {

    $vm = $_

    Get-NetworkAdapter -VM $vm | ForEach-Object {
        $nic = $_
        $pgName = $nic.NetworkName
        $pg = Get-VDPortGroup -Name $pgName
        if ($pg.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId -is [int]) {
            $vlan = ($pg.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId)
        }
        else {
            $vlan = $pg.VlanConfiguration.Ranges
        }
        
        #Write-Host $vm $nic $pgName $vlan $switch
        [PSCustomObject]@{
            VMName         = $vm.Name
            NetworkAdapter = $nic.Name
            Portgroup      = $pgName
            VlanId         = $vlan
        }


    }
} | export-csv -Path C:\git\powershell\stefan_dc3_utils\vm_nic_vlans.csv -NoTypeInformation -Encoding unicode