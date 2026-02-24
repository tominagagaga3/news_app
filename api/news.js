export default async function handler(req, res) {
  const apiKey = process.env.NEWS_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: "NEWS_API_KEY is not set" });
  }

  const category = req.query.category ?? "technology";
  const language = req.query.language ?? "en"; 
  const pageSize = req.query.pageSize ?? "20";
  const page = req.query.page ?? "1";

  const url = new URL("https://newsapi.org/v2/top-headlines");
  url.searchParams.set("category", String(category));
  url.searchParams.set("language", String(language));
  url.searchParams.set("pageSize", String(pageSize));
  url.searchParams.set("page", String(page));

  const r = await fetch(url.toString(), {
    headers: { "X-Api-Key": apiKey },
  });

  const data = await r.json();
  return res.status(r.status).json(data);
}