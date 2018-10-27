<# 
Author: Barbara Forbes
Version: 1.0 
 
    https://4bes.nl/2018/10/27/step-by-step-create-a-devtest-labs-custom-image-based-on-an-azure-vm/
#>

$AzurermSubscription = "[id for your surbscription]"
$VHDSourceResourceGroupName = "[resourcegroupname for the vm]"
$LabResourceGroupName = "[resourcegroupname for the lab]"
$VHDName = "[name for the vhd in the lab]"


#set subscription
Select-AzurermSubscription -SubscriptionId $AzurermSubscription

#get the name of the SourceDisk
$SourceDisk = Get-AzureRmDisk -ResourceGroupName $VHDSourceResourceGroupName| Select-Object ResourceGroupName, Name, DiskSizeGB | Select-Object -First 1
#get access to the disk from this prompt. It will last 5 minutes
$SourceAccess = Grant-AzureRmDiskAccess -ResourceGroupName $VHDSourceResourceGroupName -DiskName $SourceDisk.Name -DurationInSecond 3600 -Access Read

#get the lab storageaccount name to copy to
$LabStorageAcountName = Get-AzureRmResource  | Where-Object {($_.ResourceGroupName -eq "$LabResourceGroupName") -and ($_.resourcetype -like "*storageAccounts")} | Select-Object -ExpandProperty Name
#get the labstorageaccount-key to get access
$LabStorageAccountKey = Get-AzureRmStorageAccountKey -Name $LabStorageAcountName -ResourceGroupName $LabResourceGroupName | Select-Object -First 1
#set up context to run the copyjob
$LabContext = New-AzureStorageContext –StorageAccountName $LabStorageAcountName -StorageAccountKey $LabStorageAccountKey.Value

#perform the actual copyjob
$CopyVHDtoLab =Start-AzureStorageBlobCopy -AbsoluteUri $SourceAccess.AccessSAS -DestContainer "uploads" -DestContext $LabContext -DestBlob $VHDName

#monitor the copyjob
while (($CopyVHDtoLab | Get-AzureStorageBlobCopyState).Status -eq "Pending"){
    Write-Host "Copyjob is still pending"
    Start-Sleep 30
}
Write-Host "copyjob is done"