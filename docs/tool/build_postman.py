"""Builds docs/TenaxProp-Mobile-App-API.postman_collection.json.

Every request mirrors a real call site in lib/ (repositories/services), with
the exact method, path, query params and body keys the app sends.
Run:  python3 docs/tool/build_postman.py
"""
import json
from pathlib import Path

API = "{{api_base_url}}"
WEB = "{{web_base_url}}"


def req(name, method, path, desc, *, base=API, query=None, body=None,
        form=None, auth="bearer", headers=None, source=""):
    url_raw = f"{base}{path}"
    q = []
    if query:
        q = [{"key": k, "value": str(v).lower() if isinstance(v, bool) else str(v)}
             for k, v in query.items()]
        url_raw += "?" + "&".join(f"{i['key']}={i['value']}" for i in q)
    host_path = path.split("?")[0].strip("/").split("/")
    hdrs = [{"key": "Accept", "value": "application/json"}]
    if body is not None:
        hdrs.append({"key": "Content-Type", "value": "application/json"})
    for k, v in (headers or {}).items():
        hdrs.append({"key": k, "value": v})
    r = {
        "method": method,
        "header": hdrs,
        "url": {"raw": url_raw, "host": [base], "path": host_path,
                **({"query": q} if q else {})},
        "description": desc + (f"\n\n**App source:** `{source}`" if source else ""),
    }
    if auth == "none":
        r["auth"] = {"type": "noauth"}
    elif auth == "challenge":
        r["auth"] = {"type": "bearer",
                     "bearer": [{"key": "token", "value": "{{challenge_token}}", "type": "string"}]}
    if body is not None:
        r["body"] = {"mode": "raw", "raw": json.dumps(body, indent=2),
                     "options": {"raw": {"language": "json"}}}
    if form is not None:
        r["body"] = {"mode": "formdata", "formdata": form}
    return {"name": f"{name} — {method} {path.split('?')[0]}", "request": r, "response": []}


def file_field(key, desc, optional=False):
    return {"key": key, "type": "file", "src": [], "description": desc,
            **({"disabled": True} if optional else {})}


def text_field(key, value, desc, optional=False):
    return {"key": key, "value": value, "type": "text", "description": desc,
            **({"disabled": True} if optional else {})}


LOGIN_TEST = """const b = pm.response.json();
if (b && b.data) {
  if (b.data.access_token) pm.collectionVariables.set('access_token', b.data.access_token);
  if (b.data.challenge_token) pm.collectionVariables.set('challenge_token', b.data.challenge_token);
}"""

folders = []

# ---------------------------------------------------------------- Auth
login = req("Login", "POST", "/auth/login",
            "Signs in. Two success shapes:\n"
            "- normal → `data.access_token` + `data.user`\n"
            "- 2FA on → `data.two_factor_required: true` + `data.challenge_token` (no user yet). "
            "Then call **Two-factor login verify**.\n\n"
            "Test script auto-saves `access_token` / `challenge_token`.",
            auth="none",
            body={"email": "{{email}}", "password": "{{password}}", "device_name": "iPhone 15"},
            source="lib/features/authentication/services/auth_service.dart:23")
login["event"] = [{"listen": "test", "script": {"type": "text/javascript", "exec": LOGIN_TEST.split("\n")}}]

