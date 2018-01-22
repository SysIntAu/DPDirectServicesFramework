<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" exclude-result-prefixes="dp json"
	version="1.0">
	<!--========================================================================
		History:
		2016-10-03	v0.1			Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///SecureTokenService/common/Constants.xsl"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="JWT_TOKEN" select="dp:http-request-header($JWT_TOKEN_LABLE)"/>
	<!--========================================================================
		MATCH TEMPLATES
	========================================================================-->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="not(json:object) and ($JWT_TOKEN != '')">
				<json:object>
					<json:string name="{$JWT_TOKEN_LABLE}">
						<xsl:value-of select="$JWT_TOKEN"/>
					</json:string>
				</json:object>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
