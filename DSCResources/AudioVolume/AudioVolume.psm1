$LibsPath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Libs'

Add-Type -Path (Join-Path $LibsPath '\CoreAudio\netstandard2.0\CoreAudio.dll')

[CoreAudio.PROPERTYKEY] $script:PKEY_DEVICE_INTERFACE_FRIENDLY_NAME = [CoreAudio.PROPERTYKEY]::new([Guid]::new('026E516E-B814-414B-83CD-856D6FEF4822'), 2)
[CoreAudio.PROPERTYKEY] $script:PKEY_DEVICE_FRIENDLY_NAME = [CoreAudio.PROPERTYKEY]::new([Guid]::new('A45C254E-DF1C-4EFD-8020-67D146A850E0'), 14)
[CoreAudio.PROPERTYKEY] $script:PKEY_DEVICE_DESCRIPTION = [CoreAudio.PROPERTYKEY]::new([Guid]::new('A45C254E-DF1C-4EFD-8020-67D146A850E0'), 2)
[CoreAudio.PROPERTYKEY] $script:PKEY_SYSTEM_NAME = [CoreAudio.PROPERTYKEY]::new([Guid]::new('B3F8FA53-0004-438E-9003-51A46E139BFC'), 6)

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

    if ($null -eq $MMDevice) {
        Write-Verbose ('Device not found')
        return $null
    }

    $result = @{}
    $result.DeviceName = $MMDevice.Properties.Item($script:PKEY_DEVICE_FRIENDLY_NAME).Value
    $result.DeviceId = $MMDevice.ID
    $result.State = $MMDevice.State.ToString()
    $result.IsDefaultDevice = $MMDevice.Selected
    $result.Volume = [uint16]($MMDevice.AudioEndpointVolume.MasterVolumeLevelScalar * 100)
    $result.Mute = $MMDevice.AudioEndpointVolume.Mute

    return $result
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

    Write-Verbose ('Device Found: {0}' -f $CurrentState.DeviceName)
    Write-Verbose ('Device ID: {0}' -f $CurrentState.DeviceId)
    Write-Verbose ('Current State: {0}' -f $CurrentState.State)
    Write-Verbose ('Current Volume: {0}' -f $CurrentState.Volume)
    Write-Verbose ('Current Mute: {0}' -f $CurrentState.Mute)

    if ($CurrentState.Mute -ne $Mute) {
        Write-Verbose ('Mute state is not desited one. Test failed.')
        return $false
    }

    if ($CurrentState.Volume -ne $Volume) {
        Write-Verbose ('Volume is not desited value. Test failed.')
        return $false
    }

    Write-Verbose 'All states are desired. Test passed.'
    return $true
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
    if ($null -eq $MMDevice) {
        Write-Verbose ('Device not found')
        if (-not $SkipWhenDeviceNotPresent) {
            Write-Error 'Device not found'
            return
        }
    }

    if ($MMDevice.State -ne [CoreAudio.DEVICE_STATE]::DEVICE_STATE_ACTIVE) {
        Write-Error ('We can not change volume when the device is not Active. (Current State is {0})' -f $MMDevice.State.ToString())
        return
    }

    try {
        $MMDevice.AudioEndpointVolume.MasterVolumeLevelScalar = ($Volume / 100)
        Write-Verbose ('Changed the volume to {0}' -f [int]($MMDevice.AudioEndpointVolume.MasterVolumeLevelScalar * 100))
        $MMDevice.AudioEndpointVolume.Mute = $Mute
        Write-Verbose ('Changed the mute states to {0}' -f $MMDevice.AudioEndpointVolume.Mute)
    }
    catch {
        Write-Error -Exception $_.Exception
        Write-Verbose 'Operation Failed.'
        return
    }

    Write-Verbose 'Operation Completed.'
}

