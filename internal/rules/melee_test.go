package rules

import "testing"

// MONS_RAT bite base damage is 3 in crawl-ref/source/mon-data.h:1998.
func TestRatBaseDamage(t *testing.T) {
	for _, test := range []struct{ roll, want int }{{-1, 0}, {2, 2}, {8, 3}} {
		if got := MeleeDamage(3, test.roll); got != test.want {
			t.Fatalf("MeleeDamage(3, %d) = %d, want %d", test.roll, got, test.want)
		}
	}
}
