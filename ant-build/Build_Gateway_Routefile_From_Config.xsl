<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:exslt="http://exslt.org/common"
	extension-element-prefixes="exslt" version="2.0">
	<!--========================================================================
		History:
		2016-11-01	v0.1	Tim Goodwill	Initial Version. 
		========================================================================-->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="yes" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:param name="SERVICE_CONFIG_FILE_PATH" select="''"/>
	<xsl:variable name="SERVICE_CONFIG_FILE_DOC" select="document($SERVICE_CONFIG_FILE_PATH)"/>
	<!--=============================================================-->
	<!-- BUILD WSPROXY SERVICE CONFIG FROM TEMPLATE                                -->
	<!--=============================================================-->
	<!-- Template to override the identity template for attributes -->
	<xsl:template match="ServiceRoute">
		<xsl:copy>
			<xsl:apply-templates select="node()"/>
			<xsl:for-each select="$SERVICE_CONFIG_FILE_DOC/ServiceConfig/OperationConfig/InputMatchCriteria">
				<InputMatchCriteria>
					<xsl:attribute name="refId">
						<xsl:value-of select="../@id"/>
					</xsl:attribute>
					<xsl:copy-of select="(Action | ../../InputMatchCriteria/Action)[1]"/>
					<xsl:copy-of select="(InboundURI | ../../InputMatchCriteria/InboundURI)[1]"/>
					<xsl:copy-of select="(HTTPPort | ../../InputMatchCriteria/HTTPPort)[1]"/>
					<xsl:copy-of select="(HTTPSPort | ../../InputMatchCriteria/HTTPSPort)[1]"/>
					<LocalHostAlias>
						<xsl:text>${localHostAlias}</xsl:text>
					</LocalHostAlias>
				</InputMatchCriteria>
			</xsl:for-each>
			<xsl:for-each select="$SERVICE_CONFIG_FILE_DOC/ServiceConfig/InputMatchCriteria">
				<xsl:if test="(HTTPPort | HTTPSPort) and (InboundURI | Action)">	
					<InputMatchCriteria>
						<xsl:attribute name="refId">
							<xsl:value-of select="substring-before(substring-after($SERVICE_CONFIG_FILE_PATH, 'config/'), '_ServiceConfig.xml')"/>
						</xsl:attribute>
						<xsl:copy-of select="*"/>
						<LocalHostAlias>
							<xsl:text>${localHostAlias}</xsl:text>
						</LocalHostAlias>
					</InputMatchCriteria>
				</xsl:if>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>
	<!-- Standard Identity template -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
