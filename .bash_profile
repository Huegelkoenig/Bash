# generated by Git for Windows
test -f ~/.profile && . ~/.profile
test -f ~/.bashrc && . ~/.bashrc

function init-node-project {  #pass https://github.com/USER/REPO.git as first argument
 if [ $# -eq 0 ]
  then
    echo "Error: No arguments supplied."
    echo 'pass a repository as first argument, eg https://github.com/USER/REPO.git'
    return 1
  fi
  git init
  git remote add github "$1"  #"$1" is the first argument

  npx gitignore node #downloads a .gitignore file
  add-own-ignores #and add own ignore rules (see function below)
  
  echo ""
  echo ""
  echo ""
  echo "Enter a description:"
  echo "press   ESC   :x   ENTER   to exit vim"
  echo "Opening README.md in"
  echo "5 seconds"
  sleep 1
  echo "4 seconds"
  sleep 1
  echo "3 seconds"
  sleep 1
  echo "2 seconds"
  sleep 1
  echo "1 second"
  vim -c :startinsert README.md #you can edit your README.md now

  npx license "$(npm get init.license)" -o "$(npm get init.author.name)" > LICENSE  #downloads a license, works with version 0.0.3 
  #npx covgen "$(npm get init.author.email)" #adds email to package.json
  npm init -y
  editpackagejson "$1" #edits the created package.json

  git add .
  git commit -m "Initial Commit"
  git push -u github master
}

function add-own-ignores {
  #adds an empty line first, adds all files with format _[test]_*.* to gitignore
  vi -c "call append('$', '')" -c "call append('$', '# my own rules')" -c "call append('$', '#test files')" -c "call append('$', '_\[test\]_*')" -c :x .gitignore

}

function editpackagejson {
  json -I -f package.json -e 'this.main="server.js"'
  json -I -f package.json -e 'this.keywords=["javascript","node.js"]'
  json -I -f package.json -e 'this.repository={}'
  json -I -f package.json -e 'this.repository.type="git"'
  json -I -f package.json -e "this.repository.url='$1'"
  linkdummy=$(cut -d'.' -f1 <<<"$1")   #cuts https://github  from repository link
  linkdummy="$linkdummy""."$(cut -d'.' -f2 <<<"$1")  #adds the .com/USER/REPO from initial link  
  dummy="$linkdummy""#readme"
  json -I -f package.json -e "this.homepage='$dummy'"
  dummy="$linkdummy""/issues"
  json -I -f package.json -e 'this.bugs={}'  
  json -I -f package.json -e "this.bugs.url='$dummy'"
  dummy=$(<README.md)
  json -I -f package.json -e "this.description='$dummy'"
  json -I -f package.json -e 'this.nodeversion={}'
  dummy=$(npm -v)
  json -I -f package.json -e "this.nodeversion.npm='$dummy'"
  dummy=$(node.exe -v)
  json -I -f package.json -e "this.nodeversion.node='$dummy'"
  unset linkdummy
  unset dummy
}


#pass "major", "minor" or "patch" as first argument
#pass a commitmessage as second argument (optional! if not passed, the version number will be passed automatically)
function gitcup { 
  if [ $# -eq 0 -o $# -eq 1 ]
  then
    echo 'Fault: No arguments supplied.'
    echo 'pass "major", "minor", "patch" or "none" as first argument'
    echo 'pass a commitmessage as  second argument'
    return 1
  fi
  if [ "$1" == "major" -o "$1" == "minor" -o "$1" == "patch" ]
  then
    echo 'project will be updated to version'
    npm --no-git-tag-version version "$1"
  else
    echo 'version will not be updated'
  fi
  if [ -n "$(git status -uno --porcelain)" ] #-n : check, if returned string is not null, which means, there are uncommitted changes (use -z to check if string is null, which means there are no pending changes); -uno : short for --untracked-files=no : untracked files will be ignored
  then
    git add .
    git commit -m "$2"
  else
    echo 'commit is clean'
  fi
  git push -u github "$(git rev-parse --abbrev-ref HEAD)"  # $(git rev...) gets the actual branch   ## github = origin
}


#pass a branch name as argument
#merges the branch with the active branch, deletes the merged branch and updates github
function gitmup { 
  if [ $# -eq 0 ]
  then
    echo 'Fault: No argument supplied.'
    echo 'pass the name of the branch to merge as first argument'
    return 1
  fi
  actbranch=$(git rev-parse --abbrev-ref HEAD)
  if git show-ref --quiet refs/heads/"$1"; # if branch exists
  then
    if [[ $actbranch == "$1" ]]
    then
      echo you can\'t merge here, since you\'re actually in the same branch
    else
      git checkout "$1"
      if [ -z "$(git status -uno --porcelain)" ] # if there are no uncommitted changes
      then
        git checkout $actbranch
        git merge --no-commit --no-ff "$1" 
        if [ $? -eq 0 ] #if no errors
        then
          git merge --abort
          git merge "$1"
          git push -u github $actbranch
          git push github --delete "$1"
          git branch -d "$1"
        else
          git merge --abort
        fi
      else
        echo Fault: there are uncommitted changes in branch "$1"
        echo you can use >gitcup patch message   to commit these changes first
        git status      
      fi
    fi
  else
    echo branch "$1" doesn\'t exist
  fi
}