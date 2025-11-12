#!/usr/bin/env bash
# Arcium — Usage Dashboard (Docker + Toolchain + Accurate Sizes)
# Показывает CPU/RAM контейнера, диск, порты и ИТОГО по установке (нода + образ + тулзы)
set -Eeuo pipefail

# -------- defaults --------
ENV_FILE_DEFAULT="$HOME/arcium-node-setup/.env"
BASE_DIR_DEFAULT="$HOME/arcium-node-setup"
CONTAINER_DEFAULT="arx-node"
IMAGE_DEFAULT="arcium/arx-node:v0.4.0"

ENV_FILE="$ENV_FILE_DEFAULT"
BASE_DIR="$BASE_DIR_DEFAULT"
CONTAINER="$CONTAINER_DEFAULT"
IMAGE="$IMAGE_DEFAULT"

# -------- args --------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)       ENV_FILE="${2:?}"; shift 2 ;;
    --base)      BASE_DIR="${2:?}"; shift 2 ;;
    --container) CONTAINER="${2:?}"; shift 2 ;;
    --image)     IMAGE="${2:?}"; shift 2 ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [--env FILE] [--base DIR] [--container NAME] [--image NAME]
EOF
      exit 0;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# -------- ui --------
cG=$'\033[0;32m'; cC=$'\033[0;36m'; cB=$'\033[0;34m'; cR=$'\033[0;31m'
cM=$'\033[1;35m'; c0=$'\033[0m'; cBold=$'\033[1m'; cDim=$'\033[2m'
hr(){ echo -e "${cDim}────────────────────────────────────────────────────────────${c0}"; }

# -------- helpers --------
fmt_bytes(){ numfmt --to=iec --suffix=B --format="%.2f" "${1:-0}" 2>/dev/null || echo "${1}B"; }
bytes_of_file(){ stat -c%s "$1" 2>/dev/null || echo 0; }
bytes_of_dir(){ du -sb "$1" 2>/dev/null | awk '{print $1}'; }
first_line(){ sed -n '1p'; }
which_path(){ command -v "$1" 2>/dev/null || true; }
realpath_safe(){ readlink -f "$1" 2>/dev/null || echo "$1"; }

add_total(){ # $1 label, $2 bytes
  printf "%-18s %s\n" "$1:" "${cC}$(fmt_bytes "$2")${c0}"
  TOTAL_BYTES=$((TOTAL_BYTES + $2))
}

# -------- load env --------
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE" || true
LOGS_DIR="$BASE_DIR/arx-node-logs"

# -------- deps --------
command -v docker >/dev/null || { echo "docker not found"; exit 1; }
command -v numfmt >/dev/null || { echo "numfmt not found (coreutils)"; exit 1; }

clear
hr
echo -e "${cBold}${cM}Arcium — Usage Dashboard${c0}"
hr
echo -e "${cBold}${cB}BASE_DIR:${c0}  $BASE_DIR"
echo -e "${cBold}${cB}LOGS_DIR:${c0}  $LOGS_DIR"
[[ -n "${RPC_HTTP:-}" ]] && echo -e "${cBold}${cB}RPC_HTTP:${c0}  ${RPC_HTTP}"
[[ -n "${RPC_WSS:-}" ]]  && echo -e "${cBold}${cB}RPC_WSS:${c0}  ${RPC_WSS}"
hr

# -------- disk: node dirs & image --------
BASE_BYTES=$(bytes_of_dir "$BASE_DIR")
LOGS_BYTES=$(bytes_of_dir "$LOGS_DIR")
IMG_BYTES=$(docker image inspect "$IMAGE" --format '{{.Size}}' 2>/dev/null || echo 0)

echo -e "${cBold}${cB}Диск (хост):${c0}"
echo -e "  BASE_DIR: $(fmt_bytes "${BASE_BYTES:-0}")"
echo -e "  LOGS_DIR: $(fmt_bytes "${LOGS_BYTES:-0}")"
echo -e "  Docker image: $(fmt_bytes "${IMG_BYTES:-0}")"
hr

