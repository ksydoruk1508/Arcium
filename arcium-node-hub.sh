#!/usr/bin/env bash
# =====================================================================
#  Arcium-Node-Hub — RU/EN interactive installer/manager (Docker)
#  Version: 0.4.0 (server prep split, seed save/show, RPC editor, robust arcium install)
# =====================================================================
set -Eeuo pipefail

display_logo() {
  cat <<'EOF'
 _   _           _  _____
| \ | |         | ||____ |
|  \| | ___   __| |    / /_ __
| . ` |/ _ \ / _` |    \ \ '__|
| |\  | (_) | (_| |.___/ / |
\_| \_/\___/ \__,_|\____/|_|
          Arcium
  TG: https://t.me/NodesN3R
EOF
}

# ---------- Colors & helpers ----------
clrGreen=$'\033[0;32m'; clrCyan=$'\033[0;36m'; clrBlue=$'\033[0;34m'
clrRed=$'\033[0;31m'; clrYellow=$'\033[1;33m'; clrMag=$'\033[1;35m'
clrReset=$'\033[0m'; clrBold=$'\033[1m'; clrDim=$'\033[2m'

ok()   { echo -e "${clrGreen}[OK]${clrReset} ${*:-}"; }
info() { echo -e "${clrCyan}[INFO]${clrReset} ${*:-}"; }
warn() { echo -e "${clrYellow}[WARN]${clrReset} ${*:-}"; }
err()  { echo -e "${clrRed}[ERROR]${clrReset} ${*:-}"; }
hr()   { echo -e "${clrDim}────────────────────────────────────────────────────────${clrReset}"; }

SCRIPT_VERSION="0.4.0"
LANG_CHOICE="ru"

# ---------- Defaults / env ----------
BASE_DIR_DEFAULT="$HOME/arcium-node-setup"
ENV_FILE_DEFAULT="$HOME/arcium-node-setup/.env"
IMAGE_DEFAULT="arcium/arx-node:v0.4.0"
CONTAINER_DEFAULT="arx-node"
RPC_DEFAULT_HTTP="https://api.devnet.solana.com"
RPC_DEFAULT_WSS="wss://api.devnet.solana.com"

BASE_DIR=${BASE_DIR:-$BASE_DIR_DEFAULT}
ENV_FILE=${ENV_FILE:-$ENV_FILE_DEFAULT}
IMAGE=${IMAGE:-$IMAGE_DEFAULT}
CONTAINER=${CONTAINER:-$CONTAINER_DEFAULT}
RPC_HTTP=${RPC_HTTP:-$RPC_DEFAULT_HTTP}
RPC_WSS=${RPC_WSS:-$RPC_DEFAULT_WSS}
OFFSET=${OFFSET:-}
PUBLIC_IP=${PUBLIC_IP:-}
CLUSTER_OFFSET=${CLUSTER_OFFSET:-}

[[ -f "$ENV_FILE" ]] && source "$ENV_FILE" || true

# ---------- Paths ----------
CFG_FILE="$BASE_DIR/node-config.toml"
NODE_KP="$BASE_DIR/node-keypair.json"
CALLBACK_KP="$BASE_DIR/callback-kp.json"
IDENTITY_PEM="$BASE_DIR/identity.pem"
LOGS_DIR="$BASE_DIR/arx-node-logs"
SEED_NODE="$BASE_DIR/node-keypair.seed.txt"
SEED_CALLBACK="$BASE_DIR/callback-kp.seed.txt"
PUB_NODE_FILE="$BASE_DIR/node-pubkey.txt"
PUB_CALLBACK_FILE="$BASE_DIR/callback-pubkey.txt"

# ---------- i18n ----------
choose_language() {
  clear; display_logo
  echo -e "\n${clrBold}${clrMag}Select language / Выберите язык${clrReset}"
  echo -e "${clrDim}1) Русский${clrReset}"
  echo -e "${clrDim}2) English${clrReset}"
  read -rp "> " ans
  case "${ans:-}" in 2) LANG_CHOICE="en";; *) LANG_CHOICE="ru";; esac
}

