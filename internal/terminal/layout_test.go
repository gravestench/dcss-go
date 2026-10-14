package terminal

import "testing"

func TestLayoutMatchesMinimumAndExpandedConsole(t *testing.T) {
	for _, tc := range []struct {
		width, height int
		want          Layout
	}{
		{79, 24, Layout{
			Dungeon: Region{
				0,
				0,
				33,
				17,
			},
			Gutter: Region{
				33,
				0,
				4,
				17,
			},
			HUD: Region{
				37,
				0,
				42,
				13,
			},
			Monsters: Region{
				37,
				13,
				42,
				4,
			},
			Messages: Region{
				0,
				17,
				79,
				7,
			},
		}},
		{120, 40, Layout{
			Dungeon: Region{
				0,
				0,
				74,
				33,
			},
			Gutter: Region{
				74,
				0,
				4,
				33,
			},
			HUD: Region{
				78,
				0,
				42,
				13,
			},
			Monsters: Region{
				78,
				13,
				42,
				20,
			},
			Messages: Region{
				0,
				33,
				120,
				7,
			},
		}},
	} {
		got, ok := ComputeLayout(tc.width, tc.height)
		if !ok || got != tc.want {
			t.Fatalf("layout %dx%d = %+v, valid %v; want %+v", tc.width, tc.height, got, ok, tc.want)
		}
	}
}

func TestLayoutRejectsBelowMinimum(t *testing.T) {
	for _, size := range [][2]int{{78, 24}, {79, 23}, {78, 23}, {0, 0}} {
		if _, ok := ComputeLayout(size[0], size[1]); ok {
			t.Fatalf("accepted %dx%d", size[0], size[1])
		}
	}
}
