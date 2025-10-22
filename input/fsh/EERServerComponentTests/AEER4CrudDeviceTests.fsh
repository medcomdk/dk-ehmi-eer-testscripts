RuleSet: AEER4CrudDeviceTests(xmlOrJson)
* insert Metadata(AEER4CrudDeviceTests-{xmlOrJson})
* insert EERMessagingDeviceAPProfile
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

* setup[+]
  * action[+].operation
    * type = $testscript-operation-codes#delete
    * description = "Delete operation to ensure the Device does not exist on the server."
    * resource = #Endpoint
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "?identifier=${DeviceCreateParamIdentifier}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is either 200(OK), 204(No Content) or 404(Not Found)."
    * operator = #in
    * responseCode = "200,204,404"
    * warningOnly = false

  * action[+].operation
    * type = $testscript-operation-codes#create
    * description = "DeviceDefinition create operation."
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
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
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
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
  * id = "ReadDevice"
  * name = "ReadDevice"
  * description = "Read the created EERDevice. To ensure AFSS.5 and AFSS.6 is possible."
  * action[+].operation
    * type = $testscript-operation-codes#read
    * description = "Device read operation."
    * resource = #Device
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "/${CreatedDeviceId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false
  * action[+].assert
    * description = "Validate that the read created endpoint conforms to the EERMessagingDeviceAP profile."
    * direction = #response
    * validateProfileId = "eer-messaging-device-ap"
    * warningOnly = false

* test[+]
  * id = "UpdateDevice"
  * name = "UpdateDevice"
  * description = "Update an existing EerDevice."
  * action[+].operation
    * type = $testscript-operation-codes#update
    * description = "Device update operation."
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "/${CreatedDeviceId}"
    * sourceId = "DeviceUpdateFixture"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false

* variable[+]
  * name = "UpdatedDeviceName"
  * expression = "deviceName.name"
  * sourceId = "DeviceUpdateFixture"

* test[+]
  * id = "ReadDeviceAfterUpdate"
  * name = "ReadDeviceAfterUpdate"
  * description = "Read the created EERDevice after update. To ensure AFSS.5 and AFSS.6 is possible."
  * action[+].operation
    * type = $testscript-operation-codes#read
    * description = "Device read operation after update."
    * resource = #Device
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "/${CreatedDeviceId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(OK)."
    * direction = #response
    * response = #okay
    * warningOnly = false
  * action[+].assert
    * description = "Validate that the read created endpoint conforms to the EERMessagingDeviceAP profile."
    * direction = #response
    * validateProfileId = "eer-messaging-device-ap"
    * warningOnly = false
  * action[+].assert
    * description = "Validate that the updated device name is updated."
    * direction = #response
    * expression = "deviceName.name"
    * operator = #equals
    * value = "${UpdatedDeviceName}"
    * warningOnly = false

* test[+]
  * id = "DeleteDevice"
  * name = "DeleteDevice"
  * description = "Delete an existing EerDevice"
  * action[+].operation
    * type = $testscript-operation-codes#delete
    * description = "Device delete operation."
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "/${CreatedDeviceId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 200(Ok)."
    * direction = #response
    * response = #okay
    * warningOnly = false

* test[+]
  * id = "ReadDeviceAfterDelete"
  * name = "ReadDeviceAfterDelete"
  * description = "Read the created EERDevice after delete. To ensure AFSS.5 and AFSS.6 is possible."
  * action[+].operation
    * type = $testscript-operation-codes#read
    * description = "Device read operation after delete."
    * resource = #Device
    * encodeRequestUrl = true
    * origin = 1
    * contentType = #{xmlOrJson}
    * destination = 1
    * accept = #{xmlOrJson}
    * params = "/${CreatedDeviceId}"
  * action[+].assert
    * description = "Confirm that the returned HTTP status is 404(Not Found)."
    * direction = #response
    * response = #notFound
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
* deviceName.name = "Updated TestAPDevice"
* deviceName.type = #manufacturer-name
* manufacturer = "TouchStoneTest"