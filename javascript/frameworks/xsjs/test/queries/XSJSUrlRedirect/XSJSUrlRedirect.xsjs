var requestParameters = $.request.parameters;

/**
 * True positive case: `location` header set to a remote value.
 */
function test1(requestParameters) {
  let someParameterValue = requestParameters.get("someParameter");
  $.response.status = $.net.http.OK;
  $.response.headers.set("location", someParameterValue);
}

/**
 * False positive case: `Content-Type` header set to a remote value.
 */
function test2(requestParameters) {
  let someParameterValue = requestParameters.get("someParameter");
  $.response.status = $.net.http.OK;
  $.response.headers.set("Content-Type", someParameterValue);
}

test1(requestParameters);
test2(requestParameters);
