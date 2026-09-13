import tensorflow as tf
import numpy as np
from PIL import Image
import glob
import os

MODEL = r"assets\models\waste_model.tflite"

interpreter = tf.lite.Interpreter(model_path=MODEL)
interpreter.allocate_tensors()

input_info = interpreter.get_input_details()[0]
output_info = interpreter.get_output_details()[0]

print("INPUT :", input_info["shape"], input_info["dtype"])
print("OUTPUT:", output_info["shape"], output_info["dtype"])

for path in sorted(glob.glob(r"test_images\*")):
    image = Image.open(path).convert("RGB").resize((160, 160))
    array = np.asarray(image, dtype=np.float32) / 255.0
    array = array[None, ...]

    interpreter.set_tensor(input_info["index"], array)
    interpreter.invoke()

    scores = interpreter.get_tensor(output_info["index"])[0]
    top = np.argsort(scores)[::-1][:5]

    print()
    print("=" * 50)
    print(os.path.basename(path))
    print("=" * 50)

    for index in top:
        print(f"Class {int(index):2d}: {float(scores[index]):.6f}")
