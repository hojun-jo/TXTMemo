# macOS 메모장 앱 아키텍처 설계

## 1. 목적

이 문서는 [macos-notepad-mvp-plan.md](./macos-notepad-mvp-plan.md), [seed.md](./seed.md), 그리고 `features/` 아래의 기능 문서를 구현 관점으로 구체화한 기술 아키텍처 문서다. 목표는 아래 7가지를 명확히 고정하는 것이다.

- 어떤 macOS API 조합으로 `Windows 메모장형 문서 앱` 동작을 만들지 결정한다.
- `문서 파일 상태`와 `창별 보기 상태`를 어디서 분리할지 정의한다.
- 앱 시작, 새 문서, Finder 파일 열기, 저장, 종료, 앱 종료의 제어 흐름을 고정한다.
- plain text 편집기에서 IME, undo/redo, wrap 토글, 글자 크기 조절을 어떤 컴포넌트로 처리할지 정한다.
- 닫기 시 4개 액션을 가진 커스텀 확인 플로우를 어디서 제어할지 정한다.
- MVP 범위에 맞는 최소 추상화와 폴더 구조를 제안한다.
- 구현 순서와 테스트 경계를 함께 제시한다.

이 문서는 제품 범위를 새로 정의하지 않는다. 기능 요구사항은 아래 문서를 따른다.

- [macos-notepad-mvp-plan.md](./macos-notepad-mvp-plan.md)
- [features/feature-01-instant-note-entry.md](./features/feature-01-instant-note-entry.md)
- [features/feature-02-text-size-control.md](./features/feature-02-text-size-control.md)
- [features/feature-03-txt-save.md](./features/feature-03-txt-save.md)
- [features/feature-04-close-confirmation.md](./features/feature-04-close-confirmation.md)
- [features/feature-05-undo-redo.md](./features/feature-05-undo-redo.md)
- [features/feature-06-auto-word-wrap.md](./features/feature-06-auto-word-wrap.md)

## 2. 아키텍처를 결정하는 핵심 제약

이 프로젝트는 단순한 SwiftUI 텍스트 입력 화면이 아니라 `문서형 macOS 앱`이다. 아래 요구사항이 구조를 사실상 결정한다.

- 앱을 실행하면 최근 문서 선택 화면 없이 빈 문서 창 1개가 즉시 열려야 한다.
- 새 문서와 기존 `.txt` 파일은 모두 `창 하나 = 문서 세션 하나` 원칙으로 독립 창에서 열려야 한다.
- Finder에서 파일을 열어도 동일한 문서 모델과 저장 규칙을 타야 한다.
- 저장은 `.txt` 고정이고, 새 문서는 첫 저장 시에만 경로를 묻는다.
- `저장`, `다른 이름으로 저장`, `취소`, `저장하지 않고 종료`의 4개 액션이 있는 종료 확인 UI가 필요하다.
- 공백, 탭, 줄바꿈만 있는 문서는 미저장 변경이 있어도 확인 없이 즉시 닫혀야 한다.
- 현재 창의 글자 크기와 wrap 상태는 문서 내용이 아니라 `창별 세션 상태`여야 한다.
- 앱 기본 글자 크기는 앱 설정에 저장되지만, 현재 창의 임시 크기는 파일이나 세션 복원 정보로 저장되면 안 된다.
- undo/redo, IME, plain text 붙여넣기, no-wrap 수평 스크롤은 실제 편집기 품질을 좌우한다.
- 세션 복원, 최근 문서 대시보드, autosave-in-place, rich text는 MVP 밖이다.

이 제약 때문에 `순수 SwiftUI TextEditor 중심 구조`보다는 `순수 AppKit 문서 앱 구조`가 더 적합하다.

## 3. 권장 기술 선택

아래 조합이 현재 MVP에 가장 안정적이다.

