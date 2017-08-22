#Variables
$region='northeurope'
$publisher='MicrosoftWindowsServer'
$offer='WindowsServer'
$sku='2016-Datacenter'
$vmSizeHDD='Standard_D4_v2'
$vmSizeSSD='Standard_DS4_v2'
$cred=Get-Credential

#Login and subscription selection
$null=Login-AzureRmAccount
$subscription=Get-AzureRmSubscription|Out-GridView -PassThru
$null=Select-AzureRmSubscription -SubscriptionId $subscription.Id -Verbose

#Deploying IaaS perf test VM on Standard Managed Disk with SSE
try
{  
    $temp=New-Guid
    $temp=$temp.Guid -split '-'
    $resourceGroup='iaasperftesthddsse'+$temp[0]
    $vnetName='vnet'+$temp[0]
    $pipName='pip'+$temp[0]
    $nicName='nic'+$temp[0]
    $nsgName='nsg'+$temp[0]
    $vmName='vm'+$temp[0]
    $osDisk='osDisk'+$temp[0]

    #RG deployment
    New-AzureRmResourceGroup -Name $resourceGroup -Location $region -Verbose

    #Virtual Network, PIP, NIC and NSG deployment
    New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName -AddressPrefix 192.168.0.0/24 -Location $region -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName
    Add-AzureRmVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet -AddressPrefix 192.168.0.0/24 -Verbose
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName
    $pip=New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $region -AllocationMethod Static -Name $pipName -Verbose
    $nic=New-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Location $region -Name $nicName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -Verbose
    $nsgRule=New-AzureRmNetworkSecurityRuleConfig -Name RDP -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow -Verbose
    $nsg=New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $region -Name $nsgName -SecurityRules $nsgRule -Verbose
    Set-AzureRmVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet -NetworkSecurityGroup $nsg -AddressPrefix 192.168.0.0/24 -Verbose
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName

    #VM deployment
    $vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSizeHDD -Verbose
    $vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate -Verbose
    $vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $publisher -Offer $offer -Skus $sku -Version latest -Verbose
    $vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id -Verbose
    New-AzureRmVM -ResourceGroupName $resourceGroup -Location $region -VM $vm -DisableBginfoExtension -Verbose

    #Data disk deployment
    $config=New-AzureRmDiskConfig -AccountType StandardLRS -Location $region -DiskSizeGB 4095 -CreateOption Empty -Verbose
    $dataDisk8=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "4TB-HDD" -Disk $config -Verbose
    $vm=Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk8.Name -CreateOption Attach -ManagedDiskId $dataDisk8.Id -Lun 1 -Verbose
    Update-AzureRmVM -ResourceGroupName $resourceGroup -VM $vm -Verbose

    #Data disk and performance test preparation via Custom Script Extension
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $resourceGroup -VMName $vmName -Location $region -FileUri 'https://raw.githubusercontent.com/neumanndaniel/iaasperftests/master/Initialize_Disk_ADETest.ps1' -Run 'Initialize_Disk_ADETest.ps1' -Name CustomScriptExtension -Verbose
}
catch
{
    $_
}