folders.append({"name": "01 · Auth", "item": [
    req("Register", "POST", "/auth/register",
        "Creates the user. Response mirrors login (`access_token` + `user`, `email_verified: false`).",
        auth="none",
        body={"first_name": "John", "last_name": "Doe", "email": "{{email}}",
              "password": "{{password}}", "country_code": "+91", "phone": "9876543210"},
        source="lib/features/authentication/services/auth_service.dart:49"),
    login,
    req("Two-factor login verify", "POST", "/auth/two-factor",
        "Completes a login that returned `two_factor_required`. Bearer = `challenge_token`. "
        "Response `data` may carry `access_token` + `user`; otherwise the challenge token becomes the session token.",
        auth="challenge",
        body={"code": "123456", "device_name": "iPhone 15"},
        source="lib/features/authentication/services/auth_service.dart:102"),
    req("Verify email (OTP)", "POST", "/auth/verify-email",
        "Confirms the post-register OTP. Needs the bearer from register. Returns fresh `access_token` + `user`.",
        body={"email": "{{email}}", "code": "123456"},
        source="lib/features/authentication/services/auth_service.dart:84"),
    req("Resend OTP", "POST", "/auth/resend-otp", "Re-sends the verification/reset OTP.",
        body={"email": "{{email}}"},
        source="lib/features/authentication/services/auth_service.dart:138"),
    req("Forgot password", "POST", "/auth/forgot-password",
        "Always succeeds (never reveals whether the email exists).", auth="none",
        body={"email": "{{email}}"},
        source="lib/features/authentication/services/auth_service.dart:73"),
    req("Logout", "POST", "/auth/logout", "Revokes the current token. No body.",
        source="lib/features/authentication/services/auth_service.dart:147"),
]})

# ---------------------------------------------------------------- Profile & KYC
folders.append({"name": "02 · Profile & KYC", "item": [
    req("Get profile", "GET", "/profile", "Profile envelope; user may be under `data.user` or `data`.",
        source="lib/features/kyc/repositories/kyc_repository.dart:33"),
    req("Update profile", "PUT", "/profile", "Updates editable profile fields.",
        body={"name": "John Doe", "email": "{{email}}", "phone": "9876543210",
              "country_code": "+91", "city": "Ahmedabad"},
        source="lib/features/kyc/repositories/kyc_repository.dart:57"),
    req("KYC status", "GET", "/kyc", "Verification state; per-document state lives under `data.submission`.",
        source="lib/features/kyc/repositories/kyc_repository.dart:49"),
    req("Upload KYC documents", "POST", "/kyc/documents",
        "ONE multipart request. `id_document` + `proof_of_address` are required together; back sides optional. "
        "Returns refreshed KYC status.",
        form=[file_field("id_document", "Required — ID front"),
              file_field("id_document_back", "Optional — ID back", optional=True),
              file_field("proof_of_address", "Required — address proof front"),
              file_field("proof_of_address_back", "Optional — address proof back", optional=True)],
        source="lib/features/kyc/repositories/kyc_repository.dart:71"),
]})

# ---------------------------------------------------------------- Dashboard
folders.append({"name": "03 · Dashboard", "item": [
    req("Dashboard", "GET", "/dashboard",
        "Home snapshot: KPIs, live accounts, health, activity, referral + unread badge data.",
        source="lib/features/home/repositories/home_repository.dart:22"),
]})

# ---------------------------------------------------------------- Accounts
folders.append({"name": "04 · Accounts & MT5", "item": [
    req("List accounts", "GET", "/accounts",
        "Account Center list. `status`: all | active | breached | passed | <raw>. "
        "`phase`: all | evaluation | verification | funded | breached. Envelope `{data[], meta}`.",
        query={"status": "all", "phase": "all"},
        source="lib/features/accounts/repositories/accounts_repository.dart:18"),
    req("Account overview", "GET", "/accounts/{{account_id}}/overview",
        "Account fields + nested `stats`, `objectives`, `credentials`, `overview`, `chart`.",
        source="lib/features/account/repositories/account_repository.dart:17"),
    req("Account platform & credentials", "GET", "/accounts/{{account_id}}/platform",
        "`data.account.credentials` (login/server/passwords), `data.platform_locked`. "
        "`reveal=true` unmasks passwords server-side.",
        query={"reveal": False},
        source="lib/features/account/repositories/account_repository.dart:33"),
    req("Account reset quote", "GET", "/accounts/{{account_id}}/reset",
        "`data.account` + `data.quote` (pricing + eligibility + payment methods).",
        source="lib/features/account/repositories/account_repository.dart:44"),
    req("Purchase account reset", "POST", "/accounts/{{account_id}}/reset",
        "Buys a reset with the chosen payment method.",
        body={"confirm": True, "payment_method_id": 1, "is_manual": False},
        source="lib/features/account/repositories/account_repository.dart:61"),
    req("MT5 accounts (primary selector)", "GET", "/mt5accounts/get",
        "`data.accounts[]` (`id, login, is_primary, is_active`) + `data.primary_account_id`.",
        source="lib/features/accounts/services/primary_account_service.dart:69"),
    req("Set primary MT5 account", "POST", "/mt5accounts/set-primary",
        "Response `data`: `primary_account_id`, `login`.",
        body={"account_id": 1},
        source="lib/features/accounts/services/primary_account_service.dart:89"),
]})

