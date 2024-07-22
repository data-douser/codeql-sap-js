/* ========== 1. Web Request ========== */

var webRequest1 = $.request;
var webRequest2 = $.request.entities[0];

/* ========== 1-1. Web Request Bodies ========== */

var webRequestBody1 = webRequest1.body;
var webRequestBody2 = webRequest2.body;

/* ========== 1-2. Web Request Parameters ========== */

var webRequestParam1 = webRequest1.parameters;
var webRequestParam2 = webRequest2.parameters;

/* ========== 1-3. Web Request Headers ========== */

var webRequestHeader1 = webRequest1.headers;
var webRequestHeader2 = webRequest2.headers;

/* ========== 2. Web Response ========== */

var webResponse1 = $.response;
var webResponse2 = $.response.entities[0];

/* ========== 2-1. Web Response Bodies ========== */

var webResponseBody1 = webResponse1.body;
var webResponseBody2 = webResponse2.body;

/* ========== 3. Mail, SMTPConnection ========== */

var mail = new $.net.Mail();
var smtpConnection = new $.net.SMTPConnection();

/* ========== 4. HTTP Client ========== */

var httpClient = new $.net.http.Client();

/* ========== 1. Retrieving Web Request Body ========== */

var webRequestBody11 = webRequestBody1.asArrayBuffer();
var webRequestBody12 = webRequestBody1.asString();
var webRequestBody13 = webRequestBody1.asWebRequest();

var webRequestBody21 = webRequestBody2.asArrayBuffer();
var webRequestBody22 = webRequestBody2.asString();
var webRequestBody23 = webRequestBody2.asWebRequest();

/* ========== 2. Retrieving Web Request Parameter Value ========== */

var webRequestParam11 = webRequestParam1.get("key");
var webRequestParam12 = webRequestParam1.key;

var webRequestParam11 = webRequestParam2.get("key");
var webRequestParam12 = webRequestParam2.key;

/* ========== 3. Receiving Response through HTTPClient ========== */

var inboundResponse = httpClient.getReponse();

var inboundResponseBody1 = inboundResponse.body;
var inboundResponseBody2 = inboundResponse.body.asArrayBuffer();
var inboundResponseBody3 = inboundResponse.body.asString();
var inboundResponseBody4 = inboundResponse.body.asWebRequest();

var inboundResponseData1 = inboundResponse.cacheControl;
var inboundResponseData2 = inboundResponse.contentType;
var inboundResponseData3 = inboundResponse.cookies;
var inboundResponseData4 = inboundResponse.entities;
var inboundResponseData5 = inboundResponse.headers;
var inboundResponseData6 = inboundResponse.status;
