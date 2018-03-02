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
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" version="1.0" exclude-result-prefixes="dp wsa wsse">
	<!--========================================================================
		Purpose:
		Ensure response addressing adheres to general Gateway  response policy as defined in the service WSDL.
				
		History:
		2016-12-12	v1.0	Tim Goodwill		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="INPUT_DOC" select="/"/>
	<xsl:variable name="MSG_PAYLOAD">
		<xsl:choose>
			<xsl:when test="/*[local-name() = 'Envelope']/*[local-name() = 'Body']/*[1]">
				<xsl:copy-of  select="/*[local-name() = 'Envelope']/*[local-name() = 'Body']/*[1]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of  select="/*[1]"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="TX_RULE_TYPE" select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
	<xsl:variable name="REQ_WSA_MSG_ID" select="normalize-space(dp:variable($REQ_WSA_MSG_ID_VAR_NAME))"/>
	<xsl:variable name="REQ_WSA_RELATES_TO" select="normalize-space(dp:variable($REQ_WSA_RELATES_TO_VAR_NAME))"/>
	<xsl:variable name="REQ_WSA_REPLY_TO" select="normalize-space(dp:variable($REQ_WSA_REPLY_TO_VAR_NAME))"/>
	<xsl:variable name="REQ_WSA_FAULT_TO" select="normalize-space(dp:variable($REQ_WSA_FAULT_TO_VAR_NAME))"/>
	<xsl:variable name="RES_WSA_MSG_ID" select="normalize-space(dp:variable($RES_WSA_MSG_ID_VAR_NAME))"/>
	<xsl:variable name="RES_WSA_RELATES_TO" select="normalize-space(dp:variable($RES_WSA_RELATES_TO_VAR_NAME))"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:variable name="REQ_SOAP_ENV" select="dp:variable($REQ_SOAP_ENV_VAR_NAME)"/>
		<xsl:choose>
			<xsl:when test="*[local-name() = 'Envelope']/*[local-name() = 'Header']">
				<xsl:apply-templates select="*[local-name() = 'Envelope']"/>
			</xsl:when>
			<xsl:when test="$REQ_SOAP_ENV">
				<xsl:apply-templates select="$REQ_SOAP_ENV/*[local-name() = 'Envelope']"/>
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
	<xsl:template match="*[local-name() = 'Body']">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:copy-of select="$MSG_PAYLOAD"/>
		</xsl:copy>
	</xsl:template>
	<!-- Template to map reply ws addressing -->
	<xsl:template match="*[local-name() = 'Header']">
		<xsl:variable name="REQ_SOAP_ENV" select="dp:variable($REQ_SOAP_ENV_VAR_NAME)"/>
			<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates select="$REQ_SOAP_ENV/*[local-name() = 'Envelope']/*[local-name() = 'Header']/wsse:Security"/>
			<wsa:MessageID>
				<xsl:choose>
					<xsl:when test="($RES_WSA_MSG_ID != '')
						and ($RES_WSA_MSG_ID != $REQ_WSA_MSG_ID)">
						<xsl:value-of select="$RES_WSA_MSG_ID"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- New WSA MessageID -->
						<xsl:variable name="NEW_MSG_ID" select="dp:generate-uuid()"/>
						<xsl:value-of select="$NEW_MSG_ID"/>
						<!-- Store the request WSA_MsgId for logging -->
						<dp:set-variable name="$RES_WSA_MSG_ID_VAR_NAME" value="$NEW_MSG_ID"/>
						<!-- Store WSA message identifier -->
						<xsl:call-template name="StoreMsgIdentifier">
							<xsl:with-param name="TYPE" select="'WSA_MSG_ID'"/>
							<xsl:with-param name="APPLIES_TO" select="'RES'"/>
							<xsl:with-param name="IDENTIFIER_VALUE" select="string($NEW_MSG_ID)"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</wsa:MessageID>
			<wsa:RelatesTo>
				<!-- Set RelatesTo to inbound request MsgId -->
				<xsl:value-of select="$REQ_WSA_MSG_ID"/>
				<!-- Store the request WSA_RelatesTo for logging -->
				<dp:set-variable name="$RES_WSA_RELATES_TO_VAR_NAME" value="$REQ_WSA_MSG_ID"/>
				<!-- Store WSA message identifier -->
				<xsl:call-template name="StoreMsgIdentifier">
					<xsl:with-param name="TYPE" select="'WSA_RELATES_TO'"/>
					<xsl:with-param name="APPLIES_TO" select="'RES'"/>
					<xsl:with-param name="IDENTIFIER_VALUE" select="string($REQ_WSA_MSG_ID)"/>
				</xsl:call-template>
			</wsa:RelatesTo>
			<wsa:To>
				<xsl:choose>
					<xsl:when test="dp:variable($ERROR_TO_WSA_ENDPOINT_RESULT_VAR_NAME) = 'SUCCESS'">
						<!-- Async WS Addressing Fault has been delivered. wsa:To is irrelavant -->
						<xsl:value-of select="'http://www.w3.org/2005/08/addressing/anonymous'"/>
					</xsl:when>
					<xsl:when test="($TX_RULE_TYPE = 'error') and ($REQ_WSA_FAULT_TO != '')">
						<!-- SOAP Fault is deliverable -->
						<xsl:value-of select="$REQ_WSA_FAULT_TO"/>
					</xsl:when>
					<xsl:when test="($TX_RULE_TYPE = 'error') and ($REQ_WSA_REPLY_TO != '')">
						<!-- SOAP Fault is deliverable -->
						<xsl:value-of select="$REQ_WSA_REPLY_TO"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'http://www.w3.org/2005/08/addressing/anonymous'"/>
					</xsl:otherwise>
				</xsl:choose>
			</wsa:To>
			<wsa:Action>
				<xsl:variable name="INBOUND_ACTION" select="$REQ_SOAP_ENV/*[local-name() = 'Envelope']/*[local-name() = 'Header']/wsa:Action"/>
				<xsl:choose>
					<xsl:when test="$TX_RULE_TYPE = 'error'">
						<xsl:value-of select="concat(normalize-space($INBOUND_ACTION),'/Fault/EnterpriseError')"/>
					</xsl:when>
					<xsl:when test="$MSG_PAYLOAD/*[local-name() = 'Acknowledgement']">
						<xsl:value-of select="concat(normalize-space($INBOUND_ACTION),'/Acknowledgement')"/>
					</xsl:when>
					<xsl:when test="contains($INBOUND_ACTION, 'Response')">
						<xsl:value-of select="concat(normalize-space($INBOUND_ACTION),'/Response')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat(normalize-space($INBOUND_ACTION),'Response')"/>
					</xsl:otherwise>
				</xsl:choose>
			</wsa:Action>
		</xsl:copy>
	</xsl:template>
	<!-- Template to copy through limited set of "wsse:Security" header content  (Strips SAML Assertion and related dig sig content) -->
<!--	<xsl:template match="wsse:Security">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="wsse:UsernameToken"/> 
		</xsl:copy>
	</xsl:template>-->
	<!-- Standard identity template -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
