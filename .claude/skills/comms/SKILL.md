---
name: comms
description: >
  How to write prose for this user — chat replies, explanations, summaries, and any
  markdown you produce — favoring short, simple sentence constructions so a
  non-native English speaker can follow technical writing without extra effort.
  Distilled from ASD-STE100 (Simplified Technical English) and paired with the
  `config/vale/styles/STE` Vale style, which lints markdown deliverables against
  the same rules. Governs sentence shape and word choice, not response length —
  Claude Code's own terseness conventions stay as they are. Load this early in a
  session (first substantive reply, or whenever picking up a new session with this
  user) and keep applying it for the rest of the conversation. Also trigger when
  explaining something technical at any length, or when the user asks you to
  simplify, clarify, or write more plainly.
---

# comms

Write for a strong engineer who reads English as a second language. The content
can be as technical as the work requires — the sentences carrying it should not
add a second problem to solve.

This does not mean write more. Stay exactly as direct and short as you already
are — no preamble, no filler, no padding for the sake of "explaining more."
It means: when you do write a sentence, build it so it takes one pass to parse.

## Sentence and paragraph shape

- Keep sentences short — aim under ~25 words. Split a sentence with two ideas
  into two sentences rather than stacking clauses with commas and "which."
- One idea per sentence. If you catch yourself writing "and" to join two
  separate claims, that's two sentences.
- Keep paragraphs short. Start each one with the sentence that states its
  topic; let the rest support it.
- Reach for a list once you have three or more related items, instead of
  packing them into one sentence.

## Say who does what

Prefer active voice: name the actor before the action.

- "The daemon clears the cache on restart," not "The cache is cleared by the
  daemon on restart."
- "You can adjust the timeout," not "The timeout can be adjusted."

This matters more than it sounds — passive voice hides the actor, and a reader
translating in their head has to reconstruct who's doing what.

## Word choice

Prefer the plain, common word over the formal one when both say the same thing:

| Instead of | Write |
|---|---|
| utilize | use |
| approximately | about |
| sufficient | enough |
| additional | more |
| purchase | buy |
| prior to | before |
| subsequent to | after |
| in order to | to |
| due to the fact that | because |
| a number of | some |
| the majority of | most |

Spell out Latin abbreviations: "for example" not "e.g.", "that is" not "i.e.",
"and so on" not "etc." — they read as noise to a reader who didn't memorize them.

Use American spelling (color, behavior, organize) unless the user's own text or
codebase uses a different convention — then match what's already there.

## Grammatical completeness

Don't drop small words to sound terse — they carry structure a non-native
reader relies on.

- Keep articles: "Remove the bolt and the stop," not "Remove bolt and stop."
- Keep "that" after verbs like "make sure," "recommend," "show," "confirm":
  "Make sure that the build passes" marks where the clause starts more clearly
  than "Make sure the build passes."
- Avoid contractions in explanations and instructions ("do not" rather than
  "don't", "it is" rather than "it's") — they take an extra beat to unpack.
  A short conversational acknowledgment doesn't need this rigor.

## Consistency

Once you pick a name for something in this conversation — a variable, a
concept, a file, a step — keep using that exact name. Don't rename it partway
through for variety; that reads as introducing something new. Spell out an
acronym or an unfamiliar term the first time you use it, then use the short
form for the rest of the conversation.

## Paired artifact

`config/vale/styles/STE` lints markdown files against the same source rules
(ASD-STE100). That style checks documents you write to disk; this skill covers
everything else you write, including the documents themselves before Vale ever
sees them.
