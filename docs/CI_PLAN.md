# CI Plan

## 현재 배포 구성

`.github/workflows/deploy-pages.yml`은 `main` 브랜치 push와 수동 실행에서 Web 빌드를 GitHub Pages에 배포합니다.

1. Godot 4.7 컨테이너에서 `Web` export preset으로 `build/web/index.html`을 생성한다.
2. GitHub Pages artifact로 업로드하고 Pages 환경에 배포한다.
3. 캐시와 빌드 산출물은 저장소에 커밋하지 않는다.

## 배포 전제

- GitHub 저장소는 Public이어야 한다.
- 저장소 Settings > Pages의 배포 원본은 GitHub Actions로 설정한다.
- 현재 export preset과 배포 workflow는 Web만 지원한다.

## 로컬 검증

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/dont_dodge_validation.gd
godot --headless --path . --export-release Web build/web/index.html
```