#Deploying IaaS perf test VM on Premium Managed Disk with SSE
try
{
    $temp=New-Guid
    $temp=$temp.Guid -split '-'
    $resourceGroup='iaasperftestssdsse'+$temp[0]
    $vnetName='vnet'+$temp[0]
    $pipName='pip'+$temp[0]
    $nicName='nic'+$temp[0]
    $nsgName='nsg'+$temp[0]
    $vmName='vm'+$temp[0]
    $osDisk='osDisk'+$temp[0]

    #RG deployment
    New-AzureRmResourceGroup -Name $resourceGroup -Location $region -Verbose

    #Virtual Network, PIP, NIC and NSG deployment
    New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName -AddressPrefix 192.168.0.0/24 -Location $region -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName
    Add-AzureRmVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet -AddressPrefix 192.168.0.0/24 -Verbose
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName
    $pip=New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $region -AllocationMethod Static -Name $pipName -Verbose
    $nic=New-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Location $region -Name $nicName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -Verbose
    $nsgRule=New-AzureRmNetworkSecurityRuleConfig -Name RDP -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow -Verbose
    $nsg=New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $region -Name $nsgName -SecurityRules $nsgRule -Verbose
    Set-AzureRmVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet -NetworkSecurityGroup $nsg -AddressPrefix 192.168.0.0/24 -Verbose
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName

    #VM deployment
    $vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSizeSSD -Verbose
    $vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate -Verbose
    $vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $publisher -Offer $offer -Skus $sku -Version latest -Verbose
    $vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id -Verbose
    New-AzureRmVM -ResourceGroupName $resourceGroup -Location $region -VM $vm -DisableBginfoExtension -Verbose

    #Data disk deployment
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 32 -CreateOption Empty -Verbose
    $dataDisk1=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "32GB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 64 -CreateOption Empty -Verbose
    $dataDisk2=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "64GB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 128 -CreateOption Empty -Verbose
    $dataDisk3=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "128GB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 512 -CreateOption Empty -Verbose
    $dataDisk4=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "512GB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 1024 -CreateOption Empty -Verbose
    $dataDisk5=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "1TB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 2048 -CreateOption Empty -Verbose
    $dataDisk6=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "2TB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 4095 -CreateOption Empty -Verbose
    $dataDisk7=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "4TB-SSD" -Disk $config -Verbose
    $vm=Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk1.Name -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk2.Name -CreateOption Attach -ManagedDiskId $dataDisk2.Id -Lun 2 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk3.Name -CreateOption Attach -ManagedDiskId $dataDisk3.Id -Lun 3 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk4.Name -CreateOption Attach -ManagedDiskId $dataDisk4.Id -Lun 4 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk5.Name -CreateOption Attach -ManagedDiskId $dataDisk5.Id -Lun 5 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk6.Name -CreateOption Attach -ManagedDiskId $dataDisk6.Id -Lun 6 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk7.Name -CreateOption Attach -ManagedDiskId $dataDisk7.Id -Lun 7 -Verbose
    Update-AzureRmVM -ResourceGroupName $resourceGroup -VM $vm -Verbose

    #Data disk and performance test preparation via Custom Script Extension
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $resourceGroup -VMName $vmName -Location $region -FileUri 'https://raw.githubusercontent.com/neumanndaniel/iaasperftests/master/Initialize_Disk_ADETest.ps1' -Run 'Initialize_Disk_ADETest.ps1' -Name CustomScriptExtension -Verbose
}
catch
{
    $_
}

