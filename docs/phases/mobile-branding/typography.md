# Mobile branding: English typography

Scope: bundle Inter for English and preserve existing NotoSansArabic rendering,
following the user’s explicit font choice. Display name and language behavior
were completed separately in PR #5. No backend or content migration is involved.

Implementation uses the same font family and fallback chain in shared tokens and
Material themes. Static upstream weights avoid platform-dependent synthesis for
Latin headings. Real fonts are loaded in layout tests, including product routes.

Validation results will be recorded after tests, analysis and the phone build.
