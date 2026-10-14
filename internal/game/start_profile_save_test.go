package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

func savedPlayer(t *testing.T, snapshot *save.Snapshot) *save.EntityRecord {
	t.Helper()

	for i := range snapshot.Entities {
		if snapshot.Entities[i].Player != nil {
			return &snapshot.Entities[i]
		}
	}

	t.Fatal("snapshot has no player")

	return nil
}

func TestStartProfileSaveRoundTrip(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)

	health.Current = 7

	magic, _ := g.stores.Magic.Get(g.player)

	magic.Current = 0

	before := g.Snapshot()

	if before.Version != save.Version ||
		savedPlayer(t, &before).Player.StartingWeaponID != "WPN_RAPIER" {
		t.Fatalf("unexpected save header or choice: %+v", before)
	}

	restored, err := Restore(before, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("start profile changed across save/restore")
	}

	view := restored.View()

	if view.PlayerHP != 7 ||
		view.PlayerMaxHP != 18 ||
		view.PlayerMP != 0 ||
		view.PlayerMaxMP != 1 ||
		len(view.Skills) != 4 {
		t.Fatalf("restored profile = %+v", view)
	}

	for _, command := range []Command{
		{Kind: CommandWait},
		{
			Kind: CommandMove,
			DX:   1,
		},
	} {
		left, leftErr := g.Step(command)
		right, rightErr := restored.Step(command)

		if leftErr != nil ||
			rightErr != nil ||
			!reflect.DeepEqual(left, right) {
			t.Fatalf("continuation differs: %+v/%v vs %+v/%v", left, leftErr, right, rightErr)
		}
	}
}

func TestSaveProfileSlicesDoNotAlias(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()

	savedPlayer(t, &snapshot).Skills.Entries[0].Points = -17

	if g.View().Skills[0].Points != 301 {
		t.Fatal("snapshot mutation changed live game")
	}

	input := g.Snapshot()
	restored, err := Restore(input, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	savedPlayer(t, &input).Skills.Entries[0].Points = -18

	if restored.View().Skills[0].Points != 301 {
		t.Fatal("restore retained caller-owned skill slice")
	}
}

func TestRestoreRejectsInvalidStartProfile(t *testing.T) {
	for _, tc := range []struct {
		name   string
		mutate func(*save.Snapshot)
	}{
		{
			name: "duplicate skill",
			mutate: func(s *save.Snapshot) {
				p := savedPlayer(t, s)

				p.Skills.Entries[1] = p.Skills.Entries[0]
			},
		},

		{
			name: "reordered skills",
			mutate: func(s *save.Snapshot) {
				p := savedPlayer(t, s)

				p.Skills.Entries[0], p.Skills.Entries[1] = p.Skills.Entries[1], p.Skills.Entries[0]
			},
		},

		{
			name: "unknown skill",
			mutate: func(s *save.Snapshot) {
				savedPlayer(t, s).Skills.Entries[0].ID = "SK_UNKNOWN"
			},
		},

		{
			name: "changed points",
			mutate: func(s *save.Snapshot) {
				savedPlayer(t, s).Skills.Entries[0].Points++
			},
		},

		{
			name: "changed level",
			mutate: func(s *save.Snapshot) {
				savedPlayer(t, s).Skills.Entries[0].Level++
			},
		},

		{
			name: "missing skills",
			mutate: func(s *save.Snapshot) {
				savedPlayer(t, s).Skills = nil
			},
		},

		{
			name: "missing magic",
			mutate: func(s *save.Snapshot) {
				savedPlayer(t, s).Magic = nil
			},
		},

		{
			name: "monster skills",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].AI != nil {
						s.Entities[i].Skills = &ecs.Skills{
							Entries: []character.Skill{
								{
									ID:     "SK_FIGHTING",
									Level:  3,
									Points: 301,
								},
							},
						}
					}
				}
			},
		},

		{
			name: "item skills",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil {
						s.Entities[i].Skills = &ecs.Skills{
							Entries: []character.Skill{
								{
									ID:     "SK_FIGHTING",
									Level:  3,
									Points: 301,
								},
							},
						}

						return
					}
				}
			},
		},

		{
			name: "monster magic",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].AI != nil {
						s.Entities[i].Magic = &ecs.Magic{
							Current: 1,
							Max:     1,
						}
					}
				}
			},
		},

		{
			name: "item magic",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil {
						s.Entities[i].Magic = &ecs.Magic{
							Current: 1,
							Max:     1,
						}

						return
					}
				}
			},
		},

		{
			name: "negative MP",
			mutate: func(s *save.Snapshot) {
				savedPlayer(t, s).Magic.Current = -1
			},
		},

		{
			name: "over-max MP",
			mutate: func(s *save.Snapshot) {
				savedPlayer(t, s).Magic.Current = 2
			},
		},

		{
			name: "changed max MP",
			mutate: func(s *save.Snapshot) {
				savedPlayer(t, s).Magic.Max = 2
			},
		},

		{
			name: "version three",
			mutate: func(s *save.Snapshot) {
				s.Version = 3
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newStepGame(t)
			before := g.Snapshot()
			invalid := g.Snapshot()
			tc.mutate(&invalid)

			if replacement, err := g.Restore(invalid); err == nil {
				replacement.Close()
				t.Fatal("invalid profile accepted")
			}

			if !reflect.DeepEqual(before, g.Snapshot()) {
				t.Fatal("failed restore changed live game")
			}
		})
	}
}
