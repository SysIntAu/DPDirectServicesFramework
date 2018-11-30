# Welcome to the DPDirect Services Framework

### Summary
The DPDirect Services Framework is an XML driven DataPower Web Services framework.
DataPower GUI familiartiy or domain knowledge is not essential. Service development is pure XML, requiring only an XML editor to develop:
- WSDL and XSD interfaces
- XML service configuration
- XSL stylesheet XML transformation

### Overview
The DPDirect Services Framework provides a robust, flexible service chain, enabling any number of optional and easily configurable processing steps in any order, including AAA, schema validation, XML-to-any transformation, MTOM encoding and decoding, and conditional service calls. The framework supports multiple transport protocols and data formats.


![Services1](https://github.com/mqsysadmin/DPDirectServicesFramework/blob/master/distribution/doc/images/xmlservices.png)

Typically, defining a new service consists of the following steps:

1) Service WSDLs and optional schemas are placed in the service-schema directory.

2) A service configuration is created for each WSDL, constrained by a service configuration schema, which can be built from a template. The service configuration will contain a relative path reference to the associated WSDL, and will define a unique port. Each service operation will be defined in the service config. A request configuration for a particular operation might look like the following:

~~~
<RequestPolicyConfig schemaValidate="true">
	<Transform>
		<Stylesheet>local:///framework-soa-esb/services/Verify/V1.0/DoSomething.xsl</Stylesheet>
	</Transform>
	<BackendRouting provider="VerfyService">
		<HTTPEndpoint>
			<Address>${verifyHttpEndpoint}</Address>
		</HTTPEndpoint>
		<TimeoutSeconds>10</TimeoutSeconds>
	</BackendRouting>
</RequestPolicyConfig>
~~~
3) If transformation, aggregation etc is required, xslt stylesheet(s) are placed in the services directory, and referenced in the service config.

Assuming your environment variables (hostnames etc) have already beed defined, all that is left is build and deploy.
---------------------------------------------
This project is currently under active development. This page, and accompanying guides, will be augmented. admin@sysint.com.au
