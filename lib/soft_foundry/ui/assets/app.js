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

  var main = document.getElementById("main");
  var updated = document.getElementById("updated");
  var announce = document.getElementById("announce");
  var pause = document.getElementById("pause");
  var live = updated.parentNode;

  var view = { name: null, slug: null, phase: null };
  var shown = null; // the data on screen, without its timestamp
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

  function changeHref(slug, phase) {
    return "#/change/" + encodeURIComponent(slug) + (phase ? "/" + encodeURIComponent(phase) : "");
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

    document.title = "Changes · Soft Foundry";
    return [
      el("h1", { tabindex: "-1", text: "Changes" }),
      el("p", { class: "lede", text: board.changes.length ? lede : "" }),
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
      el("a", { class: "back", href: "#/", text: "All changes" }),
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

      el("section", { "aria-labelledby": "line-title" },
        el("h2", { id: "line-title", text: "Gates" }),
        el("ol", { class: "line" }, change.gates.map(function (gate, i) {
          var open = gate.phase === selected.phase;
          return el("li", {}, el("button", {
            type: "button", class: "gate", "data-run": run(gate), "data-phase": gate.phase, "data-key": "gate:" + gate.phase,
            "aria-expanded": open ? "true" : "false", "aria-controls": "gate-panel"
          },
            el("span", { class: "num", text: number(i) }),
            el("span", { class: "name", text: gate.phase.replace(/_/g, " ") }),
            el("span", { class: "state" }, mark(gateState(gate)), gateWord(gate))));
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
            el("span", { class: "what" }, check.name, check.detail ? el("span", { class: "detail", text: check.detail }) : null));
        }))
      ],
      gate.blocking.length ? [el("h4", { text: "Blocking" }), el("ul", { class: "plain" }, gate.blocking.map(function (item) {
        return el("li", { text: typeof item === "string" ? item : JSON.stringify(item) });
      }))] : null,
      gate.findings.length ? [el("h4", { text: "Findings for later phases" }), el("ul", { class: "plain" }, gate.findings.map(function (finding) {
        return el("li", {}, el("span", { class: "area", text: [finding.id, finding.severity].filter(Boolean).join(" · ") }), finding.summary);
      }))] : null);
  }

  // --- messages ----------------------------------------------------------

  function problemView(title, text) {
    document.title = title + " · Soft Foundry";
    return [
      view.name === "board" ? null : el("a", { class: "back", href: "#/", text: "All changes" }),
      el("h1", { tabindex: "-1", text: title }),
      el("p", { class: "note", "data-tone": "flaw", text: text })
    ];
  }

  // --- routing, loading, and staying current ------------------------------

  function route() {
    var parts = location.hash.replace(/^#\/?/, "").split("/").filter(Boolean).map(function (part) {
      try { return decodeURIComponent(part); } catch (e) { return part; }
    });
    if (parts[0] === "change" && parts[1]) return { name: "change", slug: parts[1], phase: parts[2] || null };
    return { name: "board", slug: null, phase: null };
  }

  function endpoint() {
    return view.name === "change" ? "/api/change?slug=" + encodeURIComponent(view.slug) : "/api/changes";
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
    draw(view.name === "change" ? changeView(data) : boardView(data));
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
    fetch(endpoint(), { headers: { Accept: "application/json" }, cache: "no-store" }).then(function (response) {
      return response.json().then(function (body) { return { status: response.status, body: body }; });
    }).then(function (result) {
      if (asked !== view) return;
      live.removeAttribute("data-lost");
      updated.textContent = (paused ? "Paused at " : "Updated ") + stamp();
      if (result.status !== 200) {
        shown = null;
        draw(result.status === 404 ?
          problemView("No such change", "There is no change record named “" + view.slug + "”. It may have been renamed or removed.") :
          problemView("This could not be read", String(result.body && result.body.error || "The server answered " + result.status + ".")));
        if (fresh) focusHeading();
        return;
      }
      var body = result.body;
      var comparable = JSON.stringify(Object.assign({}, body, { generated_at: null }));
      if (!fresh && comparable === shown) return;
      var changed = shown !== null && !fresh;
      shown = comparable;
      render(body);
      if (fresh) focusHeading();
      if (changed) announce.textContent = (view.name === "change" ? "This change" : "The board") + " was updated at " + stamp() + ".";
    }).catch(function () {
      if (asked !== view) return;
      live.setAttribute("data-lost", "");
      updated.textContent = "Not connected";
      if (shown === null) {
        draw(problemView("Not connected", "The page cannot reach soft-foundry ui. If it was stopped, start it again and reload."));
      }
    });
  }

  function focusHeading() {
    var heading = main.querySelector("h1");
    if (heading) heading.focus({ preventScroll: true });
    window.scrollTo(0, 0);
  }

  function navigate() {
    var next = route();
    var sameChange = next.name === "change" && view.name === "change" && next.slug === view.slug;
    view = next;
    if (sameChange && shown !== null) {
      // Only the selected gate changed: redraw from what is on screen.
      render(Object.assign(JSON.parse(shown), {}));
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
    location.hash = changeHref(view.slug, button.getAttribute("data-phase"));
  });

  document.querySelector(".skip").addEventListener("click", function (event) {
    event.preventDefault();
    main.focus();
  });

  pause.addEventListener("click", function () {
    paused = !paused;
    pause.setAttribute("aria-pressed", paused ? "true" : "false");
    updated.textContent = paused ? "Paused" : "Updating";
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
