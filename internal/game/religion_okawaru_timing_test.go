package game

import "testing"

// Finesse changes the real attack command's elapsed aut. The same test
// runs through Lua timing and the Go scheduler rather than a private
// formula that gameplay never calls.
func TestOkawaruFinesseSpeedsMeleeWithoutStackingHaste(t *testing.T) {
	attack := func(finesse, haste bool) Aut {
		t.Helper()

		g := newStepGame(t)
		defer g.Close()

		if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
			t.Fatal(err)
		}

		if finesse {
			_, err := g.scripts.Components()["religion.worship"].Set(
				g.player,
				map[string]any{
					"god_id": "GOD_OKAWARU",
					"piety":  int64(200),
				},
			)
			if err != nil {
				t.Fatal(err)
			}

			_, err = g.scripts.Components()["religion.okawaru_status"].Set(
				g.player,
				map[string]any{
					"finesse_aut": int64(200),
				},
			)
			if err != nil {
				t.Fatal(err)
			}
		}

		if haste {
			durations, _ := g.stores.Durations.Get(g.player)
			durations.HasteAut = 200
		}

		result, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})
		if err != nil {
			t.Fatal(err)
		}

		return result.Spent
	}

	ordinary := attack(false, false)
	fast := attack(true, false)
	hasted := attack(false, true)
	combined := attack(true, true)

	if fast >= ordinary || combined >= hasted ||
		combined < fast-1 || combined > fast+1 {
		t.Fatalf("attack costs ordinary=%d finesse=%d haste=%d both=%d",
			ordinary, fast, hasted, combined)
	}
}
