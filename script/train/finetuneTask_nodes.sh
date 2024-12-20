#!/bin/bash
export CUDA_DEVICE_MAX_CONNECTIONS=1
DIR=`pwd`


export NCCL_SOCKET_IFNAME=eth0
export NCCL_IB_DISABLE=0
export NCCL_IB_GID_INDEX=3
#export NCCL_IB_HCA=mlx5_2:1,mlx5_2:1
#export NCCL_IB_SL=3
#export NCCL_CHECKS_DISABLE=1
export NCCL_P2P_DISABLE=0
#export NCCL_LL_THRESHOLD=16384
export NCCL_IB_CUDA_SUPPORT=1
export NCCL_DEBUG=INFO

INDEX=2
MASTER_ADDR="10.206.0.199"
# communication on taiji platform
DISTRIBUTED_ARGS="
    --nproc_per_node 8 \
    --nnodes 3 \
    --node_rank $INDEX \
    --master_addr $MASTER_ADDR \
    --master_port 9999
"
export NCCL_TIMEOUT=25200
MODEL_TYPE=mixtral-8x7b
OUTPUT_DIR=$1
OUTPUT_DIR_FT=${OUTPUT_DIR}/llava-s3-finetune_task
mkdir -p ${OUTPUT_DIR_FT}

torchrun $DISTRIBUTED_ARGS vita/train/train.py \
    --deepspeed ./script/deepspeed/zero3.json \
    --model_name_or_path /mnt/cfs/lhj/videomllm_ckpt/outputs/vita_video_audio_0823/llava-s2-pretrain_video/0823ckpt5400/ \
    --model_type $MODEL_TYPE \
    --version mixtral_two \
    --dataset_use Pretrain_video \
    --vision_tower /mnt/cfs/lhj/model_weights/InternViT-300M-448px \
    --mm_projector_type mlp2x_gelu \
    --audio_encoder /mnt/cfs/lhj/model_weights/audio-encoder-2wh_zh_en_audioset_Mixtral-8x7B_New-base-tunning \
    --freeze_audio_encoder True \
    --freeze_audio_encoder_adapter True \
    --image_aspect_ratio square \
    --group_by_modality_length False \
    --bf16 True \
    --output_dir ${OUTPUT_DIR_FT} \
    --num_train_epochs 1 \
    --per_device_train_batch_size 6 \
    --per_device_eval_batch_size 4 \
    --gradient_accumulation_steps 2 \
    --evaluation_strategy "no" \
    --save_strategy "steps" \
    --save_steps 500 \
    --save_total_limit 2 \
    --learning_rate 2e-5 \
    --weight_decay 0. \
    --warmup_ratio 0.03 \
    --lr_scheduler_type "cosine" \
    --logging_steps 1 \
    --tf32 True \
    --model_max_length 9100 \
    --ddp_timeout 25200 \
    --gradient_checkpointing True \
    --dataloader_num_workers 4 \
    --lazy_preprocess True \
    --report_to none \
    2>&1 | tee -a ${OUTPUT_DIR_FT}/log_node_$INDEX.txt && echo "Done."