# -------- container quick (без ошибок с CPU форматами) --------
CID="$(docker ps -aq --filter "name=^${CONTAINER}$" | head -n1 || true)"
if [[ -n "$CID" ]]; then
  STATE_LINE="$(docker inspect -f '{{.State.Status}};{{.State.Running}};{{.State.StartedAt}};{{.State.Health.Status}}' "$CID" 2>/dev/null || true)"
  STATUS="$(echo "$STATE_LINE" | awk -F';' '{print $1}')"
  RUNNING="$(echo "$STATE_LINE" | awk -F';' '{print $2}')"
  STARTED_AT="$(echo "$STATE_LINE" | awk -F';' '{print $3}')"
  HEALTH="$(echo "$STATE_LINE" | awk -F';' '{print $4}')"

  # uptime
  UPTIME="-"
  if [[ -n "$STARTED_AT" && "$STARTED_AT" != "0001-01-01T00:00:00Z" ]]; then
    START_TS=$(date -d "$STARTED_AT" +%s 2>/dev/null || echo "")
    NOW_TS=$(date +%s)
    if [[ -n "$START_TS" ]]; then
      SEC=$((NOW_TS-START_TS)); (( SEC<0 )) && SEC=0
      d=$((SEC/86400)); h=$(((SEC%86400)/3600)); m=$(((SEC%3600)/60))
      UPTIME=$(printf "%dd %02dh %02dm" "$d" "$h" "$m")
    fi
  fi

  echo -e "${cBold}${cC}Статус:${c0}  $STATUS  ${cDim}(running=$RUNNING, health=${HEALTH:-n/a})${c0}"
  echo -e "${cBold}${cC}Аптайм:${c0}  $UPTIME"

  # ports
  PORTS="$(docker inspect -f '{{range $p,$v := .NetworkSettings.Ports}}{{printf "%s -> " $p}}{{range $i, $b := $v}}{{printf "%s:%s " $b.HostIp $b.HostPort}}{{end}}{{printf "\n"}}{{end}}' "$CID" 2>/dev/null | sed '/^$/d' || true)"
  echo -e "${cBold}${cC}Порты:${c0}"
  if [[ -n "$PORTS" ]]; then echo "$PORTS" | sed 's/^/  /'; else echo "  -"; fi
  hr

  # stats
  STATS="$(docker stats "$CID" --no-stream --format '{{.CPUPerc}};{{.MemUsage}};{{.MemPerc}};{{.NetIO}};{{.BlockIO}};{{.PIDs}}' 2>/dev/null || true)"
  if [[ -n "$STATS" ]]; then
    IFS=';' read -r CPU_P MEM_USAGE MEM_P NET_IO BLK_IO PIDS <<< "$STATS"
    CPU_P="${CPU_P//[^0-9.,]/}"
    echo -e "${cBold}${cG}CPU:${c0}       ${CPU_P:-0}%"
    echo -e "${cBold}${cG}RAM:${c0}       ${MEM_USAGE:-0/0}  (${MEM_P:-0})  PIDs: ${PIDS:-0}"
    echo -e "${cBold}${cG}Net I/O:${c0}   ${NET_IO:-0B/0B}   ${cBold}${cG}Block I/O:${c0} ${BLK_IO:-0B/0B}"
  fi
fi

# -------- Toolchain (умный учет размеров) --------
hr
echo -e "${cBold}${cM}Toolchain${c0}"
hr

TOTAL_BYTES=0
TOOL_BYTES=0

# утилита печати и учета
print_tool(){
  # $1 label  $2 version_text  $3 path  $4 bytes
  printf "%-18s %s\n" "$1:" "${cG}${2}${c0}"
  printf "%-18s %s\n" "  path:" "${cDim}${3}${c0}"
  printf "%-18s %s\n\n" "  size:" "${cC}$(fmt_bytes "$4")${c0}"
  TOOL_BYTES=$((TOOL_BYTES + $4))
}

# arcium
arcium_path="$(which_path arcium)"
if [[ -n "$arcium_path" ]]; then
  arcium_ver="$(arcium --version 2>/dev/null | first_line || echo 'arcium')"
  arcium_real="$(realpath_safe "$arcium_path")"
  arcium_bytes="$(bytes_of_file "$arcium_real")"
  # плюс весь ~/.arcium/bin если есть
  arcium_bin_dir="$HOME/.arcium/bin"
  if [[ -d "$arcium_bin_dir" ]]; then
    extra="$(bytes_of_dir "$arcium_bin_dir")"
    ((extra>arcium_bytes)) && arcium_bytes="$extra"
  fi
  print_tool "arcium" "$arcium_ver" "$arcium_path" "$arcium_bytes"
fi

# arcup
arcup_path="$(which_path arcup)"
if [[ -n "$arcup_path" ]]; then
  arcup_ver="$(arcup --version 2>/dev/null | first_line || echo 'arcup')"
  arcup_bytes="$(bytes_of_file "$(realpath_safe "$arcup_path")")"
  print_tool "arcup" "$arcup_ver" "$arcup_path" "$arcup_bytes"
fi

# anchor
anchor_path="$(which_path anchor)"
if [[ -n "$anchor_path" ]]; then
  anchor_ver="$(anchor --version 2>/dev/null | first_line || echo 'anchor')"
  anchor_bytes="$(bytes_of_file "$(realpath_safe "$anchor_path")")"
  print_tool "anchor" "$anchor_ver" "$anchor_path" "$anchor_bytes"
fi

# solana / solana-keygen — считаем всю active_release
sol_path="$(which_path solana)"
if [[ -n "$sol_path" ]]; then
  sol_ver="$(solana --version 2>/dev/null | first_line || echo 'solana')"
  sol_real="$(realpath_safe "$sol_path")"
  sol_dir="$(dirname "$sol_real")"       # .../active_release/bin
  sol_active="$(dirname "$sol_dir")"     # .../active_release
  if [[ -d "$sol_active" ]]; then
    sol_bytes="$(bytes_of_dir "$sol_active")"
  else
    sol_bytes="$(bytes_of_file "$sol_real")"
  fi
  print_tool "solana" "$sol_ver" "$sol_path" "$sol_bytes"
