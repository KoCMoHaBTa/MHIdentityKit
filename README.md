# MHIdentityKit

[![Build Status](https://app.bitrise.io/app/94d7f7f8c90d806a/status.svg?token=uHSLJczg75y16H8qzqPpHA&branch=master)](https://app.bitrise.io/app/94d7f7f8c90d806a)

## OAuth2 and OpenID connect iOS Protocol Oriented Swift client library

## Installation

[Embed]:
https://developer.apple.com/library/content/technotes/tn2435/_index.html#//apple_ref/doc/uid/DTS40017543-CH1-PROJ_CONFIG-APPS_WITH_MULTIPLE_XCODE_PROJECTS

#### [Carthage](https://github.com/Carthage/Carthage)

Add `github "KoCMoHaBTa/MHIdentityKit"` to your `Cartfile`, then [Embed] the framework directly into your project.

#### [Cocoapods](https://cocoapods.org)

Add `pod 'MHIdentityKit'` to your  `Podfile`

#### [Submodules](http://git-scm.com/docs/git-submodule)

[Add a submodule](https://git-scm.com/docs/git-submodule#git-submodule-add-bltbranchgt-f--force--nameltnamegt--referenceltrepositorygt--depthltdepthgt--ltrepositorygtltpathgt) to your repostiroy, then [Embed] the framework directly into your project

#### Manually

[Download](https://github.com/KoCMoHaBTa/MHIdentityKit/releases), then [Embed] the framework directly into your project

## How to use

### Automatic

One of the concepts in this library is to allow the developers to integrate with any OAuth2 identity server with less effort, by just setting up their needs. This is why this library provides a mechanism, called `OAuth2IdentityManager`, that performs this task.

In order to get started, create an instance of the identity manager using a flow, optional refresher, storage and authorization method:

	let flow: AuthorizationGrantFlow = <#T##...#>
    let refresher: AccessTokenRefresher? = DefaultAccessTokenRefresher(tokenEndpoint: <#T##URL#>, clientID: <#T##String#>, secret: <#T##String#>)
    let storage: IdentityStorage = InMemoryIdentityStorage()
    let manager: IdentityManager = OAuth2IdentityManager(flow: <#T##AuthorizationGrantFlow#>, refresher: <#T##AccessTokenRefresher?#>, storage: <#T##IdentityStorage#>, authorizationMethod: .header)
    
Build, authorize and perform your your request:

	//build your request
	let url = URL(string: <#T##Your protected resource URL#>)!
    let request = URLRequest(url: url)
    
    //authorize your request
    manager.authorize(request: request) { (request, error) in
        
        guard error == nil else {
            
            //handle the error
            return
        }
        
        //perform the authorized request
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            
            //handle your data
        })
    }
    
    
When you call the `authorize` method of `OAuth2IdentityManager `, it handles automatically the management involved in the authentincation (using the provided flow), authorization, refreshing process and storing any state needed into the provided storage.

### Manual

Even that the role of an identity manager is to handle a lot of stuffs automatically in order to reduce boilerplate code, you might end up implementing your own that fits your specific needs or just to everything manually in order to have even more control.

In that case you can perform every step you need, manually.

#### Authentication - getting an access token

The authentication process is represented as an implementation of the AuthorizationGrantFlow protocol.

As per [OAuth2](https://tools.ietf.org/html/rfc6749) specification, there are 4 Flows defined:

- [Authorization Code Grant Flow](https://tools.ietf.org/html/rfc6749#section-4.1) - implemented as `AuthorizationCodeGrantFlow`
- [Implicit Grant Flow](https://tools.ietf.org/html/rfc6749#section-4.2) - implemented as `ImplicitGrantFlow`
- [Resource Owner Password Credentials Grant Flow](https://tools.ietf.org/html/rfc6749#section-4.3) - implemented as `ResourceOwnerPasswordCredentialsGrantFlow`
- [Client Credentials Grant Flow](https://tools.ietf.org/html/rfc6749#section-4.4) - implemented as `ClientCredentialsGrantFlow`

In order to get an access token - just create an instance of the desired flow, following the code documentation and call `authenticate` on the respective instance. Then, upon success, you will receive an instance of `AccessTokenResponse` where the access token, refresh token and other meta information is stored. 

It is up to you to handle use and manage the response.
 
#### Authorization - accessing protected resources using an access token

Once you get your hands dirty with an access token, you have make use of it in order to authorize some requests.

Request authorization is defined as `RequestAuthorizer` protocol, but since it is not bound to an access token usage, the existing implementation that makes use of an access token is `BearerAccessTokenAuthorizer`

It's usage is straightforward:

	let authorizer = BearerAccessTokenAuthorizer(token: <#T##String#>, method: <#T##BearerAccessTokenAuthorizer.AuthorizationMethod#>)
    authorizer.authorize(request: <#T##URLRequest#>) { (request, error) in
        
        guard error == nil else {
            
            //handle the error
            return
        }
        
        //perform the authorized request
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            
            //handle your data
        })
    }
    
Upon success, the provided `request ` in the completion handler will be authorized using the specified method.

#### Refreshing an access token 

Refreshing an access token is also a straightforward task:

	//create a refresher
    let refresher = DefaultAccessTokenRefresher(tokenEndpoint: <#T##URL#>, clientID: <#T##String#>, secret: <#T##String#>)
    
    //create a refresh request
    let refreshRequest = AccessTokenRefreshRequest(refreshToken: <#T##String#>, scope: <#T##Scope?#>)
    
    //refresh the access token
    refresher.refresh(using: refreshRequest) { (accessTokenResponse, error) in
        
        //handle the authorization process
    }
    
The outcome of refreshing an access token is the same as authenticating - upon success, you receive an instance of `AccessTokenResponse` where the access token, refresh token and other meta information is stored.   

It is, again, up to you to handle use and manage the response.

#### Additional request parameters

Because a lot of auth services actually put custom data into token and auth requests, that is out of the official OAuth2 spec - you can inject custom parameters in one of the following ways:

- set the `additionalAuthorizationRequestParameters` or `additionalAccessTokenRequestParameters` on the flow you are using. If you specift a parameter that is originally supplied by the flow - your custom one will override it.
- inherit the desired flow and override the `parameters(from:)` function to specify your own custom parameters.

## Documentation

The code contains inline documentation supported by Xcode. In order to find out more - just check it out. 

## Contribution

Any kind of contribution is welcome.

If you would like to contribute - fork the repo, implement your feature and submit a PR for review.

If you find any issues or just have questions - don't hesitate to report and/or ask.

## Development in progress ...

- Infrastructure
    - [X] Automatic identity management
    - [x] Default network client
    - [x] Default In-Memory credentials provider
    - [x] In-Memory identity storage  
    - [x] Keychain identity storage  
    - [x] [Authorizing requests using Basic HTTP scheme](https://tools.ietf.org/html/rfc2617#section-2)
    - [x] [Authorizing requests using Bearer access token](https://tools.ietf.org/html/rfc6750#section-2)

- Delegation
    - [x] Ability to use custom netowk client
    - [x] Ability to use custom credential provider
    - [x] Ability to use custom storage
    - [x] Ability to use custom request authorizers
    - [x] Ability to use custom flows
    - [x] Ability to use custom grant types

- [OAuth2](https://tools.ietf.org/html/rfc6749)
	- [x] [Authorization Code Grant Flow](https://tools.ietf.org/html/rfc6749#section-4.1)
	- [x] [Implicit Grant Flow](https://tools.ietf.org/html/rfc6749#section-4.2)
	- [x] [Resource Owner Password Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.3)
	- [x] [Client Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.4)
	
- Platform specific default user agents or examples
	- [x] iOS default UserAgent
	- [x] macOS default UserAgent
	- [ ] tvOS default UserAgent (if possible)
	- [ ] watchOS default UserAgent (if possible)

- [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html#toc)
	- [ ] Service Discovery
        - [x] [Code Flow](https://openid.net/specs/openid-connect-core-1_0.html#CodeFlowAuth)
        - [ ] [Implicit Flow](https://openid.net/specs/openid-connect-core-1_0.html#ImplicitFlowAuth)
	- [ ] [Hybrid Flow](https://openid.net/specs/openid-connect-core-1_0.html#HybridFlowAuth)
        - [x] [ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
	- [ ] ...
    
- [JWT](https://tools.ietf.org/html/rfc7519)
    - [x] [JWS](https://tools.ietf.org/html/rfc7515)
    - [ ] [JWE](https://tools.ietf.org/html/rfc7516)
    
- iOS demos
    - [x] Authorization Code Grant Flow
    - [x] Implicit Grant Flow
    - [x] Resource Owner Password Credentials Grant
    - [x] Client Credentials Grant

- macOS demo
    - [x] Authorization Code Grant Flow
    - [x] Implicit Grant Flow
    - [x] Resource Owner Password Credentials Grant
    - [x] Client Credentials Grant
