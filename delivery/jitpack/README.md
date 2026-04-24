# Manual JitPack artifacts (business requirement)

JitPack runs `delivery/jitpack/install-to-m2.sh`, which **`mvn install:install-file`s** the files in **this folder** into `~/.m2/repository`. JitPack then serves them like any other Maven install.

## What to commit here (exact names)

| File | Required | Notes |
|------|------------|--------|
| `maven-coordinates.properties` | yes | `groupId`, `artifactId`; `version` is for **local** installs only (JitPack uses **git** for version). |
| `{artifactId}.aar` | yes | Example: `mapsglmaps.aar` — copy/rename from Gradle output (see below). |
| `{artifactId}-sources.jar` | yes | Example: `mapsglmaps-sources.jar` — KDoc/sources for IDE hovers. |
| `{artifactId}-javadoc.jar` | no | If present, it is installed with classifier `javadoc`. |

**Naming rule:** the stem must match `artifactId` in `maven-coordinates.properties` (e.g. `mapsglmaps` → `mapsglmaps.aar`, `mapsglmaps-sources.jar`).

## Where Gradle writes the binaries (to copy from)

From repo root, after a release build:

1. **AAR** (typical path):  
   `mapsglmaps/build/outputs/aar/mapsglmaps-release.aar`  
   → copy here as **`mapsglmaps.aar`** (name must match `artifactId` + `.aar`).

2. **Sources JAR:**  
   `.\gradlew :mapsglmaps:sourceReleaseJar`  
   then copy from e.g. `mapsglmaps/build/libs/` the `*-sources.jar` → rename to **`mapsglmaps-sources.jar`**.

3. **Javadoc JAR (optional):**  
   If you build `dokkaJavadocJar`, copy the `*-javadoc.jar` → **`mapsglmaps-javadoc.jar`**.

## Release checklist

1. **`groupId`** must match the GitHub repo JitPack builds. For [jasonsuto/test240815](https://github.com/jasonsuto/test240815/) use **`com.github.jasonsuto.test240815`**. If this is wrong, JitPack reports **“No build artifacts found”** even when `mvn install` succeeds.
2. **`artifactId`** is the Gradle module name (`mapsglmaps`). Consumers depend with:  
   `implementation 'com.github.jasonsuto.test240815:mapsglmaps:Tag'`  
   (see [JitPack multi-module](https://docs.jitpack.io/building/).)
3. **`version=`** in the properties file is used for **local** `install-to-m2.sh` runs. **On JitPack**, `JITPACK=true` causes the script to **ignore** that value and use **`git describe`** so the Maven version matches the **tag or commit** JitPack is building (otherwise artifacts land under the wrong folder and JitPack cannot find them).
4. Replace the binary files under `delivery/jitpack/` with the new build outputs (exact filenames above).
5. Commit, tag, push — JitPack runs only the install script + Maven.

## Large binaries

If policy allows, consider **Git LFS** for `.aar` / `.jar` files so the main repo stays lean.

## Shell script line endings (Windows)

`install-to-m2.sh` **must be committed with Unix LF** only. CRLF causes JitPack errors like `set: pipefail: invalid option name` (the `\r` corrupts the `set` line). Root **`.gitattributes`** forces `eol=lf` for `delivery/jitpack/*.sh`. After changing the script, normalize once:

```bash
git add --renormalize delivery/jitpack/install-to-m2.sh
```

Or re-save the file in the editor as **LF** / disable CRLF for `*.sh`.

## Local test (Linux/macOS or Git Bash)

```bash
bash delivery/jitpack/install-to-m2.sh
ls ~/.m2/repository/com/github/jasonsuto/test240815/mapsglmaps/
```
