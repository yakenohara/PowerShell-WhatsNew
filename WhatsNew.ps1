# 引数を変数に格納
Param(
	[String]$arg0,
	[Int]$arg1
)

# 引数１の内容を表示
Write-Host $arg0
# 引数２の内容を表示
Write-Host $arg1

# 検索対象となる `System.IO.FileInfo` オブジェクトリストを作成
$obj_finfos = 
    Get-ChildItem -Path $arg0 -Recurse | # `System.IO.FileInfo` オブジェクトリストを取得
    Sort-Object -Property FullName # フルパスの名称で sort

# 対象件数が 0 だった場合は終了
if ($obj_finfos -eq $null){ # 対象件数が 0 だった場合
    Write-Error "パス `"$arg0`" 内に子項目が存在しません。"
    return
}

for ($int_idx = 0 ; $int_idx -lt $obj_finfos.count ; $int_idx++){
    
    Write-Host "($($int_idx + 1) of $($obj_finfos.count)) $($obj_finfos[$int_idx].FullName)"
    
    

}
