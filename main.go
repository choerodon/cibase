package main

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing"
)

var (
	tags            = make([]string, 0)
	branches        = make([]string, 0)
	CiCommitRefName string
	CiCommitTime    string
	isGitlabCI      bool
	isCircleCI      bool
)

func CheckErr(err error) {
	if err != nil {
		fmt.Printf("%v", err)
		os.Exit(1)
	}
}

func Max(cur, max string) bool {
	i1, err := strconv.Atoi(cur)
	CheckErr(err)
	i2, err := strconv.Atoi(max)
	CheckErr(err)
	if i1 >= i2 {
		return true
	}
	return false
}

func GetMaxBranchVersion() string {
	maxBranchVersion := "0.0.0"
	if len(branches) == 0 {
		return maxBranchVersion
	}
	for _, b := range branches {
		match, err := regexp.MatchString(`^releases?[/-](\d+(\.\d+){1,2}).*`, b)
		CheckErr(err)
		if !match {
			continue
		}
		r, err := regexp.Compile(`^releases?[/-](\d+(\.\d+){1,2}).*`)
		CheckErr(err)
		CurBranch := r.FindStringSubmatch(b)[1]
		if Max(strings.Split(CurBranch, ".")[0], strings.Split(maxBranchVersion, ".")[0]) {
			maxBranchVersion = CurBranch
			if Max(strings.Split(CurBranch, ".")[1], strings.Split(maxBranchVersion, ".")[1]) {
				maxBranchVersion = CurBranch
			}
		}
	}
	return maxBranchVersion
}

func GetMaxTagVersion() string {
	maxTagVersion := "0.0.0"
	if len(tags) == 0 {
		return maxTagVersion
	}
	for _, t := range tags {
		match, err := regexp.MatchString(`^[Vv]?(\d+(\.\d+){1,2}).*`, t)
		CheckErr(err)
		if !match {
			continue
		}
		r, err := regexp.Compile(`^[Vv]?(\d+(\.\d+){1,2}).*`)
		CheckErr(err)
		CurTagVersion := r.FindStringSubmatch(t)[1]
		if Max(strings.Split(CurTagVersion, ".")[0], strings.Split(maxTagVersion, ".")[0]) {
			maxTagVersion = CurTagVersion
			if Max(strings.Split(CurTagVersion, ".")[1], strings.Split(maxTagVersion, ".")[1]) {
				maxTagVersion = CurTagVersion
			}
		}
	}
	return maxTagVersion
}

func GetDevelopBranchCurVersion() string {
	max := GetMaxTagVersion()
	bv := GetMaxBranchVersion()
	if Max(strings.Split(bv, ".")[0], strings.Split(max, ".")[0]) {
		max = bv
		if Max(strings.Split(bv, ".")[1], strings.Split(max, ".")[1]) {
			max = bv
		}
	}
	return max
}

func init() {
	ci := os.Getenv("CI")
	if len(ci) == 0 || ci == "" {
		panic("当前版本生成，只支持CI环境！")
	}
	isGitlabCI = func() bool {
		gitlabCI := os.Getenv("GITLAB_CI")
		if len(gitlabCI) == 0 || gitlabCI == "" {
			return false
		}
		return true
	}()
	isCircleCI = func() bool {
		circleCI := os.Getenv("CIRCLECI")
		if len(circleCI) == 0 || circleCI == "" {
			return false
		}
		return true
	}()
	if isGitlabCI {
		CiCommitTag := os.Getenv("CI_COMMIT_TAG")
		if len(CiCommitTag) != 0 || CiCommitTag != "" {
			fmt.Print(CiCommitTag)
			os.Exit(0)
		}
	} else if isCircleCI {
		CircleCITag := os.Getenv("CIRCLE_TAG")
		if len(CircleCITag) != 0 || CircleCITag != "" {
			fmt.Print(CircleCITag)
			os.Exit(0)
		}
	} else {
		panic("不支持当前CI环境！")
	}
}

func InitData() {
	path, _ := filepath.Abs(filepath.Dir(os.Args[0]))
	if isGitlabCI {
		CiCommitRefName = os.Getenv("CI_COMMIT_REF_NAME")
		path = os.Getenv("CI_PROJECT_DIR")
	} else if isCircleCI {
		CiCommitRefName = os.Getenv("CIRCLE_BRANCH")
	} else {
		panic("不支持当前CI环境！")
	}
	client, err := git.PlainOpen(path)
	CheckErr(err)
	client.Fetch(&git.FetchOptions{RemoteName: "origin"})
	refs, _ := client.References()
	refs.ForEach(
		func(t *plumbing.Reference) error {
			if t.Name().IsRemote() {
				branches = append(branches, strings.Split(t.Name().Short(), "/")[1])
			}
			if t.Name().IsBranch() || t.Name().IsRemote() {
				branches = append(branches, t.Name().Short())
			}
			if t.Name().IsTag() {
				tags = append(tags, t.Name().Short())
			}
			return nil
		},
	)
	gitLogs, err := client.Log(&git.LogOptions{Order: git.LogOrderCommitterTime})
	CheckErr(err)
	gitLog, err := gitLogs.Next()
	CheckErr(err)
	CiCommitTime = gitLog.Committer.When.Format("20060102150405")
}

func GetReleaseOrHotfixBranchVersion() string {
	match, err := regexp.MatchString(`^releases?[/-](\d+(\.\d+){1,2}).*`, CiCommitRefName)
	CheckErr(err)
	if match {
		r, err := regexp.Compile(`^releases?[/-](\d+(\.\d+){1,2}).*`)
		CheckErr(err)
		ReleaseBranchVersion := r.FindStringSubmatch(CiCommitRefName)[1]
		return fmt.Sprintf("%s-rc.%s", ReleaseBranchVersion, CiCommitTime)
	}
	match, err = regexp.MatchString(`^hotfix(es)?[/-](\d+(\.\d+){1,2}).*`, CiCommitRefName)
	CheckErr(err)
	if match {
		r, err := regexp.Compile(`^hotfix(es)?[/-](\d+(\.\d+){1,2}).*`)
		CheckErr(err)
		ReleaseBranchVersion := r.FindStringSubmatch(CiCommitRefName)[2]
		return fmt.Sprintf("%s-beta.%s", ReleaseBranchVersion, CiCommitTime)
	}

	vss := GetDevelopBranchCurVersion()
	vs := strings.Split(vss, ".")
	v, err := strconv.Atoi(vs[len(vs)-1])
	CheckErr(err)
	return fmt.Sprintf("%s.%d-%s.%s", strings.Join(vs[:len(vs)-1], "."), v+1, CiCommitRefName, CiCommitTime)
}

func GetDevelopBranchVersion() string {
	vs := strings.Split(GetDevelopBranchCurVersion(), ".")
	v, err := strconv.Atoi(vs[1])
	CheckErr(err)
	return fmt.Sprintf("%s.%d.0-dev.%s", vs[0], v+1, CiCommitTime)
}

func GetVersion() string {
	match, err := regexp.MatchString(`^dev(elop)?(ment)?$`, CiCommitRefName)
	CheckErr(err)
	if match {
		return GetDevelopBranchVersion()
	}
	return GetReleaseOrHotfixBranchVersion()
}

func main() {
	InitData()
	fmt.Print(GetVersion())
}
