
#Defined input parameters.
  Param(
	[parameter(Mandatory=$true)]
	$impofile,
	[parameter(Mandatory=$true)]
	$nicfile
  )
 
. .\functions\get-folderbypath.ps1


#$impofile="C:\git\powershell\stefan_dc3_utils\vm_inventory.csv"
#$nicfile="C:\git\powershell\stefan_dc3_utils\vm_nic_vlans.csv"   
$impodat = Import-Csv $impofile 
$nicdat = Import-Csv $nicfile

#$myline = ($impodat | Where-Object {$_.Name -eq "imp_exp_test_stefan"})
foreach($myline in $impodat) {

			write-host "Found line in input file:"
			$myline | Format-List
			$dest_cluster=$myline.Path.split("/")[2]
			$dest_folder=get-folderbypath ($myline.BluePath.Replace($myline.Name,""))
			write-host "Registering VMX with name: $($myline.Name) on the platform."
			New-VM -VMFilePath $myline.VMX -ResourcePool $dest_cluster -Location $dest_folder #-RunAsync

			write-host "Wait for VM to be registred"
			$newvm = Get-VM -Name $myline.Name
			while ($null -eq $newvm) {
				Start-Sleep -Seconds 5
				$newvm = Get-VM -Name $myline.Name
			}
			Write-Host "VM $($myline.Name) is now registered. "
			if ( $newvm.ExtensionData.Config.Uuid -eq $myline.UUID) {
				Write-Host "VM $($myline.Name) has the expected UUID: $($myline.UUID). Proceeding with configuration."
			} else {
				Write-Warning "VM $($myline.Name) does not have the expected UUID. Expected: $($myline.UUID), Actual: $($newvm.ExtensionData.Config.Uuid)"
			}

			write-host "Configuring NICs."
			Get-NetworkAdapter -VM $newvm | ForEach-Object {
				$nic = $_
				write-host "VM: $($myline.Name) NIC: $($nic.Name)"
				$nicinfo = ($nicdat | Where-Object {$_.VMName -eq $myline.Name -and $_.NetworkAdapter -eq $nic.Name})
				if ($nicinfo) {
					write-host "Found NIC info in input file:"
					$nicinfo | Format-List
					$pgName = $nicinfo.Portgroup
					$vlanId = $nicinfo.VlanId
					if ($vlanId.contains(",") -or $vlanId.contains("-")) {
						write-host "Vlan ID is a range or list: $vlanId"
						$newdvportg = Get-VDPortgroup | Where-Object {$_.VlanConfiguration.Ranges -like $vlanId -and $_.Name -notlike "*DVUplinks*"}
					} else {
						write-host "Looking for portgroup with VLAN ID: $vlanId"
						$newdvportg = Get-VDPortgroup | Where-Object {$_.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId -eq $vlanId }
					}

					write-host "setting network adapter $($nic.Name) to portgroup $($newdvportg.Name) from $pgName"
					Set-NetworkAdapter -NetworkAdapter $nic -Portgroup $newdvportg -Confirm:$false
				} else {
					write-host "No matching NIC info found in input file for VM: $($myline.Name) NIC: $($nic.Name). Skipping NIC configuration."
				}
			}
	}