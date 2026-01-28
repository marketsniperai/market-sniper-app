# Performance Note
**Feature:** HF24 — Time-Traveller Chart v1

## Observations
- **Animation:** `AnimationController` runs a 2-second repeat loop.
- **Painting:** CustomPainter uses efficient `drawRect` and `drawLine`.
- **Optimization:** `CustomPaint` is wrapped in `AnimatedBuilder` to target updates only to the chart area, not the entire panel.
- **Memory:** `ChartCandle` is a lightweight object. Lists are generally small (<50 items for intraday).
- **Jank Risk:** Low. Logic is O(N) where N is number of candles (small).

## Conclusion
Implementation is lightweight and performant.
