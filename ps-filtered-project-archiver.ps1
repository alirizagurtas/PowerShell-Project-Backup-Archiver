<#
.SYNOPSIS
Birden fazla kaynak klas�r�ndeki dosyalar� ve alt klas�rleri, belirtilen klas�rleri ve dosya uzant�lar�n� hari� tutarak ZIP ar�ivleri olu�turur.
Her kaynak klas�r i�in, hedef klas�r alt�nda tarih damgal� ayr� bir ZIP dosyas� olu�turulur.

.DESCRIPTION
Script, SourceRoots olarak belirtilen her bir klas�r� ayr� ayr� i�ler.
Her kaynak klas�r�n i�eri�i (dosya ve alt klas�rler), �nce belirtilen klas�rler ve dosya uzant�lar� hari� tutularak ge�ici bir klas�re kopyalan�r.
Daha sonra bu ge�ici klas�r�n i�eri�i, DestinationRoot alt�nda kaynak klas�r�n ad� ve g�ncel tarih/saat ile isimlendirilmi� bir ZIP dosyas�na s�k��t�r�l�r.
S�k��t�rma tamamland�ktan sonra ge�ici klas�r silinir.

.PARAMETER SourceRoots
Yedeklenecek ana klas�rlerin yollar�n� i�eren bir string dizisi.
Her bir eleman, ba��ms�z olarak yedeklenecek bir klas�r� temsil eder.
�rn: @("C:\Users\KullaniciAdi\Documents\ProjeA", "D:\Development\ProjeB")

.PARAMETER DestinationRoot
Olu�turulan ZIP ar�ivlerinin kaydedilece�i hedef klas�r�n yolu.
Bu klas�r genellikle Google Drive veya benzeri bir senkronizasyon arac�n�n
takip etti�i bir klas�r i�inde olmal�d�r.
�rn: "C:\Users\KullaniciAdi\Drive'�m\ProjelerYedegiArsiv"

.PARAMETER ExcludeFolders
Yedekleme s�ras�nda hari� tutulacak klas�r isimlerini i�eren bir string dizisi.
Bu isimler b�y�k/k���k harfe duyarl� de�ildir. Bu klas�rler, SourceRoots alt�ndaki
herhangi bir seviyede bulundu�unda kopyalanmayacakt�r.
�rn: @("node_modules", ".venv", "build", "__pycache__", ".git")

.PARAMETER ExcludeFileExtensions
Yedekleme s�ras�nda hari� tutulacak dosya uzant�lar�n� i�eren bir string dizisi.
Uzant�lar nokta (.) ile ba�lamal�d�r. B�y�k/k���k harfe duyarl� de�ildir.
Bu uzant�lara sahip dosyalar kopyalanmayacakt�r.
�rn: @(".log", ".tmp", ".bak", ".cache")

.EXAMPLE
.\Backup-ToZipArchives.ps1
Bu, scriptin i�inde tan�mlanan varsay�lan SourceRoots, DestinationRoot, ExcludeFolders
ve ExcludeFileExtensions de�erlerini kullanarak yedeklemeyi ba�lat�r ve ZIP dosyalar� olu�turur.

.EXAMPLE
.\Backup-ToZipArchives.ps1 -SourceRoots @("C:\MyCode\Proj1", "D:\OldProjects\ProjX") -DestinationRoot "E:\GDriveBackup\Archives" -ExcludeFolders @("vendor") -ExcludeFileExtensions @(".log")
Belirtilen iki klas�r�, farkl� hari� tutmalarla ZIP ar�ivlerine yedekler.

