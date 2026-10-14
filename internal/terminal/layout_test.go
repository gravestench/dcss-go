package terminal

import "testing"

func TestLayoutMatchesMinimumAndExpandedConsole(t *testing.T) {
	for _, tc := range []struct {
		width  int
		height int
		want   Layout
	}{
		{
			width:  79,
			height: 24,
			want: Layout{
				Dungeon: Region{
					X: 0,
					Y: 0,
					W: 33,
					H: 17,
				},

				Gutter: Region{
					X: 33,
					Y: 0,
					W: 4,
					H: 17,
				},

				HUD: Region{
					X: 37,
					Y: 0,
					W: 42,
					H: 13,
				},

				Monsters: Region{
					X: 37,
					Y: 13,
					W: 42,
					H: 4,
				},

				Messages: Region{
					X: 0,
					Y: 17,
					W: 79,
					H: 7,
				},
			},
		},

		{
			width:  120,
			height: 40,
			want: Layout{
				Dungeon: Region{
					X: 0,
					Y: 0,
					W: 74,
					H: 33,
				},

				Gutter: Region{
					X: 74,
					Y: 0,
					W: 4,
					H: 33,
				},

				HUD: Region{
					X: 78,
					Y: 0,
					W: 42,
					H: 13,
				},

				Monsters: Region{
					X: 78,
					Y: 13,
					W: 42,
					H: 20,
				},

				Messages: Region{
					X: 0,
					Y: 33,
					W: 120,
					H: 7,
				},
			},
		},
	} {
		got, ok := ComputeLayout(tc.width, tc.height)

		if !ok || got != tc.want {
			t.Fatalf("layout %dx%d = %+v, valid %v; want %+v", tc.width, tc.height, got, ok, tc.want)
		}
	}
}

func TestLayoutRejectsBelowMinimum(t *testing.T) {
	for _, size := range [][2]int{
		{78, 24},
		{79, 23},
		{78, 23},
		{0, 0},
	} {
		if _, ok := ComputeLayout(size[0], size[1]); ok {
			t.Fatalf("accepted %dx%d", size[0], size[1])
		}
	}
}
