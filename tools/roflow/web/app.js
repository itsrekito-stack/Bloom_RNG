const invoke=window.__TAURI__?.core?.invoke;
const dialog=window.__TAURI__?.dialog;
const $=selector=>document.querySelector(selector);
const state={
 status:null,
 root:localStorage.getItem("roflowProjectRoot")||"",
 studioLoaded:false,
 selectedFile:"",
 logs:["RoFlow started."],
 tasks:[],
 health:null,
 rojo:null,
 planner:null
};

const escapeHtml=value=>String(value??"").replace(/[&<>"']/g,char=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"}[char]));
const shortSha=sha=>(sha||"").slice(0,8)||"—";
const fmtTime=seconds=>seconds?new Date(seconds*1000).toLocaleString():"—";

function log(message){
 const time=new Date().toLocaleTimeString();
 state.logs.push(`[${time}] ${message}`);
 if(state.logs.length>300)state.logs.splice(0,state.logs.length-300);
 const out=$("#logOutput");
 if(out){out.textContent=state.logs.join("\n");out.scrollTop=out.scrollHeight}
}

function requireProject(){
 if(!state.root)throw new Error("Choose a project first");
}

function applyStatus(status){
 state.status=status;
 $("#projectName").textContent=(status.root||"").split(/[\\/]/).filter(Boolean).pop()||"Bloom_RNG";
 $("#projectPath").textContent=status.root||"";
 $("#branchValue").textContent=status.branch||"(detached)";
 $("#commitValue").textContent=shortSha(status.head)+" · "+(status.subject||"");
 $("#dirtyValue").textContent=status.dirty?"LOCAL CHANGES":"CLEAN";
 $("#dirtyValue").style.color=status.dirty?"#ffbe40":"#66e0a6";
 $("#changeCount").textContent=status.dirty?`${status.changes.length} changed path(s)`:"Working tree clean";
 $("#changesBadge").textContent=String(status.changes.length||0);
 $("#sideStatus").textContent=(status.branch||"git")+" · "+shortSha(status.head);
 $(".dot").classList.add("ready");
}


function localPlannerDate(){
 const now=new Date();
 const pad=value=>String(value).padStart(2,"0");
 return `${now.getFullYear()}-${pad(now.getMonth()+1)}-${pad(now.getDate())}`;
}
function plannerCounts(tasks){
 const total=tasks?.length||0;
 const done=(tasks||[]).filter(task=>task.done).length;
 return {done,total,percent:total?Math.round(done/total*100):0};
}
function plannerTaskMarkup(task,compact=false){
 return `<label class="planner-task ${task.done?"done":""} ${compact?"compact":""}">
  <input type="checkbox" data-planner-task="${escapeHtml(task.id)}" ${task.done?"checked":""}>
  <span class="planner-check"></span>
  <span class="planner-copy"><strong>${escapeHtml(task.title)}</strong>${compact?"":`<small>${escapeHtml(task.detail||"")}</small>`}</span>
 </label>`;
}
function groupedPlannerMarkup(tasks){
 const groups=[];const byGroup=new Map();
 for(const task of tasks||[]){if(!byGroup.has(task.group)){byGroup.set(task.group,[]);groups.push(task.group)}byGroup.get(task.group).push(task)}
 return groups.map(group=>{
  const list=byGroup.get(group),counts=plannerCounts(list);
  return `<section class="planner-group"><div class="planner-group-head"><strong>${escapeHtml(group)}</strong><span>${counts.done}/${counts.total}</span></div><div class="planner-group-tasks">${list.map(task=>plannerTaskMarkup(task)).join("")}</div></section>`;
 }).join("");
}
function bindPlannerCheckboxes(){
 document.querySelectorAll("[data-planner-task]").forEach(input=>{
  input.onchange=async()=>{
   const id=input.dataset.plannerTask,done=input.checked;input.disabled=true;
   try{renderPlanner(await invoke("planner_set_done",{taskId:id,done}));log((done?"Completed: ":"Reopened: ")+id)}
   catch(error){input.checked=!done;log("Planner update failed: "+error)}
   finally{input.disabled=false}
  };
 });
}
function renderPlanner(planner){
 state.planner=planner;
 const today=plannerCounts(planner.today),release=plannerCounts(planner.roadmap);
 $("#plannerDate").textContent=planner.todayDate||localPlannerDate();
 $("#plannerBadge").textContent=`${today.done}/${today.total}`;
 $("#todayProgressText").textContent=`${today.done} / ${today.total}`;$("#todayPercent").textContent=today.percent+"%";$("#todayProgressBar").style.width=today.percent+"%";
 $("#releaseProgressText").textContent=`${release.done} / ${release.total}`;$("#releasePercent").textContent=release.percent+"%";$("#releaseProgressBar").style.width=release.percent+"%";
 $("#todayTaskList").innerHTML=groupedPlannerMarkup(planner.today)||'<div class="empty-state">No tasks for today.</div>';
 $("#roadmapTaskList").innerHTML=groupedPlannerMarkup(planner.roadmap)||'<div class="empty-state">Roadmap is empty.</div>';
 $("#todayPreviewTitle").textContent="Today’s Focus · "+(planner.todayDate||"");
 $("#todayPreviewCount").textContent=`${today.done}/${today.total}`;
 const preview=[...(planner.today||[]).filter(task=>!task.done),...(planner.today||[]).filter(task=>task.done)].slice(0,5);
 $("#todayPreview").innerHTML=preview.length?preview.map(task=>plannerTaskMarkup(task,true)).join(""):'<div class="empty-state">Today is complete.</div>';
 bindPlannerCheckboxes();
}
async function refreshPlanner(){
 if(!state.root)return;
 try{renderPlanner(await invoke("planner_state",{date:localPlannerDate()}))}
 catch(error){log("Planner failed: "+error)}
}

