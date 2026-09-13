import tensorflow as tf
import numpy as np
from PIL import Image
import glob
import os

MODEL = r"assets\models\waste_model.tflite"

interpreter = tf.lite.Interpreter(model_path=MODEL)
interpreter.allocate_tensors()

input_tensor = interpreter.get_input_details()[0]
output_tensor = interpreter.get_output_details()[0]

print("=== PREPROCESSING COMPARISON ===")
print("Input:", input_tensor["shape"], input_tensor["dtype"])
print("Output:", output_tensor["shape"], output_tensor["dtype"])

for path in sorted(glob.glob(r"test_images\*")):
    print()
    print("=" * 50)
    print(os.path.basename(path))
    print("=" * 50)

    image = Image.open(path).convert("RGB").resize((160, 160))
    pixels = np.asarray(image, dtype=np.float32)

    for name, data in [
        ("0-1", pixels / 255.0),
        ("-1 to 1", pixels / 127.5 - 1.0),
    ]:
        interpreter.set_tensor(
            input_tensor["index"],
            data[None, ...],
        )

        interpreter.invoke()

        scores = interpreter.get_tensor(
            output_tensor["index"]
        )[0]

        top = np.argsort(scores)[::-1][:5]

        print(
            name,
            "->",
            [
                (int(i), round(float(scores[i]), 6))
                for i in top
            ],
        )
