package jobimport

import (
	"fmt"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

type token struct {
	kind  string
	value string
}

func lexJobData(path, source string) ([]token, error) {
	var tokens []token

	for i := 0; i < len(source); {
		ch := source[i]

		switch {
		case ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r':
			i++
		case ch == '{' || ch == '}' || ch == ',' || ch == ';':
			tokens = append(tokens, token{
				kind:  string(ch),
				value: string(ch),
			})
			i++
		case ch == '"':
			start := i
			i++
			escaped := false

			for i < len(source) {
				if escaped {
					escaped = false
				} else if source[i] == '\\' {
					escaped = true
				} else if source[i] == '"' {
					i++
					break
				}

				i++
			}

			if i > len(source) || source[i-1] != '"' {
				return nil, fmt.Errorf("%s: unterminated job string", path)
			}

			value, err := strconv.Unquote(source[start:i])

			if err != nil {
				return nil, fmt.Errorf("%s: invalid job string: %w", path, err)
			}

			tokens = append(tokens, token{
				kind:  "string",
				value: value,
			})
		case ch == '-' || ch == '+' || ch >= '0' && ch <= '9':
			start := i
			i++

			for i < len(source) && source[i] >= '0' && source[i] <= '9' {
				i++
			}

			if _, err := strconv.Atoi(source[start:i]); err != nil {
				return nil, fmt.Errorf("%s: invalid integer %q", path, source[start:i])
			}

			tokens = append(tokens, token{
				kind:  "integer",
				value: source[start:i],
			})
		case ch >= 'A' && ch <= 'Z' || ch >= 'a' && ch <= 'z' || ch == '_':
			start := i
			i++

			for i < len(source) {
				c := source[i]

				if c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z' || c >= '0' && c <= '9' || c == '_' {
					i++
				} else {
					break
				}
			}

			tokens = append(tokens, token{
				kind:  "identifier",
				value: source[start:i],
			})
		default:
			return nil, fmt.Errorf("%s: unsupported job initializer character %q", path, ch)
		}
	}

	return tokens, nil
}

type jobParser struct {
	path   string
	tokens []token
	index  int
}

func (p *jobParser) peek() token {
	if p.index >= len(p.tokens) {
		return token{kind: "end"}
	}

	return p.tokens[p.index]
}

func (p *jobParser) take(kind, field string) (string, error) {
	current := p.peek()

	if current.kind != kind {
		return "", fmt.Errorf("%s: expected %s in %s, got %q", p.path, kind, field, current.value)
	}

	p.index++

	return current.value, nil
}

func (p *jobParser) symbol(symbol, field string) error {
	_, err := p.take(symbol, field)

	return err
}

func (p *jobParser) integer(field string) (int, error) {
	value, err := p.take("integer", field)

	if err != nil {
		return 0, err
	}

	number, err := strconv.Atoi(value)

	if err != nil {
		return 0, fmt.Errorf("%s: invalid %s integer %s", p.path, field, value)
	}

	return number, nil
}

func (p *jobParser) vector(kind, field string) ([]string, error) {
	if err := p.symbol("{", field); err != nil {
		return nil, err
	}

	var values []string

	for p.peek().kind != "}" {
		value, err := p.take(kind, field)

		if err != nil {
			return nil, err
		}

		values = append(values, value)

		if p.peek().kind == "}" {
			break
		}

		if err := p.symbol(",", field); err != nil {
			return nil, err
		}
	}

	return values, p.symbol("}", field)
}

func (p *jobParser) skills() ([]content.JobSkillGrant, error) {
	if err := p.symbol("{", "skills"); err != nil {
		return nil, err
	}

	var skills []content.JobSkillGrant

	for p.peek().kind != "}" {
		if err := p.symbol("{", "skill grant"); err != nil {
			return nil, err
		}

		id, err := p.take("identifier", "skill ID")

		if err != nil {
			return nil, err
		}

		if err := p.symbol(",", "skill grant"); err != nil {
			return nil, err
		}

		level, err := p.integer("skill level")

		if err != nil {
			return nil, err
		}

		if err := p.symbol("}", "skill grant"); err != nil {
			return nil, err
		}

		skills = append(skills, content.JobSkillGrant{
			ID:    id,
			Level: level,
		})

		if p.peek().kind == "}" {
			break
		}

		if err := p.symbol(",", "skills"); err != nil {
			return nil, err
		}
	}

	return skills, p.symbol("}", "skills")
}