| 영역              | 권장 선택                                                         | 이유                                                                                                      |
| ----------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 앱 진입점         | `@main` + `NSApplicationDelegate`                                 | 앱 시작, 무창 재활성화, 앱 종료 orchestration을 AppKit 한 곳에서 제어할 수 있다.                          |
| 문서 라이프사이클 | `NSDocument`, `NSDocumentController`, 커스텀 `NSWindowController` | Finder 열기, 새 문서, 파일 URL, 저장, 창 제목, 창별 문서 독립성을 macOS 방식으로 다루기 가장 쉽다.        |
| 텍스트 편집기     | `NSTextView` + `NSScrollView`                                     | IME, undo/redo, plain text 모드, wrap on/off, 수평 스크롤, first responder 제어까지 가장 성숙한 선택이다. |
| 화면 구성         | 커스텀 `NSViewController` + AppKit 뷰 계층                        | responder chain, 툴바, first responder, sheet 소유권을 브리지 없이 직접 제어할 수 있다.                   |
| 툴바              | `NSToolbar`                                                       | `저장`, `A-`, 현재 pt 입력 필드, `A+`, wrap 토글을 현재 창 기준으로 정교하게 검증하고 연결하기 쉽다.      |
| 설정 저장         | `UserDefaults` 래퍼 `SettingsStore`                               | 기본 글자 크기처럼 작은 앱 전역 설정 저장에 충분하고 AppKit 설정 창과도 자연스럽게 연결된다.              |
| 파일 입출력       | Foundation `String` / `Data` 기반 `TextFileCodec`                 | `.txt` UTF-8 저장 정책을 명확하게 고정할 수 있다.                                                         |
| 오류 피드백       | 단순 `NSAlert`                                                    | 저장 실패는 MVP에서 복잡한 오류 상태 UI보다 단순 alert가 적합하다.                                        |
| 종료 확인 UI      | 커스텀 sheet + `CloseWorkflowCoordinator`                         | 기본 3버튼 경고창으로는 4개 액션을 자연스럽게 담기 어렵다.                                                |

## 4. 이번 설계에서 의도적으로 선택하지 않는 것

- `DocumentGroup` + `FileDocument`: 파일 열기와 저장은 쉽지만, 4버튼 종료 플로우, empty-close 규칙, no-wrap 편집기 제어, active-window command 제어가 거칠어질 가능성이 크다.
- 순수 `TextEditor`: no-wrap과 수평 스크롤, first responder 포커스, IME/undo 세부 제어에서 제약이 크다.
- SwiftUI 셸 또는 `NSHostingController` 브리지: 이 앱에서는 설정 창 외 대부분의 핵심 동작이 AppKit에 남기 때문에, 포커스와 responder chain만 복잡하게 만들 가능성이 크다.
- SwiftData, Core Data, SQLite: 앱의 영속 데이터는 문서 파일과 작은 앱 설정뿐이다. DB 계층은 과하다.
- 무거운 Clean Architecture 템플릿: 프로젝트 규모에 비해 파일 수와 추상화가 불필요하게 늘어난다.
- autosave-in-place와 Versions: Windows 메모장형 명시적 저장 흐름과 충돌한다.
- 세션 복원과 최근 문서 복원: MVP의 `실행 즉시 빈 문서 1개` 경험을 흐린다.

## 5. 권장 아키텍처 스타일

권장 스타일은 `가벼운 문서형 아키텍처 + 순수 AppKit UI/편집기`다.

핵심 원칙은 아래 5가지다.

- 문서 파일 상태와 창별 보기 상태를 분리한다.
- macOS의 문서/창/메뉴 responder chain을 억지로 우회하지 않는다.
- 텍스트 편집은 `NSTextView`에 맡기고, 비즈니스 규칙만 별도 coordinator로 분리한다.
- 기능별 순수 규칙은 작은 policy 또는 engine으로 빼서 테스트 가능하게 만든다.
- UI 계층은 가볍게 유지하되, 종료/저장처럼 실패 비용이 큰 흐름은 coordinator가 명시적으로 관리한다.

전체 구조는 아래처럼 본다.

```text
NSApplicationMain
  -> AppDelegate / AppTerminationCoordinator
  -> NSDocumentController
    -> NotepadDocument
      -> DocumentWindowController
        -> DocumentWindowViewController
          -> EditorSessionController
          -> NotepadTextView + NSScrollView

DocumentWindow actions
  -> responder chain or toolbar action
  -> DocumentWindowViewController / EditorSessionController / NotepadDocument / CloseWorkflowCoordinator
  -> TextFileCodec / SettingsStore / AlertPresenter
```

## 6. 계층 구조

### 6.1 App Layer

책임:

- 앱 부팅
- AppDelegate 초기화
- 앱 메뉴와 설정 창 등록
- 정상 실행 시 빈 문서 자동 생성
- 앱 종료 시 창 순차 종료 orchestration 시작

포함 요소:

- `main.swift` 또는 `@main AppDelegate`
- `AppDelegate`
- `AppTerminationCoordinator`
- `PreferencesWindowController`

### 6.2 Document Lifecycle Layer

책임:

- 새 문서 생성
- Finder 또는 파일 열기 연동
- 문서별 파일 URL 보관
- 저장/다른 이름으로 저장 진입점 제공
- window-controller 생성
- 제목 갱신과 dirty 상태 반영

포함 요소:

- `NotepadDocumentController`
- `NotepadDocument`
- `DocumentWindowController`
- `WindowTitleFormatter`
- `UntitledNameAllocator`

### 6.3 Editor Layer

책임:

- plain text 입력
- undo/redo
- IME 조합 안정성
- wrap on/off
- 글자 크기 반영
- 현재 창 포커스와 선택 상태 유지

포함 요소:

- `DocumentWindowViewController`
- `NotepadTextView`
- `EditorSessionController`
- `WrapLayoutController`

