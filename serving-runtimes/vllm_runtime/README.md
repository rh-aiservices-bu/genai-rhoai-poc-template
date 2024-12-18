# vLLM Runtime

The [vLLM](https://docs.vllm.ai/en/latest/index.html) runtime can be used with Open Data Hub and OpenShift AI Single-Model Serving stack to serve Large Language Models (LLMs) as an alternative to Caikit+TGIS or standalone TGIS. Currently supported models are listed [here](https://docs.vllm.ai/en/latest/models/supported_models.html).

Note that as the standard runtime is specifically meant to run LLMs and uses custom kernels based on CUDA, a **GPU is required** to load models for this version.  
There is, however, also a **CPU version** that can load models on the CPU.

## Installation

You must first make sure that you have properly installed the necessary component of the Single-Model Serving stack, as documented [here](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2-latest/html/serving_models/serving-large-models_serving-large-models).

Once the stack is installed, adding the runtime is pretty straightforward:

- As an admin, in the OpenShift AI Dashboard, open the menu `Settings -> Serving runtimes`.
- Click on `Add serving runtime`.
- For the type of model serving platforms this runtime supports, select `Single model serving platform`.
- Upload the file `vllm-runtime.yaml` from the current folder, or click `Start from scratch` and copy/paste its content. A CPU-only version of the runtime is also available in the relevant file.

The runtime is now available when deploying a model.

## Model Deployment

This runtime can be used in the exact same way as the out of the box ones:

- Copy your model files in an object store bucket.
- Deploy the model from the Dashboard.
- Make sure you have added a GPU to your GPU configuration, that you have enough VRAM (GPU memory) to load the model, and that you have enough standard memory (RAM). Although the model loads into the GPU, RAM is still used for the pre-loading operations.
- Once the model is loaded, you can access the inference endpoint provided through the dashboard.

For CPU, note that the model has some limitations such as only being compatible with FP32 and BF16 - any FP16 model gets automatically converted to BF16. Read more about it in the official documentation [here](https://docs.vllm.ai/en/latest/getting_started/cpu-installation.html).  

## Usage

This implementation of the runtime provides an **OpenAI compatible API**. So any tool or library that can connect to OpenAI services will be able to consume the endpoint.

Python and Curl examples are provided [here](https://docs.vllm.ai/en/latest/getting_started/quickstart.html#using-openai-completions-api-with-vllm).

You can also find a notebook example using Langchain to query vLLM in this repo [here](../../examples/notebooks/langchain/Langchain-vLLM-Prompt-memory.ipynb).

Also, vLLM provides a full Swagger UI where you can get the full documentation of the API (methods, parameters), and try it directly without any coding,... It is accessible at the address `https://your-endpoint-address/docs`.
