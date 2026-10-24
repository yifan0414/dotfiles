// Run in Zotero Tools > Developer > Run JavaScript with "Run as async function".
const at = Zotero.ActionsTags;
if (!at) throw new Error("Enable Actions & Tags first.");
const homeDir = Services.dirsvc.get("Home",Components.interfaces.nsIFile).path;
const root = PathUtils.join(homeDir,".config","zotero");
const backups = PathUtils.join(homeDir,".config","yadm","local","zotero","backups");
const source = await Zotero.File.getContentsAsync(PathUtils.join(root,"conference-tags.js"));
const backup = {
  savedAt: new Date().toISOString(),
  actions: Object.fromEntries(at.data.actions.map)
};
await IOUtils.makeDirectory(backups,{ignoreExisting:true,createAncestors:true});
await Zotero.File.putContentsAsync(PathUtils.join(backups,`actions-${Date.now()}.json`), JSON.stringify(backup, null, 2));
// Disable only the plugin's two sample unread actions, unrelated to this setup.
for (const key of ["default0", "default1"]) {
  const action = at.data.actions.map.get(key);
  if (action && action.data === "/unread") at.api.actionManager.updateAction({...action, enabled:false}, key);
}
at.api.actionManager.updateAction({
  name:"会议简称＋年份：自动监听与启动补全", event:9, operation:4,
  data:source, shortcut:"", enabled:true, menu:"",
  showInMenu:{item:false,collection:false,tools:false,reader:false,readerAnnotation:false}
}, "conference-year-tags-startup-v1");
at.api.actionManager.updateAction({
  name:"会议简称＋年份：补全所选条目", event:0, operation:4,
  data:'if (!items?.length) return; const Z=require("Zotero"); if (!Z.ConferenceYearTags) throw new Error("Restart Zotero to activate conference tags."); await Z.ConferenceYearTags.run(items);',
  shortcut:"", enabled:true, menu:"补全会议年份标签",
  showInMenu:{item:true,collection:false,tools:false,reader:false,readerAnnotation:false}
}, "conference-year-tags-selected-v1");
const AsyncFunction = Object.getPrototypeOf(async function(){}).constructor;
at.api.actionManager.updateAction({
  name:"导入 arXiv 后自动查询正式发表信息", event:1, operation:4,
  data:await Zotero.File.getContentsAsync(PathUtils.join(root,"import-arxiv-update.js")),
  shortcut:"", enabled:true, menu:"",
  showInMenu:{item:false,collection:false,tools:false,reader:false,readerAnnotation:false}
}, "arxiv-auto-update-on-import-v1");
const aiEnabled = Zotero.Prefs?.get("extensions.actionsTags.conferenceAI.enabled",true) === true;
at.api.actionManager.updateAction({
  name:"AI 会议查询：启动监听", event:9, operation:4,
  data:await Zotero.File.getContentsAsync(PathUtils.join(root,"conference-ai.js")),
  shortcut:"",enabled:aiEnabled,menu:"",
  showInMenu:{item:false,collection:false,tools:false,reader:false,readerAnnotation:false}
}, "conference-ai-startup-v1");
at.api.actionManager.updateAction({
  name:"AI 查询会议信息",event:0,operation:4,
  data:'if (!items?.length) return; const Z=require("Zotero"); if (!Z.ConferenceAI?.runSelected) throw new Error("Restart Zotero to activate AI lookup."); return await Z.ConferenceAI.runSelected(items);',
  shortcut:"",enabled:aiEnabled,menu:"AI 查询会议信息",
  showInMenu:{item:true,collection:false,tools:false,reader:false,readerAnnotation:false}
}, "conference-ai-selected-v1");
at.api.actionManager.updateAction({
  name:"复制 PDF：阅读器按钮与快捷键",event:9,operation:4,
  data:await Zotero.File.getContentsAsync(PathUtils.join(root,"copy-pdf.js")),
  shortcut:"",enabled:true,menu:"",
  showInMenu:{item:false,collection:false,tools:false,reader:false,readerAnnotation:false}
}, "copy-pdf-startup-v1");
at.api.actionManager.updateAction({
  name:"复制 PDF 文件",event:0,operation:4,
  data:'if (!items?.length) return; const Z=require("Zotero"); if (!Z.CopyPDF) throw new Error("Restart Zotero to activate PDF copy."); return await Z.CopyPDF.copySelected(items);',
  shortcut:"",enabled:true,menu:"复制 PDF 文件",
  showInMenu:{item:true,collection:false,tools:false,reader:true,readerAnnotation:false}
}, "copy-pdf-selected-v1");
return await new AsyncFunction("Zotero",source)(Zotero);