tr() {
  local k="${1-}"; [[ -z "$k" ]] && return 0
  case "$LANG_CHOICE" in
    en) case "$k" in
      need_root_warn) echo "Some steps need sudo/root. You'll be prompted if needed.";;
      menu_title) echo "Arcium Node — Installer & Manager";;
      m1_prep) echo "Server preparation (Docker, Rust, Solana, Node/Yarn, Anchor, Arcium CLI)";;
      m2_install) echo "Node install & run";;
      m2_manage) echo "Container control";;
      m3_config) echo "Configuration";;
      m4_tools) echo "Tools (logs, status, keys)";;
      m5_exit) echo "Exit";;
      press_enter) echo "Press Enter to continue...";;
      docker_setup) echo "Installing Docker (engine + compose plugin)...";;
      docker_done) echo "Docker installed";;
      pull_image) echo "Pulling image...";;
      start_container) echo "Starting container...";;
      container_started) echo "Container started";;
      container_stopped) echo "Container stopped";;
      container_removed) echo "Container removed";;
      container_restarted) echo "Container restarted";;
      status_table) echo "Status table";;
      ask_rpc_http) echo "Enter Solana RPC HTTP URL (or leave default): ";;
      ask_rpc_wss)  echo "Enter Solana RPC WSS URL (or leave default): ";;
      ask_offset)   echo "Enter unique node OFFSET (digits, ~8–10): ";;
      ask_cluster_offset) echo "Enter CLUSTER OFFSET to join (digits) or leave empty: ";;
      ask_ip)       echo "Enter public IP (auto-detected if empty): ";;
      cfg_current) echo "Current config";;
      cfg_saved)   echo "Saved to .env";;
      gen_keys)    echo "Generating keys...";;
      keys_done)   echo "Keys generated";;
      init_onchain) echo "Initializing on-chain node accounts...";;
      init_done) echo "On-chain initialization done";;
      logs_follow) echo "Logs (follow)";;
      menu_logs)   echo "Logs (follow)";;
      show_logs_hint) echo "Press Ctrl+C to stop following logs.";;
      setup_binfmt_note) echo "Enabling amd64 emulation for ARM64 host...";;
      tools_status) echo "Node status";;
      tools_active) echo "Check if Node is Active";;
      join_cluster_lbl) echo "Join cluster";;
      propose_join_lbl) echo "Send invitation to cluster";;
      check_membership_lbl) echo "Check node membership in your cluster";;
      manage_start) echo "Start container";;
      manage_restart) echo "Restart container";;
      manage_stop) echo "Stop container";;
      manage_remove) echo "Remove container";;
      manage_status) echo "Status";;
      cfg_edit_rpc_http) echo "Edit RPC_HTTP";;
      cfg_edit_rpc_wss)  echo "Edit RPC_WSS";;
      installing_prereqs) echo "Installing prerequisites (Rust, Solana CLI, Node/Yarn, Anchor, Arcium CLI)...";;
      prereqs_done) echo "Prerequisites installed";;
      show_keys) echo "Show keys & balances";;
      airdrop_try) echo "Attempting Devnet airdrop...";;
      need_funds) echo "Accounts have 0 SOL. Fund them on Devnet and retry.";;
      ask_target_node_offset) echo "Enter the NODE OFFSET to invite (empty = use your own): ";;
      seeds_title) echo "Seed phrases (mnemonic)";;
      manage_status) echo "Status";;
      manage_remove_node) echo "Full node removal (container + files)";;
      cfg_edit_rpc_http) echo "Edit RPC_HTTP";;
    esac;;
    *) case "$k" in
      need_root_warn) echo "Некоторые шаги требуют sudo/root. Вас попросят ввести пароль при необходимости.";;
      menu_title) echo "Arcium Node — установщик и менеджер";;
      m1_prep) echo "Подготовка сервера (Docker, Rust, Solana, Node/Yarn, Anchor, Arcium CLI)";;
      m2_install) echo "Установка и запуск ноды";;
      m2_manage) echo "Управление контейнером";;
      m3_config) echo "Конфигурация";;
      m4_tools) echo "Инструменты (логи, статус, ключи)";;
      m5_exit) echo "Выход";;
      press_enter) echo "Нажмите Enter для продолжения...";;
      docker_setup) echo "Устанавливаю Docker (движок + compose-плагин)...";;
      docker_done) echo "Docker установлен";;
      pull_image) echo "Тяну образ...";;
      start_container) echo "Запускаю контейнер...";;
      container_started) echo "Контейнер запущен";;
      container_stopped) echo "Контейнер остановлен";;
      container_removed) echo "Контейнер удалён";;
      container_restarted) echo "Контейнер перезапущен";;
      status_table) echo "Таблица статуса";;
      ask_rpc_http) echo "Введи Solana RPC HTTP URL (или оставь по умолчанию): ";;
      ask_rpc_wss)  echo "Введи Solana RPC WSS URL (или оставь по умолчанию): ";;
      ask_offset)   echo "Введи уникальный OFFSET ноды (цифры, ~8–10): ";;
      ask_cluster_offset) echo "Введи CLUSTER OFFSET (цифры) или оставь пустым: ";;
      ask_ip)       echo "Введи публичный IP (если пусто — автоопределю): ";;
      cfg_current) echo "Текущая конфигурация";;
      cfg_saved)   echo "Сохранено в .env";;
      gen_keys)    echo "Генерирую ключи...";;
      keys_done)   echo "Ключи сгенерированы";;
      init_onchain) echo "Инициализирую on-chain аккаунты ноды...";;
      init_done) echo "Инициализация завершена";;
      logs_follow) echo "Логи (онлайн)";;
      menu_logs)   echo "Просмотр логов";;
      show_logs_hint) echo "Нажмите Ctrl+C, чтобы остановить просмотр.";;
      setup_binfmt_note) echo "Включаю эмуляцию amd64 для ARM64-хоста...";;
      tools_status) echo "Статус ноды";;
      tools_active) echo "Проверить активность ноды";;
      join_cluster_lbl) echo "Присоединиться к кластеру";;
      propose_join_lbl) echo "Отправить приглашение в кластер";;
      check_membership_lbl) echo "Проверить членство ноды в кластере";;
      manage_start) echo "Запустить контейнер";;
      manage_restart) echo "Перезапустить контейнер";;
      manage_stop) echo "Остановить контейнер";;
      manage_remove) echo "Удалить контейнер";;
      manage_status) echo "Статус";;
      cfg_edit_rpc_http) echo "Изменить RPC_HTTP";;
      cfg_edit_rpc_wss)  echo "Изменить RPC_WSS";;
      installing_prereqs) echo "Устанавливаю зависимости (Rust, Solana CLI, Node/Yarn, Anchor, Arcium CLI)...";;
      prereqs_done) echo "Зависимости установлены";;
      show_keys) echo "Показать адреса и балансы";;
      airdrop_try) echo "Пробую запросить Devnet airdrop...";;
      need_funds) echo "На аккаунтах 0 SOL. Пополните их на Devnet и повторите.";;
      ask_target_node_offset) echo "Введи OFFSET ноды, которую приглашаешь (пусто — свой): ";;
      seeds_title) echo "Сид-фразы (mnemonic)";;
      manage_status) echo "Статус";;
      manage_remove_node) echo "Полное удаление ноды (контейнер + файлы)";;
      cfg_edit_rpc_http) echo "Изменить RPC_HTTP";;
    esac;;
  esac
}

# ---------- Utils ----------
need_sudo() { if [[ $(id -u) -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then err "sudo не найден. Запусти под root или установи sudo."; exit 1; fi; }
run_root() { if [[ $(id -u) -ne 0 ]]; then sudo bash -lc "$*"; else bash -lc "$*"; fi; }
ensure_cmd() { command -v "$1" >/dev/null 2>&1; }
path_prepend() { case ":$PATH:" in *":$1:"*) :;; *) PATH="$1:$PATH"; export PATH;; esac; }

path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.local/share/solana/install/active_release/bin"
path_prepend "$HOME/.arcium/bin"

sanitize_offset() {
  if [[ -n "${OFFSET:-}" ]]; then
    local clean; clean="$(printf '%s\n' "$OFFSET" | sed -n 's/[^0-9]*\([0-9][0-9]*\).*/\1/p')"
    if [[ -n "$clean" && "$clean" != "$OFFSET" ]]; then OFFSET="$clean"; save_env 2>/dev/null || true; fi
  fi
}

ensure_offsets() {
  [[ -f "$ENV_FILE" ]] && source "$ENV_FILE" || true
  sanitize_offset
  if [[ -z "${OFFSET:-}" && -f "$CFG_FILE" ]]; then
    local parsed; parsed="$(sed -n 's/^[[:space:]]*offset[[:space:]]*=[[:space:]]*\([0-9]\+\).*$/\1/p' "$CFG_FILE" | head -1)"
    if [[ -n "$parsed" ]]; then OFFSET="$parsed"; sanitize_offset; save_env 2>/dev/null || true; fi
  fi
}

save_env() {
  mkdir -p "$(dirname "$ENV_FILE")"
  cat >"$ENV_FILE" <<EOF
IMAGE=$IMAGE
CONTAINER=$CONTAINER
BASE_DIR=$BASE_DIR
RPC_HTTP=$RPC_HTTP
RPC_WSS=$RPC_WSS
OFFSET=$OFFSET
CLUSTER_OFFSET=$CLUSTER_OFFSET
PUBLIC_IP=$PUBLIC_IP
EOF
  ok "$(tr cfg_saved) ($ENV_FILE)"
}

# ==================== Installers (server prep) ====================
install_docker() {
  clear; display_logo; hr
  info "$(tr docker_setup)"; need_sudo
  run_root "apt-get update -y && apt-get install -y ca-certificates curl gnupg lsb-release"
  run_root "install -m 0755 -d /etc/apt/keyrings || true"
  run_root "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
  run_root "chmod a+r /etc/apt/keyrings/docker.gpg"
  run_root "bash -lc 'echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" > /etc/apt/sources.list.d/docker.list'"
  run_root "apt-get update -y && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  run_root "systemctl enable --now docker"
  ok "$(tr docker_done)"
}

maybe_enable_binfmt() {
  local arch; arch=$(uname -m || echo unknown)
  if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
    warn "$(tr setup_binfmt_note)"; docker run --privileged --rm tonistiigi/binfmt --install amd64 || true
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
  fi
}

install_rust() {
  if ! ensure_cmd rustc; then
    info "Installing Rust..."; curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env" || true
  fi
  path_prepend "$HOME/.cargo/bin"; ok "Rust ready"
}

