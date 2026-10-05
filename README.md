# mac-display-align

Aligns two side-by-side Mac displays by eye. macOS only lets you drag displays in System Settings, which makes it hard to line up the edges of two screens of different sizes.

## Install

Download `DisplayAlign.zip` from the [latest release](https://github.com/sanderland/mac-display-align/releases/latest), unzip, and open `DisplayAlign.app`. Requires macOS 13 or later (Apple Silicon and Intel).

The app is ad-hoc signed, not notarized, so Gatekeeper blocks the first launch. Right-click the app and choose Open, or run `xattr -dr com.apple.quarantine DisplayAlign.app`.

To build from source, run `./build.sh`. The app lands in `dist/`.

## Use

1. Click a point on the edge of one display (e.g. a ruler mark or a window corner). A line and dot appear.
2. Click the point next to it on the neighbouring display.
3. Up/Down move the line on the first display (Shift = 10 px) until both lines meet across the bezel.
4. Return moves the second display so both lines share the same y, snaps it flush against the first, and saves the layout. Esc cancels.

No accessibility permission is needed.
