// Package worktrees manages git worktrees for the repositories under a source directory.
//
// Repositories live at <source>/<host>/<org>/<repo> and their worktrees at
// <source>/worktrees/<host>/<org>/<repo>/<branch>.
package worktrees

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
)

// Worktree is a linked worktree of a repository.
type Worktree struct {
	Repo        string
	Path        string
	Branch      string
	Description string
}

// detached is the branch shown for a worktree that has no branch checked out.
const detached = "detached"

// maxRepoDepth is how many directories below the source directory a repository may be.
const maxRepoDepth = 3

// sourceDir is the source directory with symlinks resolved, which is how git reports paths.
func (o Options) sourceDir() string {
	if resolved, err := filepath.EvalSymlinks(o.SourceDir); err == nil {
		return resolved
	}
	return o.SourceDir
}

func (o Options) worktreesDir() string {
	return filepath.Join(o.sourceDir(), "worktrees")
}

// findRepos returns every repository beneath the source directory, skipping worktrees.
func (o Options) findRepos() []string {
	var repos []string
	var walk func(dir string, depth int)
	walk = func(dir string, depth int) {
		entries, err := os.ReadDir(dir)
		if err != nil {
			return
		}
		for _, entry := range entries {
			if entry.Name() == ".git" {
				if entry.IsDir() {
					repos = append(repos, dir)
				}
				return
			}
		}
		if depth >= maxRepoDepth {
			return
		}
		for _, entry := range entries {
			child := filepath.Join(dir, entry.Name())
			if entry.IsDir() && child != o.worktreesDir() {
				walk(child, depth+1)
			}
		}
	}
	walk(o.sourceDir(), 0)
	sort.Strings(repos)
	return repos
}

// currentRepo returns the repository containing the working directory, or "" outside one.
func currentRepo() string {
	common, err := git(".", "rev-parse", "--path-format=absolute", "--git-common-dir")
	if err != nil {
		return ""
	}
	return filepath.Dir(common)
}

// ProjectName returns the repository name for a directory inside a worktree, and the
// directory's own name elsewhere.
func (o Options) ProjectName(cwd string) string {
	if strings.HasPrefix(cwd, o.worktreesDir()+string(filepath.Separator)) {
		if repo := currentRepo(); repo != "" {
			return filepath.Base(repo)
		}
	}
	return filepath.Base(cwd)
}

func branchDescriptions(repo string) map[string]string {
	descriptions := map[string]string{}
	// git exits 1 when no branch has a description
	out, err := git(repo, "config", "--get-regexp", `^branch\..*\.description$`)
	if err != nil {
		return descriptions
	}
	for _, line := range strings.Split(out, "\n") {
		key, value, _ := strings.Cut(line, " ")
		if strings.HasPrefix(key, "branch.") && strings.HasSuffix(key, ".description") {
			branch := strings.TrimSuffix(strings.TrimPrefix(key, "branch."), ".description")
			descriptions[branch] = value
		}
	}
	return descriptions
}

func branchSubjects(repo string) map[string]string {
	subjects := map[string]string{}
	out, err := git(repo, "for-each-ref", "--format=%(refname)\t%(subject)", "refs/heads")
	if err != nil {
		return subjects
	}
	for _, line := range strings.Split(out, "\n") {
		ref, subject, _ := strings.Cut(line, "\t")
		subjects[strings.TrimPrefix(ref, "refs/heads/")] = subject
	}
	return subjects
}

func setDescription(repo, branch, description string) error {
	key := "branch." + branch + ".description"
	if description != "" {
		_, err := git(repo, "config", key, description)
		return err
	}
	// an empty description is removed so the last commit subject shows again; git exits 5 if unset
	if _, err := git(repo, "config", "--unset", key); err != nil && exitCode(err) != 5 {
		return err
	}
	return nil
}

func listWorktrees(repo string) ([]Worktree, error) {
	out, err := git(repo, "worktree", "list", "--porcelain")
	if err != nil {
		return nil, err
	}
	descriptions := branchDescriptions(repo)
	subjects := branchSubjects(repo)

	var worktrees []Worktree
	// the first block is the main checkout
	for _, block := range strings.Split(out, "\n\n")[1:] {
		fields := map[string]string{}
		for _, line := range strings.Split(block, "\n") {
			key, value, _ := strings.Cut(line, " ")
			fields[key] = value
		}
		w := Worktree{Repo: repo, Path: fields["worktree"], Branch: detached}
		if ref, ok := fields["branch"]; ok {
			w.Branch = strings.TrimPrefix(ref, "refs/heads/")
		}
		if description, ok := descriptions[w.Branch]; ok {
			w.Description = description
		} else if subject, ok := subjects[w.Branch]; ok {
			w.Description = subject
		} else {
			w.Description, _ = git(w.Path, "log", "-1", "--format=%s")
		}
		worktrees = append(worktrees, w)
	}
	return worktrees, nil
}

// listAll returns the worktrees of every repository.
func (o Options) listAll() []Worktree {
	repos := o.findRepos()
	results := make([][]Worktree, len(repos))
	var wg sync.WaitGroup
	for i, repo := range repos {
		wg.Add(1)
		go func() {
			defer wg.Done()
			results[i], _ = listWorktrees(repo)
		}()
	}
	wg.Wait()

	var all []Worktree
	for _, worktrees := range results {
		all = append(all, worktrees...)
	}
	return all
}

func (o Options) prune() {
	for _, repo := range o.findRepos() {
		git(repo, "worktree", "prune")
	}
}

// deleteWarning describes work that would be lost by deleting the worktree.
func deleteWarning(w Worktree) string {
	dirty, err := git(w.Path, "status", "--porcelain")
	if err != nil {
		return "could not check for uncommitted or unpushed work"
	}
	unpushed, err := git(w.Path, "rev-list", "--count", "HEAD", "--not", "--remotes")
	if err != nil {
		return "could not check for uncommitted or unpushed work"
	}

	var warnings []string
	if dirty != "" {
		warnings = append(warnings, fmt.Sprintf("%d uncommitted files", len(strings.Split(dirty, "\n"))))
	}
	if unpushed != "0" {
		warnings = append(warnings, unpushed+" unpushed commits")
	}
	return strings.Join(warnings, ", ")
}