# ---------------------------------------------------------------- Challenges & orders
folders.append({"name": "05 · Challenges & Orders", "item": [
    req("Challenge plans", "GET", "/challenges", "Plans/steps catalogue for the Buy Challenge screen.",
        query={"currency": "USD"},
        source="lib/features/challenge/repositories/challenge_repository.dart:14"),
    req("Compare plans", "GET", "/challenges/compare", "Plan comparison matrix.",
        query={"currency": "USD"},
        source="lib/features/challenge/repositories/challenge_repository.dart:26"),
    req("Price quote", "POST", "/challenges/quote?currency=USD",
        "Recalculates the price for a plan + add-ons. `currency` is a query param.",
        body={"plan_version_id": 1, "addon_ids": []},
        source="lib/features/challenge/repositories/challenge_repository.dart:36"),
    req("Apply coupon", "POST", "/challenges/coupon",
        "Validates a coupon and returns the discounted quote. Invalid coupon → top-level `message`.",
        body={"plan_version_id": 1, "quantity": 1, "addon_ids": [], "swap_free": False,
              "coupon_code": "WELCOME10", "currency": "USD"},
        source="lib/features/challenge/repositories/challenge_repository.dart:58"),
    req("Purchase challenge", "POST", "/challenges/purchase",
        "Creates an order. Response `data`: `order_id`, `path` (free | manual | gateway), optional `gateway_url`.",
        body={"plan_version_id": 1, "quantity": 1, "addon_ids": [], "swap_free": False,
              "coupon_code": None, "payment_method_id": 1, "is_manual": True, "currency": "USD"},
        source="lib/features/challenge/repositories/challenge_repository.dart:87"),
    req("Start free trial", "POST", "/challenges/free-trial",
        "Starts a free-trial account. `platform_integration_id` optional.",
        body={"plan_version_id": 1, "platform_integration_id": 1},
        source="lib/features/challenge/repositories/challenge_repository.dart:124"),
    req("Order detail", "GET", "/orders/{{order_id}}",
        "Complete-payment screen: `order`, `choices`, `payment_instructions`.",
        source="lib/features/payment/repositories/orders_repository.dart:19"),
    req("Upload payment proof", "POST", "/orders/{{order_id}}/proof",
        "Manual payment screenshot (multipart). Returns the updated order.",
        form=[file_field("proof", "Required — payment screenshot"),
              text_field("reference", "TXN123456", "Optional — bank/UTR reference", optional=True)],
        source="lib/features/payment/repositories/orders_repository.dart:35"),
]})

