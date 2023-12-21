::<License>------------------------------------------------------------
::
:: Copyright (c) 2023 Shinnosuke Yakenohara
::
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
::
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
::
:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see <http://www.gnu.org/licenses/>.
::
::-----------------------------------------------------------</License>

:: <CAUTION!>
:: このファイルは文字コード `SJIS` で保存すること
:: レジストリエントリの '名前' が `(規定)` の場合かどうかを判断するため。
:: </CAUTION!>

@echo off

:: コードページ (文字コード) を `SJIS` に設定
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/chcp
:: https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
chcp 932 > nul
:: <NOTE>
::  - このファイルを `UTF-8` で保存して、ファイル冒頭で `chcp 65001` を実行してから
::    `set STR_OUT_FILE_NAME=` に日本語を設定すると、実行時エラーになってしまう
::  -  `> nul`
::    出力を破棄
::    https://learn.microsoft.com/ja-jp/troubleshoot/developer/visualstudio/cpp/language-compilers/redirecting-error-command-prompt
:: </NOTE>

:: カスタム URI スキーム名
set str_schemeName=kickexplorer

:: カスタム URI スキームで起動されるアプリ名
set ste_appName=kickexplorer.bat

:: レジストリエントリの '名前'
set str_entryName=(既定)

:: レジストリキーパス
set str_regKeyPath="HKEY_CLASSES_ROOT\%str_schemeName%"

:: レジストリエントリ登録先親パス
set str_regPath="HKEY_CLASSES_ROOT\%str_schemeName%\shell\open\command"

:: Progress 表示用変数定義
set /a int_totalSped=3
set /a int_progOfSpes=1

echo Uninstalling...

:: インストール先ディレクトリ名の取得
echo (%int_progOfSpes%of%int_totalSped%) Searching for installed folder
:: レジストリエントリの一覧を取得 (値の名前が空のクエリを実行)
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/reg-query
reg query %str_regPath% /ve > nul 2>&1
:: "エラー: 指定されたレジストリ キーまたは値が見つかりませんでした" の場合
if %errorlevel% neq 0 (
    echo アンインストール失敗。レジストリへのアクセスが拒否されたか、すでにアンインストール済みです。アクセス権を与えるには、管理者として実行してください。
    pause
    exit /b 1
)
:: レジストリエントリの一覧を取得して '名前' が `(規定)` の場合の 'データ' を文字列として取得
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/reg-query
:: `reg query ~` 結果に対してループ
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/for
for /f "TOKENS=1,2,*" %%A in ('reg query %str_regPath% /ve') DO (
    IF "%%A"=="(既定)" (
        SET str_dataOfEntry=%%C
        goto queryend
    )
)
:queryend
:: 末尾の `" "%1"` を削除
set str_dirInstalled=%str_dataOfEntry:" "%1"=%
:: 先頭の `"` を削除
set str_dirInstalled=%str_dirInstalled:"=%
:: 末尾の `\kickexplorer.bat` を削除
@REM set str_dirInstalled=%str_dirInstalled:\%ste_appName%=%
call set str_dirInstalled=%%str_dirInstalled:\kickexplorer.bat=%%
::echo %str_dirInstalled%

set /a int_progOfSpes=%int_progOfSpes%+1

:: レジストリキーの削除
echo (%int_progOfSpes%of%int_totalSped%) Removing registry key
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/reg-delete
reg delete %str_regKeyPath% /f > nul 2>&1
:: "エラー: 指定されたレジストリ キーまたは値が見つかりませんでした" の場合
if %errorlevel% neq 0 (
    echo アンインストール失敗。レジストリへのアクセスが拒否されました。管理者として実行してください。
    pause
    exit /b 1
)

set /a int_progOfSpes=%int_progOfSpes%+1

:: インストールディレクトリの削除
echo (%int_progOfSpes%of%int_totalSped%) Uninstalling files
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/rmdir
rmdir /s /q "%str_dirInstalled%" > nul 2>&1
:: Note
:: 削除に失敗しても `%errorlevel%` が `0` 以外にならない？ Windows の仕様？？
:: 削除に失敗したかどうかは削除したはずのディレクトリが依然存在するかどうかで判断する
if exist "%str_dirInstalled%" (
    echo アンインストール失敗。インストール先フォルダー ^("%str_dirInstalled%"^) が削除できません。フォルダーが他のプロセスに掴まれている可能性があります。手動で削除してください。
    explorer.exe /e,/select,"%str_dirInstalled%"
    pause
    exit /b 1
)

echo アンインストールが完了しました。

pause
