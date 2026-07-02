# side-mirror

![Side Mirror 소개](Resources/preview.png)

`claude.md`의 화면 프라이버시 보호 기능 명세를 구현한 macOS 메뉴바 앱입니다.
카메라로 화면 앞 인원 수를 감지해 2명 이상이 3초 이상 지속되면 경고를 띄우고,
5초 이상 지속되면 자동으로 바탕화면으로 전환합니다.

## 빌드 & 실행

```sh
./Scripts/build_app.sh
open dist/SideMirror.app
```

첫 실행 시 카메라 접근 권한과, Show Desktop 단축키 전송을 위한 손쉬운 사용(Accessibility)
권한 허용이 필요합니다. 메뉴바 아이콘 상태: 🟢 Safe / 🟡 Warning / 🔴 Privacy Mode.
