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
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:err="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0" extension-element-prefixes="dp regexp"
	version="1.0" exclude-result-prefixes="dp regexp err scm wsa wsse">
	<!--========================================================================
		Purpose:
		Performs initialisation of the generic policy flow. The request or response policy configuration
		node is output to the SERVICE_METADATA context and the first rule in the policy is set on the associated
		context variable. The INPUT context is copied to the RESULT_DOC context.
				
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
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
			<xsl:with-param name="EVENT_ID">
				<xsl:choose>
					<xsl:when test="$TX_RULE_TYPE = 'response'">
						<xsl:text>ResponseFlow</xsl:text>
					</xsl:when>
					<!-- Implies $TX_RULE_TYPE = 'error' -->
					<xsl:otherwise>
						<xsl:text>ErrorFlow</xsl:text>
						<!-- Stop either the request or response flow timer, as one of them will be left running at this point -->
						<!-- The template call is nested in a variable to prevent concatenation of the output of the "StopTimerEvent" call -->
						<xsl:variable name="MASK_TIMER_CALL_VAR">
							<xsl:call-template name="StopTimerEvent">
								<xsl:with-param name="EVENT_ID">
									<xsl:variable name="REQ_MILLIS_VAR"
										select="dp:variable(concat($TIMER_ELAPSED_BASEVAR_NAME,'RequestFlow'))"/>
									<xsl:choose>
										<xsl:when test="string(number($REQ_MILLIS_VAR)) != 'NaN'">
											<!-- Implies the request flow finished so we need to stop the response flow timer -->
											<xsl:value-of select="'ResponseFlow'"/>
										</xsl:when>
										<xsl:otherwise>
											<!-- Implies the error prevented completion of the request flow so we need to stop the request flow timer -->
											<xsl:value-of select="'RequestFlow'"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:variable>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:variable name="MSG_ROOT_LOCAL_NAME" select="local-name(/*[local-name() = 'Envelope'][1]/*[local-name() = 'Body'][1]/*[1])"/>
		<xsl:variable name="INPUT_MSG_ROOT_NAME">
			<xsl:text>{</xsl:text>
			<xsl:value-of select="normalize-space(namespace-uri(/*[local-name() =
				'Envelope'][1]/*[local-name() = 'Body'][1]/*[1]))"/>
			<xsl:text>}</xsl:text>
		</xsl:variable>
		<xsl:if test="$TX_RULE_TYPE = 'response'">
			<!-- Store WSA message identifier -->
			<xsl:if test="normalize-space($WSA_MSG_ID) != ''">
				<xsl:call-template name="StoreMsgIdentifier">
					<xsl:with-param name="TYPE" select="'WSA_MSG_ID'"/>
					<xsl:with-param name="APPLIES_TO" select="'RES'"/>
					<xsl:with-param name="IDENTIFIER_VALUE" select="string($WSA_MSG_ID)"/>
				</xsl:call-template>
			</xsl:if>
			<!-- Store the backend HTTP response headers -->
<!--			<xsl:call-template name="StoreHTTPHeadersForLog">
				<xsl:with-param name="LOGPOINT" select="'SUB_RES'"/>
			</xsl:call-template>-->
			<!-- Store the response WSAddressing from the SOAP header for logging -->
			<dp:set-variable name="$RES_WSA_MSG_ID_VAR_NAME" value="string($WSA_MSG_ID)"/>
			<dp:set-variable name="$RES_WSA_RELATES_TO_VAR_NAME" value="string($WSA_RELATES_TO)"/>
			<dp:set-variable name="$RES_WSA_TO_VAR_NAME" value="string($WSA_TO)"/>
			<dp:set-variable name="$RES_WSA_FAULT_TO_VAR_NAME" value="string($WSA_FAULT_TO)"/>
			<!-- Store the response messagename value -->
			<dp:set-variable name="$RES_IN_MSG_NAME_VAR_NAME" value="string($MSG_ROOT_LOCAL_NAME)"/>
			<!-- Store the Message Format -->
			<dp:set-variable name="$RES_IN_MSG_FORMAT_VAR_NAME" value="$MSG_FORMAT"/>
			<!-- Store the response message size -->
			<dp:set-variable name="$STATS_LOG_RES_INMSG_SIZE_VAR_NAME" value="string($INPUT_MSG_SIZE)"/>
			<!-- Store the response message payload qualified name value -->
			<dp:set-variable name="$STATS_LOG_RES_INMSG_ROOT_VAR_NAME" value="string($INPUT_MSG_ROOT_NAME)"/>
			<!-- Store the point Log -->
			<xsl:if test="($CAPTURE_POINT_LOGS != 'none')">
				<!-- Store the response input message to point log -->
				<xsl:call-template name="StorePointLog">
					<xsl:with-param name="MSG" select="."/>
					<xsl:with-param name="POINT_LOG_VAR_NAME" select="$POINT_LOG_RES_INMSG_VAR_NAME"/>
				</xsl:call-template>
			</xsl:if>
			<!-- Clear the RESULT_DOC context and strip any attachments (only possible for response flows) -->
			<dp:set-variable name="$RESULT_DOC_CONTEXT_NAME" value="$EMPTY_SOAP_11_DOC"/>
			<dp:strip-attachments context="RESULT_DOC"/>
			<!-- Copy attachments to RESULT_DOC context -->
			<xsl:call-template name="CopyAttachments"/>
		</xsl:if>
		<xsl:if test="$TX_RULE_TYPE = 'error'">
			<!-- Log error as response where response flow is not invoked -->
			<xsl:variable name="RES_IN_LOG_MSG" select="string(dp:variable($POINT_LOG_RES_INMSG_VAR_NAME))"/>
			<xsl:variable name="BACKEND_PROVIDER_NAME" select="string(dp:variable($PROVIDER_VAR_NAME))"/>
			<xsl:if test="($BACKEND_PROVIDER_NAME != '')
				and ($RES_IN_LOG_MSG = '')">
				<!-- Store WSA message identifier -->
				<xsl:if test="normalize-space($WSA_MSG_ID) != ''">
					<xsl:call-template name="StoreMsgIdentifier">
						<xsl:with-param name="TYPE" select="'WSA_MSG_ID'"/>
						<xsl:with-param name="APPLIES_TO" select="'RES'"/>
						<xsl:with-param name="IDENTIFIER_VALUE" select="string($WSA_MSG_ID)"/>
					</xsl:call-template>
				</xsl:if>
				<!-- Store the backend HTTP response headers -->
<!--				<xsl:call-template name="StoreHTTPHeadersForLog">
					<xsl:with-param name="LOGPOINT" select="'SUB_RES'"/>
				</xsl:call-template>-->
				<!-- Store the point Log -->
				<xsl:if test="($CAPTURE_POINT_LOGS != 'none')">
					<!-- Store the response input message to point log -->
					<xsl:call-template name="StorePointLog">
						<!-- Just the root-name, this is a placeholder for backent timing -->
						<xsl:with-param name="MSG" select="$INPUT_MSG_ROOT_NAME"/>
						<xsl:with-param name="POINT_LOG_VAR_NAME" select="$POINT_LOG_RES_INMSG_VAR_NAME"/>
					</xsl:call-template>
				</xsl:if>
				<!-- Store the Message Format -->
				<dp:set-variable name="$RES_IN_MSG_FORMAT_VAR_NAME" value="$MSG_FORMAT"/>
				<!-- Store the response message size -->
				<dp:set-variable name="$STATS_LOG_RES_INMSG_SIZE_VAR_NAME" value="string($INPUT_MSG_SIZE)"/>
				<!-- Store the response message payload qualified name value -->
				<dp:set-variable name="$STATS_LOG_RES_INMSG_ROOT_VAR_NAME" value="$INPUT_MSG_ROOT_NAME"/>
			</xsl:if>
		</xsl:if>
		<!-- Retrieve the policy configuration for the matching service and store 
			for later use in the request/response flow -->
		<xsl:variable name="OPERATION_CONFIG_NODE">
			<xsl:element name="OperationConfig">
				<xsl:attribute name="txRuleType"><xsl:value-of select="$TX_RULE_TYPE"/></xsl:attribute>
				<xsl:choose>
					<!-- In response flow -->
					<xsl:when test="$TX_RULE_TYPE = 'response'">
						<!-- Retrieve the policy config node id -->
						<xsl:variable name="OPERATION_CONFIG_NODE_ID"
							select="string(dp:variable($OPERATION_CONFIG_NODE_ID_VAR_NAME))"/>
						<!-- Copy OperationConfig Attributes -->
						<xsl:for-each select="$CONFIG_DOC/ServiceConfig/OperationConfig[@id =
							$OPERATION_CONFIG_NODE_ID]/ResponsePolicyConfig/@*">
							<xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
						</xsl:for-each>
						<xsl:variable name="DP_RESPONSE_CODE" select="dp:response-header('x-dp-response-code')"/>
						<xsl:variable name="BACKSIDE_PROTOCOL" select="substring-before(dp:variable($DP_SERVICE_URL_OUT),':')"/>
						<xsl:variable name="PROVIDER_NAME" select="dp:variable($PROVIDER_VAR_NAME)"/>
						<xsl:variable name="INPUT_MSG_EMPTY" select="boolean(not(/*))"/>
						<!-- Copy the response config child elements -->
						<xsl:apply-templates select="$CONFIG_DOC/ServiceConfig/OperationConfig[@id =
							$OPERATION_CONFIG_NODE_ID]/ResponsePolicyConfig/*" mode="processPolicyMetadata"/>
						<xsl:choose>
							<!-- Reject backend for MQ put errors -->
							<xsl:when test="$INPUT_MSG_EMPTY 
								and ($BACKSIDE_PROTOCOL = 'dpmq')
								and (number($DP_RESPONSE_CODE) = number($DP_RESPONSE_CODE) )
								and (number($DP_RESPONSE_CODE) &gt;= 2000)
								and (number($DP_RESPONSE_CODE) != 2033)">
								<!-- Store the Message Format -->
								<dp:set-variable name="$RES_IN_MSG_FORMAT_VAR_NAME" value="'zero-bytes'"/>
								<!-- Reject to error flow -->
								<xsl:call-template name="RejectToErrorFlow">
									<xsl:with-param name="MSG">
										<xsl:text>MQ PUT Failure - Failed to put current message to URL '</xsl:text>
										<xsl:value-of select="dp:variable($DP_SERVICE_URL_OUT)"/>
										<xsl:text>'. Backside url-open error: [errorcode=</xsl:text>
										<xsl:value-of select="$DP_RESPONSE_CODE"/>
										<xsl:text>]</xsl:text>
									</xsl:with-param>
									<xsl:with-param name="ERROR_CODE" select="'FRMWK0020'"/>
								</xsl:call-template>
							</xsl:when>
							<!-- Empty response : assume timeout -->
							<xsl:when test="$INPUT_MSG_EMPTY">
								<!-- Store the Message Format -->
								<dp:set-variable name="$RES_IN_MSG_FORMAT_VAR_NAME" value="'zero-bytes'"/>
								<!-- Reject to error flow -->
								<xsl:call-template name="RejectToErrorFlow">
									<xsl:with-param name="ERROR_CODE" select="'ERROR0012'"/>
									<xsl:with-param name="ORIGINATOR_NAME" select="$PROVIDER_NAME"/>
									<xsl:with-param name="ADD_DETAILS" select="'A valid response was not returned by the backend.'"/>
								</xsl:call-template>
							</xsl:when>
						</xsl:choose>
					</xsl:when>
					<!-- In error flow -->
					<xsl:otherwise>
						<!-- Determine provider name -->
						<xsl:variable name="PROVIDER_NAME" select="dp:variable($PROVIDER_VAR_NAME)"/>
						<!-- Determine backside protocol -->
						<xsl:variable name="BACKSIDE_PROTOCOL" select="substring-before(dp:variable($DP_SERVICE_URL_OUT),':')"/>
						<!-- Store SOAP envelope in those cases where early rejection results in no policy step to store the SOAP env (e.g. SAML security rejection) -->
						<xsl:variable name="REQ_SOAP_ENV_VAR" select="dp:variable($REQ_SOAP_ENV_VAR_NAME)"/>
						<xsl:if test="not($REQ_SOAP_ENV_VAR/*)">
							<xsl:variable name="REQ_SOAP_ENV">
								<xsl:apply-templates select="." mode="storeSoapEnv"/>
							</xsl:variable>
							<dp:set-variable name="$REQ_SOAP_ENV_VAR_NAME" value="$REQ_SOAP_ENV"/>
						</xsl:if>
						<!-- Read and store error information in those cases where the error information
							has not already been set by a call to the "RejectToErrorFlow" template (See Utils.xsl) -->						<!-- Save DP Event vars if not already set -->
						<xsl:if test="normalize-space(dp:variable($EVENT_CODE_VAR_NAME)) = ''">
							<dp:set-variable name="$EVENT_CODE_VAR_NAME" value="dp:variable($DP_SERVICE_ERROR_CODE)"/>
							<dp:set-variable name="$EVENT_SUBCODE_VAR_NAME" value="dp:variable($DP_SERVICE_ERROR_SUBCODE)"/>
							<dp:set-variable name="$EVENT_MESSAGE_VAR_NAME" value="dp:variable($DP_SERVICE_ERROR_MSG)"/>
						</xsl:if>
						<xsl:choose>
							<!-- 0x01130006 response: Determine if HTTP/S timeout. Test time-elapsed against service backend timeout -->
							<xsl:when test="(normalize-space(dp:variable($ERROR_CODE_VAR_NAME)) = '')
								and (dp:variable($DP_SERVICE_ERROR_CODE) = '0x01130006')
								and (number(dp:variable($DP_SERVICE_TIME_ELAPSED)) &gt;= number(dp:variable($PROVIDER_TIMEOUT_MILLIS_VAR_NAME)))">
								<!-- Read error information -->
								<xsl:variable name="ERROR_MSG" select="normalize-space(concat('A response was not received from ', $PROVIDER_NAME, ' within the timeout period'))"/>
								<xsl:variable name="ERROR_CODE" select="'ERROR0012'"/>
								<xsl:variable name="ERROR_SUBCODE" select="$ERROR_CODE"/>
								<!-- Store error information (which is otherwise not accessible in sub-rule invocations later in the error flow) -->
								<dp:set-variable name="$ERROR_MSG_VAR_NAME" value="$ERROR_MSG"/>
								<dp:set-variable name="$ERROR_CODE_VAR_NAME" value="$ERROR_CODE"/>
								<dp:set-variable name="$ERROR_SUBCODE_VAR_NAME" value="$ERROR_SUBCODE"/>
							</xsl:when>
							<!-- Schema validation error  -->
							<xsl:when test="(normalize-space(dp:variable($ERROR_CODE_VAR_NAME)) = '')
								and (dp:variable($DP_SERVICE_ERROR_CODE) = '0x00230001')
								and contains(dp:variable($DP_SERVICE_ERROR_MSG), 'cvc-particle')">
								<!-- Read error information -->
								<xsl:variable name="ERROR_MSG" select="dp:variable($DP_SERVICE_ERROR_MSG)"/>
								<xsl:variable name="ERROR_CODE" select="'FRMWK0026'"/>
								<!-- Store error information (which is otherwise not accessible in sub-rule invocations later in the error flow) -->
								<dp:set-variable name="$ERROR_MSG_VAR_NAME" value="$ERROR_MSG"/>
								<dp:set-variable name="$ERROR_CODE_VAR_NAME" value="$ERROR_CODE"/>
							</xsl:when>
							<!-- WSDL policy  -->
							<xsl:when test="(normalize-space(dp:variable($ERROR_CODE_VAR_NAME)) = '')
								and (dp:variable($DP_SERVICE_ERROR_CODE) = '0x00d30003')
								and contains(dp:variable($DP_SERVICE_ERROR_MSG), 'Required elements filter')">
								<!-- Read error information -->
								<xsl:variable name="ERROR_MSG" select="'Service request policy violation - required header not found.'"/>
								<xsl:variable name="ERROR_CODE" select="'FRMWK0020'"/>
								<!-- Store error information (which is otherwise not accessible in sub-rule invocations later in the error flow) -->
								<dp:set-variable name="$ERROR_MSG_VAR_NAME" value="string($ERROR_MSG)"/>
								<dp:set-variable name="$ERROR_CODE_VAR_NAME" value="string($ERROR_CODE)"/>
							</xsl:when>
							<xsl:when test="normalize-space(dp:variable($ERROR_CODE_VAR_NAME)) = ''">
								<!-- Read error information from DP Service error variables -->
								<!-- Strip out known patterns of local IP addresses from error messages. -->
								<xsl:variable name="ERROR_MSG" select="regexp:replace(dp:variable($DP_SERVICE_ERROR_MSG), '(https*://)\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:*\d{0,4}\b', 'g', '$1(IP-removed)')"/>
								<xsl:variable name="ERROR_CODE" select="dp:variable($DP_SERVICE_ERROR_CODE)"/>
								<xsl:variable name="ERROR_SUBCODE">
									<xsl:variable name="SUBCODE" select="dp:variable($DP_SERVICE_ERROR_SUBCODE)"/>
									<xsl:choose>
										<xsl:when test="translate(string($SUBCODE),'0x&#x20;','') = ''">
											<xsl:value-of select="$ERROR_CODE"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$SUBCODE"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<!-- Store error information (which is otherwise not accessible in sub-rule invocations later in the error flow) -->
								<xsl:choose>
									<xsl:when test="contains($BACKSIDE_PROTOCOL, 'http')">
										<dp:set-variable name="$ERROR_ADD_DETAILS_VAR_NAME" value="concat($PROVIDER_NAME, ' http error: ', $ERROR_MSG)"/>
									</xsl:when>
									<xsl:otherwise>
										<dp:set-variable name="$ERROR_ADD_DETAILS_VAR_NAME" value="concat($PROVIDER_NAME, ' : ', $ERROR_MSG)"/>
									</xsl:otherwise>
								</xsl:choose>
								<dp:set-variable name="$ERROR_CODE_VAR_NAME" value="$ERROR_CODE"/>
								<dp:set-variable name="$ERROR_SUBCODE_VAR_NAME" value="$ERROR_SUBCODE"/>
							</xsl:when>
						</xsl:choose>
						<!-- Retrieve the policy config node id -->
						<xsl:variable name="OPERATION_CONFIG_NODE_ID" select="string(dp:variable($OPERATION_CONFIG_NODE_ID_VAR_NAME))"/>
						<!-- Copy the response config child elements -->
						<xsl:variable name="ERROR_POLICY_CONFIG">
							<xsl:choose>
								<xsl:when test="$CONFIG_DOC/ServiceConfig/OperationConfig[@id =
									$OPERATION_CONFIG_NODE_ID]/ErrorPolicyConfig">
									<xsl:copy-of select="$CONFIG_DOC/ServiceConfig/OperationConfig[@id =
										$OPERATION_CONFIG_NODE_ID]/ErrorPolicyConfig"/>
								</xsl:when>
								<xsl:otherwise>
									<ErrorPolicyConfig>
										<Transform>
											<Stylesheet>local:///ESB_Services/framework/HandleErrors.xsl</Stylesheet>
										</Transform>
									</ErrorPolicyConfig>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:apply-templates select="$ERROR_POLICY_CONFIG/ErrorPolicyConfig/*" mode="processPolicyMetadata"/>
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
	<!-- Template to add timing metadata to policy config metadata -->
	<xsl:template match="ResponsePolicyConfig/*|ErrorPolicyConfig/*" mode="processPolicyMetadata">
		<xsl:copy>
			<xsl:attribute name="timerId">
				<xsl:choose>
					<xsl:when test="parent::ResponsePolicyConfig">
						<xsl:text>Res</xsl:text>
					</xsl:when>
					<!-- Implies "parent::ErrorPolicyConfig" -->
					<xsl:otherwise>
						<xsl:text>Err</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
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
