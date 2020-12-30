<###############################################################################
 The MIT License (MIT)

 Copyright (c) 2020 Daiki Sakamoto

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
################################################################################>

# Target Module:
$target_module_name = 'BUILDLet.PowerShell.PackageMaker'

# Check Required Module
. ($PSScriptRoot | Join-Path -ChildPath 'RequiredModule.ps1')

# Import Target Module
# (Get Target Module, remove it if required, and import it again)
if ($null -ne ($target_module = Get-Module -Name $target_module_name)) { $target_module | Remove-Module }
Import-Module -Name ($PSScriptRoot | Split-Path -Parent | Join-Path -ChildPath $target_module_name)


# NEW & SET $TargetDir
$TargetDir = New-Item -Path ($PSScriptRoot | Join-Path -ChildPath 'bin') -ItemType Directory -Force


# Update-StringsInContent
Describe "Update-StringsInContent" {

    BeforeEach {

        # Set Location
        Set-Location -Path $TargetDir
    }


    AfterEach {

        # Reset Location
        Set-Location -Path $PSScriptRoot
    }


    Context "normally" {

        $TestCase = @(

            # 1) Update-StringsInContentTest1
            @{
                FileName = 'Update-StringsInContentTest1.txt'
                Encoding = 'UTF8'
                content = @"
Helo, __TEST__.
"@
                Expected = @"
Helo, world.
"@
                TargetStrings = @{
                    '__TEST__' = 'world'
                }
            }

            # 2) Update-StringsInContentTest2
            @{
                FileName = 'Update-StringsInContentTest2.txt'
                Encoding = 'UTF8'
                content = @"
Copyright (c) __COPYRIGHT_YEAR__ BUILDLet
__DATE__
Version __VERSION__
"@
                Expected = @"
Copyright (c) 2019-2020 BUILDLet
December 20, 2020
Version 1.50
"@
                TargetStrings = @{
                    '__COPYRIGHT_YEAR__' = '2019-2020'
                    '__DATE__' = 'December 20, 2020'
                    '__VERSION__' = '1.50'
                }
            }

            <# N/A
            # 3) Update-StringsInContentTest3
            @{
                FileName = 'Update-StringsInContentTest3.txt'
                Encoding = 'UTF8'
                content = @"
A = __SCRIPTBLOCK_A__
B = __SCRIPTBLOCK_B__
C = __SCRIPTBLOCK_C__
"@
                Expected = @"
A = 1
B = Hello, world.
C = Hello
"@
                TargetStrings = @{
                    '__SCRIPTBLOCK_A__' = '{$x = 1; $x}'
                    '__SCRIPTBLOCK_B__' = '{Write-Output "Hello, world."}'
                    '__SCRIPTBLOCK_C__' = '{"Hello, world.".Split('','')[0]}'
                }
            }
            #>
        )

        It "replaces strngs in content" -TestCases $TestCase {

            # PARAMETER(S)
            Param($FileName, $Encoding, $content, $Expected, $TargetStrings)

            # ARRANGE: NEW File
            $content | Out-File -FilePath $FileName -Encoding $Encoding -NoNewline -Force

            # ACT
            Update-StringsInContent -Path $FileName -TargetStrings $TargetStrings -Encoding $Encoding

            # ASSERT
            Get-Content -Path $FileName -Encoding $Encoding -Raw | Should Be $Expected
        }
    }
}