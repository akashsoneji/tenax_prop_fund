# TenaxProp Mobile App — API Reference

This lists every REST call the Flutter app makes. Each entry comes from the matching repository or service in `lib/`.
Postman: import `docs/TenaxProp-Mobile-App-API.postman_collection.json`. To regenerate it, run `python3 docs/tool/build_postman.py`.

## Conventions

**Base URLs**
- `api_base_url`: the REST mobile API, including `/api/v1`. It comes from `FlavorConfig.apiBaseUrl`, which reads `API_BASE_URL` in `config/flavors/<flavor>.json`.
- `web_base_url`: the portal host, from `FlavorConfig.webBaseUrl` (`WEB_BASE_URL` in the same file). Only **Trading** and **Broadcasting auth** use it (`ApiClient.getWeb` / `postWeb`).

**Headers**
- `Accept: application/json`
- `Authorization: Bearer <access_token>`. `ApiInterceptor` injects this automatically. Login, Register and Forgot password don't need it.
- Multipart endpoints send `multipart/form-data`.

**Response envelope**
```json
{ "success": true, "message": "…", "data": {}, "meta": { "current_page": 1, "has_next": true, "total": 42 } }
```
Validation errors come back as HTTP `422` with `{ "message": "…", "errors": { "field": ["msg"] } }`.

---

## 1. Auth

| Method | Path | Body | Notes |
|---|---|---|---|
| POST | `/auth/register` | `first_name, last_name, email, password, country_code, phone` | Returns `access_token` + `user` (`email_verified: false`) |
| POST | `/auth/login` | `email, password, device_name` | Returns either `access_token` + `user`, or `two_factor_required: true` + `challenge_token` |
| POST | `/auth/two-factor` | `code, device_name` | Bearer = `challenge_token` |
| POST | `/auth/verify-email` | `email, code` | Post-register OTP; returns a fresh token + user |
| POST | `/auth/resend-otp` | `email` | |
| POST | `/auth/forgot-password` | `email` | Always succeeds |
| POST | `/auth/logout` | none | Revokes the token |

## 2. Profile & KYC

| Method | Path | Params / Body | Notes |
|---|---|---|---|
| GET | `/profile` | none | User is at `data.user` or `data` |
| PUT | `/profile` | `name, email, phone, country_code, city` | |
| GET | `/kyc` | none | Document state is at `data.submission` |
| POST | `/kyc/documents` | **multipart**: `id_document`*, `proof_of_address`*, `id_document_back`, `proof_of_address_back` | Sent as one request. The two fields marked * are required together |

## 3. Dashboard

| GET | `/dashboard` | none | KPIs, live accounts, health, activity, referral, unread count |
|---|---|---|---|

## 4. Accounts & MT5

| Method | Path | Params / Body | Notes |
|---|---|---|---|
| GET | `/accounts` | `?status=all\|active\|breached\|passed&phase=all\|evaluation\|verification\|funded\|breached` | `data[]` + `meta` |
| GET | `/accounts/{id}/overview` | none | `stats, objectives, credentials, overview, chart` |
| GET | `/accounts/{id}/platform` | `?reveal=false` | `reveal=true` unmasks the passwords |
| GET | `/accounts/{id}/reset` | none | Reset quote plus eligibility |
| POST | `/accounts/{id}/reset` | `confirm: true, payment_method_id, is_manual` | Buys the reset |
| GET | `/mt5accounts/get` | none | `data.accounts[]`, `data.primary_account_id` |
| POST | `/mt5accounts/set-primary` | `account_id` | |

## 5. Challenges & Orders

| Method | Path | Params / Body | Notes |
|---|---|---|---|
| GET | `/challenges` | `?currency=USD` | Plan catalogue |
| GET | `/challenges/compare` | `?currency=USD` | |
| POST | `/challenges/quote?currency=USD` | `plan_version_id, addon_ids[]` | |
| POST | `/challenges/coupon` | `plan_version_id, quantity, addon_ids[], swap_free, coupon_code, currency` | An invalid coupon returns a top-level `message` |
| POST | `/challenges/purchase` | `plan_version_id, quantity, addon_ids[], swap_free, coupon_code?, payment_method_id, is_manual, currency` | `data`: `order_id`, `path` (free/manual/gateway), `gateway_url?` |
| POST | `/challenges/free-trial` | `plan_version_id, platform_integration_id?` | |
| GET | `/orders/{id}` | none | `order, choices, payment_instructions` |
| POST | `/orders/{id}/proof` | **multipart**: `proof`*, `reference` | Manual payment proof |

## 6. Trading (on `web_base_url`)

`mt5_account` is the MT5 login. TP and SL are sent under **both** key names: `tp` + `take_profit` and `sl` + `stop_loss`.

