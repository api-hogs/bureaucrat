---
title: SwaggerDemo App

search: true
---

# SwaggerDemo App



# Models

## User

A user of the app

|Property|Description|Type|Required|
|--------|-----------|----|--------|
|email|Email address|string|true|
|id|User ID|integer|false|
|inserted_at|Creation timestamp|string|false|
|name|User name|string|true|
|updated_at|Update timestamp|string|false|

## UserRequest

POST body for creating a user

|Property|Description|Type|Required|
|--------|-----------|----|--------|
|user|A user of the app|[User](#user)|false|

## UserResponse

Response schema for single user

|Property|Description|Type|Required|
|--------|-----------|----|--------|
|data|A user of the app|[User](#user)|false|

## UsersResponse

Response schema for multiple users

|Property|Description|Type|Required|
|--------|-----------|----|--------|
|data|The users details|array([User](#user))|false|

# User

Operations related to Users

## Create user

> does not create resource and renders errors when data is invalid

```plaintext
POST /api/users
accept: application/json
content-type: multipart/mixed; charset: utf-8
```

```json
{
  "user": {}
}
```

> Response

```plaintext
422
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: fb2rkvo607dcarlur29r8c8l9bvomkek
```

```json
{
  "errors": {
    "name": [
      "can't be blank"
    ],
    "email": [
      "can't be blank"
    ]
  }
}
```

> creates and renders resource when data is valid

```plaintext
POST /api/users
accept: application/json
content-type: multipart/mixed; charset: utf-8
```

```json
{
  "user": {
    "name": "some content",
    "email": "some content"
  }
}
```

> Response

```plaintext
201
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: 0p498qvv889slm4dff9i3nes9pi7tikn
location: /api/users/134
```

```json
{
  "data": {
    "name": "some content",
    "id": 134,
    "email": "some content"
  }
}
```

Creates a new user

#### Responses

| Status | Description | Schema |
|--------|-------------|--------|
|201 | User created OK | [UserResponse](#userresponse)|
## Delete User

> deletes chosen resource

```plaintext
DELETE /api/users/131
accept: application/json
```

> Response

```plaintext
204
cache-control: max-age=0, private, must-revalidate
x-request-id: 4bbv0nulnkmg1h5vl8i9he7pvoubp0q2
```

```json

```

Delete a user by ID

#### Responses

| Status | Description | Schema |
|--------|-------------|--------|
|203 | No Content - Deleted Successfully | |
## List Users

> lists all entries on index

```plaintext
GET /api/users
accept: application/json
```

> Response

```plaintext
200
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: gb5guam3dafr0l7jv0j0v2q7lnhnfi73
```

```json
{
  "data": []
}
```

List all users in the database

#### Responses

| Status | Description | Schema |
|--------|-------------|--------|
|200 | OK | [UsersResponse](#usersresponse)|
## Show User

> shows chosen resource

```plaintext
GET /api/users/135
accept: application/json
```

> Response

```plaintext
200
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: vkmr1m6tnu29k9bchfd2q6fp9gvs2n7s
```

```json
{
  "data": {
    "name": null,
    "id": 135,
    "email": null
  }
}
```

Show a user by ID

#### Responses

| Status | Description | Schema |
|--------|-------------|--------|
|200 | OK | [UserResponse](#userresponse)|
## Update user

> does not update chosen resource and renders errors when data is invalid

```plaintext
PUT /api/users/132
accept: application/json
content-type: multipart/mixed; charset: utf-8
```

```json
{
  "user": {}
}
```

> Response

```plaintext
422
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: 5sri188ba35a5qaev7t2li22fjb9kjp0
```

```json
{
  "errors": {
    "name": [
      "can't be blank"
    ],
    "email": [
      "can't be blank"
    ]
  }
}
```

> updates and renders chosen resource when data is valid

```plaintext
PUT /api/users/133
accept: application/json
content-type: multipart/mixed; charset: utf-8
```

```json
{
  "user": {
    "name": "some content",
    "email": "some content"
  }
}
```

> Response

```plaintext
200
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: va30dei76856qf0tejiv7k2i79v3v9no
```

```json
{
  "data": {
    "name": "some content",
    "id": 133,
    "email": "some content"
  }
}
```

Update all attributes of a user

#### Responses

| Status | Description | Schema |
|--------|-------------|--------|
|200 | Updated Successfully | [UserResponse](#userresponse)|
