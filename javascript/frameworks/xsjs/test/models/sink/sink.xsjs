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

webResponse1.setBody(code0);
webResponse2.setBody(code0);