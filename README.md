### 包含的工具包
- 添加以下命令行工具

命令行 | 备注
---|---
curl | 基础命令
wget | 基础命令
git | 用于获取仓库信息
helm | 用户打包Chart包
maven | 用于测试及打包Java程序
docker | 用于镜像构建阶段
mysql-client | 用于数据库初始化脚本测试
xmlstarlet | 用户HAP框架配置文件修改、POM文件修改
yq | 用于yaml文件解析
jq | 用于json文件解析

### Go实现生成版本号

#### 版本号规则

- 主版本号.次版本号.修订号-其他信息
- 详细规则请查阅：[Semver](https://semver.org/lang/zh-CN/)

#### develop分支

- 注意：匹配规则`^dev(elop)?(ment)?$`

1. 查找当前最大的tag
1. 查找当前最大的release分支本版号
1. 将最大的tag与最大的release分支本版号进行比较，取最大
1. 再将最大的版本，次版本号+1,修订号置0，即为当前develop分支版本号

> e.g. 当前最大tag为1.2.3，当前最大release分支本版号release-1.3.0，那么得到的版本号为：1.4.0-dev.最后一次提交的时间戳

#### release分支

- 注意：匹配规则`^releases?[/-](\d+(\.\d+){1,2}).*`

1. 取分支名中携带的版本号

> e.g. 当前release分支名为release-1.1.0，那么得到的版本号为：1.1.0-rc.最后一次提交的时间戳

#### hotfix分支

- 注意：匹配规则`^hotfix(es)?[/-](\d+(\.\d+){1,2}).*`

1. 取分支名中携带的版本号

> e.g. 当前hotfix分支名为hotfix-1.2.3，那么得到的版本号为：1.2.3-beta.最后一次提交的时间戳

#### 其他分支

1. 查找当前最大的tag
1. 查找当前最大的release分支本版号
1. 将最大的tag与最大的release分支本版号进行比较取最大
1. 在修订号+1即为当前分支版本号

> e.g. 分支名为feature-12480 当前最大tag为1.2.3，当前最大release分支本版号release-1.3.0，那么得到的版本号为：1.3.1-feature-12480.最后一次提交的时间戳

### 镜像构建

> 注意：构建时Docker服务端版本必须为17.5.0-ce版本及以上

```
docker build -t baseci .
```