#Deploying IaaS perf test VM on Standard Managed Disk with ADE
try
{    
    $temp=New-Guid
    $temp=$temp.Guid -split '-'
    $resourceGroup='iaasperftesthddade'+$temp[0]
    $vaultName='adekeyvault'+$temp[0]
    $vnetName='vnet'+$temp[0]
    $pipName='pip'+$temp[0]
    $nicName='nic'+$temp[0]
    $nsgName='nsg'+$temp[0]
    $vmName='vm'+$temp[0]
    $osDisk='osDisk'+$temp[0]

    #RG deployment
    New-AzureRmResourceGroup -Name $resourceGroup -Location $region -Verbose

    #Key Vault Deployment and Preparation
    New-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $resourceGroup -Location $region -EnabledForDeployment -EnabledForTemplateDeployment -EnabledForDiskEncryption -Sku premium -Verbose -ErrorAction Stop
    $null=Add-AzureKeyVaultKey -VaultName $vaultName -Name 'ADE-KEK' -Destination HSM -Verbose
    $aadClientSecret=New-Guid -Verbose
    $vaultURI='https://'+$vaultName
    $aadApplication= New-AzureRmADApplication -DisplayName $vaultName -HomePage $vaultURI -IdentifierUris $vaultURI -Password $aadClientSecret.Guid -Verbose
    $aadClientSecretSecure=ConvertTo-SecureString $aadClientSecret.Guid -AsPlainText -Force -Verbose
    $null=Set-AzureKeyVaultSecret -VaultName $vaultName -Name 'aadADEClientSecret' -SecretValue $aadClientSecretSecure -Verbose 
    $aadApplicationSecure=ConvertTo-SecureString $aadApplication.ApplicationId -AsPlainText -Force -Verbose
    $null=Set-AzureKeyVaultSecret -VaultName $vaultName -Name 'aadADEClientID' -SecretValue $aadApplicationSecure -Verbose 
    $servicePrincipal=New-AzureRmADServicePrincipal -ApplicationId $aadApplication.ApplicationId -Verbose 
    Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[1] -PermissionsToKeys all -PermissionsToSecrets all -Verbose

    #Virtual Network, PIP, NIC and NSG deployment
    New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName -AddressPrefix 192.168.0.0/24 -Location $region -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName
    Add-AzureRmVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet -AddressPrefix 192.168.0.0/24 -Verbose
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName
    $pip=New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $region -AllocationMethod Static -Name $pipName -Verbose
    $nic=New-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Location $region -Name $nicName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -Verbose
    $nsgRule=New-AzureRmNetworkSecurityRuleConfig -Name RDP -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow -Verbose
    $nsg=New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $region -Name $nsgName -SecurityRules $nsgRule -Verbose
    Set-AzureRmVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet -NetworkSecurityGroup $nsg -AddressPrefix 192.168.0.0/24 -Verbose
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName

    #VM deployment
    $vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSizeHDD -Verbose
    $vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate -Verbose
    $vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $publisher -Offer $offer -Skus $sku -Version latest -Verbose
    $vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id -Verbose
    New-AzureRmVM -ResourceGroupName $resourceGroup -Location $region -VM $vm -DisableBginfoExtension -Verbose

    #Data disk deployment
    $config=New-AzureRmDiskConfig -AccountType StandardLRS -Location $region -DiskSizeGB 4095 -CreateOption Empty -Verbose
    $dataDisk8=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "4TB-HDD" -Disk $config -Verbose
    $vm=Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk8.Name -CreateOption Attach -ManagedDiskId $dataDisk8.Id -Lun 1 -Verbose
    Update-AzureRmVM -ResourceGroupName $resourceGroup -VM $vm -Verbose

    #Data disk and performance test preparation via Custom Script Extension
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $resourceGroup -VMName $vmName -Location $region -FileUri 'https://raw.githubusercontent.com/neumanndaniel/iaasperftests/master/Initialize_Disk_ADETest.ps1' -Run 'Initialize_Disk_ADETest.ps1' -Name CustomScriptExtension -Verbose    

    #Enabling Azure Disk Encryption
    $aadClientSecret=(Get-AzureKeyVaultSecret -VaultName $VaultName -Name "aadADEClientSecret").SecretValueText
    $azureAdApplication=(Get-AzureKeyVaultSecret -VaultName $VaultName -Name "aadADEClientID").SecretValueText
    $KeyVault=Get-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $resourceGroup
    $diskEncryptionKeyVaultUrl=$KeyVault.VaultUri
    $KeyVaultResourceId=$KeyVault.ResourceId
    $keyEncryptionKeyUrl=(Get-AzureKeyVaultKey -VaultName $vaultName -Name "ADE-KEK").Key.Kid
    $SequenceVersion="1"

    Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $resourceGroup -VMName $vmName -AadClientID $azureAdApplication -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $KeyVaultResourceId -VolumeType All -KeyEncryptionAlgorithm RSA-OAEP -SequenceVersion $SequenceVersion -Verbose -Force
}
catch
{
    $_
}

