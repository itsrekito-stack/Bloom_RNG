use serde::Serialize;
use std::{
    fs,
    path::{Path, PathBuf},
    process::Command,
    sync::Mutex,
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
        return Err(format!("{} was not found in this project", MODEL_PATH));
    }

    let inside = git(&root, &["rev-parse", "--is-inside-work-tree"])?;
    if inside != "true" {
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

#[tauri::command]
fn set_project_root(path: String, state: State<AppState>) -> Result<ProjectStatus, String> {
    let root = validate_project_root(&path)?;
    {
        let mut guard = state
            .project_root
            .lock()
            .map_err(|_| "Project state lock failed".to_string())?;
        *guard = Some(root.clone());
    }
    status_for(&root)
}

#[tauri::command]
fn project_status(state: State<AppState>) -> Result<ProjectStatus, String> {
    let root = current_root(&state)?;
    status_for(&root)
}

#[tauri::command]
fn read_ui_model(state: State<AppState>) -> Result<String, String> {
    let root = current_root(&state)?;
    fs::read_to_string(root.join(MODEL_PATH))
        .map_err(|e| format!("Failed to read {MODEL_PATH}: {e}"))
}

#[tauri::command]
fn write_ui_model(contents: String, state: State<AppState>) -> Result<(), String> {
    let root = current_root(&state)?;

    serde_json::from_str::<serde_json::Value>(&contents)
        .map_err(|e| format!("Refusing to write invalid JSON: {e}"))?;

    fs::write(root.join(MODEL_PATH), contents)
        .map_err(|e| format!("Failed to write {MODEL_PATH}: {e}"))
}

#[tauri::command]
fn git_diff_stat(state: State<AppState>) -> Result<String, String> {
    let root = current_root(&state)?;
    git(&root, &["diff", "--stat"])
}

#[tauri::command]
fn git_pull_ff_only(state: State<AppState>) -> Result<ProjectStatus, String> {
    let root = current_root(&state)?;
    let before = status_for(&root)?;

    if before.dirty {
        return Err(
            "RoFlow v0.1 will not pull over local changes. Commit/stash them or use the existing Bloom UI Studio safe AI SYNC."
                .into(),
        );
    }

    git(&root, &["pull", "--ff-only"])?;
    status_for(&root)
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
            git_pull_ff_only
        ])
        .run(tauri::generate_context!())
        .expect("error while running RoFlow");
}
