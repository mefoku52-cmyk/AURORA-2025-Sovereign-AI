#!/usr/bin/env python3
import gguf
import numpy as np
from tqdm import tqdm
import argparse
import os
import logging
import sys
import traceback
from typing import Dict, Tuple, Any, List

def setup_logging(log_file: str) -> None:
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    for h in list(logger.handlers):
        logger.removeHandler(h)
    formatter = logging.Formatter(fmt="%(asctime)s - %(levelname)s - %(name)s - %(message)s", datefmt="%Y-%m-%d %H:%M:%S")
    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(logging.INFO)
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    try:
        fh = logging.FileHandler(log_file, mode="a", encoding="utf-8")
        fh.setLevel(logging.INFO)
        fh.setFormatter(formatter)
        logger.addHandler(fh)
    except Exception as e:
        logging.error("Failed to set up file logger '%s': %s", log_file, e)

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create a GGUF file for the custom OLLAURA model with robust error handling.")
    parser.add_argument("--weights-dir", type=str, required=True, help="Path to directory containing weight tensors (.npy or .bin).")
    parser.add_argument("--output", type=str, default="ollauro.gguf", help="Output GGUF file path (default: ollauro.gguf).")
    parser.add_argument("--dtype", type=str, choices=["f32", "f16"], default="f16", help="Target tensor dtype for GGUF (f32 or f16, default: f16).")
    parser.add_argument("--log-file", type=str, default="gguf_creation.log", help="Optional log file path (default: gguf_creation.log).")
    return parser.parse_args()

def get_expected_tensors() -> Dict[str, Tuple[int, ...]]:
    expected: Dict[str, Tuple[int, ...]] = {}
    expected["token_embedding.weight"] = (50257, 4096)
    expected["position_embedding.rope.theta"] = (128,)
    expected["final_norm.weight"] = (4096,)
    expected["lm_head.weight"] = (50257, 4096)
    num_layers = 32
    for i in range(num_layers):
        prefix = f"model.layers.{i}"
        expected[f"{prefix}.attention_norm.weight"] = (4096,)
        expected[f"{prefix}.ffn_norm.weight"] = (4096,)
        expected[f"{prefix}.attention.wq.weight"] = (4096, 4096)
        expected[f"{prefix}.attention.wk.weight"] = (4096, 1024)
        expected[f"{prefix}.attention.wv.weight"] = (4096, 1024)
        expected[f"{prefix}.attention.wo.weight"] = (4096, 4096)
        expected[f"{prefix}.ffn_gate.weight"] = (11008, 4096)
        expected[f"{prefix}.ffn_down.weight"] = (4096, 11008)
        expected[f"{prefix}.ffn_up.weight"] = (11008, 4096)
    return expected

def validate_shape(name: str, actual: Tuple[int, ...], expected: Tuple[int, ...], allow_alt_rope: bool = True) -> None:
    if name == "position_embedding.rope.theta" and allow_alt_rope:
        if actual in [(128,), (64,)]:
            return
        raise ValueError(f"Tensor '{name}' has invalid shape {actual}, expected (128,) or (64,).")
    if len(actual) != len(expected):
        raise ValueError(f"Tensor '{name}' rank mismatch: got {len(actual)}, expected {len(expected)} (shape {actual} vs expected {expected}).")
    for i, (a, e) in enumerate(zip(actual, expected)):
        if abs(a - e) > 1:
            raise ValueError(f"Tensor '{name}' dimension {i} mismatch: got {a}, expected approx {e} (tolerance ±1, shape {actual} vs expected {expected}).")

def load_tensor_npy(path: str) -> np.ndarray:
    try:
        arr = np.load(path, allow_pickle=False)
        if not isinstance(arr, np.ndarray):
            raise TypeError(f"Loaded object from '{path}' is not a NumPy array.")
        return arr
    except Exception as e:
        raise RuntimeError(f"Failed to load tensor from .npy file '{path}': {e}") from e

