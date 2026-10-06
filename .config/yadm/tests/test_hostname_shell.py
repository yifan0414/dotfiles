"""Exercise real yadm alternates and automatic zsh startup in isolated homes."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
YADM = shutil.which("yadm")
GIT = shutil.which("git")
ZSH = shutil.which("zsh")
HOSTS = ("nlp3090-2", "nlp3090-4", "nlp4090-8")
NCCL_VALUES = {
    "NCCL_CUMEM_ENABLE": "1", "NCCL_P2P_LEVEL": "SYS", "NCCL_P2P_DISABLE": "0",
    "NCCL_LOCAL_REGISTER": "0", "NCCL_GRAPH_REGISTER": "0",
}


@unittest.skipUnless(YADM and GIT and ZSH, "real yadm, git and zsh are required")
class HostnameShellTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="yadm-hostname-")
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        self.home = self.base / "home with spaces"
        self.home.mkdir()
        self.hdd = self.base / "hdd1_4t"
        self.ssd = self.base / "ssd_2t"
        self.cuda = self.base / "cuda-12.8"
        self.tools = self.base / "fixture tools"
        self.runtime = self.base / "active Node runtime/bin"
        self.conda = self.base / "fixture Conda"
        for directory in (self.tools, self.runtime, self.cuda / "bin",
                          self.hdd / "yifan/shared/env", self.hdd / "yifan/lmms-eval",
                          self.ssd / "yifan", self.ssd / "shared/models", self.conda / "etc/profile.d"):
            directory.mkdir(parents=True)
        self.shared_paths = self.hdd / "yifan/shared/env/shared_paths.sh"
        self.shared_paths.write_text("export FIXTURE_SHARED_PATHS=loaded\n")
        self.executable(self.tools / "tty", "printf '/dev/null\\n'\n")
        self.executable(self.tools / "node", "printf 'old-node\\n'\n")
        self.executable(self.tools / "codex", "printf 'old-codex\\n'\n")
        self.executable(self.runtime / "node", "printf 'active-node\\n'\n")
        self.executable(self.runtime / "codex", "printf 'active-codex\\n'\n")
        self.executable(self.cuda / "bin/nvcc", "printf 'fixture-nvcc\\n'\n")
        self.executable(self.tools / "direnv", """
if [ "$1 $2" != 'hook zsh' ]; then exit 1; fi
printf 'export FIXTURE_DIRENV=loaded\n'
""")
        (self.home / ".oh-my-zsh").mkdir()
        (self.home / ".oh-my-zsh/oh-my-zsh.sh").write_text("# safe fixture OMZ\n")
        (self.home / ".nvm").mkdir()
        (self.home / ".nvm/nvm.sh").write_text('export PATH="$FIXTURE_RUNTIME_BIN:$PATH"\n')
        (self.conda / "etc/profile.d/conda.sh").write_text("export FIXTURE_CONDA=loaded\n")

        self.config = self.home / ".config/yadm"
        self.data = self.home / ".local/share/yadm"
        self.repo = self.data / "repo.git"
        self.config.mkdir(parents=True)
        self.data.mkdir(parents=True)
        replacements = {"/hdd1_4t": str(self.hdd), "/ssd_2t": str(self.ssd),
                        "/usr/local/cuda-12.8": str(self.cuda)}
        candidates = [".zshrc##os.Linux", ".zshrc##os.Darwin",
                      *(".zshrc.local##hostname." + host for host in HOSTS)]
        for name in candidates:
            destination = self.home / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            source = ROOT / name
            contents = source.read_text()
            for fixed, fixture in replacements.items():
                contents = contents.replace(fixed, fixture)
            destination.write_text(contents)
        shutil.copyfile(ROOT / ".zshenv", self.home / ".zshenv")
        # yadm also selects alternates from encrypt's include list. This gives
        # its real selector the fixture candidates without staging anything.
        (self.config / "encrypt").write_text("\n".join(candidates) + "\n")
        self.env = {
            "HOME": str(self.home), "PATH": "/usr/bin:/bin", "LC_ALL": "C", "TERM": "dumb",
            "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull,
            "DOTFILES_CONDA_ROOT": str(self.conda), "FIXTURE_RUNTIME_BIN": str(self.runtime),
            "FIXTURE_CUDA_BIN": str(self.cuda / "bin"), "HOMEBREW_PREFIX": str(self.base / "brew"),
        }
        self.yadm("init")

    def executable(self, path, body):
        path.write_text("#!/bin/sh\n" + body)
        path.chmod(0o755)

    def yadm(self, *args):
        result = subprocess.run([YADM, "--yadm-dir", str(self.config), "--yadm-data", str(self.data),
                                 "--yadm-repo", str(self.repo), *args],
                                env=self.env, cwd=self.home, text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def select(self, host, system="Linux"):
        for key, value in (("local.hostname", host), ("local.os", system)):
            result = subprocess.run([GIT, "config", "--file", str(self.repo / "config"), key, value],
                                    env=self.env, cwd=self.home, text=True, capture_output=True, timeout=5)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.yadm("alt")
        self.assertEqual((self.home / ".zshrc").resolve(), self.home / (".zshrc##os." + system))

    def shell(self, extra=""):
        names = ["MODEL_NAME", "UV_CACHE_DIR", "UV_LINK_MODE", "CUDA_HOME", "LD_LIBRARY_PATH", "HF_ENDPOINT",
                 "HF_HUB_CACHE", "HF_DATASETS_CACHE", "NO_PROXY", "no_proxy", "HF_XET_LOG_DIR",
                 "FIXTURE_DIRENV", "FIXTURE_SHARED_PATHS", "FIXTURE_CONDA",
                 "AM_HOME", "NEMU_HOME", "NAVY_HOME", "NPC_HOME", *NCCL_VALUES]
        report = """
