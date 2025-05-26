alias g='git'
alias k='kubectl'
alias h='helm'
alias gradlew='./gradlew'
alias gradle='./gradlew'
alias d='docker'
alias cuts='cut -d" " -f'

alias context='kubectl config current-context'
alias debug='kubectl run -ti --rm=true debug --image=busybox'
alias namespace='kubectl config set-context --current --namespace'

alias knames='kubectl get -o "go-template={{range .items}}{{println .metadata.name}}{{end}}"'
alias pod='kubectl describe pod'
alias pods='kubectl get pods'

alias watch='watch -n 1 '
alias every='xargs -i '
alias millis='date +%s%N | cut -b1-13'

packpngstojpg() {
  for filename in *.png; do
    pngpacktojpg "$filename"
  done
}

pngpacktojpg() {
  convert -quality 75 -resize 80% $1 $(echo $1 | sed "s/.png/.jpg/g")
}

selector() {
  history_file=$1
  looking_for=$2
  if [ -z "$looking_for" ]; then
    looking_for=$(basename "$history_file" | sed 's#s$##g')
  fi
  if [ ! -f "$history_file" ]; then
    touch "$history_file"
  fi
  history=$(cat "$history_file")
  selection=$(echo -e "new\n$history" | fzf --header "($history_file)" --history "$history_file.hist" --prompt "Select $looking_for (new for other): ")
  return_code=$?
  if [ -z "$selection" ]; then
    echo 'No selection made'
    return $return_code
  fi
  if [ "$selection" == "new" ]; then
    read -r -p "Enter a new item: " selection
    return_code=$?
    if [ -z "$selection" ]; then
      return $return_code
    fi
    echo "$selection" >> "$history_file"
  fi
  echo "$selection"
}

jenkins-auth() {
  export full_jenkins_url
  if ! full_jenkins_url=$(selector ~/.jenkins-auth) ; then
    return 1
  fi
  export JENKINS_URL
  JENKINS_URL=$(echo "$full_jenkins_url" | cut -d":" -f1)'://'$(echo "$full_jenkins_url" | cut -d'@' -f2)
  export JENKINS_AUTH
  JENKINS_AUTH=$(echo "$full_jenkins_url" | cut -d '/' -f3 | cut -d'@' -f1)
}

auth() {
  full=$(selector "$1")
  echo "$full" | cut -d '/' -f3 | cut -d'@' -f1
}

jenkins() {
  local script
  if [ -z "$1" ]; then
    while read -r -p '>> ' script_line; do
      script+="$script_line"$'\n'
    done
  else
    if [ -f "$1" ]; then
      script=$(cat "$1")
    else
      script="$1"
    fi
  fi
  curl -s -k --fail-with-body -L -H "$CRUMB" -X POST "$JENKINS_URL/scriptText" --user "$JENKINS_AUTH" --data-urlencode "script=${script}" | sed 's#\r##g'
}

kapi-resources() {
  kubectl api-resources $1 $2 $3 $4 $5 $6 $7 $8 $9
}

c9s() {
  KUBECONFIG=~/.kube/$1.config.yaml k9s --kubeconfig ~/.kube/$1.config.yaml $2 $3 $4 $5 $6 $7 $8 $9
}

devup() {
  load-secrets
  ARTIFACTORY_USER=$(whoami) devcontainer up --workspace-folder "$1" $2 $3 $4 $5 $6 $7 $8 $9
}

actmyworkflow() {
  echo "Please input the workflow"
  local workflow="$(cat -)"
  local work_dir=/tmp/actmyworkflow-${RANDOM}
  mkdir -p "${work_dir}/.github/workflows"
  pushd "${work_dir}"
  git init
  echo "${workflow}" >"${work_dir}/.github/workflows/test.yaml"
  git add "${work_dir}/.github/workflows/test.yaml"
  git commit -m "add workflow"
  act "${1}"
  popd
  rm -fr "${work_dir}"
}

load-secrets() {
  set -a && source .secrets && set +a
}

ghapi() {
  local method="$(echo $1 | tr a-z A-Z)"
  local gh=$2
  local path=$3
  local url_prefix="$(grep $gh ~/.git-credentials)"
  curl -s -X "${method}" \
    -H "Accept: application/vnd.github.v3+json" \
    "${url_prefix}/api/v3/$path"
}

runnerreg() {
  local gh=$1
  local org=$2
  echo 'getting runner registration token' >&2
  ghapi post $gh "orgs/$org/actions/runners/registration-token" | jq -r .token
}

runnerreg2() {
  local gh=$1
  local org=$2
  local token="$(runnerreg $gh $org)"
  local gh_host="$(grep $gh ~/.git-credentials | cut -d'@' -f2)"
  local data="$(jq -n --arg url https://$gh_host/$org --arg runner_event register '$ARGS.named')"
  echo 'getting registration token pipeline service' >&2
  curl -s -X POST \
    -d "$data" \
    -H "Accept: application/json" \
    -H "Authorization: RemoteAuth ${token}" \
    "https://$gh_host/api/v3/actions/runner-registration"
}

