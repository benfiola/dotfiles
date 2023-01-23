#!/usr/bin/env python3
import json
import os


warhammer_darktide = 1361210

app_settings = {warhammer_darktide: {"VKD3D_CONFIG": ""}}

default_settings = {
    "PROTON_HIDE_NVIDIA_GPU": "0",
    "PROTON_ENABLE_NVAPI": "1",
    "VKD3D_FEATURE_LEVEL": "12_2",
    "VKD3D_CONFIG": "dxr,dxr11",
    "DXVK_ASYNC": "1",
}


app_id = int(os.environ.get("SteamAppId", "-1"))
user_settings = dict(default_settings)
user_settings.update(app_settings.get(app_id, {}))
print(f"user settings: {app_id}")
print(json.dumps(user_settings, indent=2))
