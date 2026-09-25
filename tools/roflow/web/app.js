const invoke=window.__TAURI__?.core?.invoke;
const dialog=window.__TAURI__?.dialog;

const $=s=>document.querySelector(s);
const state={status:null,root:localStorage.getItem("roflowProjectRoot")||""};

function log(message){
  const out=$("#logOutput");
  const time=new Date().toLocaleTimeString();
  out.textContent+=`\n[${time}] ${message}`;
  out.scrollTop=out.scrollHeight;
}
function shortSha(sha){return (sha||"").slice(0,8)||"—"}

async function connectRoot(path){
  if(!invoke)throw new Error("Tauri bridge is unavailable");
  const status=await invoke("set_project_root",{path});
  state.root=path;
  localStorage.setItem("roflowProjectRoot",path);
  applyStatus(status);
  log("Project connected: "+path);
  return status;
}

function applyStatus(s){
  state.status=s;
  $("#projectName").textContent=(s.root||"").split(/[\\/]/).filter(Boolean).pop()||"Bloom_RNG";
  $("#projectPath").textContent=s.root;
  $("#branchValue").textContent=s.branch||"(detached)";
  $("#commitValue").textContent=shortSha(s.head)+" · "+(s.subject||"");
  $("#dirtyValue").textContent=s.dirty?"LOCAL CHANGES":"CLEAN";
  $("#dirtyValue").style.color=s.dirty?"#ffbe40":"#66e0a6";
  $("#changeCount").textContent=s.dirty?`${s.changes.length} changed path(s)`:"Working tree clean";
  $("#modelValue").textContent=s.modelExists?"MODEL READY":"MODEL MISSING";
  $("#modelValue").style.color=s.modelExists?"#66e0a6":"#ff697b";
  $("#changesOutput").textContent=s.changes.length?s.changes.join("\n"):"Working tree clean.";
  $("#sideStatus").textContent=(s.branch||"git")+" · "+shortSha(s.head);
  $(".dot").classList.add("ready");
}

async function refresh(){
  if(!state.root)return;
  try{
    const s=await invoke("project_status");
    applyStatus(s);
    log("Project status refreshed");
  }catch(e){log("Refresh failed: "+e);throw e}
}

async function chooseProject(){
  try{
    const selected=await dialog.open({directory:true,multiple:false,title:"Choose Bloom_RNG project"});
    if(selected)await connectRoot(selected);
  }catch(e){log("Project selection failed: "+e)}
}

async function inspectModel(){
  try{
    const raw=await invoke("read_ui_model");
    const model=JSON.parse(raw);
    let nodes=0;
    (function walk(n){nodes++;for(const c of n.Children||[])walk(c)})(model);
    $("#modelOutput").textContent=[
      "Name: "+(model.Name||"BloomUI"),
      "Class: "+(model.ClassName||"ScreenGui"),
      "Instances: "+nodes,
      "Bytes: "+new Blob([raw]).size.toLocaleString(),
      "Source: src/StarterGui/BloomUI.model.json"
    ].join("\n");
    $("#modelStats").textContent=nodes.toLocaleString()+" authored instances detected";
    log("Bloom UI model inspected");
  }catch(e){
    $("#modelOutput").textContent=String(e);
    log("Model inspection failed: "+e);
  }
}

async function sync(){
  const out=$("#syncOutput");
  out.textContent="Pulling latest main with --ff-only…";
  try{
    const s=await invoke("git_pull_ff_only");
    applyStatus(s);
    out.textContent="Sync complete.\n"+shortSha(s.head)+" · "+s.subject;
    log("Git pull --ff-only completed");
  }catch(e){
    out.textContent="SYNC STOPPED SAFELY\n"+String(e);
    log("Sync stopped: "+e);
  }
}

document.querySelectorAll(".nav").forEach(btn=>btn.onclick=()=>{
  document.querySelectorAll(".nav").forEach(x=>x.classList.toggle("active",x===btn));
  document.querySelectorAll(".page").forEach(x=>x.classList.remove("active"));
  $("#"+btn.dataset.page+"Page").classList.add("active");
  $("#pageTitle").textContent=btn.textContent;
});

$("#chooseBtn").onclick=chooseProject;
$("#refreshBtn").onclick=()=>refresh().catch(()=>{});
$("#syncBtn").onclick=sync;
$("#inspectModelBtn").onclick=inspectModel;

(async()=>{
  if(!invoke){
    log("This page must run inside the RoFlow Tauri desktop app.");
    return;
  }
  if(state.root){
    try{await connectRoot(state.root);await inspectModel()}catch(e){
      localStorage.removeItem("roflowProjectRoot");
      state.root="";
      log("Saved project path is no longer valid: "+e);
    }
  }
})();
