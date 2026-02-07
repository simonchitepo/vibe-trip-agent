import express from "express";
import cors from "cors";
import OpenAI from "openai";

const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));

const PORT = parseInt(process.env.PORT || "8080", 10);
const MODEL = process.env.MODEL || "gpt-4.1";

/**
 * Keep startup resilient: don't crash if key is missing; return an error per-request instead.
 * Also trim to avoid illegal header values caused by whitespace/newlines.
 */
function getClient() {
  const key = (process.env.OPENAI_API_KEY || "").trim();
  if (!key) return null;
  return new OpenAI({ apiKey: key });
}

app.get("/health", (_, res) => res.json({ ok: true }));

function buildPrompt({ vibe, budgetUsd, fromAirportCode, startDate, endDate }) {
  const system = `
You are a travel-planning AI agent.
Return STRICT JSON ONLY (no markdown, no commentary) that matches exactly:

{
 "destinationCity": string,
 "summary": string,
 "budgetUsd": number,
 "dates": { "start":"YYYY-MM-DD", "end":"YYYY-MM-DD" },
 "flights":[
   {"airline":string,"from":string,"to":string,"departLocal":"YYYY-MM-DDTHH:mm","arriveLocal":"YYYY-MM-DDTHH:mm","stops":number,"priceUsd":number,"carbonKg":number},
   {"airline":string,"from":string,"to":string,"departLocal":"YYYY-MM-DDTHH:mm","arriveLocal":"YYYY-MM-DDTHH:mm","stops":number,"priceUsd":number,"carbonKg":number}
 ],
 "hotel":{"name":string,"area":string,"rating":number,"pricePerNightUsd":number,"perks":[string]},
 "transit":{"airportToHotel":string,"dayPass":string,"totalCostUsd":number,"notes":[string]},
 "dinners":[
   {"restaurant":string,"cuisine":string,"neighborhood":string,"dayLabel":string,"time":string,"partySize":number,"estimatedCostUsd":number}
 ]
}

Rules:
- Keep total estimated cost within budget if possible.
- Use fromAirportCode for departure airport.
- Be realistic and internally consistent.
`.trim();

  const user = `
VIBE: ${vibe}
BUDGET_USD: ${budgetUsd}
FROM_AIRPORT: ${fromAirportCode}
DATES: ${startDate} to ${endDate}
`.trim();

  return { system, user };
}

function validateBody(body) {
  const { vibe, budgetUsd, fromAirportCode, startDate, endDate } = body ?? {};
  if (!vibe || !budgetUsd || !fromAirportCode || !startDate || !endDate) {
    return {
      ok: false,
      message:
        "Missing required fields: vibe, budgetUsd, fromAirportCode, startDate, endDate",
    };
  }
  return { ok: true, vibe, budgetUsd, fromAirportCode, startDate, endDate };
}

function writeSse(res, event, dataObj) {
  res.write(`event: ${event}\n`);
  res.write(`data: ${JSON.stringify(dataObj)}\n\n`);
}

/**
 * ✅ Booking Deep-Link Endpoint (V1)
 * Your Flutter app calls this and opens the returned URL in the external browser/app.
 *
 * POST /v1/book/link
 * body:
 * {
 *   "type": "flight" | "hotel" | "restaurant",
 *   "payload": { ... }
 * }
 */
