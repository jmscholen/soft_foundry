// Soft Foundry: the page served by `soft-foundry ui`.
// It reads three JSON endpoints and draws them. Everything from a change
// record is data someone else may have written, so it only ever reaches
// the page as a text node or an attribute value, never as markup.
(function () {
  "use strict";

  var POLL_MS = 5000;

  // One word and one shape for each state a gate can be in.
  var STATES = {
    pass: "Pass",
    warn: "Pass, with warnings",
    fail: "Fail",
    stale: "Stale",
    in_progress: "In progress",
    blocked: "Blocked",
    pending: "Pending",
    missing: "Missing",
    complete: "Complete, as recorded"
  };
  var SKIPS = { waived: "Waived", track: "Not on this track", optional: "Optional" };
  var SKIP_REASONS = {
    waived: "Waived for this change",
    track: "Not required on this change's track",
    optional: "Optional for every change, and not started"
  };
  var OUTCOMES = { pass: "Pass", fail: "Fail", warn: "Warning", skip: "Skipped" };
  var EVENTS = {
    created: "Created", started: "Started", completed: "Completed", iteration: "Iteration",
    vetted: "Vetted", reopened: "Reopened", human_decision: "Decision", spend: "Spend"
  };
  var CONDITIONS = {
    on_code_change: "when code changed",
    on_blocking_findings: "on blocking findings",
    on_blocked: "when the judgment is BLOCKED",
    on_rejected: "when the judgment is REJECTED"
  };

  var main = document.getElementById("main");
  var updated = document.getElementById("updated");
  var announce = document.getElementById("announce");
  var pause = document.getElementById("pause");
  var live = updated.parentNode;

  var view = { name: null, repo: null, slug: null, phase: null };
  var repos = null; // every repository the server knows
  var workflows = {}; // each repository's lifecycle, by repository id

  // The link the command printed carries a token after the #. It is kept
  // for this tab, taken out of the address bar, and sent with each request
  // for data.
  var TOKEN_KEY = "soft-foundry-token";
  var token = null;
  try { token = sessionStorage.getItem(TOKEN_KEY); } catch (e) { token = null; }
  function takeToken() {
    var given = /^#token=([\w-]+)/.exec(location.hash);
    if (!given) return;
    token = given[1];
    try { sessionStorage.setItem(TOKEN_KEY, token); } catch (e) { /* kept in memory for this page */ }
    history.replaceState(null, "", location.pathname + "#/");
  }
  takeToken();
  var shown = null; // the data on screen, without its timestamp
  var current = null; // the data the view on screen was drawn from
  var running = null; // soft-foundry processes on this machine
  var paused = false;

  // --- building blocks -------------------------------------------------

  function el(tag, attrs) {
    var node = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (name) {
      var value = attrs[name];
      if (value === null || value === undefined || value === false) return;
      if (name === "text") node.textContent = String(value);
      else if (name === "class") node.className = value;
      else node.setAttribute(name, value === true ? "" : String(value));
    });
    for (var i = 2; i < arguments.length; i++) add(node, arguments[i]);
    return node;
  }

  function add(node, child) {
    if (child === null || child === undefined || child === false) return;
    if (Array.isArray(child)) child.forEach(function (c) { add(node, c); });
    else node.appendChild(typeof child === "object" ? child : document.createTextNode(String(child)));
  }

  function mark(state) {
    return el("span", { class: "mark", "data-state": state, "aria-hidden": "true" });
  }

  function gateState(cell) {
    return cell.state === "pending" && cell.skip_reason ? "skipped" : cell.state;
  }

  function gateWord(cell) {
    if (cell.state === "pending" && cell.skip_reason) return SKIPS[cell.skip_reason] || "Skipped";
    return STATES[cell.state] || String(cell.state);
  }

  function number(index) {
    return index < 10 ? "0" + index : String(index);
  }

  function plural(count, one, many) {
    return count + " " + (count === 1 ? one : many);
  }

  // A recorded time, shown as recorded. Times in a record are what its
  // author wrote; they are not corrected here.
  function when(value) {
    if (!value) return "not recorded";
    var match = /^(\d{4}-\d\d-\d\d)T(\d\d:\d\d)(?::\d\d(?:\.\d+)?)?Z$/.exec(value);
    return el("time", { datetime: value, text: match ? match[1] + " " + match[2] + " UTC" : value });
  }

  function words(id) {
    return String(id).replace(/_/g, " ");
  }

  function money(amount) {
    return amount === null || amount === undefined ? "not priced" : "$" + Number(amount).toFixed(2);
  }

  // What a check establishes, in the words of this repository's workflow.
  function describe(name) {
    var flow = workflows[currentRepo()];
    return flow && flow.check_descriptions ? flow.check_descriptions[name] : null;
  }

  // --- repositories ----------------------------------------------------------

  function repoList() {
    return repos && repos.repositories || [];
  }

  function homeRepo() {
    var home = repoList().filter(function (repo) { return repo.home; })[0];
    return home ? home.id : null;
  }

  // The repository the view on screen is about.
  function currentRepo() {
    return view.repo || homeRepo();
  }

  function repoNamed(id) {
    return repoList().filter(function (repo) { return repo.id === id; })[0] || null;
  }

  function repoName(id) {
    var repo = repoNamed(id);
    return repo ? repo.name : "this repository";
  }

  function repoHref(id, tail) {
    return (id ? "#/r/" + encodeURIComponent(id) : "#") + "/" + (tail || "changes");
  }

  // Where you are: every repository view starts with the repository's
  // name and its two pages.
  function crumbs(page) {
    var id = currentRepo();
    var repo = repoNamed(id);
    return el("nav", { class: "crumbs", "aria-label": "Repository" },
      el("a", { href: "#/", text: "Repositories" }),
      el("span", { class: "sep", "aria-hidden": "true", text: "/" }),
      el("span", { class: "repo", text: repoName(id) }),
      repo && repo.path ? el("span", { class: "mono path", text: repo.path }) : null,
      el("span", { class: "tabs" },
        el("a", { href: repoHref(id), "aria-current": page === "changes" ? "page" : null, text: "Changes" }),
        el("a", { href: repoHref(id, "workflow"), "aria-current": page === "workflow" ? "page" : null, text: "Workflow" })));
  }

  // What a process is doing, in a few words: "phase run verify", "ui".
  function doing(process) {
    return process.command + (process.phase ? " " + words(process.phase) : "");
  }

  // Commands in the repository on screen working on one change, other
  // than the server drawing this page.
  function activeFor(slug) {
    return (running && running.processes || []).filter(function (process) {
      return process.repo === currentRepo() && !process.self && process.change === slug;
    });
  }

  function interruptedFor(slug) {
    return (running && running.recorded_runs || []).filter(function (run) {
      return run.repo === currentRepo() && run.change === slug && !run.live;
    });
  }

  function others() {
    return (running && running.processes || []).filter(function (process) { return !process.self; });
  }

  // Coding shells a person has open, in any Soft Foundry repository.
  function sessions() {
    return running && running.sessions || [];
  }

  function sessionsFor(slug) {
    return sessions().filter(function (session) { return session.repo === currentRepo() && session.change === slug; });
  }

  function sessionsIn(id) {
    return sessions().filter(function (session) { return session.repo === id; });
  }

  function commandsIn(id) {
    return others().filter(function (process) { return process.repo === id; });
  }

  function hereSentence() {
    var parts = [];
    var open = sessionsIn(currentRepo()).length;
    var busy = commandsIn(currentRepo()).length;
    if (open) parts.push(plural(open, "coding-shell session", "coding-shell sessions"));
    if (busy) parts.push(plural(busy, "Soft Foundry command", "Soft Foundry commands"));
    return parts.join(" and ");
  }

  // A session in a sentence: "claude in ttys004 on change/x".
  function sessionPhrase(session) {
    return session.shell + (session.terminal ? " in " + session.terminal : "") + (session.branch ? " on " + session.branch : "");
  }

  function reposView(data) {
    var list = data.repositories;
    var open = sessions().length;
    document.title = "Repositories · Soft Foundry";
    return [
      el("h1", { tabindex: "-1", text: "Repositories" }),
      el("p", { class: "lede", text: plural(list.length, "Soft Foundry repository", "Soft Foundry repositories") + " on this machine: the one this page was started in" +
        (list.length > 1 ? ", and every one with a session or a command running." : ". Others appear here when a session or a command is running in them.") +
        " " + (open ? plural(open, "coding-shell session is", "coding-shell sessions are") + " open across them." : "No coding-shell session is open in any of them.") }),
      el("ul", { class: "repos" }, list.map(function (repo) {
        var open = sessionsIn(repo.id);
        var busy = commandsIn(repo.id);
        return el("li", { class: "repo-card", "data-live": open.length || busy.length ? true : null },
          el("h2", {}, el("a", { href: repoHref(repo.id), "data-key": "repo:" + repo.id, text: repo.name })),
          el("p", { class: "mono path", text: repo.path || "" }),
          repo.home ? el("p", { class: "meta", text: "This page was started here." }) : null,
          repo.error ? el("p", { class: "note", "data-tone": "flaw", text: "Its records could not be read: " + repo.error }) : null,
          el("h3", { text: "Sessions" }),
          open.length ? el("ul", { class: "plain" }, open.map(function (session) {
            return el("li", {}, sessionPhrase(session), session.change ? [": ",
              el("a", { href: changeHref(session.change, null, repo.id), text: session.change }),
              session.phase ? ", phase " + words(session.phase) : ""] : ": no change record for that branch");
          })) : el("p", { class: "empty", text: "No coding shell is open here." }),
          busy.length ? [el("h3", { text: "Commands running" }), el("ul", { class: "plain" }, busy.map(function (process) {
            return el("li", { text: "soft-foundry " + doing(process) + (process.change ? " on " + process.change : "") });
          }))] : null,
          el("h3", { text: "Open changes (" + repo.open + ")" }),
          repo.changes.length ? el("ul", { class: "plain" }, repo.changes.map(function (change) {
            return el("li", {}, el("a", { href: changeHref(change.slug, null, repo.id), text: change.slug }),
              change.error ? ": could not be read" : ": " + words(change.status || "no status") + (change.current_phase ? ", phase " + words(change.current_phase) : ""));
          })) : el("p", { class: "empty", text: "No change is open." }),
          el("p", { class: "meta" }, repo.closed + " closed. ", el("a", { href: repoHref(repo.id), text: "All changes and gates in " + repo.name })));
      }))
    ];
  }

  function changeHref(slug, phase, repo) {
    return repoHref(repo || currentRepo(), "change/" + encodeURIComponent(slug) + (phase ? "/" + encodeURIComponent(phase) : ""));
  }

  // --- the board ---------------------------------------------------------

  function boardView(board) {
    var open = board.changes.filter(function (c) { return !c.closed; });
    var closed = board.changes.filter(function (c) { return c.closed; });
    var failing = open.filter(function (c) { return c.failed || c.error; }).length;
    var unclosed = open.filter(function (c) { return c.merged_unclosed; }).length;
    var lede = plural(open.length, "open change", "open changes") + ", " +
      (failing ? failing + " with a failing gate" : "none failing") +
      (unclosed ? ", " + unclosed + " merged but not closed" : "") + ". " +
      plural(closed.length, "closed record", "closed records") + ".";

    document.title = "Changes · " + repoName(currentRepo()) + " · Soft Foundry";
    return [
      crumbs("changes"),
      el("h1", { tabindex: "-1", text: "Changes in " + repoName(currentRepo()) }),
      el("p", { class: "lede", text: board.changes.length ? lede : "" }),
      hereSentence() ? el("p", { class: "meta" }, "In this repository now: " + hereSentence() + ". ",
        el("a", { href: "#/running", text: "See everything that is running" })) : null,
      board.changes.length ? null : el("p", { class: "empty" },
        "No change records yet. Create one with ", el("code", { text: "soft-foundry change new <slug>" }), "."),
      open.length ? boardSection("Open", "open", board.phases, open,
        "Each gate is evaluated now, against the code and records as they stand.") : null,
      closed.length ? boardSection("Closed", "closed", board.phases, closed,
        "Closed records show what their handoffs recorded. They are not gated again here; open one to gate it.") : null,
      board.changes.length ? legend() : null
    ];
  }

  function boardSection(title, key, phases, changes, caption) {
    var head = el("tr", {}, el("th", { scope: "col", text: "Change" }), phases.map(function (phase, i) {
      return el("th", { scope: "col", "data-optional": phase.optional },
        el("span", { class: "num", text: number(i) }),
        el("span", { class: "name", text: phase.id.replace(/_/g, " ") }));
    }));
    return el("section", { "aria-labelledby": "board-" + key },
      el("h2", { id: "board-" + key, text: title + " (" + changes.length + ")" }),
      el("div", { class: "scroller", tabindex: "0", role: "group", "aria-labelledby": "board-" + key },
        el("table", { class: "board" },
          el("caption", { class: "sr-only", text: title + " changes, one column per phase. " + caption }),
          el("thead", {}, head),
          el("tbody", {}, changes.map(function (change) { return boardRow(change, phases); })))),
      el("p", { class: "meta", text: caption }));
  }

  function boardRow(change, phases) {
    var flags = [];
    if (change.error) flags.push(["Unreadable", "flaw"]);
    if (change.failed && !change.stale) flags.push(["Failing", "flaw"]);
    if (change.stale) flags.push(["Stale evidence", "cold"]);
    if (change.merged_unclosed) flags.push(["Merged, not closed", "flaw"]);
    if (change.exploring) flags.push(["Exploring", "pour"]);
    if (change.advisories) flags.push([plural(change.advisories, "advisory", "advisories"), "pour"]);
    sessionsFor(change.slug).forEach(function (session) { flags.push(["Session open: " + session.shell, "pour"]); });
    activeFor(change.slug).forEach(function (process) { flags.push(["Running: " + doing(process), "pour"]); });
    if (interruptedFor(change.slug).length) flags.push(["Interrupted run", "flaw"]);

    var name = el("th", { scope: "row" },
      el("a", { href: changeHref(change.slug), "data-key": "row:" + change.slug, text: change.slug }),
      change.title && change.title !== change.slug ? el("span", { class: "title", text: change.title }) : null,
      flags.length ? el("span", { class: "flags" }, flags.map(function (flag) {
        return el("span", { class: "flag", "data-tone": flag[1], text: flag[0] });
      })) : null);

    if (change.error) {
      return el("tr", {}, name, el("td", { colspan: phases.length, class: "detail", text: "This record could not be read: " + change.error }));
    }
    return el("tr", {}, name, change.cells.map(function (cell) {
      var word = gateWord(cell);
      return el("td", { title: cell.phase.replace(/_/g, " ") + ": " + word },
        mark(gateState(cell)), el("span", { class: "sr-only", text: word }));
    }));
  }

  function legend() {
    var entries = Object.keys(STATES).map(function (state) { return [state, STATES[state]]; });
    entries.push(["skipped", "Waived, optional, or not required on the track"]);
    return el("section", { "aria-labelledby": "legend" },
      el("h2", { id: "legend", text: "Key" }),
      el("ul", { class: "legend" }, entries.map(function (entry) {
        return el("li", {}, mark(entry[0]), entry[1]);
      })));
  }

  // --- one change --------------------------------------------------------

  // Which run of the line a gate belongs to: metal has reached it
  // (poured), is in it now (molten), went wrong (flawed, cold), has not
  // arrived (pending), or was routed past it (skipped).
  function run(gate) {
    switch (gate.state) {
      case "pass": case "warn": case "complete": return "poured";
      case "in_progress": return "molten";
      case "fail": case "blocked": case "missing": return "flawed";
      case "stale": return "cold";
      default: return gate.skip_reason ? "skipped" : "pending";
    }
  }

  function defaultGate(gates) {
    var pick = function (states) {
      return gates.filter(function (g) { return states.indexOf(g.state) >= 0; })[0];
    };
    var done = gates.filter(function (g) { return g.state !== "pending"; });
    return pick(["fail", "missing", "blocked"]) || pick(["stale"]) || pick(["in_progress"]) || done[done.length - 1] || gates[0];
  }

  function trackSentence(track, risk) {
    if (!track.defined) return "Track “" + track.name + "” is not defined in .ai/workflow.yml.";
    var text = track.name.charAt(0).toUpperCase() + track.name.slice(1) + " track";
    if (track.exploring) {
      text += ", exploring: " + plural(track.iterations, "iteration", "iterations") + " recorded" +
        (track.last_deployed ? ", last deployed to " + track.last_deployed : "") + ". Not yet vetted by a person";
    } else if (track.vetted) {
      text += ", vetted by " + track.vetted.by + " at " + track.vetted.commit.slice(0, 12) + "; the specification is locked";
    } else if (track.exploring_stage) {
      text += "; the exploring stage was not entered";
    }
    if (track.forced_by_risk && track.forced_by_risk !== track.name) {
      text += ". Risk " + risk + " requires the " + track.forced_by_risk + " track";
    }
    return text + ".";
  }

  function changeView(change) {
    var selected = change.gates.filter(function (g) { return g.phase === view.phase; })[0] || defaultGate(change.gates);
    var failing = change.gates.filter(function (g) { return ["fail", "missing", "blocked"].indexOf(g.state) >= 0; }).length;
    var stale = change.gates.filter(function (g) { return g.state === "stale"; }).length;

    document.title = (change.title || change.slug) + " · Soft Foundry";
    return [
      crumbs("changes"),
      el("h1", { tabindex: "-1", text: change.title || change.slug }),
      el("p", { class: "meta" },
        el("span", { class: "mono", text: change.slug }),
        el("span", { text: "Status: " + (change.status || "not recorded") }),
        el("span", { text: "Risk: " + (change.risk || "not recorded") }),
        el("span", { text: "Type: " + (change.type || "not recorded") }),
        change.branch ? el("span", {}, "Branch: ", el("span", { class: "mono", text: change.branch })) : null),
      el("p", { class: "lede", text: trackSentence(change.track, change.risk) }),
      change.merged_unclosed ? el("p", { class: "note", "data-tone": "flaw" },
        "This change is merged but its record is not closed, which fails ", el("code", { text: "soft-foundry ci" }), ". Close it with ",
        el("code", { text: "soft-foundry change close " + change.slug }), ".") : null,
      change.closed ? el("p", { class: "note" },
        "This record is closed. " + (stale ? "Its stale gates mean code has changed since its evidence was recorded, which is expected once a change has merged." :
          "Its gates are evaluated here against the code as it stands now.")) : null,
      !change.closed && failing ? el("p", { class: "note", "data-tone": "flaw", text: plural(failing, "gate is", "gates are") + " failing. Select one to see which checks." }) : null,
      !change.closed && stale ? el("p", { class: "note", "data-tone": "flaw", text: plural(stale, "gate has", "gates have") + " stale evidence: code changed after the commit the evidence describes. Rerun from verification." }) : null,

      sessionsFor(change.slug).map(function (session) {
        return el("p", { class: "note", "data-tone": "pour" },
          "A " + session.shell + " session is open on this change" + (session.terminal ? " in terminal " + session.terminal : "") +
          ", pid " + session.pid + ", since ", when(session.started_at), ".");
      }),
      activeFor(change.slug).map(function (process) {
        return el("p", { class: "note", "data-tone": "pour" },
          "Running now: ", el("code", { text: "soft-foundry " + process.command + (process.phase ? " " + process.phase : "") }),
          process.session ? " in a " + process.session.name + " session (pid " + process.session.pid + ")" : "",
          ", pid " + process.pid + ", since ", when(process.started_at), ".");
      }),
      interruptedFor(change.slug).map(function (interrupted) {
        return el("p", { class: "note", "data-tone": "flaw" },
          "A " + interrupted.shell + " session was started for " + words(interrupted.phase) + " at ", when(interrupted.started_at),
          " and never recorded as finished, and no such process is running. It was probably interrupted; run the phase again.");
      }),

      el("section", { "aria-labelledby": "line-title" },
        el("h2", { id: "line-title", text: "Gates" }),
        el("ol", { class: "line" }, change.gates.map(function (gate, i) {
          var open = gate.phase === selected.phase;
          var live = activeFor(change.slug).some(function (process) { return process.phase === gate.phase || process.phase === gate.output; });
          return el("li", {}, el("button", {
            type: "button", class: "gate", "data-run": live ? "molten" : run(gate), "data-phase": gate.phase, "data-key": "gate:" + gate.phase,
            "aria-expanded": open ? "true" : "false", "aria-controls": "gate-panel"
          },
            el("span", { class: "num", text: number(i) }),
            el("span", { class: "name", text: gate.phase.replace(/_/g, " ") }),
            el("span", { class: "state" }, mark(gateState(gate)), gateWord(gate) + (live ? ", running now" : ""))));
        })),
        gatePanel(selected, change.gates.indexOf(selected))),

      el("section", { "aria-labelledby": "advice-title" },
        el("h2", { id: "advice-title", text: "Before this goes live" }),
        change.advisories.length ? [
          el("p", { class: "meta", text: "Advisories do not fail a gate. They name what a person should settle before shipping." }),
          el("ul", { class: "plain" }, change.advisories.map(function (notice) {
            return el("li", {}, el("span", { class: "area", text: notice.area }), notice.message);
          }))
        ] : el("p", { class: "empty", text: "No advisories." })),

      timelineSection(change.timeline),
      spendSection(change.spend),

      change.undischarged.length ? el("section", { "aria-labelledby": "owed-title" },
        el("h2", { id: "owed-title", text: "Awaiting confirmation" }),
        el("ul", { class: "plain" }, change.undischarged.map(function (item) {
          return el("li", {}, el("span", { class: "area", text: item.id }), item.description);
        }))) : null
    ];
  }

  function gatePanel(gate, index) {
    var summary;
    if (gate.state === "pending") {
      summary = gate.skip_reason ? SKIP_REASONS[gate.skip_reason] + (gate.skip_rationale ? ": " + gate.skip_rationale : ".") :
        "Not started. Nothing is gated until the phase is marked complete.";
    } else if (gate.state === "missing") {
      summary = "This phase has no handoff.yml, so there is nothing to gate.";
    } else {
      var failed = gate.checks.filter(function (c) { return c.outcome === "fail"; }).length;
      summary = "Handoff status: " + gate.status.replace(/_/g, " ") + ". " +
        (failed ? plural(failed, "check fails", "checks fail") + "." : plural(gate.checks.length, "check", "checks") + ", none failing.");
    }

    var ranBy = gate.executed_by ? "soft-foundry phase run" +
      (gate.executed_by.shell ? " (" + gate.executed_by.shell + (gate.executed_by.fresh_context ? ", fresh session" : "") + ")" : "") : "not recorded";

    return el("div", { class: "panel", id: "gate-panel", role: "region", "aria-labelledby": "gate-title" },
      el("h3", { id: "gate-title" }, number(index) + " " + gate.phase.replace(/_/g, " ") + ": ", gateWord(gate)),
      el("p", { class: "summary", text: summary }),
      el("dl", { class: "facts" },
        el("dt", { text: "Directory" }), el("dd", { class: "mono", text: gate.output }),
        el("dt", { text: "Skill" }), el("dd", { class: "mono", text: gate.skill }),
        el("dt", { text: "Started" }), el("dd", {}, when(gate.started_at)),
        el("dt", { text: "Completed" }), el("dd", {}, when(gate.completed_at)),
        el("dt", { text: "Commit" }), el("dd", { class: "mono", text: gate.commit_sha ? String(gate.commit_sha).slice(0, 12) : "not recorded" }),
        el("dt", { text: "Run by" }), el("dd", { text: ranBy })),
      gate.state === "pending" || gate.state === "missing" ? null : [
        el("h4", { text: "Checks" }),
        el("ul", { class: "checks" }, gate.checks.map(function (check) {
          return el("li", { "data-outcome": check.outcome },
            mark(check.outcome),
            el("span", { class: "outcome", text: OUTCOMES[check.outcome] || check.outcome }),
            el("span", { class: "what" }, check.name,
              check.detail ? el("span", { class: "detail", text: check.detail }) : null,
              describe(check.name) ? el("span", { class: "detail", text: "Checks: " + describe(check.name) }) : null));
        }))
      ],
      gate.blocking.length ? [el("h4", { text: "Blocking" }), el("ul", { class: "plain" }, gate.blocking.map(function (item) {
        return el("li", { text: typeof item === "string" ? item : JSON.stringify(item) });
      }))] : null,
      gate.findings.length ? [el("h4", { text: "Findings for later phases" }), el("ul", { class: "plain" }, gate.findings.map(function (finding) {
        return el("li", {}, el("span", { class: "area", text: [finding.id, finding.severity].filter(Boolean).join(" · ") }), finding.summary);
      }))] : null);
  }

  function timelineSection(events) {
    return el("section", { "aria-labelledby": "timeline-title" },
      el("h2", { id: "timeline-title", text: "Timeline" }),
      events.length ? [
        el("p", { class: "meta", text: "Oldest first. Times are shown as the change's files record them; some were typed by hand." }),
        el("ol", { class: "timeline" }, events.map(function (event) {
          return el("li", {},
            when(event.at),
            el("span", { class: "kind", text: EVENTS[event.kind] || event.kind }),
            el("span", { class: "label", text: event.label }));
        }))
      ] : el("p", { class: "empty", text: "No times are recorded for this change yet." }));
  }

  function spendSection(spend) {
    var totals = spend.totals;
    var policy = spend.policy;
    var caps = policy ? [
      policy.max_usd_per_change !== null ? "cap " + money(policy.max_usd_per_change) + " per change" : null,
      policy.max_usd_per_phase !== null ? money(policy.max_usd_per_phase) + " per phase" : null,
      policy.require_human_approval_above_usd !== null ? "a person approves above " + money(policy.require_human_approval_above_usd) : null
    ].filter(Boolean).join(", ") : "";

    return el("section", { "aria-labelledby": "spend-title" },
      el("h2", { id: "spend-title", text: "Spend" }),
      spend.entries.length ? [
        el("p", { class: "lede", text: "Recorded " + money(totals.estimated_usd) + " across " + plural(spend.entries.length, "entry", "entries") +
          ": " + totals.tokens_in + " tokens in, " + totals.tokens_out + " out." +
          (totals.entries_missing_cost ? " " + plural(totals.entries_missing_cost, "entry has", "entries have") + " no cost." : "") }),
        caps ? el("p", { class: "meta", text: "Budget policy for this change's risk: " + caps + ". It applies when usage is metered, not on a subscription." }) : null,
        totals.over_cap ? el("p", { class: "note", "data-tone": "flaw", text: "Over the cap for one change. Continuing is a financial commitment that needs a person's approval." }) :
          totals.needs_approval ? el("p", { class: "note", "data-tone": "pour", text: "Above the amount a person must approve before work continues." }) : null,
        el("div", { class: "scroller", tabindex: "0", role: "group", "aria-labelledby": "spend-title" },
          el("table", { class: "spend" },
            el("caption", { class: "sr-only", text: "Recorded spend by phase" }),
            el("thead", {}, el("tr", {}, ["Phase", "Tokens in", "Tokens out", "Estimated cost", "Entries", "Against the phase cap"].map(function (heading) {
              return el("th", { scope: "col", text: heading });
            }))),
            el("tbody", {}, spend.by_phase.map(function (row) {
              return el("tr", {},
                el("th", { scope: "row", text: words(row.phase) }),
                el("td", { text: row.tokens_in }), el("td", { text: row.tokens_out }),
                el("td", { text: money(row.estimated_usd) }), el("td", { text: row.entries }),
                el("td", { class: row.over_cap ? "over" : null, text: row.over_cap ? "Over" : row.estimated_usd === null ? "Unknown" : "Within" }));
            }))))
      ] : el("p", { class: "empty" }, "No spend is recorded. Whoever runs a phase records it with ",
        el("code", { text: "soft-foundry budget record" }), "."));
  }

  // --- what is running ------------------------------------------------------

  function runningView(data) {
    var list = data.processes;
    var elsewhere = list.filter(function (p) { return !p.self; });
    var place = function (entry) {
      return entry.repo ? el("a", { href: repoHref(entry.repo), text: repoName(entry.repo) }) : entry.repository || "not in a Soft Foundry repository";
    };
    var interrupted = data.recorded_runs.filter(function (r) { return !r.live; });
    var open = data.sessions || [];
    var across = open.map(function (s) { return s.repo; }).filter(function (id, i, all) { return id && all.indexOf(id) === i; }).length;

    document.title = "Running · Soft Foundry";
    return [
      el("h1", { tabindex: "-1", text: "Running" }),
      data.error ? el("p", { class: "note", "data-tone": "flaw", text: "The process list could not be read: " + data.error }) : null,
      el("p", { class: "lede", text: open.length || elsewhere.length ?
        plural(open.length, "coding-shell session is", "coding-shell sessions are") + " open across " + plural(across, "Soft Foundry repository", "Soft Foundry repositories") + " on this machine. " +
        plural(elsewhere.length, "Soft Foundry command is", "Soft Foundry commands are") + " running besides this page." :
        "Nothing else is running. The server drawing this page is the only Soft Foundry process on this machine, and no coding shell is open in a Soft Foundry repository." }),
      el("section", { "aria-labelledby": "sessions-title" },
        el("h2", { id: "sessions-title", text: "Sessions" }),
        open.length ? el("div", { class: "scroller", tabindex: "0", role: "group", "aria-labelledby": "sessions-title" },
          el("table", { class: "spend procs" },
            el("caption", { class: "sr-only", text: "Coding-shell sessions open in Soft Foundry repositories, oldest first" }),
            el("thead", {}, el("tr", {}, ["Session", "Change", "Branch", "Terminal", "Repository", "Started", "Process"].map(function (heading) {
              return el("th", { scope: "col", text: heading });
            }))),
            el("tbody", {}, open.map(function (session) {
              var where = [session.phase ? "phase " + words(session.phase) : null, session.status ? words(session.status) : null].filter(Boolean).join(", ");
              return el("tr", {},
                el("th", { scope: "row", text: session.shell }),
                el("td", {}, session.change ? [
                  session.repo ? el("a", { href: changeHref(session.change, null, session.repo), "data-key": "session:" + session.pid, text: session.change }) : session.change,
                  where ? el("span", { class: "detail", text: where }) : null
                ] : "no change record for this branch"),
                el("td", { class: "mono", text: session.branch || "unknown" }),
                el("td", { class: "mono", text: session.terminal || "none" }),
                el("td", {}, place(session)),
                el("td", {}, when(session.started_at)),
                el("td", { class: "mono", text: "pid " + session.pid }));
            })))) : el("p", { class: "empty", text: "No claude, codex, or grok session is open in a repository that has a Soft Foundry control plane." }),
        el("p", { class: "meta", text: "A session is a claude, codex, or grok process whose working directory is inside a repository with .ai/workflow.yml. Its change is the one its repository's checked-out branch belongs to, and the phase and status are what that change's record says, not what the session is doing at this moment." })),
      el("section", { "aria-labelledby": "procs-title" },
        el("h2", { id: "procs-title", text: "Commands" }),
        list.length ? el("div", { class: "scroller", tabindex: "0", role: "group", "aria-labelledby": "procs-title" },
          el("table", { class: "spend procs" },
            el("caption", { class: "sr-only", text: "Running Soft Foundry processes, oldest first" }),
            el("thead", {}, el("tr", {}, ["Doing", "Change", "Session", "Repository", "Started", "Process"].map(function (heading) {
              return el("th", { scope: "col", text: heading });
            }))),
            el("tbody", {}, list.map(function (process) {
              return el("tr", { "data-self": process.self },
                el("th", { scope: "row" }, doing(process), process.port ? " on port " + process.port : "", process.self ? " (this page)" : ""),
                el("td", {}, process.change ? (process.repo ? el("a", { href: changeHref(process.change, process.command === "phase run" ? process.phase : null, process.repo), "data-key": "proc:" + process.pid, text: process.change }) : process.change) : "none"),
                el("td", { text: process.session ? process.session.name + ", pid " + process.session.pid : process.shell ? process.shell + ", not started yet or already ended" : "none" }),
                el("td", {}, place(process)),
                el("td", {}, when(process.started_at)),
                el("td", { class: "mono", text: "pid " + process.pid }));
            })))) : el("p", { class: "empty", text: "No processes." }),
        el("p", { class: "meta", text: "Every command started as soft-foundry by your user account, in any repository, read from the process list. A session a phase runner launched is shown with its runner here, not under Sessions." })),
      interrupted.length ? el("section", { "aria-labelledby": "stopped-title" },
        el("h2", { id: "stopped-title", text: "Started and never finished" }),
        el("p", { class: "meta", text: "A repository's records say a phase run began, nothing recorded its end, and no process is running it." }),
        el("ul", { class: "plain" }, interrupted.map(function (r) {
          return el("li", {}, repoName(r.repo) + ": ", el("a", { href: changeHref(r.change, r.phase, r.repo), text: r.change }), ": " + words(r.phase) + ", " + r.shell + " session, started ", when(r.started_at));
        }))) : null
    ];
  }

  // --- the workflow ---------------------------------------------------------

  function waysBack(flow) {
    var order = flow.phases.map(function (p) { return p.id; });
    var edges = [];
    Object.keys(flow.transitions).forEach(function (from) {
      var edge = flow.transitions[from];
      Object.keys(edge).forEach(function (key) {
        var linear = key === "next" && order.indexOf(edge[key]) === order.indexOf(from) + 1;
        if (!linear) edges.push({ from: from, to: edge[key], when: key === "next" ? "always" : CONDITIONS[key] || words(key) });
      });
    });
    return edges;
  }

  function phasePanel(flow, phase, index) {
    var loops = waysBack(flow).filter(function (edge) { return edge.from === phase.id; });
    var summary = "Worked by the " + phase.skill + " skill into " + phase.output + "/. " +
      (phase.optional ? "Optional: it may stay pending if the change does not need it. " : "") +
      (phase.hardening ? "A hardening phase: it cannot be complete while a change is still exploring. " : "") +
      (phase.commit_bound ? "Its evidence is bound to a commit and goes stale when code changes after it." : "");

    return el("div", { class: "panel", id: "gate-panel", role: "region", "aria-labelledby": "gate-title" },
      el("h3", { id: "gate-title", text: number(index) + " " + words(phase.id) }),
      el("p", { class: "summary", text: summary }),
      el("dl", { class: "facts" },
        el("dt", { text: "Directory" }), el("dd", { class: "mono", text: phase.output }),
        el("dt", { text: "Skill" }), el("dd", { class: "mono", text: phase.skill }),
        el("dt", { text: "Model profile" }), el("dd", { class: "mono", text: phase.profile || "not set" }),
        phase.after ? [el("dt", { text: "Follows" }), el("dd", { text: words(phase.after) + ", not the phase before it in the list" })] : null,
        el("dt", { text: "Then" }), el("dd", { text: phase.next === "done" ? "the lifecycle ends" : words(phase.next) }),
        loops.length ? [el("dt", { text: "Can return to" }), el("dd", { text: loops.map(function (edge) { return words(edge.to) + " (" + edge.when + ")"; }).join(", ") })] : null),
      el("h4", { text: "What its gate checks once the phase is marked complete" }),
      el("ul", { class: "explain" }, phase.checks.map(function (check) {
        return el("li", {}, el("span", { class: "term", text: check.name }), el("span", { class: "detail", text: check.description }));
      })),
      el("h4", { text: "Files it must produce" }),
      phase.required_files.length ? el("ul", { class: "inline" }, phase.required_files.map(function (file) { return el("li", { text: file }); })) :
        el("p", { class: "empty", text: "None listed." }),
      phase.blocking.length ? [el("h4", { text: "Conditions that block it" }),
        el("ul", { class: "inline" }, phase.blocking.map(function (item) { return el("li", { text: words(item) }); }))] : null);
  }

  function workflowView(flow) {
    var selected = flow.phases.filter(function (p) { return p.id === view.phase; })[0] || flow.phases[0];
    var edges = waysBack(flow);
    var forced = Object.keys(flow.tracks.forced_by_risk);

    document.title = "Workflow · " + repoName(currentRepo()) + " · Soft Foundry";
    return [
      crumbs("workflow"),
      el("h1", { tabindex: "-1", text: "Workflow in " + repoName(currentRepo()) }),
      el("p", { class: "lede", text: "Every change runs these " + flow.phases.length + " phases in order. A phase is done when its gate passes, and a gate only passes once the phase before it is complete; optional and waived phases are stepped over." }),
      el("section", { "aria-labelledby": "line-title" },
        el("h2", { id: "line-title", text: "Phases" }),
        el("ol", { class: "line" }, flow.phases.map(function (phase, i) {
          return el("li", {}, el("button", {
            type: "button", class: "gate", "data-run": phase.optional ? "skipped" : "poured", "data-phase": phase.id, "data-key": "gate:" + phase.id,
            "aria-expanded": phase.id === selected.id ? "true" : "false", "aria-controls": "gate-panel"
          },
            el("span", { class: "num", text: number(i) }),
            el("span", { class: "name", text: words(phase.id) }),
            el("span", { class: "state", text: phase.optional ? "Optional" : "Required" })));
        })),
        phasePanel(flow, selected, flow.phases.indexOf(selected))),

      edges.length ? el("section", { "aria-labelledby": "back-title" },
        el("h2", { id: "back-title", text: "Ways back" }),
        el("p", { class: "meta", text: "The line is not only forward. These are the moves that leave the listed order." }),
        el("ul", { class: "explain" }, edges.map(function (edge) {
          return el("li", {}, el("span", { class: "term", text: words(edge.from) + " to " + words(edge.to) }), el("span", { class: "detail", text: edge.when }));
        }))) : null,

      el("section", { "aria-labelledby": "tracks-title" },
        el("h2", { id: "tracks-title", text: "Tracks" }),
        el("p", { class: "meta", text: "A track decides which phases a change must finish before implementation. New changes start on the " + flow.tracks.default + " track unless another is named." +
          forced.map(function (risk) { return " A " + risk + " risk change is always on the " + flow.tracks.forced_by_risk[risk] + " track."; }).join("") }),
        el("div", { class: "tracks" }, flow.tracks.list.map(function (track) {
          return el("div", { class: "track", "data-exploring": track.exploring },
            el("h3", { text: track.name + (track.name === flow.tracks.default ? " (default)" : "") }),
            el("p", { text: track.description || "No description recorded." }),
            track.exploring ? el("dl", { class: "facts" },
              el("dt", { text: "Starts with" }), el("dd", { text: "an exploring stage, journalled in " + track.output + "/, worked by the " + track.skill + " skill" }),
              el("dt", { text: "Before a person vets it" }), el("dd", { text: track.vet_requires.map(words).join(", ") + " complete and passing" }),
              el("dt", { text: "Not required first" }), el("dd", { text: track.optional.map(words).join(", ") || "nothing" })) : null);
        }))),

      flow.judgments.length ? el("section", { "aria-labelledby": "judgments-title" },
        el("h2", { id: "judgments-title", text: "Judgments" }),
        el("p", { class: "meta", text: "The verdicts the judge phase may record." }),
        el("ul", { class: "inline" }, flow.judgments.map(function (verdict) { return el("li", { text: verdict }); }))) : null
    ];
  }

  // --- messages ----------------------------------------------------------

  function problemView(title, text) {
    document.title = title + " · Soft Foundry";
    return [
      view.name === "repos" ? null : el("a", { class: "back", href: "#/", text: "Repositories" }),
      el("h1", { tabindex: "-1", text: title }),
      el("p", { class: "note", "data-tone": "flaw", text: text })
    ];
  }

  // --- routing, loading, and staying current ------------------------------

  function route() {
    var parts = location.hash.replace(/^#\/?/, "").split("/").filter(Boolean).map(function (part) {
      try { return decodeURIComponent(part); } catch (e) { return part; }
    });
    // #/r/<repository>/... is a page of one repository. The shorter forms
    // without a repository mean the one this page was started in.
    var repo = null;
    if (parts[0] === "r" && parts[1]) {
      repo = parts[1];
      parts = parts.slice(2);
      if (!parts.length) parts = ["changes"];
    }
    if (parts[0] === "change" && parts[1]) return { name: "change", repo: repo, slug: parts[1], phase: parts[2] || null };
    if (parts[0] === "workflow") return { name: "workflow", repo: repo, slug: null, phase: parts[1] || null };
    if (parts[0] === "changes") return { name: "board", repo: repo, slug: null, phase: null };
    if (parts[0] === "running") return { name: "running", repo: null, slug: null, phase: null };
    return { name: "repos", repo: null, slug: null, phase: null };
  }

  function endpoint() {
    var repo = view.repo ? "repo=" + encodeURIComponent(view.repo) : "";
    if (view.name === "repos") return "/api/repositories";
    if (view.name === "running") return "/api/processes";
    if (view.name === "workflow") return "/api/workflow" + (repo ? "?" + repo : "");
    if (view.name === "change") return "/api/change?slug=" + encodeURIComponent(view.slug) + (repo ? "&" + repo : "");
    return "/api/changes" + (repo ? "?" + repo : "");
  }

  function draw(nodes) {
    var active = document.activeElement && document.activeElement.getAttribute("data-key");
    var scroll = window.scrollY;
    main.replaceChildren();
    add(main, nodes);
    if (active) {
      var again = main.querySelector('[data-key="' + active.replace(/["\\]/g, "\\$&") + '"]');
      if (again) again.focus({ preventScroll: true });
    }
    window.scrollTo(0, scroll);
  }

  function render(data) {
    current = data;
    if (view.name === "workflow" && currentRepo()) workflows[currentRepo()] = data;
    if (view.name === "running") running = data;
    if (view.name === "repos") repos = data;
    draw(view.name === "change" ? changeView(data) : view.name === "workflow" ? workflowView(data) :
      view.name === "running" ? runningView(data) : view.name === "repos" ? reposView(data) : boardView(data));
    explain();
    Array.prototype.forEach.call(document.querySelectorAll("#nav a"), function (link) {
      if (link.getAttribute("data-view") === view.name) link.setAttribute("aria-current", "page");
      else link.removeAttribute("aria-current");
    });
  }

  function stamp() {
    var now = new Date();
    var two = function (n) { return n < 10 ? "0" + n : String(n); };
    return two(now.getHours()) + ":" + two(now.getMinutes()) + ":" + two(now.getSeconds());
  }

  // `fresh` is true when the view itself changed (a navigation), false
  // for a poll. A poll redraws only when the data differs, keeps focus
  // where it was, and says so once for screen readers.
  function load(fresh) {
    var asked = view;
    // Every view also learns what is running and which repositories there
    // are, so each can say where it is and what is going on there.
    var quiet = function (url) { return getJSON(url).catch(function () { return null; }); };
    var alsoRunning = view.name === "running" ? Promise.resolve(null) : quiet("/api/processes");
    var alsoRepos = view.name === "repos" ? Promise.resolve(null) : quiet("/api/repositories");
    Promise.all([getJSON(endpoint()), alsoRunning, alsoRepos]).then(function (results) {
      var result = results[0];
      if (asked !== view) return;
      if (results[1]) running = results[1].status === 200 ? results[1].body : null;
      if (results[2] && results[2].status === 200) repos = results[2].body;
      live.removeAttribute("data-lost");
      updated.textContent = (paused ? "Paused at " : "Updated ") + stamp();
      if (result.status !== 200) {
        shown = null;
        draw(result.status === 401 ?
          problemView("Open the link from your terminal", "This page shows nothing without the link soft-foundry ui printed when it started, which ends in #token= and a long code. Open that link in this tab. If the server was restarted, it printed a new one.") :
          result.status === 404 && view.name !== "change" ?
          problemView("No such repository", "The server does not know this repository. It knows the one it was started in, any added with --repo, and any with a session or command running.") :
          result.status === 404 ?
          problemView("No such change", "There is no change record named “" + view.slug + "” in " + repoName(currentRepo()) + ". It may have been renamed or removed.") :
          problemView("This could not be read", String(result.body && result.body.error || "The server answered " + result.status + ".")));
        if (fresh) focusHeading();
        return;
      }
      var body = result.body;
      var comparable = JSON.stringify([Object.assign({}, body, { generated_at: null }),
        view.name === "running" || !running ? null : Object.assign({}, running, { generated_at: null }),
        view.name === "repos" || !repos ? null : Object.assign({}, repos, { generated_at: null })]);
      if (!fresh && comparable === shown) return;
      var changed = shown !== null && !fresh;
      shown = comparable;
      render(body);
      if (fresh) focusHeading();
      if (changed) announce.textContent = (view.name === "change" ? "This change" : view.name === "workflow" ? "The workflow" :
        view.name === "running" ? "The list of what is running" : view.name === "repos" ? "The list of repositories" : "The board") + " was updated at " + stamp() + ".";
    }).catch(function (problem) {
      // A failed request and a fault in drawing both end here; the console
      // says which.
      if (window.console && console.error) console.error(problem);
      if (asked !== view) return;
      live.setAttribute("data-lost", "");
      updated.textContent = "Not connected";
      if (shown === null) {
        draw(problemView("Not connected", "The page cannot reach soft-foundry ui. If it was stopped, start it again and reload."));
      }
    });
  }

  function getJSON(url) {
    return fetch(url, { headers: { Accept: "application/json", "X-Soft-Foundry-Token": token || "" }, cache: "no-store" }).then(function (response) {
      return response.json().then(function (body) { return { status: response.status, body: body }; });
    });
  }

  // A change's checks are explained from its repository's workflow, which
  // is fetched once per repository; the change is redrawn when it arrives.
  function explain() {
    var id = currentRepo();
    if (view.name !== "change" || !id || workflows[id]) return;
    workflows[id] = {};
    var asked = view;
    getJSON("/api/workflow?repo=" + encodeURIComponent(id)).then(function (result) {
      if (result.status !== 200) return;
      workflows[id] = result.body;
      if (asked === view && shown !== null) draw(changeView(current));
    }).catch(function () { delete workflows[id]; });
  }

  function focusHeading() {
    var heading = main.querySelector("h1");
    if (heading) heading.focus({ preventScroll: true });
    window.scrollTo(0, 0);
  }

  function navigate() {
    takeToken(); // the link may be opened in a tab that already has the page
    var next = route();
    var sameChange = next.name === view.name && next.repo === view.repo && next.slug === view.slug && (next.name === "change" || next.name === "workflow");
    view = next;
    if (sameChange && shown !== null) {
      // Only the selected gate changed: redraw from what is on screen.
      render(current);
      var button = main.querySelector('[data-key="gate:' + (view.phase || "").replace(/["\\]/g, "\\$&") + '"]');
      if (button) button.focus({ preventScroll: true });
      return;
    }
    shown = null;
    load(true);
  }

  main.addEventListener("click", function (event) {
    var button = event.target.closest ? event.target.closest("button.gate") : null;
    if (!button) return;
    var phase = button.getAttribute("data-phase");
    location.hash = view.name === "workflow" ? repoHref(currentRepo(), "workflow/" + encodeURIComponent(phase)) : changeHref(view.slug, phase);
  });

  document.querySelector(".skip").addEventListener("click", function (event) {
    event.preventDefault();
    main.focus();
  });

  pause.addEventListener("click", function () {
    paused = !paused;
    pause.setAttribute("aria-pressed", paused ? "true" : "false");
    updated.textContent = paused ? "Paused" : "Updating";
    if (paused) document.documentElement.setAttribute("data-paused", "");
    else document.documentElement.removeAttribute("data-paused");
    if (!paused) load(false);
  });

  window.addEventListener("hashchange", navigate);
  document.addEventListener("visibilitychange", function () {
    if (!document.hidden && !paused) load(false);
  });

  window.setInterval(function () {
    if (!paused && !document.hidden) load(false);
  }, POLL_MS);

  navigate();
})();
