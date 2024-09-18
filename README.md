# AthanPlus-watchOS-Companion

This repository houses my side project in developing a standalone watchOS application.

This app is designed to provide users with the public congregation timings for the 5 daily Islamic prayers of their local mosque by leveraging Masjidal's API.

Masjidal is a company that provides "convenient, time-saving, cloud based technologies" for both homes and mosques. They offer solutions ranging from prayer time management to flexible digital signage. They also have a convenient mobile application for iOS and Android called _Athan+_, which is the only app that finds nearby mosques based on your location and displays the congregation timing for all 5 prayers of all the nearby mosques along with the prayer timings of your location.

Currently, **they do not have a companion app for smartwatches**, whether it's Apple, Samsung, Google, or any other brands. That is what **my project aims to solve**.

## Masjidal API
The way that Masjidal's API works is that a user must provide their local mosque's unique ID number as a query parameter in the API link. This unique ID number is assigned to a mosque when they sign up to use Masjidal's services. After adding this number to the end of the API link, a JSON object of the following format is returned:

```json
{
  "status": "success",
  "data": {
    "salah": [
      {
        "date": "Wednesday, Sep 18, 2024",
        "hijri_date": "15, 1446",
        "hijri_month": "Rabi Al-Awwal",
        "day": "Wednesday",
        "fajr": "5:27AM",
        "sunrise": "6:43AM",
        "zuhr": "12:52PM",
        "asr": "5:13PM",
        "maghrib": "7:01PM",
        "isha": "8:16PM"
      }
    ],
    "iqamah": [
      {
        "date": "Wednesday, Sep 18, 2024",
        "fajr": "6:00AM",
        "zuhr": "1:15PM",
        "asr": "5:30PM",
        "maghrib": "7:06PM",
        "isha": "8:30PM",
        "jummah1": "1:15 PM",
        "jummah2": "2:30PM"
      }
    ]
  },
  "message": []
}
```

## App Features
I aim to add the following features to this app:

- Display the prayer timings of your closest, local mosque daily (also plan to add capability to view timings for up to 3 favorite mosques).
- Show a countdown timer to the next closest prayer timing based on the current time, in the app and in supported watch face complications.
- Have the app fetch prayer timings in the background (i.e., when the app isn't open/in use) once at the start of each day.
- Multiple types of complications to display the next prayer name and its time based on the current time.


## Additional Information
For more information about Masjidal and the types of products and services they offer, you can visit their [website](https://mymasjidal.com/).

For more information about Masjidal's API, you can visit the following [link](https://help.masjidal.com/knowledge-base/apis/).
