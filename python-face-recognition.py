# facial_recognition.py
# Core functionality for facial recognition and model training

import os
import pickle
import json
import face_recognition
import numpy as np
from sklearn.neighbors import KNeighborsClassifier
from PIL import Image
import argparse
import sys

class FacialRecognitionEngine:
    def __init__(self, model_path="face_model.pkl"):
        self.model_path = model_path
        self.model = None
        self.load_model()
    
    def load_model(self):
        """Load the trained model if it exists"""
        if os.path.exists(self.model_path):
            try:
                with open(self.model_path, 'rb') as f:
                    self.model = pickle.load(f)
                return True
            except Exception as e:
                print(f"Error loading model: {e}", file=sys.stderr)
        return False
    
    def save_model(self):
        """Save the trained model to disk"""
        with open(self.model_path, 'wb') as f:
            pickle.dump(self.model, f)
    
    def train(self, training_dir):
        """
        Train the facial recognition model using images in the specified directory
        
        Expected structure:
        training_dir/
            person1/
                image1.jpg
                image2.jpg
            person2/
                image1.jpg
                ...
        """
        face_encodings = []
        face_names = []
        
        # Process each subdirectory (person)
        for person_name in os.listdir(training_dir):
            person_dir = os.path.join(training_dir, person_name)
            if not os.path.isdir(person_dir):
                continue
            
            # Process each image in the person's directory
            for image_file in os.listdir(person_dir):
                image_path = os.path.join(person_dir, image_file)
                if not image_path.lower().endswith(('.png', '.jpg', '.jpeg')):
                    continue
                
                try:
                    # Load the image and find face encodings
                    image = face_recognition.load_image_file(image_path)
                    encodings = face_recognition.face_encodings(image)
                    
                    # If faces were found, add them to our training data
                    if len(encodings) > 0:
                        face_encodings.append(encodings[0])
                        face_names.append(person_name)
                        print(f"Processed {image_path} - Found face of {person_name}")
                    else:
                        print(f"Warning: No face found in {image_path}", file=sys.stderr)
                except Exception as e:
                    print(f"Error processing {image_path}: {e}", file=sys.stderr)
        
        # Train the model using KNN
        if len(face_encodings) > 0:
            self.model = KNeighborsClassifier(n_neighbors=min(5, len(face_encodings)))
            self.model.fit(face_encodings, face_names)
            self.save_model()
            return len(face_encodings)
        else:
            print("No face encodings found! Training failed.", file=sys.stderr)
            return 0
    
    def recognize(self, image_path, tolerance=0.6):
        """
        Recognize faces in the given image
        
        Returns:
        List of recognized people in the image
        """
        if not self.model:
            print("No trained model found! Please train the model first.", file=sys.stderr)
            return []
        
        try:
            # Load the image and find face locations and encodings
            image = face_recognition.load_image_file(image_path)
            face_locations = face_recognition.face_locations(image)
            face_encodings = face_recognition.face_encodings(image, face_locations)
            
            people_found = []
            
            # Recognize each face in the image
            for face_encoding in face_encodings:
                # KNN prediction
                closest_distances = self.model.kneighbors([face_encoding], n_neighbors=1)
                is_match = closest_distances[0][0][0] <= tolerance
                
                if is_match:
                    person_name = self.model.predict([face_encoding])[0]
                    if person_name not in people_found:
                        people_found.append(person_name)
            
            return people_found
            
        except Exception as e:
            print(f"Error recognizing faces in {image_path}: {e}", file=sys.stderr)
            return []

def process_directory(engine, directory_path, json_output=True):
    """Process all images in a directory and return recognition results"""
    results = {}
    
    for filename in os.listdir(directory_path):
        file_path = os.path.join(directory_path, filename)
        if not file_path.lower().endswith(('.png', '.jpg', '.jpeg')):
            continue
            
        try:
            people = engine.recognize(file_path)
            results[filename] = people
        except Exception as e:
            print(f"Error processing {file_path}: {e}", file=sys.stderr)
            results[filename] = {"error": str(e)}
    
    if json_output:
        return json.dumps(results)
    return results

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Facial Recognition Tool")
    parser.add_argument("--train", help="Directory containing training images")
    parser.add_argument("--recognize", help="Image file to recognize faces in")
    parser.add_argument("--process-dir", help="Directory of images to process")
    parser.add_argument("--model", default="face_model.pkl", help="Path to model file")
    parser.add_argument("--tolerance", type=float, default=0.6, 
                        help="Recognition tolerance (0.0-1.0, lower is stricter)")
    
    args = parser.parse_args()
    
    engine = FacialRecognitionEngine(args.model)
    
    if args.train:
        count = engine.train(args.train)
        print(f"Training complete! Processed {count} face(s)")
    elif args.recognize:
        people = engine.recognize(args.recognize, args.tolerance)
        print(json.dumps(people))
    elif args.process_dir:
        results = process_directory(engine, args.process_dir)
        print(results)
    else:
        parser.print_help()