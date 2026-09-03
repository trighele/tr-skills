#!/usr/bin/env bash
#
# Install / refresh the tr-* skills into the local Claude Code skills directory.
#
#   ./sync.sh              pull, then install
#   ./sync.sh --no-pull    install what's already checked out
#
# Copies, never symlinks: nothing git-shaped is created under ~/.claude, and the
# copies survive being bind-mounted into a dev container.
#
# Only touches directories matching tr-* . Anything else in the destination
# (msk-*, hand-written skills, plugins) is left strictly alone.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
SRC="$REPO/skills"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

PULL=1
for arg in "$@"; do
  case "$arg" in
    --no-pull) PULL=0 ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

[ -d "$SRC" ] || { echo "error: no skills/ directory in $REPO" >&2; exit 1; }

# Refuse to invent a Claude home. An empty ~/.claude almost always means the
# path is wrong (or, in a container, that the bind mount didn't resolve), and
# silently creating it turns that into "my skills vanished" three steps later.
parent="$(dirname "$DEST")"
if [ ! -d "$parent" ]; then
  echo "error: $parent does not exist." >&2
  echo "       Claude Code has not run on this machine, or CLAUDE_SKILLS_DIR is wrong." >&2
  exit 1
fi
mkdir -p "$DEST"

if [ "$PULL" -eq 1 ]; then
  echo "pulling $(git -C "$REPO" rev-parse --abbrev-ref HEAD)..."
  git -C "$REPO" pull --ff-only
  echo
fi

# --- install -----------------------------------------------------------------
installed=0
names=""
for dir in "$SRC"/tr-*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  names="$names $name"
  rm -rf "$DEST/$name"          # so deletions inside a skill propagate
  cp -R "$dir" "$DEST/$name"
  echo "  installed  $name"
  installed=$((installed + 1))
done

[ "$installed" -gt 0 ] || { echo "error: no tr-* skills found in $SRC" >&2; exit 1; }

# --- prune -------------------------------------------------------------------
# A tr-* skill that has been renamed or deleted upstream must actually go away,
# or the old copy keeps answering to its slash command.
pruned=0
for dir in "$DEST"/tr-*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  case " $names " in
    *" $name "*) ;;
    *) rm -rf "$dir"; echo "  PRUNED     $name (no longer in the repo)"; pruned=$((pruned + 1)) ;;
  esac
done

echo
echo "$installed skill(s) installed$( [ "$pruned" -gt 0 ] && echo ", $pruned pruned" ) into $DEST"
echo "Restart Claude Code to pick up the changes."
