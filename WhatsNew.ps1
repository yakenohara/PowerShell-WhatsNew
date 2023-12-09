# <CAUTION!>
# このファイルは UTF-8 (BOM 付き) で保存すること。(ターミナルに日本語メッセージを表示するため)
# </CAUTION!>

# PowerShell ターミナルで `.\WhatsNew.ps1 -DirInfo ([System.IO.DirectoryInfo]::new("D:\yakenohara\PowerShell-WhatsNew\assets"))` でも実行できる

<#
    .SYNOPSIS
    //todo 関数またはスクリプトの簡単な説明
    
    .PARAMETER DirInfo
    走査対象ディレクトリ
#>
# Note:
# '.PARAMETER <パラメーター名>' で使用する "<パラメーター名>" は、アッパーキャメルケースを使用しないと `Get-Help <スクリプトファイル> -full` 実行時にうまく認識されないらしい
# https://learn.microsoft.com/ja-jp/previous-versions/windows/powershell-scripting/hh847834(v=wps.640)?redirectedfrom=MSDN#parameter-%E3%83%91%E3%83%A9%E3%83%A1%E3%83%BC%E3%82%BF%E3%83%BC%E5%90%8D

Param(
    $DirInfo
)


if ($DirInfo -eq $null) { # 指定されなかった場合
    Write-Error
    exit 1
    # Note:
    # `return` は使用しない。バッチファイルから call される想定のため。
    # `%errorlevel%` で取得可能な値しか返さない(`0` or `1` しか使えない仕様?)
    # `return` を使用するとコマンドプロンプトに値が表示されてしまう

} elseif ($DirInfo -is [System.String]){ # 文字列の場合
    # Note: `.GetType().FullName -eq "System.String"` でも判定できるが、将来 `.FullName` で取得できる名前が変わっても通用するように、 ` -is [(データ型)]` で比較する

    # Nothing todo

} elseif ($DirInfo -is [System.IO.DirectoryInfo]) { # ディレクトリオブジェクトの指定の場合
    $DirInfo = $DirInfo.FullName # パス文字列に変換 (`Get-ChildItem` のオプション `-Path` が文字列型である必要があるため)

} else {
    Write-Error
    return 1
}

# 検索対象となる `System.IO.FileInfo` オブジェクトリストを作成
$obj_finfos = 
    Get-ChildItem -Path $DirInfo -Recurse | # `System.IO.FileInfo` オブジェクトリストを取得
    Sort-Object -Property FullName # フルパスの名称で sort

# 対象件数が 0 だった場合は終了
if ($obj_finfos -eq $null){ # 対象件数が 0 だった場合
    Write-Error "パス `"$DirInfo`" 内に子項目が存在しません。"
    return
}

for ($int_idx = 0 ; $int_idx -lt $obj_finfos.count ; $int_idx++){
    
    Write-Host "($($int_idx + 1) of $($obj_finfos.count)) $($obj_finfos[$int_idx].FullName)"
    Write-Host $obj_finfos[$int_idx].GetType().FullName

}
