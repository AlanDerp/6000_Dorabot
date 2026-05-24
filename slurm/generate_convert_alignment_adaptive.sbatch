#!/bin/bash
#SBATCH --job-name=align-adapt-data
#SBATCH --account=mscbdtsuperpod
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=03:30:00
#SBATCH --output=alignment-adaptive-data-%j.out
#SBATCH --error=alignment-adaptive-data-%j.err

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DORABOT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CONDA_BIN="${CONDA_BIN:-conda}"
CONDA_ENV="${CONDA_ENV:-dorabot}"

RUN_NAME="${RUN_NAME:-jointbc_taskaware_alignment_adaptive}"
MIX="${MIX:-RRTStar:VirtualForcePlanner:80,RRTStar:RVOPlanner:20}"
MINUTES="${MINUTES:-5}"
AGENTS="${AGENTS:-10}"
LOAD_PORTS="${LOAD_PORTS:-2}"
UNLOAD_PORTS="${UNLOAD_PORTS:-2}"
RECORD_FREQ="${RECORD_FREQ:-1}"
PLANNER_SEARCH_TIME="${PLANNER_SEARCH_TIME:-1.0}"
PROGRESS_INTERVAL="${PROGRESS_INTERVAL:-30}"

GEN_JSONL="data_samples/${RUN_NAME}.jsonl"
DATASET_ROOT="${DORABOT_ROOT}/src/converted/${RUN_NAME}_lerobot_images"
DATASET_REPO_ID="${DATASET_REPO_ID:-local/dorabot-pi05-alignment-adaptive}"

cd "${DORABOT_ROOT}"

echo "[alignment-adaptive:data] Dorabot root: ${DORABOT_ROOT}"
echo "[alignment-adaptive:data] JSONL: ${DORABOT_ROOT}/src/${GEN_JSONL}"
echo "[alignment-adaptive:data] Dataset root: ${DATASET_ROOT}"
echo "[alignment-adaptive:data] Dataset repo id: ${DATASET_REPO_ID}"

"${CONDA_BIN}" run --no-capture-output -n "${CONDA_ENV}" \
  python -u src/tools/generate_pi05_expert_dataset.py \
    --mix "${MIX}" \
    --minutes "${MINUTES}" \
    --agents "${AGENTS}" \
    --ports "${LOAD_PORTS}" "${UNLOAD_PORTS}" \
    --record-freq "${RECORD_FREQ}" \
    --planner-search-time "${PLANNER_SEARCH_TIME}" \
    --progress-interval "${PROGRESS_INTERVAL}" \
    --output "${GEN_JSONL}" \
    --overwrite

"${CONDA_BIN}" run --no-capture-output -n "${CONDA_ENV}" \
  python -u src/tools/convert_joint_bc_lerobot_stream.py \
    --input "${DORABOT_ROOT}/src/${GEN_JSONL}" \
    --output "${DATASET_ROOT}" \
    --repo_id "${DATASET_REPO_ID}" \
    --pad_state_dim 163 \
    --pad_action_dim 20 \
    --include_images \
    --progress-interval 10000 \
    --overwrite

echo "[alignment-adaptive:data] Done."
