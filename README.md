# 하루 컨디션 (day_condition)

날마다 취침·기상 시간, 컨디션, 메모를 기록하는 Flutter 앱.

- 기록은 기기(웹은 브라우저)에 저장된다. 설정 화면의 "백업 복사 / 백업 불러오기"로 옮기거나 보관할 수 있다.
- 공휴일은 `assets/holidays.json`을 쓰고, 실행할 때 GitHub의 최신 파일로 갱신한다.
  `.github/workflows/update-holidays.yml`이 매주 `tool/generate_holidays.py`로 이 파일을 다시 만든다.
  저장소 Secret `HOLIDAY_API_KEY`(공공데이터포털 특일 정보 API)가 있으면 공식 발표 기준으로 덮어쓴다.
- `master`에 푸시하면 GitHub Pages로 배포된다(`.github/workflows/deploy-pages.yml`).
