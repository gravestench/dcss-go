package terminal

import "testing"

func TestNoWeaponChoiceSkipsWeaponScreen(t *testing.T) {
	for _, name := range []string{"", "Alice"} {
		t.Run(name, func(t *testing.T) {
			m := pregameModel(t)

			m.name = name
			m.selectSpecies("SP_HUMAN")
			m.selectBackground("JOB_FIRE_ELEMENTALIST")

			if m.weaponID != "" || len(m.options) != 0 {
				t.Fatalf("no-choice job received weapon options: %q / %+v",
					m.weaponID,
					m.options,
				)
			}

			if name == "" && m.screen != ScreenName {
				t.Fatalf("unnamed character reached %v, want name", m.screen)
			}

			if name != "" && (m.screen != ScreenPlay || m.game == nil) {
				t.Fatalf("named character failed to start: %v / %s", m.screen, m.notice)
			}
		})
	}
}