### 6.4 Workflow / Policy Layer

책임:

- 닫기 판정 규칙
- 저장 분기 규칙
- 글자 크기 clamp 규칙
- 메뉴/툴바 액션이 현재 창에만 적용되도록 연결

포함 요소:

- `CloseDecisionEngine`
- `CloseWorkflowCoordinator`
- `DocumentSaveCoordinator`
- `FontSizePolicy`
- `MenuActionValidator`

### 6.5 Infrastructure Layer

책임:

- 파일 읽기/쓰기
- 저장 패널 및 열기 패널 연동
- 오류 alert 표시
- UserDefaults 기반 설정 저장

포함 요소:

- `TextFileCodec`
- `SavePanelService`
- `OpenPanelService`가 필요하면 최소 래퍼만 제공
- `AlertPresenter`
- `SettingsStore`

## 7. 상태 모델과 경계

이 앱에서 가장 중요한 설계는 `무엇이 파일에 저장되는지`와 `무엇이 창 세션에만 머무는지`를 분리하는 것이다.

### 7.1 영속 문서 상태

문서 파일 또는 문서 객체가 책임지는 상태:

- `fileURL: URL?`
- `text: String`
- `lastSavedText: String`
- `untitledDisplayIndex: Int?`
- `lastSaveEncoding: String.Encoding`

설명:

- `text`는 현재 문서의 canonical plain text다.
- `lastSavedText`는 저장 성공 시점의 스냅샷이다.
- dirty 여부는 가능하면 `NSDocument` change count와 동기화하되, 비교 기준으로 `lastSavedText`도 유지한다.
- `untitledDisplayIndex`는 저장 전 창 제목 구분용이다.
- 인코딩은 저장 시 UTF-8로 고정하되, 읽기 시 감지 결과를 내부적으로 참고할 수 있다.

### 7.2 창 세션 상태

현재 창이 닫히면 사라지는 상태:

- `windowID: UUID`
- `fontSize: Int`
- `wrapEnabled: Bool`
- `isEditorFocused: Bool`
- `isCloseSheetPresented: Bool`
- `pendingCloseIntent: CloseIntent?`
- `toolbarFontFieldValue: String`
- `isIMEComposing: Bool`

설명:

- 글자 크기와 wrap은 문서 내용이 아니라 보기 상태다.
- 이미 열린 다른 창과 동기화하지 않는다.
- 파일 저장, 재실행, 재오픈 시 이 값은 복원하지 않는다.

### 7.3 앱 전역 설정 상태

앱 종료 후에도 유지되는 작은 설정 상태:

- `defaultFontSize: Int`

초기값과 규칙:

- 초기값은 14pt
- 최소 8pt, 최대 72pt
- 현재 창의 임시 글자 크기 변경은 이 값을 자동으로 바꾸지 않는다.

### 7.4 파생 상태 규칙

아래 파생 규칙을 코드로도 명확히 유지하는 것이 중요하다.

```text
trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
isLogicallyEmpty = trimmedText.isEmpty
hasUnsavedChanges = document.isDocumentEdited || text != lastSavedText
shouldPromptOnClose = !isLogicallyEmpty && hasUnsavedChanges
displayTitle = fileURL?.lastPathComponent ?? untitledName
windowTitle = hasUnsavedChanges ? "\(displayTitle) *" : displayTitle
```

주의점:

- `isLogicallyEmpty`가 `true`이면 미저장 변경이 있어도 종료 확인을 띄우지 않는다.
- wrap 토글과 글자 크기 변경은 `hasUnsavedChanges`를 바꾸면 안 된다.
- undo/redo 결과로 `text == lastSavedText`가 되면 dirty 상태도 해제돼야 한다.

## 8. 핵심 컴포넌트 설계

### 8.1 `AppEntryPoint`

역할:

- AppKit 앱 진입점
- `AppDelegate` 연결
- 메인 메뉴와 설정 창 진입점 등록
- 문서 윈도우 생성을 `NSDocumentController`에 위임

핵심 결정:

- 앱 전체를 AppKit responder chain 안에서 유지한다.
- 앱 초기화와 설정 창 노출도 AppKit 윈도우 컨트롤러로 처리한다.

### 8.2 `AppDelegate`

역할:

- 정상 앱 시작 시 빈 문서 1개 생성
- 앱이 무창 상태로 재활성화될 때 새 빈 문서 재생성
- 앱 종료 시 `AppTerminationCoordinator` 시작

핵심 규칙:

- Finder 파일 열기 이벤트가 먼저 들어온 경우에는 추가 빈 문서를 중복 생성하지 않는다.
- 마지막 창이 닫힌 뒤 앱이 살아 있는 상태에서 다시 활성화되면 새 빈 문서를 연다.
- 상태 복원과 이전 창 재오픈에 의존하지 않는다.

