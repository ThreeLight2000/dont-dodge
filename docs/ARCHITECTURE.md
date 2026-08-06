# Architecture

DON'T DODGE는 게임성 가설을 빠르게 검증하기 위한 최소 구조만 유지합니다.

## Boundaries

- **Input**: `DontDodgeInputSource`가 키보드와 화면 UI 입력을 `DontDodgeCommand`로 변환한다.
- **Gameplay simulation**: `DontDodgeGame`이 이동, 집중 베기, 공유 방어 스택, 궁극기, 웨이브와 종료 상태를 소유한다.
- **Combat entities**: `DontDodgePlayer`, `DontDodgeEnemy`, `DontDodgeProjectile`, `DontDodgeHeart`, `DontDodgeExperienceOrb`가 전투 상태를 표현한다.
- **Pattern data**: `DontDodgePatternData`가 4개 웨이브의 패턴 타임라인과 위치 규칙을 제공한다.
- **Presentation**: `scripts/dont_dodge/visuals/`와 UI 노드가 결과를 보여주되 피해량이나 판정 결과를 바꾸지 않는다.
- **Configuration and validation**: `DontDodgeTuning`은 초기 수치를, `tests/dont_dodge_validation.gd`는 핵심 전투 회귀 검증을 담당한다.

## Rules

- 입력 장치는 명령을 생성하고 게임 규칙을 직접 수정하지 않는다.
- 게임 규칙은 그래픽 노드에 과도하게 의존하지 않는다.
- 연출은 피해량이나 판정 결과를 결정하지 않는다.
- Web 빌드는 `export_presets.cfg`의 `Web` preset만 사용하며, 배포 산출물은 저장소에 커밋하지 않는다.
- 아직 커스텀 ECS, 서비스 로케이터, 이벤트 버스 프레임워크를 만들지 않는다.
- 실제 복잡성이 생기기 전에는 추상화를 추가하지 않는다.