#Deploying IaaS perf test VM on Premium Managed Disk with ADE
try
{
    $temp=New-Guid
    $temp=$temp.Guid -split '-'
    $resourceGroup='iaasperftestssdade'+$temp[0]
    $vaultName='adekeyvault'+$temp[0]
    $vnetName='vnet'+$temp[0]
    $pipName='pip'+$temp[0]
    $nicName='nic'+$temp[0]
    $nsgName='nsg'+$temp[0]
    $vmName='vm'+$temp[0]
    $osDisk='osDisk'+$temp[0]

    #RG deployment
    New-AzureRmResourceGroup -Name $resourceGroup -Location $region -Verbose

    #Key Vault Deployment and Preparation
    New-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $resourceGroup -Location $region -EnabledForDeployment -EnabledForTemplateDeployment -EnabledForDiskEncryption -Sku premium -Verbose -ErrorAction Stop
    $null=Add-AzureKeyVaultKey -VaultName $vaultName -Name 'ADE-KEK' -Destination HSM -Verbose
    $aadClientSecret=New-Guid -Verbose
    $vaultURI='https://'+$vaultName
    $aadApplication= New-AzureRmADApplication -DisplayName $vaultName -HomePage $vaultURI -IdentifierUris $vaultURI -Password $aadClientSecret.Guid -Verbose
    $aadClientSecretSecure=ConvertTo-SecureString $aadClientSecret.Guid -AsPlainText -Force -Verbose
    $null=Set-AzureKeyVaultSecret -VaultName $vaultName -Name 'aadADEClientSecret' -SecretValue $aadClientSecretSecure -Verbose 
    $aadApplicationSecure=ConvertTo-SecureString $aadApplication.ApplicationId -AsPlainText -Force -Verbose
    $null=Set-AzureKeyVaultSecret -VaultName $vaultName -Name 'aadADEClientID' -SecretValue $aadApplicationSecure -Verbose 
    $servicePrincipal=New-AzureRmADServicePrincipal -ApplicationId $aadApplication.ApplicationId -Verbose 
    Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[1] -PermissionsToKeys all -PermissionsToSecrets all -Verbose    

    #Virtual Network, PIP, NIC and NSG deployment
    New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName -AddressPrefix 192.168.0.0/24 -Location $region -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName
    Add-AzureRmVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet -AddressPrefix 192.168.0.0/24 -Verbose
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName
    $pip=New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $region -AllocationMethod Static -Name $pipName -Verbose
    $nic=New-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Location $region -Name $nicName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -Verbose
    $nsgRule=New-AzureRmNetworkSecurityRuleConfig -Name RDP -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow -Verbose
    $nsg=New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $region -Name $nsgName -SecurityRules $nsgRule -Verbose
    Set-AzureRmVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet -NetworkSecurityGroup $nsg -AddressPrefix 192.168.0.0/24 -Verbose
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -Verbose
    $vnet=Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName

    #VM deployment
    $vm=New-AzureRmVMConfig -VMName $vmName -VMSize $vmSizeSSD -Verbose
    $vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate -Verbose
    $vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $publisher -Offer $offer -Skus $sku -Version latest -Verbose
    $vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id -Verbose
    New-AzureRmVM -ResourceGroupName $resourceGroup -Location $region -VM $vm -DisableBginfoExtension -Verbose

    #Data disk deployment
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 32 -CreateOption Empty -Verbose
    $dataDisk1=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "32GB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 64 -CreateOption Empty -Verbose
    $dataDisk2=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "64GB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 128 -CreateOption Empty -Verbose
    $dataDisk3=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "128GB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 512 -CreateOption Empty -Verbose
    $dataDisk4=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "512GB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 1024 -CreateOption Empty -Verbose
    $dataDisk5=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "1TB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 2048 -CreateOption Empty -Verbose
    $dataDisk6=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "2TB-SSD" -Disk $config -Verbose
    $config=New-AzureRmDiskConfig -AccountType PremiumLRS -Location $region -DiskSizeGB 4095 -CreateOption Empty -Verbose
    $dataDisk7=New-AzureRmDisk -ResourceGroupName $resourcegroup -DiskName "4TB-SSD" -Disk $config -Verbose
    $vm=Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk1.Name -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk2.Name -CreateOption Attach -ManagedDiskId $dataDisk2.Id -Lun 2 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk3.Name -CreateOption Attach -ManagedDiskId $dataDisk3.Id -Lun 3 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk4.Name -CreateOption Attach -ManagedDiskId $dataDisk4.Id -Lun 4 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk5.Name -CreateOption Attach -ManagedDiskId $dataDisk5.Id -Lun 5 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk6.Name -CreateOption Attach -ManagedDiskId $dataDisk6.Id -Lun 6 -Verbose
    $vm=Add-AzureRmVMDataDisk -VM $vm -Name $dataDisk7.Name -CreateOption Attach -ManagedDiskId $dataDisk7.Id -Lun 7 -Verbose
    Update-AzureRmVM -ResourceGroupName $resourceGroup -VM $vm -Verbose

    #Data disk and performance test preparation via Custom Script Extension
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $resourceGroup -VMName $vmName -Location $region -FileUri 'https://raw.githubusercontent.com/neumanndaniel/iaasperftests/master/Initialize_Disk_ADETest.ps1' -Run 'Initialize_Disk_ADETest.ps1' -Name CustomScriptExtension -Verbose 
    
    #Enabling Azure Disk Encryption
    $aadClientSecret=(Get-AzureKeyVaultSecret -VaultName $VaultName -Name "aadADEClientSecret").SecretValueText
    $azureAdApplication=(Get-AzureKeyVaultSecret -VaultName $VaultName -Name "aadADEClientID").SecretValueText
    $KeyVault=Get-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $resourceGroup
    $diskEncryptionKeyVaultUrl=$KeyVault.VaultUri
    $KeyVaultResourceId=$KeyVault.ResourceId
    $keyEncryptionKeyUrl=(Get-AzureKeyVaultKey -VaultName $vaultName -Name "ADE-KEK").Key.Kid
    $SequenceVersion="1"
    Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $resourceGroup -VMName $vmName -AadClientID $azureAdApplication -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId -KeyEncryptionKeyUrl $keyEncryptionKeyUrl -KeyEncryptionKeyVaultId $KeyVaultResourceId -VolumeType All -KeyEncryptionAlgorithm RSA-OAEP -SequenceVersion $SequenceVersion -Verbose -Force
}
catch
{
    $_
}