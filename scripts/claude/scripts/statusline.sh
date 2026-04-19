#!/usr/bin/env bash
# ~/.claude/scripts/statusline.sh
# Claude Code status line script
# Reads JSON from stdin (Claude Code environment data)

# ---------------------------------------------------------------------------
# Color constants (ANSI escape codes)
# ---------------------------------------------------------------------------
RESET_COLOR="\e[0m"
GRAY="\e[38;5;245m"
GREEN="\e[32m"
ORANGE="\e[38;5;214m"
RED="\e[31m"
BLUE="\e[34m"
YELLOW="\e[33m"

# ---------------------------------------------------------------------------
# Read JSON from stdin
# ---------------------------------------------------------------------------
input=$(cat)

# ---------------------------------------------------------------------------
# Extract fields from JSON
# ---------------------------------------------------------------------------
model_name=$(echo "$input" | jq -r '.model.display_name // "Model?"')
effort_lvl=$(echo "$input" | jq -r '.output_style.name // "medium/dflt"')
context_window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
total_input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
current_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
current_output=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')

five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ---------------------------------------------------------------------------
# Format context window size (e.g. 200000 -> 200k)
# ---------------------------------------------------------------------------
if [ "$context_window_size" -ge 1000 ] 2>/dev/null; then
  ctx_size_k=$(( context_window_size / 1000 ))
  ctx_size_fmt="${ctx_size_k}k"
else
  ctx_size_fmt="${context_window_size}"
fi

# ---------------------------------------------------------------------------
# Helper: pick color based on used percentage (green/orange/red)
# ---------------------------------------------------------------------------
pick_color_by_used_pct() {
  local pct_int=$1
  if [ "$pct_int" -le 50 ]; then
    echo "$GREEN"
  elif [ "$pct_int" -le 80 ]; then
    echo "$ORANGE"
  else
    echo "$RED"
  fi
}

# ---------------------------------------------------------------------------
# Context usage bar (10 bars) - always shown
# ---------------------------------------------------------------------------
if [ -n "$used_pct" ]; then
  used_int=$(awk "BEGIN { printf \"%d\", ($used_pct + 0.5) }")
  if [ -n "$remaining_pct" ]; then
    remaining_int=$(awk "BEGIN { printf \"%d\", ($remaining_pct + 0.5) }")
  else
    remaining_int=$(( 100 - used_int ))
  fi

  # Determine color based on usage percentage
  bar_color=$(pick_color_by_used_pct "$used_int")
  pct_color="$bar_color"

  filled=$(( used_int / 10 ))
  empty=$(( 10 - filled ))

  bar_filled=""
  bar_empty=""
  i=0
  while [ $i -lt $filled ]; do
    bar_filled="${bar_filled}▓"
    i=$(( i + 1 ))
  done
  i=0
  while [ $i -lt $empty ]; do
    bar_empty="${bar_empty}░"
    i=$(( i + 1 ))
  done

  context_bar="${bar_color}${bar_filled}${GRAY}${bar_empty}${RESET_COLOR}"
  context_pct="${pct_color}${used_int}%${RESET_COLOR}"
  context_section="[${context_bar}${GRAY}]${RESET_COLOR} ${context_pct}${GRAY} used${RESET_COLOR}"
else
  context_section="[${GRAY}░░░░░░░░░░]${RESET_COLOR} ${GREEN}0%${RESET_COLOR}${GRAY} used${RESET_COLOR}"
fi

# ---------------------------------------------------------------------------
# Format token counts (shorten large numbers)
# ---------------------------------------------------------------------------
format_tokens() {
  local n=$1
  if [ -z "$n" ] || [ "$n" = "null" ]; then
    echo "0"
    return
  fi
  if [ "$n" -ge 1000000 ] 2>/dev/null; then
    printf "%.1fM" "$(echo "scale=1; $n / 1000000" | bc)"
  elif [ "$n" -ge 1000 ] 2>/dev/null; then
    printf "%.1fk" "$(echo "scale=1; $n / 1000" | bc)"
  else
    echo "$n"
  fi
}

