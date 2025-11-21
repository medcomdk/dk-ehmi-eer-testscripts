RuleSet: Server-AEER4CrudDeviceTests(xmlOrJson)
* insert Metadata(Server-AEER4CrudDeviceTests-{xmlOrJson})
* insert EERMessagingDeviceAPProfile
* insert OriginClient
* insert DestinationServer

* fixture[+]
  * id = "DeviceCreateFixture"
  * autocreate = false
  * autodelete = false
  * resource.reference = "../Fixtures/DeviceCreateFixture.{xmlOrJson}"

* fixture[+]
  * id = "DeviceUpdateFixture"
  * autocreate = false
  * autodelete = false
  * resource.reference = "../Fixtures/DeviceUpdateFixture.{xmlOrJson}"

* variable[+]
  * name = "DeviceCreateParamIdentifier"
  * expression = "identifier[0].value"
  * sourceId = "DeviceCreateFixture"

* setup[+]
  * action[+].operation
    * type = $testscript-operation-codes#delete
    * description = "Delete operation to ensure the Device does not exist on the server."
    * resource = #Device
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

* test[+]
  * id = "CreateNewDevice"
  * name = "CreateNewDevice"
  * description = "Create a new EerDevice."
  * action[+].operation
    * type = $testscript-operation-codes#create
    * description = "Device create operation"
    * resource = #Device
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


Instance: Server-AEER4CrudDeviceTestsJson
InstanceOf: TestScript
Title: "Test for AEER.4 - CRUD operations on Device JSON format"
Description: "This test script performs CRUD operations on the Device resource to validate compliance with AEER.4 requirements. JSON format."
* insert Server-AEER4CrudDeviceTests(json)

Instance: Server-AEER4CrudDeviceTestsXml
InstanceOf: TestScript
Title: "Test for AEER.4 - CRUD operations on Device XML format"
Description: "This test script performs CRUD operations on the Device resource to validate compliance with AEER.4 requirements. XML format."
* insert Server-AEER4CrudDeviceTests(xml)

Instance: DeviceCreateFixture
InstanceOf: EerDevice
* insert OverrideGeneratedFileNameHelper(DeviceCreateFixture)
* identifier.value = "CreateEerDeviceAP-TouchstoneTestAP"
* status = #active
* deviceName.name = "TestAPDevice"
* deviceName.type = #manufacturer-name
* manufacturer = "TouchStoneTest"
* type = $EERDeviceTypeCS#AP

Instance: DeviceUpdateFixture
InstanceOf: EerDevice
* insert IdTouchstoneVariable(CreatedDeviceId)
* insert OverrideGeneratedFileNameHelper(DeviceUpdateFixture)
* identifier.value = "UpdateEerDeviceAP-TouchstoneTestAP"
* status = #active
* deviceName.name = "Updated TestAPDevice"
* deviceName.type = #manufacturer-name
* manufacturer = "TouchStoneTest"
* type = $EERDeviceTypeCS#AP