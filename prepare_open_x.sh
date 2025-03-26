: '
Script for downloading, cleaning and resizing Open X-Embodiment Dataset (https://robotics-transformer-x.github.io/)

Performs the preprocessing steps:
  1. Downloads datasets from Open X-Embodiment
  2. Runs resize function to convert all datasets to 256x256 (if image resolution is larger) and jpeg encoding
  3. Fixes channel flip errors in a few datasets, filters success-only for QT-Opt ("kuka") data

To reduce disk memory usage during conversion, we download the datasets 1-by-1, convert them
and then delete the original.
We specify the number of parallel workers below -- the more parallel workers, the faster data conversion will run.
Adjust workers to fit the available memory of your machine, the more workers + episodes in memory, the faster.
The default values are tested with a server with ~120GB of RAM and 24 cores.
'

DOWNLOAD_DIR=/data2/lzixuan/rfm_dataset/test/oxe
CONVERSION_DIR=/data2/lzixuan/rfm_dataset/test/conversion
N_WORKERS=20                  # number of workers used for parallel conversion --> adjust based on available RAM
MAX_EPISODES_IN_MEMORY=200    # number of episodes converted in parallel --> adjust based on available RAM

# increase limit on number of files opened in parallel to 20k --> conversion opens up to 1k temporary files
# in /tmp to store dataset during conversion
ulimit -n 20000

echo "!!! Warning: This script downloads the Bridge dataset from the Open X-Embodiment bucket, which is currently outdated !!!"
echo "!!! Instead download the bridge_dataset from here: https://rail.eecs.berkeley.edu/datasets/bridge_release/data/tfds/ !!!"

# format: [dataset_name, dataset_version, transforms]
DATASET_TRANSFORMS=(
    # Datasets used for OpenVLA: https://openvla.github.io/
    # "fractal20220817_data 0.1.0 resize_and_jpeg_encode" # 111.1 98
    # "bridge 0.1.0 resize_and_jpeg_encode"  
    # "kuka 0.1.0 resize_and_jpeg_encode,filter_success" # 778.0 70
    "taco_play 0.1.0 resize_and_jpeg_encode" # 47.8 126
    # "jaco_play 0.1.0 resize_and_jpeg_encode" # 9.2 3.0
    # "berkeley_cable_routing 0.1.0 resize_and_jpeg_encode" # 4.7 3.3
    # "roboturk 0.1.0 resize_and_jpeg_encode" # 45.4 4.5
    # "viola 0.1.0 resize_and_jpeg_encode" # 10.4 3.2
    # "berkeley_autolab_ur5 0.1.0 resize_and_jpeg_encode,flip_wrist_image_channels" # 76.4 20
    # "toto 0.1.0 resize_and_jpeg_encode" # 127.7 11
    # "language_table 0.1.0 resize_and_jpeg_encode" # 399.9 194
    # "stanford_hydra_dataset_converted_externally_to_rlds 0.1.0 resize_and_jpeg_encode,flip_wrist_image_channels,flip_image_channels" # 72.5 16
    # "austin_buds_dataset_converted_externally_to_rlds 0.1.0 resize_and_jpeg_encode" # 1.5 1.2
    # "nyu_franka_play_dataset_converted_externally_to_rlds 0.1.0 resize_and_jpeg_encode" # 5.2 13
    # "furniture_bench_dataset_converted_externally_to_rlds 0.1.0 resize_and_jpeg_encode" # 115.0 141
    # "ucsd_kitchen_dataset_converted_externally_to_rlds 0.1.0 resize_and_jpeg_encode" # 1.3 (110M)
    # "austin_sailor_dataset_converted_externally_to_rlds 0.1.0 resize_and_jpeg_encode" # 18.8 14
    # "austin_sirius_dataset_converted_externally_to_rlds 0.1.0 resize_and_jpeg_encode" # 6.6 8.0
    # "bc_z 0.1.0 resize_and_jpeg_encode" # 80.5 128
    # "dlr_edan_shared_control_converted_externally_to_rlds 0.1.0 resize_and_jpeg_encode" # 3.1 (263M)
    # "iamlab_cmu_pickup_insert_converted_externally_to_rlds 0.1.0 resize_and_jpeg_encode" # 50.3 5.9
    # "utaustin_mutex 0.1.0 resize_and_jpeg_encode,flip_wrist_image_channels,flip_image_channels" # 20.8 16
    # "berkeley_fanuc_manipulation 0.1.0 resize_and_jpeg_encode,flip_wrist_image_channels,flip_image_channels" # 8.8 2.5
    # "cmu_stretch 0.1.0 resize_and_jpeg_encode" # (728M) (510M)
    # "dobbe 0.0.1 resize_and_jpeg_encode" # 67.6 22
    # "fmb 0.0.1 resize_and_jpeg_encode" # (1.2T) (1.2T)
    # "droid 1.0.0 resize_and_jpeg_encode"
)

for tuple in "${DATASET_TRANSFORMS[@]}"; do
  # Extract strings from the tuple
  strings=($tuple)
  DATASET=${strings[0]}
  VERSION=${strings[1]}
  TRANSFORM=${strings[2]}
  mkdir ${DOWNLOAD_DIR}/${DATASET}
  gsutil -m cp -n -r gs://gresearch/robotics/${DATASET}/${VERSION} ${DOWNLOAD_DIR}/${DATASET}
  python3 modify_rlds_dataset.py --dataset=$DATASET --data_dir=$DOWNLOAD_DIR --target_dir=$CONVERSION_DIR --mods=$TRANSFORM --n_workers=$N_WORKERS --max_episodes_in_memory=$MAX_EPISODES_IN_MEMORY
  rm -rf ${DOWNLOAD_DIR}/${DATASET}
  mv ${CONVERSION_DIR}/${DATASET} ${DOWNLOAD_DIR}
done
