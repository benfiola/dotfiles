// Package claude manages Claude Code session transcripts.
package claude

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

// Session is a Claude Code transcript and the data stored alongside it.
type Session struct {
	ID         string
	Path       string
	ProjectDir string
	Cwd        string
	Title      string
	ModTime    time.Time
	// Size is the transcript plus its tool-result and file-history directories.
	Size int64
}

func claudeDir() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".claude")
}

func (s Session) dataDir() string {
	return existingDir(filepath.Join(s.ProjectDir, s.ID))
}

func (s Session) fileHistoryDir() string {
	return existingDir(filepath.Join(claudeDir(), "file-history", s.ID))
}

func existingDir(path string) string {
	if info, err := os.Stat(path); err == nil && info.IsDir() {
		return path
	}
	return ""
}

// Discover loads every session, newest first.
func Discover() ([]Session, error) {
	projectsDir := filepath.Join(claudeDir(), "projects")
	projects, err := os.ReadDir(projectsDir)
	if errors.Is(err, fs.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	var paths []string
	for _, project := range projects {
		if !project.IsDir() {
			continue
		}
		matches, _ := filepath.Glob(filepath.Join(projectsDir, project.Name(), "*.jsonl"))
		paths = append(paths, matches...)
	}

	sessions := make([]Session, len(paths))
	var wg sync.WaitGroup
	limit := make(chan struct{}, 8)
	for i, path := range paths {
		wg.Add(1)
		limit <- struct{}{}
		go func() {
			defer wg.Done()
			defer func() { <-limit }()
			sessions[i] = Load(path)
		}()
	}
	wg.Wait()

	sort.Slice(sessions, func(i, j int) bool { return sessions[i].ModTime.After(sessions[j].ModTime) })
	return sessions, nil
}

type entry struct {
	Type        string          `json:"type"`
	Cwd         string          `json:"cwd"`
	AITitle     string          `json:"aiTitle"`
	CustomTitle string          `json:"customTitle"`
	Message     json.RawMessage `json:"message"`
}

// Load reads one transcript. Unreadable files still produce a session.
func Load(path string) Session {
	s := Session{
		ID:         strings.TrimSuffix(filepath.Base(path), ".jsonl"),
		Path:       path,
		ProjectDir: filepath.Dir(path),
	}
	if info, err := os.Stat(path); err == nil {
		s.ModTime = info.ModTime()
		s.Size = info.Size()
	}

	var aiTitle, customTitle, firstUserText string
	if f, err := os.Open(path); err == nil {
		defer f.Close()
		reader := bufio.NewReaderSize(f, 1<<20)
		for {
			line, err := reader.ReadBytes('\n')
			// transcripts are large, so only parse lines that can matter
			wantCwd := s.Cwd == "" && bytes.Contains(line, []byte(`"cwd"`))
			wantUser := firstUserText == "" && bytes.Contains(line, []byte(`"type":"user"`))
			isTitle := bytes.Contains(line, []byte(`"ai-title"`)) || bytes.Contains(line, []byte(`"custom-title"`))
			if wantCwd || wantUser || isTitle {
				var e entry
				if json.Unmarshal(line, &e) == nil {
					if s.Cwd == "" {
						s.Cwd = e.Cwd
					}
					switch {
					case e.Type == "ai-title" && e.AITitle != "":
						aiTitle = e.AITitle
					case e.Type == "custom-title" && e.CustomTitle != "":
						customTitle = e.CustomTitle
					case e.Type == "user" && firstUserText == "":
						firstUserText = userText(e.Message)
					}
				}
			}
			if err != nil {
				break
			}
		}
	}

	s.Title = firstNonEmpty(customTitle, aiTitle, summarize(firstUserText), "(no title)")
	if s.Cwd == "" {
		s.Cwd = "(unknown directory)"
	}
	s.Size += dirSize(s.dataDir()) + dirSize(s.fileHistoryDir())
	return s
}

// userText returns the first text of a user message, whose content is a string or a list of blocks.
func userText(message json.RawMessage) string {
	var m struct {
		Content json.RawMessage `json:"content"`
	}
	if json.Unmarshal(message, &m) != nil {
		return ""
	}
	var text string
	if json.Unmarshal(m.Content, &text) == nil {
		return text
	}
	var blocks []struct {
		Type string `json:"type"`
		Text string `json:"text"`
	}
	if json.Unmarshal(m.Content, &blocks) == nil {
		for _, block := range blocks {
			if block.Type == "text" {
				return block.Text
			}
		}
	}
	return ""
}

func summarize(text string) string {
	text = strings.Join(strings.Fields(text), " ")
	if runes := []rune(text); len(runes) > 80 {
		return string(runes[:77]) + "..."
	}
	return text
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}

func dirSize(dir string) int64 {
	if dir == "" {
		return 0
	}
	var total int64
	filepath.WalkDir(dir, func(_ string, d fs.DirEntry, err error) error {
		if err == nil && !d.IsDir() {
			if info, err := d.Info(); err == nil {
				total += info.Size()
			}
		}
		return nil
	})
	return total
}

type titleEntry struct {
	Type      string `json:"type"`
	Title     string `json:"customTitle"`
	SessionID string `json:"sessionId"`
}

type agentNameEntry struct {
	Type      string `json:"type"`
	Name      string `json:"agentName"`
	SessionID string `json:"sessionId"`
}

// Rename appends the two entries Claude writes for /rename; the last ones win.
func (s Session) Rename(title string) error {
	f, err := os.OpenFile(s.Path, os.O_RDWR|os.O_APPEND, 0)
	if err != nil {
		return err
	}
	defer f.Close()

	// a transcript that was cut off mid-line would swallow the first entry
	last := make([]byte, 1)
	if info, err := f.Stat(); err == nil && info.Size() > 0 {
		if _, err := f.ReadAt(last, info.Size()-1); err == nil && last[0] != '\n' {
			if _, err := f.WriteString("\n"); err != nil {
				return err
			}
		}
	}

	encoder := json.NewEncoder(f)
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(titleEntry{"custom-title", title, s.ID}); err != nil {
		return err
	}
	return encoder.Encode(agentNameEntry{"agent-name", title, s.ID})
}

// Delete removes the transcript and the data stored alongside it.
func (s Session) Delete() error {
	if err := os.Remove(s.Path); err != nil {
		return err
	}
	for _, dir := range []string{s.dataDir(), s.fileHistoryDir()} {
		if dir != "" {
			os.RemoveAll(dir)
		}
	}
	return nil
}
