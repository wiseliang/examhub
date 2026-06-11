$sdkRoot = "D:\AndroidStudio\SDK"
$sdkManager = "$sdkRoot\cmdline-tools\latest\bin\sdkmanager.bat"
$cmdExe = "C:\Windows\System32\cmd.exe"

# Create yes-input file
Write-Host "Creating yes-input..."
$yesPath = "$env:TEMP\yes_input.txt"
"y`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny" | Out-File -FilePath $yesPath -Encoding ascii -NoNewline

Write-Host "Accepting licenses..."
& $cmdExe /c type $yesPath `| $sdkManager --sdk_root=$sdkRoot --licenses

Write-Host "Installing SDK components..."
& $cmdExe /c $sdkManager --sdk_root=$sdkRoot platforms`;android-34 build-tools`;34.0.0 platform-tools

Write-Host "Done!"
Remove-Item $yesPath -ErrorAction SilentlyContinue
