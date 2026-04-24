# Manual JitPack artifacts (business requirement)

**On JitPack**, the root `jitpack.yml` runs **`delivery/jitpack/jitpack-gradle-publish.sh`**, which invokes the repo-root **`gradlew`** against **`jitpack-upload/`** (`publishToMavenLocal`). The script resolves the Git root first so Android detection does not break `./gradlew` with “No such file or directory”. The standalone project `jitpack-upload/` applies `maven-publish` and publishes the files in **this folder** to `~/.m2/repository` with the correct coordinates. Plain `mvn install:install-file` is not sufficient (“No build artifacts found”).

For **local** installs without Gradle, you can still run `bash delivery/jitpack/install-to-m2.sh` (same coordinates and `~/.m2` layout).

## What to commit here (exact names)

| File | Required | Notes |
|------|------------|--------|
| `jitpack-gradle-publish.sh` | yes | Used by root `jitpack.yml`; must stay **Unix LF** (see root `.gitattributes`). |
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

1. **`groupId`** in the properties file uses the **multi-module** form `com.github.<User>.<Repo>` (e.g. `com.github.jasonsuto.test240815` for [jasonsuto/test240815](https://github.com/jasonsuto/test240815/)). The install script **also** publishes the [default JitPack GAV](https://docs.jitpack.io/building/) `com.github.<User>:<Repo>:version` so JitPack’s artifact scanner finds the build.
2. **`artifactId`** is the Gradle module name (`mapsglmaps`) — your committed files stay named `mapsglmaps.aar` / `mapsglmaps-sources.jar`.
3. **Consumers** should use the usual JitPack line (repo name = artifact):  
   `implementation 'com.github.jasonsuto:test240815:Tag'`  
   Optional multi-module style (still installed):  
   `implementation 'com.github.jasonsuto.test240815:mapsglmaps:Tag'`
4. **`version=`** in the properties file is used for **local** `install-to-m2.sh` runs. **On JitPack**, `JITPACK=true` causes the script to **ignore** that value and use **`git describe`** so the Maven version matches the **tag or commit** JitPack is building (otherwise artifacts land under the wrong folder and JitPack cannot find them).
5. Replace the binary files under `delivery/jitpack/` with the new build outputs (exact filenames above).
6. Commit, tag, push — JitPack runs **`jitpack-upload`** (`publishToMavenLocal`), not the shell script.

## Large binaries

If policy allows, consider **Git LFS** for `.aar` / `.jar` files so the main repo stays lean.

## Shell script line endings (Windows)

`install-to-m2.sh` **must be committed with Unix LF** only. CRLF causes JitPack errors like `set: pipefail: invalid option name` (the `\r` corrupts the `set` line). Root **`.gitattributes`** forces `eol=lf` for `delivery/jitpack/*.sh`. After changing the script, normalize once:

```bash
git add --renormalize delivery/jitpack/install-to-m2.sh
```

Or re-save the file in the editor as **LF** / disable CRLF for `*.sh`.

## Local test

**Same path as JitPack** (from repo root; uses `version` in `maven-coordinates.properties` unless you set `JITPACK=true` to mimic JitPack’s `git describe` version):

```bash
bash delivery/jitpack/jitpack-gradle-publish.sh
# or from repo root only: ./gradlew -p jitpack-upload publishToMavenLocal
```

**Maven-only** (shell script; Linux/macOS or Git Bash):

```bash
bash delivery/jitpack/install-to-m2.sh
ls ~/.m2/repository/com/github/jasonsuto/test240815/mapsglmaps/
```
