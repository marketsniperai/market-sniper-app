
import os

# Minimal 1x1 black PNG
png_hex = "89504E470D0A1A0A0000000D49484452000000010000000108060000001F15C4890000000A49444154789C63000100000500010D0A2DB40000000049454E44AE426082"
png_bytes = bytes.fromhex(png_hex)

path = "market_sniper_app/assets/textures/leather_midnight.png"
with open(path, "wb") as f:
    f.write(png_bytes)
print(f"Created {path}")
