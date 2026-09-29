{ writers }:

writers.writePython3Bin "claude-cleanup" { doCheck = false; } (
  builtins.readFile ./claude-cleanup.py
)
