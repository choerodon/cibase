package main

import (
	"gopkg.in/src-d/go-git.v4"
	"fmt"
	"os"
	"path/filepath"
)

var (
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
	gitLogs, err := client.Log(&git.LogOptions{Order: git.LogOrderCommitterTime})
	CheckErr(err)
	gitLog, err := gitLogs.Next()
	CheckErr(err)
	ciCommitTime = gitLog.Committer.When.Format("2006.1.2-150405")
}

func GetVersion() string {
	return fmt.Sprintf("%s-%s", ciCommitTime, ciCommitRefName)
}

func main() {
	InitData()
	fmt.Print(GetVersion())
}