### 8.3 `NotepadDocumentController`

역할:

- `NSDocumentController` 커스터마이즈
- untitled 이름 관리
- 문서 생성과 파일 열기 정책 통합

구체 책임:

- `Untitled`, `Untitled 2`, `Untitled 3` 규칙으로 새 문서 기본 이름 부여
- `openUntitledDocumentAndDisplay` 기반 새 문서 생성
- Finder 또는 파일 열기에서 `.txt` 문서를 별도 문서 인스턴스로 연다.
- 필요 시 `Open Recent` 같은 문서형 앱 기본 메뉴를 축소해 제품 범위를 넘지 않게 한다.

### 8.4 `NotepadDocument`

역할:

- 문서 canonical state 소유
- 파일 읽기/쓰기 수행
- 저장 성공 시 dirty 상태 정리
- 자신만의 window controller 생성

핵심 구현 원칙:

- `autosavesInPlace`는 `false`로 둔다.
- 텍스트 변경은 editor callback을 통해 문서로 반영한다.
- 변경 시 `updateChangeCount(.changeDone)`를 호출해 macOS 문서 dirty 상태와 동기화한다.
- 저장 성공 시 `lastSavedText = text`로 갱신하고 dirty 상태를 정리한다.
- 새 문서는 `fileURL == nil` 상태로 시작한다.

읽기/쓰기 정책:

- 읽기: plain text만 허용한다.
- 쓰기: UTF-8 without BOM으로 저장한다.
- 사용자가 다른 확장자를 입력해도 최종 파일명은 `.txt`로 정규화한다.

### 8.5 `DocumentWindowController`

역할:

- 창 하나의 라이프사이클 제어
- 현재 문서와 현재 창 세션 연결
- 툴바 구성
- 제목 갱신
- 창 닫기 인터셉트

구체 책임:

- `EditorSessionController` 생성 및 보유
- `windowShouldClose` 또는 동등한 경로에서 `CloseWorkflowCoordinator` 호출
- 현재 창이 key window가 될 때 메뉴/툴바 상태 갱신
- 창 제목을 `파일명 + *` 규칙으로 갱신
- 생성 직후 편집기로 first responder 포커스를 보낸다.

권장 구현:

- content view는 `DocumentWindowViewController`의 루트 `NSView`
- 툴바는 `NSToolbar`로 구성해 저장 버튼, 현재 pt 입력 필드, wrap 토글을 현재 창 기준으로 직접 제어

### 8.6 `EditorSessionController`

역할:

- 현재 창 전용 보기 상태 관리
- 글자 크기 액션과 wrap 토글 액션 처리
- 툴바 값과 실제 편집기 상태 동기화

필수 메서드 예시:

- `increaseFontSize()`
- `decreaseFontSize()`
- `resetFontSizeToDefault()`
- `commitFontSizeInput(_:)`
- `setWrapEnabled(_:)`
- `applySessionStateToEditor()`

핵심 규칙:

- 값 변경은 현재 창에만 반영한다.
- 최소/최대 범위는 `FontSizePolicy`로 clamp 한다.
- 앱 기본 글자 크기는 `SettingsStore`에서 읽되, 창 임시 크기 변경은 곧바로 저장하지 않는다.

### 8.7 `DocumentWindowViewController`와 `NotepadTextView`

역할:

- 편집기, 스크롤 뷰, 종료 sheet 진입점을 포함한 문서 창 본문 UI를 구성
- plain text 입력과 selection/IME/undo를 실제로 담당

핵심 설정:

- `isRichText = false`
- `importsGraphics = false`
- `usesFindBar = false`
- `isAutomaticQuoteSubstitutionEnabled = false` 여부는 MVP에서 팀이 결정하되, 기본 텍스트 무결성을 해치지 않는 쪽을 우선한다.
- paste는 rich text가 들어와도 plain text만 남도록 처리한다.

wrap 제어 방식:

- `wrapEnabled == true`:
  - `textContainer.widthTracksTextView = true`
  - 수평 스크롤 비활성화
- `wrapEnabled == false`:
  - `textContainer.widthTracksTextView = false`
  - `textContainer.containerSize.width = .greatestFiniteMagnitude`
  - `isHorizontallyResizable = true`
  - `enclosingScrollView.hasHorizontalScroller = true`

이 선택이 중요한 이유:

- 순수 AppKit이면 bridge 계층 없이 responder chain과 first responder를 직접 다룰 수 있다.
- `NSTextView`는 undo manager와 IME 처리에서 기본 품질이 높다.

### 8.8 `PreferencesWindowController`

역할:

- 앱 전역 기본 글자 크기 설정 창 제공
- 현재 저장된 기본 글자 크기 로드와 저장
- 입력값 검증 후 `SettingsStore`에 반영

구체 책임:

