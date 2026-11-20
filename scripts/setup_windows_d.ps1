param([string]$DevelopmentRoot = 'D:\Development', [switch]$InstallAndroidSdk)
$ErrorActionPreference = 'Stop'
if ($DevelopmentRoot -notmatch '^D:\\') { throw 'Sesuai permintaan, gunakan lokasi pada drive D.' }
if (-not (Test-Path 'D:\')) { throw 'Drive D tidak ditemukan. Sambungkan/siapkan drive D terlebih dahulu.' }
$FlutterDirectory = Join-Path $DevelopmentRoot 'flutter'
$CacheDirectory = Join-Path $DevelopmentRoot 'cache'
$SdkDirectory = Join-Path $DevelopmentRoot 'Android\Sdk'
$EnvironmentValues = @{
    PUB_CACHE = (Join-Path $CacheDirectory 'pub')
    GRADLE_USER_HOME = (Join-Path $CacheDirectory 'gradle')
    ANDROID_HOME = $SdkDirectory
    ANDROID_SDK_ROOT = $SdkDirectory
    ANDROID_USER_HOME = (Join-Path $CacheDirectory 'android')
    ANDROID_AVD_HOME = (Join-Path $DevelopmentRoot 'Android\Avd')
    ANALYZER_STATE_LOCATION_OVERRIDE = (Join-Path $CacheDirectory 'analyzer')
    XDG_CONFIG_HOME = (Join-Path $CacheDirectory 'config')
    XDG_CACHE_HOME = $CacheDirectory
    FLUTTER_SUPPRESS_ANALYTICS = 'true'
}
New-Item -ItemType Directory -Path $DevelopmentRoot,$CacheDirectory,$SdkDirectory -Force | Out-Null
foreach ($Item in $EnvironmentValues.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($Item.Key, $Item.Value, 'User')
    Set-Item -Path "Env:$($Item.Key)" -Value $Item.Value
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git belum tersedia. Pasang Git lalu jalankan skrip ini kembali.' }
if (-not (Test-Path (Join-Path $FlutterDirectory 'bin\flutter.bat'))) {
    git clone --depth 1 --branch 3.50.1 https://github.com/flutter/flutter.git $FlutterDirectory
    if ($LASTEXITCODE -ne 0) { throw 'Unduhan Flutter gagal.' }
}
$PathAdditions = @((Join-Path $FlutterDirectory 'bin'),(Join-Path $SdkDirectory 'platform-tools'),(Join-Path $SdkDirectory 'cmdline-tools\latest\bin'))
$CurrentUserPath = [Environment]::GetEnvironmentVariable('Path','User')
foreach ($Directory in $PathAdditions) {
    if (($CurrentUserPath -split ';') -notcontains $Directory) { $CurrentUserPath = "$Directory;$CurrentUserPath" }
}
[Environment]::SetEnvironmentVariable('Path',$CurrentUserPath,'User')
$env:Path = ($PathAdditions -join ';') + ';' + $env:Path
& (Join-Path $FlutterDirectory 'bin\flutter.bat') --suppress-analytics --version
if ($LASTEXITCODE -ne 0) { throw 'Inisialisasi Flutter gagal.' }
if ($InstallAndroidSdk) {
    if (-not (Get-Command java -ErrorAction SilentlyContinue) -or -not (Get-Command javac -ErrorAction SilentlyContinue)) { throw 'JDK 21 belum tersedia. Pasang JDK 21 pada drive D, tambahkan bin ke PATH, lalu ulangi dengan -InstallAndroidSdk.' }
    $Manager = Join-Path $SdkDirectory 'cmdline-tools\latest\bin\sdkmanager.bat'
    if (-not (Test-Path $Manager)) {
        $Download = Join-Path $CacheDirectory 'android-commandline.zip'
        $Extract = Join-Path $CacheDirectory 'android-commandline'
        Invoke-WebRequest 'https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip' -OutFile $Download
        Expand-Archive $Download $Extract -Force
        New-Item -ItemType Directory -Path (Join-Path $SdkDirectory 'cmdline-tools') -Force | Out-Null
        Move-Item (Join-Path $Extract 'cmdline-tools') (Join-Path $SdkDirectory 'cmdline-tools\latest')
        Remove-Item $Download -Force
    }
    # SDK license terms are shown interactively for the computer owner to review.
    & $Manager "--sdk_root=$SdkDirectory" --licenses
    & $Manager "--sdk_root=$SdkDirectory" 'platform-tools' 'platforms;android-36' 'platforms;android-35' 'build-tools;36.0.0' 'ndk;28.2.13676358'
    if ($LASTEXITCODE -ne 0) { throw 'Instalasi Android SDK belum selesai.' }
}
& (Join-Path $FlutterDirectory 'bin\flutter.bat') --suppress-analytics config --android-sdk $SdkDirectory
Write-Host "Flutter: $FlutterDirectory"
Write-Host "Android SDK: $SdkDirectory"
Write-Host "Pub/Gradle cache: $CacheDirectory"
Write-Host 'Buka terminal baru, lalu jalankan flutter doctor. Project dapat diletakkan di D:\Projects\CPNSJourney.'