function Get-MMDevice([string]$DeviceName) {
    $enum = [CoreAudio.MMDeviceEnumerator]::new()
    $allDevices = $enum.EnumerateAudioEndPoints([CoreAudio.EDataFlow]::eRender, ([CoreAudio.DEVICE_STATE]::DEVICE_STATE_ACTIVE -bor [CoreAudio.DEVICE_STATE]::DEVICE_STATE_UNPLUGGED -bor [CoreAudio.DEVICE_STATE]::DEVICE_STATE_DISABLED))
    foreach ($device in $allDevices) {
        if ($device.Properties.Item($script:PKEY_DEVICE_FRIENDLY_NAME).Value -match $DeviceName) {
            return $device
            break
        }
    }
    return $null
}

Export-ModuleMember -function *-TargetResource

# [DscResource()]
# class AudioVolume {
#     # DSC Properties
#     [DscProperty(Key)]
#     [ValidateNotNullOrEmpty()]
#     [string]$DeviceName

#     [DscProperty(Mandatory)]
#     [ValidateRange(0, 100)]
#     [uint16] $Volume

#     [DscProperty()]
#     [bool] $Mute = $false

#     [DscProperty()]
#     [bool] $SkipWhenDeviceNotPresent = $false

#     [DscProperty(NotConfigurable)]
#     [String] $State

#     [DscProperty(NotConfigurable)]
#     [bool] $IsDefaultDevice

#     [DscProperty(NotConfigurable)]
#     [string] $DeviceId

#     # Private (Hidden) field
#     [CoreAudio.PROPERTYKEY] Hidden $PKEY_DEVICE_INTERFACE_FRIENDLY_NAME = [CoreAudio.PROPERTYKEY]::new([Guid]::new('026E516E-B814-414B-83CD-856D6FEF4822'), 2)
#     [CoreAudio.PROPERTYKEY] Hidden $PKEY_DEVICE_FRIENDLY_NAME = [CoreAudio.PROPERTYKEY]::new([Guid]::new('A45C254E-DF1C-4EFD-8020-67D146A850E0'), 14)
#     [CoreAudio.PROPERTYKEY] Hidden $PKEY_DEVICE_DESCRIPTION = [CoreAudio.PROPERTYKEY]::new([Guid]::new('A45C254E-DF1C-4EFD-8020-67D146A850E0'), 2)
#     [CoreAudio.PROPERTYKEY] Hidden $PKEY_SYSTEM_NAME = [CoreAudio.PROPERTYKEY]::new([Guid]::new('B3F8FA53-0004-438E-9003-51A46E139BFC'), 6)

#     [CoreAudio.MMDevice] Hidden $MMDevice

#     [AudioVolume] GetDevice([string]$DeviceName) {
#         Add-Type -Path (Join-Path $PSScriptRoot '\Libs\CoreAudio\netstandard2.0\CoreAudio.dll')

#         $result = [AudioVolume]::new()
#         $enum = [CoreAudio.MMDeviceEnumerator]::new()
#         $allDevices = $enum.EnumerateAudioEndPoints([CoreAudio.EDataFlow]::eRender, ([CoreAudio.DEVICE_STATE]::DEVICE_STATE_ACTIVE -bor [CoreAudio.DEVICE_STATE]::DEVICE_STATE_UNPLUGGED -bor [CoreAudio.DEVICE_STATE]::DEVICE_STATE_DISABLED))
#         foreach ($device in $allDevices) {
#             if ($device.Properties.Item($this.PKEY_DEVICE_FRIENDLY_NAME).Value -match $DeviceName) {
#                 $result.MMDevice = $device
#                 $result.DeviceName = $device.Properties.Item($this.PKEY_DEVICE_FRIENDLY_NAME).Value
#                 $result.DeviceId = $device.ID
#                 $result.State = $device.State
#                 $result.IsDefaultDevice = $device.Selected
#                 $result.Volume = [uint16]($device.AudioEndpointVolume.MasterVolumeLevelScalar * 100)
#                 $result.Mute = $device.AudioEndpointVolume.Mute
#                 return $result
#                 break
#             }
#         }
#         return $null
#     }

