# Localization completeness

Updated for the stable source release against the 934-message English source.

| State | Locale count | Key completeness | Native-speaker review |
|---|---:|---:|---:|
| English source verified | 1 | 934 / 934 | Source reviewed |
| Complete English fallback draft | 32 | 934 / 934 each | Required |
| Missing or empty resources | 0 | 0 | Not applicable |

Every resource has exact English key and metadata parity, no empty message
values, and unchanged placeholder contracts. This is source completeness, not
translation completeness. The 32 fallback packs must remain visibly marked
`community_review_required` in developer metadata until a human review is
recorded.

Run `dart run tool/verify_localizations.dart` to reproduce this report’s
structural claims. CI also runs the generator drift check and verifier.
