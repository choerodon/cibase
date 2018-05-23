package main

import (
	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing"
	"fmt"
	"regexp"
	"strings"
	"strconv"
	"os"
	"path/filepath"
)

var (
	tags            = make([]string, 0)
	branches        = make([]string, 0)
	ciCommitRefName string
	ciCommitTime    string
	isGitlabCI      bool
	isCircleCI      bool
)

func CheckErr(err error) {
	if err != nil {
		fmt.Printf("%v", err)
		os.Exit(1)
	}
}

func init() {
	ci := os.Getenv("CI")
	if len(ci) == 0 || ci == "" {
		panic("GetVersion can only be used in a CI environment.")
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
		gitlabCITag := os.Getenv("CI_COMMIT_TAG")
		if len(gitlabCITag) != 0 || gitlabCITag != "" {
			fmt.Print(gitlabCITag)
			os.Exit(0)
		}
	} else if isCircleCI {
		circleCITag := os.Getenv("CIRCLE_TAG")
		if len(circleCITag) != 0 || circleCITag != "" {
			fmt.Print(circleCITag)
			os.Exit(0)
		}
	} else {
		panic("Not support the current CI environment!")
	}
}

func InitData() {
	path, _ := filepath.Abs(filepath.Dir(os.Args[0]))
	if isGitlabCI {
		ciCommitRefName = os.Getenv("CI_COMMIT_REF_NAME")
		path = os.Getenv("CI_PROJECT_DIR")
	} else if isCircleCI {
		ciCommitRefName = os.Getenv("CIRCLE_BRANCH")
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
	ciCommitTime = gitLog.Committer.When.Format("20060102150405")
}

func GetMaxSubVersion(cur, max string) int {
	iCur, err := strconv.Atoi(cur)
	CheckErr(err)
	iMax, err := strconv.Atoi(max)
	CheckErr(err)
	if iCur > iMax {
		return 1
	} else if iCur == iMax {
		return 0
	}
	return -1
}

func GetMaxVersion(cur, max string) string {
	flag := GetMaxSubVersion(strings.Split(cur, ".")[0], strings.Split(max, ".")[0])
	if flag == 1 {
		return cur
	} else if flag == -1 {
		return max
	} else {
		flag = GetMaxSubVersion(strings.Split(cur, ".")[1], strings.Split(max, ".")[1])
		if flag == -1 {
			return max
		} else {
			return cur
		}
	}
}

func GetMaxBranchVersion() string {
	maxBranchVersion := "0.0.0"
	if len(branches) == 0 {
		return maxBranchVersion
	}
	for _, branch := range branches {
		match, err := regexp.MatchString(`^releases?[/-](\d+(\.\d+){1,2}).*`, branch)
		CheckErr(err)
		if !match {
			continue
		}
		r, err := regexp.Compile(`^releases?[/-](\d+(\.\d+){1,2}).*`)
		CheckErr(err)
		curBranchVersion := r.FindStringSubmatch(branch)[1]
		maxBranchVersion = GetMaxVersion(curBranchVersion, maxBranchVersion)
	}
	return maxBranchVersion
}

func GetMaxTagVersion() string {
	maxTagVersion := "0.0.0"
	if len(tags) == 0 {
		return maxTagVersion
	}
	for _, tag := range tags {
		match, err := regexp.MatchString(`^[Vv]?(\d+(\.\d+){1,2}).*`, tag)
		CheckErr(err)
		if !match {
			continue
		}
		r, err := regexp.Compile(`^[Vv]?(\d+(\.\d+){1,2}).*`)
		CheckErr(err)
		curTagVersion := r.FindStringSubmatch(tag)[1]
		maxTagVersion = GetMaxVersion(curTagVersion, maxTagVersion)
	}
	return maxTagVersion
}

func GetCurMaxVersion() string {
	return GetMaxVersion(GetMaxBranchVersion(), GetMaxTagVersion())
}

func GetVersion() string {
	match, err := regexp.MatchString(`^dev(elop)?(ment)?$`, ciCommitRefName)
	CheckErr(err)
	if match {
		vs := strings.Split(GetCurMaxVersion(), ".")
		v, err := strconv.Atoi(vs[1])
		CheckErr(err)
		return fmt.Sprintf("%s.%d.0-dev.%s", vs[0], v+1, ciCommitTime)
	}
	match, err = regexp.MatchString(`^releases?[/-](\d+(\.\d+){1,2}).*`, ciCommitRefName)
	CheckErr(err)
	if match {
		r, err := regexp.Compile(`^releases?[/-](\d+(\.\d+){1,2}).*`)
		CheckErr(err)
		releaseBranchVersion := r.FindStringSubmatch(ciCommitRefName)[1]
		return fmt.Sprintf("%s-rc.%s", releaseBranchVersion, ciCommitTime)
	}
	match, err = regexp.MatchString(`^hotfix(es)?[/-](\d+(\.\d+){1,2}).*`, ciCommitRefName)
	CheckErr(err)
	if match {
		r, err := regexp.Compile(`^hotfix(es)?[/-](\d+(\.\d+){1,2}).*`)
		CheckErr(err)
		hotfixBranchVersion := r.FindStringSubmatch(ciCommitRefName)[2]
		return fmt.Sprintf("%s-beta.%s", hotfixBranchVersion, ciCommitTime)
	}
	vss := GetCurMaxVersion()
	vs := strings.Split(vss, ".")
	v, err := strconv.Atoi(vs[len(vs)-1])
	CheckErr(err)
	return fmt.Sprintf("%s.%d-%s.%s", strings.Join(vs[:len(vs)-1], "."), v+1, ciCommitRefName, ciCommitTime)
}

func main() {
	InitData()
	fmt.Print(GetVersion())
}