# Graph Report - emsi-chatbot  (2026-11-15)

## Corpus Check
- 46 files · ~22,059 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 52 file(s) not represented in the graph (top: (none) 8, .xcconfig 8, .xml 7)

## Summary
- 292 nodes · 413 edges · 18 communities (11 shown, 7 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 33 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a74b6d88`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Windows Runner Window Plumbing
- agent.py
- my_application.cc
- Agentic Multimodal RAG
- AppDelegate
- Windows App Entry and Utils
- Windows Flutter Embedding
- Flutter Counter Scaffold
- README.md
- main.py
- Web PWA Manifest
- Flutter SDK Dependency
- FlutterActivity

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 21 edges
2. `FlutterWindow` - 10 edges
3. `point_id()` - 8 edges
4. `usable_chunks()` - 7 edges
5. `_MyApplication` - 7 edges
6. `WindowClassRegistrar` - 7 edges
7. `Agentic Multimodal RAG` - 6 edges
8. `search_documents()` - 5 edges
9. `search_images()` - 5 edges
10. `embed_text()` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Flutter Mobile Chat App` --references--> `Mobile Flutter Project Scaffold`  [EXTRACTED]
  README.md → mobile/README.md
- `Dart http Package ^1.6.0` --references--> `api_service.dart (HTTP Client to Backend)`  [INFERRED]
  mobile/pubspec.yaml → README.md
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  mobile/windows/runner/main.cpp → mobile/windows/runner/utils.cpp
- `test_blank_chunks_are_dropped_but_indices_held()` --calls--> `usable_chunks()`  [EXTRACTED]
  backend/tests/test_chunking.py → backend/app/chunking.py
- `test_ids_are_stable_and_distinct()` --calls--> `point_id()`  [EXTRACTED]
  backend/tests/test_chunking.py → backend/app/chunking.py

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Flutter Mobile Project Configuration** — mobile_pubspec_flutter, mobile_pubspec_http, mobile_analysis_options_analyzer_config, mobile_analysis_options_flutter_lints_ruleset, mobile_web_index_flutter_web_shell [EXTRACTED 0.95]
- **Multimodal Indexing and Fusion** — readme_indexing_pipeline, readme_bge_m3, readme_clip, readme_qdrant, readme_reciprocal_rank_fusion [EXTRACTED 0.95]
- **Runtime Question-Answering Flow** — readme_flutter_mobile_app, readme_fastapi_backend, readme_react_agent, readme_qdrant, readme_ollama [EXTRACTED 0.95]

## Communities (18 total, 7 thin omitted)

### Community 0 - "Windows Runner Window Plumbing"
Cohesion: 0.08
Nodes (16): EnableFullDpiSupportIfAvailable(), Point, x, y, Scale(), Size, height, width (+8 more)

### Community 1 - "agent.py"
Cohesion: 0.09
Nodes (15): search_documents(), search_images(), chunk_text(), point_id(), usable_chunks(), embed_image(), embed_text(), embed_text_for_image_search() (+7 more)

### Community 2 - "my_application.cc"
Cohesion: 0.09
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 3 - "Agentic Multimodal RAG"
Cohesion: 0.10
Nodes (27): Dart http Package ^1.6.0, Agentic Multimodal RAG, api_service.dart (HTTP Client to Backend), Audio Input via Whisper (Planned), BGE-M3 Text Embeddings, POST /chat Endpoint, chat_screen.dart Conversational UI, CLIP (ViT-B-32) Image Embeddings (+19 more)

### Community 4 - "AppDelegate"
Cohesion: 0.06
Nodes (13): Cocoa, Flutter, FlutterMacOS, Foundation, AppDelegate, SceneDelegate, RunnerTests, RegisterGeneratedPlugins() (+5 more)

### Community 5 - "Windows App Entry and Utils"
Cohesion: 0.13
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 6 - "Windows Flutter Embedding"
Cohesion: 0.09
Nodes (5): RegisterPlugins(), FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 7 - "Flutter Counter Scaffold"
Cohesion: 0.12
Nodes (10): build, _counter, createState, _incrementCounter, main, MyApp, MyHomePage, _MyHomePageState (+2 more)

### Community 9 - "main.py"
Cohesion: 0.23
Nodes (4): ask(), chat(), ChatRequest, ChatResponse

### Community 10 - "Web PWA Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 11 - "Flutter SDK Dependency"
Cohesion: 0.25
Nodes (8): Dart Analyzer Configuration, flutter_lints Recommend Lint Set, cupertino_icons ^1.0.8, Flutter SDK Dependency, flutter_lints ^6.0.0, Mobile Flutter Project Scaffold, flutter_bootstrap.js Loader, Flutter Web index.html Shell

## Knowledge Gaps
- **31 isolated node(s):** `title`, `_counter`, `main`, `build`, `createState` (+26 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 122 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Windows Runner Window Plumbing` to `Windows App Entry and Utils`, `Windows Flutter Embedding`?**
  _High betweenness centrality (0.032) - this node is a cross-community bridge._
- **What connects `title`, `_counter`, `main` to the rest of the system?**
  _31 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Windows Runner Window Plumbing` be split into smaller, more focused modules?**
  _Cohesion score 0.08140610545790934 - nodes in this community are weakly interconnected._
- **Why does `FlutterWindow` connect `Windows Flutter Embedding` to `Windows Runner Window Plumbing`, `Windows App Entry and Utils`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Should `agent.py` be split into smaller, more focused modules?**
  _Cohesion score 0.0859465737514518 - nodes in this community are weakly interconnected._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.08735632183908046 - nodes in this community are weakly interconnected._
- **Should `Agentic Multimodal RAG` be split into smaller, more focused modules?**
  _Cohesion score 0.09971509971509972 - nodes in this community are weakly interconnected._