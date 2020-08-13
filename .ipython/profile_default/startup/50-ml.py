# ml
import sklearn

# # for TFv2:
import tensorflow as tf
from tensorflow.compat.v1 import ConfigProto as _ConfigProto
from tensorflow.compat.v1 import InteractiveSession as _InteractiveSession

_config = _ConfigProto()
_config.gpu_options.allow_growth = True
session = _InteractiveSession(config=_config)

# export CUDA_HOME=/usr/local/cuda-10.1
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-10.1/lib64:/usr/local/cudnn/lib64
# export LD_LIBRARY_PATH=${CUDA_HOME}/bin:${PATH}
# export PATH=/usr/local/cuda-10.1/bin:$PATH

from jax import grad, vmap
