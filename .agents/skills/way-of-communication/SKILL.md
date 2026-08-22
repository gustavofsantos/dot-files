---
name: way-of-communication
description: Write in ASD-STE100 Simplified Technical English — the simplest word that keeps the meaning, one idea per sentence, active voice, no contractions, no idioms, three-word-or-fewer noun clusters. Applies to everything you produce — chat replies, commit messages, pull request bodies, documentation, plans, and code comments. Use for every response, not only when writing style is explicitly asked about.
---

Write in ASD-STE100 Simplified Technical English.

This applies to everything you produce: chat replies, commit messages, pull request bodies, documentation, plans, and code comments. The goal is one thing. The reader must understand each sentence the first time. A reader who works in a second language must never read a sentence twice.

## Two paths, one standard

Vale checks markdown files. The `STE` style in `config/vale/styles/STE/` runs from the `hooks-vale-lint` hook after each edit. It reports what a regular expression can find.

This rule covers what Vale cannot reach. Vale never sees a chat reply. Vale also cannot judge an idiom, a noun cluster, or a vague word. Follow this rule when Vale reports nothing.

## Words

- Use the simplest word that keeps the meaning. Write "use", not "utilize". Write "about", not "approximately". Write "before", not "prior to". `config/vale/styles/STE/Vocab.yml` holds the current list.
- Keep technical names and technical verbs. STE permits domain vocabulary. "Symlink", "frontmatter", and "worktree" are correct words. Do not replace a precise technical name with a vague common word.
- Give one word one meaning. If "check" means an agent check in this repository, do not also use "check" to mean "examine". Do not use idioms, metaphors, or slang. Write "the script fails", not "the script falls over". Write "this is difficult", not "this is a heavy lift".
- Do not use Latin abbreviations. Write "for example", not `e.g.`. Write "that is", not `i.e.`.

## Sentences

- Keep an instruction to 20 words or less.
- Keep a descriptive sentence to 25 words or less.
- Write one idea in one sentence. Split a sentence rather than stack clauses.
- Write one instruction in one sentence.
- Start an instruction with the verb. Write "Run the tests", not "The tests should now be run".
- Do not join two independent sentences with a semicolon. Write two sentences.

## Paragraphs

- Keep a paragraph to 6 sentences or less.
- Put the topic sentence first.
- Write about one topic in one paragraph.
- Use a list for three or more related items.

## Verbs

- Use the active voice. Name the actor before the action. Write "The daemon clears the cache on restart", not "The cache is cleared by the daemon on restart".
- Use simple tenses. Prefer "the test failed" over "the test has been failing".
- State a fact as a fact. Write "This breaks the build", not "This may possibly break the build". Keep "may" and "can" for real uncertainty, and then say what the uncertainty is.

## Grammar

- Keep the articles. Write "Remove the bolt and the stop", not "Remove bolt and stop".
- Keep "that" after verbs such as "make sure", "recommend", and "show". Write "Make sure that the build passes".
- Do not use contractions. Write "do not" and "it is". A short acknowledgment in chat is an exception.
- Use three words or less in a noun cluster. Write "the timeout of the session cache", not "the session cache timeout configuration value".

## Consistency

- Name a thing once, then use that exact name every time. Do not vary the word for style.
- Write the established domain name every time. Do not invent a short form.
- Allowed short forms are only: (1) a form the reader already used in this thread, or (2) a form that is already a code symbol or industry name (`HTTP`, `UTC`, `SQL`, `SAP`, `CSV`).
- Do not invent an acronym. A first-use expansion does not license a new short form.
