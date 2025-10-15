RuleSet: AEER2CrudEndpointTests(xmlOrJson)
* insert Metadata(AEER2CrudEndpointTests-{xmlOrJson})
* insert EERMessagingEndpointEdeliveryProfile
* insert OriginClient
* insert DestinationServer

* fixture[0]
  * id = "EndpointCreate"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/Endpoint-AEER2EndpointCreateFixture.{xmlOrJson})

* fixture[+]
  * id = "EndpointUpdate"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/Endpoint-AEER2EndpointUpdateFixture.{xmlOrJson})

* variable[0]
  * name = "EndpointCreateParamIdentifier"
  * expression = "identifier[0].value"
  * sourceId = "EndpointCreate"

* setup
  * action[0].operation
    * type = $testscript-operation-codes#delete
    * resource = #Endpoint
    * description = "Delete operation to ensure the Endpoint does not exist on the server."
    * params = "?identifier=${EndpointCreateParamIdentifier}"
    * encodeRequestUrl = true
    * accept = #{xmlOrJson}
  * action[+].assert
    * description = "Confirm that the returned HTTP status is either 200(OK), 204(No Content) or 404(Not Found)."
    * operator = #in
    * responseCode = "200,204,404"
    * warningOnly = false

* test[0]
  * id = "CreateNewEndpoint"
  * name = "CreateNewEndpoint"
  * description = "Create a new EerEndpointMessagingEdeliveryFhir."
  * action[0].operation
    * type = $testscript-operation-codes#create
    * description = "Endpoint create operation"
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * sourceId = "EndpointCreate"
    * responseId = "CreatedEndpoint"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 201(Created)."
    * direction = #response
    * response = #created
    * warningOnly = false

* variable[+]
  * name = "CreatedEndpointId"
  * expression = "id"
  * sourceId = "CreatedEndpoint"

* test[+]
  * id = "UpdateEndpoint"
  * name = "UpdateEndpoint"
  * description = "Update an existing EerEndpointMessagingEdeliveryFhir."
  * action[0].operation
    * type = $testscript-operation-codes#update
    * description = "Endpoint update operation."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * params = "/${CreatedEndpointId}"
    * sourceId = "EndpointUpdate"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false

* test[+]
  * id = "DeleteEndpoint"
  * name = "DeleteEndpoint"
  * description = "Delete an existing EerEndpointMessagingEdeliveryFhir."
  * action[0].operation
    * type = $testscript-operation-codes#delete
    * description = "Endpoint delete operation."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * params = "/${CreatedEndpointId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(Ok)."
    * direction = #response
    * response = #okay
    * warningOnly = false

Instance: AEER2CrudEndpointTestsJson
InstanceOf: TestScript
Title: "Test for AEER.1 - CRUD operations on Endpoint JSON format"
Description: "This test script performs CRUD operations on the Endpoint resource to validate compliance with AEER.1 requirements. JSON format."
* insert AEER2CrudEndpointTests(json)

Instance: AEER2CrudEndpointTestsXml
InstanceOf: TestScript
Title: "Test for AEER.1 - CRUD operations on Endpoint XML format"
Description: "This test script performs CRUD operations on the Endpoint resource to validate compliance with AEER.1 requirements. XML format."
* insert AEER2CrudEndpointTests(xml)

Instance: AEER2EndpointCreateFixture
InstanceOf: EerEndpointMessagingEdeliveryFhir
* identifier.value = "SomeTestGLNNumber"
* status = #test
* managingOrganization.identifier.value = "aNonExistantOrganizationIdForTestPurposesOnly"
* period
  * start = "2025-01-01"
  * end = "2025-01-01"
* payloadType[+] = $EhmiMessageDefinitionUri#urn:dk:healthcare:medcom:messaging:fhir:structuredefinition:homecareobservation:1.1
* payloadMimeType[+] = #application/fhir+json
* address = "http://www.test.test/test"

Instance: AEER2EndpointUpdateFixture
InstanceOf: EerEndpointMessagingEdeliveryFhir
* insert IdWithoutAffectingGeneratedFileName(CreatedEndpointId, Endpoint-AEER2EndpointUpdateFixture)
* identifier.value = "SomeTestGLNNumber"
* status = #off
* managingOrganization.identifier.value = "aNonExistantOrganizationIdForTestPurposesOnly"
* period
  * start = "2025-01-01"
  * end = "2025-01-01"
* payloadType[+] = $EhmiMessageDefinitionUri#urn:dk:healthcare:medcom:messaging:fhir:structuredefinition:homecareobservation:1.1
* payloadMimeType[+] = #application/fhir+json
* address = "http://www.test.test/test"
