package worktrees

import (
	"errors"
	"fmt"
	"os/user"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/benfiola/dotfiles/packages/bf/tui"
)

// Options configures the worktrees command.
type Options struct {
	// SourceDir holds the repositories; worktrees are created in its "worktrees" subdirectory.
	SourceDir string
	// Issue lets branches be named after an issue tracker item. Nil offers only free-form names.
	Issue *IssueOptions
}

// IssueOptions describes how branches are named after an issue tracker item.
type IssueOptions struct {
	// Label names the tracker item in prompts, such as "radar".
	Label string
	// Parse extracts the issue id and, if the input has one, its title from user input.
	Parse func(input string) (id, title string, err error)
	// Branch names the branch for an issue in a repository.
	Branch func(repo, id string) string
}

var (
	nonSlug     = regexp.MustCompile("[^a-z0-9]+")
	hasSlugRune = regexp.MustCompile("[a-z0-9]")
)

// branchSource is what a new branch is named after.
type branchSource struct {
	issue string
	name  string
}

func (o Options) branchName(repo string, source branchSource) (string, error) {
	if source.issue != "" {
		id, _, err := o.Issue.Parse(source.issue)
		if err != nil {
			return "", err
		}
		return o.Issue.Branch(filepath.Base(repo), id), nil
	}
	current, err := user.Current()
	if err != nil {
		return "", err
	}
	slug := strings.Trim(nonSlug.ReplaceAllString(strings.ToLower(source.name), "-"), "-")
	return fmt.Sprintf("eng/%s/%s", current.Username, slug), nil
}

// chooseBranch avoids silently reusing a branch that only exists on origin, which may be someone else's.
func (o Options) chooseBranch(repo string, source branchSource) (string, error) {
	branch, err := o.branchName(repo, source)
	if err != nil {
		return "", err
	}
	if localBranchExists(repo, branch) || !remoteBranchExists(repo, branch) {
		return branch, nil
	}

	current, err := user.Current()
	if err != nil {
		return "", err
	}
	suffixed := branch + "-" + current.Username
	switch {
	case localBranchExists(repo, suffixed):
		return suffixed, nil
	case remoteBranchExists(repo, suffixed):
		return "", fmt.Errorf("branch already exists on origin: %s", suffixed)
	}
	choice, err := tui.Choose("origin/"+branch+" already exists", []string{
		"check out the existing origin/" + branch,
		"create " + suffixed,
	})
	if err != nil {
		return "", err
	}
	if choice == 0 {
		return branch, nil
	}
	return suffixed, nil
}

type newWorktree struct {
	repo        string
	source      branchSource
	description string
	base        string
}

// prompt asks what to create, returning tui.ErrCancelled if the user backs out.
func (o Options) prompt() (newWorktree, error) {
	var w newWorktree
	current := currentRepo()

	repos := o.findRepos()
	if len(repos) == 0 {
		return w, fmt.Errorf("no repositories found in %s", o.SourceDir)
	}
	// the current repository is the likeliest choice, so list it first
	sort.SliceStable(repos, func(a, b int) bool { return repos[a] == current && repos[b] != current })
	labels := make([]string, len(repos))
	for i, repo := range repos {
		labels[i], _ = filepath.Rel(o.sourceDir(), repo)
	}
	choice, err := tui.Choose("repo", labels)
	if err != nil {
		return w, err
	}
	w.repo = repos[choice]

	var defaultDescription string
	useIssue := false
	if o.Issue != nil {
		kind, err := tui.Choose("branch for", []string{o.Issue.Label, "name"})
		if err != nil {
			return w, err
		}
		useIssue = kind == 0
	}
	if useIssue {
		input, err := tui.Ask(o.Issue.Label, "", func(text string) error {
			_, _, err := o.Issue.Parse(text)
			return err
		})
		if err != nil {
			return w, err
		}
		_, defaultDescription, _ = o.Issue.Parse(input)
		w.source.issue = input
	} else {
		name, err := tui.Ask("name", "", func(text string) error {
			if !hasSlugRune.MatchString(strings.ToLower(text)) {
				return errors.New("a name with letters or digits is required")
			}
			return nil
		})
		if err != nil {
			return w, err
		}
		w.source.name = name
	}

	if w.description, err = tui.Ask("description (optional)", defaultDescription, nil); err != nil {
		return w, err
	}

	base, err := defaultBase(w.repo)
	if err != nil {
		return w, err
	}
	baseLabels := []string{base + " (default)"}
	bases := []string{base}
	if w.repo == current {
		head, err := git(".", "rev-parse", "--short", "HEAD")
		if err != nil {
			return w, err
		}
		baseLabels = append(baseLabels, fmt.Sprintf("current HEAD (%s)", head))
		bases = append(bases, head)
	}
	baseLabels = append(baseLabels, "other")
	choice, err = tui.Choose("branch from", baseLabels)
	if err != nil {
		return w, err
	}
	if choice < len(bases) {
		w.base = bases[choice]
	} else if w.base, err = tui.Ask("branch or ref", "", nil); err != nil {
		return w, err
	}
	return w, nil
}

// create adds the worktree and returns its path.
func (o Options) create(w newWorktree) (string, error) {
	if err := gitStream(w.repo, "fetch", "origin"); err != nil {
		return "", err
	}
	branch, err := o.chooseBranch(w.repo, w.source)
	if err != nil {
		return "", err
	}
	rel, err := filepath.Rel(o.sourceDir(), w.repo)
	if err != nil {
		return "", err
	}
	path := filepath.Join(o.worktreesDir(), rel, strings.ReplaceAll(branch, "/", "-"))

	var args []string
	switch {
	case localBranchExists(w.repo, branch):
		args = []string{path, branch}
	case remoteBranchExists(w.repo, branch):
		args = []string{"-b", branch, path, "origin/" + branch}
	default:
		base, err := resolveBase(w.repo, w.base)
		if err != nil {
			return "", err
		}
		args = []string{"--no-track", "-b", branch, path, base}
	}
	if err := gitStream(w.repo, append([]string{"worktree", "add"}, args...)...); err != nil {
		return "", err
	}
	if w.description != "" {
		if err := setDescription(w.repo, branch, w.description); err != nil {
			return "", err
		}
	}
	return path, nil
}
