#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

long_lines=$(
	find cmd internal -name '*.go' -print0 |
		xargs -0 awk 'length($0) > 120 {
			print FILENAME ":" FNR ": " length($0) " columns"
		}'
)
if [ -n "$long_lines" ]; then
	printf '%s\n' "$long_lines"
	exit 1
fi

unformatted=$(find cmd internal -name '*.go' -exec gofmt -l {} +)
if [ -n "$unformatted" ]; then
	printf 'Run gofmt on:\n%s\n' "$unformatted"
	exit 1
fi
