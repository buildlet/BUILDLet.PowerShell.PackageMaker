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

# Parameter(s)
Param(
    [Parameter(ParameterSetName = 'Path')]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]
    # Release Notes を作成する対象のルートディレクトリのパスを指定します。
    # 省略した場合は、このスクリプトと同じディレクトリが指定されます。
    $Path = $PSScriptRoot,

    [Parameter(ParameterSetName = 'Path')]
    [string]
    # 作成した Release Notes をファイルに保存する場合に、保存パスを指定します。
    # このパラメーターを指定しなかった場合は、Release Notes の内容は標準出力に出力されます。
    $DestinationPath,
    
    [Parameter(ParameterSetName = 'Path', Mandatory = $true)]
    [hashtable]
    # 文字列の置換テーブルを Hashtable で指定します。
    $StringTable,
    
    [Parameter(ParameterSetName = 'Path')]
    [string]
    # Project Name を指定します。
    $ProjectName = '__PROJECT_NAME__',
    
    [Parameter(ParameterSetName = 'Path')]
    [string]
    # Project Version を指定します。
    $ProjectVersion = '__PROJECT_VERSION__',

    [Parameter(ParameterSetName = 'Version', Mandatory = $true)]
    [switch]
    # このスクリプトのバージョンを表示します。
    $Version
)

# Required Module(s)
#Requires -Module @{ ModuleName = 'BUILDLet.PowerShell.Utilities'; ModuleVersion = '1.6.3' }
#Requires -Module @{ ModuleName = 'BUILDLet.PowerShell.PackageMaker'; ModuleVersion = '1.6.3' }

# SET Script Version
$ScriptVersion = '1.6.3'

# RETURN: Version
if ($Version) { return $ScriptVersion }


################################################################################
# Function(s)
################################################################################

# New-BaseHtmlRawContent
function New-BaseHtmlRawContent {

    # Paremeter(s) for this function 
    param (
        [Parameter()]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]
        $Path,

        [Parameter()]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]
        $BaseHtmlFilePath,

        [Parameter()]
        [string[]]
        $TargetString,

        [Parameter()]
        [hashtable]
        $StringTable
    )

    # GET Directory Path & Name
    $dir_path = Convert-Path -Path $Path
    $dir_name = $dir_path | Split-Path -Leaf

    # GET Target String (Use pre-defined String or Directory Name)
    $new_string = (($null -ne $StringTable) -and ($StringTable.ContainsKey($dir_name))) `
        ? $StringTable.$dir_name `
        : $dir_name

    # GET RAW content
    $RAW_content = (Get-Content -Path $BaseHtmlFilePath -Raw) -replace $TargetString, $new_string
    
    # RETURN: RAW content
    return $RAW_content
}


################################################################################
# START
################################################################################

# This script is based on assumption of the following directory structure;
#   - $Path/Model/Driver/Language/Archtecture

# GET RAW content of Base of Release Notes
$RAW_content = `
    Get-Content -Path './ReleaseNotes.html' -Raw | `
    Get-StringReplacedBy -SubstitutionTable @{
        '__PROJECT_NAME__' = $ProjectName
        '__PROJECT_VERSION__' = $ProjectVersion
    }

# GET HTML contents of Base of Release Notes
$HTML_contents = Get-HtmlContent -InputObject $RAW_content


