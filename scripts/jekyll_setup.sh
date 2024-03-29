# ------------------------------------------------------------------------------------------
#!/bin/bash
# args: GitHub user_name
# ------------------------------------------------------------------------------------------
echo ${L1}
echo "Setting up Jekyll for GitHub pages..."
echo ${L1}

if [[ $# -ne 1 ]]; then
    echo "Illegal number of parameters" >&2
    echo "./jekyll_setup.sh user_name (GitHub)"
    exit 2
fi

# ------------------------------------------------------------------------------------------
# Dependencies
echo "Installing dependencies"
sudo apt update -y
sudo apt install -y ruby-full build-essential zlib1g-dev

echo "Setting .bashrc_local"
if [ -z "${GEM_HOME}" ]; then
  # Load local .bashrc setttings
  if [ -f ~/.bashrc_local ]; then
    echo 'export GEM_HOME="${HOME}/gems"' >> ~/.bashrc_local
    echo 'export PATH="${HOME}/gems/bin:$PATH"' >> ~/.bashrc_local
  else
    echo 'export GEM_HOME="${HOME}/gems"' >> ~/.bashrc
    echo 'export PATH="${HOME}/gems/bin:$PATH"' >> ~/.bashrc
  fi
  source ~/.bashrc
  
else 
  if [ "${GEM_HOME}" != "${HOME}/gems" ]; then
    echo "GEM_HOME wrong value, declared as: ${GEM_HOME}, expecting ${HOME}/gems}"
    echo "Remove GEM_HOME declaration (maybe at .bashrc or .bashrc_local) and also check PATH env.var."
    exit 1
  fi
fi

gem install jekyll bundler

# ------------------------------------------------------------------------------------------
# Setup repository
echo ${L2}

# git repo
USER=$1
REPO_PATH="~/dev/${USER}.github.io"
REPO=git@github.com:${USER}/${USER}.github.io.git
echo "Creating GitHub.io (pages) at ${REPO_PATH}"
mkdir -p ~/dev
cd ~/dev
git clone ${REPO}
cd ${USER}.github.io

if [ ! -f .gitignore ]; then
  echo "Generating .gitignore for Jekyll"
  wget https://www.toptal.com/developers/gitignore/api/jekyll,python -O .gitignore
fi

bundle init
#bundle config set --local path 'vendor/bundle'
bundle add jekyll
if [ ! -f _config.yml ]; then
  bundle exec jekyll new --force --skip-bundle .
fi
bundle install

# I don't like .markdown extension, switch to .md
for f in *.markdown; do mv -- "$f" "${f%.markdown}.md"; done
for f in **/*.markdown; do mv -- "$f" "${f%.markdown}.md"; done

if [ ! -f "./jekyll_setup_gems.lst" ]; then
  if [ -f "${HOME}/dev/devsetup/scripts/assets/jekyll_setup_gems.lst" ]; then
    cp ${HOME}/dev/devsetup/scripts/assets/jekyll_setup_gems.lst ./
  fi
fi

if [ -f "./jekyll_setup_gems.lst" ]; then
  while IFS= read -r line; do
    gem install ${line}
  done < ./jekyll_setup_gems.lst
fi

git log > /dev/null
if [ "$?" != "0" ]; then
  git add -A
  git commit -am "First commit..."
  git push
fi

BRANCH=gh-pages
git ls-remote --heads ${REPO} ${BRANCH} | grep ${BRANCH} >/dev/null
if [ "$?" == "1" ]; then
  echo ${L2}
  echo "Creating gh-pages branch"
  git checkout --orphan gh-pages
  git rm -rf 
  git push
  git checkout main
fi

echo ${L1}
echo "Done! Happy web coding..."
echo ${L1}