app.post("/v1/book/link", (req, res) => {
  try {
    const { type, payload } = req.body ?? {};
    if (!type || !payload) {
      return res.status(400).json({ error: "Missing type or payload" });
    }

    const enc = encodeURIComponent;

    if (type === "hotel") {
      const { city, checkIn, checkOut, adults = 2, rooms = 1 } = payload;
      if (!city || !checkIn || !checkOut) {
        return res.status(400).json({ error: "Missing city/checkIn/checkOut" });
      }

      // Booking.com search deep link (works without partner keys)
      const url =
        `https://www.booking.com/searchresults.html?ss=${enc(city)}` +
        `&checkin=${enc(checkIn)}&checkout=${enc(checkOut)}` +
        `&group_adults=${enc(String(adults))}&no_rooms=${enc(String(rooms))}` +
        `&group_children=0`;

      return res.json({ url });
    }

    if (type === "flight") {
      const { from, to, departDate, returnDate } = payload;
      if (!from || !to || !departDate) {
        return res
          .status(400)
          .json({ error: "Missing from/to/departDate" });
      }

      // Google Flights deep link (works without keys)
      const base = "https://www.google.com/travel/flights";
      const url = returnDate
        ? `${base}?q=Flights%20from%20${enc(from)}%20to%20${enc(
            to
          )}%20on%20${enc(departDate)}%20returning%20${enc(returnDate)}`
        : `${base}?q=Flights%20from%20${enc(from)}%20to%20${enc(
            to
          )}%20on%20${enc(departDate)}`;

      return res.json({ url });
    }

    if (type === "restaurant") {
      const { city, restaurant, date, time, partySize = 2 } = payload;
      if (!city || !date || !time) {
        return res.status(400).json({ error: "Missing city/date/time" });
      }

      // OpenTable search deep link (works without keys)
      const term = restaurant ? `${restaurant} ${city}` : city;

      // OpenTable expects dateTime like 2026-04-01T19:30
      const dateTime = `${date}T${time}`;

      const url =
        `https://www.opentable.com/s?term=${enc(term)}` +
        `&dateTime=${enc(dateTime)}` +
        `&covers=${enc(String(partySize))}`;

      return res.json({ url });
    }

    return res.status(400).json({ error: "Unknown type" });
  } catch (e) {
    console.error("book/link error:", e);
    return res.status(500).json({ error: "Server error" });
  }
});

app.post("/v1/plan/stream", async (req, res) => {
  // SSE headers
  res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
  res.setHeader("Cache-Control", "no-cache, no-transform");
  res.setHeader("Connection", "keep-alive");
  res.flushHeaders?.();

  const client = getClient();
  if (!client) {
    writeSse(res, "error", {
      message: "Server misconfigured: OPENAI_API_KEY is missing.",
    });
    res.end();
    return;
  }

  const v = validateBody(req.body);
  if (!v.ok) {
    writeSse(res, "error", { message: v.message });
    res.end();
    return;
  }

  const { system, user } = buildPrompt(v);

  try {
    // OpenAI Responses streaming via official SDK.
    const stream = await client.responses.create({
      model: MODEL,
      stream: true,
      input: [
        { role: "system", content: system },
        { role: "user", content: user },
      ],
    });

    let finalText = "";

    for await (const event of stream) {
      if (event?.type === "response.output_text.delta") {
        const delta = event.delta ?? "";
        if (delta) {
          finalText += delta;
          writeSse(res, "delta", { text: delta });
        }
      } else if (event?.type === "response.completed") {
        writeSse(res, "done", { finalText });
        res.end();
        return;
      } else if (event?.type === "response.failed") {
        writeSse(res, "error", { message: "OpenAI response failed." });
        res.end();
        return;
      } else if (event?.type === "error") {
        writeSse(res, "error", {
          message: event?.error?.message ?? "OpenAI stream error.",
        });
        res.end();
        return;
      }
    }

    // If stream ends without completed event, still send done.
    writeSse(res, "done", { finalText });
    res.end();
  } catch (err) {
    console.error("Server error:", err);
    writeSse(res, "error", { message: String(err?.message ?? err) });
    res.end();
  }
});

// Non-stream endpoint (useful for debugging)
app.post("/v1/plan", async (req, res) => {
  const client = getClient();
  if (!client) return res.status(500).json({ error: "OPENAI_API_KEY missing on server." });

  const v = validateBody(req.body);
  if (!v.ok) return res.status(400).json({ error: v.message });

  const { system, user } = buildPrompt(v);

  try {
    const response = await client.responses.create({
      model: MODEL,
      input: [
        { role: "system", content: system },
        { role: "user", content: user },
      ],
    });

    const rawText = response.output_text ?? "";
    let plan = null;

    try {
      const start = rawText.indexOf("{");
      const end = rawText.lastIndexOf("}");
      if (start !== -1 && end !== -1 && end > start) {
        plan = JSON.parse(rawText.slice(start, end + 1));
      }
    } catch {
      // ignore parse error
    }

    res.json({ plan, rawText });
  } catch (err) {
    console.error("OpenAI error:", err);
    res.status(500).json({ error: String(err?.message ?? err) });
  }
});

app.listen(PORT, () => {
  console.log(`Server listening on :${PORT}`);
});
