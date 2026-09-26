#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
html=(ROOT/"tools/bloom-ui-editor/index.html").read_text(encoding="utf-8")
app=(ROOT/"tools/bloom-ui-editor/app.js").read_text(encoding="utf-8")
engine=(ROOT/"tools/bloom-ui-editor/engine-v2.js").read_text(encoding="utf-8")
sync=(ROOT/"tools/roflow/scripts/sync-ui-studio.mjs").read_text(encoding="utf-8")
rust=(ROOT/"tools/roflow/src-tauri/src/lib.rs").read_text(encoding="utf-8")
roflow_html=(ROOT/"tools/roflow/web/index.html").read_text(encoding="utf-8")
roflow_css=(ROOT/"tools/roflow/web/app.css").read_text(encoding="utf-8")
roflow_app=(ROOT/"tools/roflow/web/app.js").read_text(encoding="utf-8")
editor_css=(ROOT/"tools/bloom-ui-editor/app.css").read_text(encoding="utf-8")

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

need(html,'id="viewportCanvas"',"Canvas viewport")
need(html,'./engine-v2.js',"Engine V2 script")
need(html,'ENGINE V2 · CANVAS2D',"Engine badge")
need(engine,'class BloomEditorEngineV2',"Canvas scene engine")
need(engine,'buildScene()',"scene graph build")
need(engine,'hitTest(x,y)',"canvas hit testing")
need(engine,'walkChildren(children,parentRect,parentNode,parentClip,parentLayoutMap)',"parent layout map must not be shadowed")
need(engine,'const childLayoutMap=this.childLayout(node,rect,childNodes);',"child layout map uses separate binding")
need(engine,'syncProxies()',"geometry compatibility bridge")
need(engine,'UIListLayout',"list layout")
need(engine,'UIGridLayout',"grid layout")
need(app,'function ensureEngineV2()',"app engine bridge")
need(app,'engine.render({',"engine render path")
need(app,'onNodePointerDown:(ev,n)=>startMove(ev,n)',"existing authoring interactions wired to canvas hit testing")
need(sync,'"engine-v2.js"',"RoFlow fallback packaging")
need(rust,'let engine_path = editor.join("engine-v2.js");',"RoFlow live engine loading")
need(rust,'UI Studio engine-v2.js tag is missing',"RoFlow engine script inlining")
print("Bloom UI Studio Engine V2 contract: PASS")
print("Canvas2D owns viewport rendering and hit-testing; DOM remains editor chrome plus geometry compatibility proxies.")

need(roflow_html,'class="studio-reload-fallback"',"RoFlow full-surface UI Studio")
need(roflow_app,'ui-studio-focus',"RoFlow UI Studio focus mode")
need(roflow_css,'body.ui-studio-focus main',"RoFlow chrome removal")
need(editor_css,'html.roflow-native',"Editor native desktop presentation")
need(editor_css,'--state-rail-w:66px',"Compact desktop state rail")
print("RoFlow native UI Studio desktop mode: PASS")
