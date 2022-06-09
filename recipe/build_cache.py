from subprocess import check_output, check_call
from pathlib import Path
import ast
import astor
import os
import shlex
import shutil

def extend_linkopts(kw, name):
    current_src = astor.to_source(kw.value)[:-1]
    kw.value = ast.parse(f"{current_src} + ['-l{name}']").body[0].value


def new_kwarg(name, code):
    return ast.keyword(arg="linkopts", value=ast.parse(code).body[0].value)

def srcs_has_code(srcs):
    if not isinstance(srcs, ast.List):
        return True
    for src in srcs.elts:
        if not isinstance(src, ast.Constant):
            return True
        if not src.value.endswith(".h"):
            return True
    return False


def find_binaries(code, symbol):
    mangled = symbol[2:].replace("/", "_")
    tree = ast.parse(code)
    libs_to_copy = []
    targets_to_build = set()
    for node in ast.walk(tree):
        # Find all function calls
        if isinstance(node, ast.Expr) and isinstance(node.value, ast.Call):
            if node.value.func.id == "cc_library":
                # Determine the name of the library
                name = srcs = alwayslink = None
                for kw in node.value.keywords:
                    if kw.arg == "name":
                        name = kw.value.value
                    elif kw.arg == "srcs":
                        srcs = kw.value
                    elif kw.arg == "alwayslink":
                        alwayslink = kw.value

                if alwayslink and isinstance(alwayslink, ast.Constant) and alwayslink.value:
                    continue
                    libext = '.lo'
                else:
                    libext = '.a'
                
                target = f"{symbol}:{name}"
                if target in build_candidates:
                    # Remove srcs
                    if srcs is not None and srcs_has_code(srcs):
                        targets_to_build.add(target)
                        libs_to_copy.append((f"{symbol[2:]}/lib{name}{libext}", f"lib{mangled}_{name}.a"))
    return targets_to_build, libs_to_copy


def rewrite_binaries(code, symbol, libs_copied):
    mangled = symbol[2:].replace("/", "_")
    tree = ast.parse(code)
    for node in ast.walk(tree):
        # Find all function calls
        if isinstance(node, ast.Expr) and isinstance(node.value, ast.Call):
            if node.value.func.id == "cc_library":
                # Determine the name of the library
                name = linkopts = alwayslink = None
                for kw in node.value.keywords:
                    if kw.arg == "name":
                        name = kw.value.value
                    elif kw.arg == "linkopts":
                        linkopts = kw
                    elif kw.arg == "alwayslink":
                        alwayslink = kw.value

                if alwayslink and isinstance(alwayslink, ast.Constant) and alwayslink.value:
                    libext = '.lo'
                else:
                    libext = '.a'
                
                libname = f"{symbol[2:]}/lib{name}{libext}"
                if libname in libs_copied:
                    # Remove srcs and alwayslink
                    node.value.keywords = [kw for kw in node.value.keywords if kw.arg not in ["srcs", "alwayslink"]]
                    if linkopts is None:
                        node.value.keywords.append(new_kwarg("linkopts", f"['-l{mangled}_{name}']"))
                    else:
                        extend_linkopts(linkopts, f"{mangled}_{name}")
    return astor.to_source(tree)


build_candidates = set()
for dep in Path("graph.in").read_text().split("\n"):
    if "->" in dep:
        targets = dep.split("->")[1].strip(' "').split("\\n")
        for target in targets:
            if target.startswith("//tensorflow/core"):
                build_candidates.add(target)
                
build_files = {c.split(':')[0] for c in build_candidates}

nonexistent_libs = set()
for bs in build_files:
    if bs.startswith('//tensorflow/core/kernels'):
        continue
    if bs in {'//tensorflow/core/grappler/graph_analyzer', '//tensorflow/core/common_runtime/eager'}:
        continue
    if 'tpu' in bs or 'windows' in bs:
        continue
    # Slowly expand the scope here
    if not (bs.startswith('//tensorflow/core/grap') or bs.startswith("//tensorflow/core/common_runtime")):
        print(f"!! Skipping {bs}")
        continue
    targets, libs_to_copy = find_binaries((Path(bs[2:]) / 'BUILD').read_text(), bs)
    print(f"!! Building {bs} targets: {targets}")
    check_call(["bazel"] + shlex.split(os.environ.get("BAZEL_OPTS", "")) + ["build"] + shlex.split(os.environ.get('BUILD_OPTS', "")) + list(targets))
    libs_copied = set()
    for lib, target_loc in libs_to_copy:
        src = Path('bazel-bin') / lib
        if src.exists():
            libs_copied.add(lib)
            shutil.copyfile(Path('bazel-bin') / lib, Path(os.environ['PREFIX']) / 'lib' / target_loc)
        else:
            nonexistent_libs.add(lib)

    code = rewrite_binaries((Path(bs[2:]) / 'BUILD').read_text(), bs, libs_copied)
    target_dir = Path(os.environ['PREFIX']) / 'share' / 'tensorflow-build-cache'/ bs[2:]
    if not target_dir.exists():
        target_dir.mkdir(parents=True)
    (target_dir / 'BUILD').write_text(code)

print("Nonexistent libraries:\n  " + "\n  ".join(nonexistent_libs))
