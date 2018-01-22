<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:otps-wst="http://www.rsasecurity.com/rsalabs/otps/schemas/2005/09/otps-wst#"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" version="1.0"
	exclude-result-prefixes="otps-wst wsse soap">
	<xsl:template match="/">
		<dp:set-variable name="'var://context/service/failuremode'" value="'authenticate'"/>
		<identity>
			<entry type="wssec-username">
				<username>
					<xsl:value-of select="dp:variable('var://context/service/RadiusUserName')"/>
				</username>
				<password type="" sanitize="true">
					<xsl:value-of select="dp:variable('var://context/service/RadiusPassword')"/>
				</password>
			</entry>
		</identity>
	</xsl:template>
</xsl:stylesheet>
