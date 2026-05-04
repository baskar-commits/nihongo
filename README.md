## Japanese weekly quiz site (GitHub Pages)

This repo hosts weekly Japanese quizzes as simple HTML pages.

### Weekly workflow (what you do)

1. Create a quiz offline as a single `.html` file in any folder you use for quiz drafts.
2. Run this command from the repo folder:

```powershell
.\scripts\publish-quiz.ps1 -SourceHtml "C:\path\to\your-quiz.html" -QuizDate 2026-05-03
```

It will:
- copy the quiz into `quizzes/YYYY/MM/YYYY-MM-DD/index.html`
- run basic validation checks
- regenerate the homepage `index.html` (This week / Last week / Archive grouped by year/month)

### GitHub Pages setup (one time)

- Create a GitHub repo (e.g. `japanese-quiz-site`)
- Add it as your remote:

```powershell
git remote add origin <YOUR_GITHUB_REPO_URL>
git branch -M main
git push -u origin main
```

- In GitHub: **Settings → Pages**
  - Source: Deploy from a branch
  - Branch: `main`
  - Folder: `/ (root)`

