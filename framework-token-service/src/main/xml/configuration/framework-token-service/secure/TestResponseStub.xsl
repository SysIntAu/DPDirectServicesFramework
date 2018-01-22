<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<xsl:template match="/">
		<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<soapenv:Header>
				<wsse:Security soapenv:mustUnderstand="1" 
					xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
					<wsse:UsernameToken>
						<wsse:Username>chrisandtim</wsse:Username>
						<wsse:Password>password</wsse:Password>
					</wsse:UsernameToken>
				</wsse:Security>
			</soapenv:Header>
			<soapenv:Body>
				<aut:AuthResponse xmlns:aut="http://www.dpdirect.org/Namespace/MSG/Auth/V1.0"/>
			</soapenv:Body>
		</soapenv:Envelope>
	</xsl:template>
</xsl:stylesheet>
