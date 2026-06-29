export default async (request, context) => {
  const url = new URL(request.url);
  const path = url.pathname;

  if (path.startsWith("/static/") || path.startsWith("/api/") || path.startsWith("/admin") || path === "/login/" || path === "/login" || path === "/404.html" || path === "/robots.txt" || path === "/feed.xml" || path === "/_headers") {
    return;
  }

  const password = Deno.env.get("SITE_PASSWORD");
  if (!password) return;

  const cookie = context.cookies.get("sb-auth");
  if (cookie === password) return;

  return new Response(null, {
    status: 302,
    headers: { Location: "/login/" },
  });
};
