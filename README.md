## Japanese class site (GitHub Pages)

A small static site for a beginner Japanese class. Two sections:

- **Quizzes**: weekly self-check quizzes, one HTML page per week.
- **Conversation Practice** (`travel/`): a role-played trip to Japan for speaking practice.

Everything is plain HTML, CSS and JavaScript. No build step, no framework, no accounts.

### Where the content comes from

The material is built from two sources:

- a six-week **Easy Conversational Japanese** course at Bellevue College Continuing Education
- ***Japanese for Busy People I***, Romaji, Revised 4th Edition (AJALT / Kodansha)

Every line traces back to one of those two, or is marked as going beyond them. That is why the
scope is what it is: this is a rehearsal of one particular class rather than a general
phrasebook, and it stays deliberately inside what has actually been taught. Anyone working from
the same textbook should find it usable; anyone else is welcome to fork it and swap in their own
scenes.

---

## Conversation Practice

Open `travel/index.html` (linked from the homepage).

Each **scene** is a place on a trip to Japan. Inside a scene, **sub-scenes** are the separate
conversations you have there. On the plane you talk to a flight attendant, to the passenger
next to you, and you hear three announcements.

For every line you see the English first. Say it in Japanese out loud, alone or with a partner,
then tap:

1. first tap reveals the **kana**
2. second tap reveals the **romaji**, a grammar note, and where the line came from
3. third tap hides it so you can try again

Two small dots on each card show which stage you are at. Every line is numbered, so `1E-09`
means scene 1, conversation E, line 9.

### What the marks mean

- Words in **red** were **not** in the class handouts.
- Words with a **dotted underline** were taught, but are worth a reminder.
- Both give the romaji and connect to a word you already know.
- **Green buttons** open a short explanation of a grammar pattern right where you are.

### Two kinds of sub-scene

**Dialogue** stays inside what the class has taught, because you have to say it.

**Announcements** are different on purpose. They use the real keigo an airline or a station
actually uses, because you never have to produce one: the whole skill is recognising it as it
washes over you. Simplifying an announcement would train you to understand something you will
never hear. Their notes say so, and every new word is glossed.

All dialogue is in polite Japanese. Casual forms may be added later as a switch.

---

## Adding or editing a scene

Scenes are data, not code. To add one, drop a JSON file in `travel/scenes/` and add an entry to
`travel/scenes/manifest.json` with `"status": "ready"`. Nothing else changes.

```jsonc
{
  "id": "scene-01-plane",
  "order": 1,
  "title": { "en": "On the Plane", "kana": "ひこうきで" },
  "summary": "One line describing the scene.",
  "register": "formal",
  "characters": {
    "attendant": { "en": "Flight attendant", "kana": "きゃくしつじょういん" }
  },
  "subscenes": [
    {
      "id": "1A",
      "mode": "dialogue",          // "dialogue" or "announcement"
      "title": { "en": "Boarding", "kana": "とうじょう" },
      "partner": "attendant",       // key from "characters"
      "note": "A string renders as a paragraph; an array of strings renders as bullets.",
      "turns": [
        { "stage": "Optional scene direction. No Japanese, no reveal." },
        {
          "speaker": "you",         // "you" | "partner" | "announce"
          "en": "May I put my bag here?",
          "kana": "かばんをここにおいてもいいですか。",
          "romaji": "Kaban o koko ni oite mo ii desu ka.",
          "source": "L4 ～てもいいですか",
          "grammar": "Note about the pattern. May contain [[concept]] markers.",
          "speakerOverride": "staff",  // optional: a different character for this line
          "words": [                   // taught, but worth a reminder (dotted underline)
            { "word": "どうぞ", "romaji": "douzo", "gloss": "please, go ahead",
              "anchor": "it offers or permits; it never asks. That is ください." }
          ],
          "extras": [                  // not taught in class (red)
            { "word": "おいて", "romaji": "oite", "gloss": "put, place",
              "anchor": "the [[te-form]] of おきます. Verbs ending in く take いて." }
          ],
          "alternative": {             // optional: a plainer or more formal version
            "kana": "にほんにいったことがありますか。",
            "romaji": "Nihon ni itta koto ga arimasu ka.",
            "note": "the plainer version, from the basic question table"
          }
        }
      ]
    }
  ]
}
```

### Grammar concepts

`travel/concepts.json` defines each grammar pattern once. Write `[[te-mo-ii]]` inside any
`grammar`, `anchor` or note and it renders as a tappable chip that expands the explanation in
place.

```jsonc
"te-mo-ii": {
  "chip": "～てもいいですか",          // the button label
  "title": "Asking permission",
  "body": "How to build it, in plain English.",
  "examples": [
    { "kana": "とります → とって → とってもいいですか。",
      "romaji": "Totte mo ii desu ka.", "en": "May I take (a photo)?" }
  ],
  "source": "Lesson 4"
}
```

### Rules the existing scenes follow

- Kana only. No kanji anywhere.
- Every line traces to a class handout or the textbook. If it cannot, gloss the new word in
  `extras`.
- Every `words` and `extras` entry needs `romaji` and an `anchor` naming a word the learner
  already knows. If there is no relative yet, say so plainly.
- **Never reference another line by number inside a note**, and never write "again", "another"
  or "as before". Use a `[[concept]]` chip, or quote the Japanese. Line numbers rot when lines
  are inserted; concepts do not.
- A concept must be *buildable*, not just named. Give the transformation rule and show the full
  chain in the examples.
- Use `stage` lines for jumps in time or place rather than inventing dialogue to cover them.
- Ask three questions of every line: would this be said *here*, by *this person*, following the
  *previous line*?
- Put a blank (`______`) where a learner supplies their own name, job or hometown. Scenes are
  shared, so nothing is personalised.
- American English in the prompts. No em dashes. The `ー` inside katakana is a different
  character and stays.

The player loads scene files with `fetch`, so **opening `travel/index.html` straight off your
hard drive will not work**; browsers block it. Use the published site, or run a local server
from the repo folder:

```powershell
python -m http.server 8000
# then open http://localhost:8000/travel/
```

---

## Publishing a quiz

1. Create a quiz as a single `.html` file in any folder you use for drafts.
2. From the repo folder:

```powershell
.\scripts\publish-quiz.ps1 -SourceHtml "C:\path\to\your-quiz.html" -QuizDate 2026-05-03
```

It will copy the quiz into `quizzes/YYYY/MM/YYYY-MM-DD/index.html`, run basic validation checks,
and regenerate the homepage `index.html`.

The homepage is regenerated by that script, so the Conversation Practice card lives in the
script's template. Edit `scripts/publish-quiz.ps1` if you need to change it, not `index.html`
directly, or the next publish will overwrite your change.

## GitHub Pages setup (one time)

```powershell
git remote add origin <YOUR_GITHUB_REPO_URL>
git branch -M main
git push -u origin main
```

In GitHub: **Settings → Pages** → Source: Deploy from a branch → Branch `main`, folder `/ (root)`.
