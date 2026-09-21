#!/usr/bin/env bash
# Write CPU / memory sampling results to tmux user options to prevent status-format from periodically spawning scripts

set -u

readonly INTERVAL="${1:-5}"
readonly LOCK_DIR="${TMPDIR:-/tmp}/tmux-status-feed.lock"

case $INTERVAL in
  ''|*[!0-9]*) exit 2 ;;
esac

((INTERVAL > 0)) || exit 2

# mkdir provides atomic single-instance protection on both macOS and Linux
if [[ -e $LOCK_DIR && ! -d $LOCK_DIR ]]; then
  rm -f "$LOCK_DIR" || exit 0
fi

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  pid=''
  if [[ -r $LOCK_DIR/pid ]]; then
    IFS= read -r pid <"$LOCK_DIR/pid" || true
  fi

  if [[ $pid =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
    exit 0
  fi

  rm -f "$LOCK_DIR/pid"
  rmdir "$LOCK_DIR" 2>/dev/null || exit 0
  mkdir "$LOCK_DIR" 2>/dev/null || exit 0
fi

printf '%s\n' "$$" >"$LOCK_DIR/pid"
cleanup() {
  # Subshells from process substitution inherit the EXIT trap; only the main shell should release the lock
  ((BASH_SUBSHELL == 0)) || return
  rm -f "$LOCK_DIR/pid"
  rmdir "$LOCK_DIR" 2>/dev/null
}
trap cleanup EXIT
trap 'exit 0' HUP INT TERM

CPU_LOW=''; CPU_MEDIUM=''; CPU_HIGH=''
RAM_LOW=''; RAM_MEDIUM=''; RAM_HIGH=''
CPU_MEDIUM_THRESHOLD=''; CPU_HIGH_THRESHOLD=''
RAM_MEDIUM_THRESHOLD=''; RAM_HIGH_THRESHOLD=''
NET_BASE=''; NET_TEXT_COLOR=''; NET_SURFACE=''; NET_DOWN=''; NET_UP=''
NET_THRESHOLD=''
PUBLISH_ROUND=0

refresh_options() {
  local key value

  while IFS=' ' read -r key value; do
    value=${value#\"}
    value=${value%\"}

    case $key in
      @status_cpu_low) CPU_LOW=$value ;;
      @status_cpu_medium) CPU_MEDIUM=$value ;;
      @status_cpu_high) CPU_HIGH=$value ;;
      @status_cpu_medium_threshold) CPU_MEDIUM_THRESHOLD=$value ;;
      @status_cpu_high_threshold) CPU_HIGH_THRESHOLD=$value ;;
      @status_ram_low) RAM_LOW=$value ;;
      @status_ram_medium) RAM_MEDIUM=$value ;;
      @status_ram_high) RAM_HIGH=$value ;;
      @status_ram_medium_threshold) RAM_MEDIUM_THRESHOLD=$value ;;
      @status_ram_high_threshold) RAM_HIGH_THRESHOLD=$value ;;
      @status_net_base) NET_BASE=$value ;;
      @status_net_text) NET_TEXT_COLOR=$value ;;
      @status_net_surface) NET_SURFACE=$value ;;
      @status_net_down) NET_DOWN=$value ;;
      @status_net_up) NET_UP=$value ;;
      @status_net_threshold) NET_THRESHOLD=$value ;;
    esac
  done < <(tmux show-options -g 2>/dev/null)

  : "${CPU_LOW:=green}" "${CPU_MEDIUM:=yellow}" "${CPU_HIGH:=red}"
  : "${RAM_LOW:=green}" "${RAM_MEDIUM:=yellow}" "${RAM_HIGH:=red}"
  : "${CPU_MEDIUM_THRESHOLD:=30}" "${CPU_HIGH_THRESHOLD:=80}"
  : "${RAM_MEDIUM_THRESHOLD:=30}" "${RAM_HIGH_THRESHOLD:=80}"
  : "${NET_BASE:=black}" "${NET_TEXT_COLOR:=white}" "${NET_SURFACE:=brightblack}"
  : "${NET_DOWN:=green}" "${NET_UP:=yellow}"
  # Do not display network speed below this byte rate; defaults to 30 KB/s
  : "${NET_THRESHOLD:=30720}"
  [[ $NET_THRESHOLD =~ ^[0-9]+$ ]] || NET_THRESHOLD=30720
}

# All percentages flow internally as integers representing tenths of a percent to avoid floating-point
# issues in bash 3.2; they are formatted to one decimal place only before writing to tmux options
FORMATTED=''
format_tenths() {
  FORMATTED="$(($1 / 10)).$(($1 % 10))"
}

