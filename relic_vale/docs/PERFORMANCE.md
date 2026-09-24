# Performance measurements — Windows 10 acceptance PC

Relic Vale 0.10.0, Godot 4.7.2 stable x64 Release template, Compatibility/OpenGL renderer, Windows 10 Enterprise 22H2 (19045), Ryzen 3 3200G, Radeon Vega 8, approximately 14 GB RAM. Measurements used a 1280×720 window, VSync off, seed 20260907, 120 warm-up frames and 5 seconds of wall-clock frame samples per scenario (8 seconds for travel). The benchmark runs inside a QA-instrumented Release export with the same game systems but extra test scripts; the distributable PCK itself has no benchmark code.

| Scenario, Medium unless stated | FPS | 95th percentile frame | Largest frame | Draw calls / frame |
| --- | ---: | ---: | ---: | ---: |
| A — starting village | 88.0 | 15.2 ms | 66.6 ms | 1242 |
| B — procedural forest | 100.5 | 11.6 ms | 15.0 ms | 853 |
| C — developed camp | 69.2 | 17.9 ms | 21.1 ms | 759 |
| D — procedural settlement | 82.6 | 14.7 ms | 50.0 ms | 908 |
| E — twelve nearby enemies | 68.9 | 18.6 ms | 40.0 ms | 1339 |
| F — guardian encounter | 100.4 | 13.7 ms | 40.9 ms | 461 |
| G — storm | 76.8 | 17.2 ms | 39.8 ms | 1263 |
| H — 20 m/s simulated streaming while storm remains active | 59.6 | 28.1 ms | 303.2 ms | 1175 |

I — teleport/loading to logical addresses (1000,1000), (10000,-10000), and home took 3258 ms, 2868 ms and 3010 ms respectively. The high-speed H run moves the player programmatically through streaming chunks; it is not a claim that a player can ride at exactly 20 m/s. In a separate 8-second input-driven horse run, `mounted=true` throughout the measured sample, the character covered 86.6 m, FPS averaged 137.3, p95 was 9.5 ms, and the worst streaming frame was 107.2 ms. Its scene density was different from the storm travel run, so their FPS values are not directly comparable.

A separate clear-weather starting-village pass changed only the graphics preset, with the same 1280×720 window and 5-second samples: Minimal 103.7 FPS / 11.2 ms p95, Medium 86.0 / 16.2, High 58.4 / 24.1, Ultra 41.8 / 28.5. This demonstrates meaningful scalability on the tested integrated GPU. It does not establish targets for other machines.

The 15-minute unattended game session completed without script errors or warnings. It recorded 37 twenty-second village samples after the A–I and preset passes. The external Windows process monitor sampled every 10 seconds. After 300 seconds, working set stayed between 952 and 961 MiB while nodes stayed near 14,600 (first long-session sample 14,622, final 14,662). The initial rise from roughly 393 MiB reflects asset/cache warm-up and preset changes; it did not continue growing during the steady portion. The separate streaming stress test traversed 1010 unique chunks with 25 floating-origin shifts; final Godot static memory was 350 MB and zero orphan nodes after return to the village. A bounded map cache held at 512 tiles.

Profiling had shown synchronous map tile rasterization up to 52.8 ms on the main thread. The new worker raster and main-thread upload path measured a maximum main-thread tile step of 1.16 ms in the final run. Shadow distance was brought within fog visibility, repeated whole-scene particle scans were removed in Release, and terrain collision uses worker-produced vertices rather than reading mesh data back. Exploratory fixed-speed H captures before/after these changes showed 2049/1115 average draw calls and 29.4/19.0 ms p95, but those runs were not isolated from all concurrent work and are not used as a controlled FPS improvement claim.

The main remaining performance issue is the occasional long streaming frame (303 ms maximum in the measured H pass). The Radeon Vega 8 results are only for this PC; no universal FPS target is certified. Engine GPU frame timing was unavailable in this Compatibility capture, and the `Performance.TIME_PROCESS` monitor is not a Windows CPU-utilization percentage. The table uses measured wall-clock frame time; OS working-set samples provide process-memory evidence.

Raw data: `downloads/phase10/final-soak-performance.json`, `final-soak-performance.log`, `final-soak-process.json`, `mount-performance.json`, `preset-performance.json`, `profile-before.json`, `profile-after-map.json`, and `relic_vale/docs/PHASE_10_STRESS_TESTS.json`.
