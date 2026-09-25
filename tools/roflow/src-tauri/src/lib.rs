use serde::Serialize;
use serde_json::{Map, Value};
use std::{
    collections::{BTreeSet, HashMap},
    fs,
    path::{Path, PathBuf},
    process::Command,
    sync::Mutex,
    time::{SystemTime, UNIX_EPOCH},
};
use tauri::State;

const MODEL_PATH: &str = "src/StarterGui/BloomUI.model.json";

#[derive(Default)]
struct AppState {
    project_root: Mutex<Option<PathBuf>>,
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
}

fn git(root: &Path, args: &[&str]) -> Result<String, String> {
    let out = Command::new("git")
        .args(args)
        .current_dir(root)
        .output()
        .map_err(|e| format!("Failed to start git: {e}"))?;

    if !out.status.success() {
        let stderr = String::from_utf8_lossy(&out.stderr).trim().to_string();
        let stdout = String::from_utf8_lossy(&out.stdout).trim().to_string();
        return Err(if !stderr.is_empty() { stderr } else { stdout });
    }
    Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
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
    let head = git(root, &["rev-parse", "HEAD"])?;
    let branch = git(root, &["branch", "--show-current"])?;
    let subject = git(root, &["log", "-1", "--pretty=%s"])?;
    let porcelain = git(root, &["status", "--porcelain"])?;
    let changes: Vec<String> = porcelain
        .lines()
        .filter(|line| !line.trim().is_empty())
        .take(50)
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
    Ok(SyncResult {
        changed: old_head != final_status.head,
        head: final_status.head,
        subject: final_status.subject,
        dirty: final_status.dirty,
        stashed,
        restored,
        model_merged,
        recovery_backup,
    })
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
            safe_ai_sync,
            roblox_thumbnail_url
        ])
        .run(tauri::generate_context!())
        .expect("error while running RoFlow");
}