.NOTES
Script, kopyalama ve s�k��t�rma s�ras�nda hatalar� yakalamaya �al���r.
Klas�r ve dosya uzant�s� isimleri case-insensitive olarak kar��la�t�r�l�r.
S�k��t�rma i�lemi ge�ici bir klas�r kullan�r, bu da ek disk alan� gerektirebilir
(ge�ici olarak yedeklenecek verinin ham boyutu kadar).
Ge�ici klas�r i�lem sonras� otomatik olarak silinir.
ZIP dosya isimleri YYYY-MM-DD_HH-mm-ss format�nda tarih/saat bilgisi i�erir.
#>
param(
    [string[]]$SourceRoots = @(
        "C:\Yol\To\Your\Project1",   # <-- Yedeklenecek 1. proje klas�r�
        "D:\Another\ProjectFolder"   # <-- Yedeklenecek 2. proje klas�r�
        # Virg�lle ay�rarak istedi�iniz kadar klas�r ekleyebilirsiniz
    ),
    [string]$DestinationRoot = "C:\Users\KullaniciAdi\GoogleDriveKlasorunuz\ProjectBackups",  # <-- ZIP dosyalar�n�n kaydedilece�i klas�r
    [string[]]$ExcludeFolders = @(
        "node_modules", # JavaScript/Node.js ba��ml�l�klar�
        ".venv",        # Python Sanal Ortam (venv)
        "venv",         # Python Sanal Ortam (venv)
        "env",          # Python Sanal Ortam (yayg�n isimler)
        ".git",         # Git versiyon kontrol klas�r� (yedeklemeye genellikle gerek yok)
        "dist",         # Build ��kt�lar� (�rn: webpack, parcel)
        "build",        # Build ��kt�lar� (�rn: make, setup.py)
        "__pycache__",  # Python cache dosyalar�
        ".vscode",      # VS Code ayar klas�rleri (iste�e ba�l�, dahil etmek isterseniz silin)
        ".idea",        # JetBrains IDE ayar klas�rleri (iste�e ba�l�)
        "bin",          # Derlenmi� ��kt�lar (�rn: .NET, Java)
        "obj",          # Derleme ara dosyalar� (.NET)
        "target",       # Build ��kt�lar� (�rn: Rust, Maven)
        "Vendor",       # Composer ba��ml�l�klar� (PHP)
        "tmp",          # Ge�ici dosyalar
        "temp"          # Ge�ici dosyalar
    ),
    [string[]]$ExcludeFileExtensions = @(
        ".log",    # Log dosyalar�
        ".tmp",    # Ge�ici dosyalar
        ".temp",   # Ge�ici dosyalar
        ".bak",    # Yedek dosyalar (genellikle)
        ".swp",    # Swap dosyalar� (Vim gibi edit�rler)
        ".swo",    # Swap dosyalar� (Vim gibi edit�rler)
        ".cache",  # Cache dosyalar�
        ".pyc",    # Python compiled files (__pycache__ zaten hari� tutuluyor ama ek g�venlik)
        ".class",  # Java compiled files
        ".obj",    # Object files (C++, C# derleme ara)
        ".exe",    # �al��t�r�labilir dosyalar (iste�e ba�l�)
        ".dll",    # K�t�phane dosyalar� (iste�e ba�l�)
        ".pdb"     # Debugging dosyalar� (iste�e ba�l�)
    )
)

# Hari� tutulacak klas�r ve dosya uzant�s� isimlerini k���k harfe �evir (case-insensitive kar��la�t�rma i�in)
$ExcludeFoldersLower = $ExcludeFolders | ForEach-Object {$_.ToLower()}
$ExcludeFileExtensionsLower = $ExcludeFileExtensions | ForEach-Object {$_.ToLower()}

