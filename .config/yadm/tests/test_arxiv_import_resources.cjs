const fs=require('node:fs'),assert=require('node:assert/strict'),path=require('node:path');
(async()=>{
 const F=Object.getPrototypeOf(async function(){}).constructor;
 const source=fs.readFileSync(path.resolve(__dirname,'../../zotero/import-arxiv-update.js'),'utf8');
 const scheduled=new Map();let next=0,opened=0,rows=[];
 const active=new Set(['pending','processing','finding-update','downloading-metadata','downloading-pdf','needs-confirmation']);
 const manager={getRows:()=>rows,filterInactive:()=>{rows=rows.filter(r=>active.has(r.status))}};
 const item={id:3000,libraryID:1,itemType:'preprint',isRegularItem:()=>true,getField:()=> 'arxiv.org/abs/1234.56789'};
 const Z={Libraries:{userLibraryID:1},getMainWindow:()=>({setTimeout:f=>{scheduled.set(++next,f);return next},clearTimeout:id=>scheduled.delete(id)}),
 Items:{getAsync:async()=>[item]},logError:e=>{throw e},
 AutoArxivImportQueue:{pending:new Set(),seen:new Set(Array.from({length:2000},(_,i)=>i)),timer:null},
 arXivWorkflow:{data:{arXivUpdate:{manager}},api:{arXivUpdate:async(items,opts)=>{if(opts.openWindow)opened++;else rows.push({id:3000,status:'finding-update'})}}}};
 async function tick(){const [id,fn]=scheduled.entries().next().value;scheduled.delete(id);await fn()}
 await new F('item','require',source)(item,()=>Z);await tick();
 assert.equal(Z.AutoArxivImportQueue.seen.size,2000);assert.equal(scheduled.size,1);
 rows[0].status='downloading-metadata';await tick();assert.equal(scheduled.size,1);
 rows[0].status='succeeded';await tick();assert.equal(scheduled.size,0);assert.equal(rows.length,0);
 item.id=3001;await new F('item','require',source)(item,()=>Z);await tick();
 rows[0].status='needs-confirmation';await tick();assert.equal(opened,1);assert.equal(rows.length,1);assert.equal(scheduled.size,0);
 console.log('arXiv bounded deduplication, single monitor, terminal cleanup and preserved confirmations passed');
})().catch(e=>{console.error(e);process.exitCode=1});
