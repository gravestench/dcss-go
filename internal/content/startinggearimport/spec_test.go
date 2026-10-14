package startinggearimport

import (
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func TestParseEquipmentSpec(t *testing.T) {
	for _, tc := range []struct {
		raw  string
		name string
		want content.StartingGrant
	}{
		{
			raw:  "scale mail",
			name: "scale mail",
			want: content.StartingGrant{
				Raw:      "scale mail",
				Quantity: 1,
			},
		},

		{
			raw:  "potion of invisibility q:2",
			name: "potion of invisibility",
			want: content.StartingGrant{
				Raw:      "potion of invisibility q:2",
				Quantity: 2,
			},
		},

		{
			raw:  "wand of flame charges:15",
			name: "wand of flame",
			want: content.StartingGrant{
				Raw:      "wand of flame charges:15",
				Quantity: 1,
				Charges:  15,
			},
		},

		{
			raw:  "dart ego:curare q:3",
			name: "dart",
			want: content.StartingGrant{
				Raw:      "dart ego:curare q:3",
				Quantity: 3,
				Ego:      "curare",
			},
		},

		{
			raw:  "scroll of fog no_exclude",
			name: "scroll of fog",
			want: content.StartingGrant{
				Raw:       "scroll of fog no_exclude",
				Quantity:  1,
				NoExclude: true,
			},
		},

		{
			raw:  "piece from Xom's chessboard",
			name: "piece from Xom's chessboard",
			want: content.StartingGrant{
				Raw:      "piece from Xom's chessboard",
				Quantity: 1,
			},
		},

		{
			raw:  "dagger plus:2",
			name: "dagger",
			want: content.StartingGrant{
				Raw:      "dagger plus:2",
				Quantity: 1,
				Plus:     2,
			},
		},
	} {
		t.Run(tc.raw, func(t *testing.T) {
			name, got, err := parseEquipmentSpec("JOB_TEST", tc.raw)

			if err != nil {
				t.Fatal(err)
			}

			if name != tc.name || got != tc.want {
				t.Fatalf("got %q, %+v; want %q, %+v", name, got, tc.name, tc.want)
			}
		})
	}
}

func TestParseEquipmentSpecRejectsBadTag(t *testing.T) {
	for _, raw := range []string{
		"dart q:2 q:3",
		"dart q:0",
		"wand of flame charges:-1",
		"dart unknown:3",
		"dart q:many",
		"q:2",
		" ",
		"dagger plus:1 charges:3",
		"dart no_exclude no_exclude",
		"dart ego:",
		"scroll of fog no_exclude:false",
		"scroll of fog no_exclude:",
		"dart q:2 trailing",
		"dart q:2 garbage:3",
	} {
		t.Run(raw, func(t *testing.T) {
			_, _, err := parseEquipmentSpec("JOB_BRIGAND", raw)

			if err == nil || !strings.Contains(err.Error(), "JOB_BRIGAND") || !strings.Contains(err.Error(), raw) {
				t.Fatalf("want contextual error for %q, got %v", raw, err)
			}
		})
	}
}
