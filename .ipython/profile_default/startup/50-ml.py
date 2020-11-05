# ml
import sklearn

# # # TF
# import tensorflow as tf
# import shutil as _shutil

# if _shutil.which("nvcc"):
#     if tf.__version__.split(".")[0] == "1":
#         from tensorflow import ConfigProto as _ConfigProto
#         from tensorflow import InteractiveSession as _InteractiveSession

#         _config = _ConfigProto()
#         _config.gpu_options.allow_growth = True
#         # session = _InteractiveSession(config=_config)
#     elif tf.__version__.split(".")[0] == "2":
#         gpu_devices = tf.config.experimental.list_physical_devices("GPU")
#         for device in gpu_devices:
#             tf.config.experimental.set_memory_growth(device, True)


# export CUDA_HOME=/usr/local/cuda-10.1
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-10.1/lib64:/usr/local/cudnn/lib64
# export LD_LIBRARY_PATH=${CUDA_HOME}/bin:${PATH}
# export PATH=/usr/local/cuda-10.1/bin:$PATH

# from jax import grad, vmap
