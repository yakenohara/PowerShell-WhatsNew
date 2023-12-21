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
:: ���W�X�g���G���g���� '���O' �� `(�K��)` �̏ꍇ���ǂ����𔻒f���邽�߁B
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

:: �J�X�^�� URI �X�L�[���ŋN�������A�v����
set ste_appName=kickexplorer.bat

:: ���W�X�g���G���g���� '���O'
set str_entryName=(����)

:: ���W�X�g���L�[�p�X
set str_regKeyPath="HKEY_CLASSES_ROOT\%str_schemeName%"

:: ���W�X�g���G���g���o�^��e�p�X
set str_regPath="HKEY_CLASSES_ROOT\%str_schemeName%\shell\open\command"

:: Progress �\���p�ϐ���`
set /a int_totalSped=3
set /a int_progOfSpes=1

echo Uninstalling...

:: �C���X�g�[����f�B���N�g�����̎擾
echo (%int_progOfSpes%of%int_totalSped%) Searching for installed folder
:: ���W�X�g���G���g���̈ꗗ���擾 (�l�̖��O����̃N�G�������s)
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/reg-query
reg query %str_regPath% /ve > nul 2>&1
:: "�G���[: �w�肳�ꂽ���W�X�g�� �L�[�܂��͒l��������܂���ł���" �̏ꍇ
if %errorlevel% neq 0 (
    echo �A���C���X�g�[�����s�B���W�X�g���ւ̃A�N�Z�X�����ۂ��ꂽ���A���łɃA���C���X�g�[���ς݂ł��B�A�N�Z�X����^����ɂ́A�Ǘ��҂Ƃ��Ď��s���Ă��������B
    pause
    exit /b 1
)
:: ���W�X�g���G���g���̈ꗗ���擾���� '���O' �� `(�K��)` �̏ꍇ�� '�f�[�^' �𕶎���Ƃ��Ď擾
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/reg-query
:: `reg query ~` ���ʂɑ΂��ă��[�v
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/for
for /f "TOKENS=1,2,*" %%A in ('reg query %str_regPath% /ve') DO (
    IF "%%A"=="(����)" (
        SET str_dataOfEntry=%%C
        goto queryend
    )
)
:queryend
:: ������ `" "%1"` ���폜
set str_dirInstalled=%str_dataOfEntry:" "%1"=%
:: �擪�� `"` ���폜
set str_dirInstalled=%str_dirInstalled:"=%
:: ������ `\kickexplorer.bat` ���폜
@REM set str_dirInstalled=%str_dirInstalled:\%ste_appName%=%
call set str_dirInstalled=%%str_dirInstalled:\kickexplorer.bat=%%
::echo %str_dirInstalled%

set /a int_progOfSpes=%int_progOfSpes%+1

:: ���W�X�g���L�[�̍폜
echo (%int_progOfSpes%of%int_totalSped%) Removing registry key
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/reg-delete
reg delete %str_regKeyPath% /f > nul 2>&1
:: "�G���[: �w�肳�ꂽ���W�X�g�� �L�[�܂��͒l��������܂���ł���" �̏ꍇ
if %errorlevel% neq 0 (
    echo �A���C���X�g�[�����s�B���W�X�g���ւ̃A�N�Z�X�����ۂ���܂����B�Ǘ��҂Ƃ��Ď��s���Ă��������B
    pause
    exit /b 1
)

set /a int_progOfSpes=%int_progOfSpes%+1

:: �C���X�g�[���f�B���N�g���̍폜
echo (%int_progOfSpes%of%int_totalSped%) Uninstalling files
:: https://learn.microsoft.com/ja-jp/windows-server/administration/windows-commands/rmdir
rmdir /s /q "%str_dirInstalled%" > nul 2>&1
:: Note
:: �폜�Ɏ��s���Ă� `%errorlevel%` �� `0` �ȊO�ɂȂ�Ȃ��H Windows �̎d�l�H�H
:: �폜�Ɏ��s�������ǂ����͍폜�����͂��̃f�B���N�g�����ˑR���݂��邩�ǂ����Ŕ��f����
if exist "%str_dirInstalled%" (
    echo �A���C���X�g�[�����s�B�C���X�g�[����t�H���_�[ ^("%str_dirInstalled%"^) ���폜�ł��܂���B�t�H���_�[�����̃v���Z�X�ɒ͂܂�Ă���\��������܂��B�蓮�ō폜���Ă��������B
    explorer.exe /e,/select,"%str_dirInstalled%"
    pause
    exit /b 1
)

echo �A���C���X�g�[�����������܂����B

pause
