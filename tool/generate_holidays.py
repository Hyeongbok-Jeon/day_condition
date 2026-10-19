"""한국 공휴일 데이터(assets/holidays.json)를 생성한다.

기본 데이터는 python-holidays 패키지로 만든다(대체공휴일, 선거일 포함).
환경 변수 HOLIDAY_API_KEY가 있으면 올해부터 2년 뒤까지는 공공데이터포털
특일 정보 API(공식 발표 기준)로 덮어써서, 갑자기 지정된 임시공휴일도 반영한다.

GitHub Actions(.github/workflows/update-holidays.yml)가 매주 실행하며,
직접 실행할 때는:

    pip install --upgrade holidays
    HOLIDAY_API_KEY=... python tool/generate_holidays.py
"""

import datetime
import json
import os
import urllib.parse
import urllib.request
from pathlib import Path

import holidays

FIRST_YEAR = 2020
LAST_YEAR = 2030
API_URL = "https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo"


def from_library():
    kr = holidays.KR(years=range(FIRST_YEAR, LAST_YEAR + 1), language="ko")
    return {day.strftime("%Y%m%d"): name for day, name in kr.items()}


def from_api(year, key):
    query = urllib.parse.urlencode(
        {"solYear": year, "ServiceKey": key, "_type": "json", "numOfRows": 100}
    )
    with urllib.request.urlopen(f"{API_URL}?{query}", timeout=30) as res:
        body = json.load(res)["response"]["body"]
    items = body.get("items") or {}
    rows = items.get("item", []) if isinstance(items, dict) else []
    if isinstance(rows, dict):  # 결과가 하나면 리스트가 아니라 객체로 온다
        rows = [rows]
    return {
        str(row["locdate"]): row["dateName"]
        for row in rows
        if row.get("isHoliday") == "Y"
    }


def main():
    data = from_library()

    key = os.environ.get("HOLIDAY_API_KEY")
    if key:
        this_year = datetime.date.today().year
        for year in range(this_year, this_year + 3):
            official = from_api(year, key)
            if not official:
                continue  # 아직 발표 전인 해는 라이브러리 값을 유지한다
            data = {d: n for d, n in data.items() if not d.startswith(str(year))}
            data.update(official)
            print(f"{year}: {len(official)} holidays from data.go.kr")

    data = dict(sorted(data.items()))
    out = Path(__file__).resolve().parent.parent / "assets" / "holidays.json"
    out.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{len(data)} holidays -> {out}")


if __name__ == "__main__":
    main()
