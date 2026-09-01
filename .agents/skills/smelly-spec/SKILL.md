---
name: smelly-spec
description: Read a natural-language change spec (OpenSpec change, RFC, requirements doc, DbC-style contract in prose) as if it were a contract, and surface where it will fail to constrain an implementer — human or model. Use whenever the user wants a spec reviewed, sanity-checked, or "smelled" before it goes to implementation, whenever they ask "is this spec clear / tight / enforceable", or before handing a spec to an agent to build from. Trigger even if the user just says "look at this change and tell me what's weak" — a spec critique is what they want.
disable-model-invocation: true
---

# smelly-spec

You are reading a spec the way a careful reviewer reads a contract. Do not ask "is this good writing". Ask instead where the text fails to bind an implementer held to *exactly* this text and nothing more. A spec smell is a place where the text *looks* like it constrains behavior but does not. An implementer, or a model compiling the spec into code, could satisfy every word and still build the wrong thing.

This is not a linter. You are a strong reader. Use judgment. The lens below tells you *what kind of regret* to hunt for and — critically — *how much confidence you are entitled to* about each one. That second part is the whole discipline.

## The one thing that governs everything: epistemic reach

A spec smell is only real if you can *see* it. Some smells live entirely inside the document — you can hold the whole thing in mind and know for certain the flaw is there. Others require ground truth that is not in front of you. You would need the reachable state of the system, the meaning of a domain word in *this* bounded context, or the invariant another change guarantees.

For those, you are guessing. A confident guess about something outside the text is the worst failure you can commit. It teaches the user to distrust the whole review.

Sort every finding you are tempted to raise into one of three reaches, and let the reach set your voice:

- **In-document** — the flaw is fully visible in the text. Two clauses contradict, a postcondition uses a word nothing could verify, or a rule has no example. State these plainly. You are right.
- **Needs-context** — the flaw *might* be there, but confirming it requires something you cannot see. Say what you'd need to check and why, as a question, not a verdict. "This assumes the ledger is already settled at entry — is that guaranteed by an earlier change, or is it an unstated precondition?"
- **Out-of-reach** — confirming it would need runtime behavior, the full codebase, or domain knowledge you do not hold. Name that it is out of reach and stop. Do not manufacture a finding to fill the gap.

If you find yourself reframing an out-of-reach worry to sound in-document, that reframing is the signal to demote it, not to raise it.

## What to hunt for

These come from two traditions worth naming, because they see different failures. **Design by Contract** sees a spec as precondition / postcondition / invariant and asks whether each actually binds. **XP communication** sees a spec as an *agreement between people* and asks whether shared understanding actually formed. A spec can be structurally perfect (DbC-clean) and still smell because two readers will picture two systems (XP-rotten). Watch for both.

You do not walk this as a list. You read the spec, and these are the shapes that should make you stop.

### The postcondition that promises nothing
The spec says what happens on success in words nothing could hold it to: "handles errors gracefully," "performs well," "appropriately," "as needed." Test: could you write a *failing* test from this clause alone? If not, the implementer is free — the spec did not constrain, it gestured. (This is usually the highest-yield smell and it is fully in-document.) The fix is a checkable postcondition, ideally with the concrete example that proves it.

### The precondition that cannot be met — or was never stated
The spec assumes the system is in a state it never establishes. The spec can assert an entry condition that nothing reachable satisfies. That is the too-strong case. The more common and more dangerous case leaves unsaid a condition the implementer *must* rely on. The implementer then assumes the happy path. **This is almost always needs-context or out-of-reach**: you cannot know from the text alone what state is reachable. Raise it as a question about where that guarantee comes from, never as "this precondition is wrong."

### The invariant nobody owns
The spec asserts a cross-cutting property, such as "every money movement is audited" or "no PII leaves the boundary". No single change is responsible for preserving it. It reads like a guarantee but it is an orphan. The next change can silently break it. Worth surfacing even when out-of-reach, but framed as "who holds this invariant?" — because the *absence* of an owner is the smell, and that absence is something the user can confirm.

### The spec that describes the how instead of the what
The text specifies mechanism — "iterate the accounts, call settle() on each" — where it should specify outcome. This over-constrains the implementer, couples the spec to one implementation, and (in the DbC frame) duplicates the code instead of contracting it. In-document and easy to see. The fix is to state the observable outcome and let the implementer choose the mechanism.

### The word that means two things (the ubiquitous-language smell)
The spec uses a domain term as if its meaning were obvious, such as "settlement," "active user," or "closed". The term carries a precise meaning in this bounded context that the text never pins. The reader, human or model, will fill it with a generic prior.

**This is the classic needs-context smell**: you genuinely cannot tell from the text whether the term is well-understood between the real authors or quietly ambiguous. The tell is a load-bearing noun doing a lot of work with no definition nearby. Ask. Do not assert.

### The rule with no example
A general rule stated with no worked instance. This is the XP "no concrete example" smell, and it is subtler than it looks. The absence of an example is often *why* the other smells hide. You cannot feel that a postcondition is vague until you try to write the one case that would satisfy it. When you hit an example-less rule, try to construct the example yourself. If you cannot produce one confidently, that failure *is* the finding.

### The change doing several things
One spec asserting multiple unrelated behaviors, so it cannot be reasoned about, tested, or reverted as a unit. In-document and countable. The fix is to split.

## How to report

Lead with the in-document findings. Those are the ones you are certain of. Leading with certainty earns the trust that the softer findings need. Then the needs-context questions, clearly marked as questions.

Then, only if genuinely useful, note what is out-of-reach. The user then knows what you *could not* assess. This is not a weakness to hide. Telling someone what you could not verify is more honest than a review that pretends to total sight.

For each real finding: name the shape, quote the smallest span that shows it, say why it fails to bind, and offer the tightening. Keep the fix concrete — a rewritten postcondition, the missing precondition stated, the term that needs a definition.

Do not pad. A spec with three real smells gets three findings, not ten with seven invented to look thorough. The credibility of the review is inversely proportional to how much you reached to fill it. If the spec is tight, say it is tight. Name the one thing you would still want pinned. That is a more useful output than a manufactured list.

## Why the reach discipline is the whole point

Anyone can generate spec critique. A strong model generates too much of it. The value you add is not the finding. It is the *calibration on the finding*. Know that "this postcondition is unverifiable" is a fact, and that "this precondition is wrong" is a guess. Speak each in its true register.

A review that mixes certain and speculative findings in one confident voice is worse than no review. The user cannot tell which finding to act on. Get the register right and even your questions are useful. Get it wrong and even your correct findings get discounted.
