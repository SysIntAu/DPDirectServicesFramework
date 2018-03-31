<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
	<title>A Schematron Schema to assert valid pre-deployment cotent in instances of DPDIRECT ESB_Services (DataPower)
		properties files.</title>
	<pattern>
		<!-- Assert non-empty value of properties in ALL Environments -->
		<rule context="PropertiesList">
			<!-- Assert non-empty value of the 'dpdirect://envName' property -->
			<assert test="normalize-space((Property[@key='dpdirect://envName']/@value)[1]) != ''">Missing or empty
				'dpdirect://envName' property value.</assert>
		</rule>
	</pattern>
	<pattern>
		<!-- Assert non-empty value of properties in Environments E4-E9 -->
		<rule context="PropertiesList[normalize-space((Property[@key='dpdirect://envName']/@value)[1]) =
			('E3','E4','E5','E6','E7','E8','E9')]">
			<!-- Assert non-empty value of the 'dpdirect://logging/successLog/putUrl/1' property -->
			<assert test="normalize-space((Property[@key='dpdirect://logging/successLog/putUrl/1']/@value)[1]) != ''"
				>Missing or empty 'dpdirect://logging/errorLog/putUrl/1' property value.</assert>
			<!-- Assert non-empty value of the 'dpdirect://logging/errorLog/putUrl/1' property -->
			<assert test="normalize-space((Property[@key='dpdirect://logging/errorLog/putUrl/1']/@value)[1]) != ''"
				>Missing or empty 'dpdirect://logging/errorLog/putUrl/1' property value.</assert>
		</rule>
	</pattern>
</schema>