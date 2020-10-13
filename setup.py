import sys
import subprocess

platform = sys.platform
print(f"Running on {platform}")
if platform == "win32":
    shell = True
elif platform == "linux":
    shell = False
else:
    print(f"<WARNING> Unknown platform: {platform}, setting shell=False")
    shell = False

# -----------------------------------------
print(f"Installing python conda packages...")
proc = subprocess.Popen(["conda", "config", "--add", "channels", "conda-forge"])
proc.wait()
# -----------------------------------------
proc = subprocess.Popen(["conda", "install", "--yes", "--file", "conda_requirements.txt"])
proc.wait()
# -----------------------------------------
print(f"Installing python pip packages...")
proc = subprocess.Popen(["pip", "install", "--requirement", "pip_requirements.txt"])
proc.wait()

# -----------------------------------------
proc = subprocess.Popen(["code"], shell=shell)
extensions = Path("vscode_extensions.txt").read_text().splitlines()
for ext in extensions:
    proc = subprocess.Popen(["code", "--install-extension", ext, "--force"], shell=shell)
    proc.wait()


print(f"Installing common repositories...")
repos = Path("repositories.txt").read_text().splitlines()
proc = []
for repo in repos:
    p = "../" + repo.split('/')[-1]
    proc.append( subprocess.Popen(["git", "clone", repo, p], shell=shell) )

rcodes = [p.wait() for p in proc]