#     [void] SetVolume([uint16] $Volume) {
#         if ($Volume -lt 0 -or $Volume -gt 100) {
#             throw [System.ArgumentOutOfRangeException]::new()
#             return
#         }

#         if ($null -eq $this.MMDevice) {
#             throw [System.InvalidOperationException]::new()
#             return
#         }

#         $this.MMDevice.AudioEndpointVolume.MasterVolumeLevelScalar = ($Volume / 100)
#         $this.Volume = $this.MMDevice.AudioEndpointVolume.MasterVolumeLevelScalar
#     }

#     [void] SetMute([bool] $Mute) {
#         if ($null -eq $this.MMDevice) {
#             throw [System.InvalidOperationException]::new()
#             return
#         }

#         $this.MMDevice.AudioEndpointVolume.Mute = $Mute
#         $this.Mute = $this.AudioEndpointVolume.Mute
#     }

#     <#
#         This method is equivalent of the Test-TargetResource script function.
#         It should return True or False, showing whether the resource
#         is in a desired state.
#     #>
#     [bool] Test() {
#         $CurrentState = $this.Get()
#         if ($null -eq $CurrentState) {
#             Write-Verbose ('Device not found')
#             if ($this.SkipWhenDeviceNotPresent) {
#                 Write-Warning 'Device not found but TEST RETURNS TRUE because SkipWhenDeviceNotPresent is specified as true.'
#                 return $true
#             }
#             else {
#                 return $false
#             }
#         }

#         Write-Verbose ('Device Found: {0}' -f $CurrentState.DeviceName)
#         Write-Verbose ('Device ID: {0}' -f $CurrentState.DeviceId)
#         Write-Verbose ('Current State: {0}' -f $CurrentState.State.ToString())
#         Write-Verbose ('Current Volume: {0}' -f $CurrentState.Volume)
#         Write-Verbose ('Current Mute: {0}' -f $CurrentState.Mute)

#         if ($CurrentState.Mute -ne $this.Mute) {
#             Write-Verbose ('Mute state is not desited one. Test failed.')
#             return $false
#         }

#         if ($CurrentState.Volume -ne $this.Volume) {
#             Write-Verbose ('Volume is not desited value. Test failed.')
#             return $false
#         }

#         Write-Verbose 'All states are desired. Test passed.'
#         return $true
#     }

#     <#
#         This method is equivalent of the Get-TargetResource script function.
#         The implementation should use the keys to find appropriate resources.
#         This method returns an instance of this class with the updated key
#          properties.
#     #>
#     [AudioVolume] Get() {
#         $CurrentState = $this.GetDevice($this.DeviceName)
#         return $CurrentState
#     }

#     <#
#         This method is equivalent of the Set-TargetResource script function.
#         It sets the resource to the desired state.
#     #>
#     [void] Set() {
#         $CurrentState = $this.Get()
#         if ($null -eq $CurrentState) {
#             Write-Verbose ('Device not found')
#             if (-not $this.SkipWhenDeviceNotPresent) {
#                 Write-Error 'Device not found'
#                 return
#             }
#         }

#         if ($CurrentState.State -ne [CoreAudio.DEVICE_STATE]::DEVICE_STATE_ACTIVE) {
#             Write-Error ('We can not change volume when the device is not Active. (Current State is {0})' -f $CurrentState.State)
#             return
#         }

#         try {
#             $CurrentState.SetVolume($this.Volume)
#             Write-Verbose ('Changed the volume to {0}' -f $CurrentState.Volume)
#             $CurrentState.SetMute($this.Mute)
#             Write-Verbose ('Changed the mute states to {0}' -f $CurrentState.Mute)
#         }
#         catch {
#             Write-Error -Exception $_.Exception
#             Write-Verbose 'Operation Failed.'
#             return
#         }

#         Write-Verbose 'Operation Completed.'
#     }

# } # This module defines a class for a DSC "AudioVolume" provider.
