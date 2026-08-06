#!/usr/bin/env python3
"""exhibit — render probe or trace output as a Mermaid exhibit.

Standard library only. Reads CSV from stdin (or --file), writes markdown to stdout.

  probe.sql | trino-q ... | exhibit.py breaks --class-col class --count-col n \
      --probe INV-014 --grain "one issued invoice" --watermark 4h
"""
import argparse
import csv
import sys
from datetime import datetime, timezone

VERBS = ("funnel", "breaks", "lateness", "trace", "drift")


def read_rows(path):
    if path in (None, "-"):
        return list(csv.DictReader(sys.stdin))
    with open(path, newline="") as fh:
        return list(csv.DictReader(fh))


def num(v):
    try:
        return float(str(v).replace(",", "").strip() or 0)
    except ValueError:
        return 0.0


def fmt(n):
    n = float(n)
    return f"{n:,.0f}" if abs(n - round(n)) < 1e-9 else f"{n:,.2f}"


def q(s):
    return '"' + str(s).replace('"', '""') + '"'


def pct(sorted_vals, p):
    if not sorted_vals:
        return 0.0
    k = max(0, min(len(sorted_vals) - 1, int(round(p * (len(sorted_vals) - 1)))))
    return sorted_vals[k]


def col(row, name):
    return (row.get(name) or "").strip()


def footer(args, rows):
    bits = [
        f"probe `{args.probe or '-'}`",
        f"grain: {args.grain or '-'}",
        f"population: {args.population or 'all'}",
        f"watermark: {args.watermark or '-'}",
        f"{len(rows)} rows",
        f"as of {args.as_of}",
    ]
    return ["", "> " + " · ".join(bits), ""]


def funnel(rows, a):
    stages = [(col(r, a.stage_col), num(col(r, a.count_col)),
               num(col(r, a.amount_col)) if a.amount_col else None) for r in rows]

    def label(name, count, amount):
        tail = f"{fmt(count)}" + (f" | {fmt(amount)}" if amount is not None else "")
        return f"{name} ({tail})"

    out = ["```mermaid", "sankey-beta", ""]
    for (s1, c1, m1), (s2, c2, m2) in zip(stages, stages[1:]):
        a1, a2 = label(s1, c1, m1), label(s2, c2, m2)
        out.append(f"{q(a1)},{q(a2)},{int(c2)}")
        lost = c1 - c2
        if lost > 0:
            out.append(f"{q(a1)},{q(f'lost before {s2} ({fmt(lost)})')},{int(lost)}")
    out.append("```")
    return out


def breaks(rows, a):
    pairs = [(col(r, a.class_col), num(col(r, a.count_col))) for r in rows]
    pairs.sort(key=lambda x: -x[1])
    if not pairs:
        return ["_no breaks_"]
    top = max(v for _, v in pairs)
    out = ["```mermaid", "xychart-beta",
           f'    title "{a.title or "Breaks by class"}"',
           "    x-axis [" + ", ".join(q(k) for k, _ in pairs) + "]",
           f'    y-axis "rows" 0 --> {int(top * 1.15) + 1}',
           "    bar [" + ", ".join(str(int(v)) for _, v in pairs) + "]",
           "```", ""]
    out += ["| class | rows | share |", "|---|---:|---:|"]
    total = sum(v for _, v in pairs) or 1
    for k, v in pairs:
        out.append(f"| {k} | {fmt(v)} | {100 * v / total:.1f}% |")
    return out


def lateness(rows, a):
    by_src = {}
    for r in rows:
        by_src.setdefault(col(r, a.source_col) or "all", []).append(num(col(r, a.lag_col)))
    stats = []
    for src, vals in by_src.items():
        vals.sort()
        stats.append((src, pct(vals, 0.50), pct(vals, 0.90), pct(vals, 0.99), vals[-1], len(vals)))
    stats.sort(key=lambda s: -s[3])

    out = ["| source | p50 | p90 | **p99** | max | n |", "|---|---:|---:|---:|---:|---:|"]
    for s, p50, p90, p99, mx, n in stats:
        out.append(f"| {s} | {fmt(p50)} | {fmt(p90)} | **{fmt(p99)}** | {fmt(mx)} | {n} |")
    out += ["", "```mermaid", "xychart-beta",
            f'    title "{a.title or "p99 ingestion lateness by source (minutes)"}"',
            "    x-axis [" + ", ".join(q(s[0]) for s in stats) + "]",
            f'    y-axis "minutes" 0 --> {int(max(s[3] for s in stats) * 1.15) + 1}',
            "    bar [" + ", ".join(str(int(s[3])) for s in stats) + "]",
            "```", "",
            f"Watermark for any probe touching these sources: **{fmt(max(s[3] for s in stats))} min**"]
    return out


def trace(rows, a):
    ordered = sorted(rows, key=lambda r: col(r, a.time_col))
    out = ["```mermaid", "gantt",
           f'    title {a.title or "Trace"}',
           "    dateFormat YYYY-MM-DDTHH:mm:ss",
           "    axisFormat %m-%d %H:%M"]
    last_src, i = None, 0
    for r in ordered:
        src = col(r, a.source_col) or "unknown"
        if src != last_src:
            out.append(f"    section {src}")
            last_src = src
        i += 1
        ts = col(r, a.time_col).replace(" ", "T").split(".")[0]
        out.append(f"    {col(r, a.event_col)} :milestone, m{i}, {ts}, 0d")
    out.append("```")
    return out


def drift(rows, a):
    pts = [(col(r, a.date_col), num(col(r, a.count_col))) for r in rows]
    pts.sort(key=lambda p: p[0])
    if not pts:
        return ["_no data_"]
    top = max(v for _, v in pts)
    out = ["```mermaid", "xychart-beta",
           f'    title "{a.title or "Break rate over time"}"',
           "    x-axis [" + ", ".join(q(d) for d, _ in pts) + "]",
           f'    y-axis "rows" 0 --> {int(max(top, a.threshold or 0) * 1.15) + 1}',
           "    line [" + ", ".join(str(int(v)) for _, v in pts) + "]"]
    if a.threshold:
        out.append("    line [" + ", ".join(str(int(a.threshold)) for _ in pts) + "]")
    out.append("```")
    if a.threshold:
        breached = [d for d, v in pts if v > a.threshold]
        out += ["", f"Threshold {fmt(a.threshold)} breached on: "
                    + (", ".join(breached) if breached else "never")]
    return out


RENDER = {"funnel": funnel, "breaks": breaks, "lateness": lateness,
          "trace": trace, "drift": drift}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("verb", choices=VERBS)
    p.add_argument("--file", default="-")
    p.add_argument("--title")
    p.add_argument("--probe")
    p.add_argument("--grain")
    p.add_argument("--population")
    p.add_argument("--watermark")
    p.add_argument("--as-of", default=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%MZ"))
    p.add_argument("--stage-col", default="stage")
    p.add_argument("--count-col", default="n")
    p.add_argument("--amount-col")
    p.add_argument("--class-col", default="class")
    p.add_argument("--lag-col", default="lag_min")
    p.add_argument("--source-col", default="src")
    p.add_argument("--time-col", default="t")
    p.add_argument("--event-col", default="event")
    p.add_argument("--date-col", default="date")
    p.add_argument("--threshold", type=float)
    a = p.parse_args()

    rows = read_rows(a.file)
    body = RENDER[a.verb](rows, a)
    print("\n".join(body + footer(a, rows)))


if __name__ == "__main__":
    main()