- 단일 설정 창 재사용
- 8~72 범위 검증
- 손상값 복구 시 14pt를 표시

권장 구현:

- `NSWindowController` + `NSViewController`
- 숫자 입력 필드와 저장 버튼 중심의 최소 UI

### 8.9 `CloseDecisionEngine`

역할:

- 종료 여부 자체를 순수 규칙으로 판단

입력:

- `text`
- `hasUnsavedChanges`
- `closeIntent` (`windowClose`, `applicationQuit`)

출력:

- `.closeImmediately`
- `.promptUser`

규칙:

- `trimmed(text).isEmpty == true` 이면 즉시 종료
- `hasUnsavedChanges == false` 이면 즉시 종료
- 그 외에는 종료 확인 sheet 표시

이 엔진은 UI와 파일 저장을 몰라도 되어야 한다. 그래야 단위 테스트가 쉽다.

### 8.10 `CloseWorkflowCoordinator`

역할:

- 종료 확인 UI 표시
- `저장`, `다른 이름으로 저장`, `취소`, `저장하지 않고 종료` 분기 처리
- 저장 취소 또는 저장 실패 시 편집 상태 복귀

구체 책임:

- 현재 창 닫기와 앱 전체 종료 모두 같은 종료 규칙을 재사용
- 현재 창 종료 시: 해당 창만 처리
- 앱 종료 시: 포커스된 창부터 시작해 순차 처리
- 저장 실패 시 alert 표시 후 종료 중단
- 같은 창에 종료 UI가 떠 있는 동안 중복 종료 요청 무시

### 8.11 `AppTerminationCoordinator`

역할:

- 앱 종료 시 여러 창을 순차로 닫는 오케스트레이션

권장 흐름:

1. `applicationShouldTerminate`에서 `.terminateLater`
2. 현재 key window부터 문서 창 목록 정렬
3. 각 창마다 `CloseWorkflowCoordinator` 실행
4. 창이 즉시 닫혀도 되고, 저장 후 닫혀도 되고, 저장 없이 닫혀도 된다.
5. 어느 한 창에서 `취소` 또는 저장 실패가 발생하면 남은 종료 절차를 중단한다.
6. 성공이면 `NSApp.reply(toApplicationShouldTerminate: true)`
7. 중단이면 `NSApp.reply(toApplicationShouldTerminate: false)`

주의점:

- 이미 닫힌 창은 취소 시 되살리지 않는다.
- 한 번에 여러 종료 확인 UI를 띄우지 않는다.

### 8.12 `TextFileCodec`

역할:

- 파일 읽기/쓰기 정책을 한 곳에 고정

권장 정책:

- 읽기:
  - UTF-8 우선
  - 필요 시 Foundation의 인코딩 감지를 보조적으로 사용
  - plain text로 해석할 수 없으면 오류 반환
- 쓰기:
  - 항상 UTF-8 without BOM
  - 내부 문자열은 그대로 저장하되 파일명은 `.txt` 정규화

MVP 결정:

- 줄바꿈은 메모리에서 `\n`로 다룬다.
- 저장 시 기존 줄바꿈 스타일 보존 로직은 두지 않는다.
- 줄바꿈 스타일 보존이 필요해지면 이후 `lineEndingStyle` 필드를 도입한다.

### 8.13 `SettingsStore`

역할:

- 앱 기본 글자 크기 읽기/쓰기

권장 API:

- `loadDefaultFontSize() -> Int`
- `saveDefaultFontSize(_ value: Int)`

규칙:

- 저장 시 8~72 범위로 clamp
- 손상값이면 14로 복구
- 이미 열린 창은 설정 변경 시 자동 동기화하지 않는다.

## 9. 뷰와 상태의 결합 방식

이 앱에서 state ownership은 아래처럼 고정하는 편이 가장 단순하다.

| 상태                           | 소유자                                                         | 비고                 |
| ------------------------------ | -------------------------------------------------------------- | -------------------- |
| 문서 텍스트                    | `NotepadDocument`                                              | canonical plain text |
| undo/redo 실제 기록            | `NSTextView`의 undo manager                                    | responder chain 사용 |
| 현재 창 글자 크기              | `EditorSessionController`                                      | 세션성 상태          |
| 현재 창 wrap 여부              | `EditorSessionController`                                      | 세션성 상태          |
| 앱 기본 글자 크기              | `SettingsStore`                                                | 앱 전역 설정         |
| 저장 패널/종료 sheet 표시 상태 | `CloseWorkflowCoordinator` 또는 `DocumentWindowViewController` | 창별 제어            |
| dirty 표시와 제목 갱신         | `NotepadDocument` + `DocumentWindowController`                 | 문서와 창 협력       |

중요 원칙:

