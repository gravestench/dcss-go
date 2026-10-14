package terminal

import (
	"fmt"
	"os"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/save"
)

type ScreenID uint8

type confirmation uint8

const (
	confirmNone confirmation = iota
	confirmSave
	confirmAbandon
)

const (
	ScreenStartup ScreenID = iota
	ScreenSpecies
	ScreenBackground
	ScreenWeapon
	ScreenName
	ScreenPlay
	ScreenInventory
	ScreenSkills
	ScreenHelp
	ScreenConfirm
	ScreenDeath
	ScreenQuaff
	ScreenStatChoice
)

// AppModel owns terminal navigation; the Game owns every turn-changing state.
type AppModel struct {
	catalog                    content.Catalog
	presentation               content.PresentationArtifact
	seed                       uint64
	savePath                   string
	game                       *game.Game
	screen                     ScreenID
	previous                   ScreenID
	weaponReturn               ScreenID
	width, height              int
	name                       string
	speciesID, jobID, weaponID string
	options                    []character.WeaponOption
	focus                      int
	notice                     string
	confirm                    confirmation
}

func NewAppModel(catalog content.Catalog, seed uint64, savePath string) (*AppModel, error) {
	if err := catalog.Validate(); err != nil {
		return nil, err
	}

	if len(catalog.Presentation().SpeciesGroups) != 3 {
		return nil, fmt.Errorf("catalog lacks console presentation")
	}

	return &AppModel{
		catalog:      catalog,
		presentation: catalog.Presentation(),
		seed:         seed,
		savePath:     savePath,
		screen:       ScreenStartup,
		width:        79,
		height:       24,
	}, nil
}

func (m *AppModel) Init() tea.Cmd {
	return nil
}

func (m *AppModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := message.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
	case tea.KeyPressMsg:
		return m, m.handleKey(msg.String())
	}

	return m, nil
}

func (m *AppModel) handleKey(key string) tea.Cmd {
	if _, valid := ComputeLayout(m.width, m.height); !valid {
		return nil
	}

	switch m.screen {
	case ScreenStartup:
		return m.handleStartupKey(key)
	case ScreenSpecies, ScreenBackground:
		m.handleCharacterChoiceKey(key)
	case ScreenWeapon:
		m.handleWeaponKey(key)
	case ScreenName:
		m.handleNameKey(key)
	case ScreenPlay:
		return m.handlePlayKey(key)
	case ScreenStatChoice:
		m.handleStatChoiceKey(key)
	case ScreenInventory, ScreenSkills:
		m.handleModalKey(key)
	case ScreenQuaff:
		return m.handleQuaffKey(key)
	case ScreenConfirm:
		return m.handleConfirmKey(key)
	case ScreenDeath:
		if key == "esc" || key == "enter" {
			m.returnToStartup()
		}
	case ScreenHelp:
		if key == "esc" {
			m.screen, m.notice = m.previous, ""
		} else {
			m.notice = "This help control is unavailable in the Go port."
		}
	}

	return nil
}

func (m *AppModel) renderCanvas() *Canvas {
	canvas := NewCanvas(m.width, m.height)

	if _, ok := ComputeLayout(m.width, m.height); !ok {
		canvas.Write(0, 0, "Your terminal window is too small; please resize to at least 79,24", LightGrey, Black)

		return canvas
	}

	switch m.screen {
	case ScreenStartup:
		m.drawStartup(canvas)
	case ScreenSpecies, ScreenBackground:
		m.drawCharacterChoice(canvas)
	case ScreenWeapon:
		m.drawWeapon(canvas)
	case ScreenName:
		m.drawName(canvas)
	case ScreenPlay:
		layout, _ := ComputeLayout(m.width, m.height)

		if m.game != nil {
			DrawPlay(canvas, layout, m.game.View(), m.notice)
		}
	case ScreenStatChoice:
		layout, _ := ComputeLayout(m.width, m.height)

		if m.game != nil {
			DrawPlay(canvas, layout, m.game.View(), m.notice)
			canvas.Write(
				0, m.height-1,
				"Increase (S)trength, (I)ntelligence, or (D)exterity?",
				LightGrey, Black,
			)
		}
	case ScreenInventory:
		if m.game != nil {
			DrawInventory(canvas, m.game.View())
		}

		m.drawModalNotice(canvas)
	case ScreenSkills:
		if m.game != nil {
			DrawSkills(canvas, m.game.View(), m.catalog)
		}

		m.drawModalNotice(canvas)
	case ScreenQuaff:
		if m.game != nil {
			DrawQuaff(canvas, m.game.View())
		}

		m.drawModalNotice(canvas)
	case ScreenHelp:
		DrawHelp(canvas)
		m.drawModalNotice(canvas)
	case ScreenConfirm:
		m.drawConfirm(canvas)
	case ScreenDeath:
		canvas.Write(0, 0, "You die...", LightRed, Black)
		canvas.Write(0, 2, "Press Enter to return to startup.", LightGrey, Black)
		canvas.Write(0, 4, "Morgue and high scores are unavailable in the Go port.", Brown, Black)
	}

	return canvas
}

func (m *AppModel) View() tea.View {
	view := tea.NewView(m.renderCanvas().Styled())
	view.AltScreen = true

	return view
}

func (m *AppModel) Close() error {
	if m.game != nil {
		return m.game.Close()
	}

	return nil
}

func (m *AppModel) savedRunExists() bool {
	_, err := os.Stat(m.savePath)

	return err == nil
}

func (m *AppModel) loadSavedRun() {
	snapshot, err := save.Read(m.savePath)

	if err != nil {
		m.notice = fmt.Sprintf("Load failed: %v", err)

		return
	}

	restored, err := game.Restore(snapshot, m.catalog)

	if err != nil {
		m.notice = fmt.Sprintf("Load failed: %v", err)

		return
	}

	if m.game != nil {
		_ = m.game.Close()
	}

	m.game = restored
	m.screen = ScreenPlay

	if restored.View().PendingStatLevel != 0 {
		m.screen = ScreenStatChoice
	}

	m.notice = ""
}

func (m *AppModel) returnToStartup() {
	if m.game != nil {
		_ = m.game.Close()
	}

	m.game = nil
	m.screen, m.previous, m.weaponReturn = ScreenStartup, ScreenStartup, ScreenStartup
	m.name, m.speciesID, m.jobID, m.weaponID = "", "", "", ""
	m.options = nil
	m.focus, m.notice, m.confirm = 0, "", confirmNone
}
