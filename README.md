# dirdiff
Make diff between directories, apply by calling the output with sh.

Example usage

```
dirdiff.sh old new | bzip2 | ssh remote "bzcat | sh -sx"
```
