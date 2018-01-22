<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions"
	version="1.0" extension-element-prefixes="dp">
	<xsl:import href="utils-saml.xsl"/>
	<xsl:variable name="FAILUREMODE" select="dp:variable('var://context/service/failuremode')"/>
	<dp:set-variable name="'var://service/error-protocol-response'" value="'200'"/>
	<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'OK'"/>
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="$FAILUREMODE = 'schema'">
				<xsl:call-template name="generateFault">
					<xsl:with-param name="FAULTCODE" select="'wst:invalidRequest'"/>
					<xsl:with-param name="FAULTSTRING" select="'The request was invalid or malformed'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$FAILUREMODE = 'authenticate'">
				<xsl:call-template name="generateFault">
					<xsl:with-param name="FAULTCODE" select="'wst:failedAuthentication'"/>
					<xsl:with-param name="FAULTSTRING" select="'Authentication failed'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$FAILUREMODE = 'authenticate nomsg_grps'">
				<xsl:call-template name="generateFault">
					<xsl:with-param name="FAULTCODE" select="'wst:failedAuthentication'"/>
					<xsl:with-param name="FAULTSTRING" select="'Authentication failed'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$FAILUREMODE = 'authenticate error'">
				<xsl:call-template name="generateFault">
					<xsl:with-param name="FAULTCODE" select="'soap:Client'"/>
					<xsl:with-param name="FAULTSTRING" select="'Authentication error'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="generateFault">
					<xsl:with-param name="FAULTCODE" select="'env:Client'"/>
					<xsl:with-param name="FAULTSTRING" select="'Unknown Error'"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:transform>
