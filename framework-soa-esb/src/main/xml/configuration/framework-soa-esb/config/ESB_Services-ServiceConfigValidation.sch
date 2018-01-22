<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
	<title>A Schematron Schema for assertion of cross-field constraints for denormalised instances
	of DPDIRECT ESB_Gateway (DataPower) configuration files.</title>
	<pattern>
		<title>Verifiying Configuration</title>
		<!--exiacd-->
<!--		<rule context="OperationConfig/RequestPolicyConfig/BackendRouting[@async = 'true']">
			<assert test="count(MQRouting/ReplyQueue) = 0">Async messaging must not specify a reply queue</assert>
		</rule>-->
	</pattern>
	<pattern>
		<title>Verifiying document refs</title>
		<rule context="Transform|Filter">
			<let name="LOCALISE_SCHEMA_DIR" value="replace(Stylesheet,'local:///service-schema','../service-schema')"/>
			<let name="LOCALISE_SERVICE_DIR" value="replace($LOCALISE_SCHEMA_DIR,'local:///ESB_Services','configuration/ESB_Services/src')"/>
			<let name="LOCAL_FILE" value="$LOCALISE_SERVICE_DIR"/>
			<assert test="unparsed-text-available(string($LOCAL_FILE))">
				The referenced file <value-of select="string($LOCAL_FILE)"/> was not found.</assert>
		</rule>
	</pattern>
	<pattern>
		<title>Verifiying document refs</title>
		<rule context="Validate">
			<let name="LOCALISE_SCHEMA_DIR" value="replace(Schema,'local:///service-schema','../service-schema')"/>
			<let name="LOCALISE_SERVICE_DIR" value="replace($LOCALISE_SCHEMA_DIR,'local:///ESB_Services','configuration/ESB_Services/src')"/>
			<let name="LOCAL_FILE" value="$LOCALISE_SERVICE_DIR"/>
			<assert test="unparsed-text-available(string($LOCAL_FILE))">
				The referenced file <value-of select="string($LOCAL_FILE)"/> was not found.</assert>
		</rule>
	</pattern>
</schema>

