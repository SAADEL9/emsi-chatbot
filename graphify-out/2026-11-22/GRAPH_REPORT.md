# Graph Report - emsi-chatbot  (2026-11-22)

## Corpus Check
- 54 files · ~289,170 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 53 file(s) not represented in the graph (top: (none) 8, .xcconfig 8, .xml 7)

## Summary
- 404 nodes · 612 edges · 19 communities (12 shown, 7 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 39 edges (avg confidence: 0.85)
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
- Web PWA Manifest
- main.py
- FlutterActivity
- api_service.dart
- test_agent.py
- widget_test.dart

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 21 edges
2. `LLMUnavailable` - 17 edges
3. `ingest_pdf()` - 11 edges
4. `upload()` - 11 edges
5. `FlutterWindow` - 10 edges
6. `point_id()` - 9 edges
7. `usable_chunks()` - 8 edges
8. `describe_image()` - 8 edges
9. `ingest_image_files()` - 7 edges
10. `ingest_text()` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Dart http Package ^1.6.0` --references--> `api_service.dart (HTTP Client to Backend)`  [INFERRED]
  mobile/pubspec.yaml → README.md
- `Flutter Mobile Chat App` --references--> `Mobile Flutter Project Scaffold`  [EXTRACTED]
  README.md → mobile/README.md
- `ingest_pdf()` --uses--> `LLMUnavailable`  [INFERRED]
  backend/app/ingestion.py → backend/app/errors.py
- `FallbackTest` --uses--> `LLMUnavailable`  [INFERRED]
  backend/tests/test_agent.py → backend/app/errors.py
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  mobile/windows/runner/main.cpp → mobile/windows/runner/utils.cpp

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Flutter Mobile Project Configuration** — mobile_pubspec_flutter, mobile_pubspec_http, mobile_analysis_options_analyzer_config, mobile_analysis_options_flutter_lints_ruleset, mobile_web_index_flutter_web_shell [EXTRACTED 0.95]
- **Multimodal Indexing and Fusion** — readme_indexing_pipeline, readme_bge_m3, readme_clip, readme_qdrant, readme_reciprocal_rank_fusion [EXTRACTED 0.95]
- **Runtime Question-Answering Flow** — readme_flutter_mobile_app, readme_fastapi_backend, readme_react_agent, readme_qdrant, readme_ollama [EXTRACTED 0.95]

## Communities (19 total, 7 thin omitted)

### Community 0 - "win32_window.cpp"
Cohesion: 0.08
Nodes (16): EnableFullDpiSupportIfAvailable(), Point, x, y, Scale(), Size, height, width (+8 more)

### Community 1 - "ingestion.py"
Cohesion: 0.07
Nodes (19): search_documents(), search_images(), chunk_text(), point_id(), usable_chunks(), embed_image(), embed_text(), embed_text_for_image_search() (+11 more)

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
Cohesion: 0.09
Nodes (5): RegisterPlugins(), FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 7 - "chat_screen.dart"
Cohesion: 0.06
Nodes (25): build, EmsiChatBotApp, main, _seed, _theme, _addMessage, _Bubble, build (+17 more)

### Community 10 - "Web PWA Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 11 - "main.py"
Cohesion: 0.09
Nodes (10): ask(), LLMUnavailable, chat(), _free_path(), health(), upload(), ChatRequest, ChatResponse (+2 more)

### Community 14 - "api_service.dart"
Cohesion: 0.20
Nodes (5): ApiService, _detail, maxUploadBytes, _overrideUrl, uploadFile

### Community 15 - "test_agent.py"
Cohesion: 0.07
Nodes (11): _image_urls(), _Agent, FallbackTest, ImageUrlsTest, _Message, _ImageFile, _Page, PdfIngestionTest (+3 more)

## Knowledge Gaps
- **51 isolated node(s):** `_seed`, `main`, `build`, `_theme`, `_Message` (+46 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 180 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `LLMUnavailable` connect `main.py` to `ingestion.py`, `test_agent.py`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `LLMUnavailable` (e.g. with `ingest_pdf()` and `chat()`) actually correct?**
  _`LLMUnavailable` has 5 INFERRED edges - model-reasoned connections that need verification._
- **What connects `_seed`, `main`, `build` to the rest of the system?**
  _51 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `win32_window.cpp` be split into smaller, more focused modules?**
  _Cohesion score 0.08140610545790934 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `win32_window.cpp` to `Windows App Entry and Utils`, `FlutterWindow`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Should `ingestion.py` be split into smaller, more focused modules?**
  _Cohesion score 0.06708595387840671 - nodes in this community are weakly interconnected._
- **Why does `FlutterWindow` connect `FlutterWindow` to `win32_window.cpp`, `Windows App Entry and Utils`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._