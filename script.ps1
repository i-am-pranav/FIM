
Write-Host ""
Write-Host "What would you like to do?"
Write-Host "A) Collect new Baseline?"
Write-Host "B) Begin monitoring files with saved Baseline?"
Write-Host ""


$response = Read-Host -Prompt "Please enter 'A' or 'B' "
Write-Host ""

Function CalculateFileHash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}
Function EraseBaselineIfAlreadyExist() {
    $baselineExists = Test-Path -Path .\baseline.txt
    if ($baselineExists) {
        #Delete It
        Remove-Item -Path .\baseline.txt
    }
}

if ($response -eq "A".ToUpper()) {
    # Delete baseline if already exists
    EraseBaselineIfAlreadyExist

    # Calculate hash from the target files and store in baseline.txt
    # Collect all the files in the target folder
    $files = Get-ChildItem -Path .\Files

    # For each file, calculate the hash, and write to baseline.txt
    foreach ($f in $files) {
        $hash = CalculateFileHash $f.Fullname 
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath.\baseline.txt -Append
    }
}              

elseif ($response -eq "B".ToUpper()) {
    $fileHashDictionary = @{}
    # Load file hash from baseline.txt and store them in a dictionary
    $filePathsAndHashes = Get-Content -Path .\baseline.txt
    foreach ($f in $filePathsAndHashes) {
        $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }

    # Begin (Continuously) monitoring files with saved baseline
    while ($true) {
        Start-sleep -Seconds 1

        $files = Get-ChildItem -Path .\Files

        foreach ($f in $files) {
            $hash = CalculateFileHash $f.Fullname 
            # "$($hash.Path) | $($hash.Hash)" | Out-File -FilePath.\baseline.txt -Append
            
            # Notify if a new file has been creted!
            if ($null -eq $fileHashDictionary[$hash.Path]) {
                # A new file has been created!
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
            }

            # Notify if a file has been changed!
            else {
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                    # The file has not changed
                }
                else {
                    #File has been compromised!, Notify the user
                    Write-Host "$($hash.Path) has been changed!!!" -ForegroundColor Red
                }
            }

        }

        foreach ($key in $fileHashDictionary.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {
                # One file in baseline files must have been deleted!! Notify the user!!
                Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Gray
            }
        }
    }
}