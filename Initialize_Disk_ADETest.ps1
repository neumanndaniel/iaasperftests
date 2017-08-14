$Disks=Get-Disk|Where-Object{$_.PartitionStyle -eq 'RAW'}
foreach($Disk in $Disks){
    Initialize-Disk -UniqueId $Disk.UniqueId -PartitionStyle GPT
    $Partition=New-Partition -DiskId $Disk.UniqueId -UseMaximumSize -AssignDriveLetter
    $Volume=Get-Volume -DriveLetter $Partition.DriveLetter
    if($Disk.Size/1GB -eq 32){
        Format-Volume -ObjectId $Volume.ObjectId -FileSystem NTFS -AllocationUnitSize 64KB -NewFileSystemLabel "4" -Force -Confirm:$false
    }
    if($Disk.Size/1GB -eq 64){
        Format-Volume -ObjectId $Volume.ObjectId -FileSystem NTFS -AllocationUnitSize 64KB -NewFileSystemLabel "6" -Force -Confirm:$false
    }
    if($Disk.Size/1GB -eq 128){
        Format-Volume -ObjectId $Volume.ObjectId -FileSystem NTFS -AllocationUnitSize 64KB -NewFileSystemLabel "10" -Force -Confirm:$false
    }
    if($Disk.Size/1GB -eq 256){
        Format-Volume -ObjectId $Volume.ObjectId -FileSystem NTFS -AllocationUnitSize 64KB -NewFileSystemLabel "15" -Force -Confirm:$false
    }
    if($Disk.Size/1GB -eq 512){
        Format-Volume -ObjectId $Volume.ObjectId -FileSystem NTFS -AllocationUnitSize 64KB -NewFileSystemLabel "20" -Force -Confirm:$false
    }
    if($Disk.Size/1GB -eq 1024){
        Format-Volume -ObjectId $Volume.ObjectId -FileSystem NTFS -AllocationUnitSize 64KB -NewFileSystemLabel "30" -Force -Confirm:$false
    }
    if($Disk.Size/1GB -eq 2048){
        Format-Volume -ObjectId $Volume.ObjectId -FileSystem NTFS -AllocationUnitSize 64KB -NewFileSystemLabel "40" -Force -Confirm:$false
    }
    if($Disk.Size/1GB -eq 4095){
        Format-Volume -ObjectId $Volume.ObjectId -FileSystem NTFS -AllocationUnitSize 64KB -NewFileSystemLabel "50" -Force -Confirm:$false
    }
}
New-Item -Path C:\ -Name 'IaaS' -ItemType Directory -Verbose
Invoke-WebRequest -Uri "https://download.microsoft.com/download/1/0/F/10F6E64A-680F-4B9D-9B74-F6511155B6A9/PerfInsights.zip" -OutFile C:\IaaS\PerfInsights.zip -Verbose
Expand-Archive -Path C:\IaaS\PerfInsights.zip -DestinationPath C:\IaaS -Force -Verbose
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/neumanndaniel/iaasperftests/master/Start.ps1" -OutFile C:\IaaS\Start.ps1 -Verbose
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/neumanndaniel/iaasperftests/master/PerfInsights_Settings.xml" -OutFile C:\IaaS\PerfInsights_Settings.xml -Verbose