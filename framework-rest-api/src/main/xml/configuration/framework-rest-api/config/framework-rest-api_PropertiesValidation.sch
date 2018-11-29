<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
	<title>A Schematron Schema to assert valid pre-deployment cotent in instances of DPDIRECT API_Services (DataPower)
		properties files.</title>
	<pattern>
		<!-- Assert non-empty value of properties in ALL Environments -->
		<rule context="PropertiesList">
			<!-- Assert non-empty value of the 'dpdirect://envName' property -->
			<assert test="normalize-space((Property[@key='dpdirect://envName']/@value)[1]) != ''">Missing or empty
				'dpdirect://envName' property value.</assert>
		</rule>
	</pattern>
</schema>