# ---------------------------------------------------------------- Trading (web host)
T = "lib/features/positions/repositories/positions_repository.dart"
folders.append({"name": "06 · Trading (web_base_url)", "description":
    "These live on the WEB host (`web_base_url`), NOT `/api/v1`. "
    "`mt5_account` = MT5 login of the active account. TP/SL are sent in BOTH spellings (`tp`/`take_profit`, `sl`/`stop_loss`).",
    "item": [
    req("Market order", "POST", "/api/user/trade/new-order",
        "`type`: buy | sell. TP/SL optional and independent.", base=WEB,
        body={"symbol": "EURUSD", "volume": 0.01, "type": "buy", "mt5_account": "{{mt5_account}}",
              "tp": 1.1, "take_profit": 1.1, "sl": 1.05, "stop_loss": 1.05},
        source=f"{T}:22"),
    req("Pending order", "POST", "/api/user/trade/new-order",
        "`type`: buy_limit | sell_limit | buy_stop | sell_stop | buy_stop_limit | sell_stop_limit. "
        "`stop_limit_price` only for stop-limit types.", base=WEB,
        body={"symbol": "EURUSD", "volume": 0.01, "type": "buy_limit", "price": 1.075,
              "mt5_account": "{{mt5_account}}", "stop_limit_price": 1.074,
              "tp": 1.1, "take_profit": 1.1, "sl": 1.05, "stop_loss": 1.05},
        source=f"{T}:54"),
    req("Close position (full/partial)", "POST", "/api/user/trade/closePositionByPositionId",
        "Omit `volume` for a full close; pass lots for a partial close.", base=WEB,
        body={"position_id": 123456, "mt5_account": "{{mt5_account}}", "volume": 0.01},
        source=f"{T}:92"),
    req("Close all positions", "POST", "/api/user/trade/closePositions",
        "Closes every open position on the account.", base=WEB,
        body={"mt5_account": "{{mt5_account}}"}, source=f"{T}:114"),
    req("Cancel pending order", "POST", "/api/user/trade/closePendingOrder", "", base=WEB,
        body={"order_id": 123456, "mt5_account": "{{mt5_account}}"}, source=f"{T}:128"),
    req("Update position TP/SL", "POST", "/api/user/trade/update-tp-sl",
        "Send `0` to clear a level; omit a key to leave it unchanged.", base=WEB,
        body={"mt5_account": "{{mt5_account}}", "position_id": 123456,
              "take_profit": 1.1, "stop_loss": 1.05}, source=f"{T}:148"),
    req("Update pending order TP/SL", "POST", "/api/user/trade/update-pending-order-tp-sl",
        "Unset level is sent as `null` (not omitted) so the engine clears it.", base=WEB,
        body={"mt5_account": "{{mt5_account}}", "order_id": 123456, "price": 1.075,
              "stop_loss": None, "take_profit": 1.1}, source=f"{T}:173"),
    req("Trade history", "GET", "/api/user/trade/tradehistory",
        "`data` is a flat list or `{data, pagination, totals, summary}`. "
        "`append=true` is sent for page > 1; `_t` is a cache-buster; `from`/`to` optional (YYYY-MM-DD).",
        base=WEB,
        query={"mt5_account": "{{mt5_account}}", "page": 1, "per_page": 10,
               "from": "2026-09-01", "to": "2026-09-28", "_t": "{{$timestamp}}"},
        source=f"{T}:198"),
]})

# ---------------------------------------------------------------- Tools
folders.append({"name": "07 · Tools & Market data", "item": [
    req("Instruments / symbols", "GET", "/tools/symbols",
        "`data.symbols[]` + `data.categories[]`. `q` (search) and `account_id` optional.",
        query={"q": "EUR", "account_id": "{{account_id}}"},
        source="lib/features/symbols/repositories/symbols_repository.dart:24"),
    req("Calculators", "GET", "/tools/calculators", "Calculator tabs + field definitions.",
        source="lib/features/calculators/repositories/calculators_repository.dart:12"),
    req("Economic calendar", "GET", "/tools/calendar",
        "`data.events[]` + `data.filters`. `currency` e.g. ALL, USD, EUR.",
        query={"currency": "ALL"},
        source="lib/features/economic_calendar/repositories/economic_calendar_repository.dart:16"),
]})

