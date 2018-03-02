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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:err="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0" extension-element-prefixes="dp regexp"
	version="1.0" exclude-result-prefixes="dp regexp errcore scm wsa saml wsse">
	<!--========================================================================
		Purpose:
		Performs initialisation of the generic policy flow. The request or response policy configuration
		node is output to the SERVICE_METADATA context and the first rule in the policy is set on the associated
		context variable. The INPUT context is copied to the RESULT_DOC context.
		
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		2016-12-12	v1.0	Tim Goodwill		Add notification support.
		2016-12-12	v1.0	Tim Goodwill		HTTP/S timeout msg and response code addl dtl.
		2016-12-12	v2.0	Tim Goodwill		Init Gateway  instance
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="FrameworkUtils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="PROXY_NAME" select="normalize-space(dp:variable($DP_SERVICE_PROCESSOR_NAME))"/>
	<xsl:variable name="CONFIG_DOC"
		select="document(concat($DPDIRECT_SERVICES_ROOT_FOLDER,'config/',$PROXY_NAME,'_ServiceConfig.xml'))"/>
	<xsl:variable name="SAML_ASSERTION" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsse:security/saml:Assertion[1])"/>
	<xsl:variable name="WSU_TIMESTAMP" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsse:security/*[local-name() = 'Timestamp'])"/>
	<xsl:variable name="SOAP_NAMESPACE" select="normalize-space(namespace-uri(/*[local-name() = 'Envelope'][1]))"/>
	<xsl:variable name="WSA_ACTION" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsa:Action[1])"/>
	<xsl:variable name="WSA_TO" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsa:To[normalize-space(.) != $WSA_ANONYMOUS_DESTINATION])"/>
	<xsl:variable name="WSA_FROM" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsa:From[normalize-space(.) != $WSA_ANONYMOUS_DESTINATION])"/>
	<xsl:variable name="WSA_REPLY_TO" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() = 
		'Header'][1]/wsa:ReplyTo[1]/wsa:Address[normalize-space(.) != $WSA_ANONYMOUS_DESTINATION])"/>
	<xsl:variable name="WSA_FAULT_TO" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() = 
		'Header'][1]/wsa:FaultTo[1]/wsa:Address[normalize-space(.) != $WSA_ANONYMOUS_DESTINATION])"/>
	<xsl:variable name="WSA_MSG_ID" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsa:MessageID[1])"/>
	<xsl:variable name="WSA_RELATES_TO" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsa:RelatesTo[1])"/>
	<xsl:variable name="REQUEST_TRANSACTION_ID" select="normalize-space((/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1])//*[local-name() = 'TransactionId'][1])"/>
	<xsl:variable name="SOAP_FAULT" select="/*[local-name() = 'Envelope']/*[local-name() = 'Body']/*[local-name() =
		'Fault'] | /*[local-name() = 'Fault']"/>
	<xsl:variable name="INPUT_URI" select="concat('/', substring-after(substring-after(dp:variable($DP_SERVICE_URL_IN), '//'), '/'))"/>
	<xsl:variable name="INPUT_PORT"
		select="normalize-space(substring-after(dp:variable($DP_SERVICE_LOCAL_SERVICE_ADDRESS),':'))"/>
	<xsl:variable name="ATTACHMENT_MANIFEST" select="dp:variable($DP_LOCAL_ATTACHMENT_MANIFEST)"/>
	<!-- Message format  -->
	<xsl:variable name="MSG_FORMAT">
		<xsl:choose>
			<xsl:when test="$ATTACHMENT_MANIFEST/manifest/media-type/value">
				<xsl:value-of select="'MIME'"/>
			</xsl:when>
			<xsl:when test="/Input/WrappedText[not(text())]">
				<xsl:value-of select="'zero-bytes'"/>
			</xsl:when>
			<xsl:when test="/Input/WrappedText">
				<xsl:value-of select="'non-XML'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'XML'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- Message meta-data structure -->
	<xsl:variable name="INPUT_MSG_SIZE" select="string(dp:get-metadata()/metadata/input-message-size)"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- The DP transaction rule type ('request'|'response'|'error') -->
		<xsl:variable name="TX_RULE_TYPE" select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
		<xsl:if test="$TX_RULE_TYPE != 'error'">
			<dp:set-variable name="$FLOW_DIRECTION_VAR_NAME" value="string($TX_RULE_TYPE)"/>
		</xsl:if>
		<!-- Custom Log type -->
		<xsl:variable name="CAPTURE_POINT_LOGS">
			<xsl:call-template name="GetCapturePointLogsProperty"/>
		</xsl:variable>
		<!-- Start a timer event for the flow -->
		<xsl:call-template name="StartTimerEvent">
			<xsl:with-param name="EVENT_ID" select="'RequestFlow'"/>
		</xsl:call-template>
		<xsl:variable name="MSG_ROOT_LOCAL_NAME" select="local-name(/*[local-name() = 'Envelope'][1]/*[local-name() = 'Body'][1]/*[1])"/>
		<xsl:variable name="INPUT_MSG_ROOT_NAME">
			<xsl:text>{</xsl:text>
			<xsl:value-of select="normalize-space(namespace-uri(/*[local-name() =
				'Envelope'][1]/*[local-name() = 'Body'][1]/*[1]))"/>
			<xsl:text>}</xsl:text>
			<xsl:value-of select="$MSG_ROOT_LOCAL_NAME"/>
		</xsl:variable>
		<xsl:variable name="SERVICE_NAME">
			<xsl:choose>
				<xsl:when
					test="substring($MSG_ROOT_LOCAL_NAME,string-length($MSG_ROOT_LOCAL_NAME)-6,7) = 'Request'">
					<xsl:value-of select="substring($MSG_ROOT_LOCAL_NAME,1,string-length($MSG_ROOT_LOCAL_NAME)-7)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$MSG_ROOT_LOCAL_NAME"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- Store the request SAML Assertion -->
		<dp:set-variable name="$SAML_ASSERTION_VAR_NAME" value="$SAML_ASSERTION"/>
		<!-- Store the request timestamp -->
		<dp:set-variable name="$WSU_TIMESTAMP_VAR_NAME" value="$WSU_TIMESTAMP"/>
		<!-- Store the request SOAP Namespace -->
		<dp:set-variable name="$REQ_SOAP_NAMESPACE_VAR_NAME" value="$SOAP_NAMESPACE"/>
		<!-- Store the request SOAP envelope -->
		<xsl:variable name="REQ_SOAP_ENV">
			<xsl:apply-templates select="." mode="storeSoapEnv"/>
		</xsl:variable>
		<dp:set-variable name="$REQ_SOAP_ENV_VAR_NAME" value="$REQ_SOAP_ENV"/>
		<!-- Store the Security Header -->
		<dp:set-variable name="$REQ_WSA_SECURITY_VAR_NAME" value="*[local-name() = 'Envelope']/*[local-name() =
			'Header']/wsse:Security"/>
		<xsl:if test="normalize-space($REQUEST_TRANSACTION_ID) != ''">
			<dp:set-variable name="$TRANSACTION_ID_VAR_NAME" value="$REQUEST_TRANSACTION_ID"/>
			<dp:set-variable name="$TRANSACTION_ID_TYPE_VAR_NAME" value="'TransactionId'"/>
			<xsl:call-template name="StoreMsgIdentifier">
				<xsl:with-param name="TYPE" select="'TransactionId'"/>
				<xsl:with-param name="APPLIES_TO" select="'REQ'"/>
				<xsl:with-param name="IDENTIFIER_VALUE" select="$REQUEST_TRANSACTION_ID"/>
			</xsl:call-template>
		</xsl:if>
		<!-- Store the request WSAddressing from the SOAP header for logging -->
		<dp:set-variable name="$REQ_WSA_MSG_ID_VAR_NAME" value="string($WSA_MSG_ID)"/>
		<dp:set-variable name="$REQ_WSA_RELATES_TO_VAR_NAME" value="string($WSA_RELATES_TO)"/>
		<dp:set-variable name="$REQ_WSA_TO_VAR_NAME" value="string($WSA_TO)"/>
		<dp:set-variable name="$REQ_WSA_REPLY_TO_VAR_NAME" value="string($WSA_REPLY_TO)"/>
		<dp:set-variable name="$REQ_WSA_FAULT_TO_VAR_NAME" value="string($WSA_FAULT_TO)"/>
		<!-- Store the WSA Action -->
		<dp:set-variable name="$REQ_WSA_ACTION_VAR_NAME" value="string($WSA_ACTION)"/>
		<!-- Store the request user name -->
		<dp:set-variable name="$REQ_USER_NAME_VAR_NAME" value="normalize-space((/*[local-name() =
			'Envelope']/*[local-name() = 'Header']/wsse:security/wsse:UsernameToken/wsse:Username)[1])"/>
		<!-- Store the Message Format -->
		<dp:set-variable name="$REQ_IN_MSG_FORMAT_VAR_NAME" value="$MSG_FORMAT"/>
		<!-- Store the request message size -->
		<dp:set-variable name="$STATS_LOG_REQ_INMSG_SIZE_VAR_NAME" value="string($INPUT_MSG_SIZE)"/>
		<!-- Store the request message payload qualified name value -->
		<dp:set-variable name="$STATS_LOG_REQ_INMSG_ROOT_VAR_NAME" value="string($INPUT_MSG_ROOT_NAME)"/>
		<!-- Store the Service Identifier value -->
		<dp:set-variable name="$SERVICE_IDENTIFIER_VAR_NAME" value="string($INPUT_MSG_ROOT_NAME)"/>
		<!-- Store the Service Name value -->
		<dp:set-variable name="$SERVICE_NAME_VAR_NAME" value="string($SERVICE_NAME)"/>
		<!-- Store WSA message identifier -->
		<xsl:if test="normalize-space($WSA_MSG_ID) != ''">
			<xsl:call-template name="StoreMsgIdentifier">
				<xsl:with-param name="TYPE" select="'WSA_MSG_ID'"/>
				<xsl:with-param name="APPLIES_TO" select="'REQ'"/>
				<xsl:with-param name="IDENTIFIER_VALUE" select="string($WSA_MSG_ID)"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="normalize-space($WSA_RELATES_TO) != ''">
			<xsl:call-template name="StoreMsgIdentifier">
				<xsl:with-param name="TYPE" select="'WSA_RELATES_TO'"/>
				<xsl:with-param name="APPLIES_TO" select="'REQ'"/>
				<xsl:with-param name="IDENTIFIER_VALUE" select="string($WSA_RELATES_TO)"/>
			</xsl:call-template>
		</xsl:if>
		<!-- Store the HTTP request headers -->
		<xsl:call-template name="StoreHTTPHeadersForLog">
			<xsl:with-param name="LOGPOINT" select="'REQ'"/>
		</xsl:call-template>
		<!-- Point log in test environments only-->
		<xsl:if test="$CAPTURE_POINT_LOGS != 'none'">
			<!-- Store the request input message to point log -->
			<xsl:call-template name="StorePointLog">
				<xsl:with-param name="MSG" select="."/>
				<xsl:with-param name="POINT_LOG_VAR_NAME" select="$POINT_LOG_REQ_INMSG_VAR_NAME"/>
			</xsl:call-template>
		</xsl:if>
		<!-- Retrieve the policy configuration for the matching service and store 
			for later use in the request/response flow -->
		<xsl:variable name="OPERATION_CONFIG_NODE">
			<xsl:element name="OperationConfig">
				<xsl:attribute name="txRuleType"><xsl:value-of select="$TX_RULE_TYPE"/></xsl:attribute>
				<!-- Match based on input criteria -->
				<xsl:variable name="OPERATION_CONFIG_ACTION_MATCH">
					<xsl:choose>
						<!-- Action input match at the Service/InputMatchCriteria level -->
						<xsl:when test="$CONFIG_DOC/ServiceConfig/OperationConfig[InputMatchCriteria/Action = $WSA_ACTION]">
							<xsl:copy-of select="$CONFIG_DOC/ServiceConfig/OperationConfig[InputMatchCriteria/Action = $WSA_ACTION]"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:copy-of select="$CONFIG_DOC/ServiceConfig/OperationConfig[InputMatchCriteria[not(Action)]]"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="OPERATION_CONFIG_PORT_MATCH">
					<xsl:choose>
						<!-- Port input match at the OperationConfig level -->
						<xsl:when test="$OPERATION_CONFIG_ACTION_MATCH/OperationConfig[InputMatchCriteria[(HTTPPort/text() =
							$INPUT_PORT) or (HTTPSPort/text() = $INPUT_PORT)]]">
							<xsl:copy-of select="$OPERATION_CONFIG_ACTION_MATCH/OperationConfig[InputMatchCriteria[(HTTPPort/text() =
								$INPUT_PORT) or (HTTPSPort/text() = $INPUT_PORT)]]"/>
						</xsl:when>
						<!-- Config with no Port specified -->
						<xsl:otherwise>
							<xsl:copy-of select="$OPERATION_CONFIG_ACTION_MATCH/OperationConfig[InputMatchCriteria[
								not(/HTTPPort) and not(/HTTPSPort)]]"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="OPERATION_CONFIG_URI_MATCH">
					<xsl:choose>
						<!-- InboundURI match at the OperationConfig level -->
						<xsl:when test="$OPERATION_CONFIG_PORT_MATCH/OperationConfig[InputMatchCriteria[
							regexp:match($INPUT_URI, regexp:replace(InboundURI/text(), '\*', 'g', '.*'))  != '']]">
							<xsl:copy-of select="$OPERATION_CONFIG_PORT_MATCH/OperationConfig[InputMatchCriteria[
								regexp:match($INPUT_URI, regexp:replace(InboundURI/text(), '\*', 'g', '.*'))  != '']]"/>
						</xsl:when>
						<!-- Config with no InboundURI specified -->
						<xsl:otherwise>
							<xsl:copy-of select="$OPERATION_CONFIG_PORT_MATCH/OperationConfig[InputMatchCriteria[
								not(/InboundURI)]]"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="OPERATION_CONFIG_NODE_ID">
					<xsl:value-of select="($OPERATION_CONFIG_URI_MATCH/OperationConfig/@id)[1]"/>
				</xsl:variable>
				<!-- Copy OperationConfig Attributes -->
				<xsl:for-each select="$CONFIG_DOC/ServiceConfig/OperationConfig[@id =
					$OPERATION_CONFIG_NODE_ID]/RequestPolicyConfig/@*">
					<xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
				</xsl:for-each>
				<xsl:choose>
					<!-- Reject unmatched services -->
					<xsl:when test="normalize-space($OPERATION_CONFIG_NODE_ID) = ''">
						<!-- Reject to error flow -->
						<xsl:call-template name="RejectToErrorFlow">
							<xsl:with-param name="MSG">
								<xsl:text>No matching service configuration for input message. wsa:Action='</xsl:text>
								<xsl:value-of select="$WSA_ACTION"/>
								<xsl:text>' on input port '</xsl:text>
								<xsl:value-of select="$INPUT_PORT"/>
								<xsl:text>'</xsl:text>
							</xsl:with-param>
							<xsl:with-param name="ERROR_CODE" select="'ENTR00011'"/>
						</xsl:call-template>
					</xsl:when>
					<!-- Configure the flow -->
					<xsl:otherwise>
						<xsl:variable name="REQUEST_POLICY_CONFIG">
							<RequestPolicyConfig>
								<xsl:copy-of select="$CONFIG_DOC/ServiceConfig/PreProcessConfig/*"/>
								<xsl:copy-of select="$CONFIG_DOC/ServiceConfig/OperationConfig[@id =
									$OPERATION_CONFIG_NODE_ID]/RequestPolicyConfig/*"/>
							</RequestPolicyConfig>
						</xsl:variable>
						<!-- Set the policy config node id for use in the response flow -->
						<dp:set-variable name="$OPERATION_CONFIG_NODE_ID_VAR_NAME"
							value="string($OPERATION_CONFIG_NODE_ID)"/>
						<!-- Set the backend provider name for the service for use in the error flow -->
						<dp:set-variable name="$OPERATION_CONFIG_PROVIDER_VAR_NAME"
							value="string($REQUEST_POLICY_CONFIG/BackendRouting/@provider)"/>
						<!-- Copy the request config child elements -->
						<xsl:apply-templates select="$REQUEST_POLICY_CONFIG/RequestPolicyConfig" mode="processPolicyMetadata"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:element>
		</xsl:variable>
		<!-- Set the next rule name variable for dynamic policy flow execution -->
		<xsl:variable name="NEXT_RULE_NAME"
			select="concat($RULE_NAME_PREFIX,normalize-space(local-name($OPERATION_CONFIG_NODE/OperationConfig/*[1])),'_rule')"/>
		<dp:set-variable name="$NEXT_RULE_NAME_VAR_NAME" value="string($NEXT_RULE_NAME)"/>
		<dp:set-variable name="$SERVICE_METADATA_CONTEXT_NAME" value="$OPERATION_CONFIG_NODE"/>
		<!-- Copy INPUT context to RESULT_DOC context -->
		<xsl:copy-of select="."/>
	</xsl:template>
	<!--=============================================================-->
	<!-- MODAL TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to add timing metadata to policy config metadata -->
	<xsl:template match="RequestPolicyConfig" mode="processPolicyMetadata">
		<!-- Copy service chain children -->
		<xsl:apply-templates select="@*|node()" mode="processPolicyMetadata"/>
	</xsl:template>
	<xsl:template match="*[parent::RequestPolicyConfig]" mode="processPolicyMetadata">
		<xsl:copy>
			<xsl:attribute name="timerId">
				<xsl:text>Req</xsl:text>
				<xsl:text>/</xsl:text>
				<xsl:value-of select="1 + count(preceding-sibling::*)"/>
				<xsl:text>/</xsl:text>
				<xsl:value-of select="local-name(.)"/>
			</xsl:attribute>
			<xsl:apply-templates select="@*|node()" mode="processPolicyMetadata"/>
		</xsl:copy>
	</xsl:template>
	<!-- Standard identity template (mode="processPolicyMetadata") -->
	<xsl:template match="node()|@*" mode="processPolicyMetadata">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="processPolicyMetadata"/>
		</xsl:copy>
	</xsl:template>
	<!-- Template to ignore payload when storing soap envelope -->
	<xsl:template match="*[local-name() = 'Envelope']/*[local-name() = 'Body']/*" mode="storeSoapEnv">
		<!-- Do Nothing -->
	</xsl:template>
	<!-- Standard identity template (mode="storeSoapEnv") -->
	<xsl:template match="node()|@*" mode="storeSoapEnv">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="storeSoapEnv"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
