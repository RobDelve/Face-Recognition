# Setup-PythonEnvironment.ps1
# This script sets up a Python environment with required packages for facial recognition

# Check if Python is installed
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCommand) {
    Write-Host "Python not found. Please install Python 3.8+ from https://www.python.org/downloads/" -ForegroundColor Red
    exit 1
}

# Create a virtual environment
Write-Host "Creating Python virtual environment..." -ForegroundColor Green
python -m venv .\face_recognition_env

# Activate the virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Green
& .\face_recognition_env\Scripts\Activate.ps1

# Install required packages
Write-Host "Installing required Python packages (this may take a while)..." -ForegroundColor Green
pip install numpy
pip install pillow
pip install face_recognition
pip install scikit-learn
pip install opencv-python

# Verify installation
Write-Host "Verifying installation..." -ForegroundColor Green
python -c "import face_recognition; print('face_recognition library installed successfully')"

Write-Host "Python environment setup complete." -ForegroundColor Green
Write-Host "To activate this environment in the future, run: & .\face_recognition_env\Scripts\Activate.ps1" -ForegroundColor Yellow