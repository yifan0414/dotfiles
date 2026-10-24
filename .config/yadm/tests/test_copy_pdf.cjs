const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
(async()=>{
const F=Object.getPrototypeOf(async function(){}).constructor;
let clipboard=null,copies=0;
const records=[],listeners=new Map();
const file={path:'/Users/test/a paper.pdf',leafName:'a paper.pdf',exists:()=>true,isFile:()=>true,QueryInterface(){return this}};
const pdf={key:'ABCDEFGH',id:1,deleted:false,isPDFAttachment:()=>true,getFilePathAsync:async()=>file.path};
const parent={isPDFAttachment:()=>false,isRegularItem:()=>true,getBestAttachment:async()=>pdf,getAttachments:()=>[1]};
const C={interfaces:{nsIFile:{},nsITransferable:{},nsIClipboard:{kGlobalClipboard:1}},classes:{
 '@mozilla.org/widget/transferable;1':{createInstance:()=>({init(){},addDataFlavor(flavor){assert.equal(flavor,'application/x-moz-file')},setTransferData(flavor,value){this.value=value},getTransferData(flavor,out){out.value=this.value}})}
}};
const S={dirsvc:{get:()=>({path:'/Users/test'})},clipboard:{setData(t){clipboard=t.value;copies++},getData(t){t.value=clipboard}}};
const Z={isMac:true,Utilities:{Internal:{exec:async(helper,args)=>{assert.equal(helper,"/Users/test/.config/yadm/local/zotero/bin/copy-pdf");assert.deepEqual(args,[file.path]);clipboard=file;copies++}}},Items:{getAsync:async()=>pdf,get:()=>pdf},File:{pathToFile:p=>{assert.equal(p,file.path);return file},putContentsAsync:async(p,data)=>records.push(JSON.parse(data))},
 Reader:{_readers:[],registerEventListener:(type,fn)=>listeners.set(type,fn),unregisterEventListener:type=>listeners.delete(type)},getMainWindows:()=>[],logError:e=>{throw e}};
const globals={Components:C,Services:S,PathUtils:{join:path.join},IOUtils:{exists:async()=>true,makeDirectory:async()=>{}}};
await new F('Zotero','require',(await fs.readFile(path.resolve(__dirname,'../../zotero/copy-pdf.js'),'utf8'))+'\nZ.CopyPDF.audit=()=>({documents:documentRefs.size,buttons:buttons.size,timers:timers.size});')(Z,n=>globals[n]);
assert.equal(await Z.CopyPDF.attachmentFor(parent),pdf);
assert.match(await Z.CopyPDF.copySelected([parent]),/已复制 PDF/);assert.equal(clipboard,file);
assert.equal(records.at(-1).clipboardVerified,true);
const previous=copies;assert.match(await Z.CopyPDF.copySelected([parent,pdf]),/一次选择/);assert.equal(copies,previous);
file.exists=()=>false;assert.match(await Z.CopyPDF.copySelected([pdf]),/不存在/);assert.equal(copies,previous);file.exists=()=>true;
let button;
const lifecycle=new Map();
const doc={defaultView:{setTimeout,clearTimeout,addEventListener:(n,f)=>lifecycle.set(n,f),removeEventListener:n=>lifecycle.delete(n)},addEventListener(){},removeEventListener(){},querySelectorAll:()=>[],createElement:()=>({style:{},events:{},setAttribute(){},addEventListener(type,fn){this.events[type]=fn},remove(){}})};
listeners.get('renderToolbar')({reader:{type:'pdf',itemID:1},doc,append:b=>button=b});
button.ownerDocument=doc;
assert.equal(button.textContent,'复制 PDF');await button.events.click();assert.equal(button.textContent,'已复制');assert.equal(button.disabled,false);
assert.equal(Z.CopyPDF.audit().timers,1);
lifecycle.get("pagehide")({persisted:false});
assert.deepEqual(Z.CopyPDF.audit(),{documents:0,buttons:0,timers:0});
for(let i=0;i<100;i++){
 listeners.get("renderToolbar")({reader:{type:"pdf",itemID:1},doc,append:b=>{button=b;b.ownerDocument=doc}});
 lifecycle.get("unload")({persisted:false});
}
assert.deepEqual(Z.CopyPDF.audit(),{documents:0,buttons:0,timers:0});
Z.CopyPDF.dispose();assert.equal(listeners.size,0);
console.log('PDF selection, missing files, clipboard readback, reader button and cleanup passed');
})().catch(e=>{console.error(e);process.exitCode=1});
