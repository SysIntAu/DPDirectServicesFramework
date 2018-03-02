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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" version="1.0" exclude-result-prefixes="dp wsse scm">
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///ESB_Services/framework/Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="INPUT_DOC" select="/"/>
	<xsl:variable name="REQ_SOAP_ENV" select="dp:variable($REQ_SOAP_ENV_VAR_NAME)"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="$REQ_SOAP_ENV/*">
				<xsl:apply-templates select="$REQ_SOAP_ENV" mode="restoreSoapEnv"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Log an error message -->
				<xsl:call-template name="WriteSysLogErrorMsg">
					<xsl:with-param name="MSG" select="'Failed to restore SOAP envelope. Null or empty request SOAP
						envelope.'"/>
				</xsl:call-template>
				<!-- Copy input to output -->
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Template to insert payload when restoring soap envelope -->
	<xsl:template match="soapenv:Body" mode="restoreSoapEnv">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:choose>
				<xsl:when test="$INPUT_DOC/soapenv:Envelope/soapenv:Body/*">
					<xsl:copy-of select="$INPUT_DOC/soapenv:Envelope/soapenv:Body/*"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$INPUT_DOC/*"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	<!-- Standard identity template -->
	<xsl:template match="node()|@*" mode="restoreSoapEnv">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="restoreSoapEnv"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
