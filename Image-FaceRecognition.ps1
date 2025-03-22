# Image-FaceRecognition.ps1
# PowerShell script to orchestrate facial recognition and EXIF tagging

param(
    [Parameter(Mandatory = $false)]
    [switch]$Train,
    
    [Parameter(Mandatory = $false)]
    [string]$TrainingDir = ".\training_images",
    
    [Parameter(Mandatory = $false)]
    [string]$ProcessDir,
    
    [Parameter(Mandatory = $false)]
    [string]$ModelPath = ".\face_model.pkl",
    
    [Parameter(Mandatory = $false)]
    [double]$Tolerance = 0.6,
    
    [Parameter(Mandatory = $false)]
    [switch]$InstallExifTool
)

# -------------------- Configuration --------------------
$pythonEnvPath = ".\face_recognition_env\Scripts\python.exe"
$pythonScriptPath = ".\facial_recognition.py"
$exifToolPath = ".\exiftool.exe"

# -------------------- Helper Functions --------------------
function Write-ColorOutput {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Test-PythonEnvironment {
    if (-not (Test-Path $pythonEnvPath)) {
        Write-ColorOutput "Python environment not found. Please run Setup-PythonEnvironment.ps1 first." "Red"
        exit 1
    }
}

function Install-ExifTool {
    Write-ColorOutput "Downloading ExifTool..." "Cyan"
    $exifToolZip = ".\exiftool.zip"
    Invoke-WebRequest -Uri "https://exiftool.org/exiftool-12.60.zip" -OutFile $exifToolZip
    
    Write-ColorOutput "Extracting ExifTool..." "Cyan"
    Expand-Archive -Path $exifToolZip -DestinationPath ".\exiftool_temp" -Force
    
    # Find the extracted directory
    $extractedDir = Get-ChildItem -Path ".\exiftool_temp" -Directory | Select-Object -First 1
    
    # Copy the exiftool(-k).exe to current directory and rename it
    Copy-Item -Path "$($extractedDir.FullName)\exiftool(-k).exe" -Destination $exifToolPath
    
    # Clean up
    Remove-Item -Path $exifToolZip -Force
    Remove-Item -Path ".\exiftool_temp" -Recurse -Force
    
    Write-ColorOutput "ExifTool installed successfully." "Green"
}

function Test-ExifTool {
    if (-not (Test-Path $exifToolPath)) {
        Write-ColorOutput "ExifTool not found." "Yellow"
        return $false
    }
    return $true
}

function Train-Model {
    param (
        [string]$TrainingDirectory
    )
    
    if (-not (Test-Path $TrainingDirectory)) {
        Write-ColorOutput "Training directory does not exist: $TrainingDirectory" "Red"
        exit 1
    }
    
    Write-ColorOutput "Training facial recognition model..." "Cyan"
    $args = "--train `"$TrainingDirectory`" --model `"$ModelPath`""
    $output = & $pythonEnvPath $pythonScriptPath $args.Split(" ")
    
    Write-ColorOutput $output "Green"
    Write-ColorOutput "Training complete!" "Green"
}

function Process-Images {
    param (
        [string]$DirectoryPath
    )
    
    if (-not (Test-Path $DirectoryPath)) {
        Write-ColorOutput "Image directory does not exist: $DirectoryPath" "Red"
        exit 1
    }
    
    if (-not (Test-Path $ModelPath)) {
        Write-ColorOutput "Model file not found: $ModelPath. Please train the model first." "Red"
        exit 1
    }
    
    Write-ColorOutput "Processing images in $DirectoryPath..." "Cyan"
    $args = "--process-dir `"$DirectoryPath`" --model `"$ModelPath`" --tolerance $Tolerance"
    $json = & $pythonEnvPath $pythonScriptPath $args.Split(" ")
    
    try {
        $results = $json | ConvertFrom-Json
        
        # Process each image and update EXIF
        foreach ($imagePath in $results.PSObject.Properties.Name) {
            $fullPath = Join-Path -Path $DirectoryPath -ChildPath $imagePath
            $peopleFound = $results.$imagePath
            
            Write-ColorOutput "Image: $imagePath" "White"
            if ($peopleFound.Count -eq 0) {
                Write-ColorOutput "  No people recognized" "Yellow"
                continue
            }
            
            # Format the people list for EXIF
            $peopleList = $peopleFound -join ", "
            Write-ColorOutput "  People found: $peopleList" "Green"
            
            # Update EXIF tags
            Update-ExifTags -ImagePath $fullPath -People $peopleFound
        }
    }
    catch {
        Write-ColorOutput "Error processing results: $_" "Red"
        Write-ColorOutput "Raw output: $json" "Red"
    }
}

function Update-ExifTags {
    param (
        [string]$ImagePath,
        [array]$People
    )
    
    try {
        # First, check if ExifTool is available
        if (-not (Test-Path $exifToolPath)) {
            Write-ColorOutput "ExifTool not found. Cannot update EXIF tags." "Red"
            return
        }
        
        # Create comma-separated list of people
        $peopleList = $People -join ", "
        
        # Update the Keywords and PersonInImage tags
        $exifArgs = @(
            "-Keywords+=$peopleList",
            "-Subject+=$peopleList",
            "-PersonInImage+=$peopleList",
            "-overwrite_original",
            "`"$ImagePath`""
        )
        
        # Run ExifTool
        $output = & $exifToolPath $exifArgs
        Write-ColorOutput "  Updated EXIF tags: $output" "Cyan"
    }
    catch {
        Write-ColorOutput "  Error updating EXIF tags: $_" "Red"
    }
}

# -------------------- Main Script --------------------

# Check Python environment
Test-PythonEnvironment

# Install ExifTool if requested
if ($InstallExifTool -or (-not (Test-ExifTool))) {
    if ($InstallExifTool) {
        Install-ExifTool
    }
    else {
        $installPrompt = Read-Host "ExifTool not found. Do you want to download and install it? (Y/N)"
        if ($installPrompt -eq "Y" -or $installPrompt -eq "y") {
            Install-ExifTool
        }
        else {
            Write-ColorOutput "ExifTool is required for updating image metadata. EXIF tagging will be skipped." "Yellow"
        }
    }
}

# Train model if requested
if ($Train) {
    Train-Model -TrainingDirectory $TrainingDir
}

# Process images if directory provided
if ($ProcessDir) {
    Process-Images -DirectoryPath $ProcessDir
}

# If no action specified, show help
if (-not $Train -and -not $ProcessDir) {
    Write-ColorOutput "No action specified. Use -Train to train the model or -ProcessDir to process images." "Yellow"
    Write-ColorOutput "Example usage:" "Cyan"
    Write-ColorOutput "  .\Image-FaceRecognition.ps1 -Train -TrainingDir .\my_training_images" "White"
    Write-ColorOutput "  .\Image-FaceRecognition.ps1 -ProcessDir .\my_photos" "White"
    Write-ColorOutput "  .\Image-FaceRecognition.ps1 -Train -TrainingDir .\my_training_images -ProcessDir .\my_photos" "White"
}