#!/bin/bash
#SBATCH --job-name=align-adapt-train
#SBATCH --account=mscbdtsuperpod
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=80G
#SBATCH --gpus-per-node=1
#SBATCH --time=24:00:00
#SBATCH --output=alignment-adaptive-train-%j.out
#SBATCH --error=alignment-adaptive-train-%j.err

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DORABOT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${DORABOT_ROOT}/.." && pwd)"
PIPLAN_ROOT="${PIPLAN_ROOT:-${PROJECT_ROOT}/PiPlan}"

CONDA_BIN="${CONDA_BIN:-conda}"
CONDA_ENV="${CONDA_ENV:-dorabot}"

RUN_NAME="${RUN_NAME:-jointbc_taskaware_alignment_adaptive}"
DATASET_ROOT="${DATASET_ROOT:-${DORABOT_ROOT}/src/converted/${RUN_NAME}_lerobot_images}"
DATASET_REPO_ID="${DATASET_REPO_ID:-local/dorabot-pi05-alignment-adaptive}"
OUTPUT_DIR="${OUTPUT_DIR:-outputs/train/piplan_pi05_alignment_adaptive}"
POLICY_PRETRAINED_PATH="${POLICY_PRETRAINED_PATH:-lerobot/pi05_base}"
STEPS="${STEPS:-20000}"
BATCH_SIZE="${BATCH_SIZE:-1}"

export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-0}"
export HF_HOME="${HF_HOME:-${PROJECT_ROOT}/.hf_cache}"
export HF_DATASETS_CACHE="${HF_DATASETS_CACHE:-${PROJECT_ROOT}/.hf_datasets_cache}"
export PYTHONPATH="${PROJECT_ROOT}/lerobot/src:${PYTHONPATH:-}"

if [ ! -d "${PIPLAN_ROOT}" ]; then
  echo "PiPlan directory not found: ${PIPLAN_ROOT}" >&2
  echo "Expected layout: PROJECT_ROOT/PiPlan next to PROJECT_ROOT/6000_Dorabot." >&2
  exit 1
fi

if [ ! -d "${DATASET_ROOT}" ]; then
  echo "Dataset root not found: ${DATASET_ROOT}" >&2
  echo "Run slurm/generate_convert_alignment_adaptive.sbatch first, or set DATASET_ROOT." >&2
  exit 1
fi

cd "${PIPLAN_ROOT}"

echo "[alignment-adaptive:train] PiPlan root: ${PIPLAN_ROOT}"
echo "[alignment-adaptive:train] Dataset root: ${DATASET_ROOT}"
echo "[alignment-adaptive:train] Output dir: ${PIPLAN_ROOT}/${OUTPUT_DIR}"

"${CONDA_BIN}" run --no-capture-output -n "${CONDA_ENV}" \
  python -u scripts/train_pi05.py \
    --dataset-repo-id "${DATASET_REPO_ID}" \
    --dataset-root "${DATASET_ROOT}" \
    --output-dir "${OUTPUT_DIR}" \
    --policy-pretrained-path "${POLICY_PRETRAINED_PATH}" \
    --steps "${STEPS}" \
    --batch-size "${BATCH_SIZE}" \
    --device cuda \
    --no-compile-model

echo "[alignment-adaptive:train] Done."
