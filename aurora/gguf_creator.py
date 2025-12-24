import logging
import sys
import argparse
import os
import numpy as np
from tqdm import tqdm
import gguf
import traceback

# Nastavenie logovania
def setup_logging(log_file: str) -> None:
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    for h in list(logger.handlers):
        logger.removeHandler(h)
    formatter = logging.Formatter(
        fmt="%(asctime)s - %(levelname)s - %(name)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
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
        logging.error(f"Failed to set up file logger '{log_file}': {e}")

# Argumenty
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="OLLAURA → GGUF konvertor")
    parser.add_argument("--weights-dir", type=str, required=True, help="Priečinok s váhami (.npy alebo .bin súbory)")
    parser.add_argument("--output", type=str, default="ollauro.gguf", help="Výstupný GGUF súbor")
    parser.add_argument("--dtype", type=str, choices=["f32", "f16"], default="f16", help="Typ dát (f16 je menší a rýchlejší)")
    parser.add_argument("--log-file", type=str, default="gguf_creation.log", help="Log súbor")
    return parser.parse_args()

# Očakávané tenzory pre OLLAURA model
def get_expected_tensors() -> dict[str, tuple[int, ...]]:
    expected = {}
    expected["token_embedding.weight"] = (50257, 4096)
    expected["position_embedding.rope.theta"] = (128,)
    expected["final_norm.weight"] = (4096,)
    expected["lm_head.weight"] = (50257, 4096)
    num_layers = 32
    for i in range(num_layers):
        p = f"model.layers.{i}"
        expected[f"{p}.attention_norm.weight"] = (4096,)
        expected[f"{p}.ffn_norm.weight"] = (4096,)
        expected[f"{p}.attention.wq.weight"] = (4096, 4096)
        expected[f"{p}.attention.wk.weight"] = (4096, 1024)
        expected[f"{p}.attention.wv.weight"] = (4096, 1024)
        expected[f"{p}.attention.wo.weight"] = (4096, 4096)
        expected[f"{p}.ffn_gate.weight"] = (11008, 4096)
        expected[f"{p}.ffn_down.weight"] = (4096, 11008)
        expected[f"{p}.ffn_up.weight"] = (11008, 4096)
    return expected

# Validácia tvaru
def validate_shape(name: str, actual: tuple[int, ...], expected: tuple[int, ...]) -> None:
    if name == "position_embedding.rope.theta" and actual in [(128,), (64,)]:
        return
    if len(actual) != len(expected):
        raise ValueError(f"Rank mismatch pre {name}: {actual} vs {expected}")
    for i, (a, e) in enumerate(zip(actual, expected)):
        if abs(a - e) > 1:
            raise ValueError(f"Rozmer {i} mismatch pre {name}: {a} vs ~{e}")

# Načítanie .npy alebo .bin
def load_tensor(weights_dir: str, name: str, expected_shape: tuple[int, ...], target_dtype: str) -> np.ndarray:
    logger = logging.getLogger("load")
    base = os.path.join(weights_dir, name.replace(".", "_"))
    npy_path = base + ".npy"
    bin_path = base + ".bin"

    for path, is_npy in [(npy_path, True), (bin_path, False)]:
        if not os.path.isfile(path):
            continue
        try:
            logger.info("Načítavam %s z %s", name, path)
            if is_npy:
                arr = np.load(path, allow_pickle=False)
            else:
                np_dtype = np.float32 if target_dtype == "f32" else np.float16
                count = int(np.prod(expected_shape))
                arr = np.fromfile(path, dtype=np_dtype.newbyteorder("<"), count=count)
                if arr.size != count:
                    raise ValueError(f"Veľkosť nesedí: {arr.size} vs {count}")
                arr = arr.reshape(expected_shape)
            validate_shape(name, arr.shape, expected_shape)
            if target_dtype == "f32" and arr.dtype != np.float32:
                arr = arr.astype(np.float32)
            elif target_dtype == "f16" and arr.dtype != np.float16:
                arr = arr.astype(np.float16)
            return arr
        except Exception as e:
            logger.warning("Chyba pri %s: %s", path, e)

    raise RuntimeError(f"Nenašiel sa platný súbor pre tensor '{name}' (skús {npy_path} alebo {bin_path})")

# Metadata
def add_metadata(writer: gguf.GGUFWriter, dtype: str) -> None:
    writer.add_string("general.architecture", "ollaura")
    writer.add_uint32("general.file_type", 1 if dtype == "f16" else 0)
    writer.add_string("general.name", "OLLAURA Custom")
    writer.add_string("general.description", "Original transformer LLM from scratch")
    writer.add_string("general.license", "custom")
    writer.add_uint32("ollauro.vocab_size", 50257)
    writer.add_uint32("ollauro.context_length", 8192)
    writer.add_uint32("ollauro.embedding_dim", 4096)
    writer.add_uint32("ollauro.num_layers", 32)
    writer.add_uint32("ollauro.num_heads", 32)
    writer.add_uint32("ollauro.head_dim", 128)
    writer.add_uint32("ollauro.ffn_hidden_dim", 11008)
    writer.add_float32("ollauro.rope_theta", 10000.0)
    writer.add_bool("ollauro.use_rope", True)
    writer.add_string("ollauro.norm_type", "rms")
    writer.add_string("ollauro.activation", "swiglu")
    writer.add_string("ollauro.tokenizer_type", "bpe")

# Hlavná funkcia
def main() -> int:
    args = parse_args()
    setup_logging(args.log_file)
    log = logging.getLogger("main")
    log.info("Štartujem konverziu OLLAURA → GGUF")
    log.info(f"Parametre: dir={args.weights_dir}, out={args.output}, dtype={args.dtype}")

    if not os.path.isdir(args.weights_dir):
        log.error("Priečinok s váhami neexistuje!")
        return 1

    expected = get_expected_tensors()
    writer = gguf.GGUFWriter(args.output, "OLLAURA GGUF")
    add_metadata(writer, args.dtype)

    ggml_type = gguf.GGMLQuantizationType.F16 if args.dtype == "f16" else gguf.GGMLQuantizationType.F32

    for name in tqdm(expected, desc="Pridávam tenzory"):
        tensor = load_tensor(args.weights_dir, name, expected[name], args.dtype)
        writer.add_tensor(name, tensor, tensor_type=ggml_type)

    writer.close()
    log.info(f"Hotovo! GGUF uložený ako {args.output}")

    # Validácia
    try:
        reader = gguf.GGUFReader(args.output)
        log.info(f"Validácia OK: {len(reader.tensors)} tenzorov")
    except Exception as e:
        log.warning(f"Validácia zlyhala: {e}")

    return 0

if __name__ == "__main__":
    sys.exit(main())