# --- Recursive Filtered Copy Function ---
# Bu fonksiyon, klas�rleri �zyinelemeli olarak kopyalar ve belirtilenleri hari� tutar.
# ZIP olu�turmak i�in ge�ici bir dizine kopyalama amac�yla kullan�l�r.
function Copy-FilteredContentRecursive {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [string[]]$ExcludeFoldersLower,
        [string[]]$ExcludeFileExtensionsLower
    )

    # Write-Host "Processing: $($SourcePath)" -ForegroundColor DarkGray # �ok fazla ��kt� olabilir

    # Hedef klas�r� olu�tur (varsa zaten var olacakt�r)
    if (-not (Test-Path $DestinationPath -PathType Container)) {
        try {
            # Write-Host "Creating directory: $($DestinationPath)" -ForegroundColor Green # �ok fazla ��kt� olabilir
            New-Item -Path $DestinationPath -ItemType Directory | Out-Null
        } catch {
            Write-Host "Error creating directory $($DestinationPath): $($_.Exception.Message)" -ForegroundColor Red
            return # Bu yolda devam etme
        }
    }

    # Kaynak klas�rdeki ��eleri (dosya ve klas�rler) al
    $items = Get-ChildItem -Path $SourcePath -Force -ErrorAction SilentlyContinue

    foreach ($item in $items) {
        $sourceItemPath = $item.FullName
        $destinationItemPath = Join-Path -Path $DestinationPath -ChildPath $item.Name

        if ($item.PSIsContainer) {
            # ��renin ad� hari� tutulanlar listesinde mi kontrol et (k���k harf kar��la�t�rma)
            if ($ExcludeFoldersLower -contains $item.Name.ToLower()) {
                Write-Host "Skipping excluded folder: $($sourceItemPath)" -ForegroundColor Yellow
            } else {
                # Hari� tutulmayan bir klas�r - �zyinelemeli olarak kopyalamaya devam et
                Copy-FilteredContentRecursive -SourcePath $sourceItemPath -DestinationPath $destinationItemPath -ExcludeFoldersLower $ExcludeFoldersLower -ExcludeFileExtensionsLower $ExcludeFileExtensionsLower
            }
        } else {
            # ��ren bir dosya

            # Dosya uzant�s� hari� tutulanlar listesinde mi kontrol et (k���k harf kar��la�t�rma)
            $fileExtensionLower = $item.Extension.ToLower()
            if ($ExcludeFileExtensionsLower -contains $fileExtensionLower) {
                 # Write-Host "Skipping excluded file extension: $($sourceItemPath)" -ForegroundColor Yellow # �ok fazla ��kt� olabilir
                 continue # D�ng�de bir sonraki ��eye ge�, bu dosyay� kopyalama
            }

            # Dosya uzant�s� hari� tutulanlar listesinde de�il, kopyalamaya devam et
            try {
                # Write-Host "Copying file: $($sourceItemPath)" -ForegroundColor Gray # �ok fazla ��kt� olabilir
                Copy-Item -Path $sourceItemPath -Destination $destinationItemPath -Force -ErrorAction Stop

            } catch {
                Write-Host "Error copying file $($sourceItemPath): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# --- Main Script Execution ---

Write-Host "--- Backup Script Starting (Creating ZIP Archives) ---" -ForegroundColor Cyan
Write-Host "Destination Root: $($DestinationRoot)"
Write-Host "Excluded Folders: $($ExcludeFolders -join ', ')"
Write-Host "Excluded File Extensions: $($ExcludeFileExtensions -join ', ')"
Write-Host "---------------------------------------------------`n"

# Hedef k�k klas�r�n� olu�tur (varsa zaten var olacakt�r)
if (-not (Test-Path $DestinationRoot -PathType Container)) {
    Write-Host "Creating destination root directory: $($DestinationRoot)" -ForegroundColor Green
    try {
        New-Item -Path $DestinationRoot -ItemType Directory | Out-Null
    } catch {
         Write-Host "FATAL ERROR: Could not create destination root directory $($DestinationRoot). Check permissions or path." -ForegroundColor Red
         exit 1
    }
}

# Her bir kaynak k�k klas�r� i�in d�ng�ye gir
if ($SourceRoots.Count -eq 0) {
    Write-Host "FATAL ERROR: No source roots specified in the `$SourceRoots` parameter!" -ForegroundColor Red
    exit 1
}

Write-Host "Processing $($SourceRoots.Count) source root(s)...`n" -ForegroundColor Cyan

foreach ($CurrentSourceRoot in $SourceRoots) {
    $TempBackupPath = $null # Ge�ici yol de�i�kenini s�f�rla
    
    try {
        # Kaynak k�k klas�r�n�n varl���n� ve klas�r olup olmad���n� kontrol et
        if (-not (Test-Path $CurrentSourceRoot -PathType Container)) {
            Write-Host "WARNING: Source root directory $($CurrentSourceRoot) not found or is not a directory. Skipping." -ForegroundColor Yellow
            continue # Bu kayna�� atla, bir sonrakine ge�
        }

        # Kaynak klas�r ad�n� al ve ge�ici yedekleme yolunu olu�tur
        $SourceFolderName = (Get-Item $CurrentSourceRoot).Name
        # Get-TempPath() kullan�l�rsa genellikle 'C:\Users\...\AppData\Local\Temp\' olur
        $TempBackupPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "BackupTemp_$($SourceFolderName)_$([Guid]::NewGuid().ToString("N"))"
        # GUID eklemek, ayn� isimli farkl� kaynaklar veya ayn� kayna��n ard���k �al��t�r�lmas� durumunda �ak��may� �nler.

        Write-Host "--- Starting backup for $($CurrentSourceRoot) ---" -ForegroundColor Cyan
        Write-Host "Using temporary path: $($TempBackupPath)" -ForegroundColor DarkGray

        # Ge�ici yedekleme klas�r�n� olu�tur (olmas� gereken)
        # Copy-FilteredContentRecursive fonksiyonu da olu�turacak ama emin olmak i�in burada da yapabiliriz.
        # Bu scriptte recursive fonksiyon zaten olu�turuyor, buras� gereksiz.

        # �nceki �al��malardan kalan ayn� isimli temp klas�r varsa temizle
        if (Test-Path $TempBackupPath -PathType Container) {
            Write-Host "Cleaning up previous temporary directory: $($TempBackupPath)" -ForegroundColor DarkYellow
            try {
                 Remove-Item -Path $TempBackupPath -Recurse -Force -ErrorAction Stop
            } catch {
                 Write-Host "ERROR: Could not clean up temporary directory $($TempBackupPath): $($_.Exception.Message). Skipping this backup." -ForegroundColor Red
                 continue # Temp klas�r silinemezse bu yedeklemeyi atla
            }
        }
        
        # Kaynak i�eri�ini hari� tutarak ge�ici klas�re kopyala
        Write-Host "Copying filtered content to temporary location..." -ForegroundColor DarkCyan
        Copy-FilteredContentRecursive -SourcePath $CurrentSourceRoot -DestinationPath $TempBackupPath -ExcludeFoldersLower $ExcludeFoldersLower -ExcludeFileExtensionsLower $ExcludeFileExtensionsLower

        # Ge�ici klas�r�n bo� olup olmad���n� kontrol et (hari� tutulan her �eyse bo� olabilir)
        if (-not (Get-ChildItem -Path $TempBackupPath -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 1)) {
            Write-Host "Temporary backup path is empty after filtering. No content to archive. Skipping archiving for $($SourceFolderName)." -ForegroundColor Yellow
        } else {
            # Tarih damgas�n� T�rkiye format�nda al
            # HH:mm:ss yerine HH-mm-ss kulland�k ��nk� kolon Windows dosya isimlerinde kullan�lamaz.
            # yyyy-MM-dd_HH-mm-ss format� hem okunur hem de dosya y�neticilerinde do�ru s�ralan�r.
            $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

            # Hedef ZIP dosya ad�n� ve yolunu olu�tur
            $ArchiveFileName = "$($SourceFolderName)_$($Timestamp).zip"
            $ArchiveFilePath = Join-Path -Path $DestinationRoot -ChildPath $ArchiveFileName

            Write-Host "Compressing temporary content to $($ArchiveFilePath)..." -ForegroundColor DarkCyan

            # Ge�ici klas�r�n i�eri�ini ZIP dosyas�na s�k��t�r
            # -Path "$TempBackupPath\*" : Bu, ge�ici klas�r�n KEND�S�N� de�il, ��ER���N� s�k��t�rmak i�in kullan�l�r.
            Compress-Archive -Path "$TempBackupPath\*" -DestinationPath $ArchiveFilePath -Force -ErrorAction Stop # Force: Hedef dosya varsa �zerine yaz (ayn� timestamp'li dosya olmaz ger�i)

            Write-Host "Successfully created archive: $($ArchiveFilePath)" -ForegroundColor Green
        }

    } catch {
        # Try blo�u i�indeki herhangi bir hatay� yakala (ge�ici klas�r silme hari�)
        Write-Host "An error occurred during processing $($CurrentSourceRoot): $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        # Ge�ici klas�r� her zaman temizle (hata olsa bile)
        if (Test-Path $TempBackupPath -PathType Container) {
             Write-Host "Cleaning up temporary directory: $($TempBackupPath)" -ForegroundColor DarkGray
             Remove-Item -Path $TempBackupPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "--- Finished processing $($CurrentSourceRoot) ---`n" -ForegroundColor Cyan
}

Write-Host "--- All Source Roots Processed ---" -ForegroundColor Cyan
Write-Host "--- Backup Script Finished ---" -ForegroundColor Cyan