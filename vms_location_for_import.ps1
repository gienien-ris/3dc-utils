
. .\inventory_plus.ps1

Get-InventoryPlus | Where-Object{$_.Type -eq 'VirtualMachine' } |

ForEach-Object -Process {

    $vm = Get-VM $_.Name
    
    $_ | Add-Member -Name VMX -Value $vm.ExtensionData.Summary.Config.VmPathName -MemberType NoteProperty
    $_ | Add-Member -Name UUID -Value $vm.ExtensionData.Config.Uuid -MemberType NoteProperty
    $_ | Add-Member -Name HARestartPriority -Value $vm.HARestartPriority -MemberType NoteProperty
    $_ | Add-Member -Name vCenter -Value (([uri]$vm.ExtensionData.Client.ServiceUrl).Host) -MemberType NoteProperty
    $_ | Add-Member -Name PowerSTate -Value $vm.PowerState -MemberType NoteProperty
    $_ | Add-Member -Name VMHost -Value $vm.VMHost.Name -MemberType NoteProperty
    $_ | Add-Member -Name Uptime -Value $vm.ExtensionData.Summary.QuickStats.UptimeSeconds -MemberType NoteProperty
    $_ | Add-Member -Name IPAddress -Value ($vm.Guest.IPAddress -join '|') -MemberType NoteProperty
    $_ | Add-Member -Name Datastore -Value ((Get-View -Id $vm.DatastoreIdList -Property Name).Name -join '|') -MemberType NoteProperty
    $_

} | #export-csv -Path C:\git\powershell\stefan_dc3_utils\vm_inventory.csv -NoTypeInformation -Encoding unicode

Where-Object{$_.Name -eq 'imp_exp_test_stefan' }| export-csv -Path C:\git\powershell\stefan_dc3_utils\vm_inventory.csv -NoTypeInformation -Encoding unicode