| Method | Path | Body / Params |
|---|---|---|
| POST | `/api/user/trade/new-order` (market) | `symbol, volume, type (buy/sell), mt5_account, tp?, take_profit?, sl?, stop_loss?` |
| POST | `/api/user/trade/new-order` (pending) | the market fields plus `price` and `stop_limit_price?`; `type` = buy_limit / sell_limit / buy_stop / sell_stop / *_stop_limit |
| POST | `/api/user/trade/closePositionByPositionId` | `position_id, mt5_account, volume?`. Leave out `volume` to close the full position |
| POST | `/api/user/trade/closePositions` | `mt5_account` |
| POST | `/api/user/trade/closePendingOrder` | `order_id, mt5_account` |
| POST | `/api/user/trade/update-tp-sl` | `mt5_account, position_id, take_profit?, stop_loss?`. Send `0` to clear a level |
| POST | `/api/user/trade/update-pending-order-tp-sl` | `mt5_account, order_id, price, stop_loss, take_profit`. Send `null` to clear a level |
| GET | `/api/user/trade/tradehistory` | `?mt5_account&page&per_page=10&from?&to?&append?&_t` |

## 7. Tools

| GET | `/tools/symbols` | `?q&account_id` | `data.symbols[]`, `data.categories[]` |
|---|---|---|---|
| GET | `/tools/calculators` | none | Tabs + field definitions |
| GET | `/tools/calendar` | `?currency=ALL` | `data.events[]`, `data.filters` |

## 8. Growth

| Method | Path | Params / Body |
|---|---|---|
| GET | `/growth/referrals` | none. Returns `data.referral`, `data.stats` |
| GET | `/growth/referrals/commissions` | `?page` |
| POST | `/growth/referrals/withdraw` | `amount, payout_method_id` |
| GET | `/growth/offers` | none |
| GET | `/growth/certificates` | none |
| GET | `/growth/certificates/{id}/download` | none. Returns `data.html` |
| GET | `/growth/competitions` | none |
| POST | `/growth/competitions/register` | `competition_id, trading_account_id` |

## 9. Finance

| Method | Path | Params / Body |
|---|---|---|
| GET | `/finance/rewards` | `?status=all\|pending\|approved\|disbursed&page` |
| GET | `/finance/method-types` | none |
| GET | `/finance/methods` | none |
| POST | `/finance/methods` | `type, label, currency, is_default, details{}`. The `details` keys depend on `type` |
| PUT | `/finance/methods/{id}` | `type?, label?, currency?, details?, is_default?` |
| DELETE | `/finance/methods/{id}` | none |
| POST | `/finance/payouts` | `amount, currency, payout_method_id, trading_account_id?, notes?, current_password?`. Returns 422 when no payout cycle is open |
| GET | `/finance/payouts` | `?status&page` |
| POST | `/finance/payouts/{id}/cancel` | none |
| GET | `/finance/transactions` | `?type=all&status=all` |
| GET | `/finance/transactions/export` | none. Returns CSV |
| GET | `/finance/transactions/{id}/invoice` | none. Returns `data.html` |

## 10. Notifications

| Method | Path | Params / Body |
|---|---|---|
| GET | `/notifications` | `?page` |
| GET | `/notifications/unread-count` | none. Returns `data.count` |
| POST | `/notifications/{id}/read` | none |
| POST | `/notifications/read-all` | none |
| GET | `/notifications/preferences` | none |
| PUT | `/notifications/preferences` | `preferences{}` |

## 11. Support & Help

| Method | Path | Params / Body |
|---|---|---|
| GET | `/support/rules` | none |
| GET | `/support/faq` | none |
| GET | `/support/topics` | none |
| GET | `/support/tickets` | `?tab=open\|closed\|all` |
| GET | `/support/tickets/{id}` | none |
| POST | `/support/tickets` | `topic, subject, message, account_login?` |
| POST | `/support/tickets/{id}/reply` | `message` |

## 12. Settings & Security

| Method | Path | Body |
|---|---|---|
| GET | `/settings/security` | none |
| PUT | `/settings/security` | `login_alerts, withdrawal_confirmation, platform_lock` |
| POST | `/settings/password` | `current_password, password, password_confirmation` |
| PUT | `/settings/beneficiary` | `full_name, relationship, email, mobile` |
| POST | `/settings/two-factor/enrol` | none. Returns `data.secret`, `data.qr_url` |
| POST | `/settings/two-factor/confirm` | `secret, code` |
| POST | `/settings/two-factor/recovery-codes` | `current_password` |
| DELETE | `/settings/two-factor` | `current_password` |

## 13. WebSocket auth (on `web_base_url`)

| POST | `/api/broadcasting/auth` | `socket_id, channel_name` | Pusher private-channel signature |
|---|---|---|---|
