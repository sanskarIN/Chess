# Locale identifiers

Resource filenames use standard base language identifiers so Flutter can build
exactly 33 resources without generating hidden base-locale fallbacks.
Script-qualified runtime tags are produced from the catalog where needed.

| # | English name | Native name | Resource/settings ID | Runtime tag | Formatting fallback | Direction |
|---:|---|---|---|---|---|---|
| 1 | Assamese | অসমীয়া | `as` | `as` | `as` | LTR |
| 2 | Bengali | বাংলা | `bn` | `bn` | `bn` | LTR |
| 3 | Bodo | बड़ो | `brx` | `brx` | `hi` | LTR |
| 4 | Dogri | डोगरी | `doi` | `doi` | `hi` | LTR |
| 5 | Gujarati | ગુજરાતી | `gu` | `gu` | `gu` | LTR |
| 6 | Hindi | हिन्दी | `hi` | `hi` | `hi` | LTR |
| 7 | Kannada | ಕನ್ನಡ | `kn` | `kn` | `kn` | LTR |
| 8 | Kashmiri | کٲشُر | `ks` | `ks-Arab` | `ur` | RTL |
| 9 | Konkani | कोंकणी | `kok` | `kok` | `mr` | LTR |
| 10 | Maithili | मैथिली | `mai` | `mai` | `hi` | LTR |
| 11 | Malayalam | മലയാളം | `ml` | `ml` | `ml` | LTR |
| 12 | Manipuri or Meitei | ꯃꯤꯇꯩ ꯂꯣꯟ | `mni` | `mni-Mtei` | `bn` | LTR |
| 13 | Marathi | मराठी | `mr` | `mr` | `mr` | LTR |
| 14 | Nepali | नेपाली | `ne` | `ne` | `ne` | LTR |
| 15 | Odia | ଓଡ଼ିଆ | `or` | `or` | `or` | LTR |
| 16 | Punjabi | ਪੰਜਾਬੀ | `pa` | `pa-Guru` | `pa` | LTR |
| 17 | Sanskrit | संस्कृतम् | `sa` | `sa` | `hi` | LTR |
| 18 | Santali | ᱥᱟᱱᱛᱟᱲᱤ | `sat` | `sat-Olck` | `bn` | LTR |
| 19 | Sindhi | سنڌي | `sd` | `sd-Arab` | `ur` | RTL |
| 20 | Tamil | தமிழ் | `ta` | `ta` | `ta` | LTR |
| 21 | Telugu | తెలుగు | `te` | `te` | `te` | LTR |
| 22 | Urdu | اردو | `ur` | `ur` | `ur` | RTL |
| 23 | Bhojpuri | भोजपुरी | `bho` | `bho` | `hi` | LTR |
| 24 | Rajasthani | राजस्थानी | `raj` | `raj` | `hi` | LTR |
| 25 | Chhattisgarhi | छत्तीसगढ़ी | `hne` | `hne` | `hi` | LTR |
| 26 | Tulu | ತುಳು | `tcy` | `tcy` | `kn` | LTR |
| 27 | Garhwali | गढ़वाली | `gbm` | `gbm` | `hi` | LTR |
| 28 | Kumaoni | कुमाऊँनी | `kfy` | `kfy` | `hi` | LTR |
| 29 | Magahi | मगही | `mag` | `mag` | `hi` | LTR |
| 30 | Haryanvi | हरियाणवी | `bgc` | `bgc` | `hi` | LTR |
| 31 | Awadhi | अवधी | `awa` | `awa` | `hi` | LTR |
| 32 | Gondi | गोंडी | `gon` | `gon` | `hi` | LTR |
| 33 | English | English | `en` | `en` | `en` | LTR |

The formatting fallback is used only when `intl` does not provide dedicated
number/date symbols for the resource identifier. It does not imply that the
languages are interchangeable.