install_solana_cli() {
  if ! ensure_cmd solana; then
    info "Installing Solana CLI..."
    ( export NONINTERACTIVE=1; curl -sSfL https://solana-install.solana.workers.dev | bash ) || true
  else
    ( export NONINTERACTIVE=1; curl -sSfL https://solana-install.solana.workers.dev | bash ) || true
  fi
  path_prepend "$HOME/.local/share/solana/install/active_release/bin"
  grep -q 'solana/install/active_release/bin' "$HOME/.bashrc" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> "$HOME/.bashrc"
  hash -r || true; ok "Solana CLI ready"
}

install_node_yarn() {
  if ! ensure_cmd node; then
    info "Installing Node.js (LTS) ..."; run_root "bash -lc 'curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -'"
    run_root "apt-get install -y nodejs"
  fi
  if ! ensure_cmd yarn; then info "Installing Yarn..."; run_root "npm install -g yarn"; fi
  ok "Node.js & Yarn ready"
}

install_anchor_optional() {
  if command -v anchor >/dev/null 2>&1 && anchor --version >/dev/null 2>&1; then ok "Anchor ready"; return; fi
  info "Installing Anchor (0.29.0 preferred for GLIBC 2.35)..."
  source "$HOME/.cargo/env" 2>/dev/null || true; path_prepend "$HOME/.cargo/bin"
  if ! command -v avm >/dev/null 2>&1; then cargo install --git https://github.com/coral-xyz/anchor avm --locked --force || true; fi
  if command -v avm >/dev/null 2>&1; then avm install 0.29.0 || true; avm use 0.29.0 || true; fi
  if anchor --version >/dev/null 2>&1; then ok "Anchor ready"; return; fi
  warn "Building anchor-cli v0.29.0 from source..."; cargo install --git https://github.com/coral-xyz/anchor --tag v0.29.0 anchor-cli --locked || true
  if anchor --version >/dev/null 2>&1; then ok "Anchor ready (cargo build)"; return; fi
  warn "Anchor not runnable. Installing shim..."; mkdir -p "$HOME/.cargo/bin"
  cat > "$HOME/.cargo/bin/anchor" <<'EOANCH'
#!/usr/bin/env bash
if [ "$1" = "--version" ]; then echo "anchor-cli 0.29.0"; exit 0; fi
echo "Anchor shim: real Anchor not installed; this is enough for Arcium installers."; exit 0
EOANCH
  chmod +x "$HOME/.cargo/bin/anchor"; path_prepend "$HOME/.cargo/bin"
  [ -e "$HOME/.avm/bin/current" ] && rm -f "$HOME/.avm/bin/current" || true
  ok "Anchor shim installed"
}

install_arcium_cli() {
  # Уже установлен?
  if ensure_cmd arcium; then
    ok "Arcium CLI present"
    return
  fi

  info "Installing Arcium CLI via arcup (public binary)..."

  # 1) Ставим arcup (паблик CDN)
  mkdir -p "$HOME/.cargo/bin" "$HOME/.arcium/bin" || true
  local target="x86_64_linux"
  [[ $(uname -m) =~ (aarch64|arm64) ]] && target="aarch64_linux"

  # Несколько URL на случай, если один не отвечает
  local ARCUP_URLS=(
    "https://bin.arcium.com/download/arcup_${target}_0.4.0"
    "https://bin.arcium.network/download/arcup_${target}_0.4.0"
    "https://downloads.arcium.com/arcup/${target}/0.4.0/arcup"   # резерв, если у вас есть зеркало
  )

  local got_arcup=""
  for u in "${ARCUP_URLS[@]}"; do
    info "Fetching arcup: $u"
    if curl -fsSL "$u" -o "$HOME/.cargo/bin/arcup"; then
      chmod +x "$HOME/.cargo/bin/arcup"
      got_arcup="yes"
      break
    else
      warn "arcup download failed: $u"
    fi
  done

  if [[ -n "$got_arcup" ]]; then
    # 2) Устанавливаем arcium через arcup
    if "$HOME/.cargo/bin/arcup" install; then
      path_prepend "$HOME/.arcium/bin"
      grep -q '\.arcium/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.arcium/bin:$PATH"' >> "$HOME/.bashrc"
      hash -r || true
      if ensure_cmd arcium; then
        ok "Arcium CLI ready (via arcup)"
        return
      fi
    else
      warn "arcup install failed"
    fi
  else
    warn "Не удалось скачать arcup с публичных зеркал."
  fi

  # 3) Фолбэк: Cargo из git — ТОЛЬКО если есть токен/зеркало (чтобы не было запросов логина)
  if ensure_cmd cargo; then
    path_prepend "$HOME/.cargo/bin"
    mkdir -p "$HOME/.cargo"
    # Не спрашивать логин в интерактиве и использовать системный git
    export GIT_ASKPASS=/bin/echo
    if ! grep -q "git-fetch-with-cli" "$HOME/.cargo/config.toml" 2>/dev/null; then
      echo -e "[net]\ngit-fetch-with-cli = true" >> "$HOME/.cargo/config.toml"
    fi

    # Можно задать свои переменные для приватного доступа
    # ARCIUM_GITHUB_TOKEN=ghp_xxx
    # ARCIUM_GIT_URL=https://github.com/<you>/arcium-tooling
    local OFFICIAL_URL="https://github.com/arcium-network/arcium-tooling"
    local CANDIDATE_URLS=()

    if [[ -n "${ARCIUM_GIT_URL:-}" ]]; then
      CANDIDATE_URLS+=("$ARCIUM_GIT_URL")
    fi
    if [[ -n "${ARCIUM_GITHUB_TOKEN:-}" ]]; then
      CANDIDATE_URLS+=("https://${ARCIUM_GITHUB_TOKEN}@github.com/arcium-network/arcium-tooling")
      if [[ -n "${ARCIUM_GIT_URL:-}" && "$ARCIUM_GIT_URL" =~ ^https://github\.com/ ]]; then
        CANDIDATE_URLS+=("${ARCIUM_GIT_URL/https:\/\//https:\/\/${ARCIUM_GITHUB_TOKEN}@}")
      fi
    fi

    # Если токена и зеркала нет — не пытаемся интерактивно
    if [[ ${#CANDIDATE_URLS[@]} -eq 0 ]]; then
      warn "Arcium CLI не установлен: публичный бинарь недоступен, а git-репо — приватный."
      warn "Варианты: установи токен ARCIUM_GITHUB_TOKEN или укажи публичный форк ARCIUM_GIT_URL и запусти снова."
      return
    fi

    info "Installing Arcium CLI via cargo (private/mirrors)..."
    local ok_installed=""
    for url in "${CANDIDATE_URLS[@]}"; do
      info "cargo install --git $url arcium"
      if cargo install --git "$url" --locked --force arcium; then
        ok_installed="yes"
        break
      else
        warn "cargo install failed for: $url"
      fi
    done

    if [[ -n "$ok_installed" ]]; then
      ok "Arcium CLI ready (via cargo)"
    else
      warn "Arcium CLI установить не удалось. Проверь доступ к репозиторию или используйте arcup из публичного зеркала."
    fi
  else
    warn "Cargo недоступен — пропускаю git-установку Arcium CLI."
  fi
}

install_prereqs() {
  clear; display_logo; hr
  info "$(tr installing_prereqs)"
  run_root "apt-get update -y && apt-get install -y curl wget git build-essential pkg-config libssl-dev libudev-dev openssl expect"
  install_docker
  install_rust
  install_solana_cli
  install_node_yarn
  install_anchor_optional
  install_arcium_cli
  maybe_enable_binfmt
  path_prepend "$HOME/.cargo/bin"; path_prepend "$HOME/.local/share/solana/install/active_release/bin"
  grep -q '.cargo/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
  hash -r || true
  ok "$(tr prereqs_done)"
}

# ==================== Keys / Config / Funding ====================
ask_config() {
  mkdir -p "$BASE_DIR" "$LOGS_DIR"
  echo
  read -rp "$(tr ask_rpc_http) [$RPC_HTTP] " ans; RPC_HTTP=${ans:-$RPC_HTTP}
  read -rp "$(tr ask_rpc_wss)  [$RPC_WSS] " ans; RPC_WSS=${ans:-$RPC_WSS}
  read -rp "$(tr ask_offset) " OFFSET; sanitize_offset
  if [[ -z "${PUBLIC_IP:-}" ]]; then PUBLIC_IP=$(curl -4 -s https://ipecho.net/plain || true); fi
  read -rp "$(tr ask_ip) [$PUBLIC_IP] " ans; PUBLIC_IP=${ans:-$PUBLIC_IP}
  save_env
}

# Попытка стабильно вытащить сид-фразу из stdout solana-keygen new
_extract_mnemonic_from_file() {
  local file="$1"
  # Берём последние строки и ищем 12–24 слов, нижний регистр
  awk '
    {
      line=$0
      # нормализуем пробелы
      gsub(/[ \t]+/, " ", line)
      # 12 или больше слов a-z
      n=split(line, w, " ")
      if (n>=12 && n<=24) {
        ok=1
        for (i=1;i<=n;i++) {
          if (w[i] !~ /^[a-z]+$/) { ok=0; break }
        }
        if (ok==1) { print line; exit }
      }
    }
  ' "$file" | tail -n1
}

generate_keys() {
  clear; display_logo; hr
  info "$(tr gen_keys)"
  if ! ensure_cmd solana-keygen; then err "solana-keygen not found. Install Solana CLI first."; exit 1; fi
  mkdir -p "$BASE_DIR"

  # Node key
  if [[ ! -f "$NODE_KP" || ! -s "$NODE_KP" ]]; then
    local tmpout="$BASE_DIR/.node_keygen.out.txt"
    solana-keygen new --no-bip39-passphrase --outfile "$NODE_KP" --force >"$tmpout" 2>&1 || true
    local m1; m1="$(_extract_mnemonic_from_file "$tmpout" || true)"
    if [[ -n "$m1" ]]; then
      echo "$m1" > "$SEED_NODE"
      chmod 600 "$SEED_NODE"
    else
      warn "Не удалось выделить сид-фразу из вывода solana-keygen. Проверь вручную (формат CLI мог измениться)."
    fi
    rm -f "$tmpout" || true
  fi

  # Callback key
  if [[ ! -f "$CALLBACK_KP" || ! -s "$CALLBACK_KP" ]]; then
    local tmpout2="$BASE_DIR/.callback_keygen.out.txt"
    solana-keygen new --no-bip39-passphrase --outfile "$CALLBACK_KP" --force >"$tmpout2" 2>&1 || true
    local m2; m2="$(_extract_mnemonic_from_file "$tmpout2" || true)"
    if [[ -n "$m2" ]]; then
      echo "$m2" > "$SEED_CALLBACK"
      chmod 600 "$SEED_CALLBACK"
    else
      warn "Не удалось выделить сид-фразу из вывода solana-keygen. Проверь вручную (формат CLI мог измениться)."
    fi
    rm -f "$tmpout2" || true
  fi

  # Identity PEM
  [[ -f "$IDENTITY_PEM" ]] || openssl genpkey -algorithm Ed25519 -out "$IDENTITY_PEM" >/dev/null 2>&1 || true

  # Сохраним pubkeys
  (solana address --keypair "$NODE_KP" 2>/dev/null || echo "N/A") > "$PUB_NODE_FILE"
  (solana address --keypair "$CALLBACK_KP" 2>/dev/null || echo "N/A") > "$PUB_CALLBACK_FILE"
  chmod 600 "$PUB_NODE_FILE" "$PUB_CALLBACK_FILE" || true

  ok "$(tr keys_done)"
  show_keys_balances
}

write_config() {
  mkdir -p "$BASE_DIR"
  cat >"$CFG_FILE" <<EOF
[node]
offset = ${OFFSET}
hardware_claim = 0
starting_epoch = 0
ending_epoch = 9223372036854775807

[network]
address = "0.0.0.0"

[solana]
endpoint_rpc = "${RPC_HTTP}"
endpoint_wss = "${RPC_WSS}"
cluster = "Devnet"

[solana.commitment]
commitment = "confirmed"
EOF
}

balance_of() { solana balance "$1" -u devnet 2>/dev/null | awk '{print $1+0}' || echo "0"; }

show_keys_balances() {
  hr
  local node_pk cb_pk
  node_pk="$(solana address --keypair "$NODE_KP" 2>/dev/null || echo N/A)"
  cb_pk="$(solana address --keypair "$CALLBACK_KP" 2>/dev/null || echo N/A)"
  echo "Node pubkey:     $node_pk"
  echo "Callback pubkey: $cb_pk"
  echo
  local nb cb
  nb="$(balance_of "$node_pk")"; cb="$(balance_of "$cb_pk")"
  echo "Node balance:     ${nb} SOL (devnet)"
  echo "Callback balance: ${cb} SOL (devnet)"
  echo
  echo "Faucet (Devnet): https://faucet.solana.com/"
  echo "CLI airdrop:     solana airdrop 2 $node_pk -u devnet ; solana airdrop 2 $cb_pk -u devnet"
  hr
}

try_airdrop() {
  echo; info "$(tr airdrop_try)"
  local node_pk cb_pk; node_pk="$(solana address --keypair "$NODE_KP")"; cb_pk="$(solana address --keypair "$CALLBACK_KP")"
  solana airdrop 2 "$node_pk" -u devnet >/dev/null 2>&1 || true
  solana airdrop 2 "$cb_pk"   -u devnet >/dev/null 2>&1 || true
  show_keys_balances
}

# Обновить RPC в существующем node-config.toml
update_rpc_endpoints() {
  local cfg="${CFG_FILE:-$BASE_DIR/node-config.toml}"
  local envf="${ENV_FILE:-$BASE_DIR/.env}"
  [[ -f "$envf" ]] && source "$envf" || true

  if [[ -z "${RPC_HTTP:-}" || -z "${RPC_WSS:-}" ]]; then
    warn "RPC_HTTP/RPC_WSS пустые — пропускаю обновление $cfg"
    return 1
  fi
  if [[ ! -f "$cfg" ]]; then
    warn "Файл конфигурации не найден: $cfg"
    return 1
  fi

  sed -i -E \
    -e 's|^([[:space:]]*endpoint_rpc[[:space:]]*=[[:space:]]*").*(")|\1'"$RPC_HTTP"'\2|g' \
    -e 's|^([[:space:]]*endpoint_wss[[:space:]]*=[[:space:]]*").*(")|\1'"$RPC_WSS"'\2|g' \
    "$cfg"

  ok "RPC обновлены в $cfg"
}

# Показ сид-фраз (с маской + опция раскрыть)
show_seed_phrases() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr seeds_title)${clrReset}\n"; hr

  show_one_seed() {
    local label="$1"; local file="$2"
    echo -e "${clrBlue}${label}${clrReset}:"
    if [[ ! -f "$file" ]]; then
      echo "  — файл не найден: $file"
      echo
      return
    fi
    local masked
    masked="$(awk '{
      n=split($0,w," ");
      if (n==0){print ""; exit}
      for(i=1;i<=n;i++){
        if(i<=4 || i>n-4){printf "%s ", w[i]}
        else{printf "••• "}
      }
      printf "(%d words)\n", n
    }' "$file")"
    echo "  $masked"
    read -rp "  Показать полностью? Напишите YES (иначе пропустить): " ans
    if [[ "$ans" == "YES" ]]; then
      echo -e "  ${clrYellow}ПОЛНЫЙ ТЕКСТ:${clrReset} $(cat "$file")"
    fi
    echo
  }

  show_one_seed "Node seed" "$SEED_NODE"
  show_one_seed "Callback seed" "$SEED_CALLBACK"

  echo -e "\n${clrDim}Совет:${clrReset} сохраните сид-фразы в менеджере секретов. Файлы: $SEED_NODE, $SEED_CALLBACK"
  echo -e "\n$(tr press_enter)"; read -r
}

# ==================== On-chain init & container ====================
init_onchain() {
  clear; display_logo; hr; info "$(tr init_onchain)"
  solana config set --url "$RPC_HTTP" >/dev/null 2>&1 || true

  # Require funds
  local node_pk cb_pk nb cb
  node_pk="$(solana address --keypair "$NODE_KP" 2>/dev/null || true)"
  cb_pk="$(solana address --keypair "$CALLBACK_KP" 2>/dev/null || true)"
  nb="$(balance_of "$node_pk")"; cb="$(balance_of "$cb_pk")"
  if ! awk "BEGIN{exit !($nb>0 && $cb>0)}"; then
    warn "$(tr need_funds)"; echo; show_keys_balances
    echo -e "\n$(tr press_enter)"; read -r; return
  fi

  for f in "$NODE_KP" "$CALLBACK_KP" "$IDENTITY_PEM"; do
    [[ -f "$f" ]] || { err "Не найден файл: $f"; echo -e "\n$(tr press_enter)"; read -r; return; }
  done

  local key_dir; key_dir="$(dirname "$NODE_KP")"
  if [[ -d "$key_dir" ]]; then
    ( cd "$key_dir" && arcium init-arx-accs \
        --keypair-path "$NODE_KP" \
        --callback-keypair-path "$CALLBACK_KP" \
        --peer-keypair-path "$IDENTITY_PEM" \
        --node-offset "$OFFSET" \
        --ip-address "$PUBLIC_IP" \
        --rpc-url "$RPC_HTTP" )
    cd "$HOME" || true
  else
    arcium init-arx-accs \
      --keypair-path "$NODE_KP" \
      --callback-keypair-path "$CALLBACK_KP" \
      --peer-keypair-path "$IDENTITY_PEM" \
      --node-offset "$OFFSET" \
      --ip-address "$PUBLIC_IP" \
      --rpc-url "$RPC_HTTP"
  fi
  ok "$(tr init_done)"
}

pull_image() { info "$(tr pull_image) $IMAGE"; docker pull "$IMAGE"; }

start_container() {
  mkdir -p "$LOGS_DIR"; docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  info "$(tr start_container)"
  docker run -d \
    --name "$CONTAINER" \
    -e NODE_IDENTITY_FILE=/usr/arx-node/node-keys/node_identity.pem \
    -e NODE_KEYPAIR_FILE=/usr/arx-node/node-keys/node_keypair.json \
    -e OPERATOR_KEYPAIR_FILE=/usr/arx-node/node-keys/operator_keypair.json \
    -e CALLBACK_AUTHORITY_KEYPAIR_FILE=/usr/arx-node/node-keys/callback_authority_keypair.json \
    -e NODE_CONFIG_PATH=/usr/arx-node/arx/node_config.toml \
    -v "$CFG_FILE:/usr/arx-node/arx/node_config.toml" \
    -v "$NODE_KP:/usr/arx-node/node-keys/node_keypair.json:ro" \
    -v "$NODE_KP:/usr/arx-node/node-keys/operator_keypair.json:ro" \
    -v "$CALLBACK_KP:/usr/arx-node/node-keys/callback_authority_keypair.json:ro" \
    -v "$IDENTITY_PEM:/usr/arx-node/node-keys/node_identity.pem:ro" \
    -v "$LOGS_DIR:/usr/arx-node/logs" \
    -p 8080:8080 \
    "$IMAGE"
  ok "$(tr container_started)"
}
stop_container()  { docker stop "$CONTAINER" && ok "$(tr container_stopped)" || true; }
remove_container(){ docker rm -f "$CONTAINER" && ok "$(tr container_removed)" || true; }
restart_container(){ docker restart "$CONTAINER" && ok "$(tr container_restarted)" || true; }
status_table()    { echo -e "$(tr status_table):\n"; docker ps -a --filter "name=$CONTAINER" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'; }

show_logs_follow() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr logs_follow)${clrReset}\n"; hr
  echo -e "${clrDim}$(tr show_logs_hint)${clrReset}\n"
  docker exec -it "$CONTAINER" sh -lc 'tail -n +1 -f "$(ls -t /usr/arx-node/logs/arx_log_*.log 2>/dev/null | head -1)"' || true
}

_get_offset_or_prompt() {
  ensure_offsets
  sanitize_offset
  if [[ -n "${OFFSET:-}" ]]; then
    info "Using node OFFSET: ${OFFSET}"
  else
    read -rp "$(tr ask_offset) " OFFSET
    sanitize_offset
  fi

  if [[ -n "${OFFSET:-}" ]]; then
    if ! [[ "$OFFSET" =~ ^[0-9]+$ ]]; then
      warn "OFFSET должен содержать только цифры."
      read -rp "$(tr ask_offset) " OFFSET
      sanitize_offset
    fi
    local len=${#OFFSET}
    if (( len < 8 || len > 12 )); then
      warn "OFFSET выглядит странно ($OFFSET). Рекомендуется 8–10 цифр."
    fi
  fi

  [[ -z "${OFFSET:-}" ]] && { warn "OFFSET пустой — операция отменена."; return 1; }
  return 0
}

node_status() { clear; display_logo; hr; echo -e "${clrBold}${clrMag}$(tr tools_status)${clrReset}\n"; hr; if _get_offset_or_prompt; then arcium arx-info "$OFFSET" --rpc-url "$RPC_HTTP" || true; fi; }
node_active() { clear; display_logo; hr; echo -e "${clrBold}${clrMag}$(tr tools_active)${clrReset}\n"; hr; if _get_offset_or_prompt; then arcium arx-active "$OFFSET" --rpc-url "$RPC_HTTP" || true; fi; }

join_cluster() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr join_cluster_lbl)${clrReset}\n"; hr
  if ! _get_offset_or_prompt; then echo -e "\n$(tr press_enter)"; read -r; return; fi
  local cur_cluster="${CLUSTER_OFFSET:-}" ans
  read -rp "$(tr ask_cluster_offset) ${cur_cluster:+[$cur_cluster]} " ans
  local cluster_offset="${ans:-$cur_cluster}"
  if [[ -z "$cluster_offset" ]]; then warn "cluster_offset пустой — операция отменена."; echo -e "\n$(tr press_enter)"; read -r; return; fi
  if [[ ! -f "$NODE_KP" ]]; then err "Файл ключа ноды не найден: $NODE_KP"; echo -e "\n$(tr press_enter)"; read -r; return; fi
  info "Joining cluster: node_offset=$OFFSET, cluster_offset=$cluster_offset"
  local key_dir; key_dir="$(dirname "$NODE_KP")"
  if [[ -d "$key_dir" ]]; then
    ( cd "$key_dir" && \
      arcium join-cluster true \
        --keypair-path "$NODE_KP" \
        --node-offset "$OFFSET" \
        --cluster-offset "$cluster_offset" \
        --rpc-url "$RPC_HTTP" )
    cd "$HOME" || true
  else
    arcium join-cluster true \
      --keypair-path "$NODE_KP" \
      --node-offset "$OFFSET" \
      --cluster-offset "$cluster_offset" \
      --rpc-url "$RPC_HTTP"
  fi
  CLUSTER_OFFSET="$cluster_offset"; save_env
  echo -e "\n$(tr press_enter)"; read -r
}

propose_join_cluster() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr propose_join_lbl)${clrReset}\n"; hr

  local cur_cluster="${CLUSTER_OFFSET:-}" ans
  read -rp "$(tr ask_cluster_offset) ${cur_cluster:+[$cur_cluster]} " ans
  local cluster_offset="${ans:-$cur_cluster}"
  [[ -z "$cluster_offset" ]] && { cluster_offset="10102025"; info "CLUSTER OFFSET не указан — использую по умолчанию: $cluster_offset"; }

  ensure_offsets; sanitize_offset
  local default_node="$OFFSET"
  read -rp "$(tr ask_target_node_offset) ${default_node:+[$default_node]} " ans
  local target_node_offset="${ans:-$default_node}"
  target_node_offset="$(printf '%s\n' "$target_node_offset" | sed -n 's/[^0-9]*\([0-9][0-9]*\).*/\1/p')"
  if [[ -z "$target_node_offset" ]]; then warn "OFFSET ноды пустой — операция отменена."; echo -e "\n$(tr press_enter)"; read -r; return; fi

  if [[ ! -f "$NODE_KP" ]]; then err "Ключ не найден: $NODE_KP"; echo -e "\n$(tr press_enter)"; read -r; return; fi

  info "Проверяю членство ноды $target_node_offset в кластере $cluster_offset..."
  if arcium arx-info "$target_node_offset" --rpc-url "$RPC_HTTP" | awk -v c="$cluster_offset" '
      /^Cluster memberships:/ { inlist=1; next }
      inlist {
        if ($0 ~ /^[[:space:]]*$/) { inlist=0; next }
        if (index($0, c)) { found=1 }
      }
      END { exit(found ? 0 : 1) }
    ' >/dev/null; then
    warn "Нода $target_node_offset уже в кластере $cluster_offset — заявку отправлять не нужно."
    echo -e "\n$(tr press_enter)"; read -r; return
  fi

  info "Proposing node_offset=${target_node_offset} to cluster_offset=${cluster_offset}"
  local key_dir; key_dir="$(dirname "$NODE_KP")"
  if [[ -d "$key_dir" ]]; then
    ( cd "$key_dir" && arcium propose-join-cluster \
        --keypair-path "$NODE_KP" \
        --node-offset "$target_node_offset" \
        --cluster-offset "$cluster_offset" \
        --rpc-url "$RPC_HTTP" ) && ok "Заявка отправлена"
    cd "$HOME" || true
  else
    arcium propose-join-cluster \
      --keypair-path "$NODE_KP" \
      --node-offset "$target_node_offset" \
      --cluster-offset "$cluster_offset" \
      --rpc-url "$RPC_HTTP" && ok "Заявка отправлена"
  fi

  CLUSTER_OFFSET="$cluster_offset"; save_env
  echo -e "\n$(tr press_enter)"; read -r
}

check_membership_single() {
  ensure_offsets; sanitize_offset
  local cur_cluster="${CLUSTER_OFFSET:-}" ans; read -rp "$(tr ask_cluster_offset) ${cur_cluster:+[$cur_cluster]} " ans
  local cluster_offset="${ans:-$cur_cluster}"; [[ -z "$cluster_offset" ]] && { warn "cluster_offset пустой"; return; }
  local node_off; read -rp "$(tr ask_offset) " node_off; node_off="$(printf '%s\n' "$node_off" | sed -n 's/[^0-9]*\([0-9][0-9]*\).*/\1/p')"
  [[ -z "$node_off" ]] && { warn "node offset пустой"; return; }
  echo; info "Checking node $node_off in cluster $cluster_offset..."
  if arcium arx-info "$node_off" --rpc-url "$RPC_HTTP" | awk -v c="$cluster_offset" '
    /^Cluster memberships:/ { inlist=1; next }
    inlist { if ($0 ~ /^[[:space:]]*$/) { inlist=0; next } if (index($0, c)) { found=1 } }
    END { exit(found ? 0 : 1) }
  ' >/dev/null; then ok "Node $node_off is IN cluster $cluster_offset"; else warn "Node $node_off is NOT in cluster $cluster_offset (or not found)"; fi
  echo
}

migration_030_to_040() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}Миграция 0.3.0 → 0.4.0${clrReset}\n"; hr

  # 1) Остановить/удалить старый контейнер
  info "Отключаю старый контейнер arx-node..."
  docker rm -f arx-node 2>/dev/null || true

  # 2) Загрузить образ 0.4.0
  local IMG="arcium/arx-node:v0.4.0"
  info "Тяну образ ${IMG}..."
  docker pull "${IMG}"

  # 3) Подготовить PATH в ~/.bashrc (на будущее), текущую сессию пока не трогаем
  info "Готовлю PATH для arcium (для будущих сессий)…"
  if ! grep -q 'export PATH="$HOME/.arcium/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    sed -i '1iexport PATH="$HOME/.arcium/bin:$PATH"' "$HOME/.bashrc"
  fi

  # 4) Переименовать старый cargo-бинарь (если был)
  mv "$HOME/.cargo/bin/arcium" "$HOME/.cargo/bin/arcium.old" 2>/dev/null || true

  # 5) Установить через arcup (при необходимости — скачать arcup)
  if [[ ! -x "$HOME/.cargo/bin/arcup" ]]; then
    warn "arcup не найден. Скачиваю…"
    mkdir -p "$HOME/.cargo/bin"
    local target="x86_64_linux"
    [[ $(uname -m) =~ (aarch64|arm64) ]] && target="aarch64_linux"
    curl -fsSL "https://bin.arcium.com/download/arcup_${target}_0.4.0" -o "$HOME/.cargo/bin/arcup" || \
    curl -fsSL "https://bin.arcium.network/download/arcup_${target}_0.4.0" -o "$HOME/.cargo/bin/arcup"
    chmod +x "$HOME/.cargo/bin/arcup"
  fi
  info "Устанавливаю Arcium CLI через arcup…"
  "$HOME/.cargo/bin/arcup" install

  # === Нормализация бинаря после arcup install ===
  mkdir -p "$HOME/.arcium/bin"

  # 1) если есть arcium-cli — линкуем на arcium
  if [[ -x "$HOME/.arcium/bin/arcium-cli" && ! -e "$HOME/.arcium/bin/arcium" ]]; then
    ln -sf "$HOME/.arcium/bin/arcium-cli" "$HOME/.arcium/bin/arcium"
  fi

  # 2) если arcup положил версионный бинарь в ~/.cargo/bin (например arcium-0.4.0) — линкуем
  if [[ ! -e "$HOME/.arcium/bin/arcium" ]]; then
    if [[ -x "$HOME/.cargo/bin/arcium-0.4.0" ]]; then
      ln -sf "$HOME/.cargo/bin/arcium-0.4.0" "$HOME/.arcium/bin/arcium"
      ok "Нашёл: $HOME/.cargo/bin/arcium-0.4.0 → $HOME/.arcium/bin/arcium"
    fi
  fi

  # 3) если всё ещё нет — ищем глубже по HOME (arcium, arcium-cli, arcium-*)
  if [[ ! -x "$HOME/.arcium/bin/arcium" ]]; then
    FOUND="$( (command -v arcium || true; command -v arcium-cli || true; \
      find "$HOME" -maxdepth 8 -type f -perm -111 \( -name 'arcium' -o -name 'arcium-cli' -o -name 'arcium-*' \) 2>/dev/null) \
      | awk 'NF' | sort -u | head -n1 )"
    if [[ -n "$FOUND" ]]; then
      ln -sf "$FOUND" "$HOME/.arcium/bin/arcium"
      ok "Нашёл бинарь: $FOUND → $HOME/.arcium/bin/arcium"
    else
      warn "Не удалось найти бинарь arcium после установки arcup."
    fi
  fi

  # 4) добавить PATH для текущей сессии и проверить версию
  export PATH="$HOME/.arcium/bin:$PATH"
  hash -r
  local ARCIUM_BIN="$HOME/.arcium/bin/arcium"
  if [[ ! -x "$ARCIUM_BIN" ]]; then
    warn "нет arcium в PATH и по абсолютному пути — проверь установку arcup"
    echo -e "\n$(tr press_enter)"; read -r; return
  fi

  # 7) Ожидаем строгий вывод версии
  if "$ARCIUM_BIN" --version 2>/dev/null | grep -qE '^arcium-cli 0\.4\.0$'; then
    ok "Версия подтверждена: arcium-cli 0.4.0"
  else
    warn "Ожидалась версия arcium-cli 0.4.0. Вывод:"
    ( "$ARCIUM_BIN" --version 2>&1 || true )
  fi

  # Пути
  local BASE="$HOME/arcium-node-setup"
  local CFG="$BASE/node-config.toml"
  local NODE_KP="$BASE/node-keypair.json"
  local CALLBACK_KP="$BASE/callback-kp.json"
  local ID_PEM="$BASE/identity.pem"
  local LOGS="$BASE/arx-node-logs"
  mkdir -p "$BASE" "$LOGS"

  # 8) Инициализация on-chain с запросом OFFSET (8–10 цифр)
  local OFFSET_IN=""
  while true; do
    read -rp "Введи OFFSET (8–10 цифр): " OFFSET_IN
    OFFSET_IN="$(printf '%s\n' "$OFFSET_IN" | sed -n 's/[^0-9]*\([0-9]\{8,10\}\).*/\1/p')"
    [[ -n "$OFFSET_IN" ]] && break
    warn "Нужны только цифры, длина 8–10."
  done

  info "Инициализирую on-chain аккаунты…"
  "$ARCIUM_BIN" init-arx-accs \
    --keypair-path "$NODE_KP" \
    --callback-keypair-path "$CALLBACK_KP" \
    --peer-keypair-path "$ID_PEM" \
    --node-offset "$OFFSET_IN" \
    --ip-address "$(curl -4 -s https://ipecho.net/plain)" \
    --rpc-url "https://api.devnet.solana.com"

  # 9) Запуск контейнера 0.4.0 (restart unless-stopped)
  info "Запускаю контейнер arx-node c образа ${IMG}…"
  docker run -d --name arx-node --restart unless-stopped \
    -e NODE_IDENTITY_FILE=/usr/arx-node/node-keys/node_identity.pem \
    -e NODE_KEYPAIR_FILE=/usr/arx-node/node-keys/node_keypair.json \
    -e OPERATOR_KEYPAIR_FILE=/usr/arx-node/node-keys/operator_keypair.json \
    -e CALLBACK_AUTHORITY_KEYPAIR_FILE=/usr/arx-node/node-keys/callback_authority_keypair.json \
    -e NODE_CONFIG_PATH=/usr/arx-node/arx/node_config.toml \
    -v "$CFG:/usr/arx-node/arx/node_config.toml" \
    -v "$NODE_KP:/usr/arx-node/node-keys/node_keypair.json:ro" \
    -v "$NODE_KP:/usr/arx-node/node-keys/operator_keypair.json:ro" \
    -v "$CALLBACK_KP:/usr/arx-node/node-keys/callback_authority_keypair.json:ro" \
    -v "$ID_PEM:/usr/arx-node/node-keys/node_identity.pem:ro" \
    -v "$LOGS:/usr/arx-node/logs" \
    -p 8080:8080 \
    "${IMG}"

  ok "Миграция завершена. Текущий статус контейнера:"
  docker ps -a --filter "name=arx-node" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
  echo -e "\n$(tr press_enter)"; read -r
}

