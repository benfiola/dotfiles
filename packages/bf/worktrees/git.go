package worktrees

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// git runs git in dir and returns its trimmed stdout.
func git(dir string, args ...string) (string, error) {
	cmd := exec.Command("git", append([]string{"-C", dir}, args...)...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, strings.TrimSpace(stderr.String()))
	}
	return strings.TrimSpace(string(out)), nil
}

// gitStream runs git in dir with its output on stderr, which leaves stdout free for the result path.
func gitStream(dir string, args ...string) error {
	fmt.Fprintf(os.Stderr, "> git -C %s %s\n", dir, strings.Join(args, " "))
	cmd := exec.Command("git", append([]string{"-C", dir}, args...)...)
	cmd.Stdout = os.Stderr
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func exitCode(err error) int {
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		return exitErr.ExitCode()
	}
	return -1
}

func refExists(repo, ref string) bool {
	_, err := git(repo, "show-ref", "--verify", "--quiet", ref)
	return err == nil
}

func localBranchExists(repo, branch string) bool {
	return refExists(repo, "refs/heads/"+branch)
}

func remoteBranchExists(repo, branch string) bool {
	return refExists(repo, "refs/remotes/origin/"+branch)
}

func defaultBase(repo string) (string, error) {
	ref, err := git(repo, "symbolic-ref", "refs/remotes/origin/HEAD")
	if err != nil {
		return "", errors.New("could not determine the default branch of origin")
	}
	return strings.TrimPrefix(ref, "refs/remotes/"), nil
}

// resolveBase turns a branch or ref into a commit. Given a branch name that only exists on
// origin, `worktree add` checks out that branch instead of branching from it.
func resolveBase(repo, base string) (string, error) {
	for _, candidate := range []string{base, "origin/" + base} {
		if commit, err := git(repo, "rev-parse", "--verify", "--quiet", candidate+"^{commit}"); err == nil {
			return commit, nil
		}
	}
	return "", fmt.Errorf("unknown branch or ref: %s", base)
}
