#!/usr/bin/env bash
# Find PipeWire sinks that fail to start, and print a WirePlumber rule that disables them.
set -euo pipefail
since="${1:--1h}"

bad=$(journalctl --user --since "$since" --no-pager 2>/dev/null \
  | grep -oP 'pw\.node: \(\K[^ ]+(?=-[0-9]+\) \S+ -> error \(Start error)' | sort -u || true)

recov=$(journalctl --user -u wireplumber --since "$since" --no-pager 2>/dev/null \
  | grep -c 'recovery attempts, giving up' || true)

echo "WirePlumber card-recovery give-ups since $since: $recov"
if [ -z "$bad" ]; then
  echo "No sinks with start errors found. Open the volume tray icon a few times, then re-run."
  exit 0
fi

echo "Sinks failing to start:"
printf '  %s\n' $bad
echo
echo "# Save as ~/.config/wireplumber/wireplumber.conf.d/60-disable-broken-sinks.conf"
echo "monitor.alsa.rules = ["
for n in $bad; do
  printf '  {\n    matches = [ { node.name = "%s" } ]\n    actions = { update-props = { node.disabled = true } }\n  }\n' "$n"
done
echo "]"
