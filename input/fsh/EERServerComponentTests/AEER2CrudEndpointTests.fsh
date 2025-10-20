RuleSet: AEER2CrudEndpointTests(xmlOrJson)
* insert Metadata(AEER2CrudEndpointTests-{xmlOrJson})
// TODO: Since we aren't validating any resources do we even need this profile to be included?
* insert EERMessagingEndpointEdeliveryProfile
* insert OriginClient
* insert DestinationServer

* fixture[+]
  * id = "OrgCreate"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/OrgCreateFixture.{xmlOrJson})

* fixture[+]
  * id = "EndpointCreate"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/EndpointCreateFixture.{xmlOrJson})

* fixture[+]
  * id = "EndpointUpdate"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/EndpointUpdateFixture.{xmlOrJson})

* variable[+]
  * name = "EndpointCreateParamIdentifier"
  * expression = "identifier[0].value"
  * sourceId = "EndpointCreate"

* setup
  * action[+].operation
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
  * action[+].operation
    * type = $testscript-operation-codes#create
    * description = "Organization create operation."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * sourceId = "OrgCreate"
    * responseId = "CreatedOrganization"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is either 201(Created)"
    * response = #created
    * warningOnly = false

* variable[+]
  * name = "CreatedOrganizationId"
  * expression = "id"
  * sourceId = "CreatedOrganization"

* test[+]
  * id = "CreateNewEndpoint"
  * name = "CreateNewEndpoint"
  * description = "Create a new EerEndpointMessagingEdeliveryFhir."
  * action[+].operation
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
  * action[+].operation
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
  * action[+].operation
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
Title: "Test for AEER.2 - CRUD operations on Endpoint JSON format"
Description: "This test script performs CRUD operations on the Endpoint resource to validate compliance with AEER.2 requirements. JSON format."
* insert AEER2CrudEndpointTests(json)

Instance: AEER2CrudEndpointTestsXml
InstanceOf: TestScript
Title: "Test for AEER.2 - CRUD operations on Endpoint XML format"
Description: "This test script performs CRUD operations on the Endpoint resource to validate compliance with AEER.2 requirements. XML format."
* insert AEER2CrudEndpointTests(xml)

Instance: EndpointCreateFixture
InstanceOf: EerEndpointMessagingEdeliveryFhir
* insert OverrideGeneratedFileNameHelper(EndpointCreateFixture)
* identifier.value = "SomeTestGLNNumber"
* status = #test
* managingOrganization.reference = "Organization/TouchstoneHelper-DS-CBS-CreatedOrganizationId-CBE"
* period
  * start = "2025-01-01"
  * end = "2025-01-01"
* payloadType[+] = $EhmiMessageDefinitionUri#urn:dk:healthcare:medcom:messaging:fhir:structuredefinition:homecareobservation:1.1
* payloadMimeType[+] = #application/fhir+json
* address = "http://www.test.test/test"

Instance: EndpointUpdateFixture
InstanceOf: EerEndpointMessagingEdeliveryFhir
* insert IdTouchstoneVariable(CreatedEndpointId)
* insert OverrideGeneratedFileNameHelper(EndpointUpdateFixture)
* identifier.value = "SomeTestGLNNumber"
* status = #off
* managingOrganization.reference = "Organization/TouchstoneHelper-DS-CBS-CreatedOrganizationId-CBE"
* period
  * start = "2025-01-01"
  * end = "2025-01-01"
* payloadType[+] = $EhmiMessageDefinitionUri#urn:dk:healthcare:medcom:messaging:fhir:structuredefinition:homecareobservation:1.1
* payloadMimeType[+] = #application/fhir+json
* address = "http://www.test.test/test"
