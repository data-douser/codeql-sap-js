var requestParameters = $.request.parameters;

function requestParameterHandler(requestParameters) {
  return "<div>" + requestParameters + "</div>";
}

/**
 * True positive case: content type is "text/html", a scriptable type
 */
function test1(requestParameters) {
  let someParameterValue1 = requestParameters.get("someParameter1");
  $.response.contentType = "text/html";
  $.response.setBody(requestParameterHandler(someParameterValue1));
  $.response.status = $.net.http.OK;
}

/**
 * False positive case: content type is "text/plain"
 */
function test2(requestParameters) {
  let someParameterValue2 = requestParameters.get("someParameter2");
  $.response.contentType = "text/plain";
  $.response.setBody(requestParameterHandler(someParameterValue2));
  $.response.status = $.net.http.OK;
}

/**
 * False positive case: content type is not set
 */
function test3(requestParameters) {
  let someParameterValue3 = requestParameters.get("someParameter3");
  $.response.setBody(requestParameterHandler(someParameterValue3));
  $.response.status = $.net.http.OK;
}

test1(requestParameters);
test2(requestParameters);
test3(requestParameters);
