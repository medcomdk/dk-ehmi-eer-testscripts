RuleSet: AEER1CrudOrgTests(xmlOrJson)
* insert Metadata(AEER1CrudOrgTests-{xmlOrJson})
// TODO: Since we aren't validating any resources do we even need this profile to be included?
* insert EERMessagingOrganizationProfile
* insert OriginClient
* insert DestinationServer

* fixture[+]
  * id = "OrgCreate"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/OrgCreateFixture.{xmlOrJson})

* fixture[+]
  * id = "OrgUpdate"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/OrgUpdateFixture.{xmlOrJson})

* variable[+]
  * name = "OrgCreateParamIdentifier"
  * expression = "identifier[0].value"
  * sourceId = "OrgCreate"

* setup
  * action[+].operation
    * type = $testscript-operation-codes#delete
    * resource = #Organization
    * description = "Delete operation to ensure the Organization does not exist on the server."
    * params = "?identifier=${OrgCreateParamIdentifier}"
    * encodeRequestUrl = true
    * accept = #{xmlOrJson}
  * action[+].assert
    * description = "Confirm that the returned HTTP status is either 200(OK), 204(No Content) or 404(Not Found)."
    * operator = #in
    * responseCode = "200,204,404"
    * warningOnly = false

* test[+]
  * id = "CreateNewOrganization"
  * name = "CreateNewOrganization"
  * description = "Create a new EERMessagingOrganization."
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
    * description = "Confirm that the returned HTTP status is 201(Created)."
    * direction = #response
    * response = #created
    * warningOnly = false

* variable[+]
  * name = "CreatedOrganizationId"
  * expression = "id"
  * sourceId = "CreatedOrganization"

* test[+]
  * id = "ReadOrganization"
  * name = "ReadOrganization"
  * description = "Read the created EERMessagingOrganization. To ensure AFSS.5 and AFSS.6 is possible."
  * action[+].operation
    * type = $testscript-operation-codes#read
    * description = "Organization read operation."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * resource = #Organization
    * params = "/${CreatedOrganizationId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false
  * action[+].assert
    * description = "Validate that the read created organization conforms to the EerMessagingOrganization profile."
    * direction = #response
    * validateProfile = $EerMessagingOrganizationProfile
    * warningOnly = false

* test[+]
  * id = "UpdateOrganization"
  * name = "UpdateOrganization"
  * description = "Update an existing EERMessagingOrganization."
  * action[+].operation
    * type = $testscript-operation-codes#update
    * description = "Organization update operation."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * params = "/${CreatedOrganizationId}"
    * sourceId = "OrgUpdate"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false

* variable[+]
  * name = "UpdatedOrganizationName"
  * expression = "name"
  * sourceId = "OrgUpdate"

* test[+]
  * id = "ReadOrganizationAfterUpdate"
  * name = "ReadOrganizationAfterUpdate"
  * description = "Read the updated EERMessagingOrganization"
  * action[+].operation
    * type = $testscript-operation-codes#read
    * description = "Organization read operation."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * resource = #Organization
    * params = "/${CreatedOrganizationId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false
  * action[+].assert
    * description = "Validate that the read organization conforms to the EerMessagingOrganization profile."
    * direction = #response
    * validateProfile = $EerMessagingOrganizationProfile
    * warningOnly = false
  * action[+].assert
    * description = "Validate that the read organization has the updated name."
    * direction = #response
    * expression = "name"
    * operator = #equals
    * value = "${UpdatedOrganizationName}"
    * warningOnly = false

* test[+]
  * id = "DeleteOrganization"
  * name = "DeleteOrganization"
  * description = "Delete an existing EERMessagingOrganization."
  * action[+].operation
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

* test[+]
  * id = "ReadOrganizationAfterDeletion"
  * name = "ReadOrganizationAfterDeletion"
  * description = "Try to read the deleted EERMessagingOrganization"
  * action[+].operation
    * type = $testscript-operation-codes#read
    * description = "Organization read operation after deletion."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * resource = #Organization
    * params = "/${CreatedOrganizationId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 404(Not Found)."
    * direction = #response
    * response = #notFound
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

Instance: OrgCreateFixture
InstanceOf: EerMessagingOrganization
* insert OverrideGeneratedFileNameHelper(OrgCreateFixture)
* name = "Lægerne Stjernepladsen I/S"
* identifier[SOR-ID].system = "urn:oid:1.2.208.176.1.1"
* identifier[SOR-ID].value = "543210987654321"
* type[SOR-Hierarchy].coding = $EerSorOrganizationTypeCS#IO

Instance: OrgUpdateFixture
InstanceOf: EerMessagingOrganization
* insert IdTouchstoneVariable(CreatedOrganizationId)
* insert OverrideGeneratedFileNameHelper(OrgUpdateFixture)
* name = "Updated Name - Lægerne Stjernepladsen I/S"
* identifier[SOR-ID].system = "urn:oid:1.2.208.176.1.1"
* identifier[SOR-ID].value = "543210987654321"
* type[SOR-Hierarchy].coding = $EerSorOrganizationTypeCS#IO
