enum Ensure {
    Absent
    Present
}

<#
   This resource manages audio volumes on the sound devices.
   [DscResource()] indicates the class is a DSC resource
#>

[DscResource()]
class AudioVolume {
    [DscProperty(Key)]
    [string]$DeviceName

    [DscProperty(Mandatory)]
    [ValidateRange(0, 100)]
    [uint16] $Volume

    [DscProperty()]
    [bool] $Mute = $false

    [DscProperty()]
    [bool] $SkipWhenDeviceNotPresent = $false

    [DscProperty(NotConfigurable)]
    [String] $State

    [DscProperty(NotConfigurable)]
    [bool] $IsDefaultDevice

    [DscProperty(NotConfigurable)]
    [bool] $DeviceId

    <#
        This method is equivalent of the Set-TargetResource script function.
        It sets the resource to the desired state.
    #>
    [void] Set() {

    }

    <#
        This method is equivalent of the Test-TargetResource script function.
        It should return True or False, showing whether the resource
        is in a desired state.
    #>
    [bool] Test() {
        return $true
    }

    <#
        This method is equivalent of the Get-TargetResource script function.
        The implementation should use the keys to find appropriate resources.
        This method returns an instance of this class with the updated key
         properties.
    #>
    [AudioVolume] Get() {
        return $null
    }

} # This module defines a class for a DSC "AudioVolume" provider.
