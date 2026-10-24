// Actions & Tags mainWindowLoad. Copy an existing PDF file to the native clipboard.
const Z = typeof Zotero !== "undefined" ? Zotero : require("Zotero");
const C = typeof Components !== "undefined" ? Components : require("Components");
const S = typeof Services !== "undefined" ? Services : require("Services");
const P = typeof PathUtils !== "undefined" ? PathUtils : require("PathUtils");
const IO = typeof IOUtils !== "undefined" ? IOUtils : require("IOUtils");
const {classes:Cc,interfaces:Ci} = C;
const home = S.dirsvc.get("Home",Ci.nsIFile).path;
const local = P.join(home,".config","yadm","local","zotero");
const pluginID = "zoterotag@euclpts.com";
const buttonID = "yadm-copy-pdf";
const shortcut = Z.isMac ? "⌘⌥⇧C" : "Ctrl+Alt+Shift+C";
const documents = new WeakMap(), documentRefs = new Set(), buttons = new Set(), timers = new Set();
function prune(refs) { for (const ref of refs) if (!ref.deref()) refs.delete(ref); }
let disposed = false;
Z.CopyPDF?.dispose();
async function report(data) {
  try {
    await IO.makeDirectory(local,{ignoreExisting:true,createAncestors:true});
    await Z.File.putContentsAsync(P.join(local,"copy-pdf-result.json"),JSON.stringify({...data,at:new Date().toISOString()},null,2));
  } catch {}
}
async function attachmentFor(item) {
  if (!item || item.deleted) throw new Error("请选择一篇论文或一个 PDF 附件");
  if (item.isPDFAttachment()) return item;
  if (!item.isRegularItem()) throw new Error("当前条目不是 PDF 附件");
  const best = await item.getBestAttachment();
  if (best?.isPDFAttachment()) return best;
  for (const id of item.getAttachments()) {
    const attachment = await Z.Items.getAsync(id);
    if (attachment?.isPDFAttachment() && !attachment.deleted) return attachment;
  }
  throw new Error("这篇论文没有 PDF 附件");
}
async function copyItem(item) {
  try {
    const attachment = await attachmentFor(item);
    const path = await attachment.getFilePathAsync();
    if (!path) throw new Error("PDF 尚未下载，请先打开附件完成下载");
    const file = Z.File.pathToFile(path);
    if (!file.exists() || !file.isFile()) throw new Error("PDF 文件不存在，请先检查附件");
    if (Z.isMac) {
      const helper = P.join(local,"bin","copy-pdf");
      if (!await IO.exists(helper)) throw new Error("请先运行 Zotero PDF 复制安装脚本");
      // NSURL pasteboard writing preserves Unicode and spaces for Finder and chat applications.
      await Z.Utilities.Internal.exec(helper,[path]);
    } else {
    const transfer = Cc["@mozilla.org/widget/transferable;1"].createInstance(Ci.nsITransferable);
    transfer.init(null);
    transfer.addDataFlavor("application/x-moz-file");
    transfer.setTransferData("application/x-moz-file",file);
    S.clipboard.setData(transfer,null,Ci.nsIClipboard.kGlobalClipboard);
    // Read back only the file flavor we just wrote, never unrelated clipboard contents.
    const check = Cc["@mozilla.org/widget/transferable;1"].createInstance(Ci.nsITransferable);
    check.init(null); check.addDataFlavor("application/x-moz-file");
    S.clipboard.getData(check,Ci.nsIClipboard.kGlobalClipboard);
    const value = {}; check.getTransferData("application/x-moz-file",value);
    const copied = value.value.QueryInterface(Ci.nsIFile);
    if (copied.path !== file.path) throw new Error("系统剪贴板未确认文件复制，请重试");
    }
    await report({status:"copied",itemKey:attachment.key,filename:file.leafName,clipboardVerified:true});
    return `已复制 PDF：${file.leafName}`;
  } catch (error) {
    await report({status:"error",message:error.message});
    throw error;
  }
}
async function copySelected(items) {
  if (items.length !== 1) return "请一次选择一篇论文或一个 PDF 附件";
  try { return await copyItem(items[0]); }
  catch (error) { return `复制失败：${error.message}`; }
}
function notify(message) {
  const popup = new Z.ProgressWindow({closeOnClick:true});
  popup.changeHeadline("复制 PDF"); popup.addDescription(message); popup.show(); popup.startCloseTimer(3500);
}
function releaseDocument(doc) {
  const binding = documents.get(doc);
  if (!binding) return;
  doc.removeEventListener("keydown",binding.keydown,true);
  doc.removeEventListener("load",binding.load,true);
  doc.defaultView?.removeEventListener("pagehide",binding.unload);
  doc.defaultView?.removeEventListener("unload",binding.unload);
  for (const ref of buttons) {
    const button = ref.deref();
    if (!button || button.ownerDocument === doc) { button?.remove(); buttons.delete(ref); }
  }
  for (const token of timers) if (token.win === doc.defaultView) {
    token.win.clearTimeout(token.id); timers.delete(token);
  }
  documents.delete(doc); documentRefs.delete(binding.ref);
}
function bindDocument(doc,reader=null) {
  if (!doc || documents.has(doc) || disposed) return;
  const keydown = event => {
    const modifier = Z.isMac ? event.metaKey && !event.ctrlKey : event.ctrlKey && !event.metaKey;
    if (event.repeat || event.defaultPrevented || !modifier || !event.altKey || !event.shiftKey || event.code !== "KeyC") return;
    event.preventDefault(); event.stopPropagation();
    let currentReader = reader;
    if (!currentReader) {
      const win = doc.defaultView;
      currentReader = Z.Reader.getByTabID(win.Zotero_Tabs?.selectedID);
    }
    const selected = currentReader ? [Z.Items.get(currentReader.itemID)] : Z.getActiveZoteroPane()?.getSelectedItems() || [];
    void copySelected(selected).then(notify);
  };
  const load = event => {
    if (reader && event.target?.localName === "iframe") {
      try { bindDocument(event.target.contentDocument,reader); } catch {}
    }
  };
  doc.addEventListener("keydown",keydown,true);
  doc.addEventListener("load",load,true);
  const unload = event => { if (!event.persisted) releaseDocument(doc); };
  const ref = new WeakRef(doc);
  prune(documentRefs); documentRefs.add(ref);
  documents.set(doc,{keydown,load,unload,ref});
  doc.defaultView?.addEventListener("pagehide",unload);
  doc.defaultView?.addEventListener("unload",unload);
  for (const frame of reader ? doc.querySelectorAll("iframe") : []) {
    try { bindDocument(frame.contentDocument,reader); } catch {}
  }
}
function renderToolbar({reader,doc,append}) {
  if (disposed || reader.type !== "pdf") return;
  bindDocument(doc,reader);
  // Drop detached toolbar nodes on rerender; only weak references survive document closure.
  for (const ref of buttons) {
    const old = ref.deref();
    if (!old || old.ownerDocument === doc) { old?.remove(); buttons.delete(ref); }
  }
  // React rebuilds the custom section on render, so create a fresh node for each callback.
  const button = doc.createElement("button");
  button.id = buttonID; button.type = "button";
  button.className = "toolbar-button";
  button.textContent = "复制 PDF";
  button.title = `复制 PDF 文件（${shortcut}）`;
  button.setAttribute("aria-label",button.title);
  button.style.cssText = "width:auto;min-width:64px;padding:0 7px;font-size:12px;white-space:nowrap;";
  button.addEventListener("click",async () => {
    button.disabled = true;
    try {
      const message = await copyItem(Z.Items.get(reader.itemID));
      button.textContent = "已复制"; button.title = message;
    } catch (error) {
      button.textContent = "复制失败"; button.title = error.message;
      notify(`复制失败：${error.message}`);
    } finally {
      button.disabled = false;
      if (disposed || !documents.has(doc)) return;
      const win = doc.defaultView;
      const token = {win,id:null};
      token.id = win.setTimeout(() => {
        timers.delete(token);
        if (!disposed) { button.textContent = "复制 PDF"; button.title = `复制 PDF 文件（${shortcut}）`; }
      },2000);
      timers.add(token);
    }
  });
  buttons.add(new WeakRef(button)); append(button);
}
function contextMenu({reader,append}) {
  if (reader.type !== "pdf") return;
  append({label:"复制 PDF 文件",onCommand:() => {
    void copySelected([Z.Items.get(reader.itemID)]).then(notify);
  }});
}
Z.Reader.registerEventListener("renderToolbar",renderToolbar,pluginID);
Z.Reader.registerEventListener("createViewContextMenu",contextMenu,pluginID);
for (const win of Z.getMainWindows()) bindDocument(win.document);
// Cover already-open readers; new readers use the public renderToolbar event above.
for (const reader of Z.Reader._readers || []) {
  try {
    const doc = reader._iframeWindow?.document;
    const container = doc?.querySelector(".toolbar .end .custom-sections");
    if (container && !doc.getElementById(buttonID)) renderToolbar({reader,doc,append:node=>container.append(node)});
  } catch (error) { Z.logError(error); }
}
Z.CopyPDF = {version:"1.0.1",copyItem,copySelected,attachmentFor,dispose() {
  disposed = true;
  Z.Reader.unregisterEventListener("renderToolbar",renderToolbar);
  Z.Reader.unregisterEventListener("createViewContextMenu",contextMenu);
  for (const ref of documentRefs) { const doc = ref.deref(); if (doc) releaseDocument(doc); }
  for (const ref of buttons) { try { ref.deref()?.remove(); } catch {} }
  for (const {win,id} of timers) { try { win.clearTimeout(id); } catch {} }
  documentRefs.clear(); buttons.clear(); timers.clear();
}};
await IO.makeDirectory(local,{ignoreExisting:true,createAncestors:true});
await Z.File.putContentsAsync(P.join(local,"copy-pdf-runtime.json"),JSON.stringify({status:"active",version:Z.CopyPDF.version,shortcut,at:new Date().toISOString()},null,2));
