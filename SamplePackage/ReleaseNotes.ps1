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


<###############################################################################
 Parameter(s)
################################################################################>
Param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]
    # Release Notes を作成する対象のルートディレクトリのパスを指定します。
    $Path = $PSScriptRoot,

    [Parameter()]
    [string]
    # 作成した Release Notes をファイルに保存する場合に、保存パスを指定します。
    # このパラメーターを指定しなかった場合は、Release Notes の内容は標準出力に出力されます。
    $DestinationPath,
    
    [Parameter()]
    [hashtable]
    # 文字列の置換テーブルを Hashtable で指定します。
    $StringTable,
    
    [Parameter()]
    [string]
    # Project Name を指定します。
    $ProjectName,
    
    [Parameter()]
    [string]
    # Project Version を指定します。
    $ProjectVersion
)


<###############################################################################
 Requires
################################################################################>
#Requires -Module @{ ModuleName = 'BUILDLet.PowerShell.Utilities'; RequiredVersion = '1.5.1' }
#Requires -Module @{ ModuleName = 'BUILDLet.PowerShell.PackageMaker'; RequiredVersion = '1.5.1' }


<###############################################################################
 Variable(s)
################################################################################>
# Script Version
$ScriptVersion = '1.5.1'

# Foreground Color
$ForegroundColor = 'Green'


<###############################################################################
 Function(s)
################################################################################>
# (None)

<###############################################################################
 Process
################################################################################>
# OUTPUT: START Message
"'" + ($PSCommandPath | Split-Path -Leaf) + "' Version $ScriptVersion" | Write-Host -ForegroundColor $ForegroundColor


# GET RAW content of Base of Release Notes
$RAW_content = Get-Content -Path './ReleaseNotes.html' -Raw

# UPDATE RAW content
if ($null -ne $ProjectName) {

    # UPDATE Project Name
    $RAW_content = $RAW_content -replace '__PROJECT_NAME__', $ProjectName
}
if ($null -ne $ProjectVersion) {

    # UPDATE Project Version
    $RAW_content = $RAW_content -replace '__PROJECT_VERSION__', $ProjectVersion
}

# GET HTML contents of Base of Release Notes
$html_contents = Get-HtmlContent -InputObject $RAW_content