- `NSTextView`가 편집을 수행하더라도 canonical state는 문서 객체에 반영되어야 한다.
- 창 세션 상태는 문서에 저장하지 않는다.
- 저장/종료 판정은 항상 문서 상태를 기준으로 하고, wrap/글자 크기는 관여하지 않는다.

## 10. 주요 사용자 흐름의 제어 구조

### 10.1 앱 실행

1. 앱 프로세스 시작
2. `AppDelegate` 초기화
3. Finder open event가 선행되지 않았다면 `NotepadDocumentController`가 빈 문서 1개 생성
4. `NotepadDocument` 생성
5. `DocumentWindowController` 생성
6. `EditorSessionController.fontSize = SettingsStore.defaultFontSize`
7. `wrapEnabled = true`
8. 창 표시 후 `NSTextView`를 first responder로 지정

### 10.2 새 문서 열기

1. 사용자 `Command+N`
2. responder chain이 `NSDocumentController` 새 문서 액션 호출
3. 새 `NotepadDocument`와 새 창 생성
4. 독립 세션 상태 부여
5. 편집기에 자동 포커스 이동

### 10.3 기존 `.txt` 파일 열기

1. Finder 또는 `Command+O`
2. `NSDocumentController`가 파일 URL 기준 문서 생성
3. `TextFileCodec`가 텍스트 로드
4. `lastSavedText = text`
5. dirty 없음 상태로 창 표시
6. 창 초기 글자 크기는 항상 앱 기본 글자 크기 사용

### 10.4 저장

1. 사용자 메뉴의 `저장`, 툴바의 `저장`, 또는 `Command+S`
2. 현재 문서가 저장 경로 없으면 저장 패널 표시
3. 저장 경로 있으면 같은 URL에 바로 저장
4. `TextFileCodec.writeUTF8Text`
5. 성공 시 `lastSavedText = text`
6. dirty 해제
7. 제목 `*` 제거

### 10.5 다른 이름으로 저장

1. 사용자 `Shift+Command+S`
2. 항상 저장 패널 표시
3. 새 URL 선택
4. 저장 성공 시 현재 문서의 `fileURL` 자체를 새 URL로 갱신
5. 제목과 represented URL 갱신

### 10.6 현재 창 닫기

1. 사용자가 창 닫기 시도
2. `DocumentWindowController`가 기본 닫기를 일단 막음
3. `CloseDecisionEngine` 평가
4. 즉시 종료면 창 닫기 진행
5. prompt 필요면 커스텀 종료 sheet 표시
6. 분기 처리
   - `저장`: 필요 시 저장 패널 포함 저장 후 닫기
   - `다른 이름으로 저장`: 저장 성공 후 닫기
   - `취소`: 종료 중단
   - `저장하지 않고 종료`: 바로 닫기

### 10.7 앱 종료

1. 사용자가 `Command+Q`
2. `AppTerminationCoordinator` 시작
3. 포커스된 창부터 순차 평가
4. 각 창은 현재 창 닫기와 동일한 규칙 사용
5. 중간에 `취소` 또는 저장 실패가 발생하면 전체 종료 중단
6. 끝까지 성공하면 앱 종료

## 11. 메뉴, 툴바, 액션 라우팅

이 앱은 `현재 활성 창` 기준 동작이 매우 중요하므로 responder chain을 최대한 활용해야 한다.

| 액션                     | 1차 처리 주체                                           | 비고                                         |
| ------------------------ | ------------------------------------------------------- | -------------------------------------------- |
| 새 문서                  | `NSDocumentController`                                  | 항상 새 창                                   |
| 파일 열기                | `NSDocumentController`                                  | Finder 연동 포함                             |
| 저장                     | `NotepadDocument`                                       | 메뉴/툴바/단축키 공통, 경로 없으면 저장 패널 |
| 다른 이름으로 저장       | `DocumentSaveCoordinator` 또는 `NotepadDocument`        | 항상 저장 패널                               |
| 창 닫기                  | `DocumentWindowController` + `CloseWorkflowCoordinator` | 4버튼 분기                                   |
| 앱 종료                  | `AppTerminationCoordinator`                             | 창 순차 처리                                 |
| Undo/Redo                | `NSTextView` responder chain                            | 창별 히스토리 자동 분리                      |
| 글자 크기 확대/축소/복원 | `EditorSessionController`                               | 현재 창에만 적용                             |
| wrap 토글                | `EditorSessionController`                               | 현재 창에만 적용                             |
| 설정 열기                | `PreferencesWindowController`                           | 앱 전역 기본 글자 크기                       |

검증 원칙:

- 메뉴 enable/disable 상태는 항상 key window 기준으로 계산한다.
- 툴바 저장 버튼도 현재 key window의 저장 액션 상태를 반영해야 한다.
- 툴바 pt 입력 필드는 현재 창의 `fontSize`를 반영해야 한다.
- wrap 메뉴 체크 상태도 현재 창 기준이어야 한다.

