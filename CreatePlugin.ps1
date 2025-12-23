# CreatePlugin.ps1
# Creates the .streamDeckPlugin distribution file that can be distributed to users
# A .streamDeckPlugin is just a ZIP file with the plugin contents
# Run this after building the project in Release mode

param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

# Paths
$ProjectRoot = $PSScriptRoot
$PluginSourceDir = Join-Path $ProjectRoot "starcitizen\bin\$Configuration\com.mhwlng.starcitizen.sdPlugin"
$OutputDir = Join-Path $ProjectRoot "dist"
$OutputFile = Join-Path $OutputDir "com.mhwlng.starcitizen.streamDeckPlugin"

# Elgato DistributionTool paths (common locations)
$DistToolPaths = @(
    "${env:ProgramFiles}\Elgato\StreamDeck\DistributionTool.exe",
    "${env:ProgramFiles(x86)}\Elgato\StreamDeck\DistributionTool.exe",
    "C:\Program Files\Elgato\StreamDeck\DistributionTool.exe",
    "$env:APPDATA\Elgato\StreamDeck\DistributionTool.exe"
)

Write-Host "=== Stream Deck Plugin Packager ===" -ForegroundColor Cyan
Write-Host ""

# Check if source directory exists
if (-not (Test-Path $PluginSourceDir)) {
    Write-Host "ERROR: Plugin directory not found!" -ForegroundColor Red
    Write-Host "Expected: $PluginSourceDir" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please build the project in $Configuration mode first:" -ForegroundColor Yellow
    Write-Host "  1. Open the solution in Visual Studio/Rider" -ForegroundColor White
    Write-Host "  2. Set configuration to '$Configuration'" -ForegroundColor White
    Write-Host "  3. Build the solution (Ctrl+Shift+B)" -ForegroundColor White
    exit 1
}

# Check for required files
$requiredFiles = @(
    "manifest.json",
    "com.mhwlng.starcitizen.exe"
)

foreach ($file in $requiredFiles) {
    $filePath = Join-Path $PluginSourceDir $file
    if (-not (Test-Path $filePath)) {
        Write-Host "ERROR: Required file missing: $file" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Source directory: $PluginSourceDir" -ForegroundColor Green
Write-Host ""

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Gray
}

# Remove old output file if exists
if (Test-Path $OutputFile) {
    Remove-Item $OutputFile -Force
    Write-Host "Removed old plugin file" -ForegroundColor Gray
}

# Find DistributionTool
$DistTool = $null
if ($UseDistributionTool) {
    foreach ($path in $DistToolPaths) {
        if (Test-Path $path) {
            $DistTool = $path
            break
        }
    }
}

if ($DistTool) {
    Write-Host "Using Elgato DistributionTool: $DistTool" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        # Run DistributionTool
        & $DistTool -b -i $PluginSourceDir -o $OutputDir
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
            Write-Host ""
            Write-Host "SUCCESS!" -ForegroundColor Green
            Write-Host "Plugin file created: $OutputFile" -ForegroundColor Cyan
        }
        else {
            throw "DistributionTool failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Host "ERROR: DistributionTool failed" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
        Write-Host "Falling back to manual ZIP creation..." -ForegroundColor Yellow
        $DistTool = $null
    }
}

# Manual ZIP creation (fallback or default)
if (-not $DistTool) {
    Write-Host "Creating plugin package (manual ZIP method)..." -ForegroundColor Yellow
    Write-Host ""
    
    # Use .NET's ZipFile for better compatibility
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    try {
        # Create temporary zip
        $tempZip = Join-Path $OutputDir "temp.zip"
        if (Test-Path $tempZip) {
            Remove-Item $tempZip -Force
        }
        
        # IMPORTANT: The .streamDeckPlugin needs to contain the .sdPlugin FOLDER, not just its contents
        # So we ZIP the parent directory (bin\Release) which contains the .sdPlugin folder
        $parentDir = Split-Path $PluginSourceDir -Parent
        $pluginFolderName = Split-Path $PluginSourceDir -Leaf
        
        # Create ZIP containing the .sdPlugin folder
        Write-Host "Packaging: $pluginFolderName" -ForegroundColor Gray
        
        $archive = [System.IO.Compression.ZipFile]::Open($tempZip, 'Create')
        
        # Add all files from the plugin directory, maintaining the .sdPlugin folder structure
        Get-ChildItem -Path $PluginSourceDir -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($PluginSourceDir.Length + 1)
            $entryName = "$pluginFolderName/$($relativePath.Replace('\', '/'))"
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $_.FullName, $entryName, 'Optimal') | Out-Null
        }
        
        $archive.Dispose()
        
        # Rename to .streamDeckPlugin
        Move-Item $tempZip $OutputFile -Force
        
        Write-Host "SUCCESS!" -ForegroundColor Green
        Write-Host "Plugin file created: $OutputFile" -ForegroundColor Cyan
    }
    catch {
        Write-Host "ERROR: Failed to create plugin package" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "File size: $([math]::Round((Get-Item $OutputFile).Length / 1MB, 2)) MB" -ForegroundColor Gray
Write-Host ""
Write-Host "To install:" -ForegroundColor Yellow
Write-Host "  1. Close Stream Deck software" -ForegroundColor White
Write-Host "  2. Double-click: $OutputFile" -ForegroundColor White
Write-Host "     (Or drag and drop into Stream Deck window)" -ForegroundColor Gray
Write-Host "  3. Restart Stream Deck software if needed" -ForegroundColor White
Write-Host ""
Write-Host "For GitHub release, upload this file to your Releases page." -ForegroundColor Cyan
Write-Host ""

# Show how to verify the package
Write-Host "To verify package contents:" -ForegroundColor DarkGray
Write-Host "  Rename to .zip and extract to inspect files" -ForegroundColor DarkGray
