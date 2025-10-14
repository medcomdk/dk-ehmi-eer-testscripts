Instance: AEER1CrudOrgTests
InstanceOf: TestScript
Title: "Test for AEER.1 - CRUD operations on Organization"
Description: "This test script performs CRUD operations on the Organization resource to validate compliance with AEER.1 requirements."
* insert Metadata(AEER1CrudOrgTests)
* insert EERMessagingOrganizationProfile
* insert OriginClient
* insert DestinationServer

* fixture[0]
  * id = "EERMessagingOrgWithoutEndpoint"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/Organization-EERMessagingOrgWithoutEndpointFixture.json)

* variable[0]
  * name = "EERMessagingOrgWithoutEndpointParamIdentifier"
  * expression = "identifier[0].value"
  * sourceId = "EERMessagingOrgWithoutEndpoint"

* setup
  * action[0].operation
    * type = $testscript-operation-codes#delete
    * resource = #Organization
    * description = "Delete operation to ensure the Organization does not exist on the server."
    * params = "?identifier=${EERMessagingOrgWithoutEndpointParamIdentifier}"
    * encodeRequestUrl = true
  * action[+].assert
    * description = "Confirm that the returned HTTP status is either 200(OK), 204(No Content) or 404(Not Found)."
    * operator = #in
    * responseCode = "200,204,404"
    * warningOnly = false

* test[0]
  * id = "CreateNewOrganization"
  * name = "CreateNewOrganization"
  * description = "Create a new EERMessagingOrganization in JSON format."
  * action[0].operation
    * type = $testscript-operation-codes#create
    * description = "Organization create operation with HTTP Header Accept and Content-Type set to JSON format."
    * contentType = #json
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * sourceId = "EERMessagingOrgWithoutEndpoint"
    * responseId = "CreatedOrganization"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 201(Created)."
    * direction = #response
    * response = #created
    * warningOnly = false

* variable[+]
  * name = "CreatedOrganizationId"
  * expression = "id"
  * sourceId = "CreatedOrganization"

* teardown
  * action[0].operation
    * type = $testscript-operation-codes#delete
    * resource = #Organization
    * description = "Delete the Organization instance."
    * encodeRequestUrl = true
    * destination = 1
    * origin = 1
    * params = "/${CreatedOrganizationId}"