# for Model(s)
$Path | Get-ChildItem -Directory | ForEach-Object {

    # GET Directory Path & Name of 'Model'
    $model_dir_path = $_.FullName
    $model_dir_name = $model_dir_path | Split-Path -Leaf

    # GET Model Headline
    $model_headline = $model_dir_name

    # UPDATE Model Headline (if exists)
    if (($null -ne $StringTable) -and ($StringTable.ContainsKey($model_headline))) {
        $model_headline = $StringTable.$model_headline
    }

    # GET HTML contents of H3: Model
    $model_html_contents = Get-HtmlContent `
        -InputObject ((Get-Content -Path './ReleaseNotes_H3.Model.html' -Raw) -replace '__MODEL_NAME__', $model_headline)


    # for Driver(s)
    $model_dir_path | Get-ChildItem -Directory | ForEach-Object {

        # GET Directory Path & Name of 'Driver'
        $driver_dir_path = $_.FullName
        $driver_dir_name = $driver_dir_path | Split-Path -Leaf

        # GET Driver Headline
        $driver_headline = $driver_dir_name

        # UPDATE Driver Headline (if exists)
        if (($null -ne $StringTable) -and ($StringTable.ContainsKey($driver_headline))) {
            $driver_headline = $StringTable.$driver_headline
        }

        # GET HTML contents of H4: Driver
        $driver_html_contents = Get-HtmlContent `
            -InputObject ((Get-Content -Path './ReleaseNotes_H4.Driver.html' -Raw) -replace '__DRIVER_NAME__', $driver_headline)


        # for Language(s)
        $driver_dir_path | Get-ChildItem -Directory | ForEach-Object {

            # GET Directory Path & Name of 'Language'
            $lang_dir_path = $_.FullName
            $lang_dir_name = $lang_dir_path | Split-Path -Leaf

            # GET Language Headline
            $lang_headline = $lang_dir_name

            # UPDATE Language Headline (if exists)
            if (($null -ne $StringTable) -and ($StringTable.ContainsKey($lang_headline))) {
                $lang_headline = $StringTable.$lang_headline
            }

            # GET HTML contents of H5: Language
            $language_html_contents = Get-HtmlContent `
                -InputObject ((Get-Content -Path './ReleaseNotes_H5.Language.html' -Raw) -replace '__LANGUAGE_NAME__', $lang_headline)


            # for Archtecture(s) : x86 / x64
            $lang_dir_path | Get-ChildItem -Directory | ForEach-Object {

                # GET Directory Path  & Name of Archtecture (x86 or x64)
                $arch_dir_path = $_.FullName
                $arch_dir_name = $arch_dir_path | Split-Path -Leaf

                # GET Archtecture Name
                $driver_arch_name = $arch_dir_name

                # UPDATE Archtecture Name (if exists)
                if (($null -ne $StringTable) -and ($StringTable.ContainsKey($driver_arch_name))) {
                    $driver_arch_name = $StringTable.$driver_arch_name
                }


                # GET Settings from INF File
                $inf_settings = Get-PrivateProfile -Path ($arch_dir_path | Join-Path -ChildPath "Dummy*.INF")

                # GET Driver Name, Date & Version from INF Settings
                $driver_name = $inf_settings.'Strings'.'PRINTER'
                $driver_date = ($inf_settings.'Version'.'DriverVer' -split ',')[0]
                $driver_version = ($inf_settings.'Version'.'DriverVer' -split ',')[1]

                # GET Driver Signer Name
                $driver_signer_name = Get-AuthenticodeSignerName -FilePath ($arch_dir_path | Join-Path -ChildPath "dummy*.cat")

                # GET Driver Signature Timestamp
                $driver_signature_timestamp = Get-AuthenticodeTimeStampString -FilePath ($arch_dir_path | Join-Path -ChildPath "dummy*.cat")

                # GET RAW content of TR: Version
                $version_RAW_content = Get-Content -Path './ReleaseNotes_TR.Version.html' -Raw

                # UPDATE RAW content
                $version_RAW_content = $version_RAW_content `
                    -replace '__DRIVER_NAME__', $driver_name.Substring(1, $driver_name.Length - 2) `
                    -replace '__DRIVER_ARCH_NAME__', $driver_arch_name `
                    -replace '__DRIVER_DATE__', $driver_date `
                    -replace '__DRIVER_VERSION__', $driver_version `
                    -replace '__DRIVER_SIGNER_NAME__', $driver_signer_name `
                    -replace '__DRIVER_SIGNATURE_TIMESTAMP__', $driver_signature_timestamp
                
                # GET HTML contents of TR: Version
                $version_html_contents = Get-HtmlContent -InputObject $version_RAW_content

                # ADD HTML content of 'Version' into 'Language'
                $language_html_contents['table', 0]['tbody', 0].Contents.AddRange($version_html_contents)            
            }

            # ADD HTML content of 'Language' into 'Driver'
            $driver_html_contents['div', 0].Contents.AddRange($language_html_contents)            
        }

        # ADD HTML content of 'Driver' into 'Model'
        $model_html_contents['div', 0].Contents.AddRange($driver_html_contents)            
    }

    # ADD HTML content of 'Driver' into Releae Notes
    $html_contents['html', 0]['body', 0]['div', 0]['div', 1].Contents.AddRange($model_html_contents)
}


# OUTPUT
if ($null -ne $DestinationPath) {
    
    # OUTPUT to File
    $html_contents.RawText | Out-File -FilePath $DestinationPath
}
else {
    # OUTPUT to Standard Output Stream
    $html_contents.RawText | Write-Output
}