## 12. 제목 표시와 dirty 상태 처리

사용자 요구사항상 창 제목 옆 `*` 표시는 명시적으로 보장해야 한다.

권장 방식:

- 제목 포맷은 `WindowTitleFormatter`가 단일 책임으로 관리
- 입력:
  - `displayName`
  - `hasUnsavedChanges`
- 출력:
  - `Untitled *`
  - `meeting-notes.txt`
  - `meeting-notes.txt *`

주의점:

- macOS 기본 edited indicator와 별도로 `*`를 제목 문자열에 포함한다.
- 저장 직후 즉시 `*` 제거
- undo/redo로 저장 시점과 동일한 텍스트가 되면 `*` 제거

## 13. plain text 편집기 세부 정책

### 13.1 plain text 보장

- rich text 붙여넣기는 허용하지 않는다.
- 서식, 이미지, 첨부 객체 import를 막는다.
- 저장되는 내용은 editor view state가 아니라 `text` 문자열 하나여야 한다.

### 13.2 IME 안정성

- 텍스트 변경 확정 시점과 조합 중 상태를 분리해 다룬다.
- 종료 직전과 저장 직전에는 조합 중 텍스트가 누락되지 않도록 편집 버퍼를 동기화한다.
- `NSTextViewDelegate` 경로를 사용해 조합 종료 후 최종 텍스트를 문서 state에 반영한다.

### 13.3 undo/redo

- 기본 undo manager는 `NSTextView`를 사용한다.
- 보기 상태 변경은 undo stack에 넣지 않는다.
- undo/redo 후 문서 dirty 상태를 다시 판단한다.

### 13.4 wrap 토글

- wrap은 purely visual state다.
- toggle 직후 layout만 다시 계산하고 text는 유지한다.
- wrap 꺼짐 상태에서는 수평 스크롤이 보여야 한다.

## 14. 파일 및 저장 정책

### 14.1 허용 범위

- 읽기/쓰기 대상은 plain text `.txt`
- 저장은 항상 UTF-8 without BOM

### 14.2 파일명 정책

- 사용자가 확장자를 입력하지 않으면 `.txt` 자동 부여
- 사용자가 다른 확장자를 입력해도 `.txt`로 정규화

### 14.3 저장 실패 정책

- alert로 오류 표시
- 문서는 열린 상태 유지
- dirty 상태 유지
- 종료 흐름 중이었다면 종료는 중단

### 14.4 비어 있는 문서 저장 정책

- 사용자가 명시적으로 저장하면 빈 `.txt`도 저장 가능
- 다만 종료 판정에서는 공백/탭/줄바꿈만 있으면 즉시 종료

## 15. 종료 확인 UI 계약

종료 확인 UI는 시스템 기본 3버튼 alert가 아니라 커스텀 sheet를 전제로 설계한다.

| 항목               | 규칙                                                                           |
| ------------------ | ------------------------------------------------------------------------------ |
| 표시 조건          | 내용 있음 + 미저장 변경 있음                                                   |
| 비표시 조건        | 빈 문서 또는 변경 없음                                                         |
| 버튼               | `저장`, `다른 이름으로 저장`, `취소`, `저장하지 않고 종료`                     |
| 배치               | 좌측 단독 `저장하지 않고 종료`, 우측 그룹 `취소`, `다른 이름으로 저장`, `저장` |
| 기본 포커스        | `저장`                                                                         |
| Escape             | `취소`                                                                         |
| destructive 스타일 | `저장하지 않고 종료`                                                           |
| 중복 표시          | 동일 창에서 동시 1개만 허용                                                    |

이 UI는 `DocumentWindowController`가 띄우되, 실제 분기 규칙은 `CloseWorkflowCoordinator`가 가진다.

## 16. 권장 폴더 구조

MVP 기준으로 아래 구조가 가장 실용적이다.

```text
NotepadApp/
├── App/
│   ├── main.swift
│   ├── AppDelegate.swift
│   ├── AppTerminationCoordinator.swift
│   └── Preferences/
│       ├── PreferencesWindowController.swift
│       ├── PreferencesViewController.swift
│       └── SettingsStore.swift
├── Document/
│   ├── NotepadDocument.swift
│   ├── NotepadDocumentController.swift
│   ├── UntitledNameAllocator.swift
│   ├── Window/
│   │   ├── DocumentWindowController.swift
│   │   ├── DocumentWindowViewController.swift
│   │   └── WindowTitleFormatter.swift
│   └── Save/
│       ├── DocumentSaveCoordinator.swift
│       └── SavePanelService.swift
├── Editor/
│   ├── NotepadTextView.swift
│   ├── EditorSessionController.swift
│   ├── FontSizePolicy.swift
│   └── WrapLayoutController.swift
├── Workflows/
│   ├── CloseDecisionEngine.swift
│   ├── CloseWorkflowCoordinator.swift
│   ├── CloseConfirmationSheetController.swift
│   └── CloseConfirmationViewController.swift
├── Infrastructure/
│   ├── TextFileCodec.swift
│   ├── AlertPresenter.swift
│   └── DefaultsKeys.swift
└── Shared/
    ├── Models/
    │   ├── CloseIntent.swift
    │   └── CloseDecision.swift
    └── Extensions/
```

