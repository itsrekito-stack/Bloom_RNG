use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use std::{
    collections::{BTreeSet, HashMap},
    env,
    fs,
    path::{Component, Path, PathBuf},
    process::{Child, Command, Stdio},
    sync::Mutex,
    time::{SystemTime, UNIX_EPOCH},
};
use tauri::{AppHandle, Manager, State, WebviewUrl, WebviewWindowBuilder};

const MODEL_PATH: &str = "src/StarterGui/BloomUI.model.json";

#[derive(Default)]
struct AppState {
    project_root: Mutex<Option<PathBuf>>,
    rojo_child: Mutex<Option<Child>>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct ProjectStatus {
    root: String,
    branch: String,
    head: String,
    subject: String,
    dirty: bool,
    changes: Vec<String>,
    model_exists: bool,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct SyncResult {
    changed: bool,
    head: String,
    subject: String,
    dirty: bool,
    stashed: bool,
    restored: bool,
    model_merged: bool,
    recovery_backup: String,
    backup_version: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct BackupEntry {
    version: String,
    snapshot_sha: String,
    source_head: String,
    created_at: u64,
    title: String,
    summary: String,
    changes: Vec<String>,
    commits: Vec<String>,
    automatic: bool,
}

#[derive(Default, Serialize, Deserialize)]
struct BackupStore {
    backups: Vec<BackupEntry>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct RestoreResult {
    restored_version: String,
    safety_version: String,
    status: ProjectStatus,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct TaskEntry {
    id: String,
    created_at: u64,
    kind: String,
    title: String,
    summary: String,
    head_before: String,
    head_after: String,
    changed_files: Vec<String>,
    backup_version: String,
    result: String,
}

#[derive(Default, Serialize, Deserialize)]
struct TaskStore {
    tasks: Vec<TaskEntry>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct GitChange {
    status: String,
    path: String,
    staged: bool,
    untracked: bool,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct CommitResult {
    head: String,
    subject: String,
    backup_version: String,
    status: ProjectStatus,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct HealthItem {
    name: String,
    ok: bool,
    detail: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct HealthReport {
    passed: usize,
    total: usize,
    checks: Vec<HealthItem>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct RojoStatus {
    available: bool,
    running: bool,
    path: String,
    version: String,
    project_file: bool,
    build_file: bool,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct ActionResult {
    success: bool,
    output: String,
    path: String,
}


#[cfg(target_os = "windows")]
fn hide_console(command: &mut Command) {
    use std::os::windows::process::CommandExt;
    const CREATE_NO_WINDOW: u32 = 0x08000000;
    command.creation_flags(CREATE_NO_WINDOW);
}

#[cfg(not(target_os = "windows"))]
fn hide_console(_command: &mut Command) {}

fn git(root: &Path, args: &[&str]) -> Result<String, String> {
    let mut command = Command::new("git");
    command.args(args).current_dir(root);
    hide_console(&mut command);
    let out = command
        .output()
        .map_err(|e| format!("Failed to start git: {e}"))?;

    if !out.status.success() {
        let stderr = String::from_utf8_lossy(&out.stderr).trim().to_string();
        let stdout = String::from_utf8_lossy(&out.stdout).trim().to_string();
        return Err(if !stderr.is_empty() { stderr } else { stdout });
    }
    Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
}

fn git_env(root: &Path, args: &[&str], envs: &[(&str, &str)]) -> Result<String, String> {
    let mut command = Command::new("git");
    command.args(args).current_dir(root);
    for (key, value) in envs {
        command.env(key, value);
    }
    hide_console(&mut command);
    let out = command.output().map_err(|e| format!("Failed to start git: {e}"))?;
    if !out.status.success() {
        let stderr = String::from_utf8_lossy(&out.stderr).trim().to_string();
        let stdout = String::from_utf8_lossy(&out.stdout).trim().to_string();
        return Err(if !stderr.is_empty() { stderr } else { stdout });
    }
    Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
}

fn roflow_dir(root: &Path) -> PathBuf {
    root.join(".roflow")
}

fn backup_store_path(root: &Path) -> PathBuf {
    roflow_dir(root).join("backups.json")
}

fn task_store_path(root: &Path) -> PathBuf {
    roflow_dir(root).join("tasks.json")
}

fn load_task_store(root: &Path) -> TaskStore {
    fs::read_to_string(task_store_path(root))
        .ok()
        .and_then(|text| serde_json::from_str(&text).ok())
        .unwrap_or_default()
}

fn save_task_store(root: &Path, store: &TaskStore) -> Result<(), String> {
    fs::create_dir_all(roflow_dir(root)).map_err(|e| e.to_string())?;
    let mut text = serde_json::to_string_pretty(store).map_err(|e| e.to_string())?;
    text.push('\n');
    fs::write(task_store_path(root), text).map_err(|e| e.to_string())
}

fn unix_now() -> Result<u64, String> {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|value| value.as_secs())
        .map_err(|e| e.to_string())
}

fn record_task(
    root: &Path,
    kind: &str,
    title: &str,
    summary: &str,
    head_before: &str,
    head_after: &str,
    changed_files: Vec<String>,
    backup_version: &str,
    result: &str,
) -> Result<TaskEntry, String> {
    let mut store = load_task_store(root);
    let created_at = unix_now()?;
    let entry = TaskEntry {
        id: format!("{}-{}", created_at, store.tasks.len() + 1),
        created_at,
        kind: kind.to_string(),
        title: title.to_string(),
        summary: summary.to_string(),
        head_before: head_before.to_string(),
        head_after: head_after.to_string(),
        changed_files,
        backup_version: backup_version.to_string(),
        result: result.to_string(),
    };
    store.tasks.push(entry.clone());
    if store.tasks.len() > 200 {
        let remove = store.tasks.len() - 200;
        store.tasks.drain(0..remove);
    }
    save_task_store(root, &store)?;
    Ok(entry)
}

fn clean_relative_path(path: &str) -> Result<&str, String> {
    let trimmed = path.trim();
    if trimmed.is_empty() {
        return Err("File path is empty".into());
    }
    let value = Path::new(trimmed);
    if value.is_absolute()
        || value.components().any(|component| {
            matches!(component, Component::ParentDir | Component::RootDir | Component::Prefix(_))
        })
    {
        return Err("Unsafe file path".into());
    }
    Ok(trimmed)
}

fn truncate_output(value: String, max_chars: usize) -> String {
    if value.chars().count() <= max_chars {
        value
    } else {
        let mut out: String = value.chars().take(max_chars).collect();
        out.push_str("\n\n[RoFlow truncated this output]");
        out
    }
}


fn load_backup_store(root: &Path) -> BackupStore {
    fs::read_to_string(backup_store_path(root))
        .ok()
        .and_then(|text| serde_json::from_str(&text).ok())
        .unwrap_or_default()
}

fn save_backup_store(root: &Path, store: &BackupStore) -> Result<(), String> {
    fs::create_dir_all(roflow_dir(root)).map_err(|e| e.to_string())?;
    let mut text = serde_json::to_string_pretty(store).map_err(|e| e.to_string())?;
    text.push('\n');
    fs::write(backup_store_path(root), text).map_err(|e| e.to_string())
}

fn backup_number(version: &str) -> u32 {
    version
        .strip_prefix("v0.")
        .and_then(|value| value.parse::<u32>().ok())
        .unwrap_or(0)
}

fn next_backup_version(root: &Path, store: &BackupStore) -> Result<String, String> {
    let mut max_number = store.backups.iter().map(|b| backup_number(&b.version)).max().unwrap_or(0);
    let refs = git(root, &["for-each-ref", "refs/roflow/backups/", "--format=%(refname:short)"])?;
    for line in refs.lines() {
        let label = line.rsplit('/').next().unwrap_or(line);
        max_number = max_number.max(backup_number(label));
    }
    Ok(format!("v0.{:03}", max_number + 1))
}

fn create_backup_internal(
    root: &Path,
    title: &str,
    summary: &str,
    automatic: bool,
) -> Result<BackupEntry, String> {
    let mut store = load_backup_store(root);
    let version = next_backup_version(root, &store)?;
    let source_head = git(root, &["rev-parse", "HEAD"])?;
    let subject = git(root, &["log", "-1", "--pretty=%s"]).unwrap_or_default();

    let git_dir = git(root, &["rev-parse", "--git-dir"])?;
    let git_dir_path = {
        let path = PathBuf::from(&git_dir);
        if path.is_absolute() { path } else { root.join(path) }
    };
    let temp_index = git_dir_path.join("roflow-backup.index");
    let _ = fs::remove_file(&temp_index);
    let temp_index_string = temp_index.to_string_lossy().to_string();
    let index_env = [("GIT_INDEX_FILE", temp_index_string.as_str())];

    let snapshot_result = (|| -> Result<String, String> {
        git_env(root, &["read-tree", "HEAD"], &index_env)?;
        git_env(root, &["add", "-A"], &index_env)?;
        // Never put RoFlow metadata or recovery scratch files into snapshots.
        let _ = git_env(
            root,
            &["rm", "-r", "--cached", "--ignore-unmatch", ".roflow", ".recovery"],
            &index_env,
        );
        let tree = git_env(root, &["write-tree"], &index_env)?;

        let identity = [
            ("GIT_INDEX_FILE", temp_index_string.as_str()),
            ("GIT_AUTHOR_NAME", "RoFlow"),
            ("GIT_AUTHOR_EMAIL", "roflow@local"),
            ("GIT_COMMITTER_NAME", "RoFlow"),
            ("GIT_COMMITTER_EMAIL", "roflow@local"),
        ];
        git_env(
            root,
            &[
                "commit-tree",
                &tree,
                "-p",
                &source_head,
                "-m",
                &format!("RoFlow backup {version}"),
            ],
            &identity,
        )
    })();
    let _ = fs::remove_file(&temp_index);
    let snapshot_sha = snapshot_result?;

    git(
        root,
        &[
            "update-ref",
            &format!("refs/roflow/backups/{version}"),
            &snapshot_sha,
        ],
    )?;

    let previous = store.backups.last();
    let diff_base = previous.map(|b| b.snapshot_sha.as_str()).unwrap_or(source_head.as_str());
    let changes = git(root, &["diff", "--name-status", diff_base, &snapshot_sha])
        .unwrap_or_default()
        .lines()
        .filter(|line| !line.trim().is_empty())
        .take(120)
        .map(str::to_string)
        .collect::<Vec<_>>();

    let commits = previous
        .filter(|p| p.source_head != source_head)
        .and_then(|p| git(root, &["log", "--format=%s", &format!("{}..{}", p.source_head, source_head)]).ok())
        .unwrap_or_else(|| if store.backups.is_empty() { subject.clone() } else { String::new() })
        .lines()
        .filter(|line| !line.trim().is_empty())
        .take(30)
        .map(str::to_string)
        .collect::<Vec<_>>();

    let created_at = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|e| e.to_string())?
        .as_secs();

    let entry = BackupEntry {
        version,
        snapshot_sha,
        source_head,
        created_at,
        title: title.trim().to_string(),
        summary: summary.trim().to_string(),
        changes,
        commits,
        automatic,
    };
    store.backups.push(entry.clone());
    save_backup_store(root, &store)?;
    Ok(entry)
}

fn ensure_initial_backup(root: &Path) -> Result<(), String> {
    if load_backup_store(root).backups.is_empty() {
        let subject = git(root, &["log", "-1", "--pretty=%s"]).unwrap_or_else(|_| "Initial project state".into());
        create_backup_internal(root, "Initial snapshot", &subject, true)?;
    }
    Ok(())
}

fn validate_project_root(path: &str) -> Result<PathBuf, String> {
    let root = fs::canonicalize(path).map_err(|e| format!("Project folder not found: {e}"))?;
    if !root.join(".git").exists() {
        return Err("Selected folder is not a Git working tree".into());
    }
    if !root.join(MODEL_PATH).is_file() {
        return Err(format!("{MODEL_PATH} was not found in this project"));
    }
    if git(&root, &["rev-parse", "--is-inside-work-tree"])? != "true" {
        return Err("Selected folder is not inside a Git working tree".into());
    }
    Ok(root)
}

fn current_root(state: &State<AppState>) -> Result<PathBuf, String> {
    state
        .project_root
        .lock()
        .map_err(|_| "Project state lock failed".to_string())?
        .clone()
        .ok_or_else(|| "Select the Bloom_RNG project folder first".to_string())
}

fn status_for(root: &Path) -> Result<ProjectStatus, String> {
    let meta = git(root, &["log", "-1", "--pretty=%H%x00%s"])?;
    let (head, subject) = meta
        .split_once('\0')
        .map(|(head, subject)| (head.to_string(), subject.to_string()))
        .unwrap_or_else(|| (meta.clone(), String::new()));

    let porcelain = git(root, &["status", "--porcelain=v1", "--branch"])?;
    let mut lines = porcelain.lines();
    let branch_line = lines.next().unwrap_or("");
    let branch = branch_line
        .strip_prefix("## ")
        .unwrap_or(branch_line)
        .split("...")
        .next()
        .unwrap_or("")
        .split_whitespace()
        .next()
        .unwrap_or("")
        .to_string();
    let changes: Vec<String> = lines
        .filter(|line| !line.trim().is_empty())
        .take(100)
        .map(str::to_string)
        .collect();

    Ok(ProjectStatus {
        root: root.to_string_lossy().to_string(),
        branch,
        head,
        subject,
        dirty: !changes.is_empty(),
        changes,
        model_exists: root.join(MODEL_PATH).is_file(),
    })
}

fn parse_json_text(text: &str) -> Option<Value> {
    serde_json::from_str(text.trim_start_matches('\u{feff}')).ok()
}

fn write_json(path: &Path, value: &Value) -> Result<(), String> {
    let mut text = serde_json::to_string_pretty(value).map_err(|e| e.to_string())?;
    text.push('\n');
    fs::write(path, text).map_err(|e| e.to_string())
}

fn backup_model(root: &Path) -> Result<String, String> {
    let model = root.join(MODEL_PATH);
    if !model.is_file() {
        return Ok(String::new());
    }
    let recovery = root.join(".recovery");
    fs::create_dir_all(&recovery).map_err(|e| e.to_string())?;
    let stamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|e| e.to_string())?
        .as_secs();
    let name = format!("BloomUI.model.before-roflow-sync.{stamp}.json");
    fs::copy(&model, recovery.join(&name)).map_err(|e| e.to_string())?;
    Ok(format!(".recovery/{name}"))
}

fn child_index(values: &[Value]) -> (Vec<String>, HashMap<String, Value>) {
    let mut counts: HashMap<String, usize> = HashMap::new();
    let mut order = Vec::with_capacity(values.len());
    let mut map = HashMap::new();

    for value in values {
        let base = if let Some(obj) = value.as_object() {
            format!(
                "{}\u{1f}{}",
                obj.get("ClassName").and_then(Value::as_str).unwrap_or(""),
                obj.get("Name").and_then(Value::as_str).unwrap_or("")
            )
        } else {
            format!("__raw__\u{1f}{}", serde_json::to_string(value).unwrap_or_default())
        };
        let index = counts.entry(base.clone()).or_insert(0);
        let key = format!("{base}\u{1f}{index}");
        *index += 1;
        order.push(key.clone());
        map.insert(key, value.clone());
    }
    (order, map)
}

fn merge_children(base: &[Value], local: &[Value], remote: &[Value]) -> Vec<Value> {
    let (_bo, bm) = child_index(base);
    let (lo, lm) = child_index(local);
    let (ro, rm) = child_index(remote);
    let mut out = Vec::new();
    let mut emitted = BTreeSet::new();

    for key in ro {
        emitted.insert(key.clone());
        let r = rm.get(&key).expect("remote key");
        match (bm.get(&key), lm.get(&key)) {
            (None, _) => out.push(r.clone()),
            (Some(b), None) => {
                if b != r {
                    out.push(r.clone());
                }
            }
            (Some(b), Some(l)) => out.push(merge_value(b, l, r)),
        }
    }

    for key in lo {
        if emitted.contains(&key) {
            continue;
        }
        if !bm.contains_key(&key) {
            if let Some(value) = lm.get(&key) {
                out.push(value.clone());
            }
        }
    }
    out
}

fn merge_value(base: &Value, local: &Value, remote: &Value) -> Value {
    if base == remote {
        return local.clone();
    }
    if base == local {
        return remote.clone();
    }

    if let (Some(b), Some(l), Some(r)) = (base.as_object(), local.as_object(), remote.as_object()) {
        let mut out: Map<String, Value> = l.clone();
        let mut keys = BTreeSet::new();
        keys.extend(b.keys().cloned());
        keys.extend(l.keys().cloned());
        keys.extend(r.keys().cloned());

        for key in keys {
            let bv = b.get(&key);
            let lv = l.get(&key);
            let rv = r.get(&key);

            match (bv, lv, rv) {
                (Some(_), _, None) => {
                    out.remove(&key);
                }
                (None, _, Some(remote_value)) => {
                    out.insert(key, remote_value.clone());
                }
                (Some(base_value), None, Some(remote_value)) => {
                    if base_value == remote_value {
                        out.remove(&key);
                    } else {
                        out.insert(key, remote_value.clone());
                    }
                }
                (Some(base_value), Some(local_value), Some(remote_value)) => {
                    let merged = if key == "Children" {
                        match (
                            base_value.as_array(),
                            local_value.as_array(),
                            remote_value.as_array(),
                        ) {
                            (Some(ba), Some(la), Some(ra)) => {
                                Value::Array(merge_children(ba, la, ra))
                            }
                            _ => merge_value(base_value, local_value, remote_value),
                        }
                    } else {
                        merge_value(base_value, local_value, remote_value)
                    };
                    out.insert(key, merged);
                }
                _ => {}
            }
        }
        return Value::Object(out);
    }

    // Atomic Roblox values (UDim2, Color3, arrays) follow the explicitly
    // requested remote AI change when both sides edited the same value.
    remote.clone()
}

#[tauri::command]
fn set_project_root(path: String, state: State<AppState>) -> Result<ProjectStatus, String> {
    let root = validate_project_root(&path)?;
    {
        let mut guard = state.project_root.lock().map_err(|_| "Project state lock failed".to_string())?;
        *guard = Some(root.clone());
    }
    // Connecting must stay lightweight. Backups are created only by explicit
    // checkpoints, restores, or successful AI Sync operations.
    status_for(&root)
}

#[tauri::command]
fn project_status(state: State<AppState>) -> Result<ProjectStatus, String> {
    status_for(&current_root(&state)?)
}

#[tauri::command]
fn read_ui_model(state: State<AppState>) -> Result<String, String> {
    let root = current_root(&state)?;
    fs::read_to_string(root.join(MODEL_PATH)).map_err(|e| format!("Failed to read {MODEL_PATH}: {e}"))
}

#[tauri::command]
fn write_ui_model(contents: String, state: State<AppState>) -> Result<(), String> {
    let root = current_root(&state)?;
    serde_json::from_str::<Value>(&contents).map_err(|e| format!("Refusing to write invalid JSON: {e}"))?;
    fs::write(root.join(MODEL_PATH), contents).map_err(|e| format!("Failed to write {MODEL_PATH}: {e}"))
}

#[tauri::command]
fn git_diff_stat(state: State<AppState>) -> Result<String, String> {
    git(&current_root(&state)?, &["diff", "--stat"])
}

#[tauri::command]
fn safe_ai_sync(editor_model: Option<Value>, state: State<AppState>) -> Result<SyncResult, String> {
    let root = current_root(&state)?;
    let before = status_for(&root)?;
    let old_head = before.head.clone();
    let model_path = root.join(MODEL_PATH);
    let base_text = git(&root, &["show", &format!("HEAD:{MODEL_PATH}")])?;
    let base_model = parse_json_text(&base_text).ok_or("HEAD BloomUI.model.json is invalid")?;

    let model_dirty = !git(&root, &["status", "--porcelain", "--", MODEL_PATH])?.trim().is_empty();
    let disk_text = fs::read_to_string(&model_path).ok();
    let disk_model = disk_text.as_deref().and_then(parse_json_text);
    let local_model = if model_dirty {
        editor_model.or(disk_model)
    } else {
        None
    };

    let mut recovery_backup = String::new();
    if model_dirty {
        recovery_backup = backup_model(&root)?;
        if local_model.is_none() {
            return Err(format!(
                "BloomUI.model.json is invalid. Raw file preserved at {}",
                recovery_backup
            ));
        }
        git(&root, &["restore", "--staged", "--worktree", "--", MODEL_PATH])?;
    }

    let mut stashed = false;
    let mut restored = false;
    let after_model = status_for(&root)?;
    if after_model.dirty {
        let stamp = SystemTime::now().duration_since(UNIX_EPOCH).map_err(|e| e.to_string())?.as_secs();
        let label = format!("RoFlow AI SYNC {stamp}");
        git(&root, &["stash", "push", "-u", "-m", &label])?;
        stashed = true;
    }

    if let Err(pull_error) = git(&root, &["pull", "--ff-only"]) {
        if stashed {
            if git(&root, &["stash", "apply", "stash@{0}"]).is_ok() {
                let _ = git(&root, &["stash", "drop", "stash@{0}"]);
            }
        }
        if let Some(local) = &local_model {
            let _ = write_json(&model_path, local);
        }
        return Err(format!("git pull --ff-only failed: {pull_error}"));
    }

    if stashed {
        if let Err(error) = git(&root, &["stash", "apply", "stash@{0}"]) {
            return Err(format!(
                "Git updated, but local non-UI changes conflicted while restoring. The stash was kept. {error}"
            ));
        }
        restored = true;
        git(&root, &["stash", "drop", "stash@{0}"])?;
    }

    let remote_text = fs::read_to_string(&model_path).map_err(|e| e.to_string())?;
    let remote_model = parse_json_text(&remote_text).ok_or("Pulled BloomUI.model.json is invalid")?;
    let mut model_merged = false;

    if let Some(local) = local_model {
        let merged = merge_value(&base_model, &local, &remote_model);
        write_json(&model_path, &merged)?;
        model_merged = true;
    }

    let final_status = status_for(&root)?;
    let backup = create_backup_internal(
        &root,
        "AI Sync",
        &final_status.subject,
        true,
    ).ok();
    let backup_version = backup.map(|entry| entry.version).unwrap_or_default();
    let changed_files = git(&root, &["diff", "--name-only", &format!("{}..{}", old_head, final_status.head)])
        .unwrap_or_default()
        .lines()
        .chain(final_status.changes.iter().filter_map(|line| line.get(3..)))
        .filter(|line| !line.trim().is_empty())
        .map(str::to_string)
        .collect::<BTreeSet<_>>()
        .into_iter()
        .take(80)
        .collect::<Vec<_>>();
    let _ = record_task(
        &root,
        "ai-sync",
        "AI Sync",
        if old_head != final_status.head { "Pulled and applied the latest repository changes." } else { "Repository was already current; local work was preserved." },
        &old_head,
        &final_status.head,
        changed_files,
        &backup_version,
        "success",
    );
    Ok(SyncResult {
        changed: old_head != final_status.head,
        head: final_status.head,
        subject: final_status.subject,
        dirty: final_status.dirty,
        stashed,
        restored,
        model_merged,
        recovery_backup,
        backup_version,
    })
}

#[tauri::command]
fn list_backups(state: State<AppState>) -> Result<Vec<BackupEntry>, String> {
    let root = current_root(&state)?;
    let mut backups = load_backup_store(&root).backups;
    backups.sort_by_key(|entry| std::cmp::Reverse(backup_number(&entry.version)));
    Ok(backups)
}

#[tauri::command]
fn create_backup(
    title: Option<String>,
    summary: Option<String>,
    state: State<AppState>,
) -> Result<BackupEntry, String> {
    let root = current_root(&state)?;
    create_backup_internal(
        &root,
        title.as_deref().unwrap_or("Manual checkpoint"),
        summary.as_deref().unwrap_or("Created manually in RoFlow"),
        false,
    )
}

#[tauri::command]
fn restore_backup(version: String, state: State<AppState>) -> Result<RestoreResult, String> {
    let root = current_root(&state)?;
    let store = load_backup_store(&root);
    let target = store
        .backups
        .iter()
        .find(|entry| entry.version == version)
        .cloned()
        .ok_or_else(|| format!("Backup {version} was not found"))?;

    let safety = create_backup_internal(
        &root,
        "Safety snapshot",
        &format!("Automatic backup before restoring {}", target.version),
        true,
    )?;

    git(
        &root,
        &[
            "restore",
            "--source",
            &target.snapshot_sha,
            "--staged",
            "--worktree",
            "--",
            ".",
        ],
    )?;
    // Exact restore for normal files while explicitly preserving RoFlow metadata
    // and recovery material.
    let _ = git(&root, &["clean", "-fd", "-e", ".roflow/", "-e", ".recovery/"]);

    Ok(RestoreResult {
        restored_version: target.version,
        safety_version: safety.version,
        status: status_for(&root)?,
    })
}

fn parse_git_changes(root: &Path) -> Result<Vec<GitChange>, String> {
    let porcelain = git(root, &["status", "--porcelain=v1"])?;
    Ok(porcelain
        .lines()
        .filter(|line| line.len() >= 3)
        .take(200)
        .map(|line| {
            let code = line.get(0..2).unwrap_or("??").to_string();
            let raw_path = line.get(3..).unwrap_or("").trim();
            let path = raw_path
                .rsplit_once(" -> ")
                .map(|(_, new_path)| new_path)
                .unwrap_or(raw_path)
                .trim_matches('"')
                .to_string();
            let first = code.chars().next().unwrap_or(' ');
            GitChange {
                staged: first != ' ' && first != '?',
                untracked: code == "??",
                status: code,
                path,
            }
        })
        .collect())
}

fn find_rojo(root: &Path) -> Option<PathBuf> {
    let local = root.join("rojo.exe");
    if local.is_file() {
        return Some(local);
    }

    if let Ok(profile) = env::var("USERPROFILE") {
        let desktop = PathBuf::from(profile).join("Desktop").join("Rojo").join("rojo.exe");
        if desktop.is_file() {
            return Some(desktop);
        }
    }

    let mut command = if cfg!(target_os = "windows") {
        let mut cmd = Command::new("where");
        cmd.arg("rojo");
        cmd
    } else {
        let mut cmd = Command::new("which");
        cmd.arg("rojo");
        cmd
    };
    hide_console(&mut command);
    let output = command.output().ok()?;
    if output.status.success() {
        let first = String::from_utf8_lossy(&output.stdout)
            .lines()
            .next()
            .map(str::trim)
            .filter(|line| !line.is_empty())?
            .to_string();
        return Some(PathBuf::from(first));
    }

    None
}

fn rojo_version(path: &Path) -> String {
    let mut command = Command::new(path);
    command.arg("--version");
    hide_console(&mut command);
    command
        .output()
        .ok()
        .filter(|output| output.status.success())
        .map(|output| String::from_utf8_lossy(&output.stdout).trim().to_string())
        .unwrap_or_default()
}

fn rojo_running(state: &AppState) -> Result<bool, String> {
    let mut guard = state.rojo_child.lock().map_err(|_| "Rojo state lock failed".to_string())?;
    let exited = if let Some(child) = guard.as_mut() {
        child.try_wait().map_err(|e| e.to_string())?.is_some()
    } else {
        false
    };
    if exited {
        *guard = None;
    }
    Ok(guard.is_some())
}

fn rojo_status_for(root: &Path, state: &AppState) -> Result<RojoStatus, String> {
    let executable = find_rojo(root);
    let running = rojo_running(state)?;
    Ok(RojoStatus {
        available: executable.is_some(),
        running,
        version: executable.as_deref().map(rojo_version).unwrap_or_default(),
        path: executable
            .as_ref()
            .map(|path| path.to_string_lossy().to_string())
            .unwrap_or_default(),
        project_file: root.join("default.project.json").is_file(),
        build_file: root.join("BloomRNG.rbxl").is_file(),
    })
}

#[tauri::command]
fn git_changes(state: State<AppState>) -> Result<Vec<GitChange>, String> {
    parse_git_changes(&current_root(&state)?)
}

#[tauri::command]
fn git_file_diff(path: String, state: State<AppState>) -> Result<String, String> {
    let root = current_root(&state)?;
    let safe = clean_relative_path(&path)?;
    let diff = git(
        &root,
        &["diff", "--no-ext-diff", "--unified=3", "HEAD", "--", safe],
    )?;
    if !diff.trim().is_empty() {
        return Ok(truncate_output(diff, 220_000));
    }

    let status = git(&root, &["status", "--porcelain=v1", "--", safe])?;
    if status.starts_with("??") {
        let candidate = root.join(safe);
        let metadata = fs::metadata(&candidate).map_err(|e| e.to_string())?;
        if metadata.len() > 220_000 {
            return Ok(format!(
                "Untracked file is {} bytes. RoFlow does not inline files larger than 220 KB.",
                metadata.len()
            ));
        }
        return match fs::read_to_string(&candidate) {
            Ok(text) => Ok(format!(
                "--- /dev/null\n+++ b/{safe}\n{}",
                text.lines()
                    .map(|line| format!("+{line}"))
                    .collect::<Vec<_>>()
                    .join("\n")
            )),
            Err(_) => Ok("Untracked binary or non-UTF8 file. Preview is unavailable.".into()),
        };
    }

    Ok("No textual diff for this path.".into())
}

#[tauri::command]
fn list_tasks(state: State<AppState>) -> Result<Vec<TaskEntry>, String> {
    let root = current_root(&state)?;
    let mut tasks = load_task_store(&root).tasks;
    tasks.sort_by_key(|task| std::cmp::Reverse(task.created_at));
    tasks.truncate(80);
    Ok(tasks)
}

#[tauri::command]
fn git_commit(message: String, state: State<AppState>) -> Result<CommitResult, String> {
    let root = current_root(&state)?;
    let message = message.trim();
    if message.len() < 3 || message.len() > 180 {
        return Err("Commit message must contain 3-180 characters".into());
    }

    let before = status_for(&root)?;
    if !before.dirty {
        return Err("Working tree is clean".into());
    }

    let safety = create_backup_internal(
        &root,
        "Before commit",
        message,
        true,
    )?;

    git(&root, &["add", "-A"])?;
    let output = git(&root, &["commit", "-m", message])?;
    let after = status_for(&root)?;
    let changed_files = before
        .changes
        .iter()
        .filter_map(|line| line.get(3..))
        .map(str::to_string)
        .take(100)
        .collect::<Vec<_>>();
    let _ = record_task(
        &root,
        "commit",
        message,
        &truncate_output(output, 3_000),
        &before.head,
        &after.head,
        changed_files,
        &safety.version,
        "success",
    );

    Ok(CommitResult {
        head: after.head.clone(),
        subject: after.subject.clone(),
        backup_version: safety.version,
        status: after,
    })
}

#[tauri::command]
fn health_check(state: State<AppState>) -> Result<HealthReport, String> {
    let root = current_root(&state)?;
    let mut checks = Vec::new();

    let git_ok = git(&root, &["rev-parse", "--is-inside-work-tree"])
        .map(|value| value == "true")
        .unwrap_or(false);
    checks.push(HealthItem {
        name: "Git working tree".into(),
        ok: git_ok,
        detail: if git_ok { "Repository is accessible".into() } else { "Git working tree check failed".into() },
    });

    let model_path = root.join(MODEL_PATH);
    let model_exists = model_path.is_file();
    checks.push(HealthItem {
        name: "BloomUI model".into(),
        ok: model_exists,
        detail: if model_exists { MODEL_PATH.into() } else { "BloomUI.model.json is missing".into() },
    });

    let model_valid = fs::read_to_string(&model_path)
        .ok()
        .and_then(|text| parse_json_text(&text))
        .is_some();
    checks.push(HealthItem {
        name: "BloomUI JSON".into(),
        ok: model_valid,
        detail: if model_valid { "Model JSON is valid".into() } else { "Model JSON is invalid or unreadable".into() },
    });

    let project_path = root.join("default.project.json");
    let project_valid = fs::read_to_string(&project_path)
        .ok()
        .and_then(|text| serde_json::from_str::<Value>(&text).ok())
        .is_some();
    checks.push(HealthItem {
        name: "Rojo project".into(),
        ok: project_valid,
        detail: if project_valid { "default.project.json is valid".into() } else { "default.project.json is missing or invalid".into() },
    });

    let unmerged = git(&root, &["diff", "--name-only", "--diff-filter=U"]).unwrap_or_default();
    checks.push(HealthItem {
        name: "Merge conflicts".into(),
        ok: unmerged.trim().is_empty(),
        detail: if unmerged.trim().is_empty() { "No unresolved Git conflicts".into() } else { truncate_output(unmerged, 2_000) },
    });

    let index_lock = root.join(".git").join("index.lock");
    checks.push(HealthItem {
        name: "Git lock".into(),
        ok: !index_lock.exists(),
        detail: if index_lock.exists() { ".git/index.lock exists".into() } else { "No stale Git index lock".into() },
    });

    let src_ok = root.join("src").is_dir();
    checks.push(HealthItem {
        name: "Rojo source tree".into(),
        ok: src_ok,
        detail: if src_ok { "src/ is available".into() } else { "src/ directory is missing".into() },
    });

    let rojo = find_rojo(&root);
    checks.push(HealthItem {
        name: "Rojo executable".into(),
        ok: rojo.is_some(),
        detail: rojo
            .map(|path| path.to_string_lossy().to_string())
            .unwrap_or_else(|| "Rojo was not found in project, Desktop\\Rojo, or PATH".into()),
    });

    let passed = checks.iter().filter(|check| check.ok).count();
    Ok(HealthReport {
        passed,
        total: checks.len(),
        checks,
    })
}

#[tauri::command]
fn rojo_status(state: State<AppState>) -> Result<RojoStatus, String> {
    let root = current_root(&state)?;
    rojo_status_for(&root, &state)
}

#[tauri::command]
fn rojo_start(state: State<AppState>) -> Result<RojoStatus, String> {
    let root = current_root(&state)?;
    if rojo_running(&state)? {
        return rojo_status_for(&root, &state);
    }
    let executable = find_rojo(&root).ok_or("Rojo executable was not found")?;
    if !root.join("default.project.json").is_file() {
        return Err("default.project.json is missing".into());
    }

    let mut command = Command::new(&executable);
    command
        .arg("serve")
        .arg("default.project.json")
        .current_dir(&root)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null());
    hide_console(&mut command);
    let child = command.spawn().map_err(|e| format!("Failed to start Rojo: {e}"))?;
    *state.rojo_child.lock().map_err(|_| "Rojo state lock failed".to_string())? = Some(child);
    rojo_status_for(&root, &state)
}

#[tauri::command]
fn rojo_stop(state: State<AppState>) -> Result<RojoStatus, String> {
    let root = current_root(&state)?;
    {
        let mut guard = state.rojo_child.lock().map_err(|_| "Rojo state lock failed".to_string())?;
        if let Some(child) = guard.as_mut() {
            let _ = child.kill();
            let _ = child.wait();
        }
        *guard = None;
    }
    rojo_status_for(&root, &state)
}

#[tauri::command]
async fn rojo_build(state: State<'_, AppState>) -> Result<ActionResult, String> {
    let root = current_root(&state)?;
    tauri::async_runtime::spawn_blocking(move || {
        let executable = find_rojo(&root).ok_or("Rojo executable was not found")?;
        let output_path = root.join("BloomRNG.rbxl");
        let mut command = Command::new(&executable);
        command
            .arg("build")
            .arg("default.project.json")
            .arg("-o")
            .arg(&output_path)
            .current_dir(&root);
        hide_console(&mut command);
        let output = command.output().map_err(|e| format!("Rojo build failed to start: {e}"))?;
        let mut text = String::from_utf8_lossy(&output.stdout).to_string();
        if !output.stderr.is_empty() {
            if !text.is_empty() {
                text.push('\n');
            }
            text.push_str(&String::from_utf8_lossy(&output.stderr));
        }
        Ok(ActionResult {
            success: output.status.success(),
            output: truncate_output(text, 40_000),
            path: output_path.to_string_lossy().to_string(),
        })
    })
    .await
    .map_err(|e| e.to_string())?
}

#[tauri::command]
fn open_roblox_project(state: State<AppState>) -> Result<(), String> {
    let root = current_root(&state)?;
    let project = root.join("BloomRNG.rbxl");
    if !project.is_file() {
        return Err("BloomRNG.rbxl does not exist yet. Build the project first.".into());
    }

    #[cfg(target_os = "windows")]
    {
        let mut command = Command::new("explorer");
        command.arg(&project);
        hide_console(&mut command);
        command.spawn().map_err(|e| format!("Failed to open Roblox project: {e}"))?;
        return Ok(());
    }

    #[cfg(not(target_os = "windows"))]
    {
        Err("Open Studio is currently implemented for Windows only".into())
    }
}

#[tauri::command]
async fn open_backups_window(app: AppHandle) -> Result<(), String> {
    if let Some(window) = app.get_webview_window("backups") {
        window.set_focus().map_err(|e| e.to_string())?;
        return Ok(());
    }

    WebviewWindowBuilder::new(
        &app,
        "backups",
        WebviewUrl::App("backups.html".into()),
    )
    .title("RoFlow · Backups")
    .inner_size(960.0, 720.0)
    .min_inner_size(760.0, 560.0)
    .center()
    .build()
    .map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
async fn roblox_thumbnail_url(asset_id: String) -> Result<String, String> {
    if asset_id.is_empty() || asset_id.len() > 20 || !asset_id.chars().all(|c| c.is_ascii_digit()) {
        return Err("Invalid Roblox asset id".into());
    }

    let client = reqwest::Client::new();
    let response = client
        .get("https://thumbnails.roblox.com/v1/assets")
        .query(&[
            ("assetIds", asset_id.as_str()),
            ("returnPolicy", "PlaceHolder"),
            ("size", "420x420"),
            ("format", "Png"),
            ("isCircular", "false"),
        ])
        .send()
        .await
        .map_err(|e| e.to_string())?
        .error_for_status()
        .map_err(|e| e.to_string())?;

    let payload: Value = response.json().await.map_err(|e| e.to_string())?;
    payload
        .get("data")
        .and_then(Value::as_array)
        .and_then(|rows| rows.first())
        .and_then(|row| row.get("imageUrl"))
        .and_then(Value::as_str)
        .filter(|url| url.starts_with("https://"))
        .map(str::to_string)
        .ok_or_else(|| "Roblox thumbnail is not ready".to_string())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .manage(AppState::default())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            set_project_root,
            project_status,
            read_ui_model,
            write_ui_model,
            git_diff_stat,
            git_changes,
            git_file_diff,
            git_commit,
            health_check,
            list_tasks,
            rojo_status,
            rojo_start,
            rojo_stop,
            rojo_build,
            open_roblox_project,
            safe_ai_sync,
            list_backups,
            create_backup,
            restore_backup,
            open_backups_window,
            roblox_thumbnail_url
        ])
        .run(tauri::generate_context!())
        .expect("error while running RoFlow");
}
