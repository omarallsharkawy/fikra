# FIKRAH brand icons

The two user-supplied PNGs under `assets/icons/` are the source artwork. They are bundled without recoloring, cropping or redrawing. `FikraBrandMark` selects the file named `dark-mode` for the resolved dark Flutter theme and `light-mode` for the resolved light theme. It updates when appearance changes, keeps a square aspect ratio, and never mirrors the lettering in RTL. It is decorative beside an existing accessible title.

The user-approved display name is **FIKRAH**, with that spelling and capitalization in both Arabic and English. Android's application label, Flutter application title, welcome branding, About title and localized references to the app use this name. Existing package identifiers and stored data namespaces retain their technical names.

Product screen headers share the mark. The preserved local app also displays it on the welcome screen and the settings About card. Existing navigation symbols retain their action meanings.

## Android launcher

Android uses the light artwork by default and the dark artwork through `drawable-night-nodpi`. These two native PNGs are byte-for-byte copies of the source assets. When replacing the source artwork, copy each file to the matching `fikrah_launcher.png` native resource as well.

API 24–25 use the complete supplied bitmap. API 26+ use an adaptive icon with a matching opaque background and a 20% foreground inset so launcher masks preserve the mark. The manifest retains `@mipmap/ic_launcher` and the existing application identifiers. No new package or native dependency is introduced.

Launcher resources resolve against the **system** appearance, independently of the Flutter appearance preference. Some launchers cache icons and may refresh them only after reopening the launcher or reinstalling/updating the app. Wallpaper-based monochrome icon coloring is controlled by supported system launchers; this change supplies the two requested color artworks, not a new monochrome design.

Implementation follows Android's [adaptive icon guidance](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive) and [configuration-specific resources](https://developer.android.com/guide/topics/resources/providing-resources). This repository currently contains an Android host; no iOS host or release identifiers are created.

## Verification

Focused widget checks decode both packaged images, switch the app theme live, preserve RTL orientation and check the shared product header at 360dp and 2x text in Arabic/English and both themes. Existing welcome and navigation tests cover the surrounding layouts. Build and physical-device results are recorded in the phase validation document.
