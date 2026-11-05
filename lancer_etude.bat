@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
title Etude du jeu par l'IA

set "GODOT="
for %%G in ("%~dp0Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" "%USERPROFILE%\zoodeck\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" "%USERPROFILE%\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe") do (
	if not defined GODOT if exist %%G set "GODOT=%%~G"
)
if not defined GODOT (
	echo Godot introuvable. Indiquez le chemin complet de Godot_v4.7.2-stable_win64_console.exe :
	set /p "GODOT=> "
)

echo.
echo ETUDE DU JEU PAR L'IA QUI APPREND
echo Des IA jouent entre elles, apprennent, et un rapport est ecrit dans rapport_etude.md.
echo Comptez environ 500 parties par heure sur le PC fixe (selon la puissance du PC).
echo Empechez le PC de se mettre en veille pendant l'etude. Fermer cette fenetre l'arrete :
echo le rapport est mis a jour au fil de l'etude, rien n'est perdu.
echo.
set "OPTS="
set "REPRENDRE=N"
if not exist etude_reprise.json goto nouvelle
echo Une etude precedente est enregistree (etude_reprise.json) : elle peut continuer
echo la ou elle s'est arretee, avec la meme population et les memes statistiques.
set /p "REPRENDRE=Reprendre l'etude precedente ? (O/N) [N] : "
if /i not "%REPRENDRE%"=="O" goto nouvelle
set "OPTS=--reprendre"
set "PARTIES=2000"
set /p "PARTIES=Combien de parties en plus ? [2000] : "
goto horaire
:nouvelle
echo Nouvelle etude : la precedente (si elle existe) sera remplacee.
set "PARTIES=1000"
set /p "PARTIES=Combien de parties ? [1000] : "
:horaire
set "FIN="
set /p "FIN=Heure de fin au plus tard, ex. 08:00 (vide : aucune) : "
set /a JOBS=%NUMBER_OF_PROCESSORS%-2
if %JOBS% LSS 1 set JOBS=1

"%GODOT%" --headless --path game --script res://tests/evolution.gd -- %OPTS% --total=%PARTIES% --jobs=%JOBS% --fin=%FIN%

echo.
echo Termine. Le rapport est dans rapport_etude.md, les trois niveaux d'IA dans game\data\ia_niveaux.json.
echo Pour continuer cette etude plus tard, relancez ce fichier et repondez O a la reprise.
if exist rapport_etude.md start "" rapport_etude.md
pause
