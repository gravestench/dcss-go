package game

import "testing"

func TestWandererFallbackUsesGeneratedAttributes(t *testing.T) {
	testCases := []struct {
		name   string
		seed   uint64
		want   string
		forbid string
	}{
		{
			name:   "dexterous fallback weapon",
			seed:   1,
			want:   "WPN_DAGGER",
			forbid: "WPN_CLUB",
		},

		{
			name:   "strong fallback armour",
			seed:   6,
			want:   "ARM_LEATHER_ARMOUR",
			forbid: "ARM_ROBE",
		},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			game, err := NewDungeonGame(
				testCase.seed,
				"SP_HUMAN",
				"JOB_WANDERER",
				"",
				"Tester",
			)

			if err != nil {
				t.Fatal(err)
			}

			defer game.Close()
			found := false

			for _, item := range game.View().Inventory {
				if item.KindID == testCase.want {
					found = true
				}

				if item.KindID == testCase.forbid {
					t.Fatalf("fallback used base stats: found %s", item.KindID)
				}
			}

			if !found {
				t.Fatalf("generated-stat fallback %s was not equipped", testCase.want)
			}
		})
	}
}
