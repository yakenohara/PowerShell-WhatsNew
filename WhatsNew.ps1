# <License>------------------------------------------------------------

#  Copyright (c) 2023 Shinnosuke Yakenohara

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# -----------------------------------------------------------</License>

# <CAUTION!>
# このファイルは UTF-8 (BOM 付き) で保存すること。(ターミナルに日本語メッセージを表示するため)
# </CAUTION!>

<#
    .SYNOPSIS
    //todo 関数またはスクリプトの簡単な説明
    
    .PARAMETER DirInfo
    走査対象ディレクトリ
    文字列型か [System.IO.DirectoryInfo] 型である必要があります。

    .PARAMETER Depth
    走査対象ディレクトリからの相対的深さ (デフォルト: 0)
    例えば、"D:\test" の配下の "D:\test\xxx\yyy" が配置された階層にまで走査したい場合、`1` を指定します。
    `0` の場合は、走査対象ディレクトリ直下、
    `-1` の場合は、走査対象ディレクトリが配置された階層、
    `-2` の場合は、走査対象ディレクトリの 1 階層上を意味します。

    .PARAMETER TimeDepth
    タイムスタンプを取得する相対的深さ (デフォルトは `-Depth` と同じ)
    `-Depth` パラメータより大きい値の場合は、その差分の分まで深いディレクトリを探索し、最新のタイムスタンプを使用します。
    `-Depth` より小さい値の場合は、走査対象のディレクトリのタイムスタンプはそのすべての子要素とディレクトリそのものの中から最新のタイムスタンプを使用します。

    .PARAMETER FileOnly
    走査対象をファイルに限定します (デフォルト: $false)

    .PARAMETER DirectoryOnly
    走査対象をにディレクトリ限定します (デフォルト: $false)

    .PARAMETER OutFilePath
    出力する .html ファイルパス (デフォルト: 'カレントディレクトリ'\whats-new.html)

#>

# Note:
# '.PARAMETER <パラメーター名>' で使用する "<パラメーター名>" は、アッパーキャメルケースを使用しないと `Get-Help <スクリプトファイル> -full` 実行時にうまく認識されないらしい
# https://learn.microsoft.com/ja-jp/previous-versions/windows/powershell-scripting/hh847834(v=wps.640)?redirectedfrom=MSDN#parameter-%E3%83%91%E3%83%A9%E3%83%A1%E3%83%BC%E3%82%BF%E3%83%BC%E5%90%8D

Param(
    # 走査対象ディレクトリ
    [ValidateScript({
        if (($_ -ne $null ) -and ($_ -isnot [System.String]) -and ($_ -isnot [System.IO.DirectoryInfo])){ # 型は文字列か [DirectoryInfo](https://learn.microsoft.com/ja-jp/dotnet/api/system.io.directoryinfo?view=net-8.0) でないといけない
            return $false
        } else {
            return $true
        }
    })]$DirInfo,

    # 階層の深さ
    [System.Int32]$Depth = 0, # 型は signed int (32bit) でないといけない
    [ValidateScript({
        if (($_ -ne $null ) -and ($_ -isnot [System.Int32])){ # 型は signed int (32bit) でないといけない
            
            # `System.Int32` 型にキャスト可能かどうか検査 (バッチファイルでマイナス値を指定した場合は `System.String` 型となるため)
            try {
                [System.Int32]$_
            } catch { # キャスト失敗の場合
                Write-Error $_.Exception.Message
                return $false
            }

            # キャスト成功の場合
            return $true

        } else { # 型は signed int (32bit) もしくは null の場合
            return $true
        }
    })]$TimeDepth,

    # ファイル限定指定
    [switch]$FileOnly,

    # フォルダー限定指定
    [switch]$DirectoryOnly,

    # 出力する .html ファイルパス
    [System.String]$OutFilePath

)

# 共通関数
# 
# カスタム URI でパーセントエンコードしてくれない文字のみパーセントエンコードする
Function func_PercentEncodeForSpecialChar($str_ReplaceFrom) {
    return ($str_ReplaceFrom -replace '&','%26')
    # Note
    # `&` はブラウザ -> カスタム URI へ渡す時にエスケープしてくれないようなので、ここで実施
    # エスケープしないと、バッチファイル内で カスタム URI 経由で渡ってきた引数文字列にそのまま `&` が這入ってしまうので、
    # `%~1` による引数展開時に `認識されていません。` となってしまう
}

