/* eslint-disable max-len */
const functions = require("firebase-functions");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const https = require("https");

admin.initializeApp();

// Firebase Realtime Database 참조 가져오기
const database = admin.database();

// 공공데이터포털 특일 정보 API 서비스 키. 코드에 두지 않고 Secret Manager에 보관한다.
// 설정: firebase functions:secrets:set HOLIDAY_API_KEY
const holidayApiKey = defineSecret("HOLIDAY_API_KEY");

// HTTP 요청을 보내고 데이터를 Firebase Realtime Database에 저장하는 함수
exports.fetchAndStoreData = functions
    .runWith({secrets: [holidayApiKey]})
    .https.onRequest((req, res) => {
      const solYear = String(req.body && req.body.solYear);
      if (!/^\d{4}$/.test(solYear)) {
        res.status(400).send("solYear must be a 4-digit year.");
        return;
      }

      const apiUrl = "https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo" +
        "?solYear=" + solYear +
        "&ServiceKey=" + encodeURIComponent(holidayApiKey.value()) +
        "&_type=json&numOfRows=100";

      https.get(apiUrl, (response) => {
        let data = "";

        response.on("data", (chunk) => {
          data += chunk;
        });

        response.on("end", () => {
          let parsed;
          try {
            parsed = JSON.parse(data);
          } catch (error) {
            console.error("Invalid response from holiday API:", error);
            res.status(502).send("The holiday API returned an invalid response.");
            return;
          }

          // 데이터를 Firebase Realtime Database에 저장
          database.ref("/holidayInfo/" + solYear).set(parsed)
              .then(() => res.status(200).send("Data fetched and stored successfully."))
              .catch((error) => {
                console.error("Error:", error);
                res.status(500).send("An error occurred while storing data.");
              });
        });
      }).on("error", (error) => {
        console.error("Error:", error);
        res.status(502).send("An error occurred while fetching data.");
      });
    });