def load_tensor_bin(path: str, shape: Tuple[int, ...], dtype: np.dtype) -> np.ndarray:
    try:
        count = int(np.prod(shape))
        dt = np.dtype(dtype).newbyteorder("<")
        arr = np.fromfile(path, dtype=dt, count=count)
        if arr.size != count:
            raise ValueError(f"Binary file '{path}' has {arr.size} elements, expected {count}.")
        arr = arr.reshape(shape)
        return arr
    except Exception as e:
        raise RuntimeError(f"Failed to load tensor from .bin file '{path}': {e}") from e

def load_tensor(weights_dir: str, name: str, expected_shape: Tuple[int, ...], target_dtype: str) -> np.ndarray:
    logger = logging.getLogger("load_tensor")
    base_path = os.path.join(weights_dir, name.replace(".", "_"))
    npy_path = base_path + ".npy"
    bin_path = base_path + ".bin"
    last_error = None

    if os.path.isfile(npy_path):
        try:
            logger.info("Loading tensor '%s' from '%s' (.npy).", name, npy_path)
            arr = load_tensor_npy(npy_path)
            validate_shape(name, tuple(arr.shape), expected_shape)
            return cast_tensor_dtype(arr, target_dtype)
        except Exception as e:
            logger.error("Error loading '%s' from npy: %s", name, e)
            last_error = e

    if os.path.isfile(bin_path):
        try:
            logger.info("Loading tensor '%s' from '%s' (.bin).", name, bin_path)
            np_dtype = np.float32 if target_dtype == "f32" else np.float16
            arr = load_tensor_bin(bin_path, expected_shape, np_dtype)
            validate_shape(name, tuple(arr.shape), expected_shape)
            return cast_tensor_dtype(arr, target_dtype)
        except Exception as e:
            logger.error("Error loading '%s' from bin: %s", name, e)
            last_error = e

    msg = f"Failed to load tensor '{name}'. Tried npy='{npy_path}', bin='{bin_path}'. Last error: {last_error}"
    raise RuntimeError(msg)

def cast_tensor_dtype(arr: np.ndarray, target_dtype: str) -> np.ndarray:
    logger = logging.getLogger("cast_tensor_dtype")
    if target_dtype == "f32":
        if arr.dtype != np.float32:
            logger.info("Casting tensor from %s to float32.", arr.dtype)
            return arr.astype(np.float32)
    elif target_dtype == "f16":
        if arr.dtype != np.float16:
            logger.info("Casting tensor from %s to float16.", arr.dtype)
            return arr.astype(np.float16)
    return arr

def get_ggml_dtype(target_dtype: str) -> gguf.GGMLQuantizationType:
    if target_dtype == "f32":
        return gguf.GGMLQuantizationType.F32
    if target_dtype == "f16":
        return gguf.GGMLQuantizationType.F16
    raise ValueError(f"Unsupported GGUF dtype mapping for '{target_dtype}'.")

def get_general_file_type(target_dtype: str) -> int:
    if target_dtype == "f32":
        return 0
    if target_dtype == "f16":
        return 1
    return 0

def add_metadata(writer: gguf.GGUFWriter, target_dtype: str) -> None:
    writer.add_metadata("general.architecture", "ollaura")
    writer.add_metadata("general.file_type", np.uint32(get_general_file_type(target_dtype)))
    writer.add_metadata("general.name", "OLLAURA Custom Model")
    writer.add_metadata("general.author", "OLLAURA Developer")
    writer.add_metadata("general.description", "Fully original transformer-based LLM built from scratch")
    writer.add_metadata("general.license", "custom")
    writer.add_metadata("ollauro.vocab_size", np.uint32(50257))
    writer.add_metadata("ollauro.context_length", np.uint32(8192))
    writer.add_metadata("ollauro.embedding_dim", np.uint32(4096))
    writer.add_metadata("ollauro.num_layers", np.uint32(32))
    writer.add_metadata("ollauro.num_heads", np.uint32(32))
    writer.add_metadata("ollauro.head_dim", np.uint32(128))
    writer.add_metadata("ollauro.ffn_hidden_dim", np.uint32(11008))
    writer.add_metadata("ollauro.rope_theta", np.float32(10000.0))
    writer.add_metadata("ollauro.use_rope", True)
    writer.add_metadata("ollauro.norm_type", "rms")
    writer.add_metadata("ollauro.activation", "swiglu")
    writer.add_metadata("ollauro.tokenizer_type", "bpe")

