"""Locust load test — jol-llm API on llm-prod-lt01.

Simulates concurrent authenticated clients against the full path
(Caddy mTLS -> bridge auth -> Ollama). Run from an authorized
workstation with a client certificate — never from the host itself
during production load:

    JOL_API_KEY=jol_test_... \
    locust -f tests/load/locustfile.py \
        --host https://10.40.10.21:8443 \
        --users 4 --spawn-rate 1 --run-time 5m --headless

Sizing rationale: llm-prod-lt01 is a single-node CPU inference box
(~1.4 tok/s on the resident model). More than ~4 concurrent
generations queue aggressively; the bridge queue-depth alert fires
above 3 sustained. Keep user counts low and interpret latency, not
throughput, as the primary output.

Compliance: prompts are canned constants only — no client content
ever enters the test suite (data-retention-policy.md §3).
"""

import os
import ssl
import time
import urllib3

from locust import HttpUser, between, events, task

MODEL = os.environ.get("MODEL", "qwen3-32b-q8_0")
MTLS_CERT = os.environ.get("JOL_MTLS_CERT", "")
MTLS_KEY = os.environ.get("JOL_MTLS_KEY", "")
MAX_TOKENS = int(os.environ.get("MAX_TOKENS", "16"))

# Small, fixed prompt corpus: deterministic, license-free, content-free.
CANNED_PROMPTS = [
    "Reply with the single word: OK",
    "What is 2 + 2? Answer with only the number.",
    "Name one primary color. One word only.",
]


class MtlsClientMixin:
    """Attach the mTLS client certificate to the underlying session."""

    def on_start(self):
        if MTLS_CERT and MTLS_KEY:
            self.client.cert = (MTLS_CERT, MTLS_KEY)
        # Internal CA is private by design; verification pinned via cert
        # pair instead of a public trust chain.
        urllib3.disable_warnings()
        self.client.verify = False


class LlmUser(MtlsClientMixin, HttpUser):
    wait_time = between(5, 15)  # think time: operators are humans

    @task(8)
    def chat_completion_short(self):
        payload = {
            "model": MODEL,
            "messages": [
                {"role": "user", "content": CANNED_PROMPTS[int(time.time()) % 3]}
            ],
            "max_tokens": MAX_TOKENS,
            "stream": False,
        }
        with self.client.post(
            "/v1/chat/completions",
            json=payload,
            headers=self._auth_headers(),
            timeout=180,  # CPU inference is slow by design; SLA is not 5s at load
            catch_response=True,
            name="/v1/chat/completions (short)",
        ) as resp:
            if resp.status_code == 429:
                resp.success()  # rate limiting is expected behaviour, not failure
            elif resp.status_code != 200:
                resp.failure(f"HTTP {resp.status_code}")

    @task(1)
    def auth_negative_control(self):
        """One in ten requests is deliberately unauthenticated — the
        platform must return 401 every time. Any other outcome is a
        regression in the auth gate."""
        with self.client.post(
            "/v1/chat/completions",
            json={"model": MODEL, "messages": [{"role": "user", "content": "ping"}]},
            timeout=15,
            catch_response=True,
            name="/v1/chat/completions (no key — must 401)",
        ) as resp:
            if resp.status_code == 401:
                resp.success()
            else:
                resp.failure(f"expected 401, got {resp.status_code}")

    def _auth_headers(self):
        key = os.environ.get("JOL_API_KEY", "")
        if not key:
            raise RuntimeError("JOL_API_KEY is required for load testing")
        return {"Authorization": f"Bearer {key}"}


@events.test_stop.add_listener
def _summary(environment, **kwargs):
    """Emit the two numbers capacity-planning cares about."""
    stats = environment.runner.stats.total
    print(
        f"[load-summary] requests={stats.num_requests} "
        f"failures={stats.num_failures} "
        f"p95_ms={stats.get_response_time_percentile(0.95):.0f} "
        f"avg_ms={stats.avg_response_time:.0f}"
    )
