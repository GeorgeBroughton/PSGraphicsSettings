function Set-PreferredGPU {
    <#
    .SYNOPSIS
    Sets the preferred graphics processor for a given application.

    .DESCRIPTION
    Sets the preferred graphics processor for a given application.

    .PARAMETER Path
    A System.IO.FileInfo object, or a string identifying the path to an executable file. This will be automatically converted to a System.IO.FileInfo object within the function.

    .PARAMETER GraphicsProfile
    1 of 3 options.

        +------------------+-----------------------------------------------+
        | Option           | Description                                   |
        +------------------+-----------------------------------------------+
        | Auto             | Lets Windows decide which GPU should be used. |
        | Low Performance  | Forces the Low Performance GPU to be used.    |
        | High Performance | Forces the High Performance GPU to be used.   |
        +------------------+-----------------------------------------------+

    .INPUTS
    You can pipe System.IO.FileInfo objects to this function.

    .OUTPUTS
    This function modifies the registry at the following location:
        HKCU:\Software\Microsoft\DirectX\UserGpuPreferences

    An object is output once this is complete, which looks like this:

    Path            : C:\Windows\Notepad.exe
    GraphicsProfile : Auto

    .EXAMPLE
    PS> Set-PreferredGPU -Path "C:\Windows\Notepad.exe" -GraphicsProfile "Auto"

    Path            : C:\Windows\Notepad.exe
    GraphicsProfile : Auto

    .EXAMPLE
    PS> Get-ChildItem -Path "E:\SteamLibrary" -Recurse -File | Where-Object Extension -eq '.exe' | Set-PreferredGPU -GraphicsProfile "High Performance"

    Path            : C:\somerandomapplication1.exe
    GraphicsProfile : High Performance

    Path            : C:\somerandomapplication2.exe
    GraphicsProfile : High Performance

    ...
    #>
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline=$true)][System.IO.FileInfo]$Path,
        [ValidateSet('Auto','Low Performance','High Performance')][string]$GraphicsProfile
    )
    Begin {
        if (!(Test-Path -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences")) {
            [void](New-Item -Path "HKCU:\Software\Microsoft\DirectX" -Force)
            [void](New-Item -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Force)
        }
        switch ($GraphicsProfile) {
            'Auto'             { $GPUProfile="GpuPreference=0;" }
            'Low Performance'  { $GPUProfile="GpuPreference=1;" }
            'High Performance' { $GPUProfile="GpuPreference=2;" }
        }
    }
    Process {
        if ( (Test-Path -Path $Path -PathType Leaf) -and ($Path.Extension -eq ".exe") ) {
            try {
                [void](New-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name $Path.FullName -Value $GPUProfile -PropertyType String -Force)
                [PSCustomObject]@{
                    Path = $Path
                    GraphicsProfile = $GraphicsProfile
                }
            }
            catch {
                Write-Error $_
            }
        } else {
            Write-Error "File path '$($Path.FullName)' does not exist, or is of incorrect type."
        }
    }
}