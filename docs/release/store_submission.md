# Store submission checklist

No Play Console mutation is performed by repository tooling.

Before submission, the owner must:

- approve the final app name, application ID, icon, screenshots, short/long
  descriptions, category, support contact, and public privacy-policy location;
- complete data-safety answers from `PRIVACY.md` and the privacy data map,
  including optional friend-relay traffic and user-directed local exports;
- complete content rating, target audience, ads declaration, account deletion
  applicability, permissions, and app-access declarations;
- confirm no account, analytics, advertising, location, contacts, microphone,
  or camera behavior has been added since policy review;
- upload an owner-signed AAB from the approved commit and verify version code,
  signing certificate, supported devices, ABIs, and pre-launch report;
- provide GPL license/notices and corresponding source access for every
  distributed GPL-covered component;
- complete native-speaker review for each locale advertised as translated;
- document staged rollout, monitoring, support, halt, and rollback ownership.

Screenshots and claims must show implemented behavior only. Planned premium
features, unbundled Stockfish, unreviewed translations, or unexecuted device
tests must not be represented as shipped.
