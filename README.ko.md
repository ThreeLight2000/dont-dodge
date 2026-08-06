# DON’T DODGE

English: [README.md](README.md)

`DON’T DODGE`는 공격을 처치할지, 지울지, 직접 회피할지를 빠르게 판단하는 90초 생존 전투를 검증하는 Godot 4.7 프로토타입입니다.

## 바로 플레이

[**🎮 브라우저에서 DON’T DODGE 플레이하기**](https://threelight2000.github.io/dont-dodge/)

데스크톱 Chrome·Edge 등 최신 브라우저를 권장합니다. 배경음악과 효과음은 브라우저 정책상 `게임 시작하기` 또는 각 오디오 버튼을 누른 뒤 재생됩니다.

## 목적

같은 위협을 보고도 상황에 따라 집중 베기, 방어 행동, 위치 이동 중 다른 선택이 더 재미있게 느껴지는지 검증합니다. 이 저장소는 완성된 상용 게임이 아니라 그 전투 가설을 확인하기 위한 게임성 검증용 프로토타입입니다.

## 핵심 규칙

- 플레이어는 HP 3으로 90초 동안 4개 웨이브를 버텨야 합니다.
- 근접, 원거리, 돌진, 연사, 정예 적은 각자 다른 공격 예고와 위협 거리를 가집니다.
- `집중 베기`는 가까운 적을 처치하거나 밀쳐내며, `회피`와 `밀쳐내기`는 2칸의 공유 방어 스택을 사용합니다.
- 완벽 회피, 공격 인터럽트, 투사체 제거, 적 처치로 궁극기 게이지를 채울 수 있습니다.
- 완벽 회피는 일반 이동이 아니라 W 무적 돌진 시작 후 첫 0.15초 안에 공격이나 투사체가 닿았을 때 발생합니다.
- 경험치 레벨 상승마다 무기·무기 기술·무기 진화 중 하나를 3장의 카드에서 선택합니다.
- 단검·대검·장검은 공격 수치뿐 아니라 E 잠금, W 방어 스택 비용처럼 서로 다른 전투 규칙을 가집니다.

## 조작

| 행동 | 키보드 |
| --- | --- |
| 이동 | 방향키 |
| 집중 베기 | `Q` |
| 회피 | `W` |
| 밀쳐내기 / 투사체 제거 | `E` |
| 궁극기 | `R` |
| 일시정지 | `Esc` |

로비와 일시정지 화면에서 BGM과 효과음을 각각 켜거나 끌 수 있습니다. 브라우저의 자동 재생 제한 때문에 두 소리는 `게임 시작하기` 또는 해당 오디오 버튼을 누른 뒤 재생됩니다.

## 실행 환경

- Godot `4.7`
- GDScript
- Compatibility renderer
- 빠른 검증 환경: macOS
- 목표 플랫폼: 데스크톱 웹 브라우저

`project.godot`의 기본 씬은 `scenes/dont_dodge/dont_dodge.tscn`입니다.

### 실행

```sh
godot --path . --editor
```

`godot` 명령이 없다면 `godot4` 또는 `/Applications/Godot.app/Contents/MacOS/Godot`를 사용합니다.

## 검증

프로젝트와 스크립트가 정상적으로 열리는지 확인:

```sh
godot --headless --path . --editor --quit
```

핵심 전투 기능 확인:

```sh
godot --headless --path . --script tests/dont_dodge_validation.gd
```

번역 키와 한영 카탈로그 확인:

```sh
godot --headless --path . --script tests/dont_dodge_localization_validation.gd
```

## 웹 빌드와 배포

`export_presets.cfg`의 웹 내보내기 설정은 GitHub Pages용 브라우저 빌드를 만듭니다. `main` 브랜치에 push하면 `.github/workflows/deploy-pages.yml`이 브라우저용 빌드를 만들고 Pages에 배포합니다.

- 플레이 URL: `https://threelight2000.github.io/dont-dodge/`
- 로컬 웹 내보내기에는 Godot 4.7.1 웹 템플릿이 필요합니다.

## 주요 구조

```text
scenes/dont_dodge/             기본 게임 씬
scripts/dont_dodge/            전투 규칙, 입력, 엔티티, 튜닝
scripts/dont_dodge/visuals/    픽셀 던전 배경, 상태별 전투 연출
localization/                  게임 한영 번역 카탈로그
assets/third_party/kenney/     CC0 RPG 아틀라스와 효과음 원본
tests/                         전투·번역 검증
docs/                          설계·비전·성능 참고 문서
```

전투 규칙은 이동, 공격, 충돌, 피해와 전투 구간 진행을 담당합니다. 화면 표현은 Kenney RPG 아틀라스의 정지 타일과 픽셀 연출을 사용하며 게임 수치나 판정에는 영향을 주지 않습니다.

## 현재 범위와 제한 사항

현재 구현되어 있습니다.

- 전투 진행, 적 등장과 공격 예고, 투사체, 피격·사망, 3단계 무기 강화 선택
- 키보드 및 화면 UI 입력
- JSON Lines 형식의 로컬 전투 로그 (`user://dont_dodge_runs.jsonl`)
- Kenney 타일 기반 던전과 코드 기반 픽셀 캐릭터·드롭·투사체·스킬 문양
- BGM/효과음 개별 설정과 전투·UI 효과음
- 타이틀과 일시정지 화면의 한국어·영어 선택 및 저장

현재는 상태별 프레임 애니메이션, 장비·상점·장기 메타 진행·온라인 기능을 구현하지 않습니다.

기준 해상도는 `1600×900`입니다. 픽셀 연출은 `scripts/dont_dodge/visuals/`에서 담당하며 충돌 반경·공격 범위·전투 구간 진행은 바꾸지 않습니다.

## 라이선스와 에셋

이 저장소의 코드와 자체 작성 문서는 [MIT License](LICENSE)를 따릅니다.

- UI 한글 폰트는 [Noto Sans KR](https://github.com/notofonts/noto-cjk)이며 SIL Open Font License 1.1로 배포됩니다.
- 그래픽과 효과음은 [Kenney Roguelike/RPG Pack](https://kenney.nl/assets/roguelike-rpg-pack), [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds)를 사용하며 CC0입니다.
- 에셋 원문과 라이선스는 `assets/third_party/kenney/`에 있습니다.

## 저장소에서 제외하는 항목

`.godot/`, 빌드·내보내기 결과물, 에디터 설정, 로컬 환경 파일과 비밀 키는 `.gitignore`로 제외합니다. 전투 로그는 `user://`에만 기록되며 저장소에 생성되지 않습니다.
