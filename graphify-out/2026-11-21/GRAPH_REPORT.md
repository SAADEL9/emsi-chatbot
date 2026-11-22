# Graph Report - emsi-chatbot  (2026-11-21)

## Corpus Check
- 52 files · ~288,497 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 53 file(s) not represented in the graph (top: (none) 8, .xcconfig 8, .xml 7)

## Summary
- 386 nodes · 557 edges · 19 communities (12 shown, 7 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 34 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `db3bf16c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- win32_window.cpp
- ingestion.py
- my_application.cc
- Agentic Multimodal RAG
- AppDelegate
- Windows App Entry and Utils
- FlutterWindow
- chat_screen.dart
- README.md
- agent.py
- Web PWA Manifest
- FlutterActivity
- api_service.dart
- test_ingestion.py
- widget_test.dart

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 21 edges
2. `upload()` - 10 edges
3. `FlutterWindow` - 10 edges
4. `point_id()` - 9 edges
5. `ingest_pdf()` - 9 edges
6. `usable_chunks()` - 8 edges
7. `ingest_image_files()` - 7 edges
8. `ingest_text()` - 7 edges
9. `describe_image()` - 7 edges
10. `_MyApplication` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Dart http Package ^1.6.0` --references--> `api_service.dart (HTTP Client to Backend)`  [INFERRED]
  mobile/pubspec.yaml → README.md
- `Flutter Mobile Chat App` --references--> `Mobile Flutter Project Scaffold`  [EXTRACTED]
  README.md → mobile/README.md
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  mobile/windows/runner/main.cpp → mobile/windows/runner/utils.cpp
- `search_documents()` --calls--> `embed_text()`  [EXTRACTED]
  backend/app/agent.py → backend/app/embeddings.py
- `chat()` --calls--> `ask()`  [EXTRACTED]
  backend/app/main.py → backend/app/agent.py

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Flutter Mobile Project Configuration** — mobile_pubspec_flutter, mobile_pubspec_http, mobile_analysis_options_analyzer_config, mobile_analysis_options_flutter_lints_ruleset, mobile_web_index_flutter_web_shell [EXTRACTED 0.95]
- **Multimodal Indexing and Fusion** — readme_indexing_pipeline, readme_bge_m3, readme_clip, readme_qdrant, readme_reciprocal_rank_fusion [EXTRACTED 0.95]
- **Runtime Question-Answering Flow** — readme_flutter_mobile_app, readme_fastapi_backend, readme_react_agent, readme_qdrant, readme_ollama [EXTRACTED 0.95]

## Communities (19 total, 7 thin omitted)

### Community 0 - "win32_window.cpp"
Cohesion: 0.07
Nodes (17): RegisterPlugins(), EnableFullDpiSupportIfAvailable(), Point, x, y, Scale(), Size, height (+9 more)

### Community 1 - "ingestion.py"
Cohesion: 0.06
Nodes (22): chunk_text(), point_id(), usable_chunks(), embed_image(), embed_text(), ingest_image_files(), ingest_images(), ingest_pdf() (+14 more)

### Community 2 - "my_application.cc"
Cohesion: 0.09
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 3 - "Agentic Multimodal RAG"
Cohesion: 0.07
Nodes (35): Dart Analyzer Configuration, flutter_lints Recommend Lint Set, cupertino_icons ^1.0.8, Flutter SDK Dependency, flutter_lints ^6.0.0, Dart http Package ^1.6.0, Mobile Flutter Project Scaffold, flutter_bootstrap.js Loader (+27 more)

### Community 4 - "AppDelegate"
Cohesion: 0.06
Nodes (14): Cocoa, file_picker_darwin, Flutter, FlutterMacOS, Foundation, AppDelegate, SceneDelegate, RunnerTests (+6 more)

### Community 5 - "Windows App Entry and Utils"
Cohesion: 0.13
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 6 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 7 - "chat_screen.dart"
Cohesion: 0.06
Nodes (25): build, EmsiChatBotApp, main, _seed, _theme, _addMessage, _Bubble, build (+17 more)

### Community 9 - "agent.py"
Cohesion: 0.12
Nodes (8): ask(), _image_urls(), search_documents(), search_images(), embed_text_for_image_search(), search(), ImageUrlsTest, _Message

### Community 10 - "Web PWA Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 14 - "api_service.dart"
Cohesion: 0.20
Nodes (5): ApiService, _detail, maxUploadBytes, _overrideUrl, uploadFile

### Community 15 - "test_ingestion.py"
Cohesion: 0.10
Nodes (5): ChatResponseTest, _ImageFile, _Page, PdfIngestionTest, _Reader

## Knowledge Gaps
- **51 isolated node(s):** `_seed`, `main`, `build`, `_theme`, `_Message` (+46 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 177 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `win32_window.cpp` to `Windows App Entry and Utils`, `FlutterWindow`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **What connects `_seed`, `main`, `build` to the rest of the system?**
  _51 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `win32_window.cpp` be split into smaller, more focused modules?**
  _Cohesion score 0.07294117647058823 - nodes in this community are weakly interconnected._
- **Why does `FlutterWindow` connect `FlutterWindow` to `win32_window.cpp`, `Windows App Entry and Utils`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **Should `ingestion.py` be split into smaller, more focused modules?**
  _Cohesion score 0.05952380952380952 - nodes in this community are weakly interconnected._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.08735632183908046 - nodes in this community are weakly interconnected._
- **Should `Agentic Multimodal RAG` be split into smaller, more focused modules?**
  _Cohesion score 0.07226890756302522 - nodes in this community are weakly interconnected._