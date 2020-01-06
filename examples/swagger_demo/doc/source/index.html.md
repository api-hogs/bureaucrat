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

> creates and renders resource when data is valid

```plaintext
POST /api/users
accept: application/json
content-type: multipart/mixed; boundary=plug_conn_test
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
x-request-id: f2crr3o17d28b3icr42d11e2bfuut1r7
location: /api/users/89
```

```json
{
  "data": {
    "name": "some content",
    "id": 89,
    "email": "some content"
  }
}
```

> does not create resource and renders errors when data is invalid

```plaintext
POST /api/users
accept: application/json
content-type: multipart/mixed; boundary=plug_conn_test
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
x-request-id: l4tj1lk1ma7vpsj0pllomd00hpa6bbuu
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

Creates a new user

#### Parameters

| Parameter   | Description | In |Type      | Required | Default | Example |
|-------------|-------------|----|----------|----------|---------|---------|
|user|The user details|body|[UserRequest](#userrequest)|false||{"user":{"name":"Joe","email":"Joe1@mail.com"}}|

#### Responses

| Status | Description | Schema |
|--------|-------------|--------|
|201 | User created OK | [UserResponse](#userresponse)|
## Delete User

> deletes chosen resource

```plaintext
DELETE /api/users/87
accept: application/json
```

> Response

```plaintext
204
cache-control: max-age=0, private, must-revalidate
x-request-id: b9kr116q9sjtfj82i9jn2647dma736nm
```

```json

```

Delete a user by ID

#### Parameters

| Parameter   | Description | In |Type      | Required | Default | Example |
|-------------|-------------|----|----------|----------|---------|---------|
|id|User ID|path|integer|true||3|

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
x-request-id: nos5vpjj3os59ccmn23d8cbdp0so4lu4
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
GET /api/users/88
accept: application/json
```

> Response

```plaintext
200
content-type: application/json; charset=utf-8
cache-control: max-age=0, private, must-revalidate
x-request-id: ac7e8rn1olr005tsmpfqr4amh4hi08o9
```

```json
{
  "data": {
    "name": null,
    "id": 88,
    "email": null
  }
}
```

Show a user by ID

#### Parameters

| Parameter   | Description | In |Type      | Required | Default | Example |
|-------------|-------------|----|----------|----------|---------|---------|
|id|User ID|path|integer|true||123|

#### Responses

| Status | Description | Schema |
|--------|-------------|--------|
|200 | OK | [UserResponse](#userresponse)|
## Update user

> updates and renders chosen resource when data is valid

```plaintext
PUT /api/users/90
accept: application/json
content-type: multipart/mixed; boundary=plug_conn_test
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
x-request-id: tk1tdafj884abiraguuc561sritcr7gg
```

```json
{
  "data": {
    "name": "some content",
    "id": 90,
    "email": "some content"
  }
}
```

> does not update chosen resource and renders errors when data is invalid

```plaintext
PUT /api/users/86
accept: application/json
content-type: multipart/mixed; boundary=plug_conn_test
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
x-request-id: 7qmbn1203vdkhpqsfu37j5ttd247i9ab
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

Update all attributes of a user

#### Parameters

| Parameter   | Description | In |Type      | Required | Default | Example |
|-------------|-------------|----|----------|----------|---------|---------|
|id|User ID|path|integer|true||3|
|user|The user details|body|[UserRequest](#userrequest)|false||{"user":{"name":"Joe","email":"joe4@mail.com"}}|

#### Responses

| Status | Description | Schema |
|--------|-------------|--------|
|200 | Updated Successfully | [UserResponse](#userresponse)|
