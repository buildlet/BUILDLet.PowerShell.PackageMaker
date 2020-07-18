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
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]
    # Readme ファイルのパスを指定します。
    $FilePath,

    [Parameter()]
    [datetime]
    # $Date の日付を指定します。
    # 既定では、このコマンドを実行した時点です。
    $Date = (Get-Date),

    [Parameter()]
    [string]
    # $Date の日付を置き換える Readme ファイルに記載されている文字列を指定します。
    $DateReplaceString,

    [Parameter()]
    [string]
    # $Date の日付を表記する際の LCID を指定します。
    # 既定では 'en-US' です。
    $LCID = 'en-US',

    [Parameter()]
    [string]
    # $Date の日付を表記する際の書式指定文字列を指定します。
    # 既定では 'D' です。
    $DateFormatString = 'D',

    [Parameter()]
    [string[]]
    # ドライバーのバージョン (DriverVer) を取得する設定ファイル (INF ファイル) のパスを指定します。
    $DriverVer,

    [Parameter()]
    [string[]]
    # $Date の日付を置き換える Readme ファイルに記載されている文字列を指定します。
    $DriverVerReplaceString,

    [Parameter()]
    [string[]]
    # $Date, $DriverVer 以外の更新対象の文字列と更新後の文字列を指定します。
    # 各要素のコンマ区切り 1 番目の要素が差し替え前の文字列、2 番目の要素が差し替え後の文字列です。
    $Strings
)

<###############################################################################
 Process
################################################################################>

# for $Path
$FilePath |
Resolve-Path |
Where-Object { $_ | Test-Path -PathType Leaf } |
ForEach-Object {

    # GET Readme File Path
    $readme_filepath = $_

    # GET Readme content
    $readme_content = Get-Content -Path $readme_filepath


    # for 'Date'
    if ($DateReplaceString) {
        
        # GET Date String
        $date_string = New-DateString -Date $Date -LCID $LCID -Format $DateFormatString

        # UPDATE Content
        $readme_content = $readme_content -replace $DateReplaceString, $date_string
    }


    # for 'DriverVer'
    if ($DriverVer -or $DriverVerReplaceString) {

        # Validation for count of 'DriverVer' and 'DriverVerReplaceStrings'
        if($DriverVer.Count -ne $DriverVer.Count) { throw New-Object System.ArgumentException }

        # for 'DriverVer'
        for ($i = 0; $i -lt $DriverVer.Count; $i++) {

            # GET DriverVer from INF file
            $driverder_string = (Get-PrivateProfile -Path $DriverVer[$i] -Section 'Version' -Key 'DriverVer').Split(',')[1].Trim()
            
            # UPDATE Content
            $readme_content = $readme_content -replace $DriverVerReplaceString[$i], $driverder_string
        }
    }


    # for $Strings
    for ($i = 0; $i -lt $Strings.Count; $i++) {

        # UPDATE Content
        $readme_content = $readme_content -replace $Strings[$i].Split(',')[0], $Strings[$i].Split(',')[1]
    }


    # Write Content to file
    $readme_content | Out-File -FilePath $readme_filepath
}
