### Access cameras and get preview images from camera

[![Build Status](https://travis-ci.org/Zogoo/preview_images.png)](https://travis-ci.org/Zogoo/preview_images.png)

EEN have cool api for control and manage cameras.
https://apidocs.eagleeyenetworks.com/apidocs

First you need to register your user and get api key. Everything is well explained in the document.

With this repo contain ruby script which is retrieve images from camera.

##### Steps for retrieve images

You can easily test with CURL with following commands.
Note: Commands are well explained in the document if you need more info please take a look at it.

1. Get token
curl -X POST https://login.eagleeyenetworks.com/g/aaa/authenticate -d '{"username": "", "password": ""}' -H "content-type: application/json" -H "Authentication: [api key]"

2. Get auth_key from cookie and active_brand_subdomain, camera_access from body
auth_key: will be used next requests
active_brand_subdomain: for performance
camera_access: to get camera
curl -D - -X POST https://login.eagleeyenetworks.com/g/aaa/authorize -d '{"token": ""}' -H "content-type: application/json"

3. Get available cameras and pick one of them. Camera Id (id) from body
curl --request GET https://[active_brand_subdomain].eagleeyenetworks.com/g/device/list -H "Authentication: [api key]" --cookie "auth_key=[AUTH_KEY]"

4. Get preview images from camera
curl -X GET https://[active_brand_subdomain].eagleeyenetworks.com/asset/asset/image.jpeg -d "id=[CAMERA_ID]" -d "timestamp=now" -d "asset_class=pre" -H "Authentication: [api key]" --cookie "auth_key=[AUTH_KEY]" -G -v

##### How to use ruby script

###### 1. Setup env variable

Create your own .env variable and setup following information

```
  PROTOCOL=https
  DEFAULT_SUBDOMAIN=login
  HOST=eagleeyenetworks.com
  USER_NAME=<username>
  PASSWORD=<password>
  API_KEY=
  CONCURENCY_LIMIT=5
  LOG_FILE_NAME='faraday.log'
```

###### 2. Execute ruby script

Open your command line execute ruby and you will get images in output folder

```
 ./image.rb
```

###### 3. Get results

You can find images from `./output` folder

Or if you want to just see sample result please take a look `./output/sample`

##### TODO

1. Image request sometimes failing 400 or 401 error
HTTP is not stable enough protocol so we need to retry at least 3 times.

3. Corner case for test cases
