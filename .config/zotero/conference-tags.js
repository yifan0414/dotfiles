// Actions & Tags: run on mainWindowLoad. All matching is local; no network calls.
// Edit the aliases below, then run install-conference-tags.js again to update.
const Z = typeof Zotero !== "undefined" ? Zotero : require("Zotero");
const normalize = value => String(value || "").normalize("NFKD")
  .replace(/[\u0300-\u036f]/g, "").toLowerCase()
  .replace(/[^a-z0-9]+/g, " ").trim().replace(/\s+/g, " ");
const venues = [
  ["NeurIPS", ["neurips", "nips", "advances in neural information processing systems", "neural information processing systems"]],
  ["ICML", ["icml", "international conference on machine learning"]],
  ["ICLR", ["iclr", "international conference on learning representations"]],
  ["AAAI", ["aaai", "aaai conference on artificial intelligence", "national conference on artificial intelligence"]],
  ["IJCAI", ["ijcai", "international joint conference on artificial intelligence"]],
  ["AISTATS", ["aistats", "international conference on artificial intelligence and statistics", "artificial intelligence and statistics"]],
  ["UAI", ["uai", "conference on uncertainty in artificial intelligence", "uncertainty in artificial intelligence"]],
  ["COLT", ["colt", "conference on learning theory", "conference on computational learning theory"]],
  ["CVPR", ["cvpr", "conference on computer vision and pattern recognition", "computer vision and pattern recognition"]],
  ["ICCV", ["iccv", "international conference on computer vision"]],
  ["ECCV", ["eccv", "european conference on computer vision"]],
  ["NAACL", ["naacl", "naacl hlt", "north american chapter of the association for computational linguistics", "nations of the americas chapter of the association for computational linguistics"]],
  ["EMNLP", ["emnlp", "empirical methods in natural language processing"]],
  ["EACL", ["eacl", "european chapter of the association for computational linguistics"]],
  ["COLING", ["coling", "international conference on computational linguistics"]],
  ["CoNLL", ["conll", "conference on computational natural language learning"]],
  ["ACL", ["acl", "annual meeting of the association for computational linguistics"]],
  ["ACMMM", ["acm mm", "acmmm", "acm international conference on multimedia", "acm multimedia"]],
  ["KDD", ["kdd", "sigkdd", "knowledge discovery and data mining"]],
  ["SIGIR", ["sigir", "research and development in information retrieval"]],
  ["WWW", ["www", "the web conference", "acm web conference", "international world wide web conference", "international conference on world wide web"]],
  ["WSDM", ["wsdm", "web search and data mining"]],
  ["ICAPS", ["icaps", "international conference on automated planning and scheduling"]],
  ["KR", ["kr", "principles of knowledge representation and reasoning"]],
  ["AAMAS", ["aamas", "autonomous agents and multiagent systems", "autonomous agents and multi agent systems"]],
];
const excluded = /\b(workshops?|findings|companion|tutorials?|demonstrations?|demos?|shared tasks?|student research|doctoral consortium|industry track|industry papers|short papers?|extended abstracts?|submissions?|submitted|under review)\b/;
function resolveDetails(venue, date, itemType, context = {}) {
  if (!["conferencePaper", "journalArticle"].includes(itemType)) return null;
  const extraVenue = String(context.extra || "").split(/\r?\n/)
    .filter(line => /^(?:conference name|proceedings title|publication title|venue(?: id)?|tex\.booktitle):/i.test(line))
    .map(line => line.replace(/^[^:]+:\s*/, "")).join(" | ");
  const text = normalize([venue, extraVenue].filter(Boolean).join(" | "));
  if (excluded.test(text)) return null;
  let url;
  try { url = new URL(context.url); } catch {}
  const host = url?.hostname.toLowerCase() || "";
  const path = decodeURIComponent(url?.pathname || "");
  const urlHints = [];
  const hint = (conference, year) => urlHints.push({conference, year:String(year)});
  const cvf = /(?:^|\.)(?:openaccess\.thecvf\.com)$/.test(host);
  if (cvf) {
    // CVPR2025W denotes workshops, not the CVPR main proceedings.
    if (/\/content\/(?:CVPR|ICCV|ECCV)\d{4}(?:W|[_/-]workshop)/i.test(path)) return null;
    const match = path.match(/\/content\/(CVPR|ICCV|ECCV)[_/-]?((?:19|20)\d{2})(?:\/|$)/i);
    if (match) hint(match[1].toUpperCase(), match[2]);
  }
  if (host === "ecva.net" || host.endsWith(".ecva.net")) {
    if (/workshop/i.test(path)) return null;
    const match = path.match(/\/papers\/eccv[_/-]((?:19|20)\d{2})\//i);
    if (match) hint("ECCV", match[1]);
  }
  if (host === "proceedings.neurips.cc" || host === "papers.nips.cc") {
    const match = path.match(/\/paper(?:_files)?(?:\/paper)?\/((?:19|20)\d{2})\//);
    if (match) hint("NeurIPS", match[1]);
  }
  if (host === "proceedings.iclr.cc") {
    const match = path.match(/\/paper_files\/paper\/((?:19|20)\d{2})\//);
    if (match && !/workshop/i.test(path)) hint("ICLR", match[1]);
  }
  if (host === "aclanthology.org" || host.endsWith(".aclanthology.org")) {
    const match = path.match(/^\/((?:19|20)\d{2})\.(acl|emnlp|naacl|eacl|coling|conll)-(long|short|main|findings|demo|industry)\./i);
    if (match) {
      if (["short", "findings", "demo", "industry"].includes(match[3].toLowerCase())) return null;
      hint(match[2].toLowerCase() === "conll" ? "CoNLL" : match[2].toUpperCase(), match[1]);
    }
  }
  if (host === "openreview.net" || host.endsWith(".openreview.net")) {
    const group = url.searchParams.get("id") || "";
    const match = group.match(/^ICLR\.cc\/((?:19|20)\d{2})\/Conference(?:\/|$)/i);
    if (match && !/workshop|submission/i.test(group)) hint("ICLR", match[1]);
  }
  const matches = venues.filter(([, aliases]) => aliases.some(alias =>
    (` ${text} `).includes(` ${normalize(alias)} `)));
  const conferences = new Set([...matches.map(([name]) => name), ...urlHints.map(h => h.conference)]);
  if (conferences.size !== 1) return null;
  const conference = [...conferences][0];
  const explicitYears = [...new Set(text.match(/\b(?:19|20)\d{2}\b/g) || [])];
  const reliableYears = new Set([...explicitYears, ...urlHints.map(h => h.year)]);
  // ICLR 1 was held in 2013. This edition-to-year mapping is specific to ICLR.
  if (conference === "ICLR") {
    const ordinals = ["first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth","thirteenth","fourteenth","fifteenth","sixteenth","seventeenth","eighteenth","nineteenth","twentieth"];
    const match = text.match(/\b(\d+(?:st|nd|rd|th)|[a-z]+) international conference on learning representations\b/);
    if (match) {
      const edition = /^\d/.test(match[1]) ? parseInt(match[1],10) : ordinals.indexOf(match[1]) + 1;
      if (edition >= 1 && edition <= 30) reliableYears.add(String(2012 + edition));
    }
  }
  if (reliableYears.size > 1) return null;
  const authoritative = reliableYears.size === 1;
  const openReview = /(^|\.)openreview\.net$/.test(host) || /openreview/i.test(context.libraryCatalog || "");
  // OpenReview submission dates cannot determine a conference year.
  const year = [...reliableYears][0] || (!openReview && String(date || "").match(/\b(?:19|20)\d{2}\b/)?.[0]);
  if (!year || +year > new Date().getFullYear() + 1) return null;
  return {conference,year,tag:conference + year,authoritative};
}
function resolve(venue, date, itemType, context = {}) {
  return resolveDetails(venue,date,itemType,context)?.tag || null;
}
// Manual tags are exact venue/year/status labels, not arbitrary topic tags.
function parseConferenceTag(value) {
  const compact = normalize(value).replace(/\s/g, "");
  const match = compact.match(/^([a-z]+)((?:19|20)\d{2})(oral|spotlight|poster|underreview)?$/);
  if (!match) return null;
  const short = match[1] === "nips" ? "neurips" : match[1];
  const conference = venues.find(([name]) => name.toLowerCase() === short)?.[0];
  if (!conference) return null;
  const status = {oral:"Oral",spotlight:"Spotlight",poster:"Poster",underreview:"UnderReview"}[match[3]] || "";
  return {conference,year:match[2],status,
    tag:conference + match[2] + (status ? ` ${status}` : ""),
    manual:true,authoritative:false};
}
function selectManualTag(tags) {
  const labels = tags.filter(tag => (tag.type ?? 0) === 0)
    .map(tag => parseConferenceTag(tag.tag)).filter(Boolean);
  if (!labels.length) return {present:false,details:null,conflict:false};
  const bases = new Set(labels.map(label => label.conference + label.year));
  const withStatus = labels.filter(label => label.status);
  const statuses = new Set(withStatus.map(label => label.status));
  if (bases.size !== 1 || statuses.size > 1) {
    return {present:true,details:null,conflict:true};
  }
  // A single richer status label takes precedence over a plain label for the same venue/year.
  return {present:true,details:withStatus[0] || labels[0],conflict:false};
}
const previous = Z.ConferenceYearTags;
if (previous) previous.dispose();
const win = Z.getMainWindow();
const prefKey = "extensions.actionsTags.conferenceYearTags.managed.v1";
let managed;
try { managed = JSON.parse(Z.Prefs.get(prefKey, true) || "{}"); }
catch (error) { Z.logError(error); throw new Error("Conference tag ownership data is invalid; stopping to preserve tags."); }
let disposed = false, timer = null;
const pending = new Set();
let queue = Promise.resolve(), managedDirty = false;
function flushManaged() {
  if (managedDirty) { Z.Prefs.set(prefKey,JSON.stringify(managed),true); managedDirty = false; }
}
const field = (item, name) => { try { return item.getField(name) || ""; } catch { return ""; } };
function resolveMetadataItem(item) {
  const venue = [...new Set(["proceedingsTitle", "conferenceName", "publicationTitle"]
    .map(name => field(item, name)).filter(Boolean))].join(" | ");
  return resolveDetails(venue,field(item,"date"),item.itemType,{
    url:field(item,"url"),extra:field(item,"extra"),libraryCatalog:field(item,"libraryCatalog")
  });
}
function resolveItem(item) {
  const manual = selectManualTag(item.getTags());
  return manual.present ? manual.details : resolveMetadataItem(item) || resolveAIItem(item);
}
function resolveAIItem(item) {
  // Existing venue metadata that failed local resolution may be conflicting or a workshop.
  // Keep that case blank rather than silently overriding it with a fallback.
  if (item.itemType !== "preprint" && ["proceedingsTitle","conferenceName","publicationTitle"].some(name => field(item,name))) return null;
  const line = field(item,"extra").split(/\r?\n/).find(line => line.startsWith("Conference AI: "));
  if (!line) return null;
  try {
    const data = JSON.parse(line.slice("Conference AI: ".length));
    const source = new URL(data.source_url);
    const allowed = ["arxiv.org","openaccess.thecvf.com","openreview.net","ecva.net","www.ecva.net",
      "proceedings.neurips.cc","papers.nips.cc","proceedings.iclr.cc","proceedings.mlr.press",
      "aclanthology.org","ojs.aaai.org","www.ijcai.org","ijcai.org","dl.acm.org"];
    if (source.protocol !== "https:" || !allowed.includes(source.hostname) ||
        normalize(data.title) !== normalize(field(item,"title")) || !data.evidence_quote) return null;
    const parsed = parseConferenceTag(`${data.conference}${data.year}`);
    if (!parsed || parsed.status || +parsed.year > new Date().getFullYear()+1) return null;
    // A verified fallback controls the badge; it does not rewrite publication dates or item types.
    return {...parsed,manual:false,authoritative:false};
  } catch { return null; }
}
async function update(item) {
  if (disposed || !item || !item.isRegularItem() || item.deleted ||
      item.libraryID !== Z.Libraries.userLibraryID) return;
  const key = `${item.libraryID}/${item.key}`;
  const manual = selectManualTag(item.getTags());
  const resolved = manual.present ? manual.details : resolveMetadataItem(item) || resolveAIItem(item);
  // Manual labels control display; never create duplicate auto tags or change metadata for them.
  const desired = manual.present ? null : resolved?.tag || null;
  const owned = managed[key];
  let changed = false;
  const date = field(item,"date");
  const dateYear = date.match(/\b(?:19|20)\d{2}\b/)?.[0];
  if (resolved?.authoritative && dateYear !== resolved.year) {
    if (date) {
      const extra = field(item,"extra");
      const original = `Original imported date: ${date}`;
      if (!extra.split(/\r?\n/).includes(original)) item.setField("extra",[extra,original].filter(Boolean).join("\n"));
    }
    // Preserve no month/day from a submission date when correcting publication year.
    item.setField("date",resolved.year); changed = true;
  }
  if (!changed && owned === desired && (!desired || item.hasTag(desired))) return;
  if (owned && owned !== desired && item.getTags().some(tag => tag.tag === owned && tag.type === 1)) {
    item.removeTag(owned); changed = true;
  }
  // Existing matching manual tags are left unowned so future corrections preserve them.
  // Another Mac may have synced this exact automatic tag without this machine's ownership cache.
  let newOwner = owned === desired ? owned :
    (!manual.present && item.getTags().some(tag => tag.type === 1 && tag.tag === desired) ? desired : null);
  if (desired && !item.hasTag(desired)) {
    item.addTag(desired, 1); changed = true; newOwner = desired;
  }
  if (changed) await item.saveTx();
  if ((managed[key] || null) !== (newOwner || null)) {
    if (newOwner) managed[key] = newOwner; else delete managed[key];
    managedDirty = true;
  }
}
function run(items) {
  queue = queue.catch(error => Z.logError(error)).then(async () => {
    try {
      let count = 0;
      for (const item of items) {
        if (disposed) break;
        await update(item);
        if (++count % 100 === 0) {
          flushManaged();
          await new Promise(resolve => win.setTimeout(resolve,0));
        }
      }
    } finally { flushManaged(); }
  });
  return queue;
}
const observerID = Z.Notifier.registerObserver({
  notify(event, type, ids) {
    if (disposed || type !== "item" || !["add", "modify"].includes(event)) return;
    for (const id of ids) pending.add(id);
    if (timer !== null) win.clearTimeout(timer);
    timer = win.setTimeout(() => {
      timer = null;
      const ids = [...pending]; pending.clear();
      void Z.Items.getAsync(ids).then(run).catch(error => Z.logError(error));
    }, 750);
  }
}, ["item"], "conference-year-tags", 50);
Z.ConferenceYearTags = {
  version: "1.2.0", resolve, resolveItem, selectManualTag, parseConferenceTag, run, venues: venues.map(([name]) => name),
  dispose() {
    disposed = true;
    Z.Notifier.unregisterObserver(observerID);
    if (timer !== null) win.clearTimeout(timer);
    pending.clear(); flushManaged();
  }
};
// Backfill the personal library once at startup; subsequently process changed items only.
await run(await Z.Items.getAll(Z.Libraries.userLibraryID, true, false));
// Compact sortable column, sharing the same venue/year rules as the tags.
// Keep the key stable so Zotero remembers visibility, width and position.
if (!Z.ConferenceYearTagsColumnKey) {
  Z.ConferenceYearTagsColumnKey = await Z.ItemTreeManager.registerColumn({
    dataKey: "conferenceYear", label: "会议年份", pluginID: "zoterotag@euclpts.com",
    enabledTreeIDs: ["main"], width: "220", minWidth: 130,
    zoteroPersist: ["width", "hidden", "sortDirection"],
    dataProvider: item => {
      if (!item.isRegularItem() || item.deleted) return "";
      return Z.ConferenceYearTags?.resolveItem(item)?.tag || "";
    },
    renderCell: (index, data, column, isFirstColumn, doc) => {
      const cell = doc.createElement("span");
      cell.className = `cell ${column.className || ""}`;
      cell.style.cssText = "display:flex;align-items:center;overflow:hidden;";
      if (!data) return cell;
      const parsed = parseConferenceTag(data);
      if (!parsed) return cell;
      const {conference,year,status} = parsed;
      const hues = {
        NeurIPS:270, ICML:215, ICLR:165, AAAI:350, IJCAI:290,
        AISTATS:195, UAI:240, COLT:130, CVPR:5, ICCV:25, ECCV:45,
        ACL:145, EMNLP:185, NAACL:225, EACL:175, COLING:310, CoNLL:255,
        ACMMM:330, KDD:35, SIGIR:200, WWW:155, WSDM:280,
        ICAPS:65, KR:95, AAMAS:15
      };
      const underReview = status === "UnderReview";
      const hue = underReview ? 215 : hues[conference] ?? 215;
      const badge = doc.createElement("span");
      badge.className = "conference-year-badge";
      badge.textContent = `${conference} ${year}`;
      if (status) {
        const state = doc.createElement("span");
        state.textContent = ` · ${underReview ? "Under Review" : status}`;
        state.style.fontWeight = status === "Oral" ? "800" : "500";
        badge.appendChild(state);
      }
      badge.title = badge.textContent;
      badge.style.cssText = `display:inline-block;box-sizing:border-box;max-width:100%;
        overflow:hidden;text-overflow:ellipsis;white-space:nowrap;
        border-radius:999px;padding:1px 8px;font-size:12px;font-weight:600;
        line-height:18px;letter-spacing:.1px;
        color:light-dark(hsl(${hue} ${underReview ? 12 : 65}% 30%),hsl(${hue} ${underReview ? 15 : 75}% 85%));
        background-color:light-dark(hsl(${hue} ${underReview ? 10 : 70}% 94%),hsl(${hue} ${underReview ? 10 : 35}% 24%));
        border:1px ${underReview ? "dashed" : "solid"} light-dark(hsl(${hue} ${underReview ? 12 : 50}% 82%),hsl(${hue} ${underReview ? 12 : 40}% 42%));`;
      cell.appendChild(badge);
      return cell;
    }
  });
}
return `Conference year tags active: ${venues.length} venues`;
