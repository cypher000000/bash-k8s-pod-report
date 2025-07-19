# Kubernetes Pods State Report

This Bash script fetches the current Kubernetes Pods status from a remote file, extracts lists of **running** and **failed** services, generates a report, archives the outputs, and optionally cleans up created files, saves the archive.


---
## Assignment: Kubernetes Pods State Report Script

Write a Bash script that:

### 1. Downloads the input state file `list.out` from the URL

### 2. Generates two filtered files from the downloaded `list.out`:

- **`<SERVER>_<DATE>_failed.out`**  
  Contains *only the service (pod) names* (column **NAME**) whose **STATUS** is `Error` **or** `CrashLoopBackOff`.

- **`<SERVER>_<DATE>_running.out`**  
  Contains *only the service (pod) names* whose **STATUS** is `Running`.

**Important:** Output files must contain just the names — no extra columns from the original file.

#### Name cleanup rule  
Strip Kubernetes ReplicaSet/Pod hash suffixes of the form `-name-xxxxxxxxxx-xxxxxx`

Example: `demomed-analysis-service-6f955bff79-cqjv9` → `demomed-analysis-service`

### 3. Generates a human-readable report file  
Create **`<SERVER>_<DATE>_report.out`** (world readable permissions) with the lines:

- `Working services: N` — where **N** = number of services in `<SERVER>_<DATE>_running.out`.
- `Broken services: M` — where **M** = number of services in `<SERVER>_<DATE>_failed.out`.
- `Username: USER` — the user who ran the script.
- `Date: DD/MM/YY` — current date at runtime.

### 4. Archives the results  
Package **all generated output files** (`failed`, `running`, `report`, and the downloaded `list.out`) into an archive named `<SERVER>_<DATE>.tar.gz` and place it in an `archives/` directory.

### 5. Cleanup  
Remove all intermediate working files (downloaded input and generated `.out` files) **except** for the archive(s) stored under `archives/`.

### 6. Integrity check  
Validate the archive for corruption and print a success or error message.  

---
## Features
- Configurable `SERVER` name and date stamp
- Download retry logic (by `wget` with back-off)
- Filters Running vs Error/CrashLoopBackOff services (by `awk/sed`)
- Archive with integrity checks (`gzip + tar + content test`)
- Detailed logging in a file
- Clear all created files, save only the archive

## Output files
By default, all files are placed in `/tmp/state/`:

| File | Description |
|:---------|:---------|
| (SERVER)_(DATE)_failed.out     | Names of pods in Error or CrashLoopBackOff   |
| (SERVER)_(DATE)_running.out    | Names of pods currently in Running state  |
| (SERVER)_(DATE)_report.out    | Report summary (state numbers, user, date)  |
| archives/(SERVER)_(DATE).tar.gz    | Gzipped archive of all files above  |

By default, script writes logs to `/tmp/log/script_log`

## Preconditions
Requires bash, wget, awk, sed, tar, gzip.

Tested on Ubuntu 22.04

---
## Usage
```bash
git clone https://github.com/cypher000000/bash-k8s-pod-report.git
cd bash-k8s-pod-report && chmod +x k8s-pod-report.sh
./k8s-pod-report.sh myserver
```

Or integrate into cron:
```bash
0 2 * * * /path/to/k8s-pod-report.sh myserver
```

## Customization

If `SERVER_NAME` is omitted, the script defaults to `def_server`.

Change `LOG_PATH` or `FOLDER_PATH` or `ARCHIVE_PATH` from the default to your value.

Modify `INPUT_FILE_URL` to your Kubernetes source.

Tweak `MAX_RETRIES` and `DELAY` for your network conditions.