func (p *jobParser) job() (job content.JobDef, err error) {
	if err = p.symbol("{", "job entry"); err != nil {
		return job, err
	}

	job.ID, err = p.take("identifier", "job ID")

	if err != nil {
		return job, err
	}

	defer func() {
		if err != nil {
			err = fmt.Errorf("%s: %s: %w", p.path, job.ID, err)
		}
	}()

	if err = p.symbol(",", "job entry"); err != nil {
		return job, err
	}

	if err = p.symbol("{", "job fields"); err != nil {
		return job, err
	}

	job.SourcePath = p.path
	job.Abbreviation, err = p.take("string", "abbreviation")

	if err != nil {
		return job, err
	}

	if err = p.symbol(",", "abbreviation"); err != nil {
		return job, err
	}

	job.Name, err = p.take("string", "name")

	if err != nil {
		return job, err
	}

	if err = p.symbol(",", "name"); err != nil {
		return job, err
	}

	for i, target := range []*int{&job.Strength, &job.Intelligence, &job.Dexterity} {
		field := []string{"strength", "intelligence", "dexterity"}[i]
		*target, err = p.integer(field)

		if err != nil {
			return job, err
		}

		if err = p.symbol(",", field); err != nil {
			return job, err
		}
	}

	job.RecommendedSpecies, err = p.vector("identifier", "recommended species")

	if err != nil {
		return job, err
	}

	if err = p.symbol(",", "recommended species"); err != nil {
		return job, err
	}

	job.Spells, err = p.vector("identifier", "spells")

	if err != nil {
		return job, err
	}

	if err = p.symbol(",", "spells"); err != nil {
		return job, err
	}

	job.Equipment, err = p.vector("string", "equipment")

	if err != nil {
		return job, err
	}

	if err = p.symbol(",", "equipment"); err != nil {
		return job, err
	}

	job.WeaponChoice, err = p.take("identifier", "weapon choice")

	if err != nil {
		return job, err
	}

	if err = p.symbol(",", "weapon choice"); err != nil {
		return job, err
	}

	job.Skills, err = p.skills()

	if err != nil {
		return job, err
	}

	if p.peek().kind == "," {
		p.index++
	}

	if err = p.symbol("}", "job fields"); err != nil {
		return job, err
	}

	if err = p.symbol("}", "job entry"); err != nil {
		return job, err
	}

	job.Selectable = len(job.RecommendedSpecies) > 0
	err = jobValidation(job)

	return job, err
}

func jobValidation(job content.JobDef) error {
	return (content.JobArtifact{
		SchemaVersion:   1,
		SourceRevision:  "source",
		TagMajorVersion: 34,
		Jobs:            []content.JobDef{job},
	}).Validate()
}

func parseJobData(path string, data []byte) ([]content.JobDef, error) {
	lines, err := sourceparse.Tag34Lines(path, data)

	if err != nil {
		return nil, err
	}

	filtered := strings.Join(lines, "\n")
	start := strings.Index(filtered, "job_data =")

	if start < 0 {
		return nil, fmt.Errorf("%s: job_data initializer missing", path)
	}

	tokens, err := lexJobData(path, filtered[start+len("job_data ="):])

	if err != nil {
		return nil, err
	}

	p := jobParser{
		path:   path,
		tokens: tokens,
	}

	if err := p.symbol("{", "job_data"); err != nil {
		return nil, err
	}

	var jobs []content.JobDef
	seen := map[string]bool{}

	for p.peek().kind != "}" {
		job, err := p.job()

		if err != nil {
			return nil, err
		}

		if seen[job.ID] {
			return nil, fmt.Errorf("%s: duplicate job %s", path, job.ID)
		}

		seen[job.ID] = true
		jobs = append(jobs, job)

		if p.peek().kind == "}" {
			break
		}

		if err := p.symbol(",", "job_data entries"); err != nil {
			return nil, err
		}
	}

	if err := p.symbol("}", "job_data"); err != nil {
		return nil, err
	}

	if err := p.symbol(";", "job_data terminator"); err != nil {
		return nil, err
	}

	if p.peek().kind != "end" || len(jobs) == 0 {
		return nil, fmt.Errorf("%s: trailing tokens or empty job_data", path)
	}

	return jobs, nil
}
