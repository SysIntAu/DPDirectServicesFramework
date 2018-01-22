<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx"
	xmlns:date="http://exslt.org/dates-and-times" xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp"
	version="1.0">
	<xsl:template match="/">
		<dp:set-variable name="'var://service/set-response-header/content-type'" value="'application/json'"/>
		<json:object xsi:schemaLocation="http://www.datapower.com/schemas/json jsonx.xsd"
			xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<json:string name="status">failed</json:string>
		</json:object>
		<!-- CORS support -->
		<dp:set-http-response-header name="'Access-Control-Allow-Origin'" value="'*'"/>
		<!-- Token 'Validate' error response -->
		<xsl:if test="not(contains(dp:variable('var://service/URI'), 'validate'))">
			<dp:set-variable name="'var://service/error-protocol-response'" value="'401'"/>
			<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Unauthorized'"/>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