async function refreshBackups(){
 if(!state.root)return;
 try{
  const backups=await invoke("list_backups");
  const latest=backups?.[0];
  $("#backupValue").textContent=latest?.version||"NONE";
  $("#backupValue").style.color=latest?"#58b1ff":"";
  $("#backupStats").textContent=backups?.length?`${backups.length} checkpoint(s) · ${latest.title||"snapshot"}`:"Create a checkpoint before risky work.";
  $("#backupNavVersion").textContent=latest?.version||"—";
 }catch(error){
  $("#backupValue").textContent="ERROR";
  $("#backupValue").style.color="#ff697b";
  $("#backupStats").textContent=String(error);
  $("#backupNavVersion").textContent="!";
  log("Backup status failed: "+error);
 }
}

function renderTasks(tasks){
 state.tasks=tasks||[];
 const render=task=>`
  <div class="activity">
   <span class="activity-kind">${escapeHtml((task.kind||"TASK").toUpperCase())}</span>
   <div><strong>${escapeHtml(task.title||"Task")}</strong><small>${escapeHtml(task.summary||"")}</small></div>
   <time>${escapeHtml(fmtTime(task.createdAt))}</time>
  </div>`;
 $("#recentTasks").innerHTML=state.tasks.length?state.tasks.slice(0,5).map(render).join(""):'<div class="empty-state">No task history yet.</div>';
 $("#taskList").innerHTML=state.tasks.length?state.tasks.map(task=>`
  <article class="task-row">
   <span class="task-kind">${escapeHtml((task.kind||"TASK").toUpperCase())}</span>
   <div>
    <strong>${escapeHtml(task.title||"Task")}</strong>
    <small>${escapeHtml(task.summary||"")}</small>
    <div class="task-files">${escapeHtml((task.changedFiles||[]).slice(0,8).join(" · ")||"No file list recorded")}</div>
   </div>
   <div class="task-meta">${escapeHtml(fmtTime(task.createdAt))}<br>${escapeHtml(shortSha(task.headBefore))} → ${escapeHtml(shortSha(task.headAfter))}<br>${escapeHtml(task.backupVersion||"no backup")}</div>
  </article>`).join(""):'<div class="empty-state">No recorded AI/Git tasks yet.</div>';
}

async function refreshTasks(){
 if(!state.root)return;
 try{renderTasks(await invoke("list_tasks"))}catch(error){log("Task history failed: "+error)}
}

