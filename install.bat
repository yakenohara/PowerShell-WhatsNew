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
:: ���̃t�@�C���͕����R�[�h `SJIS` �ŕۑ����邱��
:: </CAUTION!>

@echo off

:: �R�[�h�y�[�W (�����R�[�h) �� `SJIS` �ɐݒ�
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/chcp
:: https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
chcp 932 > nul
:: <NOTE>
::  - ���̃t�@�C���� `UTF-8` �ŕۑ����āA�t�@�C���`���� `chcp 65001` �����s���Ă���
::    `set STR_OUT_FILE_NAME=` �ɓ��{���ݒ肷��ƁA���s���G���[�ɂȂ��Ă��܂�
::  -  `> nul`
::    �o�͂�j��
::    https://learn.microsoft.com/ja-jp/troubleshoot/developer/visualstudio/cpp/language-compilers/redirecting-error-command-prompt
:: </NOTE>

:: �J�X�^�� URI �X�L�[����
set str_schemeName=kickexplorer

:: �C���X�g�[���t�H���_�[��
set str_folderNameToInstall=kickexplorer

:: �J�X�^�� URI �X�L�[���ŋN�������A�v����
set ste_appName=kickexplorer.bat

:: ���W�X�g���L�[�p�X
set str_regKeyPath="HKEY_CLASSES_ROOT\%str_schemeName%"

:: ���W�X�g���G���g���o�^��e�p�X
set str_regPath="HKEY_CLASSES_ROOT\%str_schemeName%\shell\open\command"

:: �t�H���_�[�I���_�C�A���O�� `�L�����Z��` ���ꂽ���ǂ����𔻒f���邽�߂̕]��������
set "str_canceled=ECHO �� <OFF> �ł��B"

:: Progress �\���p�ϐ���`
set /a int_totalSped=3
set /a int_progOfSpes=1

echo Installing...

:: �C���X�g�[����t�H���_�[�I���_�C�A���O
set "Title=�C���X�g�[����t�H���_�[��I�����Ă�������"
set dialog="about:<script language=vbscript>resizeTo 0,0:Sub window_onload():
set dialog=%dialog%Set Shell=CreateObject("Shell.Application"):
set dialog=%dialog%Set Env=CreateObject("WScript.Shell").Environment("Process"):
:: ���[�U�[���t�H���_�[��I�����A�I�������t�H���_�[�� Folder �I�u�W�F�N�g��Ԃ��_�C�A���O �{�b�N�X���쐬
:: https://learn.microsoft.com/ja-jp/windows/win32/shell/shell-browseforfolder
set dialog=%dialog%Set Folder=Shell.BrowseForFolder(0, Env("Title"), 1):
set dialog=%dialog%If Folder Is Nothing Then ret="" Else ret=Folder.Items.Item.Path End If:
set dialog=%dialog%CreateObject("Scripting.FileSystemObject").GetStandardStream(1).Write ret:
set dialog=%dialog%Close:End Sub</script><hta:application caption=no showintaskbar=no />"
set str_toInstallDir=
for /f "delims=" %%p in ('MSHTA.EXE %dialog%') do  set "str_toInstallDir=%%p"
:: Note `�L�����Z��` ���I�����ꂽ�� errorlevel �� 0 �ƂȂ�
:: ������ `ECHO �� <OFF> �ł��B` ���ǂ����ŃL�����Z�����ꂽ���ǂ����𔻒f����K�v������
if "%str_toInstallDir%"=="%str_canceled%" (
    echo �C���X�g�[�����L�����Z������܂����B
    pause
    exit /b 1
)
:: echo %str_toInstallDir%

:: �C���X�g�[����t�H���_�[�`�F�b�N
echo (%int_progOfSpes%of%int_totalSped%) Checking existence of specified folder ("%str_toInstallDir%\%str_folderNameToInstall%")
if not exist "%str_toInstallDir%" (
    echo �C���X�g�[�����s�B�I�������t�H���_�[�����݂��܂���B
    pause
    exit /b 1
)
if exist "%str_toInstallDir%\%str_folderNameToInstall%" (
    echo ���ł� %str_folderNameToInstall% ���C���X�g�[������Ă��܂��B
    pause
    exit /b 1
)

set /a int_progOfSpes=%int_progOfSpes%+1

:: ���W�X�g���o�^
echo (%int_progOfSpes%of%int_totalSped%) Adding registry key
reg add %str_regKeyPath% /t REG_SZ /v "URL Protocol" /f > nul 2>&1
if %errorlevel% neq 0 (
    echo �C���X�g�[�����s�B���W�X�g���ւ̃A�N�Z�X�����ۂ���܂����B�Ǘ��҂Ƃ��Ď��s���Ă��������B
    pause
    exit /b 1
)
reg add %str_regPath% /t REG_SZ /d "\"%str_toInstallDir%\%str_folderNameToInstall%\%ste_appName%\" \"%%1\"" /f > nul 2>&1
if %errorlevel% neq 0 (
    echo �C���X�g�[�����s�B���W�X�g���ւ̃A�N�Z�X�����ۂ���܂����B�Ǘ��҂Ƃ��Ď��s���Ă��������B
    pause
    exit /b 1
)

:: �t�@�C���̃C���X�g�[��
echo (%int_progOfSpes%of%int_totalSped%) Installing files
xcopy "%~dp0\%str_folderNameToInstall%" "%str_toInstallDir%\%str_folderNameToInstall%\" /e /q > nul 2>&1
if %errorlevel% neq 0 (
    echo �C���X�g�[�����s�B"%str_toInstallDir%\%str_folderNameToInstall%\"�ւ̃A�N�Z�X�����ۂ���܂����B�Ǘ��҂Ƃ��Ď��s���Ă��������B
    pause
    exit /b 1
)

set /a int_progOfSpes=%int_progOfSpes%+1

echo �C���X�g�[�����������܂����B
pause
