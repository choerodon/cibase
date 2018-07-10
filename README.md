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

#### 所有分支

生成tag格式为：年.月.日-时分秒-分支名

> e.g. 分支名为feature-12480，提交时间2018年07月10日19:25:11， 那么得到的版本号为：2018.7.10-192511-feature-12480

### 镜像构建

> 注意：构建时Docker服务端版本必须为17.5.0-ce版本及以上

```
docker build -t baseci .
```