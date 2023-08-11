function SystemReport {
    [CmdletBinding()]
    param (
        [Switch]$system,
        [Switch]$disks,
        [Switch]$network
    )

    if ($system) {
        #System Reporting Section
        Write-Host "Generating System report..." #Let the User know why they may be waiting.

        $operatingsystem = Get-WmiObject win32_operatingsystem
        $version = $operatingsystem.Version
        $OSText = "The Windows Operating System version is: " + $version
        Write-Host $OSText
        #This has now output the windows OS version

        $processor = Get-WmiObject win32_processor
        $cpuspecsone = $processor.Name + 'With ' + $processor.NumberOfCores + ' Cores' + ' @ ' + $processor.MaxClockSpeed +'Mhz'
        $CPUText = "The CPU in this system is a: " + $cpuspecsone
        Write-Host $CPUText


        $processorCache = Get-WmiObject win32_cachememory
        $reportOne = @()
        foreach ($cache in $processorCache) {
            $cacheLevel = switch ($cache.DeviceID) {
                'Cache Memory 0' { 'Level 1' }
                'Cache Memory 1' { 'Level 2' }
                'Cache Memory 2' { 'Level 3' }
        Default { $cache.DeviceID }
    }
            $reportEntryOne = [PSCustomObject]@{
                'Size(kb)' = $cache.MaxCacheSize -replace "Physical Memory (\d+)", '$1'
                'Level' = $cacheLevel
                
            }
            $reportOne += $reportEntryOne
        }
        $reportOne | Format-Table -AutoSize
    }

        get-wmiobject -class win32_physicalmemory | foreach {
            new-object -TypeName psobject -Property @{
            Manufacturer = $_.manufacturer
            "Speed(MHz)" = $_.speed
            "Size(MB)" = $_.capacity/1mb
            Bank = $_.banklabel
            Slot = $_.devicelocator
            }
            $totalcapacity += $_.capacity/1mb
            } |  ft -auto Manufacturer, "Size(MB)", "Speed(MHz)", Bank, Slot
        #Way better formatting
        
        
        <#$memorySticks = Get-WmiObject win32_physicalmemory

       $reportTwo = @()

       foreach ($DIMM in $memorySticks) {
            $reportEntryTwo = [PSCustomObject]@{
                DIMMslot = $DIMM.Tag -replace "Physical Memory (\d+)", '$1'
                'Capacity(mb)' = $DIMM.Capacity / 1mb -as [int]
                Speed = $DIMM.Speed
                Part = $DIMM.PartNumber
                
            }
            $reportTwo += $reportEntryTwo
        }

        $reportTwo | Format-Table -AutoSize        #>

        $videoDevice = Get-WmiObject win32_videocontroller | Select-Object -First 1
        $videoSpecs = $videoDevice.Description
        $videoDevice = Get-WmiObject win32_videocontroller
        $videoResSpecs = $videoDevice.CurrentHorizontalResolution + "X" + $videoDevice.CurrentVerticalResolution + " @ " + $videoDevice.CurrentRefreshRate +"Hz"
        $videoText = "The Active Video Device in this system is a " + $videospecs
        $videoResText = "The Monitor Resolution and Refresh Rate is " + $videoResSpecs
        Write-Host $videoText
        Write-Host $videoResText
  
  
    }

    if ($disks) {
        #Video Devices Reporting SEction
        Write-Host "Generating Disks report..." #Let the User know why they may be waiting.
        $diskdrives = Get-CIMInstance CIM_diskdrive

        foreach ($disk in $diskdrives) {
            $partitions = $disk|get-cimassociatedinstance -resultclassname CIM_diskpartition
            foreach ($partition in $partitions) {
                    $logicaldisks = $partition | get-cimassociatedinstance -resultclassname CIM_logicaldisk
                    foreach ($logicaldisk in $logicaldisks) {
                             new-object -typename psobject -property @{Manufacturer=$disk.Manufacturer
                                                               Location=$partition.deviceid
                                                               Drive=$logicaldisk.deviceid
                                                               "Size(GB)"=$logicaldisk.size / 1gb -as [int]
                                                               }
           }
      }
  }
    }

    if ($network) {
        # This is the Network Report Section
        Write-Host "Generating Network report..." #Let the User know why they may be waiting.
        $adapters = Get-CimInstance CIM_NetworkAdapter
        $filteredadapters = $adapters | Where-Object { $_.AdapterType -match "ethernet" -and $_.NetEnabled -eq $true }
        $myNetworkObjects = $filteredadapters | ForEach-Object {
            $adapter = $_
            $nac = $adapter | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration
            $ipv4Addresses = $nac.IPAddress | Where-Object { $_ -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' }
            #IPv6 over my dead body, just cleaning it up for Aesthetics.

            New-Object PSObject -Property @{
                Name = $adapter.Name
                IPAddress = $ipv4Addresses -join ', '
                Gateway = $nac.DefaultIPGateway
                ConnectionName = $adapter.NetConnectionID
                "Speed(Mbps)" = $adapter.Speed / 1000000
    }
}

$myNetworkObjects | Format-Table Name, ConnectionName, IPAddress, Gateway, "Speed(Mbps)"
    }
}

Export-ModuleMember -Function 'SystemReport'