package content

import "testing"

func TestDungeonPopulationWeightCurves(t *testing.T) {
	for _, tc := range []struct {
		curve string
		want  [3]int
	}{
		{"FLAT", [3]int{25200, 25200, 25200}},
		{"SEMI", [3]int{12600, 25200, 12600}},
		{"PEAK", [3]int{12600, 25200, 12600}},
		{"RISE", [3]int{8400, 16800, 25200}},
		{"FALL", [3]int{25200, 16800, 8400}},
	} {
		entry := DungeonPopEntry{MinDepth: 1, MaxDepth: 3, Rarity: 10, Curve: tc.curve, MonsterID: "MONS_RAT", SourceLine: 1}
		for depth := 1; depth <= 3; depth++ {
			if got := entry.WeightAtDepth(depth); got != tc.want[depth-1] {
				t.Errorf("%s depth %d = %d, want %d", tc.curve, depth, got, tc.want[depth-1])
			}
		}
		if entry.WeightAtDepth(0) != 0 || entry.WeightAtDepth(4) != 0 {
			t.Errorf("%s has weight outside depth range", tc.curve)
		}
	}
}

func TestDungeonPopulationArtifactRejectsMalformedRows(t *testing.T) {
	good := DungeonPopulationArtifact{SchemaVersion: 1, SourceRevision: sourceRevision, TagMajorVersion: 34,
		SourceFiles: []JobSourceFile{{Path: "crawl-ref/source/mon-pick-data.h", SHA256: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}},
		Rows:        []DungeonPopEntry{{MinDepth: 1, MaxDepth: 3, Rarity: 1000, Curve: "FLAT", MonsterID: "MONS_RAT", SourceLine: 60}}}
	if err := good.Validate(); err != nil {
		t.Fatal(err)
	}
	for _, bad := range []DungeonPopEntry{
		{MinDepth: 3, MaxDepth: 1, Rarity: 1000, Curve: "FLAT", MonsterID: "MONS_RAT", SourceLine: 60},
		{MinDepth: 1, MaxDepth: 3, Rarity: 0, Curve: "FLAT", MonsterID: "MONS_RAT", SourceLine: 60},
		{MinDepth: 1, MaxDepth: 3, Rarity: 1000, Curve: "BAD", MonsterID: "MONS_RAT", SourceLine: 60},
		{MinDepth: 1, MaxDepth: 3, Rarity: 1000, Curve: "FLAT", MonsterID: "RAT", SourceLine: 60},
	} {
		artifact := good
		artifact.Rows = []DungeonPopEntry{bad}
		if err := artifact.Validate(); err == nil {
			t.Fatalf("malformed row accepted: %+v", bad)
		}
	}
}
