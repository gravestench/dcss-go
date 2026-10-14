package visibility

import (
	"encoding/json"
	"os"
	"testing"
)

type goldenFile struct {
	SourceRevision string `json:"sourceRevision"`
	SourcePath     string `json:"sourcePath"`
	SourceSHA256   string `json:"sourceSHA256"`
	Maps           []struct {
		Name string   `json:"name"`
		Rows []string `json:"rows"`
	} `json:"maps"`
}

func TestSourceGoldenSightMaps(t *testing.T) {
	raw, err := os.ReadFile("testdata/dcss-los-tag34.json")

	if err != nil {
		t.Fatal(err)
	}

	var fixture goldenFile

	if err := json.Unmarshal(raw, &fixture); err != nil {
		t.Fatal(err)
	}

	if fixture.SourceRevision != "e60ba3568b0c26447ad36ec5c7b963eb04b2778f" ||
		fixture.SourcePath != "crawl-ref/source/dat/des/test/suite-los.des" ||
		fixture.SourceSHA256 != "850a05146a96e8d778c3f666ee07d7b6a056afc499081e2ca30ecd631380ed10" ||
		len(fixture.Maps) != 15 {
		t.Fatalf("bad source provenance or map count: %+v", fixture)
	}

	for _, mapCase := range fixture.Maps {
		t.Run(mapCase.Name, func(t *testing.T) {
			for _, mirrored := range []bool{false, true} {
				origin := 0
				size := 10

				if mirrored {
					origin = 9
					size = 19
				}

				rows := make([]string, size)
				want := make([]bool, size*size)

				for y := 0; y < size; y++ {
					row := make([]byte, size)

					for x := 0; x < size; x++ {
						sx, sy := x, y

						if mirrored {
							sx = x - origin

							if sx < 0 {
								sx = -sx
							}

							sy = y - origin

							if sy < 0 {
								sy = -sy
							}
						}

						symbol := mapCase.Rows[sy][sx]

						if symbol == '@' || symbol == '.' || symbol == 'w' {
							row[x] = '.'
						} else {
							row[x] = '#'
						}

						want[y*size+x] = symbol == '@' || symbol == '.' || symbol == 'x'
					}

					rows[y] = string(row)
				}

				got, err := Compute(rows, origin, origin, 7)

				if err != nil {
					t.Fatal(err)
				}

				if len(got) != len(want) {
					t.Fatalf("mask length %d, want %d", len(got), len(want))
				}

				for i, v := range want {
					if got[i] != v {
						t.Fatalf("mirrored=%t cell=(%d,%d) got %t want %t", mirrored, i%size, i/size, got[i], v)
					}
				}
			}
		})
	}
}

func TestVisibilityInputValidation(t *testing.T) {
	cases := []struct {
		name string
		rows []string
		x    int
		y    int
		r    int
	}{
		{
			name: "empty",
			rows: nil,
			x:    0,
			y:    0,
			r:    7,
		},
		{
			name: "ragged",
			rows: []string{"...", ".."},
			x:    0,
			y:    0,
			r:    7,
		},
		{
			name: "unknown",
			rows: []string{".?."},
			x:    0,
			y:    0,
			r:    7,
		},
		{
			name: "opaque origin",
			rows: []string{"#.."},
			x:    0,
			y:    0,
			r:    7,
		},
		{
			name: "negative origin",
			rows: []string{"..."},
			x:    -1,
			y:    0,
			r:    7,
		},
		{
			name: "outside origin",
			rows: []string{"..."},
			x:    3,
			y:    0,
			r:    7,
		},
		{
			name: "zero radius",
			rows: []string{"..."},
			x:    0,
			y:    0,
			r:    0,
		},
		{
			name: "large radius",
			rows: []string{"..."},
			x:    0,
			y:    0,
			r:    9,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if _, err := Compute(tc.rows, tc.x, tc.y, tc.r); err == nil {
				t.Fatal("accepted invalid input")
			}
		})
	}
}

func TestOpenTerrainChebyshevRange(t *testing.T) {
	rows := make([]string, 19)

	for y := range rows {
		rows[y] = "..................."
	}

	visible, err := Compute(rows, 9, 9, 7)

	if err != nil {
		t.Fatal(err)
	}

	for _, offset := range [][2]int{
		{7, 7},
		{-7, -7},
		{7, -7},
		{-7, 7},
	} {
		x, y := 9+offset[0], 9+offset[1]

		if !visible[y*19+x] {
			t.Fatalf("(%d,%d) should be visible", x, y)
		}
	}

	for _, offset := range [][2]int{
		{8, 0},
		{-8, 0},
		{0, 8},
		{0, -8},
	} {
		x, y := 9+offset[0], 9+offset[1]

		if visible[y*19+x] {
			t.Fatalf("(%d,%d) should be hidden", x, y)
		}
	}
}
