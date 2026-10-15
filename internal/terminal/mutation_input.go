package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
)

func (m *AppModel) handleMutationInput(key string) tea.Cmd {
	result, err := m.game.PresentationPolicy("presentation.mutations", map[string]any{
		"height":   m.height,
		"width":    m.width,
		"page":     m.mutationPage,
		"selected": m.mutationSelected,
	})

	if err != nil {
		m.notice = fmt.Sprintf("Mutation menu failed: %v", err)

		return nil
	}

	pages, ok := result["pages"].(int64)

	if !ok || pages < 1 {
		m.notice = "Mutation menu returned an invalid page count."

		return nil
	}

	m.mutationPages = int(pages)
	m.mutationOptions = make(map[string]string)

	for _, raw := range policyRows(result["options"]) {
		option := policyRecord(raw)
		key, keyOK := option["key"].(string)
		id, idOK := option["id"].(string)

		if !keyOK ||
			!idOK ||
			key == "" ||
			id == "" {
			m.notice = "Mutation menu returned an invalid option."

			return nil
		}

		m.mutationOptions[key] = id
	}

	return m.routeInput("mutations", key, map[string]any{
		"page":     m.mutationPage,
		"pages":    pages,
		"selected": m.mutationSelected,
		"options":  result["options"],
	})
}

func (m *AppModel) applyMutationDecision(
	action string,
	decision map[string]any,
) tea.Cmd {
	switch action {
	case "mutation_page":
		return m.applyMutationPageDecision(decision)

	case "mutation_detail":
		id, ok := decision["id"].(string)

		if !ok || !m.canExamineMutation(id) {
			m.notice = "Input policy returned an invalid mutation."

			return nil
		}

		m.mutationSelected = id
		m.mutationListPage = m.mutationPage
		m.mutationPage = 0
		m.notice = ""

	case "mutation_close_detail":
		m.mutationSelected = ""
		m.mutationPage = m.mutationListPage
		m.notice = ""
	}

	return nil
}

func (m *AppModel) canExamineMutation(id string) bool {
	for _, optionID := range m.mutationOptions {
		if optionID == id {
			return true
		}
	}

	return false
}

func (m *AppModel) applyMutationPageDecision(decision map[string]any) tea.Cmd {
	page, ok := decision["page"].(int64)

	if !ok ||
		page < 0 ||
		page >= int64(m.mutationPages) {
		m.notice = "Input policy returned an invalid mutation page."

		return nil
	}

	m.mutationPage = int(page)
	m.notice = ""

	return nil
}
