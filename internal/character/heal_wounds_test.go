package character

import (
	"fmt"
	"testing"
)

type healWoundsRoller struct {
	values []int
	bounds []int
}

func (r *healWoundsRoller) Intn(stream string, bound int) (int, error) {
	if stream != "potion" || len(r.values) == 0 {
		return 0, fmt.Errorf("unexpected heal wounds draw %s/%d", stream, bound)
	}
	r.bounds = append(r.bounds, bound)
	value := r.values[0]
	r.values = r.values[1:]
	return value, nil
}

func TestHealWoundsUsesSourceThreeRollAverage(t *testing.T) {
	for _, tc := range []struct {
		values                 []int
		current, maximum, want int
	}{
		{
			values:  []int{0, 0, 0},
			current: 1,
			maximum: 40,
			want:    11,
		},
		{
			values:  []int{27, 28, 28},
			current: 1,
			maximum: 40,
			want:    38,
		},
		{
			values:  []int{1, 2, 3},
			current: 1,
			maximum: 40,
			want:    13,
		},
		{
			values:  []int{27, 28, 28},
			current: 35,
			maximum: 40,
			want:    40,
		},
	} {
		r := &healWoundsRoller{values: tc.values}
		got, err := HealWoundsHP(r, tc.current, tc.maximum)
		if err != nil || got != tc.want || len(r.values) != 0 || len(r.bounds) != 3 ||
			r.bounds[0] != 28 || r.bounds[1] != 29 || r.bounds[2] != 29 {
			t.Fatalf(
				"rolls %+v at %d/%d => %d, %v, bounds %+v; want %d",
				tc.values,
				tc.current,
				tc.maximum,
				got,
				err,
				r.bounds,
				tc.want,
			)
		}
	}
}

func TestHealWoundsRejectsInvalidInputAndDraws(t *testing.T) {
	for _, tc := range []struct {
		current, maximum int
	}{
		{
			current: 0,
			maximum: 18,
		},
		{
			current: 19,
			maximum: 18,
		},
		{
			current: 1,
			maximum: 0,
		},
	} {
		r := &healWoundsRoller{values: []int{0, 0, 0}}
		if _, err := HealWoundsHP(r, tc.current, tc.maximum); err == nil || len(r.bounds) != 0 {
			t.Fatalf("accepted %d/%d with draws %+v", tc.current, tc.maximum, r.bounds)
		}
	}
	for _, invalid := range []int{-1, 28} {
		r := &healWoundsRoller{values: []int{invalid, 0, 0}}
		if _, err := HealWoundsHP(r, 1, 18); err == nil {
			t.Fatalf("accepted first draw %d", invalid)
		}
	}
}
