RuleSet: AEER1CrudOrgTests(xmlOrJson)
* insert Metadata(AEER1CrudOrgTests-{xmlOrJson})
* insert EERMessagingOrganizationProfile
* insert OriginClient
* insert DestinationServer

* fixture[0]
  * id = "AEER1OrgCreate"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/Organization-AEER1OrgCreateFixture.{xmlOrJson})

* fixture[+]
  * id = "AEER1OrgUpdate"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/Organization-AEER1OrgUpdateFixture.{xmlOrJson})

* variable[0]
  * name = "AEER1OrgCreateParamIdentifier"
  * expression = "identifier[0].value"
  * sourceId = "AEER1OrgCreate"

* setup
  * action[0].operation
    * type = $testscript-operation-codes#delete
    * resource = #Organization
    * description = "Delete operation to ensure the Organization does not exist on the server."
    * params = "?identifier=${AEER1OrgCreateParamIdentifier}"
    * encodeRequestUrl = true
    * accept = #{xmlOrJson}
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
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * sourceId = "AEER1OrgCreate"
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

* test[+]
  * id = "UpdateOrganization"
  * name = "UpdateOrganization"
  * description = "Update an existing EERMessagingOrganization in JSON format."
  * action[0].operation
    * type = $testscript-operation-codes#update
    * description = "Organization update operation with json content."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * params = "/${CreatedOrganizationId}"
    * sourceId = "AEER1OrgUpdate"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false

* test[+]
  * id = "DeleteOrganization"
  * name = "DeleteOrganization"
  * description = "Delete an existing EERMessagingOrganization in JSON format."
  * action[0].operation
    * type = $testscript-operation-codes#delete
    * description = "Organization delete operation."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * params = "/${CreatedOrganizationId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(Ok)."
    * direction = #response
    * response = #okay
    * warningOnly = false

Instance: AEER1CrudOrgTestsJson
InstanceOf: TestScript
Title: "Test for AEER.1 - CRUD operations on Organization JSON format"
Description: "This test script performs CRUD operations on the Organization resource to validate compliance with AEER.1 requirements. JSON format."
* insert AEER1CrudOrgTests(json)

Instance: AEER1CrudOrgTestsXml
InstanceOf: TestScript
Title: "Test for AEER.1 - CRUD operations on Organization XML format"
Description: "This test script performs CRUD operations on the Organization resource to validate compliance with AEER.1 requirements. XML format."
* insert AEER1CrudOrgTests(xml)

Instance: AEER1OrgCreateFixture
InstanceOf: EerMessagingOrganization
* name = "Lægerne Stjernepladsen I/S"
* identifier[SOR-ID].system = "urn:oid:1.2.208.176.1.1"
* identifier[SOR-ID].value = "543210987654321"
* type[SOR-Hierarchy].coding = $EerSorOrganizationTypeCS#IO

Instance: AEER1OrgUpdateFixture
InstanceOf: EerMessagingOrganization
* insert IdWithoutAffectingGeneratedFileName(CreatedOrganizationId, Organization-AEER1OrgUpdateFixture)
* name = "Updated Name - Lægerne Stjernepladsen I/S"
* identifier[SOR-ID].system = "urn:oid:1.2.208.176.1.1"
* identifier[SOR-ID].value = "543210987654321"
* type[SOR-Hierarchy].coding = $EerSorOrganizationTypeCS#IO