remove_node_full() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr manage_remove_node)${clrReset}\n"; hr
  echo "Будут удалены:"
  echo "  - Docker контейнер:  $CONTAINER"
  echo "  - Docker образ:      $IMAGE"
  echo "  - Каталог ноды:      $BASE_DIR"
  echo "    включая:"
  echo "      • node-config.toml"
  echo "      • node-keypair.json"
  echo "      • callback-kp.json"
  echo "      • identity.pem"
  echo "      • arx-node-logs/ (лог-файлы ноды)"
  echo "      • node-keypair.seed.txt (сид ноды)"
  echo "      • callback-kp.seed.txt (сид callback)"
  echo "      • node-pubkey.txt"
  echo "      • callback-pubkey.txt"
  echo "      • .env (файл окружения ноды, если существует)"
  echo
  echo "После этого восстановить эти ключи из файлов будет невозможно. Нужны заранее сохранённые сид-фразы."
  echo
  read -rp "Чтобы ПОЛНОСТЬЮ удалить ноду, напишите YES и нажмите Enter: " ans
  if [[ "$ans" != "YES" ]]; then
    warn "Удаление ноды отменено пользователем."
    echo -e "\n$(tr press_enter)"; read -r
    return
  fi

  info "Останавливаю и удаляю контейнер $CONTAINER..."
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

  info "Пробую удалить Docker-образ $IMAGE..."
  docker rmi "$IMAGE" >/dev/null 2>&1 || warn "Не удалось удалить образ $IMAGE (возможно, он используется где-то ещё)."

  if [[ -n "${BASE_DIR:-}" && "$BASE_DIR" != "/" && "$BASE_DIR" != "$HOME" && -d "$BASE_DIR" ]]; then
    info "Удаляю каталог ноды: $BASE_DIR"
    rm -rf "$BASE_DIR"
  else
    warn "Каталог BASE_DIR не найден или выглядит подозрительно: '$BASE_DIR' — пропускаю rm -rf."
  fi

  if [[ -n "${ENV_FILE:-}" && -f "$ENV_FILE" ]]; then
    info "Удаляю файл окружения: $ENV_FILE"
    rm -f "$ENV_FILE" || true
  fi

  ok "Нода полностью удалена (контейнер, образ и файлы ноды)."
  echo -e "\n$(tr press_enter)"; read -r
}