def add_tensors_to_writer(writer: gguf.GGUFWriter, weights_dir: str, expected_tensors: Dict[str, Tuple[int, ...]], target_dtype: str) -> None:
    logger = logging.getLogger("add_tensors")
    tensor_names = list(expected_tensors.keys())
    ggml_dtype = get_ggml_dtype(target_dtype)
    for name in tqdm(tensor_names, desc="Adding tensors to GGUF", unit="tensor"):
        expected_shape = expected_tensors[name]
        try:
            tensor = load_tensor(weights_dir, name, expected_shape, target_dtype)
            writer.add_tensor(name, tensor, tensor_type=ggml_dtype)
        except Exception as e:
            logger.error("Failed to load/add tensor '%s': %s\n%s", name, e, traceback.format_exc())
            raise

def validate_gguf_file(path: str) -> None:
    logger = logging.getLogger("validate_gguf")
    try:
        reader = gguf.GGUFReader(path)
        tensor_count = len(reader.tensors)
        total_bytes = 0
        tensor_names = []
        for t in reader.tensors:
            tensor_names.append(t.name)
            try:
                shape = t.shape
                qtype = t.tensor_type
                elem_size = 4 if qtype == gguf.GGMLQuantizationType.F32 else 2 if qtype == gguf.GGMLQuantizationType.F16 else 2
                numel = 1
                for d in shape:
                    numel *= int(d)
                total_bytes += numel * elem_size
            except Exception:
                continue
        total_gb = total_bytes / (1024 ** 3) if total_bytes > 0 else 0.0
        logger.info("GGUF validation summary for '%s':", path)
        logger.info("  Tensors: %d", tensor_count)
        logger.info("  Approx total size: %.3f GB", total_gb)
        logger.info("  Tensor names (first 10): %s", tensor_names[:10])
    except Exception as e:
        logger.error("GGUF validation failed for '%s': %s\n%s", path, e, traceback.format_exc())

def main() -> int:
    try:
        args = parse_args()
    except SystemExit:
        return 1
    except Exception as e:
        print(f"Argument parsing failed: {e}", file=sys.stderr)
        return 1

    setup_logging(args.log_file)
    logger = logging.getLogger("main")
    logger.info("Starting OLLAURA GGUF creation with args: %s", vars(args))

    if not os.path.isdir(args.weights_dir):
        logger.error("Weights directory '%s' does not exist or is not a directory.", args.weights_dir)
        return 1

    try:
        expected_tensors = get_expected_tensors()
        writer = gguf.GGUFWriter(args.output, "OLLAURA GGUF Writer")
        add_metadata(writer, args.dtype)
        add_tensors_to_writer(writer, args.weights_dir, expected_tensors, args.dtype)
        writer.close()
        logger.info("Successfully wrote GGUF file to '%s'.", args.output)
        validate_gguf_file(args.output)
        logger.info("OLLAURA GGUF creation completed successfully.")
        return 0
    except KeyboardInterrupt:
        logger.warning("Interrupted by user. Cleaning up...")
        try:
            writer.close()
        except:
            pass
        return 1
    except Exception as e:
        logger.error("Fatal error during GGUF creation: %s\n%s", e, traceback.format_exc())
        try:
            writer.close()
        except:
            pass
        return 1

if __name__ == "__main__":
    sys.exit(main())
