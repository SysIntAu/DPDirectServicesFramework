<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" version="1.0" exclude-result-prefixes="dp">
	<!--========================================================================
		Purpose:
		Named templates to perform local code lookups from xml code map documents
		
		History:
		2016-11-12	v0.1	N.A.		Initial Version.
		2016-03-20	v2.0	Tim Goodwill		Init Gateway  instance
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="THIS_PROVIDER_NAME" select="'MSG'"/>
	<xsl:variable name="ENT_MSG_CODES_DOC_NAME" select="'EnterpriseMessageCodes.xml'"/>
	<xsl:variable name="ENT_MSG_CODES_DOC"
		select="document(concat($DPDIRECT_SERVICES_ROOT_FOLDER, 'codemaps/',$ENT_MSG_CODES_DOC_NAME))"/>
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Gets an Enterprise Code value based on service name, provider code -->
	<xsl:template name="GetEnterpriseCodeMapEntry">
		<!-- Mandatory -->
		<xsl:param name="ERROR_CODE" select="''"/>
		<!-- Optional -->
		<xsl:param name="SERVICE_NAME" select="''"/>
		<!-- Optional -->
		<xsl:param name="PROVIDER_NAME" select="'MSG'"/>
		<!-- create prioritsed Code Map Entry set -->
		<xsl:variable name="SERVICE_INSTANCES">
			<xsl:copy-of select="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[Service = $SERVICE_NAME]"/>
		</xsl:variable>
		<xsl:variable name="CODE_MAP_ENTRY">
			<!-- Attempt lookup -->
			<xsl:choose>
				<xsl:when test="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =      $ERROR_CODE and Provider =
					$PROVIDER_NAME and Service = $SERVICE_NAME]">
					<xsl:copy-of select="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =       $ERROR_CODE and
						Provider = $PROVIDER_NAME and Service = $SERVICE_NAME]"/>
				</xsl:when>
				<xsl:when test="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =      $ERROR_CODE and Provider =
					$PROVIDER_NAME and Service = '*']">
					<xsl:copy-of select="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =       $ERROR_CODE and
						Provider = $PROVIDER_NAME and Service = '*']"/>
				</xsl:when>
				<xsl:when test="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =      $ERROR_CODE and Provider =
					'*' and Service = $SERVICE_NAME]">
					<xsl:copy-of select="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =       $ERROR_CODE and
						Provider = '*' and Service = $SERVICE_NAME]"/>
				</xsl:when>
				<xsl:when test="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =      $ERROR_CODE and Provider =
					'*' and Service = '*']">
					<xsl:copy-of select="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =       $ERROR_CODE and
						Provider = '*' and Service = '*']"/>
				</xsl:when>
				<xsl:when test="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =      $ERROR_CODE and Service =
					$SERVICE_NAME]">
					<xsl:copy-of select="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =       $ERROR_CODE and
						Service = $SERVICE_NAME]"/>
				</xsl:when>
				<xsl:when test="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =      $ERROR_CODE and Service =
					'*']">
					<xsl:copy-of select="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =       $ERROR_CODE and
						Service = '*']"/>
				</xsl:when>
				<xsl:when test="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[ProviderCode =      $ERROR_CODE and Provider =
					$PROVIDER_NAME and Service = $SERVICE_NAME]">
					<xsl:copy-of select="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[ProviderCode =       $ERROR_CODE and
						Provider = $PROVIDER_NAME and Service = $SERVICE_NAME]"/>
				</xsl:when>
				<xsl:when test="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[ProviderCode =      $ERROR_CODE and Provider =
					$PROVIDER_NAME and Service = '*']">
					<xsl:copy-of select="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[ProviderCode =       $ERROR_CODE and
						Provider = $PROVIDER_NAME and Service = '*']"/>
				</xsl:when>
				<xsl:when test="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[ProviderCode =      $ERROR_CODE and Provider =
					'*' and (Service = $SERVICE_NAME or Service = '*')]">
					<xsl:copy-of select="$ENT_MSG_CODES_DOC/Worksheet/Table/Row[ProviderCode =       $ERROR_CODE and
						Provider = '*' and (Service = $SERVICE_NAME or Service = '*')]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="($ENT_MSG_CODES_DOC/Worksheet/Table/Row[EnterpriseCode =        'ENTR00001' and
						(Service = '*')])[1]"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="not($CODE_MAP_ENTRY/*)">
			<xsl:call-template name="WriteSysLogWarnMsg">
				<xsl:with-param name="MSG">
					<xsl:text>No code map entry located for ERROR_CODE~'</xsl:text>
					<xsl:value-of select="$ERROR_CODE"/>
					<xsl:text>' SERVICE_NAME~'</xsl:text>
					<xsl:value-of select="$SERVICE_NAME"/>
					<xsl:text>' CODEMAP_NAME~'</xsl:text>
					<xsl:value-of select="$ENT_MSG_CODES_DOC_NAME"/>
					<xsl:text>'.</xsl:text>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:copy-of select="$CODE_MAP_ENTRY"/>
	</xsl:template>
</xsl:stylesheet>
