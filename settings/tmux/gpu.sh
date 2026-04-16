#!/usr/bin/env bash

mode="$1"

# NVIDIA
if command -v nvidia-smi >/dev/null 2>&1; then
    if [ "$mode" = "load" ]; then
        nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1 | awk '{print $1"%"}'
    elif [ "$mode" = "vram" ]; then
        nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | head -n1 | awk '{printf "%s/%sMB", $1, $2}'
    fi
    exit 0
fi

# AMD ROCm
if command -v rocm-smi >/dev/null 2>&1; then
    if [ "$mode" = "load" ]; then
        rocm-smi --showuse | grep GPU | awk '{print $4"%"}'
    elif [ "$mode" = "vram" ]; then
        rocm-smi --showmemuse | grep GPU | awk '{print $5"/"$7"MB"}'
    fi
    exit 0
fi

# Intel GPU
if command -v intel_gpu_top >/dev/null 2>&1; then
    if [ "$mode" = "load" ]; then
        intel_gpu_top -J -s 200 | jq '.engines.render.busy' | head -n1 | awk '{print $1"%"}'
    elif [ "$mode" = "vram" ]; then
        echo "N/A"
    fi
    exit 0
fi

echo "N/A"
