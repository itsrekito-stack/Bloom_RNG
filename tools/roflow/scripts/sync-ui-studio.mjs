import { copyFile, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here=dirname(fileURLToPath(import.meta.url));
const source=resolve(here,"../../bloom-ui-editor");
const target=resolve(here,"../web/ui-studio");

await rm(target,{recursive:true,force:true});
await mkdir(target,{recursive:true});

for(const file of ["app.css","app.js"]){
 await copyFile(resolve(source,file),resolve(target,file));
}

let html=await readFile(resolve(source,"index.html"),"utf8");
html=html.replace("<title>Bloom UI Studio</title>","<title>RoFlow · UI Studio</title>");
html=html.replace(
 '<script src="./app.js?v=8"></script>',
 '<script>window.__ROFLOW_EMBEDDED__=true;</script>\n<script src="./app.js?v=8"></script>'
);
await writeFile(resolve(target,"index.html"),html,"utf8");

console.log("RoFlow: embedded Bloom UI Studio synced");