for fixture_name in %s; do
  print -r -- "$fixture_name=${(P)fixture_name}"
done
print -r -- "SHELL_UMASK=$(umask)"
print -r -- "NODE_PATH=$(command -v node)"
print -r -- "CODEX_PATH=$(command -v codex)"
print -r -- "NODE_VALUE=$(node)"
print -r -- "CODEX_VALUE=$(codex)"
print -r -- "NVCC_PATH=$(command -v nvcc 2>/dev/null)"
fixture_cuda_count=0
for fixture_path in $path; do
  [[ "$fixture_path" == "$FIXTURE_CUDA_BIN" ]] && (( fixture_cuda_count += 1 ))
done
print -r -- "CUDA_PATH_COUNT=$fixture_cuda_count"
""" % " ".join(names)
        env = dict(self.env, PATH=str(self.tools))
        # -i loads ~/.zshrc automatically; -d avoids other global startup files.
        result = subprocess.run([ZSH, "-d", "-i", "-c", extra + "\n" + report],
                                env=env, cwd=self.home, text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stderr, "")
        return dict(line.split("=", 1) for line in result.stdout.splitlines())

    def assert_runtime(self, state):
        self.assertEqual(state["NODE_PATH"], str(self.runtime / "node"))
        self.assertEqual(state["CODEX_PATH"], str(self.runtime / "codex"))
        self.assertEqual(state["NODE_VALUE"], "active-node")
        self.assertEqual(state["CODEX_VALUE"], "active-codex")

    def assert_no_server_model_cache(self, state):
        for name in ("MODEL_NAME", "UV_CACHE_DIR", "UV_LINK_MODE",
                     "FIXTURE_DIRENV", "FIXTURE_SHARED_PATHS"):
            self.assertEqual(state[name], "", name)

    def test_each_hostname_selects_its_own_profile_with_both_mounts_present(self):
        for host in HOSTS:
            with self.subTest(host=host):
                self.select(host)
                self.assertEqual((self.home / ".zshrc.local").resolve(),
                                 self.home / (".zshrc.local##hostname." + host))
                state = self.shell()
                self.assert_runtime(state)
                self.assertEqual(state["CUDA_HOME"], str(self.cuda))
                self.assertEqual(state["NVCC_PATH"], str(self.cuda / "bin/nvcc"))
                self.assertEqual(int(state["SHELL_UMASK"], 8), 0o002)
                self.assertEqual(state["HF_ENDPOINT"], "https://hf-mirror.com")
                self.assertIn(".hf.co", state["NO_PROXY"])
                for name, value in NCCL_VALUES.items():
                    self.assertEqual(state[name], value if host == "nlp4090-8" else "")
                if host == "nlp3090-2":
                    self.assertEqual(state["MODEL_NAME"], str(self.hdd / "yifan/shared/models/Qwen2.5-VL-7B-Instruct"))
                    self.assertEqual(state["UV_CACHE_DIR"], str(self.hdd / "yifan/shared/uv-cache"))
                    self.assertEqual(state["UV_LINK_MODE"], "hardlink")
                    self.assertEqual(state["FIXTURE_DIRENV"], "loaded")
                    self.assertEqual(state["FIXTURE_SHARED_PATHS"], "loaded")
                elif host == "nlp3090-4":
                    self.assertEqual(state["MODEL_NAME"], str(self.ssd / "shared/models/Qwen2.5-VL-7B-Instruct"))
                    for name in ("UV_CACHE_DIR", "UV_LINK_MODE", "FIXTURE_DIRENV", "FIXTURE_SHARED_PATHS"):
                        self.assertEqual(state[name], "", name)
                else:
                    self.assert_no_server_model_cache(state)

    def test_unknown_linux_host_removes_previous_host_selection(self):
        self.select("nlp4090-8")
        self.assertEqual(self.shell()["NCCL_CUMEM_ENABLE"], "1")
        self.select("unconfigured-linux")
        self.assertFalse((self.home / ".zshrc.local").is_symlink())
        state = self.shell()
        self.assert_no_server_model_cache(state)
        self.assertEqual(state["CUDA_HOME"], "")
        self.assertEqual(state["NVCC_PATH"], "")
        for name in NCCL_VALUES:
            self.assertEqual(state[name], "")
        self.assert_runtime(state)

    def test_project_variables_are_host_local_and_conditional(self):
        projects = {"AM_HOME": "ics2020/abstract-machine", "NEMU_HOME": "ics2020/nemu",
                    "NAVY_HOME": "ics2020/navy-apps", "NPC_HOME": "ysyx-workbench/npc"}
        for relative in projects.values():
            (self.home / relative).mkdir(parents=True)
        for host in (*HOSTS, "unconfigured-linux"):
            self.select(host)
            state = self.shell()
            for name, relative in projects.items():
                self.assertEqual(state[name], str(self.home / relative) if host in HOSTS else "")
            if host not in HOSTS:
                for name in ("HF_ENDPOINT", "NO_PROXY", "no_proxy", "HF_XET_LOG_DIR"):
                    self.assertEqual(state[name], "")
        shutil.rmtree(self.home / "ics2020")
        shutil.rmtree(self.home / "ysyx-workbench")
        self.select("nlp4090-8")
        state = self.shell()
        for name in projects:
            self.assertEqual(state[name], "")

    def test_local_tool_paths_preserve_active_runtime_and_deduplicate(self):
        local_bin = self.home / "miniforge3/bin"
        local_bin.mkdir(parents=True)
        self.executable(local_bin / "node", "printf 'base-node\\n'\n")
        for host in HOSTS:
            self.select(host)
            state = self.shell('source "$HOME/.zshrc.local"\n'
                               'fixture_count=0\n'
                               'for fixture_path in "$path[@]"; do\n'
                               '  [[ "$fixture_path" == "$HOME/miniforge3/bin" ]] && (( fixture_count += 1 ))\n'
                               'done\nprint -r -- "LOCAL_BIN_COUNT=$fixture_count"')
            self.assert_runtime(state)
            self.assertEqual(state["LOCAL_BIN_COUNT"], "1")

    def test_host_hf_endpoint_is_applied(self):
        self.select('nlp4090-8')
        candidate = self.home / '.zshrc.local##hostname.nlp4090-8'
        candidate.write_text(candidate.read_text().replace('https://hf-mirror.com', 'https://host-mirror.example'))
        self.assertEqual(self.shell()['HF_ENDPOINT'], 'https://host-mirror.example')

    def test_full_shell_preserves_hf_project_and_network_overrides(self):
        self.select('nlp4090-8')
        expected = dict(HF_ENDPOINT='https://huggingface.co', HF_HUB_CACHE='/project/cache',
                        HF_DATASETS_CACHE='/project/processed', NO_PROXY='upper.example',
                        no_proxy='lower.example', HF_XET_LOG_DIR='/project/logs')
        self.env.update(expected)
        state = self.shell()
        for key, value in expected.items():
            self.assertEqual(state[key], value)
        self.env.update(NO_PROXY='', no_proxy='')
        state = self.shell()
        self.assertEqual(state['NO_PROXY'], '')
        self.assertEqual(state['no_proxy'], '')

    def test_mac_without_matching_hostname_applies_no_server_profile(self):
        self.select("my-mac", "Darwin")
        self.assertFalse((self.home / ".zshrc.local").exists())
        state = self.shell()
        self.assert_no_server_model_cache(state)
        self.assertEqual(state["CUDA_HOME"], "")
        self.assertEqual(state["NVCC_PATH"], "")
        for name in NCCL_VALUES:
            self.assertEqual(state[name], "")
        self.assert_runtime(state)

    def test_3090_two_gpu_host_does_not_use_ssd_when_hdd_mount_is_missing(self):
        shutil.rmtree(self.hdd)
        self.select("nlp3090-2")
        state = self.shell()
        self.assert_no_server_model_cache(state)
        self.assertEqual(state["CUDA_HOME"], "")
        self.assert_runtime(state)

    def test_3090_four_gpu_host_does_not_use_hdd_when_ssd_mount_is_missing(self):
        shutil.rmtree(self.ssd)
        self.select("nlp3090-4")
        state = self.shell()
        self.assert_no_server_model_cache(state)
        self.assertEqual(state["CUDA_HOME"], "")
        self.assert_runtime(state)

    def test_3090_two_gpu_host_skips_direnv_when_project_is_missing(self):
        shutil.rmtree(self.hdd / "yifan/lmms-eval")
        self.select("nlp3090-2")
        state = self.shell()
        self.assertEqual(state["FIXTURE_DIRENV"], "")
        self.assertEqual(state["FIXTURE_SHARED_PATHS"], "loaded")
        self.assertTrue(state["MODEL_NAME"].startswith(str(self.hdd)))

    def test_3090_two_gpu_host_skips_missing_direnv_and_shared_paths(self):
        (self.tools / "direnv").unlink()
        self.shared_paths.unlink()
        self.select("nlp3090-2")
        state = self.shell()
        self.assertEqual(state["FIXTURE_DIRENV"], "")
        self.assertEqual(state["FIXTURE_SHARED_PATHS"], "")
        self.assertTrue(state["MODEL_NAME"].startswith(str(self.hdd)))
        self.assert_runtime(state)

    def test_4090_skips_cuda_without_executable_nvcc_but_loads_host_nccl(self):
        (self.cuda / "bin/nvcc").chmod(0o644)
        self.select("nlp4090-8")
        state = self.shell()
        self.assertEqual(state["CUDA_HOME"], "")
        self.assertEqual(state["CUDA_PATH_COUNT"], "0")
        self.assert_no_server_model_cache(state)
        for name, value in NCCL_VALUES.items():
            self.assertEqual(state[name], value)
        self.assert_runtime(state)

    def test_4090_cuda_path_deduplicates_and_nccl_values_survive_reload(self):
        self.select("nlp4090-8")
        state = self.shell('source "$HOME/.zshrc.local"')
        self.assertEqual(state["CUDA_PATH_COUNT"], "1")
        for name, value in NCCL_VALUES.items():
            self.assertEqual(state[name], value)
        self.assert_runtime(state)

    def test_all_hostname_profiles_preserve_existing_libraries_when_reloaded_twice(self):
        first = self.base / "other libraries first"
        second = self.base / "other libraries second"
        cuda_library = self.cuda / "lib64"
        for directory in (first, cuda_library, second):
            directory.mkdir()
        original = ":".join(map(str, (first, cuda_library, second)))
        for host in HOSTS:
            with self.subTest(host=host):
                self.env["LD_LIBRARY_PATH"] = original
                self.select(host)
                state = self.shell('source "$HOME/.zshrc.local"\nsource "$HOME/.zshrc.local"')
                self.assertEqual(state["CUDA_PATH_COUNT"], "1")
                libraries = state["LD_LIBRARY_PATH"].split(":")
                self.assertEqual(libraries.count(str(cuda_library)), 1)
                self.assertEqual(libraries.count(str(first)), 1)
                self.assertEqual(libraries.count(str(second)), 1)
                self.assertLess(libraries.index(str(first)), libraries.index(str(second)))
                self.assert_runtime(state)

    def test_3090_profiles_add_cuda_library_only_once_and_keep_other_libraries(self):
        first = self.base / "existing library one"
        second = self.base / "existing library two"
        for directory in (first, second):
            directory.mkdir()
        original = ":".join(map(str, (first, second)))
        for host in ("nlp3090-2", "nlp3090-4"):
            with self.subTest(host=host):
                self.env["LD_LIBRARY_PATH"] = original
                self.select(host)
                state = self.shell('source "$HOME/.zshrc.local"\nsource "$HOME/.zshrc.local"')
                self.assertEqual(state["CUDA_PATH_COUNT"], "1")
                self.assertEqual(state["LD_LIBRARY_PATH"], str(self.cuda / "lib64") + ":" + original)
                self.assert_runtime(state)


if __name__ == "__main__":
    unittest.main(verbosity=2)
