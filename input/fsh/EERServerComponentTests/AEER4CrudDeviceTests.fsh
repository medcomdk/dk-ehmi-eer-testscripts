RuleSet: AEER4CrudDeviceTests(xmlOrJson)
* insert Metadata(AEER4CrudDeviceTests-{xmlOrJson})
// TODO: Check if we even need these profiles since we aren't validating any resources?
* insert EERMessagingDeviceAPProfile
* insert EERMessagingDeviceEUAProfile
* insert EERMessagingDeviceMSHProfile
* insert OriginClient
* insert DestinationServer

* fixture[+]
  * id = "DeviceDefinitionCreateFixture"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/DeviceDefinitionCreateFixture.{xmlOrJson})

* fixture[+]
  * id = "DeviceCreateFixture"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/DeviceCreateFixture.{xmlOrJson})

* fixture[+]
  * id = "DeviceUpdateFixture"
  * autocreate = false
  * autodelete = false
  * resource = Reference(./Fixtures/DeviceUpdateFixture.{xmlOrJson})

* variable[+]
  * name = "DeviceCreateParamIdentifier"
  * expression = "identifier[0].value"
  * sourceId = "DeviceCreateFixture"

* setup
  * action[+].operation
    * type = $testscript-operation-codes#delete
    * resource = #Endpoint
    * description = "Delete operation to ensure the Device does not exist on the server."
    * params = "?identifier=${DeviceCreateParamIdentifier}"
    * encodeRequestUrl = true
    * accept = #{xmlOrJson}
  * action[+].assert
    * description = "Confirm that the returned HTTP status is either 200(OK), 204(No Content) or 404(Not Found)."
    * operator = #in
    * responseCode = "200,204,404"
    * warningOnly = false
  * action[+].operation
    * type = $testscript-operation-codes#create
    * description = "DeviceDefinition create operation."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * sourceId = "DeviceDefinitionCreateFixture"
    * responseId = "CreatedDeviceDefinition"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is either 201(Created)"
    * response = #created
    * warningOnly = false

* variable[+]
    * name = "CreatedDeviceDefinitionId"
    * expression = "id"
    * sourceId = "CreatedDeviceDefinition"

* test[+]
  * id = "CreateNewDevice"
  * name = "CreateNewDevice"
  * description = "Create a new EerDevice."
  * action[+].operation
    * type = $testscript-operation-codes#create
    * description = "Device create operation"
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * sourceId = "DeviceCreateFixture"
    * responseId = "CreatedDevice"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 201(Created)."
    * direction = #response
    * response = #created
    * warningOnly = false

* variable[+]
  * name = "CreatedDeviceId"
  * expression = "id"
  * sourceId = "CreatedDevice"

* test[+]
  * id = "UpdateDevice"
  * name = "UpdateDevice"
  * description = "Update an existing EerDevice."
  * action[+].operation
    * type = $testscript-operation-codes#update
    * description = "Device update operation."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * params = "/${CreatedDeviceId}"
    * sourceId = "DeviceUpdateFixture"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false

* test[+]
  * id = "DeleteDevice"
  * name = "DeleteDevice"
  * description = "Delete an existing EerDevice"
  * action[+].operation
    * type = $testscript-operation-codes#delete
    * description = "Device delete operation."
    * contentType = #{xmlOrJson}
    * accept = #{xmlOrJson}
    * destination = 1
    * encodeRequestUrl = true
    * origin = 1
    * params = "/${CreatedDeviceId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(Ok)."
    * direction = #response
    * response = #okay
    * warningOnly = false

Instance: AEER4CrudDeviceTestsJson
InstanceOf: TestScript
Title: "Test for AEER.4 - CRUD operations on Device JSON format"
Description: "This test script performs CRUD operations on the Device resource to validate compliance with AEER.4 requirements. JSON format."
* insert AEER4CrudDeviceTests(json)

Instance: AEER2CrudDeviceTestsXml
InstanceOf: TestScript
Title: "Test for AEER.4 - CRUD operations on Device XML format"
Description: "This test script performs CRUD operations on the Device resource to validate compliance with AEER.4 requirements. XML format."
* insert AEER2CrudEndpointTests(xml)

// TODO: Talk with Ole about deleting the EERDeviceDefinition and deleting the AP, EUA, MSH Device StructureDefinition and just use the type element instead
Instance: DeviceDefinitionCreateFixture
InstanceOf: DeviceDefinition
* insert OverrideGeneratedFileNameHelper(DeviceDefinitionCreateFixture)
* deviceName
    * name = "TestDevice"
    * type = #user-friendly-name

Instance: DeviceCreateFixture
InstanceOf: EerDeviceAP
* insert OverrideGeneratedFileNameHelper(DeviceCreateFixture)
* identifier.value = "CreateEerDeviceAP-TouchstoneTestAP"
* definition = "DeviceDefinition/TouchstoneHelper-DS-CBS-CreatedDeviceDefinitionId-CBE"
* status = #active
* deviceName.name = "TestAPDevice"
* deviceName.type = #manufacturer-name
* manufacturer = "TouchStoneTest"

Instance: DeviceUpdateFixture
InstanceOf: EerDeviceAP
* insert IdTouchstoneVariable(CreatedDeviceId)
* insert OverrideGeneratedFileNameHelper(DeviceUpdateFixture)
* identifier.value = "UpdateEerDeviceAP-TouchstoneTestAP"
* definition = "DeviceDefinition/TouchstoneHelper-DS-CBS-CreatedDeviceDefinitionId-CBE"
* status = #active
* deviceName.name = "TestAPDevice"
* deviceName.type = #manufacturer-name
* manufacturer = "TouchStoneTest"