COLOR=''
pick_color() {
  local tenths=$1 kind=$2 medium_threshold high_threshold low medium high

  if [[ $kind = cpu ]]; then
    medium_threshold=$CPU_MEDIUM_THRESHOLD
    high_threshold=$CPU_HIGH_THRESHOLD
    low=$CPU_LOW
    medium=$CPU_MEDIUM
    high=$CPU_HIGH
  else
    medium_threshold=$RAM_MEDIUM_THRESHOLD
    high_threshold=$RAM_HIGH_THRESHOLD
    low=$RAM_LOW
    medium=$RAM_MEDIUM
    high=$RAM_HIGH
  fi

  # Thresholds are configured as whole-number percentage points; scale up by 10x for comparison
  if ((tenths >= high_threshold * 10)); then
    COLOR=$high
  elif ((tenths >= medium_threshold * 10)); then
    COLOR=$medium
  else
    COLOR=$low
  fi
}

RAM_TENTHS=0
read_darwin_ram() {
  local key value active=0 inactive=0 speculative=0 wired=0 compressed=0
  local purgeable=0 file_backed=0 used

  while IFS=: read -r key value; do
    value=${value//[^0-9]/}
    case $key in
      'Pages active') active=${value:-0} ;;
      'Pages inactive') inactive=${value:-0} ;;
      'Pages speculative') speculative=${value:-0} ;;
      'Pages wired down') wired=${value:-0} ;;
      'Pages occupied by compressor') compressed=${value:-0} ;;
      'Pages purgeable') purgeable=${value:-0} ;;
      'File-backed pages') file_backed=${value:-0} ;;
    esac
  done < <(vm_stat 2>/dev/null)

  used=$((active + inactive + speculative + wired + compressed - purgeable - file_backed))
  ((used < 0)) && used=0
  ((used > DARWIN_TOTAL_PAGES)) && used=$DARWIN_TOTAL_PAGES
  # Same as format_rate: round the last digit instead of truncating
  ((DARWIN_TOTAL_PAGES > 0)) &&
    RAM_TENTHS=$(((1000 * used + DARWIN_TOTAL_PAGES / 2) / DARWIN_TOTAL_PAGES))
}

read_linux_ram() {
  local key value unit total=0 available=0

  while read -r key value unit; do
    case $key in
      MemTotal:) total=$value ;;
      MemAvailable:) available=$value ;;
    esac
  done </proc/meminfo

  ((total > 0)) && RAM_TENTHS=$(((1000 * (total - available) + total / 2) / total))
}

# ── Network Speed ─────────────────────────────────────────────────────────────
# Calculating cumulative bytes requires two samples to find the difference. The original net_speed.sh
# ran as a #() substitution every refresh, so it had to persist the previous value to /tmp and read it back;
# since this is a long-running process, we keep it in memory, saving temp files and date calls
# (using bash builtin SECONDS for timing without forking)
NET_PREVIOUS_TIME=0
NET_PREVIOUS_RX=0
NET_PREVIOUS_TX=0
NET_TEXT=''

FORMATTED_RATE=''

# Round when converting to "tenths of a unit": printf "%.1f" rounds instead of truncating,
# whereas integer division would be one step too low (e.g., 2202009 B/s: awk gives 2.1M, truncation gives 2.0M)
format_rate() {
  local bytes=$1 tenths unit suffix

  if ((bytes >= 1073741824)); then
    unit=1073741824; suffix=G
  elif ((bytes >= 1048576)); then
    unit=1048576; suffix=M
  elif ((bytes >= 1024)); then
    unit=1024; suffix=K
  else
    FORMATTED_RATE="${bytes}B"
    return
  fi

  tenths=$(((bytes * 10 + unit / 2) / unit))
  FORMATTED_RATE="$((tenths / 10)).$((tenths % 10))$suffix"
}

read_net_counters() {
  case $PLATFORM in
    Darwin)
      # Each interface may have multiple rows (different address families); !seen[$1]++ ensures each interface is counted only once
      netstat -ibn 2>/dev/null | awk '
        /:/ && !seen[$1]++ {
          if ($1 ~ /^lo/) next
          rx += $7; tx += $10
        } END { print rx+0, tx+0 }'
      ;;
    Linux)
      awk -F'[: \t]+' 'NR>2 {
        iface = ($1 == "") ? $2 : $1
        if (iface ~ /^(lo|docker|veth|br-|virbr|tun|vnet)/) next
        rx += ($1 == "") ? $3 : $2
        tx += ($1 == "") ? $11 : $10
      } END { print rx+0, tx+0 }' /proc/net/dev 2>/dev/null
      ;;
  esac
}

read_net() {
  local rx tx now=$SECONDS elapsed rx_rate tx_rate

  read -r rx tx < <(read_net_counters)
  [[ $rx =~ ^[0-9]+$ && $tx =~ ^[0-9]+$ ]] || return

  elapsed=$((now - NET_PREVIOUS_TIME))

  if ((NET_PREVIOUS_TIME > 0 && elapsed > 0)); then
    rx_rate=$(((rx - NET_PREVIOUS_RX) / elapsed))
    tx_rate=$(((tx - NET_PREVIOUS_TX) / elapsed))
    ((rx_rate < 0)) && rx_rate=0
    ((tx_rate < 0)) && tx_rate=0

    # Leave blank when below threshold to keep the status bar clean
    if ((rx_rate > NET_THRESHOLD || tx_rate > NET_THRESHOLD)); then
      format_rate "$rx_rate"; local down=$FORMATTED_RATE
      format_rate "$tx_rate"; local up=$FORMATTED_RATE
      NET_TEXT=$(printf ' #[fg=%s,bg=%s] 󰇚 #[fg=%s,bg=%s] %s/s #[fg=%s,bg=%s] 󰕒 #[fg=%s,bg=%s] %s/s ' \
        "$NET_BASE" "$NET_DOWN" "$NET_TEXT_COLOR" "$NET_SURFACE" "$down" \
        "$NET_BASE" "$NET_UP" "$NET_TEXT_COLOR" "$NET_SURFACE" "$up")
    else
      NET_TEXT=''
    fi
  fi

  NET_PREVIOUS_TIME=$now
  NET_PREVIOUS_RX=$rx
  NET_PREVIOUS_TX=$tx
}

