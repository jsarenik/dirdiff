# dirdiff

[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/jsarenik/dirdiff)

Make diff between directories, apply by calling the output with sh.

Example usage

```
dirdiff.sh old new | bzip2 | ssh remote "bzcat | sh -sx"
```