# ---------------------------------------------------------------- Growth
folders.append({"name": "08 · Growth (Referral, Offers, Certificates, Competitions)", "item": [
    req("Referral summary", "GET", "/growth/referrals",
        "`data.referral` (code, share_url) + `data.stats` (referrals, to_be_paid).",
        source="lib/features/referral/repositories/referral_repository.dart:27"),
    req("Referral commissions", "GET", "/growth/referrals/commissions",
        "Paged. `data[]` flat; `meta.current_page` / `meta.has_next`.",
        query={"page": 1},
        source="lib/features/referral/repositories/referral_repository.dart:39"),
    req("Referral withdraw", "POST", "/growth/referrals/withdraw",
        "Withdraw referral earnings to a saved payout method.",
        body={"amount": 50, "payout_method_id": 1},
        source="lib/features/referral/repositories/referral_repository.dart:80"),
    req("Offers", "GET", "/growth/offers", "`data.offers[]` + `data.available_count`.",
        source="lib/features/offers/repositories/offers_repository.dart:15"),
    req("Certificates", "GET", "/growth/certificates",
        "`data.certificates[]` (criteria[], earned, download_url) + `data.earned_count`.",
        source="lib/features/certificates/repositories/certificates_repository.dart:15"),
    req("Certificate document", "GET", "/growth/certificates/{{certificate_id}}/download",
        "`data`: name, holder, issued_at, verification_code, format (`html`), html.",
        source="lib/features/certificates/repositories/certificates_repository.dart:24"),
    req("Competitions", "GET", "/growth/competitions",
        "`data.competitions[]` (prizes, rules, leaderboard), `competitions_meta`, `accounts[]`, `stats.cash_pool`.",
        source="lib/features/competitions/repositories/competitions_repository.dart:36"),
    req("Register for competition", "POST", "/growth/competitions/register",
        "Response: user-facing `message`, `data: null`.",
        body={"competition_id": 1, "trading_account_id": 1},
        source="lib/features/competitions/repositories/competitions_repository.dart:18"),
]})

# ---------------------------------------------------------------- Finance
F = "lib/features/rewards/repositories/rewards_repository.dart"
PM = "lib/features/payout_methods/repositories/payout_methods_repository.dart"
folders.append({"name": "09 · Finance (Rewards, Payouts, Billing)", "item": [
    req("Rewards page", "GET", "/finance/rewards",
        "Stats + eligible accounts + methods + payouts. `status`: all | pending | approved | disbursed.",
        query={"status": "all", "page": 1}, source=f"{F}:23"),
    req("Payout method types", "GET", "/finance/method-types",
        "Types (bank / usdt / upi) with field definitions. List under `data.method_types` or `data.types`.",
        source=f"{PM}:28"),
    req("Saved payout methods", "GET", "/finance/methods", "List under `data.methods`.",
        source=f"{PM}:13"),
    req("Add payout method", "POST", "/finance/methods",
        "`details` keys depend on `type` — use the field keys from method-types.",
        body={"type": "bank", "label": "HDFC Savings", "currency": "USD", "is_default": True,
              "details": {"account_holder": "John Doe", "account_number": "1234567890",
                          "ifsc": "HDFC0001234", "bank_name": "HDFC Bank"}},
        source=f"{PM}:45"),
    req("Update payout method", "PUT", "/finance/methods/{{method_id}}",
        "Payout Methods screen sends type/label/currency/details; Rewards screen may send only "
        "`label` / `details` / `is_default`.",
        body={"type": "bank", "label": "HDFC Savings", "currency": "USD",
              "details": {"account_number": "1234567890"}},
        source=f"{PM}:64"),
    req("Delete payout method", "DELETE", "/finance/methods/{{method_id}}", "", source=f"{PM}:83"),
    req("Request payout", "POST", "/finance/payouts",
        "422 when no payout cycle is open. `trading_account_id`, `notes`, `current_password` optional.",
        body={"amount": 100, "currency": "USD", "payout_method_id": 1, "trading_account_id": 1,
              "notes": "Monthly payout", "current_password": "{{password}}"},
        source=f"{F}:150"),
    req("Payout history", "GET", "/finance/payouts",
        "Paged. `data[]` flat; `meta.current_page / has_next / total`.",
        query={"status": "all", "page": 1}, source=f"{F}:180"),
    req("Cancel payout", "POST", "/finance/payouts/{{payout_id}}/cancel", "Cancels a pending payout.",
        source=f"{F}:206"),
    req("Billing transactions", "GET", "/finance/transactions",
        "`type`: all | <filter name>. `status`: all | …",
        query={"type": "all", "status": "all"},
        source="lib/features/billing/repositories/billing_repository.dart:13"),
    req("Export billing CSV", "GET", "/finance/transactions/export", "Returns raw CSV text.",
        source="lib/features/billing/repositories/billing_repository.dart:38"),
    req("Invoice", "GET", "/finance/transactions/{{transaction_id}}/invoice",
        "`data`: invoice_number, format, html.",
        source="lib/features/billing/repositories/billing_repository.dart:49"),
]})