publish() {
  local cpu_tenths=$1 cpu_color ram_color cpu_text ram_text

  if ((PUBLISH_ROUND % 12 == 0)); then
    refresh_options
  fi
  ((PUBLISH_ROUND++))

  case $PLATFORM in
    Darwin) read_darwin_ram ;;
    Linux) read_linux_ram ;;
  esac
  read_net

  pick_color "$cpu_tenths" cpu
  cpu_color=$COLOR
  pick_color "$RAM_TENTHS" ram
  ram_color=$COLOR

  format_tenths "$cpu_tenths"
  cpu_text=$FORMATTED
  format_tenths "$RAM_TENTHS"
  ram_text=$FORMATTED

  # Sampling stream has recovered normally; signals the outer loop to reset backoff
  PUBLISHED=1

  tmux set-option -g @status_cpu "${cpu_text}%" \; \
    set-option -g @status_cpu_color "$cpu_color" \; \
    set-option -g @status_ram "${ram_text}%" \; \
    set-option -g @status_ram_color "$ram_color" \; \
    set-option -g @status_net "$NET_TEXT" 2>/dev/null
}

run_darwin() {
  local line idle_index idle

  # The last four columns of macOS iostat are CPU idle and the three load averages
  while IFS= read -r line; do
    set -- $line
    (($# >= 6)) || continue
    idle_index=$(($# - 3))
    idle=${!idle_index}
    [[ $idle =~ ^[0-9]+$ ]] || continue

    # iostat's id column only has integer precision, so the CPU decimal place is always .0, used only to align formatting with RAM
    publish "$(((100 - idle) * 10))" || return
  done < <(iostat -w "$INTERVAL" 2>/dev/null)
}

run_linux() {
  local cpu user nice system idle iowait irq softirq steal guest guest_nice
  local previous_total=0 previous_idle=0 total idle_total delta_total delta_idle

  while :; do
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice </proc/stat
    idle_total=$((idle + iowait))
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))

    if ((previous_total > 0 && total > previous_total)); then
      delta_total=$((total - previous_total))
      delta_idle=$((idle_total - previous_idle))
      publish "$((1000 * (delta_total - delta_idle) / delta_total))" || return
    fi

    previous_total=$total
    previous_idle=$idle_total
    sleep "$INTERVAL"
  done
}

readonly PLATFORM=$(uname -s)
case $PLATFORM in
  Darwin|Linux) ;;
  *) exit 1 ;;
esac

# Total physical memory pages are determined by two boot-fixed sysctls, so we only fetch them once at startup.
# Putting this inside the collection loop would cause two extra sysctl forks per cycle,
# which goes against this script's goal of "rendering the status bar without spawning subprocesses"
DARWIN_TOTAL_PAGES=0
if [[ $PLATFORM = Darwin ]]; then
  memsize=$(sysctl -n hw.memsize 2>/dev/null) || memsize=0
  pagesize=$(sysctl -n hw.pagesize 2>/dev/null) || pagesize=0
  [[ $memsize =~ ^[0-9]+$ ]] || memsize=0
  [[ $pagesize =~ ^[0-9]+$ && $pagesize -gt 0 ]] || pagesize=0
  ((pagesize > 0)) && DARWIN_TOTAL_PAGES=$((memsize / pagesize))
fi
readonly DARWIN_TOTAL_PAGES

refresh_options

PUBLISHED=0
BACKOFF=1

# Restart when the collector exits abnormally. Backoff is necessary: if iostat fails permanently
# (PATH, permissions, corrupted binary), a fixed 1-second retry would degrade into a spawn loop of
# one cycle per second, creating even denser process churn than before without any logs to inspect
while tmux has-session 2>/dev/null; do
  PUBLISHED=0

  case $PLATFORM in
    Darwin) run_darwin ;;
    Linux) run_linux ;;
  esac

  # Marking unknown values must happen immediately after the collection stream breaks, otherwise the status bar
  # will display stale numbers throughout the backoff window — exactly the situation this placeholder avoids
  tmux set-option -g @status_cpu '--' \; set-option -g @status_ram '--' 2>/dev/null || exit 0

  if ((PUBLISHED)); then
    BACKOFF=1
  elif ((BACKOFF < 60)); then
    BACKOFF=$((BACKOFF * 2))
  fi

  sleep "$BACKOFF"
  refresh_options
done
