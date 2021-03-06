#!/bin/bash
MODIFIED_FILES=$(git --no-pager diff --name-only ${TRAVIS_COMMIT_RANGE})
if grep -q "docs/" <<<$MODIFIED_FILES
then
  echo "Modified doc files found"
  sudo apt-get install -y aspell-en
  result=$?
  if [ $result -eq "0" ]
  then
    echo "Successfully installed aspell-en"
    modified_files_arr=($MODIFIED_FILES)
    for docs_file_modified in "${modified_files_arr[@]}"
    do
      if grep -q "docs/" <<<$docs_file_modified
      then
        <$docs_file_modified aspell pipe list -d en_US --encoding utf-8 --personal=./tests/.aspell.en.pws |
        grep '[a-zA-Z]\+ [0-9]\+ [0-9]\+' -oh |
        grep '[a-zA-Z]\+' -o | sort | uniq |
        while read word; do
          grep -on "\<$word\>" $docs_file_modified;
        done >>./misspelled_per_file.txt;
        if [[ -s ./misspelled_per_file.txt ]]
        then
          sort -n ./misspelled_per_file.txt -o ./misspelled_per_file.txt;
          echo "Misspelled words in File : $docs_file_modified :- " > ./Misspelled_words.txt;
          cat ./misspelled_per_file.txt >> ./Misspelled_words.txt;
        fi
      fi
    done
    if [[ -s ./Misspelled_words.txt ]]
    then
      echo "~~~  Spelling Errors  ~~~ "
      cat ./Misspelled_words.txt
      return 1;
    else
      echo "Spell Check Successful : No erros found."
    fi
    if [ "${TRAVIS_PULL_REQUEST}" = "false" ] && [ "${TRAVIS_BRANCH}" = "master" ]
    then
      mkdir out;
      cd out
      git clone https://github.com/ParsaLab/cloudsuite.git
      cd cloudsuite
      git checkout gh-pages
      git config user.name ${GIT_USER}
      git config user.email ${GIT_EMAIL}
      git config credential.helper "store --file=.git/credentials"
      git config --global push.default matching
      echo "https://$GH_TOKEN:x-oauth-basic@github.com" >> .git/credentials
      git merge master --no-edit
      result=$?
      if [ $result -eq "1" ]
      then
        echo "Merge Failed"
        return 1
      else
        echo "Merge Successful"
        git push -f origin gh-pages
        result=$?
        if [ $result -eq "0" ]
        then
          echo "Successfully updated branch gh-pages"
        else
          echo "Push command Failed"
          return 1
        fi
      fi
    fi
  else
    echo "Installation of Aspell Failed : No updates performed."
  fi
else
  echo "No modifications to Doc files"
fi
