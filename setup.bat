@echo off
echo ========================================
echo   SETUP - AI Stock App
echo ========================================
echo.

set CONDA_PATH=

if exist "%USERPROFILE%\anaconda3\Scripts\activate.bat" set CONDA_PATH=%USERPROFILE%\anaconda3
if exist "%USERPROFILE%\miniconda3\Scripts\activate.bat" set CONDA_PATH=%USERPROFILE%\miniconda3
if exist "C:\ProgramData\anaconda3\Scripts\activate.bat" set CONDA_PATH=C:\ProgramData\anaconda3
if exist "C:\ProgramData\miniconda3\Scripts\activate.bat" set CONDA_PATH=C:\ProgramData\miniconda3
if exist "D:\anaconda3\Scripts\activate.bat" set CONDA_PATH=D:\anaconda3
if exist "D:\Download\anaconda3\Scripts\activate.bat" set CONDA_PATH=D:\Download\anaconda3

if "%CONDA_PATH%"=="" (
    echo ERREUR : Anaconda introuvable automatiquement.
    echo.
    echo Ouvre ce fichier avec Notepad et remplace CONDA_PATH
    echo par le chemin de ton Anaconda.
    echo Ex: set CONDA_PATH=C:\Users\TonNom\anaconda3
    echo.
    pause
    exit /b 1
)

echo Anaconda trouve : %CONDA_PATH%
call "%CONDA_PATH%\Scripts\activate.bat" "%CONDA_PATH%"

conda env list | find "vision" >nul 2>&1
if %errorlevel% == 0 (
    echo Environnement vision existe deja, mise a jour...
    call conda env update -f environment.yml --prune
) else (
    echo Creation de l'environnement vision...
    call conda env create -f environment.yml
)

echo.
echo Setup termine ! Lance start_camera.bat pour demarrer.
pause