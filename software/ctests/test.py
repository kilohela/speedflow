#!/usr/bin/python3

import os
import subprocess
import glob

test_images = glob.glob(os.path.join("./build", "*.bin"))

for image in test_images:
    print(f"Start testing image: {image}")
    result = subprocess.run(["../../build/obj_dir/Vtop", "-i", image, "-k"])
    print(result.stdout)
    print()