# ==================== Menus ====================
config_menu() {
  while true; do
    clear; display_logo; hr
    echo -e "${clrBold}${clrMag}$(tr cfg_current)${clrReset}\n"
    echo -e "IMAGE:        ${clrBlue}${IMAGE}${clrReset}"
    echo -e "CONTAINER:    ${clrBlue}${CONTAINER}${clrReset}"
    echo -e "BASE_DIR:     ${clrBlue}${BASE_DIR}${clrReset}"
    echo -e "RPC_HTTP:     ${clrBlue}${RPC_HTTP}${clrReset}"
    echo -e "RPC_WSS:      ${clrBlue}${RPC_WSS}${clrReset}"
    ensure_offsets; sanitize_offset
    echo -e "OFFSET:       ${clrBlue}${OFFSET:-not-set}${clrReset}"
    echo -e "PUBLIC_IP:    ${clrBlue}${PUBLIC_IP:-auto}${clrReset}"
    hr
    echo -e "${clrGreen}1)${clrReset} $(tr cfg_edit_rpc_http)"
    echo -e "${clrGreen}2)${clrReset} $(tr cfg_edit_rpc_wss)"
    echo -e "${clrGreen}0)${clrReset} $(tr m5_exit)"
    hr
    read -rp "> " c
    case "${c:-}" in
      1)
        read -rp "RPC_HTTP: " RPC_HTTP
        save_env
        update_rpc_endpoints
        echo "→ RPC_HTTP обновлён в $CFG_FILE."
        read -rp "Перезапустить контейнер сейчас? (y/N): " z
        [[ "$z" =~ ^[Yy]$ ]] && restart_container
        ;;
      2)
        read -rp "RPC_WSS: " RPC_WSS
        save_env
        update_rpc_endpoints
        echo "→ RPC_WSS обновлён в $CFG_FILE."
        read -rp "Перезапустить контейнер сейчас? (y/N): " z
        [[ "$z" =~ ^[Yy]$ ]] && restart_container
        ;;
      0) return ;;
      *) ;;
    esac
    echo -e "\n$(tr press_enter)"; read -r
  done
}