# ---------------------------------------------------------------- Notifications
N = "lib/features/notifications/repositories/notifications_repository.dart"
folders.append({"name": "10 · Notifications", "item": [
    req("Notifications feed", "GET", "/notifications",
        "Paged. Items: id, type, title, body, event_key, meta, read_at, created_at.",
        query={"page": 1}, source=f"{N}:25"),
    req("Unread count", "GET", "/notifications/unread-count", "`data.count`.", source=f"{N}:49"),
    req("Mark one read", "POST", "/notifications/{{notification_id}}/read",
        "Returns new unread total in `data.count`.", source=f"{N}:62"),
    req("Mark all read", "POST", "/notifications/read-all", "", source=f"{N}:75"),
    req("Get preferences", "GET", "/notifications/preferences", "`data.catalog[]` + `data.preferences`.",
        source=f"{N}:85"),
    req("Save preferences", "PUT", "/notifications/preferences",
        "`preferences` = map of event_key → channel toggles.",
        body={"preferences": {"payout_approved": {"email": True, "push": True}}},
        source=f"{N}:97"),
]})

# ---------------------------------------------------------------- Support
S = "lib/features/support/repositories/support_repository.dart"
folders.append({"name": "11 · Support & Help", "item": [
    req("Trading rules", "GET", "/support/rules", "`data.tabs[]` + `data.sections[]`.",
        source="lib/features/trading_rules/repositories/trading_rules_repository.dart:15"),
    req("FAQ", "GET", "/support/faq", "`data.items[]` of `{q, a}`.",
        source="lib/features/faq/repositories/faq_repository.dart:18"),
    req("Ticket topics", "GET", "/support/topics", "`data.topics[]` of `{value, label}`.",
        source=f"{S}:33"),
    req("List tickets", "GET", "/support/tickets", "`tab`: open | closed | all.",
        query={"tab": "open"}, source=f"{S}:51"),
    req("Ticket detail", "GET", "/support/tickets/{{ticket_id}}", "Ticket + messages thread.",
        source=f"{S}:68"),
    req("Create ticket", "POST", "/support/tickets",
        "`topic` = a value from Ticket topics. `account_login` optional.",
        body={"topic": "trading", "subject": "Order not executed",
              "message": "My order on EURUSD did not execute.", "account_login": "{{mt5_account}}"},
        source=f"{S}:85"),
    req("Reply to ticket", "POST", "/support/tickets/{{ticket_id}}/reply",
        "Returns the updated ticket (may be nested under `data.ticket`).",
        body={"message": "Any update on this?"}, source=f"{S}:109"),
]})

