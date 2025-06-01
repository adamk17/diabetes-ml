import tensorflow as tf
import numpy as np
import matplotlib.pyplot as plt
from sklearn.datasets import load_diabetes
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import pickle

# === Load data ===
data = load_diabetes()
X = data.data
y = data.target

print(f"Dataset size: {len(X)} samples with {X.shape[1]} features")

# === Data scaling ===
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# === Train/test split with stratification ===
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y, test_size=0.2, random_state=42
)

# === Improved Keras model with regularization ===
def build_model(learning_rate=0.001):
    model = tf.keras.Sequential([
        tf.keras.layers.Dense(64, input_shape=(X.shape[1],), 
                             activation='relu',
                             kernel_regularizer=tf.keras.regularizers.l2(0.001)),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.3),
        
        tf.keras.layers.Dense(32, activation='relu',
                             kernel_regularizer=tf.keras.regularizers.l2(0.001)),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.3),
        
        tf.keras.layers.Dense(1)  # Regression output
    ])
    
    optimizer = tf.keras.optimizers.Adam(learning_rate=learning_rate)
    model.compile(optimizer=optimizer, loss='mse', metrics=['mae'])
    return model

# === Early stopping callback ===
early_stopping = tf.keras.callbacks.EarlyStopping(
    monitor='val_loss',
    patience=30,
    restore_best_weights=True,
    verbose=1
)

# === Reduce learning rate on plateau ===
reduce_lr = tf.keras.callbacks.ReduceLROnPlateau(
    monitor='val_loss',
    factor=0.5,
    patience=10,
    min_lr=0.00001,
    verbose=1
)

# === Model training ===
model = build_model()
history = model.fit(
    X_train, y_train,
    epochs=300,
    batch_size=16,  # Smaller batch size for better generalization
    validation_split=0.2,  # Larger validation split
    callbacks=[early_stopping, reduce_lr],
    verbose=1
)

# === Evaluate model on test set ===
test_loss, test_mae = model.evaluate(X_test, y_test, verbose=0)
print(f"Test MAE: {test_mae:.2f}")

# === Save model and scaler ===
model.save("./trained_model/tf_model.h5")
with open("./trained_model/scaler.pkl", "wb") as f:
    pickle.dump(scaler, f)

# === Plot training history ===
plt.figure(figsize=(12, 5))

# Training metrics plot
plt.subplot(1, 2, 1)
plt.plot(history.history['mae'], label='Training MAE')
plt.plot(history.history['val_mae'], label='Validation MAE')
plt.xlabel('Epoch')
plt.ylabel('MAE')
plt.title('Training & Validation MAE')
plt.legend()
plt.grid(True)

# Learning rate plot if available
if 'lr' in history.history:
    plt.subplot(1, 2, 2)
    plt.semilogy(history.history['lr'], label='Learning Rate')
    plt.xlabel('Epoch')
    plt.ylabel('Learning Rate')
    plt.title('Learning Rate Schedule')
    plt.grid(True)
    plt.legend()

plt.tight_layout()
plt.savefig("./trained_model/training_plot.png")

# === 11. Feature importance analysis ===
# Get weights from the first layer
first_layer_weights = np.abs(model.layers[0].get_weights()[0])
feature_importance = np.mean(first_layer_weights, axis=1)
feature_names = data.feature_names

# Plot feature importance
plt.figure(figsize=(10, 6))
plt.barh(feature_names, feature_importance)
plt.xlabel('Average Absolute Weight')
plt.title('Feature Importance')
plt.tight_layout()
plt.savefig("./trained_model/feature_importance.png")

# === 12. Make predictions on test data and visualize ===
y_pred = model.predict(X_test).flatten()

plt.figure(figsize=(8, 8))
plt.scatter(y_test, y_pred)
plt.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 'k--', lw=2)
plt.xlabel('Actual Values')
plt.ylabel('Predicted Values')
plt.title('Prediction Scatter Plot')
plt.grid(True)
plt.savefig("./trained_model/prediction_scatter.png")

print("Model training and evaluation complete!")
