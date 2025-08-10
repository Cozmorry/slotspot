#!/usr/bin/env python3
"""
Model Download Script for SlotSpot
Downloads and prepares TensorFlow Lite models for parking predictions
"""

import os
import requests
import tensorflow as tf
import numpy as np
from pathlib import Path

def create_simple_lstm_model():
    """Create a simple Dense model for parking predictions (more TFLite compatible)"""
    print("🏗️ Creating Dense model for parking predictions...")
    
    # Model architecture - using Dense layers instead of LSTM for better TFLite compatibility
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(168, 6)),
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(32, activation='relu'),
        tf.keras.layers.Dense(24, activation='sigmoid')  # 24 predictions (12 hours * 2)
    ])
    
    # Compile model
    model.compile(
        optimizer='adam',
        loss='mse',
        metrics=['mae']
    )
    
    print("✅ Model created successfully")
    return model

def train_model_with_synthetic_data(model):
    """Train the model with synthetic parking data"""
    print("🎯 Training model with synthetic data...")
    
    # Generate synthetic training data
    np.random.seed(42)
    n_samples = 1000
    
    # Input: 7 days * 24 hours = 168 time steps, 6 features each
    X = np.random.random((n_samples, 168, 6))
    
    # Output: 24 predictions (12 hours * 2 intervals)
    y = np.random.random((n_samples, 24))
    
    # Add some realistic patterns
    for i in range(n_samples):
        # Add time-based patterns
        for t in range(168):
            hour = t % 24
            day = t // 24
            
            # Weekend effect
            weekend_factor = 1.2 if day in [5, 6] else 1.0
            
            # Peak hours
            peak_factor = 1.3 if hour in [12, 13, 17, 18, 19] else 0.8
            
            # Apply patterns to features
            X[i, t, 0] = hour / 24.0  # Normalized hour
            X[i, t, 1] = day / 7.0    # Normalized day
            X[i, t, 2] = 1.0 if day in [5, 6] else 0.0  # Weekend flag
            X[i, t, 3] = 0.6 * weekend_factor * peak_factor  # Historical average
            X[i, t, 4] = np.random.random() * 0.3  # Reservation count
            X[i, t, 5] = np.random.random() * 0.4 + 0.3  # Crowd activity
        
        # Generate realistic output patterns
        for j in range(24):
            hour = j // 2  # Convert 30-min intervals to hours
            y[i, j] = 0.6 + 0.2 * np.sin(hour * np.pi / 12) + 0.1 * np.random.random()
            y[i, j] = np.clip(y[i, j], 0.1, 0.95)
    
    # Train the model
    model.fit(
        X, y,
        epochs=50,
        batch_size=32,
        validation_split=0.2,
        verbose=1
    )
    
    print("✅ Model training completed")
    return model

def convert_to_tflite(model, output_path):
    """Convert the model to TensorFlow Lite format"""
    print(f"🔄 Converting model to TensorFlow Lite...")
    
    # Convert to TensorFlow Lite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Enable optimizations
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # Add compatibility settings
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    converter._experimental_lower_tensor_list_ops = False
    
    # Convert
    tflite_model = converter.convert()
    
    # Save the model
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    # Get model size
    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"✅ Model saved to {output_path} ({size_mb:.1f}MB)")

def download_pretrained_model():
    """Download a pre-trained model from a URL"""
    print("📥 Skipping pre-trained model download, creating custom model...")
    return None

def main():
    """Main function to download/prepare the model"""
    print("🚀 SlotSpot Model Download Script")
    print("=" * 40)
    
    # Create models directory
    models_dir = Path("assets/models")
    models_dir.mkdir(parents=True, exist_ok=True)
    
    output_path = models_dir / "parking_predictor.tflite"
    
    # Try to download pre-trained model first
    pretrained_model = download_pretrained_model()
    
    if pretrained_model:
        # Save downloaded model
        with open(output_path, 'wb') as f:
            f.write(pretrained_model)
        size_mb = os.path.getsize(output_path) / (1024 * 1024)
        print(f"✅ Pre-trained model saved ({size_mb:.1f}MB)")
    else:
        # Create and train a new model
        print("🏗️ Creating custom model for SlotSpot...")
        
        # Create model
        model = create_simple_lstm_model()
        
        # Train model
        model = train_model_with_synthetic_data(model)
        
        # Convert to TensorFlow Lite
        convert_to_tflite(model, output_path)
    
    print("\n🎉 Model preparation completed!")
    print(f"📁 Model location: {output_path}")
    print(f"📱 Ready to use in SlotSpot app")
    
    # Test the model
    print("\n🧪 Testing model...")
    try:
        interpreter = tf.lite.Interpreter(model_path=str(output_path))
        interpreter.allocate_tensors()
        
        # Get input and output details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"✅ Model loaded successfully")
        print(f"📊 Input shape: {input_details[0]['shape']}")
        print(f"📊 Output shape: {output_details[0]['shape']}")
        
        # Test with sample input
        test_input = np.random.random((1, 168, 6)).astype(np.float32)
        interpreter.set_tensor(input_details[0]['index'], test_input)
        interpreter.invoke()
        
        test_output = interpreter.get_tensor(output_details[0]['index'])
        print(f"✅ Test prediction shape: {test_output.shape}")
        
    except Exception as e:
        print(f"❌ Model test failed: {e}")

if __name__ == "__main__":
    main()
