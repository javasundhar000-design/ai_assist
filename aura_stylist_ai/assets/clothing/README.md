# Real clothing images go here

Drop transparent-background PNG (or WebP) garment cutouts in this folder,
one per item, then set `imagePath` on the matching `ClothingItem` in
`demo_clothing_catalog.dart` (or wherever your real catalog lives), e.g.:

    imagePath: 'assets/clothing/shirt_navy.png',

## Requirements for the image itself
- **Transparent background is mandatory.** A garment photographed on a
  white/colored background will render as a rectangle stuck to the body,
  not a garment. Use a background-removal tool (remove.bg, Photoshop,
  GIMP, etc.) if your source photo isn't already a cutout.
- **Front-facing, roughly symmetric pose** (garment laid flat or on a
  mannequin facing forward) tracks best — side-angle or twisted garment
  photos won't line up well with a front-facing body.
- **Reasonably tight crop** around the garment itself. The image is
  scaled to fill the computed width/height box for that layer, so a lot
  of empty transparent padding around the garment makes it render
  smaller than intended relative to the body.
- Any resolution works; the app decodes and scales it, but keep files
  reasonably sized (under ~1-2MB each) so the try-on overlay doesn't
  stutter the first time an item is selected.

## After adding files
Run `flutter pub get` (only needed if this is a new folder addition to
pubspec.yaml's assets list — already done) and hot restart (not just hot
reload — new asset files need a restart to be picked up by the asset
bundle).