in_fmt=$(format_tokens "$current_input")
out_fmt=$(format_tokens "$current_output")

# ---------------------------------------------------------------------------
# Effort / output style
# ---------------------------------------------------------------------------
effort_val="${effort_lvl}"

# ---------------------------------------------------------------------------
# Python virtualenv - always shown
# ---------------------------------------------------------------------------
if [ -n "$VIRTUAL_ENV" ]; then
  venv_name=$(basename "$VIRTUAL_ENV")
  venv_section="${GRAY} | venv:${YELLOW}${venv_name}${RESET_COLOR}"
else
  venv_section="${GRAY} | venv:${GRAY}-${RESET_COLOR}"
fi

# ---------------------------------------------------------------------------
# Git changed files (run in cwd from Claude's workspace) - always shown
# ---------------------------------------------------------------------------
if [ -n "$cwd" ] && [ "$cwd" != "." ]; then
  git_count=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
else
  git_count=$(git --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
fi
if [ -n "$git_count" ] && [ "$git_count" -gt 0 ] 2>/dev/null; then
  git_section="${GRAY} | git:${GREEN}${git_count}${RESET_COLOR}"
else
  git_section="${GRAY} | git:${GRAY}0${RESET_COLOR}"
fi

# ---------------------------------------------------------------------------
# Rate limits: 5-hour window - always shown
# ---------------------------------------------------------------------------
if [ -n "$five_hour_pct" ]; then
  five_int=$(awk "BEGIN { printf \"%d\", ($five_hour_pct + 0.5) }")
  five_color=$(pick_color_by_used_pct "$five_int")
  if [ -n "$five_hour_reset" ]; then
    reset_hhmm=$(date -d "@${five_hour_reset}" +%H:%M 2>/dev/null || date -r "${five_hour_reset}" +%H:%M 2>/dev/null)
    now_epoch=$(date +%s)
    mins_left=$(( (five_hour_reset - now_epoch) / 60 ))
    [ "$mins_left" -lt 0 ] && mins_left=0
    five_time_left="${mins_left}min"
  else
    reset_hhmm="--:--"
    five_time_left="--min"
  fi
  rate_section="${GRAY} | 5hr:${five_color}${five_int}%${GRAY} @${reset_hhmm} (${five_time_left})${RESET_COLOR}"
else
  rate_section="${GRAY} | 5hr:${GRAY}-${RESET_COLOR}"
fi

# 7-day window - always shown
if [ -n "$seven_day_pct" ]; then
  week_int=$(awk "BEGIN { printf \"%d\", ($seven_day_pct + 0.5) }")
  week_color=$(pick_color_by_used_pct "$week_int")
  if [ -n "$seven_day_reset" ]; then
    reset_date=$(date -d "@${seven_day_reset}" +%Y-%m-%d 2>/dev/null || date -r "${seven_day_reset}" +%Y-%m-%d 2>/dev/null)
    now_epoch=$(date +%s)
    days_left=$(( (seven_day_reset - now_epoch) / 86400 ))
    [ "$days_left" -lt 0 ] && days_left=0
    week_time_left="${days_left}days"
  else
    reset_date="----"
    week_time_left="--days"
  fi
  rate_section="${rate_section}${GRAY} | 7day:${week_color}${week_int}%${GRAY} ${reset_date} (${week_time_left})${RESET_COLOR}"
else
  rate_section="${rate_section}${GRAY} | 7day:${GRAY}-${RESET_COLOR}"
fi

# ---------------------------------------------------------------------------
# Assemble and print status line
# ---------------------------------------------------------------------------
printf "%b" "${GRAY}${model_name} (${ctx_size_fmt}) - effort:${RESET_COLOR}${effort_lvl} ${GRAY}|${RESET_COLOR} "
printf "%b" "${context_section}"
printf "%b" " ${GRAY}| in↓:${BLUE}${in_fmt}${GRAY} out↑:${BLUE}${out_fmt}${RESET_COLOR}"
printf "%b" "${venv_section}"
printf "%b" "${git_section}"
printf "%b" "${rate_section}"
printf "%b" "${RESET_COLOR}\n"