tools_menu() {
  while true; do
    clear; display_logo; hr
    echo -e "${clrBold}${clrMag}$(tr m4_tools)${clrReset}\n"
    echo -e "${clrGreen}1)${clrReset} $(tr menu_logs)"
    echo -e "${clrGreen}2)${clrReset} $(tr tools_status)"
    echo -e "${clrGreen}3)${clrReset} $(tr tools_active)"
    echo -e "${clrGreen}4)${clrReset} $(tr propose_join_lbl)"
    echo -e "${clrGreen}5)${clrReset} $(tr join_cluster_lbl)"
    echo -e "${clrGreen}6)${clrReset} $(tr check_membership_lbl)"
    echo -e "${clrGreen}7)${clrReset} $(tr show_keys)"
    echo -e "${clrGreen}8)${clrReset} Airdrop (Devnet)"
    echo -e "${clrGreen}9)${clrReset} Показать сид-фразы"
    echo -e "${clrGreen}0)${clrReset} $(tr m5_exit)"
    hr
    read -rp "> " c
    case "${c:-}" in
      1) show_logs_follow ;;
      2) node_status ;;
      3) node_active ;;
      4) propose_join_cluster ;;
      5) join_cluster ;;
      6) check_membership_single ;;
      7) show_keys_balances ;;
      8) try_airdrop ;;
      9) show_seed_phrases ;;
      0) return ;;
      *) ;;
    esac
    echo -e "\n$(tr press_enter)"; read -r
  done
}

