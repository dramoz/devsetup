# ------------------------------------------------------------------------------------------
#!/bin/bash
# args: user_name
# ------------------------------------------------------------------------------------------
echo ${L1}
echo "Setting up Jekyll for GitHub pages..."
echo ${L1}

if [[ $# -ne 1 ]]; then
    echo "Illegal number of parameters" >&2
    exit 2
fi

# ------------------------------------------------------------------------------------------
# Dependencies
echo "Installing dependencies"
sudo apt update -y
sudo apt install -y ruby-full build-essential zlib1g-dev

echo "Setting .bashrc"
if [[ -z "${GEM_HOME}" ]]; then
  echo 'export GEM_HOME="${HOME}/gems"' >> ~/.bashrc
  echo 'export PATH="${HOME}/gems/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
else 
  if [ "${GEM_HOME}" != "${HOME}/gems" ]; then
    echo "GEM_HOME wrong value, declared as: ${GEM_HOME}, expecting ${HOME}/gems}"
    echo "Remove GEM_HOME declaration (maybe at .bashrc) and also in PATH"
    exit 1
  fi
fi

gem install jekyll bundler

# ------------------------------------------------------------------------------------------
# Setup repository
echo ${L2}

# git repo
user=$1
repo_path="~/dev/${user}.github.io"
echo "Creating GitHub.io (pages) at ${repo_path}"
mkdir -p ~/dev
cd ~/dev
git clone git@github.com:${user}/${user}.github.io.git
cd ${user}.github.io

echo "Generating .gitignore for Jekyll"
wget https://www.toptal.com/developers/gitignore/api/jekyll,python -O .gitignore

bundle init
#bundle config set --local path 'vendor/bundle'
bundle add jekyll
bundle exec jekyll new --force --skip-bundle .
bundle install

# I don't like .markdown extension, switch to .md
for f in *.markdown; do mv -- "$f" "${f%.markdown}.md"; done
for f in **/*.markdown; do mv -- "$f" "${f%.markdown}.md"; done

if [ -d "$DEVSETUP_DIR" ]; then
  # Take action if $DIR exists. #
  echo "Copying files from devsetup/jekyll ..."
  cp ${DEVSETUP_DIR}/scripts/jekyll_files/* ./
  
  gem 'jekyll-seo-tag'
fi

#git add -A
#git commit -am "First commit..."
#git push

#echo ${L2}
#echo "Creating gh-pages branch"
#git checkout --orphan gh-pages
#git rm -rf 
#git push
#git checkout main

echo ${L1}
echo "Done! Happy coding..."
echo ${L1}