gh-apis() {
  local method="$(echo $1 | tr a-z A-Z)"
  local registration="$(runnerreg2 $2 $3)"
  local token="$(echo $registration | jq -r .token)"
  local url="$(echo $registration | jq -r .url)"
  local full_url="${url}/_apis/$4?api-version=6.0-preview.1$5"
  echo "${method}: ${full_url}" >&2
  curl -s -X "${method}" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer ${token}" \
    "${full_url}"
}

scalesets() {
  local method=$1
  local gh=$2
  local org=$3
  gh-apis "$method" "$gh" "$org" "runtime/runnerscalesets$4" "$5"
}

scaleset() {
  local gh=$1
  local org=$2
  local name=$3
  scalesets get $gh $org | jq '.value | .[] | select(.name == "'$name'")'
}

scaleset_id() {
  local gh=$1
  local org=$2
  local name=$3
  scaleset $gh $org $name | jq -r .id
}

scaleset_delete() {
  local gh=$1
  local org=$2
  local name=$3
  local id=$(scaleset_id $gh $org $name)
  if [ -z "$id" ]; then
    echo "No scaleset found with name $name" >&2
    return
  fi
  scalesets delete $gh $org /$id
}

scalesets_old() {
  local gh=$1
  local org=$2
  local old=$(date -d '1 days ago' +'%s')
  scalesets get $gh $org | jq '.value[] | select (.status=="offline") | select (.createdOn | .[0:19] +"Z" | fromdateiso8601 < '${old}' )'
}

scalesets_delete_old() {
  local gh=$1
  local org=$2
  scalesets_old $gh $org | jq -r '"\(.name) \(.id)"' | while read name id; do
    echo "Deleting scaleset $name with id $id" >&2
    scalesets delete $gh $org /$id
  done
}

sshvm() {
  local port=${1:-2222}
  ssh-keygen -f "/home/$(whoami)/.ssh/known_hosts" -R "[localhost]:${port}"
  ssh -o StrictHostKeychecking=no ubuntu@localhost -p ${port}
}

dudir() {
  for i in $(ls -a $1); do du -hs $i; done | sort -h
}

tms-gen-dev() {
  for link in ~/dev-sessions/*; do
    session_name=$(basename "$link")
    if [ -d "$link" ]; then
      cat <<EOF > ~/.config/tmuxinator/"$session_name".yml
name: $session_name
root: ~/dev-sessions/$session_name
attach: false
windows:
- $session_name:
    layout: tiled
    panes:
    - nvim
    -
EOF
    fi
  done
}

tms-start() {
  local yamls
  yamls=$(find ~/.config/tmuxinator -name '*.yaml' ! -name '*-disabled.yaml')
  for yaml in ${yamls}; do
    cp "$yaml" "${yaml//.yaml/.yml}"
  done
  local sessions
  sessions="$(tmuxinator list | tail -n 1)"
  for session in ${sessions}; do
    tmuxinator start "$session"
  done
}

tms-stop() {
  local sessions
  sessions="$(tmuxinator list | tail -n 1)"
  for session in ${sessions}; do
    tmuxinator stop "$session"
  done
}

ghauth() {
  export GITHUB_TOKEN
  GITHUB_TOKEN=$(grep "$1" ~/.git-credentials | cut -d':' -f3 | cut -d'@' -f1)
}

wincd() {
  local win_path
  if [ -z "$1" ]; then
    win_path=$(wslclip --get | tr -d '\r')
  else
    win_path=$(echo "$1" | tr -d '\r')
  fi
  path=$(wslpath "$win_path")
  cd "$path" || return 1
}

nnncd() {
  [ "${NNNLVL:-0}" -eq 0 ] || {
    echo "nnn is already running"
    return
  }
  export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
  command nnn "$@"
  [ ! -f "$NNN_TMPFILE" ] || {
    . "$NNN_TMPFILE"
    rm -f -- "$NNN_TMPFILE" > /dev/null
  }
}

docker-port-forward() {
  if [[ -z $1 || -z $2 ]]; then
    echo "Usage: docker-port-forward <container_name> <port>"
    return 1
  fi
  local container_name port ip_address
  container_name=$1
  port=$2
  ip_address=$(docker inspect "${container_name}" --format '{{.NetworkSettings.IPAddress}}')
  if [[ -z $ip_address ]]; then
    echo "Container ${container_name} not found" >&2
    return 1
  fi
  new_container_name="${container_name}_port_forward_port_${port}"
  docker run --name "${new_container_name}" --rm --net host alpine/socat TCP4-LISTEN:"${port}" "TCP4:${ip_address}:${port}"
}
