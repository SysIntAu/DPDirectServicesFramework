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

### Rapid, XML-Only Development ###
Typically, defining a new service consists of the following steps:

1) Service WSDLs (and referenced schemas, if any) are placed in the service-schema directory.

2) A service configuration is created for each WSDL, constrained by a service configuration schema, and can be built from a template. The service configuration will contain a relative path reference to the associated WSDL. Each service operation will be defined in the service config. Configuration for a particular operation may contain any number of optional steps, in any order, including transformation, schema validation, MTOM encoding and decoding, service calls and aggregation. A request configuration might look like the following:
~~~
<RequestPolicyConfig schemaValidate="true">
	<Transform>
		<Stylesheet>local:///framework-soa-esb/services/RetrieveSomething/V1.0/ChangeSomething.xsl</Stylesheet>
	</Transform>
	<BackendRouting provider="SomethingService">
		<HTTPEndpoint>
			<Address>${somethingHttpEndpoint}</Address>
		</HTTPEndpoint>
		<TimeoutSeconds>10</TimeoutSeconds>
	</BackendRouting>
</RequestPolicyConfig>
~~~
3) If transformation, aggregation etc is required, xslt stylesheet(s) are placed in the services directory, and referenced in the service config.

#### Assuming your environment variables (hostnames etc) have already beed defined, all that is left is build and deploy. ####

Use the pre-defined Verify Service as a WSDL and Service Configuration template, and explore the ServiceConfig schema, or a schema aware editor to discover supported service chain operations.

### Multi-Protocol Gateway ###

Optionally deploy a multi-tenancy aware Multi-Protocol Gateway to enable service invocation via MQ, SFTP etc, or to provide mediation services to XML consumers that are not SOAP aware. The gateway is configuration free - and is created at build-time from the information contained in existing service WSDLs and configuration files.

### API Gateway: Present an JSON/REST Service Facade ###

Optionally deploy a fast, lightwieight API gateway to provide a AAA protected JSON/REST API interface to services. The API Gateway supports several authentication and authorization schemas, and is readily extensible to integrate in any way you need it to.

### Build and Deploy ###

The project provides Maven and Ant build configurations, and may be deployed via a dedicated ant task, or via any script capable of command-line execution. Example scripts are provided. For more details on the DPDirect command-line and ant-task utility, see the aligned DPDirect project at https://github.com/SysIntAu/dpdirect.

---------------------------------------------



This project is currently under active development. This page, and accompanying guides, will be augmented. admin@sysint.com.au
