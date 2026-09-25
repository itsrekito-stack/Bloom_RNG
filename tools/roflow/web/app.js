const invoke=window.__TAURI__?.core?.invoke;
const dialog=window.__TAURI__?.dialog;
const $=s=>document.querySelector(s);
const state={status:null,root:localStorage.getItem("roflowProjectRoot")||"",studioLoaded:false};

function log(message){const out=$("#logOutput");const time=new Date().toLocaleTimeString();out.textContent+=`\n[${time}] ${message}`;out.scrollTop=out.scrollHeight}
function shortSha(sha){return (sha||"").slice(0,8)||"—"}
async function connectRoot(path){if(!invoke)throw new Error("Tauri bridge is unavailable");const status=await invoke("set_project_root",{path});state.root=path;localStorage.setItem("roflowProjectRoot",path);applyStatus(status);await refreshBackups();log("Project connected: "+path);return status}
function applyStatus(s){state.status=s;$("#projectName").textContent=(s.root||"").split(/[\\/]/).filter(Boolean).pop()||"Bloom_RNG";$("#projectPath").textContent=s.root;$("#branchValue").textContent=s.branch||"(detached)";$("#commitValue").textContent=shortSha(s.head)+" · "+(s.subject||"");$("#dirtyValue").textContent=s.dirty?"LOCAL CHANGES":"CLEAN";$("#dirtyValue").style.color=s.dirty?"#ffbe40":"#66e0a6";$("#changeCount").textContent=s.dirty?`${s.changes.length} changed path(s)`:"Working tree clean";$("#modelValue").textContent=s.modelExists?"MODEL READY":"MODEL MISSING";$("#modelValue").style.color=s.modelExists?"#66e0a6":"#ff697b";$("#changesOutput").textContent=s.changes.length?s.changes.join("\n"):"Working tree clean.";$("#sideStatus").textContent=(s.branch||"git")+" · "+shortSha(s.head);$(".dot").classList.add("ready")}
async function refreshBackups(){
 if(!state.root)return;
 try{
  const backups=await invoke("list_backups");
  const latest=backups?.[0];
  $("#backupValue").textContent=latest?.version||"—";
  $("#backupStats").textContent=backups?.length?`${backups.length} saved version(s) · latest ${latest.title||"snapshot"}`:"No backups yet";
  $("#backupNavVersion").textContent=latest?.version||"—";
 }catch(e){
  $("#backupValue").textContent="ERROR";
  $("#backupValue").style.color="#ff697b";
  $("#backupStats").textContent="Backups unavailable · "+String(e);
  $("#backupNavVersion").textContent="!";
  log("Backup status failed: "+e)
 }
}
async function refresh(){if(!state.root)return;try{const s=await invoke("project_status");applyStatus(s);await refreshBackups();log("Project status refreshed")}catch(e){log("Refresh failed: "+e);throw e}}
async function chooseProject(){try{const selected=await dialog.open({directory:true,multiple:false,title:"Choose Bloom_RNG project"});if(selected){await connectRoot(selected);const frame=$("#uiStudioFrame");if(frame.contentWindow)frame.contentWindow.location.reload()}}catch(e){log("Project selection failed: "+e)}}
async function inspectModel(){try{const raw=await invoke("read_ui_model");const model=JSON.parse(raw);let nodes=0;(function walk(n){nodes++;for(const c of n.Children||[])walk(c)})(model);$("#modelStats").textContent=nodes.toLocaleString()+" authored instances detected";log("Bloom UI model inspected: "+nodes+" instances")}catch(e){log("Model inspection failed: "+e)}}
async function sync(){
 const out=$("#syncOutput");out.textContent="Safe sync: backup → stash → pull → merge → restore…";
 try{
  const data=await invoke("safe_ai_sync",{editorModel:null});
  await refresh();await inspectModel();
  out.textContent=(data.changed?"Updated to ":"Already current at ")+shortSha(data.head)+"\n"+data.subject+(data.modelMerged?"\nBloomUI.model.json merged safely":"")+(data.stashed&&data.restored?"\nOther local changes restored":"")+(data.backupVersion?"\nBackup created: "+data.backupVersion:"");
  log("Safe AI sync completed");
  const frame=$("#uiStudioFrame");if(state.studioLoaded&&frame.contentWindow)frame.contentWindow.location.reload();
 }catch(e){out.textContent="SYNC STOPPED SAFELY\n"+String(e);log("Sync stopped: "+e)}
}
function ensureUiStudio(force=false){const frame=$("#uiStudioFrame");if(force||!state.studioLoaded){frame.src="./ui-studio/index.html?ts="+Date.now();state.studioLoaded=true;log("Embedded UI Studio loaded")}}
document.querySelectorAll(".nav").forEach(btn=>btn.onclick=()=>{document.querySelectorAll(".nav").forEach(x=>x.classList.toggle("active",x===btn));document.querySelectorAll(".page").forEach(x=>x.classList.remove("active"));$("#"+btn.dataset.page+"Page").classList.add("active");$("#pageTitle").textContent=btn.textContent;if(btn.dataset.page==="ui")ensureUiStudio()});
$("#chooseBtn").onclick=chooseProject;$("#refreshBtn").onclick=()=>refresh().catch(()=>{});$("#syncBtn").onclick=sync;$("#reloadStudioBtn").onclick=()=>ensureUiStudio(true);$("#backupsBtn").onclick=async()=>{try{await invoke("open_backups_window");log("Backups window opened")}catch(e){log("Failed to open backups: "+e)}};
window.addEventListener("message",async e=>{if(e.data?.type==="roflow-project-changed"){state.root=e.data.path||state.root;if(state.root)localStorage.setItem("roflowProjectRoot",state.root);await refresh().catch(()=>{})}else if(e.data?.type==="roflow-sync-complete"){await refresh().catch(()=>{});log("UI Studio completed AI sync")}});
(async()=>{if(!invoke){log("This page must run inside the RoFlow Tauri desktop app.");return}if(state.root){try{await connectRoot(state.root);await inspectModel()}catch(e){localStorage.removeItem("roflowProjectRoot");state.root="";log("Saved project path is no longer valid: "+e)}}})();
