import type { APIRoute } from "astro";

export const GET: APIRoute = async () => {
  const markdownContent = `# Just Carlson

Writing about things I find interesting.

## Navigation

- [About](/about.md)
- [Recent Posts](/posts.md)
- [RSS Feed](/rss.xml)

## Links

- GitHub: [justcarlson](https://github.com/justcarlson)
- LinkedIn: [justincarlson0](https://www.linkedin.com/in/justincarlson0/)

---

*This is the markdown version of justcarlson.com. Visit [justcarlson.com](https://justcarlson.com) for the full experience.*`;

  return new Response(markdownContent, {
    status: 200,
    headers: {
      "Content-Type": "text/markdown; charset=utf-8",
      "Cache-Control": "public, max-age=3600",
    },
  });
};