function renderHealth(report){
 state.health=report;
 $("#healthValue").textContent=`${report.passed}/${report.total} PASS`;
 $("#healthValue").style.color=report.passed===report.total?"#66e0a6":"#ffbe40";
 $("#healthStats").textContent=report.passed===report.total?"Project checks passed":"Review failing checks below";
 const pill=$("#healthPill");
 pill.textContent=`${report.passed}/${report.total}`;
 pill.className="pill "+(report.passed===report.total?"":"muted-pill");
 $("#healthList").innerHTML=report.checks.map(check=>`
  <div class="health-item ${check.ok?"ok":"bad"}">
   <span class="health-icon">${check.ok?"✓":"!"}</span>
   <div><b>${escapeHtml(check.name)}</b><span>${escapeHtml(check.detail)}</span></div>
  </div>`).join("");
}

async function runHealth(){
 requireProject();
 const report=await invoke("health_check");
 renderHealth(report);
 log(`Health check: ${report.passed}/${report.total} passed`);
 return report;
}

function applyRojo(status){
 state.rojo=status;
 $("#rojoValue").textContent=status.running?"RUNNING":status.available?"READY":"NOT FOUND";
 $("#rojoValue").style.color=status.running?"#66e0a6":status.available?"#58b1ff":"#ff697b";
 $("#rojoStats").textContent=status.available?(status.version||status.path||"Rojo available"):"Install Rojo or place rojo.exe in the project/Desktop/Rojo.";
 $("#rojoPageState").textContent=status.running?"Rojo serve is running":status.available?"Rojo is ready":"Rojo not found";
 $("#rojoPageState").style.color=status.running?"#66e0a6":status.available?"#58b1ff":"#ff697b";
 $("#rojoPageDetail").textContent=status.available?((status.version||status.path)+(status.projectFile?" · project config ready":" · default.project.json missing")):"RoFlow checked project folder, Desktop\\Rojo and PATH.";
 $("#startRojoBtn").disabled=!status.available||status.running||!status.projectFile;
 $("#stopRojoBtn").disabled=!status.running;
 $("#buildBtn").disabled=!status.available||!status.projectFile;
 $("#openStudioBtn").disabled=!status.buildFile;
}

async function refreshRojo(){
 if(!state.root)return;
 try{applyRojo(await invoke("rojo_status"))}catch(error){log("Rojo status failed: "+error)}
}

async function connectRoot(path){
 const status=await invoke("set_project_root",{path});
 state.root=path;
 localStorage.setItem("roflowProjectRoot",path);
 applyStatus(status);
 await Promise.all([refreshBackups(),refreshTasks(),refreshRojo(),refreshPlanner()]);
 log("Project connected: "+path);
 return status;
}

async function refresh(){
 if(!state.root)return;
 try{
  const status=await invoke("project_status");
  applyStatus(status);
  await Promise.all([refreshBackups(),refreshTasks(),refreshRojo(),refreshPlanner()]);
  log("Project status refreshed");
 }catch(error){log("Refresh failed: "+error);throw error}
}

async function chooseProject(){
 try{
  const selected=await dialog.open({directory:true,multiple:false,title:"Choose Roblox/Rojo project"});
  if(selected)await connectRoot(selected);
 }catch(error){log("Project selection failed: "+error)}
}

function notifyStudioModelChanged(){
 if(!state.studioLoaded)return;
 const frame=$("#uiStudioFrame");
 try{frame.contentWindow?.postMessage({type:"roflow-refresh-model"},"*")}catch{}
}

async function runSync(){
 requireProject();
 const out=$("#syncOutput");
 out.textContent="Safe sync: preserve → pull → merge → restore → checkpoint…";
 try{
  const data=await invoke("safe_ai_sync",{editorModel:null});
  out.textContent=(data.changed?"Updated to ":"Already current at ")+shortSha(data.head)+"\n"+data.subject+(data.modelMerged?"\nBloomUI.model.json merged safely":"")+(data.stashed&&data.restored?"\nOther local changes restored":"")+(data.backupVersion?"\nCheckpoint: "+data.backupVersion:"");
  notifyStudioModelChanged();
  await refresh();
  log("Safe AI Sync completed");
  return data;
 }catch(error){
  out.textContent="SYNC STOPPED SAFELY\n"+String(error);
  log("Sync stopped: "+error);
  throw error;
 }
}

async function createCheckpoint(note="Manual checkpoint"){
 requireProject();
 const backup=await invoke("create_backup",{title:"Checkpoint",summary:note});
 await refreshBackups();
 log("Checkpoint created: "+backup.version);
 return backup;
}

