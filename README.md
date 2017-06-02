# MHIdentityKit

[![Build Status](https://www.bitrise.io/app/e4aae8e132be2cf8/status.svg?token=FHpa_DLw0GpS-_rbXunbYQ&branch=master)](https://www.bitrise.io/app/e4aae8e132be2cf8)

## OAuth2 and OpenID connect iOS Swift client library

Development in progress ...

- [ ] Infrastructure
    - [ ] Automatic identity management
    - [x] Default network client
    - [x] Default In-Memory credentials provider
    - [x] In-Memory identity storage  
    - [ ] Keychain identity storage  
    - [x] [Authorizing requests using Basic HTTP scheme](https://tools.ietf.org/html/rfc2617#section-2)
    - [x] [Authorizing requests using Bearer access token](https://tools.ietf.org/html/rfc6750#section-2)

- [ ] Delegation
    - [x] Ability to use custom netowk client
    - [x] Ability to use custom credential provider
    - [x] Ability to use custom storage
    - [x] Ability to use custom request authorizers
    - [x] Ability to use custom flows

- [ ] [OAuth2](https://tools.ietf.org/html/rfc6749)
	- [ ] [Authorization Code Grant Flow](https://tools.ietf.org/html/rfc6749#section-4.1)
	- [ ] [Implicit Grant Flow](https://tools.ietf.org/html/rfc6749#section-4.2)
	- [x] [Resource Owner Password Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.3)
	- [x] [Client Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.4)

- [ ] OpenID Connect
	- [ ] Service Discovery