manage_menu() {
  while true; do
    clear; display_logo; hr
    echo -e "${clrBold}${clrMag}$(tr m2_manage)${clrReset}\n"
    echo -e "${clrGreen}1)${clrReset} $(tr manage_start)"
    echo -e "${clrGreen}2)${clrReset} $(tr manage_restart)"
    echo -e "${clrGreen}3)${clrReset} $(tr manage_stop)"
    echo -e "${clrGreen}4)${clrReset} $(tr manage_remove)"
    echo -e "${clrGreen}5)${clrReset} $(tr manage_status)"
    echo -e "${clrGreen}0)${clrReset} $(tr m5_exit)"
    hr
    read -rp "> " c
    case "${c:-}" in
      1) start_container ;;
      2) restart_container ;;
      3) stop_container ;;
      4) remove_container ;;
      5) status_table ;;
      0) return ;;
      *) ;;
    esac
    echo -e "\n$(tr press_enter)"; read -r
  done
}

server_prep_menu() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr m1_prep)${clrReset}\n"; hr
  install_prereqs
  echo -e "\n$(tr press_enter)"; read -r
}

install_and_run_menu() {
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}$(tr m2_install)${clrReset}\n"; hr
  ask_config
  generate_keys
  write_config
  pull_image
  # funding loop
  while true; do
    local node_pk cb_pk nb cb
    node_pk="$(solana address --keypair "$NODE_KP" 2>/dev/null || echo N/A)"
    cb_pk="$(solana address --keypair "$CALLBACK_KP" 2>/dev/null || echo N/A)"
    nb="$(balance_of "$node_pk")"; cb="$(balance_of "$cb_pk")"
    if awk "BEGIN{exit !($nb>0 && $cb>0)}"; then
      break
    fi
    warn "$(tr need_funds)"
    echo "→ Faucet: https://faucet.solana.com/"
    echo "→ Or run: solana airdrop 2 $node_pk -u devnet && solana airdrop 2 $cb_pk -u devnet"
    read -rp "Попробовать авто-airdrop сейчас? (y/N): " z
    [[ "$z" =~ ^[Yy]$ ]] && try_airdrop
    read -rp "Проверить балансы ещё раз? (y/N): " z2
    [[ "$z2" =~ ^[Yy]$ ]] && { show_keys_balances; continue; }
    read -rp "Прервать установку (рекомендуется до пополнения)? (y/N): " z3
    [[ "$z3" =~ ^[Yy]$ ]] && return
  done
  init_onchain
  start_container
  status_table
  echo -e "\n$(tr press_enter)"; read -r
}

