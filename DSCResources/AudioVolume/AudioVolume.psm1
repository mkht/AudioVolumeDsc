﻿$LibsPath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Libs'

Add-Type -Path (Join-Path $LibsPath '\CoreAudio\netstandard2.0\CoreAudio.dll')

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DeviceName,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [uint16] $Volume
    )

    $MMDevice = Get-MMDevice -DeviceName $DeviceName

    if ($MMDevice.Count -eq 0) {
        Write-Verbose ('Device not found.')
        return $null
    }
    elseif ($MMDevice.Count -gt 1) {
        Write-Warning ('Multiple audio devices found.')
    }

    foreach ($device in $MMDevice) {
        $result = @{}
        $result.DeviceName = $device.DeviceFriendlyName
        $result.DeviceId = $device.ID
        $result.State = $device.State.ToString()
        $result.IsDefaultDevice = $device.Selected
        $result.Volume = [uint16]($device.AudioEndpointVolume.MasterVolumeLevelScalar * 100)
        $result.Mute = $device.AudioEndpointVolume.Mute
        $result
        $device.Dispose()
    }
}

function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DeviceName,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [uint16] $Volume,

        [Parameter()]
        [bool] $Mute = $false,

        [Parameter()]
        [bool] $SkipWhenDeviceNotPresent = $false,

        [Parameter()]
        [string] $State,

        [Parameter()]
        [bool] $IsDefaultDevice,

        [Parameter()]
        [string] $DeviceId
    )

    $CurrentState = Get-TargetResource -DeviceName $DeviceName -Volume $Volume

    if ($null -eq $CurrentState) {
        if ($SkipWhenDeviceNotPresent) {
            Write-Warning 'Device not found but TEST RETURNS TRUE because SkipWhenDeviceNotPresent is specified as true.'
            return $true
        }
        else {
            return $false
        }
    }

    $ret = $true
    foreach ($item in $CurrentState) {
        Write-Verbose ('Device Found: {0}' -f $item.DeviceName)
        Write-Verbose ('Device ID: {0}' -f $item.DeviceId)
        Write-Verbose ('Current State: {0}' -f $item.State)
        Write-Verbose ('Current Volume: {0}' -f $item.Volume)
        Write-Verbose ('Current Mute: {0}' -f $item.Mute)

        if ($item.Mute -ne $Mute) {
            Write-Verbose ('The Mute state is not desired one. Test failed.')
            $ret = $false
        }
        else {
            Write-Verbose ('The Mute state is desired one. Test passed.')
        }

        if ($item.Volume -ne $Volume) {
            Write-Verbose ('The Volume is not desired value. Test failed.')
            $ret = $false
        }
        else {
            Write-Verbose ('The Volume is desired value. Test passed.')
        }
    }

    if ($ret) {
        Write-Verbose 'All states are desired. Test passed.'
    }
    return $ret
}

function Set-TargetResource {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DeviceName,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [uint16] $Volume,

        [Parameter()]
        [bool] $Mute = $false,

        [Parameter()]
        [bool] $SkipWhenDeviceNotPresent = $false,

        [Parameter()]
        [string] $State,

        [Parameter()]
        [bool] $IsDefaultDevice,

        [Parameter()]
        [string] $DeviceId
    )

    $MMDevice = Get-MMDevice -DeviceName $DeviceName
    if ($MMDevice.Count -eq 0) {
        Write-Verbose ('Device not found')
        if (-not $SkipWhenDeviceNotPresent) {
            Write-Error 'Device not found'
            return
        }
    }

    foreach ($device in $MMDevice) {
        Write-Verbose ('Target device: {0}' -f $device.DeviceFriendlyName)
        Write-Verbose ('Target device ID: {0}' -f $device.ID)
        Write-Verbose ('Target device State: {0}' -f $device.State.ToString())
        try {
            $device.AudioEndpointVolume.MasterVolumeLevelScalar = ($Volume / 100)
            Write-Verbose ('Changed the volume to {0}' -f [int]($device.AudioEndpointVolume.MasterVolumeLevelScalar * 100))
            $device.AudioEndpointVolume.Mute = $Mute
            Write-Verbose ('Changed the mute states to {0}' -f $device.AudioEndpointVolume.Mute)
        }
        catch {
            Write-Error -Exception $_.Exception
            continue
        }
        finally {
            $device.Dispose()
        }
    }

    Write-Verbose 'Operation Completed.'
}

function Get-MMDevice([string]$DeviceName) {
    $enum = [CoreAudio.MMDeviceEnumerator]::new()
    $allDevices = $enum.EnumerateAudioEndPoints([CoreAudio.EDataFlow]::eRender, ([CoreAudio.DEVICE_STATE]::DEVICE_STATE_ACTIVE -bor [CoreAudio.DEVICE_STATE]::DEVICE_STATE_UNPLUGGED -bor [CoreAudio.DEVICE_STATE]::DEVICE_STATE_DISABLED))
    $allDevices | Where-Object { $_.DeviceFriendlyName -match $DeviceName }
}

Export-ModuleMember -function *-TargetResource