# ---------------------------------------------------------------- Settings
SEC = "lib/features/settings/repositories/security_repository.dart"
folders.append({"name": "12 · Settings & Security", "item": [
    req("Security snapshot", "GET", "/settings/security",
        "two_factor_enabled, two_factor_required, recovery_codes_remaining, prefs, sessions[].",
        source=f"{SEC}:15"),
    req("Save security prefs", "PUT", "/settings/security", "",
        body={"login_alerts": True, "withdrawal_confirmation": True, "platform_lock": False},
        source=f"{SEC}:22"),
    req("Change password", "POST", "/settings/password",
        "Signs the user out of other devices. 422 → `errors.<field>[0]`.",
        body={"current_password": "{{password}}", "password": "NewPass@123",
              "password_confirmation": "NewPass@123"},
        source=f"{SEC}:31"),
    req("Save beneficiary", "PUT", "/settings/beneficiary", "",
        body={"full_name": "Jane Doe", "relationship": "Spouse", "email": "jane@example.com",
              "mobile": "9876543210"},
        source=f"{SEC}:47"),
    req("2FA — start enrolment", "POST", "/settings/two-factor/enrol",
        "`data.secret` + `data.qr_url` (otpauth://).", source=f"{SEC}:65"),
    req("2FA — confirm enrolment", "POST", "/settings/two-factor/confirm",
        "Wrong code → 422 `errors.code[]`.",
        body={"secret": "{{twofa_secret}}", "code": "123456"}, source=f"{SEC}:76"),
    req("2FA — regenerate recovery codes", "POST", "/settings/two-factor/recovery-codes",
        "Codes in `data` (list) or `data.recovery_codes`.",
        body={"current_password": "{{password}}"}, source=f"{SEC}:87"),
    req("2FA — disable", "DELETE", "/settings/two-factor", "DELETE with a JSON body.",
        body={"current_password": "{{password}}"}, source=f"{SEC}:108"),
]})

# ---------------------------------------------------------------- WebSocket
folders.append({"name": "13 · WebSocket auth (web_base_url)", "item": [
    req("Broadcasting auth", "POST", "/api/broadcasting/auth",
        "Pusher private-channel auth used by the WebSocket manager. Returns `{auth}` signature.",
        base=WEB,
        body={"socket_id": "123.456", "channel_name": "private-account.{{mt5_account}}"},
        source="lib/core/websocket/pusher_client.dart"),
]})

collection = {
    "info": {
        "name": "TenaxProp Mobile App — Full API",
        "_postman_id": "tenax-prop-mobile-full-api",
        "description": (
            "Every REST call the Flutter app makes, generated from the repositories in `lib/`.\n\n"
            "**Bases**\n- `api_base_url` — REST mobile API (includes `/api/v1`)\n"
            "- `web_base_url` — portal host; used by Trading + broadcasting auth\n\n"
            "**Auth** — `Authorization: Bearer {{access_token}}` (collection-level). "
            "Run *Auth → Login* first; its test script saves the token.\n\n"
            "**Envelope** — `{ success: bool, message: string, data: any, meta?: {current_page, has_next, total}, "
            "errors?: {field: [msg]} }`. Validation errors return HTTP 422 with `errors`.\n\n"
            "**Regenerate** — `python3 docs/tool/build_postman.py`."
        ),
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    },
    "auth": {"type": "bearer", "bearer": [{"key": "token", "value": "{{access_token}}", "type": "string"}]},
    "variable": [
        {"key": "api_base_url", "value": "https://your-domain.com/api/v1"},
        {"key": "web_base_url", "value": "https://your-domain.com"},
        {"key": "email", "value": "user@example.com"},
        {"key": "password", "value": ""},
        {"key": "access_token", "value": ""},
        {"key": "challenge_token", "value": ""},
        {"key": "account_id", "value": "1"},
        {"key": "mt5_account", "value": "100001"},
        {"key": "order_id", "value": "1"},
        {"key": "method_id", "value": "1"},
        {"key": "payout_id", "value": "1"},
        {"key": "transaction_id", "value": "1"},
        {"key": "certificate_id", "value": "1"},
        {"key": "notification_id", "value": "1"},
        {"key": "ticket_id", "value": "1"},
        {"key": "twofa_secret", "value": ""},
    ],
    "item": folders,
}

out = Path(__file__).resolve().parents[1] / "TenaxProp-Mobile-App-API.postman_collection.json"
out.write_text(json.dumps(collection, indent=2) + "\n")
count = sum(len(f["item"]) for f in folders)
print(f"wrote {out} — {len(folders)} folders, {count} requests")
