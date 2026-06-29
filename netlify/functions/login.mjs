export default async (request) => {
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  let body;
  try { body = await request.json(); } catch {
    const form = await request.formData();
    body = Object.fromEntries(form);
  }

  const password = process.env.SITE_PASSWORD;
  if (!password) {
    return new Response(JSON.stringify({ error: "No configurado" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }

  if (body.password !== password) {
    return new Response(JSON.stringify({ error: "Contrasenia incorrecta" }), { status: 401, headers: { "Content-Type": "application/json" } });
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
      "Set-Cookie": `sb-auth=${password}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=2592000`,
    },
  });
};
