# Analytics dashboard loading

The dashboard uses content-shaped card placeholders while its analytics
request is loading. A single 1.4-second shimmer animation covers the visible
section, and accessibility semantics report “Loading analytics.” The
animation stops when the platform requests reduced motion.

This follows the [Flutter shimmer recipe](https://docs.flutter.dev/cookbook/effects/shimmer-loading)
and [Flutter rendering guidance](https://docs.flutter.dev/perf/rendering-performance).
[Groww's public web design-system repository](https://github.com/Groww-OSS/webster)
also documents a preloader package. Public engineering details for RentOk,
PhonePe, and Paytm's loading implementations were not found, so the screen
does not claim to reproduce their private code or timing.

The loading treatment is scoped to the Analytics Dashboard screen. The
section tabs remain available while metrics load, and property cards are
requested only for list items built on screen.