## 17. 테스트 전략

### 17.1 단위 테스트

우선순위가 높은 순수 규칙:

- `CloseDecisionEngine`
- `FontSizePolicy`
- `UntitledNameAllocator`
- `WindowTitleFormatter`
- `TextFileCodec`의 `.txt` 정규화와 UTF-8 저장 규칙
- `SettingsStore`의 손상값 복구

### 17.2 통합 테스트

- 새 문서 생성 시 기본 글자 크기와 wrap 기본값 적용
- 저장 후 dirty 해제와 제목 `*` 제거
- 다른 이름으로 저장 후 현재 파일 URL 갱신
- 앱 종료 시 여러 창 순차 종료 중 `취소` 분기 동작

### 17.3 수동 QA 필수 시나리오

- 앱 실행 직후 첫 키 입력 누락 여부
- 한글 IME 조합 중 저장/종료
- Finder에서 `.txt` 파일 열기
- wrap 꺼짐 상태의 긴 한 줄 수평 스크롤
- undo/redo 후 저장 상태와 제목 `*` 일치 여부
- 공백만 있는 문서가 확인 없이 즉시 닫히는지
- 앱이 무창 상태가 된 뒤 재활성화 시 새 빈 창이 열리는지

## 18. 구현 순서 권장안

가장 리스크가 큰 부분부터 구현하는 순서가 적절하다.

1. `NSDocument` 기반 새 문서/파일 열기/다중 창 셸 구축
2. `NSTextView` 기반 plain text 편집기 연결과 first responder 자동 포커스
3. 저장/다른 이름으로 저장과 title dirty 표시 연동
4. 종료 확인 sheet와 앱 종료 순차 처리
5. 글자 크기 조절과 앱 기본 글자 크기 설정
6. auto word wrap on/off와 수평 스크롤
7. undo/redo, IME, empty-close 규칙 집중 QA

이 순서를 권장하는 이유는 저장과 종료가 흔들리면 이후 보기 기능 구현 가치가 크게 떨어지기 때문이다.

### 18.1 구현 반복 체크리스트

실제 작업용 체크리스트는 별도 문서로 분리한다.

- [execution-checklist.md](./execution-checklist.md)

핵심 운영 원칙만 여기서 유지한다.

- 각 반복 루프는 별도 브랜치에서 시작한다.
- 작업 단위는 `기능 1개 또는 하위 시나리오 1개` 수준으로 자른다.
- 각 작업 단위는 `브랜치 생성 -> 구현 -> 테스트 -> 수정 -> 리뷰(별도 에이전트) -> 수정 -> 리팩토링(별도 에이전트) -> 재테스트 -> 커밋 -> develop 머지` 순서로 닫는다.
- 리뷰 에이전트와 리팩토링 에이전트는 역할을 섞지 않는다.
- 각 반복 종료 시점에는 항상 실행 가능한 상태와 통과한 검증 근거를 남긴다.
- 각 작업 단위는 완료 시점에 해당 변경만 포함한 커밋으로 마무리한다.
- 각 반복 루프는 검증과 커밋이 끝난 뒤 `develop` 브랜치에 머지하고 종료한다.

## 19. 최종 권장안

이 프로젝트의 MVP에는 `순수 AppKit 문서 구조 + NSTextView 편집기`가 가장 적합하다. 핵심 이유는 아래 5가지다.

- 문서 창, Finder 열기, 저장, 여러 창 독립성은 `NSDocument`가 가장 잘 맞는다.
- IME, undo/redo, no-wrap, plain text 붙여넣기 품질은 `NSTextView`가 가장 안정적이다.
- 4버튼 종료 확인과 empty-close 규칙은 별도 coordinator가 있어야 안전하게 구현된다.
- 글자 크기와 wrap은 문서 데이터가 아니라 창 세션 상태로 분리해야 요구사항과 정확히 맞는다.
- 이 앱에서는 SwiftUI를 남겨도 핵심 복잡도가 줄지 않으므로, pure AppKit이 responder chain과 포커스 제어를 더 단순하게 만든다.

즉, 이 앱의 구현 핵심은 `문서 앱처럼 파일을 다루되, 메모장처럼 단순하게 행동하도록 AppKit만으로 일관되게 구성하는 것`이다. 문서 라이프사이클, 창 제어, 편집기, 설정 창까지 모두 같은 AppKit 모델 안에 두는 편이 이 MVP에는 가장 현실적이다.