fi

skg_path="$(which_path solana-keygen)"
if [[ -n "$skg_path" && -d "$sol_active" ]]; then
  # уже учтён весь active_release — чтобы не двойной счет, покажем как алиас нулем
  print_tool "solana-keygen" "$(solana-keygen --version 2>/dev/null | first_line || echo 'solana-keygen')" "$skg_path" 0
fi

# rust — считаем ~/.rustup + ~/.cargo
rustc_path="$(which_path rustc)"
cargo_path="$(which_path cargo)"
if [[ -n "$rustc_path" || -n "$cargo_path" ]]; then
  rust_ver="$(rustc --version 2>/dev/null | first_line || echo 'rustc')"
  cargo_ver="$(cargo --version 2>/dev/null | first_line || echo 'cargo')"
  rustup_dir="$HOME/.rustup"
  cargo_dir="$HOME/.cargo"
  ru_bytes=0
  [[ -d "$rustup_dir" ]] && ru_bytes=$((ru_bytes + $(bytes_of_dir "$rustup_dir")))
  [[ -d "$cargo_dir"  ]] && ru_bytes=$((ru_bytes + $(bytes_of_dir "$cargo_dir")))
  # показываем как “rust toolchain”
  print_tool "rust toolchain" "$rust_ver; $cargo_ver" "${rustup_dir}, ${cargo_dir}" "$ru_bytes"
fi

# node (nvm) — считаем всю директорию версии
node_path="$(which_path node)"
if [[ -n "$node_path" ]]; then
  node_ver="$(node -v 2>/dev/null | first_line || echo 'node')"
  node_real="$(realpath_safe "$node_path")"
  node_version_dir="$(echo "$node_real" | sed -n 's|\(.*\.nvm/versions/node/v[^/]*\)/bin/node|\1|p')"
  if [[ -n "$node_version_dir" && -d "$node_version_dir" ]]; then
    node_bytes="$(bytes_of_dir "$node_version_dir")"
  else
    node_bytes="$(bytes_of_file "$node_real")"
  fi
  print_tool "node" "$node_ver" "$node_path" "$node_bytes"
fi

# yarn — если это corepack, считаем папку corepack
yarn_path="$(which_path yarn)"
if [[ -n "$yarn_path" ]]; then
  yarn_ver="$(yarn -v 2>/dev/null | first_line || echo 'yarn')"
  yarn_real="$(realpath_safe "$yarn_path")"
  corepack_dir="/usr/lib/node_modules/corepack"
  if [[ -d "$corepack_dir" ]]; then
    yarn_bytes="$(bytes_of_dir "$corepack_dir")"
    print_tool "yarn (corepack)" "$yarn_ver" "$yarn_path" "$yarn_bytes"
  else
    yarn_bytes="$(bytes_of_file "$yarn_real")"
    print_tool "yarn" "$yarn_ver" "$yarn_path" "$yarn_bytes"
  fi
fi

# docker — бинарь
docker_path="$(which_path docker)"
if [[ -n "$docker_path" ]]; then
  docker_ver="$(docker --version 2>/dev/null | first_line || echo 'docker')"
  docker_bytes="$(bytes_of_file "$(realpath_safe "$docker_path")")"
  print_tool "docker" "$docker_ver" "$docker_path" "$docker_bytes"
fi

# docker compose — плагин
compose_bytes=0
if docker compose version >/dev/null 2>&1; then
  compose_ver="$(docker compose version | head -1)"
  # популярные пути плагина
  for p in \
    "/usr/libexec/docker/cli-plugins/docker-compose" \
    "/usr/lib/docker/cli-plugins/docker-compose" \
    "/usr/local/lib/docker/cli-plugins/docker-compose"
  do
    if [[ -f "$p" ]]; then
      compose_bytes="$(bytes_of_file "$p")"
      compose_path="$p"
      break
    fi
  done
  [[ -z "${compose_path:-}" ]] && compose_path="docker compose (plugin)"
  print_tool "docker compose" "$compose_ver" "$compose_path" "$compose_bytes"
fi

# -------- ИТОГО --------
TOTAL_BYTES=0
echo; hr
echo -e "${cBold}${cM}ИТОГО по Arcium${c0}"
hr
add_total "BASE_DIR" "${BASE_BYTES:-0}"
add_total "LOGS_DIR" "${LOGS_BYTES:-0}"
add_total "Docker image" "${IMG_BYTES:-0}"
add_total "Toolchain" "${TOOL_BYTES:-0}"
hr
echo -e "${cBold}${cG}Общий размер:${c0}  $(fmt_bytes "$TOTAL_BYTES")"
hr
