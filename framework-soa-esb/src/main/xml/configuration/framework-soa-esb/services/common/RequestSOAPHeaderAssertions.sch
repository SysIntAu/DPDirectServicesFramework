<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt">
	<title>A Schematron Schema for assertion of SOAP header fields.</title>
	<ns uri="http://schemas.xmlsoap.org/soap/envelope/" prefix="soap"/>
	<ns uri="http://www.w3.org/2005/08/addressing" prefix="wsa"/>
	<ns uri="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
		prefix="wsse"/>
	<pattern>
		<rule context="soap:Header">
			<assert test="normalize-space(wsse:security/wsse:UsernameToken/wsse:Username) != ''">The
				request 'soap:Header' must have a valid
				'wsse:security/wsse:UsernameToken/wsse:Username' descendant element.</assert>
		</rule>
	</pattern>
</schema>
