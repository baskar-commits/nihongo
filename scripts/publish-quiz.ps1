param(
  [Parameter(Mandatory=$true)]
  [string]$SourceHtml,

  [Parameter(Mandatory=$true)]
  [ValidatePattern("^\d{4}-\d{2}-\d{2}$")]
  [string]$QuizDate,

  [string]$SiteTitle = "Japanese Class Quiz"
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Host ""
  Write-Host "ERROR: $Message" -ForegroundColor Red
  exit 1
}

function Get-RepoRoot {
  $root = Split-Path -Parent $PSScriptRoot
  return $root
}

function Read-FileUtf8($Path) {
  return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

function Get-TitleFromHtml($Html) {
  $m = [regex]::Match($Html, "<title>\s*(.*?)\s*</title>", "IgnoreCase,Singleline")
  if ($m.Success) { return $m.Groups[1].Value }
  return ""
}

function Validate-QuizHtml($Html) {
  if (-not ($Html -match "<!DOCTYPE\s+html")) { Fail "Missing <!DOCTYPE html>." }
  if (-not ($Html -match "<meta\s+charset\s*=\s*[""']?UTF-8")) { Fail "Missing UTF-8 charset meta tag." }
  if (-not ($Html -match "<meta\s+name\s*=\s*[""']viewport[""']")) { Fail "Missing viewport meta tag (mobile-friendly)." }
  if (-not ($Html -match "<script")) { Fail "No <script> tag found. If this is a quiz, did you paste the full file?" }
  if (-not ($Html -match "</html>")) { Fail "Missing closing </html> tag." }
}

function Validate-QuizSecurity($Html) {
  # Block risky patterns that are unnecessary for this static quiz site.
  $blockedRules = @(
    @{ Pattern = "<script[^>]+src\s*=\s*[""']https?://"; Message = "External remote <script> is not allowed." },
    @{ Pattern = "<link[^>]+href\s*=\s*[""']https?://"; Message = "External remote stylesheet is not allowed." },
    @{ Pattern = "<iframe\b"; Message = "<iframe> is not allowed in quiz files." },
    @{ Pattern = "<object\b|<embed\b"; Message = "<object>/<embed> is not allowed in quiz files." },
    @{ Pattern = "eval\s*\("; Message = "eval() is not allowed." },
    @{ Pattern = "new\s+Function\s*\("; Message = "new Function() is not allowed." },
    @{ Pattern = "document\.write\s*\("; Message = "document.write() is not allowed." },
    @{ Pattern = "fetch\s*\(|XMLHttpRequest|WebSocket"; Message = "Network calls are not allowed in quiz files." },
    @{ Pattern = "href\s*=\s*[""']\s*javascript:"; Message = "javascript: URLs are not allowed." }
  )

  foreach ($rule in $blockedRules) {
    if ([regex]::IsMatch($Html, $rule.Pattern, "IgnoreCase")) {
      Fail "Security check failed: $($rule.Message)"
    }
  }

  # Informational warning only: inline handlers are currently used by this quiz engine.
  if ([regex]::IsMatch($Html, "\son[a-z]+\s*=", "IgnoreCase")) {
    Write-Host "Security note: inline event handlers detected (allowed for current quiz format)." -ForegroundColor Yellow
  }
}

function Ensure-Dir($Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

function Format-MonthName($yyyyMM) {
  $dt = [datetime]::ParseExact("$yyyyMM-01", "yyyy-MM-dd", $null)
  return $dt.ToString("MMMM yyyy")
}

function Format-QuizLabel($Date) {
  # Derives "Monday, May 18, 2026" from a YYYY-MM-DD string — never relies on the HTML title
  $dt = [datetime]::ParseExact($Date, "yyyy-MM-dd", $null)
  return $dt.ToString("dddd, MMMM d, yyyy")
}

function Build-HomePage($RepoRoot, $SiteTitle) {
  $quizzesRoot = Join-Path $RepoRoot "quizzes"
  $indexPath = Join-Path $RepoRoot "index.html"

  $quizFiles = @()
  if (Test-Path -LiteralPath $quizzesRoot) {
    $quizFiles = Get-ChildItem -LiteralPath $quizzesRoot -Recurse -File -Filter "index.html" |
      Where-Object { $_.FullName -match "\\quizzes\\\d{4}\\\d{2}\\\d{4}-\d{2}-\d{2}\\index\.html$" }
  }

  $items = $quizFiles | ForEach-Object {
    $m = [regex]::Match($_.FullName, "\\quizzes\\(?<y>\d{4})\\(?<mo>\d{2})\\(?<d>\d{4}-\d{2}-\d{2})\\index\.html$")
    $rel = $_.FullName.Substring($RepoRoot.Length).TrimStart("\","/")
    # Keep index.html in the link so it works for both:
    # - GitHub Pages / local web server (directory index resolution)
    # - opening index.html directly as a file (no directory index resolution)
    $url = ($rel -replace "\\","/")
    $html = Read-FileUtf8 $_.FullName
    $title = Get-TitleFromHtml $html
    if ([string]::IsNullOrWhiteSpace($title)) { $title = "Japanese Quiz - $($m.Groups['d'].Value)" }

    [pscustomobject]@{
      Date = $m.Groups["d"].Value
      Year = $m.Groups["y"].Value
      Month = $m.Groups["mo"].Value
      Url = $url
      Title = $title
    }
  } | Sort-Object Date -Descending

  $latest = $items | Select-Object -First 1
  $archiveItems = @()
  if ($null -ne $latest) {
    $archiveItems = @($items | Where-Object { $_.Date -ne $latest.Date })
  } else {
    $archiveItems = @($items)
  }

  $archiveHtml = ""
  if ($archiveItems.Count -eq 0) {
    $archiveHtml = "<p class=""meta"">Older quizzes will appear here.</p>"
  } else {
    $groupYear = $archiveItems | Group-Object Year
    foreach ($yGroup in ($groupYear | Sort-Object Name -Descending)) {
      $archiveHtml += "<h3>$($yGroup.Name)</h3>`n"
      $byMonth = $yGroup.Group | Group-Object Month
      foreach ($mGroup in ($byMonth | Sort-Object Name -Descending)) {
        $monthLabel = Format-MonthName "$($yGroup.Name)-$($mGroup.Name)"
        $archiveHtml += "<div class=""month""><div class=""month-title"">$monthLabel</div><ul>`n"
        foreach ($q in ($mGroup.Group | Sort-Object Date -Descending)) {
          $dateLabel = Format-QuizLabel $q.Date
          $archiveHtml += "<li><a href=""$($q.Url)"">$dateLabel</a> <span class=""date"">$($q.Date)</span></li>`n"
        }
        $archiveHtml += "</ul></div>`n"
      }
    }
  }

  $latestHtml = "<p class=""meta"">No quizzes published yet.</p>"
  if ($null -ne $latest) {
    $dateLabel = Format-QuizLabel $latest.Date
    $latestHtml = "<a class=""primary"" href=""$($latest.Url)"">Start Quiz</a><div class=""meta"">$dateLabel<br>$($latest.Date)</div>"
  }

  $homeHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$SiteTitle</title>
  <style>
    :root{--bg:#f8f6f1;--card:#fff;--accent:#c0392b;--accent2:#2980b9;--text:#2c3e50;--muted:#7f8c8d;--border:#ddd}
    *{box-sizing:border-box}
    body{margin:0;font-family:system-ui,-apple-system,Segoe UI,sans-serif;background:var(--bg);color:var(--text);line-height:1.5;padding:18px}
    .container{max-width:860px;margin:0 auto}
    header{background:linear-gradient(135deg,var(--accent),#e74c3c);color:#fff;border-radius:14px;padding:18px 16px}
    header h1{margin:0 0 6px;font-size:1.4rem}
    header p{margin:0;opacity:.95}
    .card{background:var(--card);border:1px solid var(--border);border-radius:14px;padding:16px;margin-top:14px;box-shadow:0 2px 10px rgba(0,0,0,.05)}
    .primary{display:inline-block;background:var(--accent2);color:#fff;text-decoration:none;font-weight:800;padding:12px 18px;border-radius:10px}
    .primary:focus,.primary:hover{filter:brightness(.95)}
    .meta{color:var(--muted);font-size:.95rem;margin-top:8px}
    h2{margin:0 0 10px;font-size:1.1rem}
    h3{margin:14px 0 8px;font-size:1.05rem;color:var(--accent)}
    ul{margin:0;padding-left:18px}
    li{margin:8px 0}
    a{color:var(--accent2)}
    .month{padding:10px 12px;border:1px solid var(--border);border-radius:12px;margin:10px 0;background:#fff}
    .month-title{font-weight:800;margin-bottom:8px}
    .date{color:var(--muted);font-size:.9rem;margin-left:6px}
    .footer{margin-top:18px;color:var(--muted);font-size:.9rem}
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>$SiteTitle</h1>
      <p>Click ""Start Quiz"" to begin.</p>
    </header>

    <div class="card">
      <h2>Current</h2>
      $latestHtml
    </div>

    <div class="card">
      <h2>Previous Quizzes</h2>
      <div id="archive">
        $archiveHtml
      </div>
    </div>

    <div class="footer">
      <div>Use this page each week to start your quiz.</div>
    </div>
  </div>
</body>
</html>
"@

  Set-Content -LiteralPath $indexPath -Value $homeHtml -Encoding UTF8
}

$repoRoot = Get-RepoRoot
$src = $SourceHtml
if (-not (Test-Path -LiteralPath $src)) { Fail "SourceHtml not found: $src" }

$html = Read-FileUtf8 $src
Validate-QuizHtml $html
Validate-QuizSecurity $html

$year = $QuizDate.Substring(0,4)
$month = $QuizDate.Substring(5,2)
$destDir = Join-Path $repoRoot ("quizzes\{0}\{1}\{2}" -f $year, $month, $QuizDate)
Ensure-Dir $destDir
$dest = Join-Path $destDir "index.html"

Copy-Item -LiteralPath $src -Destination $dest -Force

Build-HomePage $repoRoot $SiteTitle

Write-Host ""
Write-Host "Published quiz:" -ForegroundColor Green
Write-Host "  $dest"
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "  git status"
Write-Host "  git add ."
Write-Host "  git commit -m ""Publish quiz $QuizDate"""
Write-Host "  git push"

