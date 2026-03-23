import torch
import torch.nn as nn
import coremltools as ct
from speechbrain.inference import EncoderClassifier

print("⏳ Downloading the Real Brain (SpeechBrain)...")

# 1. Define the Wrapper
class RealBrainWrapper(nn.Module):
    def __init__(self):
        super().__init__()
        # Load the pre-trained ECAPA-VoxCeleb model
        self.classifier = EncoderClassifier.from_hparams(
            source="speechbrain/spkrec-ecapa-voxceleb",
            run_opts={"device": "cpu"}
        )

    def forward(self, wavs):
        # Forward pass to get embeddings
        return self.classifier.encode_batch(wavs)

# 2. Initialize and set to eval mode
model = RealBrainWrapper().eval()

# 3. Define the Input Shape (THE FIX)
# 16,000 Hz * 3 seconds = 48,000 samples
# This provides 2x more data per inference than your previous 1.5s model.
SAMPLE_RATE = 16000
DURATION_SECONDS = 3
NUM_SAMPLES = SAMPLE_RATE * DURATION_SECONDS

dummy_input = torch.randn(1, NUM_SAMPLES)

print(f"📸 Tracing the model structure with {DURATION_SECONDS}s window ({NUM_SAMPLES} samples)...")
traced_model = torch.jit.trace(model, dummy_input)

print("🍏 Converting to CoreML...")
mlmodel = ct.convert(
    traced_model,
    inputs=[ct.TensorType(name="audio", shape=dummy_input.shape)],
    outputs=[ct.TensorType(name="embedding")],
    minimum_deployment_target=ct.target.iOS16,
    compute_units=ct.ComputeUnit.CPU_AND_NE
)

# 4. Save with a NEW Name
model_name = "VL-1004.mlpackage"
mlmodel.save(model_name)
print(f"SUCCESS! '{model_name}' is ready.")