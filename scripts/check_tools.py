# --------------------------------------------------------------------------------
import sys, os
import re
import argparse

from subprocess import Popen, PIPE
from shlex import split
from pathlib import Path
from packaging import version
# --------------------------------------------------------------------------------
def run_process(command_line, wait=True, stdout=PIPE, stderr=PIPE):
    args = split(command_line)
    print(f'$ {command_line}')
    p = Popen(args, stdout=stdout, stderr=stderr, text=True, start_new_session=True)
    if wait:
      p.wait()
      return p.stdout, p.stderr
    
# --------------------------------------------------------------------------------
def run_bash_script(command, stdout=sys.stdout, stderr=sys.stderr):
  return run_process(f'bash {command}', stdout=stdout, stderr=stderr)

# --------------------------------------------------------------------------------
def get_shell_app_path(app):
  r, _ = run_process(f"which {app}")
  return  r.readline().rstrip()
  
# --------------------------------------------------------------------------------
def run_with_venvwrapper(home, command, stdout=sys.stdout, stderr=sys.stderr):
  return run_process(f'bash -c "source {home}/.local/bin/virtualenvwrapper.sh; {command}"', stdout=stdout, stderr=stderr)

# --------------------------------------------------------------------------------
def run_with_venv(venv, command, stdout=sys.stdout, stderr=sys.stderr):
  return run_process(f'bash -c "source {venv}/bin/activate; {command}"', stdout=stdout, stderr=stderr)

# --------------------------------------------------------------------------------
def get_base_prefix_compat():
  """Get base/real prefix, or sys.prefix if there is none."""
  return getattr(sys, "base_prefix", None) or getattr(sys, "real_prefix", None) or sys.prefix

# --------------------------------------------------------------------------------
def in_virtualenv():
  return get_base_prefix_compat() != sys.prefix

# --------------------------------------------------------------------------------
def ask_yes_no(q):
  while True:
    r = input(f"{q} (y/n)? ").lower().strip()[:1]
    if r == "y":
      return True
    if r == "n":
      return False

# ====================================================================================
# python
def python_setup(home, venv, usr_instructions, auto_yes=False):
  if not in_virtualenv():
    print("No python virtual-env detected")
    if auto_yes or ask_yes_no("Use virtual-env"):
      try:
        import virtualenv
      except:
        print("Installing virtualenv")
        run_process("pip3 install virtualenv")
      else:
        pass
      finally:
        pass
      
      try:
        import virtualenvwrapper
      except:
        if auto_yes or ask_yes_no(f"Use virtualenvwrapper (recommended)"):
          print("Installing virtualenvwrapper")
          run_process("pip3 install virtualenvwrapper")
          # Get config
          python3_path = get_shell_app_path("python3")
          virtualenv_path = get_shell_app_path("virtualenv")
          # Update .bashrc
          with Path(f"{home}/.bashrc").open("a") as f:
            f.write(f"""
# virtualenv and virtualenvwrapper
export WORKON_HOME=${{HOME}}/.virtualenvs
export VIRTUALENVWRAPPER_PYTHON={python3_path}
export VIRTUALENVWRAPPER_VIRTUALENV={virtualenv_path}
source ${{HOME}}/.local/bin/virtualenvwrapper.sh
""")
          usr_instructions.append("source ~/.bashrc (once, to enable virtualenv-wrapper")
          
          run_with_venvwrapper(home, f"mkvirtualenv {venv}")
          usr_instructions.append(f"workon {venv} (to activate python-venv)")
          venv = f"{home}/.virtualenvs/{venv}"
          
        else: # no virtualenvwrapper
          from virtualenv import cli_run
          venv = f".venv/{venv}"
          cli_run([venv])
          usr_instructions.append(f"source {venv}/bin/activate (to activate python-venv)")
      
      else:
        run_with_venvwrapper(home, f"mkvirtualenv {venv}")
        venv = f"{home}/.virtualenvs/{venv}"
        
      finally:
        python = "python"
        pip = "pip"
      #end try virtualenvwrapper
      
    else: # don't use virtualenv
      python = "python3"
      pip = "pip3"
      venv = None
    
  else: # we are in a venv
    python = "python"
    pip = "pip"
    venv = None
    
  if venv is None:
    run_process(f"{pip} install -r requirements.txt")
  else:
    run_with_venv(venv, f"{pip} install -r requirements.txt")
  
  return python, pip, venv
  
# ====================================================================================
# verilator
def app_install(name, url, rex_rule=r"\d(\.(\d)+)*", v="+", this_ver=False, auto_yes=False):
  app_path = get_shell_app_path(f"{name}")
  curr_ver = None
  if app_path:
    app_version, _ = run_process(f"{name} --version")
    app_version = app_version.read().splitlines()[0]
    rex_rule = re.compile(rex_rule)
    rex_match = rex_rule.search(app_version)
    if rex_match is None:
      curr_ver = None
    else:
      curr_ver = rex_match.group()
  
  if curr_ver is None or (
      v is not None and (
        (v == "+")
        or
        (     this_ver and version.parse(curr_ver) != version.parse(v) )
        or
        ( not this_ver and version.parse(curr_ver) < version.parse(v) )
      )
  ):
    if auto_yes or ask_yes_no(f"{name} install/update required, proceed (no will exit and required a manual installation)"):
      if curr_ver is None:
        print(f"{name} not found, installing to '{home}/repos'")
      
      elif v is not None:
        if v=="+":
          print(f"{name} upgrading to latest'{home}/repos'")
        
        elif this_ver and version.parse(curr_ver) != version.parse(v):
          print(f"{name} wrong version({curr_ver} != {v}), installing/upgrading to/from '{home}/repos'")
        
        elif not this_ver and version.parse(curr_ver) < version.parse(v):
          print(f"{name} wrong version({curr_ver} < {v}), installing/upgrading to/from '{home}/repos'")
      
      print(f"Installing {name}...")
      tag = v if v is not None and this_ver else ""
      
      run_bash_script(f"./install_{name}.sh {home}/repos {tag}")
      
    else:
      usr_instructions.append(f"cmd: 'scripts/install_{name}.sh target_dir version' ({url})")
      
  else:
    print(f"{app_version}")
  
# ====================================================================================

# ====================================================================================
# --------------------------------------------------------------------------------
if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Check and install required tools')
  parser.add_argument('-y', action='store_true')
  args = parser.parse_args()
  
  home = os.getenv("HOME")
  venv = "dev"
  usr_instructions = []
  auto_yes = args.y
  
  print('.'*60)
  python, pip, venv = python_setup(home, venv, usr_instructions, auto_yes=auto_yes)
  print('.'*60)
  app_install(name="verilator", url="https://verilator.org/guide/latest/install.html", v="v4.224", auto_yes=auto_yes)
  print('.'*60)
  app_install(name="cmake", url="https://github.com/Kitware/CMake/tree/master", v="v3.22.1", this_ver=True, auto_yes=auto_yes)
  
  # --------------------------------
  print('='*60)
  print("\n".join(usr_instructions))
