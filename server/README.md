# Vibe Trip Agent Server (Cloud Run friendly)

## Endpoints
- `GET /health` -> `{ ok: true }`
- `POST /v1/plan/stream` -> **SSE** stream:
  - `event: delta` `data: {"text":"..."}`
  - `event: done`  `data: {"finalText":"..."}`
  - `event: error` `data: {"message":"..."}`
- `POST /v1/plan` -> non-stream JSON `{ plan: <object>, rawText: <string> }`

## Run locally
```bash
npm install
# set OPENAI_API_KEY in env, or create .env and use a dotenv runner of your choice
export OPENAI_API_KEY="sk-..."
export MODEL="gpt-4.1"
npm start
```

## Cloud Run deploy (source deploy)
```bash
gcloud run deploy vibe-trip-agent \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars MODEL=gpt-4.1 \
  --set-secrets OPENAI_API_KEY=OPENAI_API_KEY:latest
```

## Test (PowerShell)
```powershell
Invoke-RestMethod "https://YOUR_URL/health"

$body = @{
  vibe = "sunny, quiet, under 2000"
  budgetUsd = 2000
  fromAirportCode = "WAW"
  startDate = "2026-04-01"
  endDate = "2026-04-04"
} | ConvertTo-Json -Compress
Set-Content -Path .\body.json -Value $body -Encoding utf8
curl.exe -N -X POST "https://YOUR_URL/v1/plan/stream" -H "Content-Type: application/json" --data-binary "@body.json"
```
