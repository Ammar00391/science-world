// Supabase Edge Function: AI Chat
// This function proxies requests to an external AI provider (e.g., OpenAI, Gemini)
// with strict limits, authentication, and safety checks.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const AI_PROVIDER = Deno.env.get("AI_PROVIDER") || "openai";
const MAX_TOKENS = parseInt(Deno.env.get("MAX_TOKENS") || "500");
const RATE_LIMIT_WINDOW_MS = 60_000; // 1 minute
const MAX_REQUESTS_PER_WINDOW = 10;

const requestLog = new Map();

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Auth check
  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return new Response("Unauthorized", { status: 401 });
  }
  const token = authHeader.split(" ")[1];

  // Verify user via Supabase
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseKey = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") || Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !supabaseKey) {
    return new Response("Supabase function secrets are not configured", { status: 503 });
  }

  const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      "Authorization": `Bearer ${token}`,
      "apikey": supabaseKey,
    },
  });
  if (!userRes.ok) {
    return new Response("Invalid token", { status: 401 });
  }
  const user = await userRes.json();
  const userId = user.id;

  // Best-effort per-function-instance rate limiting; this Map is not a global quota store.
  const now = Date.now();
  const windowStart = now - RATE_LIMIT_WINDOW_MS;
  const userRequests = requestLog.get(userId) || [];
  const recentRequests = userRequests.filter((t) => t > windowStart);
  if (recentRequests.length >= MAX_REQUESTS_PER_WINDOW) {
    return new Response(
      JSON.stringify({ error: "لقد تجاوزت الحد المسموح من Requests. يرجى الانتظار." }),
      { status: 429, headers: { "Content-Type": "application/json" } }
    );
  }
  recentRequests.push(now);
  requestLog.set(userId, recentRequests);

  // Parse request
  let body;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }
  const { prompt, context } = body;
  if (!prompt || typeof prompt !== "string") {
    return new Response("Missing prompt", { status: 400 });
  }

  // Limit prompt length
  const trimmedPrompt = prompt.slice(0, 2000);

  // Build system message
  const systemMessage = `أنت مساعد تعليمي لتطبيق عالم العلوم، مخصص لطلاب المنهاج السوري من الصف التاسع حتى البكالوريا.
مهمتك مساعدة الطالب على الفهم والتعلّم، لا الاكتفاء بإعطاء النتيجة.
- اشرح المفاهيم والمصطلحات بلغة عربية واضحة ومناسبة لعمر الطالب.
- حل مسائل الرياضيات والفيزياء خطوة بخطوة، مع توضيح القوانين والتعويض والوحدات.
- وازن المعادلات الكيميائية واشرح خطوات الحل.
- وضّح سبب صحة الإجابة أو خطئها، وقدّم أمثلة تدريبية عند الحاجة.
- لا تنسب معلومة إلى كتاب أو صفحة أو مصدر رسمي ما لم تكن متأكدًا منها.
- إذا كان السؤال خارج نطاق التعليم، وضّح حدود اختصاصك بأدب.
- لا تخترع موعد امتحان أو محتوى منهجي أو إجابة غير مؤكدة.
- لا تكشف بيانات مستخدمين آخرين أو أسرارًا أو مفاتيح تقنية.`;

  // A missing provider secret is a setup error, not a valid empty response.
  if (AI_PROVIDER === "openai" && !OPENAI_API_KEY) {
    return new Response(
      JSON.stringify({ error: "المساعد الذكي غير مهيأ على الخادم بعد." }),
      { status: 503, headers: { "Content-Type": "application/json" } }
    );
  }

  // Call AI provider
  let aiReply;
  try {
    if (AI_PROVIDER === "openai") {
      const aiRes = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: systemMessage },
            { role: "user", content: trimmedPrompt },
          ],
          max_tokens: MAX_TOKENS,
          temperature: 0.7,
        }),
      });
      if (!aiRes.ok) {
        throw new Error(`OpenAI API error: ${aiRes.status}`);
      }
      const aiData = await aiRes.json();
      aiReply = aiData.choices?.[0]?.message?.content || "لا توجد إجابة";
    } else {
      throw new Error("Unsupported AI provider");
    }
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "حدث خطأ في معالجة الطلب. يرجى المحاولة لاحقًا." }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  return new Response(
    JSON.stringify({ reply: aiReply }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});