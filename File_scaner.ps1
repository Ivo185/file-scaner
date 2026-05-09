# Избор на директории за сканиране (може една или няколко, разделени със запетая)
$inputPath = Read-Host "Въведи пътя или пътищата до папката/папките: "

# Превръщаме текста в масив от пътища и изчистваме излишните интервали
$sourcePaths = $inputPath.Split(',').Trim()

# Проверка дали всички въведени пътища съществуват
foreach ($path in $sourcePaths) {
    if (-not (Test-Path $path)) { 
        Write-Error "Папката '$path' не съществува!"; 
        exit 
    }
}

# Избор на сортиране
Write-Host "Как да бъдат подредени годините?"
Write-Host "1 - От най-старите към най-новите (Възходящо)"
Write-Host "2 - От най-новите към най-старите (Низходящо)"
$sortChoice = Read-Host "Избор (1/2)"

# Речник за имената на месеците на български
$monthsBG = @{1="Януари";2="Февруари";3="Март";4="Април";5="Май";6="Юни";7="Юли";8="Август";9="Септември";10="Октомври";11="Ноември";12="Декември"}

Write-Host "`nСканиране... Моля, изчакай.`n" -ForegroundColor Cyan

# Вземане на всички файлове (променено за работа с масив от пътища)
$files = Get-ChildItem -Path $sourcePaths -File -Recurse -Attributes !Hidden,!System -ErrorAction SilentlyContinue

if ($files.Count -eq 0) {
    Write-Host "Не бяха намерени файлове в избраната директория." -ForegroundColor Yellow
    exit
}

# ГРУПИРАНЕ: първо по година, после по месец
$report = $files | Group-Object { $_.LastWriteTime.Year } | ForEach-Object {
    $year = $_.Name
    $monthsInYear = $_.Group | Group-Object { $_.LastWriteTime.Month } | ForEach-Object {
        [PSCustomObject]@{
            MonthNum  = [int]$_.Name
            MonthName = $monthsBG[[int]$_.Name]
            Count     = $_.Count
        }
    }
    
    # Сортиране на месеците винаги от 1 до 12 в рамките на годината
    $monthsSorted = $monthsInYear | Sort-Object MonthNum

    [PSCustomObject]@{
        Year   = [int]$year
        Months = $monthsSorted
    }
}

# Сортиране на годините според избора на потребителя
if ($sortChoice -eq "2") {
    $report = $report | Sort-Object Year -Descending
} else {
    $report = $report | Sort-Object Year
}

# ПРИНТИРАНЕ НА ОТЧЕТА
Write-Host "Разпределение:" -ForegroundColor White
foreach ($yearEntry in $report) {
    Write-Host "     $($yearEntry.Year) г." -ForegroundColor Yellow
    foreach ($monthEntry in $yearEntry.Months) {
        Write-Host "          $($monthEntry.MonthName)" -ForegroundColor White
        Write-Host "               $($monthEntry.Count) файла" -ForegroundColor Gray
    }
}

Write-Host "--------------------------------------"
Write-Host "Общ брой намерени файлове: $($files.Count)" -ForegroundColor Green
Write-Host "--------------------------------------"

pause