# for Level 1 (H3: Model)
$Path | Get-ChildItem -Directory | ForEach-Object {

    # GET Directory Path of Level 1 (H3: Model)
    $model_dir_path = $_.FullName

    # Paremeter of New-BaseHtmlRawContent function for Level 1 (H3: Model)
    $parmeter_H3 = @{
        Path = $model_dir_path
        BaseHtmlFilePath = './ReleaseNotes_Level1_H3.html'
        TargetString = '__LEVEL1_TITLE__'
        StringTable = $StringTable
    }

    # GET Base HTML RAW content of Level 1 (H3: Model)
    $model_RAW_content = New-BaseHtmlRawContent @parmeter_H3

    # GET HTML contents of Level 1 (H3: Model)
    $model_HTML_contents = Get-HtmlContent -InputObject $model_RAW_content


    # for Level 2 (H4: Driver)
    $model_dir_path | Get-ChildItem -Directory | ForEach-Object {

        # GET Directory Path of Level 2 (for H4: Driver)
        $driver_dir_path = $_.FullName

        # Paremeter of New-BaseHtmlRawContent function for Level 2 (H4: Driver)
        $parmeter_H4 = @{
            Path = $driver_dir_path
            BaseHtmlFilePath = './ReleaseNotes_Level2_H4.html'
            TargetString = '__LEVEL2_TITLE__'
            StringTable = $StringTable
        }

        # GET Base HTML RAW content of Level 2 (H4: Driver)
        $driver_RAW_content = New-BaseHtmlRawContent @parmeter_H4

        # GET HTML contents of Level 2 (H4: Driver)
        $driver_HTML_contents = Get-HtmlContent -InputObject $driver_RAW_content

        
        # for Level 3 (H5: Language)
        $driver_dir_path | Get-ChildItem -Directory | ForEach-Object {

            # GET Directory Path of Level 3 (H5: Language)
            $lang_dir_path = $_.FullName

            # Paremeter of New-BaseHtmlRawContent function for Level (H5: Language)
            $parmeter_H5 = @{
                Path = $lang_dir_path
                BaseHtmlFilePath = './ReleaseNotes_Level3_H5.html'
                TargetString = '__LEVEL3_TITLE__'
                StringTable = $StringTable
            }

            # GET Base HTML RAW content of Level 3 (H5: Language)
            $language_RAW_content = New-BaseHtmlRawContent @parmeter_H5

            # GET HTML contents of Level 3 (H5: Language)
            $language_HTML_contents = Get-HtmlContent -InputObject $language_RAW_content


            # for for TR in Table in Level 3
            $lang_dir_path | Get-ChildItem -Directory | ForEach-Object {

                # GET Directory Path of Level 4 (Archtecture (x86 or x64))
                $arch_dir_path = $_.FullName
                $arch_dir_name = $arch_dir_path | Split-Path -Leaf

                # GET Archtecture Name
                $driver_arch_name = (($null -ne $StringTable) -and ($StringTable.ContainsKey($arch_dir_name))) `
                    ? $StringTable.$arch_dir_name `
                    : $arch_dir_name


                # GET Package Directory Path (= Level 4: Archtecture Directory Path)
                $package_dir_path = $arch_dir_path

                # GET Settings from INF File
                $inf_settings = Get-PrivateProfile `
                    -Path ($package_dir_path | Join-Path -ChildPath "*.INF") `
                    -IgnoreDuplicatedEntry

                # GET Driver Name, Date & Version from INF Settings
                $driver_name = ($inf_settings.'Strings'.'PRINTER' -split '"')[1]
                $driver_date = ($inf_settings.'Version'.'DriverVer' -split ',')[0]
                $driver_version = ($inf_settings.'Version'.'DriverVer' -split ',')[1]

                # GET Driver Signer Name
                $driver_signer_name = Get-AuthenticodeSignerName `
                    -FilePath ($package_dir_path | Join-Path -ChildPath "*.CAT")

                # GET Driver Signature Timestamp
                $driver_signature_timestamp = Get-AuthenticodeTimeStampString `
                    -FilePath ($package_dir_path | Join-Path -ChildPath "*.CAT")

                # GET RAW content of TR: Version
                $version_RAW_content = `
                    Get-Content -Path './ReleaseNotes_Level4_TR.html' -Raw | `
                    Get-StringReplacedBy -SubstitutionTable @{
                        '__DRIVER_NAME__' = $driver_name
                        '__DRIVER_ARCH_NAME__' = $driver_arch_name
                        '__DRIVER_DATE__' = $driver_date
                        '__DRIVER_VERSION__' = $driver_version
                        '__DRIVER_SIGNER_NAME__' = $driver_signer_name
                        '__DRIVER_SIGNATURE_TIMESTAMP__' = $driver_signature_timestamp
                    }

                # GET HTML contents of Level 4 (TR)
                $version_HTML_contents = Get-HtmlContent -InputObject $version_RAW_content


                # ADD HTML content of Level 4 (TR) into Table in Level 3 (H5)
                $language_HTML_contents['table', 0]['tbody', 0].Contents.AddRange($version_HTML_contents)
            }

            # ADD HTML content of Level 3 (H5) into Level 2 (H4)
            $driver_HTML_contents['div', 0].Contents.AddRange($language_HTML_contents)
        }

        # ADD HTML content of Level 2 (H4) into Level 1 (H3)
        $model_HTML_contents['div', 0].Contents.AddRange($driver_HTML_contents)
    }

    # ADD HTML content of Level 1 (H3) into Releae Notes
    $HTML_contents['html', 0]['body', 0]['div', 0]['div', 1].Contents.AddRange($model_HTML_contents)
}

# GET HTML contents of Restrictions
$restrictions_HTML_contents = Get-HtmlContent -Path '.\ReleaseNotes_Restrictions.html'

# ADD HTML content of Restrictions into Releae Notes
$HTML_contents['html', 0]['body', 0]['div', 0]['div', 2].Contents.AddRange($restrictions_HTML_contents)


# OUTPUT
if ($null -ne $DestinationPath) {
    
    # OUTPUT to File
    $HTML_contents.RawText | Out-File -FilePath $DestinationPath
}
else {
    # OUTPUT to Standard Output Stream
    $HTML_contents.RawText | Write-Output
}
