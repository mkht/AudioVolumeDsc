AudioVolumeDsc
====

PowerShell DSC Resource to control audio volume.

## Install
You can install Resource through [PowerShell Gallery](https://www.powershellgallery.com/packages/AudioVolumeDsc/).
```PowerShell
Install-Module -Name AudioVolumeDsc
```

## Resources
* **AudioVolume**
PowerShell DSC Resource to control audio volume.

## Properties
### AudioVolume
+ [string] **DeviceName** (Key):
    + The name of the audio device.
    + You can use regular expression.
    + If more than one devices found, all devices are targeted for configuration.

+ [int] **Volume** (Required):
    + The target volume. (0 to 100)

+ [bool] **Mute** (Write):
    + The state of mute.
    + Default is `$false`

+ [bool] **SkipWhenDeviceNotPresent** (Write):
    + When this property is specied as `$true`, this resouce won't throw an error if the device is not found.
    + Default is `$false`

## Examples
+ **Example 1**: Set the volume of the "Speaker" to 80.
```PowerShell
Configuration Example1
{
    Import-DscResource -ModuleName AudioVolumeDsc
    AudioVolume Speaker80
    {
        DeviceName = 'Speaker'
        Volume = 80
        Mute = $false
    }
}
```

## License
> Copyright (c) 2020 mkht  
> AudioVolumeDsc is released under the MIT License  
> https://github.com/mkht/AudioVolumeDsc/blob/master/LICENSE
>
> AudioVolumeDsc includes these software / libraries.
> * [CoreAudio](https://github.com/morphx666/CoreAudio)  
> Copyright (c) 2017 Xavier Flix  
> Licensed under the [MIT License](https://github.com/morphx666/CoreAudio/blob/master/LICENSE).

## ChangeLog
### v2.0.0
 - if multiple devices with the same name are found, all devices are targeted for configuration.
 - Devices in an inactive state are also targeted for configuration.
 - Update [CoreAudio.dll](https://www.nuget.org/packages/CoreAudio/1.16.0) (v1.16.0)

### v1.0.0
 - First public release.
