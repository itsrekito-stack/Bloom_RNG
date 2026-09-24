(()=>{
"use strict";

const $=s=>document.querySelector(s);
const els={
 tree:$("#tree"),inspector:$("#inspector"),device:$("#device"),guiRoot:$("#guiRoot"),overlay:$("#selectionOverlay"),geometry:$("#geometryLayer"),
 stageScroller:$("#stageScroller"),status:$("#statusText"),pixels:$("#pixelReadout"),target:$("#targetReadout"),
 toast:$("#toast"),fileInput:$("#fileInput"),jsonDialog:$("#jsonDialog"),jsonArea:$("#jsonArea")
};

const MODIFIERS=new Set(["UICorner","UIStroke","UIPadding","UIListLayout","UIGridLayout","UIAspectRatioConstraint","UIScale","UIGradient"]);
const TEXT_CLASSES=new Set(["TextLabel","TextButton","TextBox"]);
const IMAGE_CLASSES=new Set(["ImageLabel","ImageButton"]);
const CONTAINERS=new Set(["ScreenGui","Frame","ScrollingFrame","TextButton","ImageButton"]);
const DEFAULT_TARGET="src/StarterGui/BloomUI.model.json";

const state={
 root:null,selectedId:null,viewport:{w:1366,h:768},zoom:.72,snap:8,labels:false,grid:true,showHidden:true,geometry:true,inset:36,mode:"design",previewScene:"gameplay",
 projectHandle:null,targetPath:localStorage.getItem("bloomTargetPath")||DEFAULT_TARGET,
 history:[],future:[],dirty:false,drag:null,collapsed:new Set(),clipboard:null,treeQuery:"",pan:null
};

let idCounter=1;
const uid=()=> "ui_"+(idCounter++).toString(36)+"_"+Date.now().toString(36).slice(-4);
const deepClone=x=>JSON.parse(JSON.stringify(x));
const clamp=(v,a,b)=>Math.min(b,Math.max(a,v));
const finite=(v,d=0)=>Number.isFinite(+v)?+v:d;
const roundOffset=v=>Math.round(finite(v));
const c3=(r=1,g=1,b=1)=>[r,g,b];
const ud=(s=0,o=0)=>({UDim:[s,o]});
const u2=(xs=0,xo=0,ys=0,yo=0)=>({UDim2:[[xs,xo],[ys,yo]]});
const v2=(x=0,y=0)=>({Vector2:[x,y]});

const PREFS_KEY="BloomUIStudioPrefsV1";
function loadPrefs(){
 try{
  const p=JSON.parse(localStorage.getItem(PREFS_KEY)||"{}");
  if(p.viewport&&Number.isFinite(p.viewport.w)&&Number.isFinite(p.viewport.h))state.viewport={w:p.viewport.w,h:p.viewport.h};
  if(Number.isFinite(p.zoom))state.zoom=clamp(p.zoom,.25,1.5);
  if(Number.isFinite(p.snap))state.snap=p.snap;
  if(typeof p.labels==="boolean")state.labels=p.labels;
  if(typeof p.grid==="boolean")state.grid=p.grid;
  if(typeof p.showHidden==="boolean")state.showHidden=p.showHidden;
  if(typeof p.geometry==="boolean")state.geometry=p.geometry;
  if(Number.isFinite(p.inset))state.inset=p.inset;
  if(["design","preview"].includes(p.mode))state.mode=p.mode;
  if(["gameplay","seedbag","reward","toast"].includes(p.previewScene))state.previewScene=p.previewScene;
 }catch{}
}
function savePrefs(){
 localStorage.setItem(PREFS_KEY,JSON.stringify({
  viewport:state.viewport,zoom:state.zoom,snap:state.snap,labels:state.labels,grid:state.grid,
  showHidden:state.showHidden,geometry:state.geometry,inset:state.inset,mode:state.mode,previewScene:state.previewScene
 }));
}
function syncToolbarFromState(){
 $("#viewportW").value=state.viewport.w;$("#viewportH").value=state.viewport.h;
 $("#zoomRange").value=Math.round(state.zoom*100);$("#zoomLabel").textContent=Math.round(state.zoom*100)+"%";
 $("#snapSelect").value=String(state.snap);
 $("#labelsToggle").checked=state.labels;$("#gridToggle").checked=state.grid;$("#hiddenToggle").checked=state.showHidden;$("#geometryToggle").checked=state.geometry;
 $("#insetInput").value=state.inset;$("#modeSelect").value=state.mode;$("#sceneSelect").value=state.previewScene;
 $("#sceneSelect").disabled=!isPreview();$("#modeSelect").classList.toggle("preview-active",isPreview());
 els.stageScroller.classList.toggle("no-grid",!state.grid);
 const preset=`${state.viewport.w}x${state.viewport.h}`;if([...$("#presetSelect").options].some(o=>o.value===preset))$("#presetSelect").value=preset;else $("#presetSelect").value="";
}


function normalizeNode(node){
 const n={
  ClassName:node.ClassName||"Frame",
  Name:node.Name||node.ClassName||"Object",
  Properties:deepClone(node.Properties||{}),
  Children:(node.Children||[]).map(normalizeNode),
  __id:uid()
 };
 return n;
}
function stripNode(node){
 return {
  ClassName:node.ClassName,
  Name:node.Name,
  Properties:sanitizeProperties(deepClone(node.Properties||{})),
  ...(node.Children&&node.Children.length?{Children:node.Children.map(stripNode)}:{})
 };
}
function sanitizeProperties(props){
 const walk=v=>{
  if(!v||typeof v!=="object") return v;
  if(Array.isArray(v)) return v.map(walk);
  if(v.UDim&&Array.isArray(v.UDim)){v.UDim=[finite(v.UDim[0]),roundOffset(v.UDim[1])];return v}
  if(v.UDim2&&Array.isArray(v.UDim2)){
   v.UDim2=[
    [finite(v.UDim2[0]?.[0]),roundOffset(v.UDim2[0]?.[1])],
    [finite(v.UDim2[1]?.[0]),roundOffset(v.UDim2[1]?.[1])]
   ];return v
  }
  Object.keys(v).forEach(k=>v[k]=walk(v[k]));
  return v;
 };
 return walk(props);
}
function serialize(pretty=true){return JSON.stringify(stripNode(state.root),null,pretty?2:0)}
function setRoot(raw,label="Модель загружена"){
 try{
  state.root=normalizeNode(raw);
  const safeRoot=(state.root.Children||[]).find(x=>x.Name==="SafeRoot"&&x.ClassName==="Frame");
  state.selectedId=(safeRoot||state.root).__id;
  state.history=[];state.future=[];state.dirty=false;
  syncInsetFromRoot();renderAll();toast(label);
 }catch(e){console.error("[Bloom UI Studio] model/render error",e);toast("Ошибка модели: "+e.message,true)}
}
function syncInsetFromRoot(){
 if(state.root?.ClassName==="ScreenGui"){
  const ignore=state.root.Properties?.IgnoreGuiInset===true;
  if(ignore) state.inset=0;
  $("#insetInput").value=state.inset;
 }
}

function walk(node,fn,parent=null){fn(node,parent);for(const c of node.Children||[])walk(c,fn,node)}
function findNode(id){let out=null;walk(state.root,n=>{if(n.__id===id)out=n});return out}
function findParent(id){let out=null;walk(state.root,(n,p)=>{if(n.__id===id)out=p});return out}
function selected(){return findNode(state.selectedId)}
function pushHistory(){
 if(!state.root)return;
 state.history.push(serialize(false));
 if(state.history.length>60)state.history.shift();
 state.future=[];
}
function restoreSnapshot(json){
 const raw=JSON.parse(json);state.root=normalizeNode(raw);state.selectedId=state.root.__id;state.dirty=true;renderAll()
}
function undo(){if(!state.history.length)return;state.future.push(serialize(false));restoreSnapshot(state.history.pop());toast("Undo")}
function redo(){if(!state.future.length)return;state.history.push(serialize(false));restoreSnapshot(state.future.pop());toast("Redo")}
function changed(){state.dirty=true;renderAll()}

function prop(node,key,fallback){return node?.Properties?.[key]??fallback}
function asUDim2(v,def=[[0,0],[0,0]]){
 if(v?.UDim2&&Array.isArray(v.UDim2))v=v.UDim2;
 if(Array.isArray(v)&&Array.isArray(v[0])&&Array.isArray(v[1])){
  return [
   [finite(v[0][0]),roundOffset(v[0][1])],
   [finite(v[1][0]),roundOffset(v[1][1])]
  ];
 }
 return deepClone(def);
}
function asUDim(v,def=[0,0]){
 if(v?.UDim&&Array.isArray(v.UDim))v=v.UDim;
 if(Array.isArray(v))return [finite(v[0]),roundOffset(v[1])];
 return deepClone(def);
}
function asVector2(v,def=[0,0]){
 if(v?.Vector2&&Array.isArray(v.Vector2))v=v.Vector2;
 if(Array.isArray(v))return [finite(v[0]),finite(v[1])];
 return deepClone(def);
}
function u2v(node,key,def=u2()){
 const fallback=asUDim2(def,[[0,0],[0,0]]);
 return asUDim2(prop(node,key,null),fallback);
}
function udv(node,key,def=ud()){
 const fallback=asUDim(def,[0,0]);
 return asUDim(prop(node,key,null),fallback);
}
function v2v(node,key,def=v2()){
 const fallback=asVector2(def,[0,0]);
 return asVector2(prop(node,key,null),fallback);
}
function color(v,trans=0){
 const a=clamp(1-finite(trans),0,1);const c=Array.isArray(v)?v:[1,1,1];
 return `rgba(${Math.round(clamp(c[0],0,1)*255)},${Math.round(clamp(c[1],0,1)*255)},${Math.round(clamp(c[2],0,1)*255)},${a})`;
}
function colorHex(v){
 const c=Array.isArray(v)?v:[1,1,1];
 return "#"+c.slice(0,3).map(x=>Math.round(clamp(x,0,1)*255).toString(16).padStart(2,"0")).join("");
}
function hexColor(h){const x=h.replace("#","");return [0,2,4].map(i=>parseInt(x.slice(i,i+2),16)/255)}
function cssUDim2(v,axis){const a=v?.UDim2||v||[[0,0],[0,0]];const p=axis===0?a[0]:a[1];return `calc(${finite(p[0])*100}% + ${roundOffset(p[1])}px)`}

function layoutChildNodes(n){return (n.Children||[]).filter(x=>!MODIFIERS.has(x.ClassName))}
function modifier(n,kind){return (n.Children||[]).find(x=>x.ClassName===kind)}
function getPadding(n){
 const p=modifier(n,"UIPadding");if(!p)return null;
 return {
  l:udv(p,"PaddingLeft")[1],r:udv(p,"PaddingRight")[1],
  t:udv(p,"PaddingTop")[1],b:udv(p,"PaddingBottom")[1]
 };
}
function imageUrl(src){
 if(!src)return "";
 const s=String(src).trim();
 const m=
  s.match(/rbxthumb:\/\/[^?]*\?[^#]*\bid=(\d+)/i)||
  s.match(/rbxthumb:\/\/.*?\bid=(\d+)/i)||
  s.match(/rbxassetid:\/\/(\d+)/i)||
  s.match(/[?&]id=(\d+)/i)||
  s.match(/^(\d{6,})$/);
 if(!m)return /^https?:\/\//i.test(s)?s:"";
 return `/api/thumbnail?id=${encodeURIComponent(m[1])}`;
}


const PREVIEW_DATA={
 currency:{Coins:"152",Honey:"68",Hive:"3",PetalDust:"1,240",AncientNectar:"7"},
 roulette:{
  Next:{name:"Розовый пион",chance:"1 / 50",image:"rbxthumb://type=Asset&id=111742972197656&w=420&h=420"},
  Current:{name:"Ромашка",chance:"1 / 25",image:"rbxthumb://type=Asset&id=117046422836136&w=420&h=420"},
  Previous:{name:"Василёк",chance:"1 / 100",image:"rbxthumb://type=Asset&id=131527836752075&w=420&h=420"}
 },
 seeds:[
  ["Ромашка","x2","117046422836136"],["Пион","x1","111742972197656"],["Василёк","x3","131527836752075"],["Лотос","x1","117046422836136"],
  ["Лаванда","x2","111742972197656"],["Тюльпан","x1","131527836752075"],["Лилия","x4","117046422836136"],["Сакура","x1","111742972197656"],
  ["Подсолнух","x2","117046422836136"],["Роза","x1","131527836752075"],["Гортензия","x1","111742972197656"],["Клевер","x5","117046422836136"]
 ]
};
function isPreview(){return state.mode==="preview"}
function parentName(n){return findParent(n.__id)?.Name||""}
function previewVisible(n){
 if(!isPreview())return null;
 const name=n.Name||"",p=parentName(n);
 if(name==="Templates"||p==="Templates"||name==="Tooltip")return false;
 if(["ObjectiveCard","CurrencyHUD","MenuDock","RollHUD","VerticalRoulette","RollButton"].includes(name))return true;
 if(name==="MainPanel")return state.previewScene==="seedbag";
 if(name==="RewardReveal")return state.previewScene==="reward";
 if(name==="Toast")return state.previewScene==="toast";
 if(name==="ModalShade"||name==="TutorialGuideBanner")return false;
 return null;
}
function previewText(n,parentNode){
 if(!isPreview())return null;
 const name=n.Name||"",p=parentNode?.Name||parentName(n);
 if(name==="ObjectiveTitle")return "ОБУЧЕНИЕ • 1/8";
 if(name==="ObjectiveText")return "Заполни Bloom и сделай особый roll";
 if(name==="MeterLabel")return "BLOOM  38%  •  DISCOVERY  3/30";
 if(name==="RollButton"){if(Object.prototype.hasOwnProperty.call(n.Properties||{},"Text")&&(n.Properties.Text??"")==="")return "";return "СДЕЛАТЬ ROLL"}
 if(name==="PanelTitle"&&state.previewScene==="seedbag")return "Сумка семян";
 if(name==="PanelSubtitle"&&state.previewScene==="seedbag")return "Собирай, сажай и выращивай редкие цветы";
 if(name==="RewardTitle"&&state.previewScene==="reward")return "Ромашка";
 if(name==="RewardMeta"&&state.previewScene==="reward")return "Обычный • 1/25 • Новый";
 if(name==="ToastLabel"&&state.previewScene==="toast")return "+24 Petal Dust";
 if(name==="Value"&&PREVIEW_DATA.currency[p]!=null)return PREVIEW_DATA.currency[p];
 if(name==="Name"&&PREVIEW_DATA.roulette[p])return PREVIEW_DATA.roulette[p].name;
 if(name==="Chance"&&PREVIEW_DATA.roulette[p])return PREVIEW_DATA.roulette[p].chance;
 return null;
}
function previewImage(n,parentNode){
 if(!isPreview())return null;
 const name=n.Name||"",p=parentNode?.Name||parentName(n);
 if(name==="RewardIcon"&&state.previewScene==="reward")return "rbxthumb://type=Asset&id=117046422836136&w=420&h=420";
 if(name==="Icon"&&PREVIEW_DATA.roulette[p])return PREVIEW_DATA.roulette[p].image;
 return null;
}
function previewSize(n){
 if(!isPreview())return null;
 if(n.Name==="ObjectiveProgressFill")return [[.38,0],[1,0]];
 if(n.Name==="BloomFill")return [[.38,0],[1,0]];
 return null;
}
function injectRuntimePreview(n,el,parentNode){
 if(!isPreview())return;
 if(n.Name==="Content"&&parentNode?.Name==="MainPanel"&&state.previewScene==="seedbag"){
  const wrap=document.createElement("div");wrap.className="preview-runtime";
  const img=id=>`/api/thumbnail?id=${id}`;
  wrap.innerHTML=`
   <div class="preview-seedbag">
    <div class="preview-seed-left">
     <div class="preview-filters">
      <span class="preview-chip active">Все (12)</span><span class="preview-chip">Обычные</span><span class="preview-chip">Редкие</span><span class="preview-chip">Эпические</span>
     </div>
     <div class="preview-grid">
      ${PREVIEW_DATA.seeds.map((s,i)=>`<div class="preview-tile ${i===0?"selected":""}"><span class="preview-count">${s[1]}</span><img src="${img(s[2])}"><strong>${s[0]}</strong></div>`).join("")}
     </div>
    </div>
    <div class="preview-seed-detail">
     <div class="preview-detail-head"><img src="${img("117046422836136")}"><div><h3>Ромашка</h3><small>ОБЫЧНЫЙ • УРОВЕНЬ 2</small></div></div>
     <p class="preview-desc">Нежный полевой цветок. Мастерство 1 • шанс 1/25.</p>
     <div class="preview-action primary">Посадить</div>
     <div class="preview-action">★ В избранное</div>
     <div class="preview-action">🔒 Запретить дубликат</div>
     <div class="preview-action success">Преобразовать дубликаты</div>
    </div>
   </div>`;
  el.appendChild(wrap);
 }
}


function setZoom(value,save=true){
 state.zoom=clamp(value,.25,1.5);
 $("#zoomRange").value=Math.round(state.zoom*100);
 $("#zoomLabel").textContent=Math.round(state.zoom*100)+"%";
 renderAll();if(save)savePrefs();
}
function fitViewport(){
 const pad=128,w=Math.max(100,els.stageScroller.clientWidth-pad),h=Math.max(100,els.stageScroller.clientHeight-pad);
 setZoom(Math.min(w/state.viewport.w,h/state.viewport.h,1.5));
 els.stageScroller.scrollLeft=0;els.stageScroller.scrollTop=0;
 toast("Viewport вписан в рабочую область");
}
function focusSelected(){
 const n=selected();if(!n)return;
 const el=els.guiRoot.querySelector(`[data-id="${n.__id}"]`);
 if(!el){toast("Выбранный объект сейчас не отображается",true);return}
 el.scrollIntoView({behavior:"smooth",block:"center",inline:"center"});
}
function copySelectedObject(){
 const n=selected();if(!n||n===state.root)return;
 state.clipboard=stripNode(n);toast(n.Name+" скопирован");
}
function pasteObject(){
 if(!state.clipboard)return toast("Буфер объектов пуст",true);
 let parent=selected();
 if(!parent||!CONTAINERS.has(parent.ClassName))parent=findParent(state.selectedId)||state.root;
 if(parent===state.root){const safe=(state.root.Children||[]).find(x=>x.Name==="SafeRoot");if(safe)parent=safe}
 pushHistory();
 const copy=normalizeNode(deepClone(state.clipboard));copy.Name=uniqueName(copy.Name||copy.ClassName);
 const pos=u2v(copy,"Position");pos[0][1]+=12;pos[1][1]+=12;copy.Properties.Position={UDim2:pos};
 parent.Children=parent.Children||[];parent.Children.push(copy);state.selectedId=copy.__id;changed();toast(copy.Name+" вставлен");
}
function renameSelected(){
 const n=selected();if(!n)return;
 const value=prompt("Имя Roblox Instance:",n.Name);if(value==null)return;
 const name=value.trim();if(!name||name===n.Name)return;
 pushHistory();n.Name=name;changed();
}


const GEOM_TOLERANCE=6;
function localRect(el){
 if(!el)return null;
 const dr=els.device.getBoundingClientRect(),rr=el.getBoundingClientRect(),z=state.zoom||1;
 const left=(rr.left-dr.left)/z,top=(rr.top-dr.top)/z,w=rr.width/z,h=rr.height/z;
 return {left,top,right:left+w,bottom:top+h,w,h,cx:left+w/2,cy:top+h/2};
}
function renderGeometryBase(){
 const g=els.geometry;if(!g)return;
 g.innerHTML="";g.classList.toggle("off",!state.geometry);
 if(!state.geometry)return;
 const corner=document.createElement("div");corner.className="geom-corner";g.appendChild(corner);
 const top=document.createElement("div");top.className="geom-ruler top";
 const left=document.createElement("div");left.className="geom-ruler left";
 const step=state.viewport.w>=1800?200:100;
 for(let x=0;x<=state.viewport.w;x+=step){
  const t=document.createElement("span");t.className="geom-tick";t.style.left=x+"px";t.textContent=x;top.appendChild(t)
 }
 for(let y=0;y<=state.viewport.h;y+=step){
  const t=document.createElement("span");t.className="geom-tick";t.style.top=y+"px";t.textContent=y;left.appendChild(t)
 }
 g.appendChild(top);g.appendChild(left);
 const vx=document.createElement("div");vx.className="geom-axis vertical";vx.style.left=(state.viewport.w/2)+"px";g.appendChild(vx);
 const hy=document.createElement("div");hy.className="geom-axis horizontal";hy.style.top=(state.viewport.h/2)+"px";g.appendChild(hy);
 if(state.inset>0){
  const safe=document.createElement("div");safe.className="geom-safe";safe.style.top=state.inset+"px";safe.innerHTML="<span>Inset "+state.inset+"px</span>";g.appendChild(safe)
 }
}
function clearSmartGuides(){
 if(!els.geometry)return;
 els.geometry.querySelectorAll(".geom-smart").forEach(x=>x.remove());
}
function showSmartGuides(xInfo,yInfo){
 if(!state.geometry||!els.geometry)return;
 clearSmartGuides();
 if(xInfo){
  const l=document.createElement("div");l.className="geom-smart vertical";l.style.left=xInfo.value+"px";
  l.innerHTML='<span class="geom-guide-label">'+esc(xInfo.label||Math.round(xInfo.value)+"px")+'</span>';els.geometry.appendChild(l)
 }
 if(yInfo){
  const l=document.createElement("div");l.className="geom-smart horizontal";l.style.top=yInfo.value+"px";
  l.innerHTML='<span class="geom-guide-label">'+esc(yInfo.label||Math.round(yInfo.value)+"px")+'</span>';els.geometry.appendChild(l)
 }
}
function addMeasureLine(x1,y1,x2,y2,label){
 if(!els.geometry)return;
 const line=document.createElement("div"),lab=document.createElement("div");
 const horizontal=Math.abs(y2-y1)<=Math.abs(x2-x1);
 line.className="geom-measure-line "+(horizontal?"horizontal":"vertical");
 if(horizontal){line.style.left=Math.min(x1,x2)+"px";line.style.top=y1+"px";line.style.width=Math.abs(x2-x1)+"px"}
 else{line.style.left=x1+"px";line.style.top=Math.min(y1,y2)+"px";line.style.height=Math.abs(y2-y1)+"px"}
 lab.className="geom-measure-label";lab.textContent=Math.max(0,Math.round(label))+" px";
 lab.style.left=((x1+x2)/2)+"px";lab.style.top=((y1+y2)/2)+"px";
 els.geometry.appendChild(line);els.geometry.appendChild(lab)
}
function updateGeometrySelection(){
 if(!els.geometry)return;
 els.geometry.querySelectorAll(".geom-measure-line,.geom-measure-label,.geom-size-badge").forEach(x=>x.remove());
 if(!state.geometry)return;
 const n=selected();if(!n||n===state.root||MODIFIERS.has(n.ClassName))return;
 const el=els.guiRoot.querySelector(`[data-id="${n.__id}"]`);if(!el||el.style.display==="none")return;
 const r=localRect(el),parent=findParent(n.__id);
 let pel=parent&&parent!==state.root?els.guiRoot.querySelector(`[data-id="${parent.__id}"]`):els.guiRoot;
 const pr=localRect(pel);if(!r||!pr)return;
 const badge=document.createElement("div");badge.className="geom-size-badge";badge.textContent=Math.round(r.w)+" × "+Math.round(r.h);
 badge.style.left=(r.right+8)+"px";badge.style.top=(r.bottom+8)+"px";els.geometry.appendChild(badge);
 const dl=Math.max(0,r.left-pr.left),dr=Math.max(0,pr.right-r.right),dt=Math.max(0,r.top-pr.top),db=Math.max(0,pr.bottom-r.bottom);
 if(dl>=4)addMeasureLine(pr.left,r.cy,r.left,r.cy,dl);
 if(dr>=4)addMeasureLine(r.right,r.cy,pr.right,r.cy,dr);
 if(dt>=4)addMeasureLine(r.cx,pr.top,r.cx,r.top,dt);
 if(db>=4)addMeasureLine(r.cx,r.bottom,r.cx,pr.bottom,db);
}
function collectGuideTargets(n){
 const el=els.guiRoot.querySelector(`[data-id="${n.__id}"]`);if(!el)return null;
 const base=localRect(el),parent=findParent(n.__id);
 let pel=parent&&parent!==state.root?els.guiRoot.querySelector(`[data-id="${parent.__id}"]`):els.guiRoot;
 const pr=localRect(pel);if(!base||!pr)return null;
 const xs=[
  {value:pr.left,label:"Parent L"},{value:pr.cx,label:"Parent CX"},{value:pr.right,label:"Parent R"},
  {value:state.viewport.w/2,label:"Viewport CX"}
 ];
 const ys=[
  {value:pr.top,label:"Parent T"},{value:pr.cy,label:"Parent CY"},{value:pr.bottom,label:"Parent B"},
  {value:state.viewport.h/2,label:"Viewport CY"}
 ];
 for(const s of parent?.Children||[]){
  if(s===n||MODIFIERS.has(s.ClassName))continue;
  const se=els.guiRoot.querySelector(`[data-id="${s.__id}"]`);if(!se||se.style.display==="none")continue;
  const r=localRect(se);if(!r)continue;
  xs.push({value:r.left,label:s.Name+" L"},{value:r.cx,label:s.Name+" CX"},{value:r.right,label:s.Name+" R"});
  ys.push({value:r.top,label:s.Name+" T"},{value:r.cy,label:s.Name+" CY"},{value:r.bottom,label:s.Name+" B"});
 }
 return {base,xs,ys};
}
function nearestGuide(candidates,targets){
 let best=null;
 for(const c of candidates)for(const t of targets){
  const delta=t.value-c.value,ad=Math.abs(delta);
  if(ad<=GEOM_TOLERANCE&&(!best||ad<best.ad))best={delta,ad,target:t,candidate:c}
 }
 return best;
}
function smartSnapMove(geom,rx,ry){
 if(!state.geometry||!geom)return {rx,ry,x:null,y:null};
 const b=geom.base;
 const bx=nearestGuide([{value:b.left+rx},{value:b.cx+rx},{value:b.right+rx}],geom.xs);
 const by=nearestGuide([{value:b.top+ry},{value:b.cy+ry},{value:b.bottom+ry}],geom.ys);
 if(bx)rx+=bx.delta;if(by)ry+=by.delta;
 return {rx,ry,x:bx?.target||null,y:by?.target||null};
}
function smartSnapResize(d,rx,ry){
 if(!state.geometry||!d.geometry)return {rx,ry,x:null,y:null};
 let bx=null,by=null,b=d.geometry.base;
 if(d.dir.includes("e"))bx=nearestGuide([{value:b.right+rx}],d.geometry.xs);
 else if(d.dir.includes("w"))bx=nearestGuide([{value:b.left+rx}],d.geometry.xs);
 if(d.dir.includes("s"))by=nearestGuide([{value:b.bottom+ry}],d.geometry.ys);
 else if(d.dir.includes("n"))by=nearestGuide([{value:b.top+ry}],d.geometry.ys);
 if(bx)rx+=bx.delta;if(by)ry+=by.delta;
 return {rx,ry,x:bx?.target||null,y:by?.target||null};
}
function alignSelected(mode){
 const n=selected();if(!n||n===state.root||MODIFIERS.has(n.ClassName))return;
 const el=els.guiRoot.querySelector(`[data-id="${n.__id}"]`);if(!el)return;
 const r=localRect(el),a=v2v(n,"AnchorPoint",[0,0]),p=deepClone(u2v(n,"Position"));
 const map={
  tl:["left","top"],tc:["center","top"],tr:["right","top"],
  ml:["left","middle"],mc:["center","middle"],mr:["right","middle"],
  bl:["left","bottom"],bc:["center","bottom"],br:["right","bottom"]
 };
 const target=map[mode];if(!target)return;
 pushHistory();
 const x=m=>{if(m==="left")p[0]=[0,roundOffset(a[0]*r.w)];if(m==="center")p[0]=[.5,roundOffset((a[0]-.5)*r.w)];if(m==="right")p[0]=[1,roundOffset((a[0]-1)*r.w)]};
 const y=m=>{if(m==="top")p[1]=[0,roundOffset(a[1]*r.h)];if(m==="middle")p[1]=[.5,roundOffset((a[1]-.5)*r.h)];if(m==="bottom")p[1]=[1,roundOffset((a[1]-1)*r.h)]};
 x(target[0]);y(target[1]);
 n.Properties.Position={UDim2:p};changed();
}
function geometryInspectorGroup(){
 return group("GEOMETRY",[
  '<div class="align-tools align-grid-3x3">'+
   '<button data-align="tl" title="Левый верхний угол">↖</button>'+
   '<button data-align="tc" title="По центру сверху">↑</button>'+
   '<button data-align="tr" title="Правый верхний угол">↗</button>'+
   '<button data-align="ml" title="Слева по центру">←</button>'+
   '<button data-align="mc" title="Точно по центру">●</button>'+
   '<button data-align="mr" title="Справа по центру">→</button>'+
   '<button data-align="bl" title="Левый нижний угол">↙</button>'+
   '<button data-align="bc" title="По центру снизу">↓</button>'+
   '<button data-align="br" title="Правый нижний угол">↘</button>'+
  '</div><div class="align-help">Кнопки повторяют положение объекта внутри родителя. Smart snap работает при drag/resize. Alt временно отключает магнит.</div>'
 ]);
}

function hasDrawableGui(){
 let count=0;
 walk(state.root,n=>{
  if(n===state.root||MODIFIERS.has(n.ClassName))return;
  if(n.ClassName==="Frame"&&n.Name==="SafeRoot")return;
  if(state.showHidden||n.Properties?.Visible!==false)count++;
 });
 return count>0;
}
function updateEmptyCanvas(){
 const box=$("#emptyCanvas");if(!box)return;
 box.classList.toggle("hidden",hasDrawableGui());
}
function renderAll(){
 renderViewport();renderTree();renderInspector();updateOverlay();updateStatus();updateEmptyCanvas();
}
function renderViewport(){
 if(!state.root)return;
 const fullW=state.viewport.w,fullH=state.viewport.h;
 els.device.style.width=fullW+"px";els.device.style.height=fullH+"px";
 els.device.style.transform=`scale(${state.zoom})`;
 $("#stage").style.width=(fullW*state.zoom+128)+"px";
 $("#stage").style.height=(fullH*state.zoom+128)+"px";
 $(".roblox-topbar").style.height=state.inset+"px";
 $(".roblox-topbar").style.display=state.inset>0?"flex":"none";
 els.guiRoot.style.top=state.inset+"px";
 els.guiRoot.innerHTML="";
 if(isPreview()){
  const wm=document.createElement("div");wm.className="preview-mode-watermark";wm.textContent="RUNTIME PREVIEW · "+state.previewScene.toUpperCase();els.guiRoot.appendChild(wm);
 }
 const children=state.root.ClassName==="ScreenGui"?state.root.Children:[state.root];
 for(const c of children) if(!MODIFIERS.has(c.ClassName)) renderGuiNode(c,els.guiRoot,null);
 renderGeometryBase();
}
function renderGuiNode(n,parentEl,parentNode){
 const el=document.createElement("div");el.className="gui-node";el.dataset.id=n.__id;el.dataset.class=n.ClassName;
 const p=n.Properties||{};
 const runtimeSize=previewSize(n);
 const renderSize=runtimeSize?{UDim2:runtimeSize}:(p.Size||u2(0,100,0,100));
 el.style.width=cssUDim2(renderSize,0);
 el.style.height=cssUDim2(renderSize,1);
 el.style.left=cssUDim2(p.Position||u2(),0);el.style.top=cssUDim2(p.Position||u2(),1);
 const ap=v2v(n,"AnchorPoint",[0,0]);const rot=finite(p.Rotation,0);
 el.style.transform=`translate(${-ap[0]*100}%,${-ap[1]*100}%) rotate(${rot}deg)`;
 el.style.transformOrigin=`${ap[0]*100}% ${ap[1]*100}%`;
 el.style.zIndex=finite(p.ZIndex,1);
 const runtimeHidden=p.Visible===false;
 const forcedVisible=previewVisible(n);
 if(forcedVisible===false)el.style.display="none";
 else if(forcedVisible===true)el.style.display="";
 else if(runtimeHidden&&!state.showHidden)el.style.display="none";
 else{
  el.style.display="";
  if(runtimeHidden)el.classList.add("runtime-hidden");
 }
 el.style.overflow=p.ClipsDescendants?"hidden":"visible";
 el.style.background=color(p.BackgroundColor3||[1,1,1],p.BackgroundTransparency??0);
 if(p.BorderSizePixel>0){el.style.border=`${p.BorderSizePixel}px solid ${color(p.BorderColor3||[0,0,0],0)}`}
 const corner=modifier(n,"UICorner");
 if(corner){const cr=udv(corner,"CornerRadius",[0,8]);el.style.borderRadius=cr[0]?`${clamp(cr[0]*100,0,50)}%`:`${roundOffset(cr[1])}px`}
 const stroke=modifier(n,"UIStroke");
 if(stroke){
  const sp=stroke.Properties||{},th=Math.max(0,finite(sp.Thickness,1)),sc=color(sp.Color||[0,0,0],sp.Transparency??0);
  el.style.boxShadow=sp.ApplyStrokeMode==="Contextual"?`0 0 0 ${th}px ${sc}`:`inset 0 0 0 ${th}px ${sc},0 0 0 ${Math.max(0,th-1)}px ${sc}`;
 }
 const padding=getPadding(n);
 if(TEXT_CLASSES.has(n.ClassName)){
  const t=document.createElement("span");t.className="gui-text";const runtimeText=previewText(n,parentNode);t.textContent=runtimeText??p.Text??"";if(padding)t.style.inset=`${padding.t}px ${padding.r}px ${padding.b}px ${padding.l}px`;
  t.style.color=color(p.TextColor3||[1,1,1],p.TextTransparency??0);t.style.fontSize=finite(p.TextSize,14)+"px";
  t.style.fontWeight=/Bold|Black/i.test(p.Font||"")?"700":"400";
  t.style.fontFamily=/Code/i.test(p.Font||"")?"Consolas,monospace":"Gotham,Montserrat,Segoe UI,Arial,sans-serif";
  t.style.justifyContent=({Left:"flex-start",Center:"center",Right:"flex-end"})[p.TextXAlignment]||"flex-start";
  t.style.alignItems=({Top:"flex-start",Center:"center",Bottom:"flex-end"})[p.TextYAlignment]||"center";
  t.style.textAlign=({Left:"left",Center:"center",Right:"right"})[p.TextXAlignment]||"left";
  t.style.whiteSpace=p.TextWrapped===false?"nowrap":"pre-wrap";
  if(p.TextStrokeTransparency<1)t.style.textShadow=`0 0 1px ${color(p.TextStrokeColor3||[0,0,0],p.TextStrokeTransparency??1)}`;
  el.appendChild(t);
 }
 if(IMAGE_CLASSES.has(n.ClassName)){
  const runtimeImage=previewImage(n,parentNode);const resolved=imageUrl(runtimeImage??p.Image??"");
  if(resolved){
   const img=document.createElement("img");img.className="gui-image";img.draggable=false;img.src=resolved;
   img.style.opacity=1-clamp(finite(p.ImageTransparency,0),0,1);img.style.objectFit=p.ScaleType==="Crop"?"cover":p.ScaleType==="Stretch"?"fill":"contain";
   if(p.ImageColor3)img.style.filter="none";el.appendChild(img);
  }
 }
 if(state.labels){
  const tag=document.createElement("div");tag.className="node-tag";tag.textContent=`${n.Name} · ${n.ClassName}`;el.appendChild(tag)
 }
 if(n.__id===state.selectedId)el.classList.add("selected");
 el.addEventListener("pointerdown",ev=>startMove(ev,n));
 el.addEventListener("click",ev=>{ev.stopPropagation();select(n.__id)});
 parentEl.appendChild(el);

 const list=modifier(n,"UIListLayout"),grid=modifier(n,"UIGridLayout");
 let childHost=el;
 if(list||grid){
  childHost=document.createElement("div");
  childHost.className="layout-host "+(list?"list-layout":"grid-layout");
  if(padding){
   childHost.style.left=padding.l+"px";childHost.style.right=padding.r+"px";
   childHost.style.top=padding.t+"px";childHost.style.bottom=padding.b+"px";
  }
  el.appendChild(childHost);
 }
 if(list){
  childHost.style.flexDirection=prop(list,"FillDirection","Vertical")==="Horizontal"?"row":"column";
  const gap=udv(list,"Padding",[0,0]);childHost.style.gap=roundOffset(gap[1])+"px";
  childHost.style.alignItems=({Left:"flex-start",Center:"center",Right:"flex-end"})[prop(list,"HorizontalAlignment","Left")]||"stretch";
 }
 if(grid){
  const cs=u2v(grid,"CellSize",u2(0,64,0,64)),cp=u2v(grid,"CellPadding",u2(0,6,0,6));
  childHost.style.gridTemplateColumns=`repeat(auto-fill,${Math.max(1,roundOffset(cs[0][1]))}px)`;
  childHost.style.gridAutoRows=Math.max(1,roundOffset(cs[1][1]))+"px";
  childHost.style.columnGap=roundOffset(cp[0][1])+"px";childHost.style.rowGap=roundOffset(cp[1][1])+"px";
 }
 for(const c of layoutChildNodes(n)){
  const child=renderGuiNode(c,childHost,n);
  if((list||grid)&&child)child.classList.add("layout-child");
 }
 injectRuntimePreview(n,el,parentNode);
 return el;
}
els.guiRoot.addEventListener("pointerdown",ev=>{if(ev.target===els.guiRoot)select(state.root.__id)});

function renderTree(){
 els.tree.innerHTML="";if(!state.root)return;
 const q=state.treeQuery.trim().toLowerCase();
 const matched=new Set(),ancestors=new Set();
 if(q){
  const scan=(n,path=[])=>{
   const next=[...path,n];
   if((n.Name+" "+n.ClassName).toLowerCase().includes(q)){matched.add(n.__id);for(const a of path)ancestors.add(a.__id)}
   for(const c of n.Children||[])scan(c,next);
  };scan(state.root);
 }
 let shown=0;
 const recur=(n,depth)=>{
  if(q&&!matched.has(n.__id)&&!ancestors.has(n.__id))return;
  shown++;
  const row=document.createElement("div");row.className="tree-row"+(n.__id===state.selectedId?" selected":"")+(MODIFIERS.has(n.ClassName)?" modifier":"")+(n.Properties?.Visible===false?" runtime-hidden":"")+(matched.has(n.__id)?" search-match":"");
  const kids=n.Children||[],collapsed=state.collapsed.has(n.__id)&&!q;
  row.dataset.id=n.__id;row.innerHTML=`<span class="tree-indent" style="width:${depth*13}px"></span><span class="tree-toggle">${kids.length?(collapsed?"▸":"▾"):""}</span><span class="tree-icon">${classIcon(n.ClassName)}</span><span class="tree-name"></span><span class="tree-kind"></span>`;
  row.querySelector(".tree-name").textContent=n.Name;row.querySelector(".tree-kind").textContent=n.ClassName;
  row.querySelector(".tree-toggle").onclick=e=>{e.stopPropagation();collapsed?state.collapsed.delete(n.__id):state.collapsed.add(n.__id);renderTree()};
  row.ondblclick=()=>{select(n.__id);renameSelected()};
  row.onclick=()=>select(n.__id);els.tree.appendChild(row);
  if(!collapsed)for(const c of kids)recur(c,depth+1);
 };
 recur(state.root,0);
 $("#treeSearchMeta").textContent=q?(matched.size?matched.size+" совпад.":"Ничего не найдено"):"";
}
function classIcon(k){return ({ScreenGui:"▱",Frame:"▣",TextLabel:"T",TextButton:"▤",ImageLabel:"◈",ImageButton:"◇",ScrollingFrame:"↕",UICorner:"◜",UIStroke:"□",UIListLayout:"☷",UIGridLayout:"▦",UIPadding:"↔"})[k]||"·"}

function revealTreePath(id){
 let p=findParent(id);
 while(p){state.collapsed.delete(p.__id);p=findParent(p.__id)}
}
function scrollTreeToSelected(){
 requestAnimationFrame(()=>{
  const row=els.tree.querySelector(`.tree-row[data-id="${state.selectedId}"]`);
  if(row)row.scrollIntoView({block:"nearest",inline:"nearest"});
 });
}
function select(id){
 state.selectedId=id;revealTreePath(id);renderTree();renderInspector();updateOverlay();updateStatus();scrollTreeToSelected();
}
function updateOverlay(){
 const n=selected();if(!n||n===state.root||MODIFIERS.has(n.ClassName)){els.overlay.classList.add("hidden");updateGeometrySelection();return}
 const nodeEl=els.guiRoot.querySelector(`[data-id="${n.__id}"]`);if(!nodeEl||nodeEl.style.display==="none"){els.overlay.classList.add("hidden");updateGeometrySelection();return}
 const dr=els.device.getBoundingClientRect(),rr=nodeEl.getBoundingClientRect(),z=state.zoom;
 els.overlay.classList.remove("hidden");
 els.overlay.style.left=((rr.left-dr.left)/z)+"px";els.overlay.style.top=((rr.top-dr.top)/z)+"px";
 els.overlay.style.width=(rr.width/z)+"px";els.overlay.style.height=(rr.height/z)+"px";
 const lr=localRect(nodeEl);
 els.overlay.querySelector(".sel-caption").textContent=`${n.Name} · ${n.ClassName} · X ${Math.round(lr.left)} Y ${Math.round(lr.top)} · ${Math.round(lr.w)}×${Math.round(lr.h)}`;
 updateGeometrySelection();
}

function renderInspector(){
 const n=selected();if(!n){els.inspector.className="inspector empty";els.inspector.innerHTML='<div class="empty-state">Выбери объект.</div>';return}
 els.inspector.className="inspector";$("#selectionKind").textContent=n.ClassName;
 const groups=[];
 groups.push(group("INSTANCE",[
  textProp("Name",n.Name,v=>{n.Name=v;changed()}),
  readonly("Class",n.ClassName),
  ...(n.ClassName==="ScreenGui"?[]:[
   boolProp("Visible",prop(n,"Visible",true),v=>setProp(n,"Visible",v)),
   numProp("ZIndex",prop(n,"ZIndex",1),v=>setProp(n,"ZIndex",v))
  ])
 ]));
 if(n.ClassName==="ScreenGui"){
  groups.push(group("SCREENGUI",[
   boolProp("IgnoreGuiInset",prop(n,"IgnoreGuiInset",false),v=>{setProp(n,"IgnoreGuiInset",v);state.inset=v?0:36;$("#insetInput").value=state.inset;renderAll()}),
   boolProp("ResetOnSpawn",prop(n,"ResetOnSpawn",false),v=>setProp(n,"ResetOnSpawn",v)),
   numProp("DisplayOrder",prop(n,"DisplayOrder",0),v=>setProp(n,"DisplayOrder",v))
  ]));
 }else if(!MODIFIERS.has(n.ClassName)){
  groups.push(group("TRANSFORM",[
   udim2Prop("Position",u2v(n,"Position"),v=>setProp(n,"Position",{UDim2:v})),
   udim2Prop("Size",u2v(n,"Size",u2(0,100,0,100)),v=>setProp(n,"Size",{UDim2:v})),
   vector2Prop("AnchorPoint",v2v(n,"AnchorPoint"),v=>setProp(n,"AnchorPoint",{Vector2:v})),
   numProp("Rotation",prop(n,"Rotation",0),v=>setProp(n,"Rotation",v))
  ]));
  groups.push(geometryInspectorGroup());
   groups.push(group("APPEARANCE",[
   colorProp("Background",prop(n,"BackgroundColor3",[1,1,1]),v=>setProp(n,"BackgroundColor3",v)),
   numProp("Transparency",prop(n,"BackgroundTransparency",0),v=>setProp(n,"BackgroundTransparency",clamp(v,0,1)),.01),
   numProp("Border",prop(n,"BorderSizePixel",0),v=>setProp(n,"BorderSizePixel",Math.max(0,v))),
   boolProp("Clips",prop(n,"ClipsDescendants",false),v=>setProp(n,"ClipsDescendants",v))
  ]));
 }
 if(TEXT_CLASSES.has(n.ClassName))groups.push(group("TEXT",[
  textareaProp("Text",prop(n,"Text",""),v=>setProp(n,"Text",v)),
  numProp("TextSize",prop(n,"TextSize",14),v=>setProp(n,"TextSize",v)),
  colorProp("TextColor",prop(n,"TextColor3",[1,1,1]),v=>setProp(n,"TextColor3",v)),
  selectProp("Align X",prop(n,"TextXAlignment","Left"),["Left","Center","Right"],v=>setProp(n,"TextXAlignment",v)),
  selectProp("Align Y",prop(n,"TextYAlignment","Center"),["Top","Center","Bottom"],v=>setProp(n,"TextYAlignment",v)),
  boolProp("Wrapped",prop(n,"TextWrapped",true),v=>setProp(n,"TextWrapped",v)),
  textProp("Font",prop(n,"Font","Gotham"),v=>setProp(n,"Font",v))
 ]));
 if(IMAGE_CLASSES.has(n.ClassName))groups.push(group("IMAGE",[
  textProp("Image",prop(n,"Image",""),v=>setProp(n,"Image",v)),
  numProp("Transparency",prop(n,"ImageTransparency",0),v=>setProp(n,"ImageTransparency",clamp(v,0,1)),.01),
  selectProp("ScaleType",prop(n,"ScaleType","Fit"),["Fit","Crop","Stretch","Tile","Slice"],v=>setProp(n,"ScaleType",v))
 ]));
 if(n.ClassName==="UICorner")groups.push(group("UICORNER",[udimProp("CornerRadius",udv(n,"CornerRadius",[0,8]),v=>setProp(n,"CornerRadius",{UDim:v}))]));
 if(n.ClassName==="UIStroke")groups.push(group("UISTROKE",[
  colorProp("Color",prop(n,"Color",[0,0,0]),v=>setProp(n,"Color",v)),numProp("Thickness",prop(n,"Thickness",1),v=>setProp(n,"Thickness",v),.5),
  numProp("Transparency",prop(n,"Transparency",0),v=>setProp(n,"Transparency",clamp(v,0,1)),.01),selectProp("Mode",prop(n,"ApplyStrokeMode","Border"),["Border","Contextual"],v=>setProp(n,"ApplyStrokeMode",v))
 ]));
 if(n.ClassName==="UIListLayout")groups.push(group("LIST LAYOUT",[
  selectProp("Direction",prop(n,"FillDirection","Vertical"),["Vertical","Horizontal"],v=>setProp(n,"FillDirection",v)),
  udimProp("Padding",udv(n,"Padding",[0,0]),v=>setProp(n,"Padding",{UDim:v})),
  selectProp("H Align",prop(n,"HorizontalAlignment","Left"),["Left","Center","Right"],v=>setProp(n,"HorizontalAlignment",v))
 ]));
 if(n.ClassName==="UIGridLayout")groups.push(group("GRID LAYOUT",[
  udim2Prop("CellSize",u2v(n,"CellSize",u2(0,64,0,64)),v=>setProp(n,"CellSize",{UDim2:v})),
  udim2Prop("CellPadding",u2v(n,"CellPadding",u2(0,6,0,6)),v=>setProp(n,"CellPadding",{UDim2:v}))
 ]));
 if(n.ClassName==="UIPadding")groups.push(group("PADDING",["PaddingLeft","PaddingRight","PaddingTop","PaddingBottom"].map(k=>udimProp(k,udv(n,k,[0,0]),v=>setProp(n,k,{UDim:v})))));
 if(!MODIFIERS.has(n.ClassName)&&n!==state.root)groups.push(computedGroup(n));
 groups.push(rawGroup(n));
 els.inspector.innerHTML=groups.join("");
 bindInspectorHandlers(n);
}
function group(title,rows){return `<section class="ins-group"><div class="ins-title">${title}</div><div class="ins-body">${rows.join("")}</div></section>`}
function row(label,html){return `<div class="prop-row"><label>${label}</label>${html}</div>`}
let handlerSeq=1,handlers={};
function h(fn){const id="h"+handlerSeq++;handlers[id]=fn;return id}
function textProp(l,v,fn){return row(l,`<input data-handler="${h(fn)}" value="${esc(v)}">`)}
function textareaProp(l,v,fn){return row(l,`<textarea data-handler="${h(fn)}">${esc(v)}</textarea>`)}
function readonly(l,v){return row(l,`<input value="${esc(v)}" disabled>`)}
function numProp(l,v,fn,step=1){return row(l,`<input type="number" step="${step}" data-handler="${h(fn)}" value="${finite(v)}">`)}
function boolProp(l,v,fn){return row(l,`<input type="checkbox" data-handler="${h(fn)}" ${v?"checked":""}>`)}
function selectProp(l,v,opts,fn){return row(l,`<select data-handler="${h(fn)}">${opts.map(o=>`<option ${o===v?"selected":""}>${o}</option>`).join("")}</select>`)}
function colorProp(l,v,fn){return row(l,`<input type="color" data-handler="${h(fn)}" value="${colorHex(v)}">`)}
function udim2Prop(l,v,fn){
 const id=h(fn);return row(l,`<div class="quad" data-udim2-handler="${id}"><input type="number" step=".01" value="${v[0][0]}" title="X Scale"><input type="number" value="${v[0][1]}" title="X Offset"><input type="number" step=".01" value="${v[1][0]}" title="Y Scale"><input type="number" value="${v[1][1]}" title="Y Offset"></div>`)
}
function vector2Prop(l,v,fn){const id=h(fn);return row(l,`<div class="xy" data-v2-handler="${id}"><input type="number" step=".01" value="${v[0]}"><input type="number" step=".01" value="${v[1]}"></div>`)}
function udimProp(l,v,fn){const id=h(fn);return row(l,`<div class="xy" data-udim-handler="${id}"><input type="number" step=".01" value="${v[0]}"><input type="number" value="${v[1]}"></div>`)}
function computedGroup(n){
 setTimeout(updatePixelReadout,0);
 return group("COMPUTED PIXELS",[`<div id="computedBox" class="computed"><div><small>X</small><strong>—</strong></div><div><small>Y</small><strong>—</strong></div><div><small>W</small><strong>—</strong></div><div><small>H</small><strong>—</strong></div></div>`])
}
function rawGroup(n){return group("RAW PROPERTIES",[`<textarea id="rawProps" class="raw-json" spellcheck="false">${esc(JSON.stringify(n.Properties||{},null,2))}</textarea><button id="applyRaw" class="btn">Применить свойства</button>`])}
function esc(x){return String(x??"").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/"/g,"&quot;")}
function bindInspectorHandlers(n){
 els.inspector.querySelectorAll("[data-handler]").forEach(input=>{
  input.addEventListener("change",()=>{pushHistory();const fn=handlers[input.dataset.handler];fn(input.type==="checkbox"?input.checked:input.type==="number"?finite(input.value):input.type==="color"?hexColor(input.value):input.value)})
 });
 els.inspector.querySelectorAll("[data-udim2-handler]").forEach(box=>box.addEventListener("change",()=>{pushHistory();const a=[...box.querySelectorAll("input")].map(x=>finite(x.value));handlers[box.dataset.udim2Handler]([[a[0],roundOffset(a[1])],[a[2],roundOffset(a[3])]])}));
 els.inspector.querySelectorAll("[data-v2-handler]").forEach(box=>box.addEventListener("change",()=>{pushHistory();const a=[...box.querySelectorAll("input")].map(x=>finite(x.value));handlers[box.dataset.v2Handler]([a[0],a[1]])}));
 els.inspector.querySelectorAll("[data-udim-handler]").forEach(box=>box.addEventListener("change",()=>{pushHistory();const a=[...box.querySelectorAll("input")].map(x=>finite(x.value));handlers[box.dataset.udimHandler]([a[0],roundOffset(a[1])])}));
 $("#applyRaw")?.addEventListener("click",()=>{
  try{
   const next=JSON.parse($("#rawProps").value);
   if(TEXT_CLASSES.has(n.ClassName)&&!Object.prototype.hasOwnProperty.call(next,"Text"))next.Text="";
   pushHistory();n.Properties=next;changed();toast("Свойства применены");
  }catch(e){toast("Неверный JSON свойств",true)}
 });
 els.inspector.querySelectorAll("[data-align]").forEach(b=>b.addEventListener("click",()=>alignSelected(b.dataset.align)));
}
function setProp(n,k,v){n.Properties=n.Properties||{};n.Properties[k]=v;changed()}

function updatePixelReadout(){
 const n=selected(),nodeEl=n&&els.guiRoot.querySelector(`[data-id="${n.__id}"]`),box=$("#computedBox");if(!n||!nodeEl)return;
 const dr=els.guiRoot.getBoundingClientRect(),rr=nodeEl.getBoundingClientRect(),z=state.zoom;
 const vals=[(rr.left-dr.left)/z,(rr.top-dr.top)/z,rr.width/z,rr.height/z].map(x=>Math.round(x*10)/10);
 els.pixels.textContent=`X ${vals[0]}  Y ${vals[1]}  W ${vals[2]}  H ${vals[3]}`;
 if(box)[...box.querySelectorAll("strong")].forEach((s,i)=>s.textContent=vals[i]);
}
function updateStatus(){
 const n=selected();const mode=isPreview()?`PREVIEW · ${state.previewScene} · mock data`:(state.projectHandle?"Project connected":"Design");els.status.textContent=(state.dirty?"● ":"")+mode+" · "+(n?`${n.Name} [${n.ClassName}]`:"");
 els.target.textContent=state.targetPath;
}

function isLayoutParent(n){return !!n&&(modifier(n,"UIListLayout")||modifier(n,"UIGridLayout"))}
function startMove(ev,n){
 if(ev.button!==0||MODIFIERS.has(n.ClassName))return;ev.stopPropagation();select(n.__id);
 if(isLayoutParent(findParent(n.__id))){toast("Позиция управляется Layout. Меняй размер или LayoutOrder.");return}
 pushHistory();
 const pos=deepClone(u2v(n,"Position")),startX=ev.clientX,startY=ev.clientY;
 state.drag={type:"move",n,startX,startY,pos,geometry:collectGuideTargets(n)};
 ev.currentTarget.setPointerCapture?.(ev.pointerId);
}
window.addEventListener("pointermove",ev=>{
 const d=state.drag;if(!d)return;const dx=(ev.clientX-d.startX)/state.zoom,dy=(ev.clientY-d.startY)/state.zoom,s=state.snap;
 if(d.type==="move"){
  let rx=Math.round(dx/s)*s,ry=Math.round(dy/s)*s,guide={rx,ry,x:null,y:null};
  if(!ev.altKey)guide=smartSnapMove(d.geometry,rx,ry);
  const p=deepClone(d.pos);p[0][1]=roundOffset(p[0][1]+guide.rx);p[1][1]=roundOffset(p[1][1]+guide.ry);
  d.n.Properties.Position={UDim2:p};renderViewport();updateOverlay();showSmartGuides(guide.x,guide.y);updatePixelReadout();state.dirty=true;updateStatus()
 }else if(d.type==="resize")resizeFromDrag(d,dx,dy,ev.altKey);
});
window.addEventListener("pointerup",()=>{if(state.drag){state.drag=null;clearSmartGuides();renderTree();renderInspector();updateGeometrySelection()}});

els.overlay.querySelectorAll("i").forEach(handle=>handle.addEventListener("pointerdown",ev=>{
 ev.stopPropagation();ev.preventDefault();const n=selected();if(!n)return;pushHistory();
 state.drag={type:"resize",n,dir:handle.dataset.dir,startX:ev.clientX,startY:ev.clientY,size:deepClone(u2v(n,"Size",u2(0,100,0,100))),pos:deepClone(u2v(n,"Position")),anchor:deepClone(v2v(n,"AnchorPoint")),geometry:collectGuideTargets(n)}
}));
function resizeFromDrag(d,dx,dy,bypassGuides=false){
 const dir=d.dir,s=state.snap;let rx=Math.round(dx/s)*s,ry=Math.round(dy/s)*s,guide={rx,ry,x:null,y:null};
 if(!bypassGuides)guide=smartSnapResize(d,rx,ry);
 rx=guide.rx;ry=guide.ry;
 const sz=deepClone(d.size),ps=deepClone(d.pos),a=d.anchor;
 const base=d.geometry?.base;
 const parent=findParent(d.n.__id);
 const parentEl=parent&&parent!==state.root?els.guiRoot.querySelector(`[data-id="${parent.__id}"]`):els.guiRoot;
 const pr=localRect(parentEl);
 const pw=Math.max(1,pr?.w||state.viewport.w),ph=Math.max(1,pr?.h||state.viewport.h);
 const baseW=Math.max(1,base?.w||(d.size[0][0]*pw+d.size[0][1]));
 const baseH=Math.max(1,base?.h||(d.size[1][0]*ph+d.size[1][1]));

 if(dir.includes("e")){
  const desiredW=Math.max(1,baseW+rx);
  const applied=desiredW-baseW;
  sz[0][1]=roundOffset(desiredW-d.size[0][0]*pw);
  ps[0][1]=roundOffset(d.pos[0][1]+applied*a[0]);
 }
 if(dir.includes("w")){
  const desiredW=Math.max(1,baseW-rx);
  const applied=baseW-desiredW;
  sz[0][1]=roundOffset(desiredW-d.size[0][0]*pw);
  ps[0][1]=roundOffset(d.pos[0][1]+applied*(1-a[0]));
 }
 if(dir.includes("s")){
  const desiredH=Math.max(1,baseH+ry);
  const applied=desiredH-baseH;
  sz[1][1]=roundOffset(desiredH-d.size[1][0]*ph);
  ps[1][1]=roundOffset(d.pos[1][1]+applied*a[1]);
 }
 if(dir.includes("n")){
  const desiredH=Math.max(1,baseH-ry);
  const applied=baseH-desiredH;
  sz[1][1]=roundOffset(desiredH-d.size[1][0]*ph);
  ps[1][1]=roundOffset(d.pos[1][1]+applied*(1-a[1]));
 }
 d.n.Properties.Size={UDim2:sz};d.n.Properties.Position={UDim2:ps};state.dirty=true;renderViewport();updateOverlay();showSmartGuides(guide.x,guide.y);updatePixelReadout();updateStatus();
}

function defaultObject(kind){
 const common={Size:u2(0,160,0,60),Position:u2(0,24,0,24),AnchorPoint:v2(0,0),BackgroundColor3:c3(.10,.14,.19),BackgroundTransparency:0,BorderSizePixel:0,ZIndex:1,Visible:true};
 const m={
  Frame:{...common},
  TextLabel:{...common,BackgroundTransparency:1,Text:"TextLabel",TextColor3:c3(1,1,1),TextSize:14,TextWrapped:true,TextXAlignment:"Center",TextYAlignment:"Center",Font:"Gotham"},
  TextButton:{...common,Text:"Button",TextColor3:c3(1,1,1),TextSize:14,TextWrapped:true,TextXAlignment:"Center",TextYAlignment:"Center",Font:"GothamBold",AutoButtonColor:false},
  ImageLabel:{...common,BackgroundTransparency:1,Image:"",ScaleType:"Fit"},
  ImageButton:{...common,BackgroundTransparency:1,Image:"",ScaleType:"Fit",AutoButtonColor:false},
  ScrollingFrame:{...common,Size:u2(0,280,0,220),CanvasSize:u2(0,0,0,500),ScrollBarThickness:6,ClipsDescendants:true},
  UICorner:{CornerRadius:ud(0,12)},
  UIStroke:{Color:c3(.05,.08,.12),Thickness:2,Transparency:.1,ApplyStrokeMode:"Border"},
  UIListLayout:{Padding:ud(0,6),FillDirection:"Vertical",HorizontalAlignment:"Left",SortOrder:"LayoutOrder"},
  UIGridLayout:{CellSize:u2(0,64,0,64),CellPadding:u2(0,6,0,6),SortOrder:"LayoutOrder"},
  UIPadding:{PaddingLeft:ud(0,8),PaddingRight:ud(0,8),PaddingTop:ud(0,8),PaddingBottom:ud(0,8)}
 };
 return normalizeNode({ClassName:kind,Name:uniqueName(kind),Properties:m[kind]||common,Children:[]});
}
function uniqueName(base){let i=1,name=base;const names=new Set();walk(state.root,n=>names.add(n.Name));while(names.has(name))name=base+(++i);return name}
function addObject(kind){
 if(!state.root)return;pushHistory();let parent=selected();
 if(parent===state.root){
  const safeRoot=(state.root.Children||[]).find(x=>x.Name==="SafeRoot"&&x.ClassName==="Frame");
  if(safeRoot)parent=safeRoot;
 }
 if(!parent||!CONTAINERS.has(parent.ClassName))parent=findParent(state.selectedId)||state.root;
 if(MODIFIERS.has(kind)&&parent.ClassName==="ScreenGui"){toast("Выбери GuiObject для "+kind,true);return}
 const n=defaultObject(kind);parent.Children=parent.Children||[];parent.Children.push(n);state.selectedId=n.__id;changed();toast(kind+" создан")
}
function deleteSelected(){
 const n=selected();if(!n||n===state.root)return;const p=findParent(n.__id);if(!p)return;pushHistory();p.Children=p.Children.filter(x=>x!==n);state.selectedId=p.__id;changed()
}
function duplicateSelected(){
 const n=selected();if(!n||n===state.root)return;const p=findParent(n.__id);pushHistory();const copy=normalizeNode(stripNode(n));copy.Name=uniqueName(n.Name);const pos=u2v(copy,"Position");if(pos){pos[0][1]+=12;pos[1][1]+=12;copy.Properties.Position={UDim2:pos}}p.Children.push(copy);state.selectedId=copy.__id;changed()
}

async function connectProject(){
 if(!window.showDirectoryPicker){toast("Нужен Chrome/Edge на localhost",true);return}
 try{
  state.projectHandle=await window.showDirectoryPicker({mode:"readwrite"});
  await saveHandle(state.projectHandle);updateStatus();toast("Проект подключён: "+state.projectHandle.name)
 }catch(e){if(e.name!=="AbortError")toast(e.message,true)}
}
async function getFile(path,create=false){
 if(!state.projectHandle)throw new Error("Сначала подключи C:\\Bloom_RNG");
 const parts=path.replace(/\\/g,"/").split("/").filter(Boolean),file=parts.pop();let dir=state.projectHandle;
 for(const part of parts)dir=await dir.getDirectoryHandle(part,{create});
 return dir.getFileHandle(file,{create});
}
async function pullProject(){
 try{const h=await getFile(state.targetPath,false),f=await h.getFile(),raw=JSON.parse(await f.text());setRoot(raw,"Загружено из Roblox/Rojo файла")}
 catch(e){toast("Не удалось прочитать: "+e.message,true)}
}
async function pushProject(){
 try{
  const h=await getFile(state.targetPath,true),w=await h.createWritable();await w.write(serialize(true)+"\n");await w.close();
  state.dirty=false;updateStatus();toast("Записано в "+state.targetPath+" — Rojo может синхронизировать")
 }catch(e){toast("Не удалось записать: "+e.message,true)}
}
function download(){
 const blob=new Blob([serialize(true)+"\n"],{type:"application/json"}),a=document.createElement("a");a.href=URL.createObjectURL(blob);a.download=(state.root?.Name||"BloomUI")+".model.json";a.click();URL.revokeObjectURL(a.href)
}
async function copyModel(){await navigator.clipboard.writeText(serialize(true));toast("Полная Roblox-модель скопирована для ChatGPT")}
function importFile(file){const r=new FileReader();r.onload=()=>{try{setRoot(JSON.parse(r.result),"JSON импортирован")}catch(e){toast(e.message,true)}};r.readAsText(file)}

function toast(msg,error=false){els.toast.textContent=msg;els.toast.style.borderColor=error?"#a94455":"#45617c";els.toast.classList.add("show");clearTimeout(toast.t);toast.t=setTimeout(()=>els.toast.classList.remove("show"),2600)}
async function saveHandle(handle){
 try{const db=await idb();const tx=db.transaction("kv","readwrite");tx.objectStore("kv").put(handle,"projectHandle")}catch{}
}
async function loadHandle(){
 try{const db=await idb();return await new Promise((res,rej)=>{const q=db.transaction("kv").objectStore("kv").get("projectHandle");q.onsuccess=()=>res(q.result);q.onerror=()=>rej(q.error)})}catch{return null}
}
function idb(){return new Promise((res,rej)=>{const q=indexedDB.open("BloomUIStudio",1);q.onupgradeneeded=()=>q.result.createObjectStore("kv");q.onsuccess=()=>res(q.result);q.onerror=()=>rej(q.error)})}

async function loadInitial(){
 state.projectHandle=await loadHandle();
 try{
  const r=await fetch("/src/StarterGui/BloomUI.model.json",{cache:"no-store"});
  if(r.ok){setRoot(await r.json(),"Текущий BloomUI открыт");return}
 }catch{}
 setRoot({ClassName:"ScreenGui",Name:"BloomUI",Properties:{ResetOnSpawn:false,IgnoreGuiInset:false,DisplayOrder:20,ZIndexBehavior:"Sibling"},Children:[]},"Новая модель")
}

$("#palette").addEventListener("click",e=>{const b=e.target.closest("[data-add]");if(b)addObject(b.dataset.add)});
$("#createFirstFrame").onclick=()=>addObject("Frame");
$("#deleteBtn").onclick=deleteSelected;$("#duplicateBtn").onclick=duplicateSelected;
$("#connectBtn").onclick=connectProject;$("#pullBtn").onclick=pullProject;$("#pushBtn").onclick=pushProject;
$("#exportBtn").onclick=download;$("#copyBtn").onclick=copyModel;$("#importBtn").onclick=()=>els.fileInput.click();
els.fileInput.onchange=()=>els.fileInput.files[0]&&importFile(els.fileInput.files[0]);
$("#presetSelect").onchange=e=>{const [w,h]=e.target.value.split("x").map(Number);state.viewport={w,h};$("#viewportW").value=w;$("#viewportH").value=h;renderAll();savePrefs();fitViewport()};
$("#viewportW").onchange=e=>{state.viewport.w=Math.max(100,+e.target.value);renderAll();savePrefs()};$("#viewportH").onchange=e=>{state.viewport.h=Math.max(100,+e.target.value);renderAll();savePrefs()};
$("#zoomRange").oninput=e=>setZoom(+e.target.value/100);
$("#snapSelect").onchange=e=>{state.snap=+e.target.value;savePrefs()};
$("#labelsToggle").onchange=e=>{state.labels=e.target.checked;renderViewport();updateOverlay();savePrefs()};
$("#gridToggle").onchange=e=>{state.grid=e.target.checked;els.stageScroller.classList.toggle("no-grid",!state.grid);savePrefs()};
$("#geometryToggle").onchange=e=>{state.geometry=e.target.checked;renderViewport();updateOverlay();savePrefs();toast(state.geometry?"Geometry helpers включены":"Geometry helpers выключены")};
$("#hiddenToggle").onchange=e=>{state.showHidden=e.target.checked;renderViewport();renderTree();updateOverlay();toast(state.showHidden?"Скрытые Roblox-объекты показаны только в редакторе":"Скрытые Roblox-объекты спрятаны");savePrefs()};
$("#modeSelect").onchange=e=>{
 state.mode=e.target.value;
 $("#sceneSelect").disabled=!isPreview();
 $("#modeSelect").classList.toggle("preview-active",isPreview());
 renderAll();
 toast(isPreview()?"Runtime Preview включён — mock-данные не сохраняются":"Design mode — отображается файл как есть");savePrefs();
};
$("#sceneSelect").onchange=e=>{state.previewScene=e.target.value;renderAll();savePrefs();};
$("#insetInput").onchange=e=>{state.inset=Math.max(0,+e.target.value);renderAll();savePrefs()};
$("#bgBtn").onclick=()=>$("#bgInput").click();
$("#bgClearBtn").onclick=()=>{els.device.style.backgroundImage="";els.device.style.backgroundColor="#182332";toast("Фон убран")};
$("#bgInput").onchange=()=>{
 const file=$("#bgInput").files?.[0];if(!file)return;
 const url=URL.createObjectURL(file),img=new Image();
 img.onload=()=>{
  els.device.style.backgroundImage=`url("${url}")`;
  els.device.style.backgroundSize="cover";els.device.style.backgroundPosition="center";
  if(img.naturalWidth>100&&img.naturalHeight>100){
   state.viewport={w:img.naturalWidth,h:img.naturalHeight};
   $("#viewportW").value=img.naturalWidth;$("#viewportH").value=img.naturalHeight;
   $("#presetSelect").value="";
  }
  renderAll();toast("Скриншот Roblox установлен как фон");
 };
 img.src=url;
};

$("#undoBtn").onclick=undo;$("#redoBtn").onclick=redo;
$("#fitBtn").onclick=fitViewport;$("#zoom100Btn").onclick=()=>setZoom(1);$("#focusBtn").onclick=focusSelected;
$("#treeSearch").addEventListener("input",e=>{state.treeQuery=e.target.value;renderTree()});
els.stageScroller.addEventListener("wheel",e=>{
 if(!e.ctrlKey)return;e.preventDefault();
 setZoom(state.zoom*(e.deltaY<0?1.1:.9));
},{passive:false});
els.stageScroller.addEventListener("pointerdown",e=>{
 if(e.button!==1)return;e.preventDefault();
 state.pan={x:e.clientX,y:e.clientY,left:els.stageScroller.scrollLeft,top:els.stageScroller.scrollTop};
 els.stageScroller.classList.add("panning");
});
window.addEventListener("pointermove",e=>{
 if(!state.pan)return;
 els.stageScroller.scrollLeft=state.pan.left-(e.clientX-state.pan.x);
 els.stageScroller.scrollTop=state.pan.top-(e.clientY-state.pan.y);
});
window.addEventListener("pointerup",()=>{if(state.pan){state.pan=null;els.stageScroller.classList.remove("panning")}});
window.addEventListener("beforeunload",e=>{if(state.dirty){e.preventDefault();e.returnValue=""}});

$("#dialogClose").onclick=()=>els.jsonDialog.close();$("#dialogCopy").onclick=()=>navigator.clipboard.writeText(els.jsonArea.value);
$("#dialogApply").onclick=()=>{try{setRoot(JSON.parse(els.jsonArea.value),"JSON применён");els.jsonDialog.close()}catch(e){toast(e.message,true)}};
$("#addMenuBtn").onclick=()=>$("#palette").scrollIntoView({behavior:"smooth"});
window.addEventListener("resize",()=>{updateOverlay();updatePixelReadout()});
window.addEventListener("keydown",e=>{
 const tag=document.activeElement?.tagName;if(["INPUT","TEXTAREA","SELECT"].includes(tag))return;
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==="z"){e.preventDefault();e.shiftKey?redo():undo();return}
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==="y"){e.preventDefault();redo();return}
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==="d"){e.preventDefault();duplicateSelected();return}
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==="c"){e.preventDefault();copySelectedObject();return}
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==="v"){e.preventDefault();pasteObject();return}
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==="f"){e.preventDefault();$("#treeSearch").focus();$("#treeSearch").select();return}
 if(e.key==="F2"){e.preventDefault();renameSelected();return}
 if(e.key.toLowerCase()==="f"){e.preventDefault();focusSelected();return}
 if(e.key==="0"){e.preventDefault();fitViewport();return}
 if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==="s"){e.preventDefault();state.projectHandle?pushProject():download();return}
 if(e.key==="Delete"){deleteSelected();return}
 const n=selected();if(!n||n===state.root||MODIFIERS.has(n.ClassName))return;
 const step=e.shiftKey?state.snap:1,p=u2v(n,"Position");
 if(e.key==="ArrowLeft"){pushHistory();p[0][1]-=step}
 else if(e.key==="ArrowRight"){pushHistory();p[0][1]+=step}
 else if(e.key==="ArrowUp"){pushHistory();p[1][1]-=step}
 else if(e.key==="ArrowDown"){pushHistory();p[1][1]+=step}else return;
 e.preventDefault();n.Properties.Position={UDim2:p};changed()
});

loadPrefs();
syncToolbarFromState();
loadInitial().then(()=>{requestAnimationFrame(()=>fitViewport())});
})();