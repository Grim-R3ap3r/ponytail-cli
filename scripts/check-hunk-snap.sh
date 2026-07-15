#!/usr/bin/env bash
# Self-check: hunk map snap + evidence existence (P0).
set -uo pipefail
TMPDIR_PT=$(mktemp -d)
trap 'rm -rf "$TMPDIR_PT"' EXIT

build_hunk_map() {
  : > "$TMPDIR_PT/hunk_lines"
  : > "$TMPDIR_PT/diff_paths"
  local path="" new_line=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^diff\ --git\ a/.+\ b/(.+)$ ]]; then
      path="${BASH_REMATCH[1]}"
      echo "$path" >> "$TMPDIR_PT/diff_paths"
      continue
    fi
    if [[ "$line" =~ ^@@\ -[0-9]+(,[0-9]+)?\ \+([0-9]+)(,[0-9]+)?\ @@ ]]; then
      new_line="${BASH_REMATCH[2]}"
      continue
    fi
    [[ -z "$path" ]] && continue
    case "$line" in
      ---*|+++*|index\ *) continue ;;
      +*)
        printf '%s:%s\n' "$path" "$new_line" >> "$TMPDIR_PT/hunk_lines"
        new_line=$((new_line + 1))
        ;;
      -*) ;;
      \\*) ;;
      *)
        printf '%s:%s\n' "$path" "$new_line" >> "$TMPDIR_PT/hunk_lines"
        new_line=$((new_line + 1))
        ;;
    esac
  done < "$TMPDIR_PT/diff"
  sort -u "$TMPDIR_PT/hunk_lines" -o "$TMPDIR_PT/hunk_lines"
}

snap_line_to_hunk() {
  local path="$1" want="$2" window="${3:-25}"
  if grep -qxF "${path}:${want}" "$TMPDIR_PT/hunk_lines" 2>/dev/null; then
    echo "$want"
    return 0
  fi
  local best="" bestdist=999999 line dist
  while IFS= read -r entry; do
    [[ "$entry" == "$path":* ]] || continue
    line="${entry##*:}"
    [[ "$line" =~ ^[0-9]+$ ]] || continue
    dist=$(( line > want ? line - want : want - line ))
    if (( dist <= window && dist < bestdist )); then
      bestdist=$dist
      best=$line
    fi
  done < "$TMPDIR_PT/hunk_lines"
  [[ -n "$best" ]] && { echo "$best"; return 0; }
  return 1
}

path_known() {
  grep -qxF "$1" "$TMPDIR_PT/file_list" 2>/dev/null || grep -qxF "$1" "$TMPDIR_PT/diff_paths" 2>/dev/null
}

evidence_pinpoint_exists() {
  local path="$1" line="$2"
  path_known "$path" || return 1
  [[ "$line" =~ ^[0-9]+$ ]] || return 1
  (( line < 1 )) && return 1
  local count=""
  count=$(awk -F'\t' -v p="$path" '$1==p {print $2; exit}' "$TMPDIR_PT/file_line_counts" 2>/dev/null || true)
  if [[ -n "$count" ]]; then
    (( line <= count )) && return 0
    return 1
  fi
  grep -qxF "${path}:${line}" "$TMPDIR_PT/hunk_lines" 2>/dev/null
}

cat > "$TMPDIR_PT/diff" <<'DIFF'
diff --git a/foo.go b/foo.go
--- a/foo.go
+++ b/foo.go
@@ -10,6 +10,8 @@ func old() {
 	keep := 1
-	bad := 2
+	good := 2
+	extra := 3
 	tail := 4
 }
DIFF

build_hunk_map

snap=$(snap_line_to_hunk foo.go 11) || true
[[ "$snap" == "11" ]] || { echo "FAIL exact snap got='$snap'"; exit 1; }

snap=$(snap_line_to_hunk foo.go 15 10) || true
[[ "$snap" == "13" || "$snap" == "14" ]] || { echo "FAIL near snap got='$snap'"; exit 1; }

if snap=$(snap_line_to_hunk foo.go 90 25); then
  echo "FAIL far snap should miss, got=$snap"
  exit 1
fi

echo "foo.go" > "$TMPDIR_PT/file_list"
printf 'foo.go\t20\n' > "$TMPDIR_PT/file_line_counts"
echo "foo.go" > "$TMPDIR_PT/diff_paths"

evidence_pinpoint_exists foo.go 11 || { echo "FAIL real pinpoint"; exit 1; }
evidence_pinpoint_exists foo.go 999 && { echo "FAIL fake line"; exit 1; }
evidence_pinpoint_exists ghost.go 1 && { echo "FAIL ghost path"; exit 1; }

echo "PASS: hunk snap + evidence existence"
