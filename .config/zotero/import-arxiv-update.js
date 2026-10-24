// Actions & Tags: createItem. Debounce to let the browser translator finish saving.
if (!item || !item.isRegularItem() || item.itemType !== "preprint") return;
const Z = require("Zotero");
if (item.libraryID !== Z.Libraries.userLibraryID) return;
const arxivRecord = target => ["archiveID", "extra", "url", "DOI"].some(name => {
  try { return /arxiv[.:/]|arxiv\.org/i.test(target.getField(name) || ""); }
  catch { return false; }
});
if (!arxivRecord(item)) return;
if (!Z.arXivWorkflow?.api?.arXivUpdate) {
  Z.logError(new Error("Auto arXiv update skipped: arXiv Workflow is disabled."));
  return;
}
const win = Z.getMainWindow();
const queue = Z.AutoArxivImportQueue ||= {pending:new Set(), seen:new Set(), timer:null};
if (queue.seen.has(item.id)) return;
queue.pending.add(item.id);
if (queue.timer !== null) win.clearTimeout(queue.timer);
queue.timer = win.setTimeout(async () => {
  queue.timer = null;
  const ids = [...queue.pending]; queue.pending.clear();
  try {
    const candidates = (await Z.Items.getAsync(ids)).filter(target => target &&
      !target.deleted && target.itemType === "preprint" && arxivRecord(target));
    if (!candidates.length) return;
    for (const target of candidates) queue.seen.add(target.id);
    while (queue.seen.size > 2000) queue.seen.delete(queue.seen.values().next().value);
    Z.arXivWorkflow.data?.arXivUpdate?.manager?.filterInactive?.();
    // Supported by Workflow 0.4.1: update without opening its progress window.
    await Z.arXivWorkflow.api.arXivUpdate(candidates, {openWindow:false});
    // Surface paused fuzzy matches so hiding progress never hides a required decision.
    const manager = Z.arXivWorkflow.data?.arXivUpdate?.manager;
    if (manager?.getRows) {
      if (queue.reviewTimer != null) win.clearTimeout(queue.reviewTimer);
      const started = Date.now();
      const checkReview = () => {
        queue.reviewTimer = null;
        const rows = manager.getRows();
        if (rows.some(row => row.status === "needs-confirmation")) {
          Z.arXivWorkflow.api.arXivUpdate([], {openWindow:true});
          return;
        }
        if (Date.now() - started < 15 * 60 * 1000 &&
            rows.some(row => ["pending", "processing", "finding-update", "downloading-metadata", "downloading-pdf"].includes(row.status))) {
          queue.reviewTimer = win.setTimeout(checkReview, 3000);
        } else {
          manager.filterInactive?.();
        }
      };
      checkReview();
    }
  } catch (error) {
    for (const id of ids) queue.seen.delete(id);
    Z.logError(error);
  }
}, 3000);
