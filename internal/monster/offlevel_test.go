package monster

import (
	"fmt"
	"testing"
)

type offLevelRoller struct {
	values []int
	calls  int
}

func (r *offLevelRoller) Intn(stream string, bound int) (int, error) {
	if stream != "offlevel" || bound != 100 || r.calls >= len(r.values) {
		return 0, fmt.Errorf("unexpected off-level roll %s/%d", stream, bound)
	}

	value := r.values[r.calls]
	r.calls++

	return value, nil
}

func TestOffLevelRecoveryUsesSourceFractionalRound(t *testing.T) {
	for _, tc := range []struct {
		name   string
		turns  int
		values []int
		want   int
	}{
		{
			name:  "no elapsed turn",
			turns: 0,
			want:  0,
		},
		{
			name:   "fraction rounds up",
			turns:  9,
			values: []int{89},
			want:   1,
		},
		{
			name:   "fraction rounds down",
			turns:  9,
			values: []int{90},
			want:   0,
		},
		{
			name:  "whole point consumes no draw",
			turns: 10,
			want:  1,
		},
		{
			name:   "whole point plus fraction",
			turns:  19,
			values: []int{89},
			want:   2,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			roller := &offLevelRoller{values: tc.values}
			got, err := OffLevelRecovery(roller, tc.turns, 10)

			if err != nil || got != tc.want || roller.calls != len(tc.values) {
				t.Fatalf("recovery = %d, calls = %d, err = %v", got, roller.calls, err)
			}
		})
	}
}

func TestFastOffLevelRecoveryHealsOncePerAwayTurn(t *testing.T) {
	roller := &offLevelRoller{}
	got, err := OffLevelRecovery(roller, 17, 100)

	if err != nil || got != 17 || roller.calls != 0 {
		t.Fatalf("fast recovery = %d, calls = %d, error = %v", got, roller.calls, err)
	}
}

func TestOffLevelMoveCountUsesSourceSpeedAndCap(t *testing.T) {
	for _, tc := range []struct {
		turns int
		speed int
		want  int
	}{
		{
			turns: 0,
			speed: 12,
			want:  0,
		},
		{
			turns: 1,
			speed: 12,
			want:  1,
		},
		{
			turns: 9,
			speed: 12,
			want:  10,
		},
		{
			turns: 100,
			speed: 12,
			want:  50,
		},
	} {
		got := OffLevelMoveCount(tc.turns, tc.speed)

		if got != tc.want {
			t.Fatalf("%d turns at speed %d => %d moves, want %d", tc.turns, tc.speed, got, tc.want)
		}
	}
}