main_menu() {
  choose_language
  info "$(tr need_root_warn)" || true
  while true; do
    clear; display_logo; hr
    local MIG_LABEL
    if [[ "$LANG_CHOICE" == "en" ]]; then
      MIG_LABEL="Migration 0.3.0 → 0.4.0"
    else
      MIG_LABEL="Миграция 0.3.0 → 0.4.0"
    fi

    echo -e "${clrBold}${clrMag}$(tr menu_title)${clrReset} ${clrDim}(v${SCRIPT_VERSION})${clrReset}\n"
    echo -e "${clrGreen}1)${clrReset} $(tr m1_prep)"
    echo -e "${clrGreen}2)${clrReset} $(tr m2_install)"
    echo -e "${clrGreen}3)${clrReset} $(tr m2_manage)"
    echo -e "${clrGreen}4)${clrReset} $(tr m3_config)"
    echo -e "${clrGreen}5)${clrReset} $(tr m4_tools)"
    echo -e "${clrGreen}6)${clrReset} ${MIG_LABEL}"
    echo -e "${clrGreen}7)${clrReset} $(tr manage_remove_node)"
    echo -e "${clrGreen}8)${clrReset} $(tr m5_exit)
    hr
    read -rp "> " choice
    case "${choice:-}" in
      1) server_prep_menu ;;
      2) install_and_run_menu ;;
      3) manage_menu ;;
      4) config_menu ;;
      5) tools_menu ;;
      6) migration_030_to_040 ;;
      7) remove_node_full ;;
      8) exit 0 ;;
      *) ;;
    esac
    echo -e "\n$(tr press_enter)"; read -r
  done
}

main_menu
