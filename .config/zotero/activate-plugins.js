// Included after a verified `prepared` manifest by setup-zotero.py.
// Execute in Zotero's native Run JavaScript window, as an async function.
if (parseInt(Zotero.version,10) !== prepared.zotero_major) {
  throw new Error("Plugin compatibility must be reviewed for this Zotero major version.");
}
const {AddonManager} = ChromeUtils.importESModule("resource://gre/modules/AddonManager.sys.mjs");
const {classes:Cc,interfaces:Ci} = Components;
const versions = value => String(value).split(/[.-]/).map(part => parseInt(part,10) || 0);
const compare = (a,b) => {
  const x=versions(a), y=versions(b);
  for (let i=0;i<Math.max(x.length,y.length);i++) {
    if ((x[i] || 0) !== (y[i] || 0)) return (x[i] || 0) - (y[i] || 0);
  }
  return 0;
};
const installed = [];
for (const plugin of prepared.plugins) {
  // Revalidate the staged file before passing it to the native installer.
  const bytes = await IOUtils.read(plugin.path);
  const hash = Cc["@mozilla.org/security/hash;1"].createInstance(Ci.nsICryptoHash);
  hash.init(hash.SHA256);
  hash.update(bytes,bytes.length);
  const digest = Array.from(hash.finish(false),char => char.charCodeAt(0).toString(16).padStart(2,"0")).join("");
  if (digest !== plugin.sha256) throw new Error(`Plugin checksum changed: ${plugin.name}`);
  let addon = await AddonManager.getAddonByID(plugin.id);
  if (!addon || compare(addon.version,plugin.version) < 0) {
    const install = await AddonManager.getInstallForFile(Zotero.File.pathToFile(plugin.path));
    if (install.addon.id !== plugin.id || install.addon.version !== plugin.version || !install.addon.isCompatible) {
      throw new Error(`Incompatible plugin or unexpected identity: ${plugin.name}`);
    }
    await install.install();
    addon = await AddonManager.getAddonByID(plugin.id);
  }
  if (addon.appDisabled) throw new Error(`Installed ${plugin.name} is incompatible with Zotero ${Zotero.version}`);
  if (addon.userDisabled) await addon.enable();
  if (!addon.isActive) throw new Error(`Restart Zotero to finish enabling ${plugin.name}, then rerun activation.`);
  installed.push({id:plugin.id,version:addon.version});
}
for (let attempt=0;!Zotero.ActionsTags?.api?.actionManager || !Zotero.arXivWorkflow?.api;attempt++) {
  if (attempt >= 100) throw new Error("Plugin startup incomplete; restart Zotero and rerun activation.");
  await Zotero.Promise.delay(100);
}
const sourceRoot = PathUtils.join(PathUtils.homeDir,".config","zotero");
const code = await Zotero.File.getContentsAsync(PathUtils.join(sourceRoot,"install-conference-tags.js"));
const F = Object.getPrototypeOf(async function(){}).constructor;
const message = await new F("Zotero",code)(Zotero);
// Metadata enrichment is the intended workflow; don't fetch another PDF on every import.
Zotero.Prefs.set("extensions.zotero.arxiv-workflow.downloadJournalPDF",false,true);
const receipt = {activatedAt:new Date().toISOString(),zotero:Zotero.version,plugins:installed,message};
const local = PathUtils.join(PathUtils.homeDir,".config","yadm","local","zotero");
await IOUtils.makeDirectory(local,{ignoreExisting:true,createAncestors:true});
await Zotero.File.putContentsAsync(PathUtils.join(local,"activation-result.json"),JSON.stringify(receipt,null,2));
return receipt;
