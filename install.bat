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

:: インストールフォルダー名
set str_folderNameToInstall=kickexplorer

:: カスタム URI スキームで起動されるアプリ名
set ste_appName=kickexplorer.bat

:: レジストリキーパス
set str_regKeyPath="HKEY_CLASSES_ROOT\%str_schemeName%"

:: レジストリエントリ登録先親パス
set str_regPath="HKEY_CLASSES_ROOT\%str_schemeName%\shell\open\command"

:: フォルダー選択ダイアログで `キャンセル` されたかどうかを判断するための評価文字列
set "str_canceled=ECHO は <OFF> です。"

:: Progress 表示用変数定義
set /a int_totalSped=3
set /a int_progOfSpes=1

echo Installing...

:: インストール先フォルダー選択ダイアログ
set "Title=インストール先フォルダーを選択してください"
set dialog="about:<script language=vbscript>resizeTo 0,0:Sub window_onload():
set dialog=%dialog%Set Shell=CreateObject("Shell.Application"):
set dialog=%dialog%Set Env=CreateObject("WScript.Shell").Environment("Process"):
:: ユーザーがフォルダーを選択し、選択したフォルダーの Folder オブジェクトを返すダイアログ ボックスを作成
:: https://learn.microsoft.com/ja-jp/windows/win32/shell/shell-browseforfolder
set dialog=%dialog%Set Folder=Shell.BrowseForFolder(0, Env("Title"), 1):
set dialog=%dialog%If Folder Is Nothing Then ret="" Else ret=Folder.Items.Item.Path End If:
set dialog=%dialog%CreateObject("Scripting.FileSystemObject").GetStandardStream(1).Write ret:
set dialog=%dialog%Close:End Sub</script><hta:application caption=no showintaskbar=no />"
set str_toInstallDir=
for /f "delims=" %%p in ('MSHTA.EXE %dialog%') do  set "str_toInstallDir=%%p"
:: Note `キャンセル` が選択されたも errorlevel は 0 となる
:: 文字列が `ECHO は <OFF> です。` かどうかでキャンセルされたかどうかを判断する必要がある
if "%str_toInstallDir%"=="%str_canceled%" (
    echo インストールがキャンセルされました。
    pause
    exit /b 1
)
:: echo %str_toInstallDir%

:: インストール先フォルダーチェック
echo (%int_progOfSpes%of%int_totalSped%) Checking existence of specified folder ("%str_toInstallDir%\%str_folderNameToInstall%")
if not exist "%str_toInstallDir%" (
    echo インストール失敗。選択したフォルダーが存在しません。
    pause
    exit /b 1
)
if exist "%str_toInstallDir%\%str_folderNameToInstall%" (
    echo すでに %str_folderNameToInstall% がインストールされています。
    pause
    exit /b 1
)

set /a int_progOfSpes=%int_progOfSpes%+1

:: レジストリ登録
echo (%int_progOfSpes%of%int_totalSped%) Adding registry key
reg add %str_regKeyPath% /t REG_SZ /v "URL Protocol" /f > nul 2>&1
if %errorlevel% neq 0 (
    echo インストール失敗。レジストリへのアクセスが拒否されました。管理者として実行してください。
    pause
    exit /b 1
)
reg add %str_regPath% /t REG_SZ /d "\"%str_toInstallDir%\%str_folderNameToInstall%\%ste_appName%\" \"%%1\"" /f > nul 2>&1
if %errorlevel% neq 0 (
    echo インストール失敗。レジストリへのアクセスが拒否されました。管理者として実行してください。
    pause
    exit /b 1
)

:: ファイルのインストール
echo (%int_progOfSpes%of%int_totalSped%) Installing files
xcopy "%~dp0\%str_folderNameToInstall%" "%str_toInstallDir%\%str_folderNameToInstall%\" /e /q > nul 2>&1
if %errorlevel% neq 0 (
    echo インストール失敗。"%str_toInstallDir%\%str_folderNameToInstall%\"へのアクセスが拒否されました。管理者として実行してください。
    pause
    exit /b 1
)

set /a int_progOfSpes=%int_progOfSpes%+1

echo インストールが完了しました。
pause
