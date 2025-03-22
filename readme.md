# PowerShell + Python Facial Recognition System

This system combines PowerShell and Python to create a facial recognition solution that can identify people in photos and tag them in the image metadata.

## Features

- Train a custom facial recognition model using your own labeled images
- Automatically process folders of photos to identify people
- Update EXIF metadata with tags containing the names of recognized individuals
- Fully local processing for privacy

## Prerequisites

- Windows 10/11
- Python 3.8 or higher
- PowerShell 5.1 or higher

## Installation

1. Clone or download this repository to your local machine
2. Run the setup script to create the Python environment:

```powershell
.\Setup-PythonEnvironment.ps1
```

3. Install ExifTool (automatically prompted during first run or use `-InstallExifTool` flag)

## Preparing Training Data

Organize your training images in the following folder structure:

```
training_images/
├── John/
│   ├── john1.jpg
│   ├── john2.jpg
│   └── ...
├── Jane/
│   ├── jane1.jpg
│   ├── jane2.jpg
│   └── ...
└── ...
```

- Each person should have their own folder named after them
- Each folder should contain several clear images of only that person
- Images should show the person's face clearly from different angles
- Use .jpg, .jpeg, or .png format

## Usage

### Training the Model

```powershell
.\Image-FaceRecognition.ps1 -Train -TrainingDir .\path\to\training_images
```

### Processing Photos

```powershell
.\Image-FaceRecognition.ps1 -ProcessDir .\path\to\photos
```

### Combined Operation

```powershell
.\Image-FaceRecognition.ps1 -Train -TrainingDir .\training_images -ProcessDir .\photos_to_process
```

### Additional Options

- `-ModelPath`: Specify a custom path for the model file (default: .\face_model.pkl)
- `-Tolerance`: Adjust recognition sensitivity (0.0-1.0, lower is stricter, default: 0.6)
- `-InstallExifTool`: Force installation of ExifTool

## How It Works

1. **Training Phase**:
   - The system scans through your training directory
   - For each person, it extracts facial features from their images
   - These features are used to train a machine learning model (K-Nearest Neighbors)
   - The model is saved to disk for future use

2. **Recognition Phase**:
   - The system loads the trained model
   - For each image in the processing directory:
     - Faces are detected and their features extracted
     - The model compares these features to the training data
     - Matches are identified based on similarity
   
3. **Tagging Phase**:
   - ExifTool updates the image metadata
   - People's names are added to the Keywords, Subject, and PersonInImage EXIF fields
   - Original files are updated in place

## Troubleshooting

- **No faces detected during training**: Ensure images clearly show faces and have good lighting
- **False recognitions**: Try adjusting the tolerance value (lower for stricter matching)
- **Python errors**: Verify that the environment was set up correctly with all dependencies
- **EXIF writing fails**: Check that ExifTool was installed correctly and images aren't read-only

## Advanced Customization

You can modify the `facial_recognition.py` script to adjust:
- Face detection parameters
- KNN classifier settings
- Recognition thresholds

## License

This project is for personal use and learning purposes.