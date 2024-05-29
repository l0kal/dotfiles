# drop anoying .gitpod.yml
if [[ -z $(git ls-files --error-unmatch .gitpod.yml 2>/dev/null) ]]; then
  rm .gitpod.yml 2> /dev/null
fi