import { assertEquals } from "jsr:@std/assert";
import { corsHeaders, normalizeSubmission } from "./helpers.ts";

Deno.test("normalizes a valid submission", () => {
  assertEquals(normalizeSubmission({
    email: " Test@Example.no ",
    consent: true,
    company: "",
    source: "nithusan.no/poengjeger",
  }), {
    email: "test@example.no",
    consent: true,
    source: "nithusan.no/poengjeger",
  });
});

Deno.test("rejects missing consent, invalid email, honeypot, and wrong source", () => {
  assertEquals(normalizeSubmission({ email: "a@b.no", consent: false, source: "nithusan.no/poengjeger" }), null);
  assertEquals(normalizeSubmission({ email: "not-an-email", consent: true, source: "nithusan.no/poengjeger" }), null);
  assertEquals(normalizeSubmission({ email: "a@b.no", consent: true, company: "spam", source: "nithusan.no/poengjeger" }), null);
  assertEquals(normalizeSubmission({ email: "a@b.no", consent: true, source: "other" }), null);
});

Deno.test("allows only configured origins", () => {
  assertEquals(corsHeaders("https://nithusan.no")?.["Access-Control-Allow-Origin"], "https://nithusan.no");
  assertEquals(corsHeaders("https://example.com"), null);
  assertEquals(corsHeaders(null), null);
});
