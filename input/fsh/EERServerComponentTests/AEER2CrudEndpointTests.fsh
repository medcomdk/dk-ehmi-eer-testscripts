RuleSet: AEER2CrudEndpointTests(xmlOrJson)
* insert Metadata(AEER2CrudEndpointTests-{xmlOrJson})
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

* setup[+]
  * action[+].operation
    * type = $testscript-operation-codes#delete
    * description = "Delete operation to ensure the Endpoint does not exist on the server."
    * resource = #Endpoint
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "?identifier=${EndpointCreateParamIdentifier}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is either 200(OK), 204(No Content) or 404(Not Found)."
    * operator = #in
    * responseCode = "200,204,404"
    * warningOnly = false
  * action[+].operation
    * type = $testscript-operation-codes#create
    * description = "Organization create operation."
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
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
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
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
  * id = "ReadEndpoint"
  * name = "ReadEndpoint"
  * description = "Read the created EERMessagingEndpoint. To ensure AFSS.5 and AFSS.6 is possible."
  * action[+].operation
    * type = $testscript-operation-codes#read
    * description = "Endpoint read operation."
    * resource = #Endpoint
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "/${CreatedEndpointId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false
  * action[+].assert
    * description = "Validate that the read created endpoint conforms to the EerMessagingEndpointEDelivery profile."
    * direction = #response
    * validateProfileId = "eer-messaging-endpoint-edelivery"
    * warningOnly = false

* test[+]
  * id = "UpdateEndpoint"
  * name = "UpdateEndpoint"
  * description = "Update an existing EerEndpointMessagingEdeliveryFhir."
  * action[+].operation
    * type = $testscript-operation-codes#update
    * description = "Endpoint update operation."
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "/${CreatedEndpointId}"
    * sourceId = "EndpointUpdate"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false

* variable[+]
  * name = "UpdatedEndpointStatus"
  * expression = "status"
  * sourceId = "EndpointUpdate"

* test[+]
  * id = "ReadEndpointAfterUpdate"
  * name = "ReadEndpointAfterUpdate"
  * description = "Read the updated EERMessagingEndpoint. To ensure AFSS.5 and AFSS.6 is possible."
  * action[+].operation
    * type = $testscript-operation-codes#read
    * description = "Endpoint read operation after update."
    * resource = #Endpoint
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "/${CreatedEndpointId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false
  * action[+].assert
    * description = "Validate that the read created endpoint conforms to the EerMessagingEndpointEDelivery profile."
    * direction = #response
    * validateProfileId = "eer-messaging-endpoint-edelivery"
    * warningOnly = false
  * action[+].assert
    * description = "Validate that the updated status is as expected after update."
    * direction = #response
    * expression = "status"
    * operator = #equals
    * value = "${UpdatedEndpointStatus}"
    * warningOnly = false

* test[+]
  * id = "DeleteEndpoint"
  * name = "DeleteEndpoint"
  * description = "Delete an existing EerEndpointMessagingEdeliveryFhir."
  * action[+].operation
    * type = $testscript-operation-codes#delete
    * description = "Endpoint delete operation."
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "/${CreatedEndpointId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(Ok)."
    * direction = #response
    * response = #okay
    * warningOnly = false

* test[+]
  * id = "ReadEndpointAfterDelete"
  * name = "ReadEndpointAfterDelete"
  * description = "Read the deleted EERMessagingEndpoint. To ensure AFSS.5 and AFSS.6 is possible."
  * action[+].operation
    * type = $testscript-operation-codes#read
    * description = "Endpoint read operation after delete."
    * resource = #Endpoint
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "/${CreatedEndpointId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 404(Not Found)."
    * direction = #response
    * response = #notFound
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
