# Manual JitPack artifacts (business requirement)

JitPack runs `delivery/jitpack/install-to-m2.sh`, which **`mvn install:install-file`s** the files in **this folder** into `~/.m2/repository`. JitPack then serves them like any other Maven install.

## What to commit here (exact names)

| File | Required | Notes |
|------|------------|--------|
| `maven-coordinates.properties` | yes | `groupId`, `artifactId`, `version` (must match the Git **tag** JitPack builds, if consumers use tag as version). |
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

1. Bump **`version=`** in `maven-coordinates.properties` to the **same string** as the Git tag you will push (e.g. `v1.6.0`).
2. Confirm **`groupId` / `artifactId`** match the dependency line JitPack shows for your repo (multi-module is often `com.github.ORG.REPO` + artifact `mapsglmaps`).
3. Replace the three binary files with the new build outputs (exact filenames above).
4. Commit, tag, push — JitPack build should only run the shell script + Maven (no Gradle publish required for this path).

## Large binaries

If policy allows, consider **Git LFS** for `.aar` / `.jar` files so the main repo stays lean.

## Local test (Linux/macOS or Git Bash)

```bash
bash delivery/jitpack/install-to-m2.sh
ls ~/.m2/repository/$(echo com.github.jasonsuto | tr . /)/mapsglmaps/
```

(Adjust the path to match your `groupId`.)
