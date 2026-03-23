import torch
import torch.nn as nn
import torchaudio
import torchaudio.functional

# Compatibility patch for torchaudio 2.5+ with SpeechBrain 1.0.3
# Must be applied before importing speechbrain
if not hasattr(torchaudio, "list_audio_backends"):
    torchaudio.list_audio_backends = lambda: []

import coremltools as ct
from speechbrain.inference import EncoderClassifier
import librosa
import numpy as np

# Link - https://huggingface.co/speechbrain/spkrec-ecapa-voxceleb

print("Loading SpeechBrain model...")

class RealBrainWrapper(nn.Module):
    def __init__(self):
        super().__init__()
        # Load the full classifier
        self.classifier = EncoderClassifier.from_hparams(
            source="speechbrain/spkrec-ecapa-voxceleb",
            run_opts={"device": "cpu"}
        )
        # Separate the internal modules we need
        self.feature_extractor = self.classifier.mods.compute_features
        self.normalizer = self.classifier.mods.mean_var_norm
        self.embedding_model = self.classifier.mods.embedding_model

    def forward(self, wavs):
        # 1. Extract 80-channel features (MFCCs)
        # Input: [Batch, Samples] -> Output: [Batch, Time, 80]
        feats = self.feature_extractor(wavs)
        
        # 2. Normalize features
        # We use a dummy length tensor as required by SpeechBrain's normalizer
        rel_len = torch.ones(wavs.shape[0])
        feats = self.normalizer(feats, rel_len)
        
        # 3. Get Embeddings
        # The embedding model expects [Batch, Time, 80]
        return self.embedding_model(feats)

# 2. Load the test audio (test.wav) using librosa for maximum portability
audio_path = "test.wav"
# Load at native rate then resample to 16kHz
signal_np, sr = librosa.load(audio_path, sr=16000, mono=True)

# Convert to torch tensor [1, Samples]
signal = torch.from_numpy(signal_np).unsqueeze(0).float()

# 3. Prepare exactly 6 seconds (96,000 samples)
# Note: SpeechBrain's internal padding might add a few samples, 
# so we use exactly 96000 for the CoreML input definition.
NUM_SAMPLES = 96000
if signal.shape[1] < NUM_SAMPLES:
    real_input = torch.nn.functional.pad(signal, (0, NUM_SAMPLES - signal.shape[1]))
else:
    real_input = signal[:, :NUM_SAMPLES]

# 4. Initialize and Trace
model = RealBrainWrapper().eval()
print(f"Tracing with input audio ({NUM_SAMPLES} samples)...")

# Tracing the full pipeline from raw audio to embedding
traced_model = torch.jit.trace(model, real_input, strict=False)

print("Converting to CoreML...")
mlmodel = ct.convert(
    traced_model,
    inputs=[ct.TensorType(name="audio", shape=real_input.shape)], # Shape [1, 96000]
    outputs=[ct.TensorType(name="embedding")],
    compute_units=ct.ComputeUnit.ALL 
)

mlmodel.save("VL1004.mlpackage")
print("CoreML model conversion complete.")