async function runDevCycle(){
 requireProject();
 const button=$("#devCycleBtn");
 button.disabled=true;
 $("#cycleTitle").textContent="Running…";
 $("#cycleOutput").textContent="1/3 Creating checkpoint…";
 try{
  const checkpoint=await createCheckpoint("Automatic checkpoint before DEV CYCLE");
  $("#cycleOutput").textContent+=`\nCreated ${checkpoint.version}\n2/3 Safe AI Sync…`;
  const sync=await runSync();
  $("#cycleOutput").textContent+=`\nHEAD ${shortSha(sync.head)}\n3/3 Health check…`;
  const health=await runHealth();
  $("#cycleOutput").textContent+=`\nHealth: ${health.passed}/${health.total} PASS`;
  $("#cycleTitle").textContent=health.passed===health.total?"Cycle complete":"Cycle complete with warnings";
  $("#cycleText").textContent="No commit or push was performed automatically.";
  log("DEV CYCLE completed");
 }catch(error){
  $("#cycleTitle").textContent="Cycle stopped safely";
  $("#cycleOutput").textContent+=`\nERROR: ${String(error)}`;
  log("DEV CYCLE stopped: "+error);
 }finally{button.disabled=false}
}

function ensureUiStudio(force=false){
 const frame=$("#uiStudioFrame");
 if(force||!state.studioLoaded){
  frame.src="./ui-studio/index.html?ts="+Date.now();
  state.studioLoaded=true;
  log("Embedded UI Studio loaded");
 }
}

function diffClass(line){
 if(line.startsWith("+++")||line.startsWith("---")||line.startsWith("diff ")||line.startsWith("index "))return"meta";
 if(line.startsWith("@@"))return"hunk";
 if(line.startsWith("+"))return"add";
 if(line.startsWith("-"))return"del";
 return"";
}

async function selectChangedFile(path,status){
 state.selectedFile=path;
 document.querySelectorAll(".file-item").forEach(item=>item.classList.toggle("active",item.dataset.path===path));
 $("#diffTitle").textContent=path;
 $("#diffMeta").textContent=status;
 $("#diffOutput").innerHTML='<div class="empty-state">Loading diff…</div>';
 try{
  const diff=await invoke("git_file_diff",{path});
  $("#diffOutput").innerHTML=String(diff).split("\n").map(line=>`<div class="diff-line ${diffClass(line)}">${escapeHtml(line)||" "}</div>`).join("");
 }catch(error){$("#diffOutput").innerHTML=`<div class="empty-state">${escapeHtml(error)}</div>`}
}

async function loadChanges(){
 if(!state.root)return;
 try{
  const changes=await invoke("git_changes");
  $("#changesBadge").textContent=String(changes.length);
  $("#fileList").innerHTML=changes.length?changes.map(change=>`
   <button class="file-item" data-path="${escapeHtml(change.path)}" data-status="${escapeHtml(change.status)}">
    <span class="file-status">${escapeHtml(change.status)}</span><span class="file-path">${escapeHtml(change.path)}</span>
   </button>`).join(""):'<div class="empty-state">Working tree clean.</div>';
  document.querySelectorAll(".file-item").forEach(item=>item.onclick=()=>selectChangedFile(item.dataset.path,item.dataset.status));
  if(changes.length){
   const selected=changes.find(change=>change.path===state.selectedFile)||changes[0];
   await selectChangedFile(selected.path,selected.status);
  }else{
   state.selectedFile="";
   $("#diffTitle").textContent="No local changes";
   $("#diffMeta").textContent="CLEAN";
   $("#diffOutput").innerHTML='<div class="empty-state">Nothing to review.</div>';
  }
 }catch(error){log("Changes failed: "+error)}
}

async function commitChanges(){
 requireProject();
 const message=$("#commitMessage").value.trim();
 if(message.length<3){log("Commit message is too short");return}
 const button=$("#commitBtn");button.disabled=true;
 try{
  const result=await invoke("git_commit",{message});
  $("#commitMessage").value="";
  applyStatus(result.status);
  log(`Commit created: ${shortSha(result.head)} · checkpoint ${result.backupVersion}`);
  await Promise.all([loadChanges(),refreshBackups(),refreshTasks()]);
 }catch(error){log("Commit failed: "+error);alert(String(error))}
 finally{button.disabled=false}
}

