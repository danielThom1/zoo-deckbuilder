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
echo.
echo A la fin, l'etude mesure trois niveaux d'IA (facile, moyen, difficile). Faut-il qu'ils remplacent ceux du jeu ?
echo   A = automatique : seulement si l'etude est au moins aussi poussee que celle qui a fait les IA actuelles
echo   O = oui, toujours        N = non, garder les IA actuelles (les nouvelles sont mises de cote)
set "IA=A"
set /p "IA=Remplacer les IA du jeu ? (A/O/N) [A] : "
set "MODE_IA=auto"
if /i "%IA%"=="O" set "MODE_IA=oui"
if /i "%IA%"=="N" set "MODE_IA=non"
set /a JOBS=%NUMBER_OF_PROCESSORS%-2
if %JOBS% LSS 1 set JOBS=1

"%GODOT%" --headless --path game --script res://tests/evolution.gd -- %OPTS% --total=%PARTIES% --jobs=%JOBS% --fin=%FIN% --ia=%MODE_IA%

echo.
echo Termine. Le rapport est dans rapport_etude.md. Les niveaux d'IA sont dans game\data\ia_niveaux.json s'ils ont
echo remplace les precedents, sinon dans ia_niveaux_candidat.json (le rapport dit lequel).
echo Pour continuer cette etude plus tard, relancez ce fichier et repondez O a la reprise.
if exist rapport_etude.md start "" rapport_etude.md
pause
