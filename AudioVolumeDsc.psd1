@{
    ModuleVersion        = '1.0.0'
    GUID                 = '31b46ae0-64e9-4801-867b-52a5923f3824'
    Author               = 'mkht'
    CompanyName          = ''
    Copyright            = '(c) 2020 mkht. All rights reserved.'
    Description          = 'PowerShell DSC Resource to control audio volume.'
    PowerShellVersion    = '4.0'
    FunctionsToExport    = @()
    CmdletsToExport      = @()
    AliasesToExport      = @()
    DscResourcesToExport = 'AudioVolume'
    PrivateData          = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = 'DesiredStateConfiguration', 'DSC', 'DSCResource'
            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/mkht/AudioVolumeDsc/blob/master/LICENSE'
            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/mkht/AudioVolumeDsc'
            # A URL to an icon representing this module.
            # IconUri = ''
            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/mkht/AudioVolumeDsc#changelog'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
