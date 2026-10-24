const fs=require('node:fs/promises'),assert=require('node:assert/strict'),path=require('node:path');
(async()=>{
const sourceRoot=path.resolve(__dirname,'../../zotero');
const F=Object.getPrototypeOf(async function(){}).constructor;
const prefs=new Map(); prefs.set('extensions.actionsTags.conferenceAI.enabled',true);
const title='EarlyTom: Early Token Compression Completes Fast Video Understanding';
const url='https://openaccess.thecvf.com/content/CVPR2026/html/Wang_EarlyTom_CVPR_2026_paper.html';
const quote='Hesong Wang; Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR), 2026';
const doc={url,content:title+'\n'+quote};
const answer={title,conference:'CVPR',year:2026,source_url:url,evidence_quote:quote};
const record={title,authors:[{lastName:'Wang'}],arxiv_id:'2605.30010'};
let network=0, lateEdit=null;
let importObserver;
const delayed=[];
const reports=[];
function item(id){return {id,key:'ABCDEF0'+id,libraryID:1,itemType:'preprint',deleted:false,
 fields:{title,extra:'arXiv:2605.30010',date:'2026-05-28',url:'https://arxiv.org/abs/2605.30010'},tags:[],saves:0,
 getField(n){return this.fields[n]||''},setField(n,v){this.fields[n]=v},getCreators(){return record.authors},
 getTags(){return this.tags},hasTag(t){return this.tags.some(x=>x.tag===t)},
 addTag(tag,type=0){this.tags.push({tag,type})},removeTag(t){this.tags=this.tags.filter(x=>x.tag!==t)},
 isRegularItem(){return true},async saveTx(){this.saves++}}}
const items=new Map();
const win={...globalThis,AbortController,setTimeout,clearTimeout,fetch:async(u,o)=>{
 assert.equal(new URL(u).origin,'https://api.deepseek.com');assert.equal(o.headers.Authorization,'Bearer fake-test-credential');
 assert.ok(!o.body.includes('fake-test-credential'));network++;
 if(u.endsWith('/search'))return {ok:true,json:async()=>({results:[doc]})};
 if(lateEdit)lateEdit();
 return {ok:true,json:async()=>({choices:[{message:{content:JSON.stringify({result:answer})}}]})};
}};
win.setTimeout=(fn,ms)=>ms===10000 ? (delayed.push(fn),100000+delayed.length) : setTimeout(fn,ms);
const Z={getMainWindow:()=>win,Libraries:{userLibraryID:1},
 Prefs:{get:k=>prefs.get(k),set:(k,v)=>prefs.set(k,v)},
 File:{getContentsAsync:async p=>{assert.ok(p.endsWith('/.pi/agent/auth.json'));return JSON.stringify({deepseek:{type:'api_key',key:'fake-test-credential'}})},
 putContentsAsync:async(p,data)=>reports.push(JSON.parse(data))},
 Notifier:{registerObserver:(observer,types,name)=>{if(name==='conference-ai-fallback')importObserver=observer;return 1},unregisterObserver(){}},ItemTreeManager:{registerColumn:async()=> 'test-column'},
 Items:{getAll:async()=>[],getAsync:async id=>Array.isArray(id)?id.map(x=>items.get(x)):items.get(id)},logError:e=>{throw e}};
const globals={PathUtils:{join:path.join},IOUtils:{makeDirectory:async()=>{}},
 Services:{dirsvc:{get:()=>({path:'/Users/test'})}},Components:{interfaces:{nsIFile:{}}}};
await new F('Zotero',await fs.readFile(path.join(sourceRoot,'conference-tags.js'),'utf8'))(Z);
await new F('Zotero','require',(await fs.readFile(path.join(sourceRoot,'conference-ai.js'),'utf8'))+'\nZ.ConferenceAI.audit={attempts,pruneAttempts,controllers};')(Z,n=>globals[n]);
assert.equal(Z.ConferenceAI.validate(answer,record,[doc]).conference,'CVPR');
for(const a of [{...answer,evidence_quote:'CVPR 2026 invented passage'}, {...answer,year:2025},
 {...answer,title:'A different paper'}, {...answer,source_url:'https://openaccess.thecvf.com.evil.org/x'},
 {...answer,conference:'ICCV'}, {...answer,conference:'Unknown'}])assert.equal(Z.ConferenceAI.validate(a,record,[doc]),null);
assert.equal(Z.ConferenceAI.validate(answer,{...record,authors:[{lastName:'Jones'}]},[doc]),null);
const rejectedQuote='Accepted by CVPR 2026 workshop';
assert.equal(Z.ConferenceAI.validate({...answer,evidence_quote:rejectedQuote},record,[{url,content:title+' Wang '+rejectedQuote}]),null);
const a=item(1);items.set(1,a);
const result=await Z.ConferenceAI.run([a,a]);assert.deepEqual(result,['updated','updated']);assert.equal(network,2);
assert.equal(Z.ConferenceYearTags.resolveItem(a).tag,'CVPR2026');
assert.equal(a.fields.date,'2026-05-28');assert.equal(a.itemType,'preprint');assert.ok(a.hasTag('CVPR2026'));
a.addTag('ICLR2027 UnderReview');
await Z.ConferenceYearTags.run([a]);assert.equal(Z.ConferenceYearTags.resolveItem(a).tag,'ICLR2027 UnderReview');
assert.ok(!a.hasTag('CVPR2026'));assert.deepEqual(await Z.ConferenceAI.run([a]),[]);
const beforeSkip=network;
assert.match(await Z.ConferenceAI.runSelected([a]),/未发起 AI 查询：已有手动会议标签 1 项/);
assert.equal(network,beforeSkip);
const b=item(2);items.set(2,b);lateEdit=()=>b.addTag('ICLR2027 UnderReview');
assert.deepEqual(await Z.ConferenceAI.run([b]),['skipped']);assert.equal(b.saves,0);assert.ok(!b.fields.extra.includes('Conference AI:'));
lateEdit=null;
const c=item(3);items.set(3,c);const row={id:3,status:'pending'};
Z.arXivWorkflow={data:{arXivUpdate:{manager:{getRows:()=>[row]}}}};
await importObserver.notify('add','item',[3]);assert.equal(delayed.length,1);
const beforeNetwork=network;await delayed.shift()();assert.equal(network,beforeNetwork);assert.equal(delayed.length,1);
row.status='up-to-date';await delayed.shift()();assert.ok(c.hasTag('CVPR2026'));
assert.equal(network,beforeNetwork+2);
assert.match(await Z.ConferenceAI.runSelected([c]),/已有可识别的会议信息 1 项/);
c.itemType='conferencePaper';c.fields.conferenceName='ICLR 2027 Under Review';
assert.equal(Z.ConferenceYearTags.resolveItem(c),null);
assert.match(await Z.ConferenceAI.runSelected([c]),/会议字段非空/);
assert.ok(!JSON.stringify(reports).includes('fake-test-credential'));
Z.ConferenceAI.dispose();Z.ConferenceYearTags.dispose();
const audit=Z.ConferenceAI.audit;
for(let i=0;i<3000;i++){ audit.pruneAttempts(Date.now());audit.attempts.set('key'+i,Date.now()); }
assert.equal(audit.attempts.size,2000);
audit.pruneAttempts(Date.now()+25*60*60*1000);assert.equal(audit.attempts.size,0);
let aborted=false;audit.controllers.add({abort(){aborted=true}});
Z.ConferenceAI.dispose();assert.equal(aborted,true);assert.equal(audit.controllers.size,0);
console.log('Bounded AI cache, expiry and shutdown cancellation passed');
console.log('AI evidence checks, credential boundaries, duplicate requests, badge integration, manual-edit race and import fallback passed');
})().catch(e=>{console.error(e);process.exitCode=1});