# <引数チェック>
if ($DirInfo -eq $null) { # `-DirInfo` が指定されなかった場合
    [System.String]$DirInfo = $PSScriptRoot # この .ps1 ファイルが配置されたディレクトリを指定。文字列型。(`Get-ChildItem` のオプション `-Path` が文字列型である必要があるため)

} elseif ($DirInfo -is [System.IO.DirectoryInfo]) { # ディレクトリオブジェクトの指定の場合
    [System.String]$DirInfo = $DirInfo.FullName # パス文字列に変換 (`Get-ChildItem` のオプション `-Path` が文字列型である必要があるため)
}
if ($TimeDepth -eq $null){ # `-TimeDepth` が指定されなかった場合
    $TimeDepth = $Depth # `-Depth` と同じ値を使用
} else { # `-TimeDepth` が指定された場合
    $TimeDepth = [System.Int32]$TimeDepth # `System.Int32` 型にキャスト (バッチファイルでマイナス値を指定した場合は `System.String` 型となるため)
}
if ($FileOnly) { # 走査対象をファイルに限定している場合
    $str_FileOpt = " -File"
} else {
    $str_FileOpt = ""
}
if ($DirectoryOnly) { # 走査対象をファイルに限定している場合
    $str_DirOpt = " -Directory"
} else {
    $str_DirOpt = ""
}
if ($OutFilePath -eq $null) { # 出力する .html ファイルパスが指定されなかった場合
    # 'カレントディレクトリ'\whats-new.html
    $str_OutFilePath = (Get-Location).Path + '\whats-new.html'
} else { # 出力する .html ファイルパスが指定されている場合
    $str_tmp = Split-Path $OutFilePath
    if (-Not(Test-Path $str_tmp)) { # 指定パスの親ディレクトリが存在しない場合
        Write-Error "フォルダ `"$str_tmp`" が存在しません。"
        exit 1
        # Note:
        # `return` は使用しない。バッチファイルから call される想定のため。
        # `%errorlevel%` で取得可能な値しか返さない(`0` or `1` しか使えない仕様?)
        # `return` を使用するとコマンドプロンプトに値が表示されてしまう
    }
    $str_OutFilePath = (Resolve-Path $str_tmp).Path + '\' + (Split-Path $OutFilePath -Leaf)
}
# </引数チェック>

if ($Depth -lt 0) {
    [System.UInt32]$NumOfUpLevelOfHierarchy = $Depth * (-1)
    $DirInfo = Convert-Path ($DirInfo + ("\.." * $NumOfUpLevelOfHierarchy))
    # Note:
    # 存在しないパスが指定された場合は "Convert-Path : パス '(パス名)' が存在しないため検出できません。" でエラー終了する

    [System.UInt32]$uint32_ScanDepth = 0 # タイムスタンプを検査する階層の深さ

} else {
    [System.UInt32]$uint32_ScanDepth = $Depth # タイムスタンプを検査する階層の深さ
}

# 検索対象となる `System.IO.FileInfo` オブジェクトリストを作成
$str_GetChildItemCmdlet = "Get-ChildItem -Path `"$DirInfo`"$str_FileOpt$str_DirOpt -Recurse -Depth $uint32_ScanDepth -Force"

$obj_FofDInfos = Invoke-Expression $str_GetChildItemCmdlet | # `System.IO.FileInfo` オブジェクトリストを取得
    Sort-Object -Property FullName # フルパスの名称で sort

# 対象件数が 0 だった場合は終了
if ($obj_FofDInfos -eq $null){ # 対象件数が 0 だった場合
    Write-Error "パス `"$DirInfo`" が存在しないか、その配下に子項目が存在しません。"
    exit 1
}

$obj_PathInfo = New-Object System.Collections.ArrayList

[System.Management.Automation.PathInfo]$obj_Curdir = Get-Location # カレントディレクトリを一時保存
Set-Location $DirInfo # 相対パスを取得するためにカレントディレクトリを指定ディレクトリに移動

$int32_tmp = ($TimeDepth - $Depth - 1)
for ($int32_Idx = 0 ; $int32_Idx -lt $obj_FofDInfos.count ; $int32_Idx++){
    
    # Write-Host "($($int32_Idx + 1) of $($obj_FofDInfos.count)) $($obj_FofDInfos[$int32_Idx].FullName)"
    # Write-Host $obj_FofDInfos[$int32_Idx].GetType().FullName
    [System.String]$str_RelPath = Resolve-Path -Path $obj_FofDInfos[$int32_Idx].FullName -Relative # カレントディレクトリからの相対パスを取得
    $str_RelPath = $str_RelPath -replace "^\.\\","" # 先頭の `.\` を削除
    # Write-host $str_RelPath

    # https://learn.microsoft.com/ja-jp/dotnet/api/system.text.regularexpressions.regex.matches?view=net-8.0#system-text-regularexpressions-regex-matches(system-string-system-string)
    if (([regex]::Matches($str_RelPath, '\\')).Count -eq $uint32_ScanDepth){
        
        if ((-1) -ne $int32_tmp){ # `-TimeDepth` パラメータが指定されていた場合

            IF ($obj_FofDInfos[$int32_Idx].GetType() -eq [System.IO.DirectoryInfo]) { # ディレクトリの場合
                
                $str_FullName = $obj_FofDInfos[$int32_Idx].FullName
                if (0 -le $int32_tmp) {
                    $str_GetChildItemCmdlet = "Get-ChildItem -Path `"$str_FullName`"$str_FileOpt$str_DirOpt -Recurse -Depth $int32_tmp -Force"
                } else {
                    $str_GetChildItemCmdlet = "Get-ChildItem -Path `"$str_FullName`"$str_FileOpt$str_DirOpt -Recurse -Force"
                }
                $obj_FofDInfosForTime = Invoke-Expression $str_GetChildItemCmdlet | Sort-Object -Property LastWriteTime -Descending
                
                if ($obj_FofDInfosForTime -ne $null){ # 子項目が存在する場合

                    # 現在のディレクトリのタイムスタンプより小項目のタイムスタンプが新しい場合
                    if (0 -lt (New-TimeSpan -Start $obj_FofDInfos[$int32_Idx].LastWriteTime -End $obj_FofDInfosForTime[0].LastWriteTime).TotalMilliseconds) {
                        # Write-Host $obj_FofDInfos[$int32_Idx].Fullname + $obj_FofDInfosForTime[0].LastWriteTime
                        $obj_PathInfo.Add([PSCustomObject]@{
                            PathName = $obj_FofDInfos[$int32_Idx].Fullname
                            LastWriteTime = $obj_FofDInfosForTime[0].LastWriteTime
                            ChildPathName = $obj_FofDInfosForTime[0].Fullname
                        }) > $null

                    }else{ # 現在のディレクトリのタイムスタンプが小項目のタイムスタンプが新しい場合
                        # Write-Host $obj_FofDInfos[$int32_Idx].Fullname + $obj_FofDInfos[$int32_Idx].LastWriteTime
                        $obj_PathInfo.Add([PSCustomObject]@{
                            PathName = $obj_FofDInfos[$int32_Idx].Fullname
                            LastWriteTime = $obj_FofDInfos[$int32_Idx].LastWriteTime
                        }) > $null
                    }

                } else { # 小項目が存在しない場合
                    # Write-Host $obj_FofDInfos[$int32_Idx].Fullname + $obj_FofDInfos[$int32_Idx].LastWriteTime
                    $obj_PathInfo.Add([PSCustomObject]@{
                        PathName = $obj_FofDInfos[$int32_Idx].Fullname
                        LastWriteTime = $obj_FofDInfos[$int32_Idx].LastWriteTime
                    }) > $null
                }

            } else { # ファイルの場合
                # Write-Host $obj_FofDInfos[$int32_Idx].Fullname + $obj_FofDInfos[$int32_Idx].LastWriteTime
                $obj_PathInfo.Add([PSCustomObject]@{
                    PathName = $obj_FofDInfos[$int32_Idx].Fullname
                    LastWriteTime = $obj_FofDInfos[$int32_Idx].LastWriteTime
                }) > $null

            }

        } else { # `-TimeDepth` パラメータが指定されていない場合
            # Write-Host $obj_FofDInfos[$int32_Idx].Fullname + $obj_FofDInfos[$int32_Idx].LastWriteTime
            $obj_PathInfo.Add([PSCustomObject]@{
                PathName = $obj_FofDInfos[$int32_Idx].Fullname
                LastWriteTime = $obj_FofDInfos[$int32_Idx].LastWriteTime
            }) > $null
        }
    }

}

Set-Location $obj_Curdir # カレントディレクトリをもとに戻す (出力先ファイル StreamWriter のインスタンス生成失敗時のためにここで1度実行しておく)

$obj_SortedPathInfo = $obj_PathInfo | Sort-Object -Property LastWriteTime -Descending # 降順にソート

# 出力先ファイル StreamWriter を開く
try{
    $enc_obj = [Text.Encoding]::GetEncoding('utf-8')
    
    if ($enc_obj.CodePage -eq 65001){ # for utf-8 encoding with no BOM
        $outFileWriter = New-Object System.IO.StreamWriter($str_OutFilePath, $false)
        
    } else {
        $outFileWriter = New-Object System.IO.StreamWriter($str_OutFilePath, $false, $enc_obj)
    }
    
} catch { # 出力先ファイル StreamWriter を開けなかった場合
    Write-Error ("[error] " + $_.Exception.Message)
    try{
        $outFileWriter.Close()
    } catch {}
    exit 1
}

# HTML ヘッダの書き込み
$outFileWriter.WriteLine(@'
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="content-type" content="text/html; charset=utf-8">
        <title>Todo タイトル</title>
    </head>
    <body>
'@)

# <table> ヘッダの書き込み
$outFileWriter.WriteLine(@'
        <table border="1">
            <thead>
                <tr>
                    <th>パス</th><th>更新日時(降順)</th>
                </tr>
                </thead>
            <tbody>
'@)

# [DateTime.ToString()](https://learn.microsoft.com/ja-jp/dotnet/api/system.datetime.tostring?view=net-8.0#system-datetime-tostring(system-string-system-iformatprovider)) へ渡す
# `IFormatProvider` パラメータの生成
$str_CultureName = (Get-Culture).Name # OS の現在のカルチャ設定を取得
if ($str_CultureName -eq 'ja-JP') { # '日本' 設定の場合
    $obj_Culture = New-Object CultureInfo($str_CultureName)
    $obj_Culture.DateTimeFormat.Calendar = New-Object System.Globalization.JapaneseCalendar
    
} else { # OS の現在のカルチャ設定が '日本' 以外の場合
    $obj_Culture = $null
    
}

for ($int32_Idx = 0 ; $int32_Idx -lt $obj_SortedPathInfo.count ; $int32_Idx++){
    # Write-Host $obj_SortedPathInfo[$int32_Idx].PathName $obj_SortedPathInfo[$int32_Idx].LastWriteTime

    if ($obj_Culture -eq $null){ # OS の現在のカルチャ設定が '日本' 以外の場合
        $str_EraAndYY = ''
    } else {
        # 和暦を "(令和XX年)" のように設定
        $str_EraAndYY = '(' + $obj_SortedPathInfo[$int32_Idx].LastWriteTime.ToString("gyy年", $obj_Culture) + ')'
    }

    If ($obj_SortedPathInfo[$int32_Idx].ChildPathName -eq $null) { # 子要素から 'LastWriteTime' を取得した場合
        $str_CstmURIForChild = ''

    } else { # 子要素から 'LastWriteTime' を取得していない場合

        Set-Location $obj_SortedPathInfo[$int32_Idx].PathName # 相対パスを取得するためにカレントディレクトリを指定ディレクトリに移動
        # Write-Host $obj_SortedPathInfo[$int32_Idx].ChildPathName
        $str_RelPath = (Resolve-Path -Path $obj_SortedPathInfo[$int32_Idx].ChildPathName -Relative) -replace "^\.\\","" # 先頭の `.\` を削除
        $str_CstmURIForChild =
            ' ' +
            '<a href="kickexplorer:' +
            (func_PercentEncodeForSpecialChar($obj_SortedPathInfo[$int32_Idx].ChildPathName)) + # カスタム URI へ渡すパラメータ文字列
            '">(' +
            $str_RelPath + # ブラウザ表示用パス文字列
            ')</a>'
    }

    $outFileWriter.WriteLine(
        '                <tr><td><a href="kickexplorer:' +
        (func_PercentEncodeForSpecialChar($obj_SortedPathInfo[$int32_Idx].PathName)) + # カスタム URI へ渡すパラメータ文字列
        '">' +
        $obj_SortedPathInfo[$int32_Idx].PathName + # ブラウザ表示用パス文字列
        '</a></td><td><time datetime="' +
        $obj_SortedPathInfo[$int32_Idx].LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss.fff") + # `datetime` 属性値
        '">' +
        $obj_SortedPathInfo[$int32_Idx].LastWriteTime.ToString("yyyy年") + $str_EraAndYY + $obj_SortedPathInfo[$int32_Idx].LastWriteTime.ToString("MM月dd日(ddd)、HH:mm:ss.fff") + # ブラウザ表示日時
        '</time>' +
        $str_CstmURIForChild + 
        '</td><tr>'
    )
    # `datetime` 属性には [ローカル日時文字列](https://developer.mozilla.org/ja/docs/Web/HTML/Date_and_time_formats#%E3%83%AD%E3%83%BC%E3%82%AB%E3%83%AB%E6%97%A5%E6%99%82%E6%96%87%E5%AD%97%E5%88%97) を使用する
    # 書式指定文字列の意味は以下参照
    # https://learn.microsoft.com/ja-jp/dotnet/standard/base-types/custom-date-and-time-format-strings?WT.mc_id=WD-MVP-36880
}

Set-Location $obj_Curdir # カレントディレクトリをもとに戻す

# <table> 要素の終了
$outFileWriter.WriteLine(@'
            </tbody>
        </table>
'@)

# HTML の終了
$outFileWriter.WriteLine(@'
    </body>
</html>
'@)

# file close
$outFileWriter.Close()
