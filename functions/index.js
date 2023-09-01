/* eslint-disable max-len */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// const axios = require("axios");

admin.initializeApp();

// Firebase Realtime Database 참조 가져오기
const database = admin.database();

// HTTP 요청을 보내고 데이터를 Firebase Realtime Database에 저장하는 함수
exports.fetchAndStoreData = functions.https.onRequest(async (req, res) => {
    try {
      const solYear = req.body.solYear;
      const apiUrl = "https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo?solYear=" + solYear + "&ServiceKey=vGcOnDW%2Bywhtts%2FPnIk6QDB%2BJ7JTcwVdOysxn74uzxJ6%2FTUtkKU5PHLf4z6yXJinJnU5qKALxEbYIz4WhemGQA%3D%3D&_type=json&numOfRows=100";

      const https = require("https");

      https.get(apiUrl, (response) => {
        let data = "";

        response.on("data", (chunk) => {
          data += chunk;
        });

        response.on("end", () => {
          // 데이터를 Firebase Realtime Database에 저장
          const ref = database.ref("/holidayInfo/" + solYear); // 실제 데이터베이스 경로로 변경하세요.
          ref.set(JSON.parse(data), (error) => {
            if (error) {
              console.error("Error:", error);
              res.status(500).send("An error occurred while storing data.");
            } else {
              res.status(200).send("Data fetched and stored successfully.");
            }
          });
        });
      });
    } catch (error) {
      console.error("Error:", error);
      res.status(500).send("An error occurred while fetching and storing data.");
    }
  });
