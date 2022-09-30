BUILDLet PackageMaker Toolkit for PowerShell (BUILDLet.PowerShell.PackageMaker)
===============================================================================

Introduction
------------

This project provides utility commands (Functions) to create the driver package by PowerShell.

Getting Started
---------------

The Artifact of this project is PowerShell Module, which is provided and is installable from
[PowerShell Gallery](https://www.powershellgallery.com).  
Copy and Paste the following command to install this package using [PowerShellGet](https://docs.microsoft.com/en-us/powershell/module/powershellget).

```PowerShell
Install-Module -Name BUILDLet.PowerShell.PackageMaker
```

This module requires another PowerShell module [BUILDLet.PowerShell.Utilities](https://www.powershellgallery.com/packages/BUILDLet.PowerShell.Utilities). If this module is not installed into your system, please also type the following command to install the package before installing "BUILDLet.PowerShell.PackageMaker".

```PowerShell
Install-Module -Name BUILDLet.PowerShell.Utilities
```

Build and Test
--------------

This project is tested by [Pester](https://pester.dev/) (<https://pester.dev> or <https://github.com/pester/>) integrated in [Visual Studio Code](https://code.visualstudio.com/).

About Sample Package
--------------------

This project is including **Sample Package**, which consists of build script ("Build.ps1") and its related files and source of dummy package.

Build script and its related files are the followings.

- "Build.ps1": Build script.
- "Build.ini": Setting file.
- ~~"Get-Settings.ps1": Utility command to get settings from INI file customized for this build script.~~
- ~~"Update-Readme.ps1": Utility command to update readme file customized for this build script.~~
- "New-ReleaseNotes.ps1": Utility command to create Release Notes as HTML file including version information of this release.

Dummy package consists of the followings.

- Dummy Driver: Zipped dummy driver package, which consists of a INF file and some DLL files.  
  In this Sample Package, the catalog files will be created, and signature will be added to these, using commands which respectively wrapps "inf2cat" and "signtool" utility.
- Readme: Dummy readme files in English and Japanese.  
  In this Sample Package, date, driver versions and some other strings will be updated.
- Sample.pfx: PFX file to be used for code signing.
- Autorun.inf
- Sample.ico

To build the sample package, please do the following procedure.

1. Import "BUILDLet.PowerShell.PackageMaker" module.  
   ("BUILDLet.PowerShell.Utilities" module will be imported automatically.)  

   To import the module, please type the following command.

   ```PowerShell
   Import-Module -Name BUILDLet.PowerShell.PackageMaker
   ```

2. Locate the "SamplePackage" directory to some arbitaly place. (e.g., "C:\Temp\SamplePackage")  
   And, set current location to there.

3. Type the following command.

   ```PowerShell
   .\Build.ps1
   ```

4. If the following error message is show, certificate file to be used for code signing may be expired.

   ```cmd
   SignTool Error: No certificates were found that met all the given criteria.
   ```

   To create new PFX file, type the following command. Please note that this command should be run as Administrator.

   ```PowerShell
   New-TestCertificate -Path .\Sample -Subject 'BUILDLet Sample Package' -Verbose
   ```

5. As the artifact of the sample package, the ISO image file "Sample.iso" is generated at "Destination" directory under "SamplePackage" directory. (e.g., "C:\Temp\SamplePackage\Destination\Sample.iso)  
Also, Release Notes as HTML file is generated in the same directory.

License
-------

This project is licensed under the [MIT](https://opensource.org/licenses/MIT) License.