async function startRojo(){
 try{applyRojo(await invoke("rojo_start"));$("#rojoOutput").textContent="Rojo serve started.";log("Rojo serve started")}catch(error){$("#rojoOutput").textContent=String(error);log("Rojo start failed: "+error)}
}
async function stopRojo(){
 try{applyRojo(await invoke("rojo_stop"));$("#rojoOutput").textContent="Rojo serve stopped.";log("Rojo serve stopped")}catch(error){$("#rojoOutput").textContent=String(error);log("Rojo stop failed: "+error)}
}
async function buildProject(){
 const button=$("#buildBtn");button.disabled=true;$("#rojoOutput").textContent="Building BloomRNG.rbxl…";
 try{
  const result=await invoke("rojo_build");
  $("#rojoOutput").textContent=(result.success?"BUILD SUCCESS\n":"BUILD FAILED\n")+(result.path||"")+"\n"+(result.output||"");
  log(result.success?"Rojo build completed":"Rojo build failed");
  await refreshRojo();
 }catch(error){$("#rojoOutput").textContent=String(error);log("Rojo build failed: "+error)}
 finally{button.disabled=false}
}

function navigate(page){
 document.querySelectorAll(".nav[data-page]").forEach(button=>button.classList.toggle("active",button.dataset.page===page));
 document.querySelectorAll(".page").forEach(section=>section.classList.remove("active"));
 $("#"+page+"Page")?.classList.add("active");
 const label=document.querySelector(`.nav[data-page="${page}"]`)?.childNodes?.[0]?.textContent?.trim()||page;
 $("#pageTitle").textContent=label;
 if(page==="ui")ensureUiStudio();
 if(page==="changes")loadChanges();
 if(page==="planner")refreshPlanner();
 if(page==="tasks")refreshTasks();
 if(page==="roblox")refreshRojo();
}

document.querySelectorAll(".nav[data-page]").forEach(button=>button.onclick=()=>navigate(button.dataset.page));
document.querySelectorAll("[data-go]").forEach(button=>button.onclick=()=>navigate(button.dataset.go));
$("#chooseBtn").onclick=chooseProject;
$("#refreshBtn").onclick=()=>refresh().catch(()=>{});
$("#syncBtn").onclick=()=>runSync().catch(()=>{});
$("#devCycleBtn").onclick=runDevCycle;
$("#checkpointBtn").onclick=()=>createCheckpoint("Manual dashboard checkpoint").catch(error=>log("Checkpoint failed: "+error));
$("#healthBtn").onclick=()=>runHealth().catch(error=>log("Health check failed: "+error));
$("#backupsBtn").onclick=async()=>{try{requireProject();await invoke("open_backups_window");log("Backups window opened")}catch(error){log("Failed to open backups: "+error)}};
$("#reloadStudioBtn").onclick=()=>ensureUiStudio(true);
$("#reloadChangesBtn").onclick=loadChanges;
$("#changesCheckpointBtn").onclick=()=>createCheckpoint("Checkpoint from Changes review").catch(error=>log("Checkpoint failed: "+error));
$("#commitBtn").onclick=commitChanges;
$("#commitMessage").addEventListener("keydown",event=>{if(event.key==="Enter")commitChanges()});
$("#reloadTasksBtn").onclick=refreshTasks;
$("#refreshRojoBtn").onclick=refreshRojo;
$("#startRojoBtn").onclick=startRojo;
$("#stopRojoBtn").onclick=stopRojo;
$("#buildBtn").onclick=buildProject;
$("#openStudioBtn").onclick=async()=>{try{await invoke("open_roblox_project");log("Opened BloomRNG.rbxl")}catch(error){$("#rojoOutput").textContent=String(error);log("Open Studio failed: "+error)}};

window.addEventListener("message",async event=>{
 if(event.data?.type==="roflow-project-changed"){
  state.root=event.data.path||state.root;
  if(state.root)localStorage.setItem("roflowProjectRoot",state.root);
  await refresh().catch(()=>{});
 }else if(event.data?.type==="roflow-sync-complete"){
  await refresh().catch(()=>{});
  log("UI Studio completed AI Sync");
 }
});

(async()=>{
 if(!invoke){log("This page must run inside the RoFlow Tauri desktop app.");return}
 if(state.root){
  try{
   await connectRoot(state.root);
  }catch(error){
   localStorage.removeItem("roflowProjectRoot");
   state.root="";
   log("Saved project path is no longer valid: "+error);
  }
 }
})();
