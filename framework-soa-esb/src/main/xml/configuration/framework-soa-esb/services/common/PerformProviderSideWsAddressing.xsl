<?xml version="1.0" encoding="UTF-8"?>
	<!-- *****************************************************************
	*	Copyright 2016 SysInt Pty Ltd (Australia)
	*	
	*	Licensed under the Apache License, Version 2.0 (the "License");
	*	you may not use this file except in compliance with the License.
	*	You may obtain a copy of the License at
	*	
	*	    http://www.apache.org/licenses/LICENSE-2.0
	*	
	*	Unless required by applicable law or agreed to in writing, software
	*	distributed under the License is distributed on an "AS IS" BASIS,
	*	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	*	See the License for the specific language governing permissions and
	*	limitations under the License.
	**********************************************************************-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
	xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" version="1.0" exclude-result-prefixes="dp">
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///framework-soa-esb/framework/Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<!-- The DP transaction rule type ('request'|'response'|'error') -->
	<xsl:variable name="TX_RULE_TYPE" select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="soapenv:Header">
		<xsl:variable name="REQ_SOAP_ENV" select="dp:variable($REQ_SOAP_ENV_VAR_NAME)"/>
		<xsl:choose>
			<xsl:when test="$REQ_SOAP_ENV/*">
				<xsl:copy>
					<xsl:apply-templates select="@*"/>
					<xsl:choose>
						<!-- Apply to existing ws addressing headers -->
						<xsl:when test="*[namespace-uri() = 'http://www.w3.org/2005/08/addressing']">
							<xsl:apply-templates select="*[namespace-uri() = 'http://www.w3.org/2005/08/addressing']"
								mode="wsAddressing"/>
						</xsl:when>
						<!-- Otherwise apply to ws addressing headers from request -->
						<xsl:otherwise>
							<xsl:apply-templates select="$REQ_SOAP_ENV//*[namespace-uri() =
								'http://www.w3.org/2005/08/addressing']" mode="wsAddressing"/>
						</xsl:otherwise>
					</xsl:choose>
					<!-- Copy through other headers -->
					<xsl:apply-templates select="*[not(namespace-uri() = 'http://www.w3.org/2005/08/addressing')]"/>
				</xsl:copy>
			</xsl:when>
			<xsl:otherwise>
				<!-- Log an error message -->
				<xsl:call-template name="WriteSysLogErrorMsg">
					<xsl:with-param name="MSG" select="'Failed to perform provider side ws-addressing. Null or empty
						request SOAP envelope.'"/>
				</xsl:call-template>
				<!-- Copy input to output -->
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Handle wsa header elements -->
	<xsl:template match="*[namespace-uri() = 'http://www.w3.org/2005/08/addressing']" mode="wsAddressing">
		<xsl:choose>
			<xsl:when test="self::wsa:MessageID">
				<xsl:variable name="NEW_MSG_ID" select="dp:generate-uuid()"/>
				<xsl:copy>
					<xsl:value-of select="$NEW_MSG_ID"/>
				</xsl:copy>
				<!-- Store WSA message identifier -->
				<xsl:call-template name="StoreMsgIdentifier">
					<xsl:with-param name="TYPE" select="'WSA_MSG_ID'"/>
					<xsl:with-param name="APPLIES_TO" select="'RES'"/>
					<xsl:with-param name="IDENTIFIER_VALUE" select="string($NEW_MSG_ID)"/>
				</xsl:call-template>
				<wsa:RelatesTo>
					<xsl:value-of select="."/>
				</wsa:RelatesTo>
			</xsl:when>
			<xsl:when test="self::wsa:Action">
				<xsl:copy>
					<xsl:choose>
						<xsl:when test="$TX_RULE_TYPE = 'error'">
							<xsl:value-of select="concat(.,'/Fault/EnterpriseError')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat(.,'Response')"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:copy>
			</xsl:when>
			<xsl:otherwise>
				<!-- Do nothing -->
			</xsl:otherwise>
		</xsl:choose>
		<!-- Strip -->
	</xsl:template>
	<!-- Standard identity template -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
