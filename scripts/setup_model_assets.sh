#!/usr/bin/env bash
set -euo pipefail

if ! command -v git-lfs >/dev/null 2>&1; then
  echo "[ERROR] git-lfs no está instalado."
  echo "Instala git-lfs y vuelve a ejecutar este script."
  exit 1
fi

git lfs install --local

git lfs pull --include="CoreMLProject/Resnet50.mlmodel"

MODEL_PATH="CoreMLProject/Resnet50.mlmodel"
MODEL_SIZE=$(wc -c < "$MODEL_PATH")

echo "Modelo listo: $MODEL_PATH ($MODEL_SIZE bytes)"
