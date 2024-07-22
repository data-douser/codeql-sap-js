var requestParameters = $.request.parameters;

/**
 * True positive case: Sink being `$.db.Connection.prepareStatement(query, arguments...)`,
 * the API in the older namespace. The remote value is concatenated raw into the query.
 */
function test1(requestParameters) {
  let someParameterValue1 = JSON.parse(requestParameters.get("someParameter1"));
  let someParameterValue2 = JSON.parse(requestParameters.get("someParameter2"));
  let query = "INSERT INTO " + someParameterValue1 + ".ENTITY (COL1) VALUES (" + someParameterValue2 + ")";
  
  let dbConnection = $.db.getConnection();
  let preparedStatement = dbConnection.prepareStatement(query);
  preparedStatement.executeUpdate();
  dbConnection.commit();
}

/**
 * True positive case: Sink being `$.hdb.Connection.executeQuery(query, arguments...)`,
 * the API in the newer namespace. The remote value is concatenated raw into the query.
 */
function test2(requestParameters) {
  let someParameterValue1 = JSON.parse(requestParameters.get("someParameter1"));
  let someParameterValue2 = JSON.parse(requestParameters.get("someParameter2"));
  let query = "INSERT INTO " + someParameterValue1 + " (COL1) VALUES (" + someParameterValue2 + ")";

  let dbConnection = $.db.getConnection();
  dbConnection.executeQuery(query);
  dbConnection.commit();
}

/**
 * False positive case: Sink being `$.db.Connection.prepareStatement(query, arguments...)`,
 * the API in the older namespace. The query is prepared by substituting values for placeholders.
 */
function test3(requestParameters) {
  let someParameterValue1 = JSON.parse(requestParameters.get("someParameter1"));
  let someParameterValue2 = JSON.parse(requestParameters.get("someParameter2"));
  let query = "INSERT INTO (?) (COL1) VALUES (?)";
  
  let dbConnection = $.db.getConnection();
  let preparedStatement = dbConnection.prepareStatement(query, someParameterValue1, someParameterValue2);
  preparedStatement.executeUpdate();
  dbConnection.commit();
}

/**
 * False positive case: Sink being `$.hdb.Connection.executeQuery(query, arguments...)`,
 * the API in the newer namespace. The query is prepared by substituting values for placeholders.
 */
function test4(requestParameters) {
  let someParameterValue1 = JSON.parse(requestParameters.get("someParameter1"));
  let someParameterValue2 = JSON.parse(requestParameters.get("someParameter2"));
  let query = "INSERT INTO (?) (COL1) VALUES (?)";

  let dbConnection = $.db.getConnection();
  dbConnection.executeQuery(query, someParameterValue1, someParameterValue2);
  dbConnection.commit();
}

test1(requestParameters);
test2(requestParameters);
test3(requestParameters);
test4(requestParameters);
