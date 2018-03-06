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
	xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:xop="http://www.w3.org/2004/08/xop/include"
	xmlns:dpconfig="http://www.datapower.com/param/config"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:err="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0"
	xmlns:ack="http://www.dpdirect.org/Namespace/Enterprise/AcknowledgementMessage/V1.0"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:dp="http://www.datapower.com/extensions" 
	extension-element-prefixes="dp date regexp" version="1.0" 
	exclude-result-prefixes="dp date regexp xop dpconfig wsse scm wsse ack">
	<!--========================================================================
		Purpose:
		A collection of common utility templates
		
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		2016-12-12	v2.0	Tim Goodwill		Init Gateway  instance
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Constants.xsl"/>
	<xsl:include href="MqConstants.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="PROPERTIES_DOC"
		select="document('local:///ESB_Services/config/ESB_Services-Properties.xml')"/>
	<xsl:variable name="DPDIRECT.STREAM_NAME" select="substring-before(dp:variable($DP_SERVICE_PROCESSOR_NAME), $SERVICES_PROXY_NAME_SUFFIX)"/>
	<xsl:variable name="OPERATION_CONFIG_NODE_ID" select="normalize-space(dp:variable($OPERATION_CONFIG_NODE_ID_VAR_NAME))"/>
	<xsl:variable name="THIS_SERVICE_NAME" select="normalize-space(regexp:replace($OPERATION_CONFIG_NODE_ID, '-.*$', 'i', ''))"/>
	<!-- Determine the name of the service log category (must be unique for each domain) -->
	<xsl:variable name="SERVICE_LOG_CATEGORY" select="concat(string(dp:variable($DP_SERVICE_DOMAIN_NAME)), $DPDIRECT.LOGCAT_DPDIRECT.SERVICE_SUFFIX)"/>
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to get a value from the local properties file -->
	<xsl:template name="GetDPDirectProperty">
		<xsl:param name="KEY"/>
		<xsl:choose>
			<xsl:when test="not($PROPERTIES_DOC/PropertiesList/Property[@key = $KEY])">
				<xsl:call-template name="WriteSysLogErrorMsg">
					<xsl:with-param name="MSG">
						<xsl:text>No entry in properties file for configuration property '</xsl:text>
						<xsl:value-of select="$KEY"/>
						<xsl:text>'</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
				<xsl:value-of select="''"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space(($PROPERTIES_DOC/PropertiesList/Property[@key =
					$KEY]/@value)[1])"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Rejects to the error flow and sets the local context versions of the error code, subcode and message variables -->
	<xsl:template name="RejectToErrorFlow">
		<xsl:param name="MSG"/>
		<xsl:param name="ERROR_CODE" select="dp:variable($DP_SERVICE_ERROR_CODE)"/>
		<xsl:param name="ERROR_DOMAIN" select="$DPDIRECT.STREAM_NAME"/>
		<xsl:param name="SERVICE_NAME" select="$THIS_SERVICE_NAME"/>
		<xsl:param name="PROVIDER_NAME" select="''"/>
		<xsl:param name="ORIGINATOR_NAME" select="''"/>
		<xsl:param name="ORIGINATOR_LOC" select="''"/>
		<xsl:param name="ADD_DETAILS" select="''"/>
		<xsl:if test="normalize-space($ERROR_CODE) != ''">
			<!-- Store error information (which is otherwise not accessible in the error flow as the dp:reject call results in a generic error code for filter rejection) -->
			<dp:set-variable name="$ERROR_MSG_VAR_NAME" value="string($MSG)"/>
			<dp:set-variable name="$ERROR_CODE_VAR_NAME" value="string($ERROR_CODE)"/>
			<dp:set-variable name="$EVENT_CODE_VAR_NAME" value="dp:variable($DP_SERVICE_ERROR_CODE)"/>
			<dp:set-variable name="$EVENT_SUBCODE_VAR_NAME" value="dp:variable($DP_SERVICE_ERROR_SUBCODE)"/>
			<dp:set-variable name="$EVENT_MESSAGE_VAR_NAME" value="dp:variable($DP_SERVICE_ERROR_MSG)"/>
			<dp:set-variable name="$ERROR_DOMAIN_VAR_NAME" value="string($ERROR_DOMAIN)"/>
			<dp:set-variable name="$ERROR_SERVICE_NAME_VAR_NAME" value="string($SERVICE_NAME)"/>
			<dp:set-variable name="$ERROR_PROVIDER_NAME_VAR_NAME" value="string($PROVIDER_NAME)"/>
			<dp:set-variable name="$ERROR_ORIG_NAME_VAR_NAME" value="string($ORIGINATOR_NAME)"/>
			<dp:set-variable name="$ERROR_ORIG_LOC_VAR_NAME" value="string($ORIGINATOR_LOC)"/>
			<dp:set-variable name="$ERROR_ADD_DETAILS_VAR_NAME" value="string($ADD_DETAILS)"/>
		</xsl:if>
		<!-- Reject the message -->
		<dp:reject override="true">
			<xsl:value-of select="$MSG"/>
		</dp:reject>
	</xsl:template>
	<!-- Templates to write a custom message to the syslog -->
	<xsl:template name="WriteSysLogDebugMsg">
		<xsl:param name="MSG"/>
		<xsl:param name="KEY_VALUES"/>
		<xsl:param name="LOG_EVENT_KEY"/>
		<!-- Write the message to the syslog -->
		<xsl:message dp:type="{$SERVICE_LOG_CATEGORY}" dp:priority="{$DP_LOG_LEVEL_DEBUG}">
			<xsl:if test="normalize-space($LOG_EVENT_KEY) != ''">
				<xsl:text>[</xsl:text>
				<xsl:value-of select="$LOG_EVENT_KEY"/>
				<xsl:text>]&#x020;</xsl:text>
			</xsl:if>
			<xsl:call-template name="NewLogMessage">
				<xsl:with-param name="MSG" select="$MSG"/>
				<xsl:with-param name="KEY_VALUES" select="$KEY_VALUES"/>
			</xsl:call-template>
		</xsl:message>
	</xsl:template>
	<xsl:template name="WriteSysLogInfoMsg">
		<xsl:param name="MSG"/>
		<xsl:param name="KEY_VALUES"/>
		<xsl:param name="LOG_EVENT_KEY"/>
		<!-- Write the message to the syslog -->
		<xsl:message dp:type="{$SERVICE_LOG_CATEGORY}" dp:priority="{$DP_LOG_LEVEL_INFO}">
			<xsl:if test="normalize-space($LOG_EVENT_KEY) != ''">
				<xsl:text>[</xsl:text>
				<xsl:value-of select="$LOG_EVENT_KEY"/>
				<xsl:text>]&#x020;</xsl:text>
			</xsl:if>
			<xsl:call-template name="NewLogMessage">
				<xsl:with-param name="MSG" select="$MSG"/>
				<xsl:with-param name="KEY_VALUES" select="$KEY_VALUES"/>
			</xsl:call-template>
		</xsl:message>
	</xsl:template>
	<xsl:template name="WriteSysLogNoticeMsg">
		<xsl:param name="MSG"/>
		<xsl:param name="KEY_VALUES"/>
		<xsl:param name="LOG_EVENT_KEY"/>
		<!-- Write the message to the syslog -->
		<xsl:message dp:type="{$SERVICE_LOG_CATEGORY}" dp:priority="{$DP_LOG_LEVEL_NOTICE}">
			<xsl:if test="normalize-space($LOG_EVENT_KEY) != ''">
				<xsl:text>[</xsl:text>
				<xsl:value-of select="$LOG_EVENT_KEY"/>
				<xsl:text>]&#x020;</xsl:text>
			</xsl:if>
			<xsl:call-template name="NewLogMessage">
				<xsl:with-param name="MSG" select="$MSG"/>
				<xsl:with-param name="KEY_VALUES" select="$KEY_VALUES"/>
			</xsl:call-template>
		</xsl:message>
	</xsl:template>
	<xsl:template name="WriteSysLogWarnMsg">
		<xsl:param name="MSG"/>
		<xsl:param name="KEY_VALUES"/>
		<xsl:param name="LOG_EVENT_KEY" select="$LOG_EVENT_KEY_EVENT"/>
		<!-- Write the message to the syslog -->
		<xsl:message dp:type="{$SERVICE_LOG_CATEGORY}" dp:priority="{$DP_LOG_LEVEL_WARN}">
			<xsl:text>[</xsl:text>
			<xsl:value-of select="$LOG_EVENT_KEY"/>
			<xsl:text>]&#x020;</xsl:text>
			<xsl:call-template name="NewLogMessage">
				<xsl:with-param name="MSG" select="$MSG"/>
				<xsl:with-param name="KEY_VALUES" select="$KEY_VALUES"/>
			</xsl:call-template>
		</xsl:message>
	</xsl:template>
	<xsl:template name="WriteSysLogErrorMsg">
		<xsl:param name="MSG"/>
		<xsl:param name="KEY_VALUES"/>
		<xsl:param name="LOG_EVENT_KEY" select="$LOG_EVENT_KEY_ERROR"/>
		<!-- Write the message to the syslog -->
		<xsl:message dp:type="{$SERVICE_LOG_CATEGORY}" dp:priority="{$DP_LOG_LEVEL_ERROR}">
			<xsl:text>[</xsl:text>
			<xsl:value-of select="$LOG_EVENT_KEY"/>
			<xsl:text>]&#x020;</xsl:text>
			<xsl:call-template name="NewLogMessage">
				<xsl:with-param name="MSG" select="$MSG"/>
				<xsl:with-param name="KEY_VALUES" select="$KEY_VALUES"/>
			</xsl:call-template>
		</xsl:message>
	</xsl:template>
	<xsl:template name="NewLogMessage">
		<xsl:param name="MSG"/>
		<xsl:param name="KEY_VALUES"/>
		<xsl:variable name="REQ_WSA_MSG_ID" select="normalize-space(dp:variable($REQ_WSA_MSG_ID_VAR_NAME))"/>
		<xsl:variable name="REQ_WSA_RELATES_TO" select="normalize-space(dp:variable($REQ_WSA_RELATES_TO_VAR_NAME))"/>
		<xsl:variable name="RES_WSA_MSG_ID" select="normalize-space(dp:variable($RES_WSA_MSG_ID_VAR_NAME))"/>
		<xsl:variable name="TX_DIRECTION" select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
		<xsl:text>Timestamp=</xsl:text>
		<xsl:call-template name="GetCurrentDateTimeWithMillis"/>
		<xsl:if test="$OPERATION_CONFIG_NODE_ID != ''">
			<xsl:text>,OperationId=</xsl:text>
			<xsl:value-of select="$OPERATION_CONFIG_NODE_ID"/>
		</xsl:if>
		<xsl:if test="normalize-space($MSG) != ''">
			<xsl:text>,LogMsg=</xsl:text>
			<xsl:value-of select="normalize-space($MSG)"/>
		</xsl:if>
		<xsl:if test="normalize-space($KEY_VALUES) != ''">
			<xsl:text>,</xsl:text>
			<xsl:value-of select="normalize-space($KEY_VALUES)"/>
		</xsl:if>
		<xsl:if test="$TX_DIRECTION = 'error'">
			<xsl:text>,ServiceIdentifier=</xsl:text>
			<xsl:value-of select="dp:variable($SERVICE_IDENTIFIER_VAR_NAME)"/>
			<xsl:if test="not(contains($KEY_VALUES, 'ServiceUrlIn'))">
				<xsl:text>,ServiceUrlIn='</xsl:text>
				<xsl:value-of select="dp:variable($DP_SERVICE_URL_IN)"/>
				<xsl:text>'</xsl:text>
			</xsl:if>
			<xsl:if test="not(contains($KEY_VALUES, 'ServiceUrlOut'))">
				<xsl:text>,ServiceUrlOut='</xsl:text>
				<xsl:value-of select="dp:variable($DP_SERVICE_URL_OUT)"/>
				<xsl:text>'</xsl:text>
			</xsl:if>
		</xsl:if>
		<xsl:text>,Username=</xsl:text>
		<xsl:value-of select="dp:variable($REQ_USER_NAME_VAR_NAME)"/>
		<xsl:if test="dp:variable($TRANSACTION_ID_VAR_NAME) != ''">
			<xsl:text>,TransactionId=</xsl:text>
			<xsl:value-of select="dp:variable($TRANSACTION_ID_VAR_NAME)"/>
		</xsl:if>
		<xsl:text>,WSAMsgId=</xsl:text>
		<xsl:value-of select="$REQ_WSA_MSG_ID"/>
		<xsl:if test="$REQ_WSA_RELATES_TO != ''">
			<xsl:text>,WSARelatesTo=</xsl:text>
			<xsl:value-of select="$REQ_WSA_RELATES_TO"/>
		</xsl:if>
		<xsl:if test="$RES_WSA_MSG_ID != ''">
			<xsl:text>,ResponseWSAMsgId=</xsl:text>
			<xsl:value-of select="$RES_WSA_MSG_ID"/>
		</xsl:if>
	</xsl:template>
	<!-- Template to track msg identifiers across protocol and service boundries -->
	<xsl:template name="StoreMsgIdentifier">
		<xsl:param name="TYPE" select="''"/>
		<xsl:param name="APPLIES_TO" select="''"/>
		<xsl:param name="IDENTIFIER_VALUE" select="''"/>
		<xsl:variable name="MSG_IDENTIFIERS">
			<xsl:call-template name="GetMsgIdentifiers"/>
		</xsl:variable>
		<xsl:variable name="NEW_MSG_IDENTIFIERS">
			<logcore:MsgIdentifiers xmlns:logcore="http://www.dpdirect.org/Namespace/EnterpriseLogging/Core/V1.0">
				<!-- Copy through existing message identifiers -->
				<xsl:copy-of select="$MSG_IDENTIFIERS//logcore:Identifier"/>
				<!-- Add the new message identifier if not already captured -->
				<xsl:if test="not($MSG_IDENTIFIERS//logcore:Identifier[text() = string($IDENTIFIER_VALUE)])">
					<logcore:Identifier type="{$TYPE}" appliesTo="{$APPLIES_TO}">
						<xsl:value-of select="$IDENTIFIER_VALUE"/>
					</logcore:Identifier>
				</xsl:if>
			</logcore:MsgIdentifiers>
		</xsl:variable>
		<dp:set-variable name="$MSG_IDENTIFIERS_VAR_NAME" value="$NEW_MSG_IDENTIFIERS"/>
	</xsl:template>
	<!-- Template to track msg identifiers across protocol and service boundries -->
	<xsl:template name="GetMsgIdentifiers">
		<xsl:variable name="MSG_IDENTIFIERS" select="dp:variable($MSG_IDENTIFIERS_VAR_NAME)"/>
		<xsl:choose>
			<xsl:when test="$MSG_IDENTIFIERS/*">
				<xsl:copy-of select="$MSG_IDENTIFIERS"/>
			</xsl:when>
			<xsl:otherwise>
				<logcore:MsgIdentifiers xmlns:logcore="http://www.dpdirect.org/Namespace/EnterpriseLogging/Core/V1.0"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Gets a UTC representation of the current dateTime e.g. '2016-12-12T10:10:10Z' -->
	<xsl:template name="GetCurrentUTCDateTime">
		<xsl:value-of select="date:add(date:date-time(),'PT0H')"/>
	</xsl:template>
	<!-- Gets a 'YYYYMMDD' formatted representation of the current UTC date (used for MQ PutDate) -->
	<xsl:template name="GetCurrentUTCDateAsYYYYMMDD">
		<xsl:value-of select="substring(translate(date:add(date:date-time(),'PT0H'),'-&#x20;',''),1,8)"/>
	</xsl:template>
	<!-- Gets a 'HHMMSSTH' formatted representation of the current UTC time (used for MQ PutTime) -->
	<xsl:template name="GetCurrentUTCTimeAsHHMMSSTH">
		<xsl:variable name="TIME_VALUE" select="dp:time-value()"/>
		<!-- Append hundreths of a second -->
		<xsl:variable name="TEMPLATE" select="concat('000000',substring($TIME_VALUE,string-length($TIME_VALUE)-2),2)"/>
		<xsl:variable name="TIME_DIGITS"
			select="translate(substring-after(date:add(date:date-time(),'PT0H'),'T'),':.Z&#x20;','')"/>
		<xsl:value-of select="concat($TIME_DIGITS,substring($TEMPLATE,string-length($TIME_DIGITS)+1,(8 - string-length($TIME_DIGITS))))"/>
	</xsl:template>
	<!-- Gets current dateTime -->
	<xsl:template name="GetCurrentDateTime">
		<xsl:value-of select="date:date-time()"/>
	</xsl:template>
	<!-- Gets a 'YYYYMMDD' formatted representation of the current local date -->
	<xsl:template name="GetCurrentDateAsYYYYMMDD">
		<xsl:value-of select="substring(translate(date:date-time(),'-&#x20;',''),1,8)"/>
	</xsl:template>
	<!-- Gets a 'HHMMSSTH' formatted representation of the current local time -->
	<xsl:template name="GetCurrentTimeAsHHMMSSTH">
		<xsl:variable name="TIME_VALUE" select="dp:time-value()"/>
		<!-- Append hundreths of a second -->
		<xsl:variable name="TEMPLATE" select="concat('000000',substring($TIME_VALUE,string-length($TIME_VALUE)-2),2)"/>
		<xsl:variable name="TIME_DIGITS"
			select="translate(substring-after(date:date-time(),'T'),':.Z&#x20;','')"/>
		<xsl:value-of select="concat($TIME_DIGITS,substring($TEMPLATE,string-length($TIME_DIGITS)+1,(8 - string-length($TIME_DIGITS))))"/>
	</xsl:template>
	<!-- Gets an ISO8601 representation of the current date time
		to the millisecond (append the dp:time-value() function output)
		E.g. '2016-12-12T10:10:10.100+10:00' -->
	<xsl:template name="GetCurrentDateTimeWithMillis">
		<xsl:variable name="DATE_TIME" select="date:date-time()"/>
		<xsl:variable name="TIME_MILLIS" select="dp:time-value()"/>
		<xsl:value-of select="concat(substring($DATE_TIME,1,19),'.',substring($TIME_MILLIS,string-length($TIME_MILLIS)
			- 2,3),substring($DATE_TIME,20))"/>
	</xsl:template>
	<!-- Gets the request MQMD header -->
	<xsl:template name="GetReqMQMD">
		<xsl:variable name="UNPARSED_MQMD" select="dp:request-header('MQMD')"/>
		<xsl:if test="$UNPARSED_MQMD != ''">
			<xsl:variable name="CURRENT_MQMD" select="dp:parse($UNPARSED_MQMD)"/>
			<xsl:copy-of select="$CURRENT_MQMD"/>
		</xsl:if>
	</xsl:template>
	<!-- Gets the current request MQMD header -->
	<xsl:template name="GetBackendReqMQMD">
		<xsl:variable name="UNPARSED_MQMD" select="dp:request-header('MQMD')"/>
		<xsl:if test="$UNPARSED_MQMD != ''">
			<xsl:variable name="CURRENT_MQMD" select="dp:parse($UNPARSED_MQMD)"/>
			<xsl:copy-of select="$CURRENT_MQMD"/>
		</xsl:if>
	</xsl:template>
	<!-- Gets the current response MQMD header -->
	<xsl:template name="GetCurrentResMQMD">
		<xsl:variable name="UNPARSED_MQMD" select="dp:response-header('MQMD')"/>
		<xsl:if test="$UNPARSED_MQMD != ''">
			<xsl:variable name="CURRENT_MQMD" select="dp:parse($UNPARSED_MQMD)"/>
			<xsl:copy-of select="$CURRENT_MQMD"/>
		</xsl:if>
	</xsl:template>
	<!-- Template to retrieve Headers and return under a <Headers> parent element -->
	<xsl:template name="GetHeaders">
		<xsl:element name="Headers">
			<xsl:for-each select="dp:variable($DP_SERVICE_HEADER_MANIFEST)/headers/*[not(substring(child::text(), 1, 2) = 'X-')]">
				<xsl:variable name="HEADER_NAME" select="normalize-space(.)"/>	
				<xsl:variable name="HEADER_CONTENT">
					<xsl:choose>
						<xsl:when test="dp:responding()">
							<xsl:value-of select="dp:response-header($HEADER_NAME)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="dp:request-header($HEADER_NAME)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="normalize-space($HEADER_CONTENT) != ''
						and ($HEADER_NAME = 'MQMD'
						or $HEADER_NAME = 'MQRFH2')">
						<xsl:element name="{$HEADER_NAME}">
							<xsl:copy-of select="dp:parse($HEADER_CONTENT)"/>
						</xsl:element>
					</xsl:when>
					<xsl:when test="normalize-space($HEADER_CONTENT) != ''">
						<xsl:element name="{$HEADER_NAME}">
							<xsl:copy-of select="$HEADER_CONTENT"/>
						</xsl:element>
					</xsl:when>
				</xsl:choose>			
			</xsl:for-each>
		</xsl:element>
	</xsl:template>
	<!-- Template to generate acknowledement message -->
	<xsl:template name="GenerateAcknowledgementMsg">
		<xsl:param name="ENDPOINT_URL"/>
		<xsl:param name="INFORMATION_CODE" select="'FRMWK0030'"/>
		<xsl:param name="DESCRIPTION_TEXT" select="'Request operation completed successfully'"/>
		<xsl:param name="ACKNOWLEDGEMENT" select="'SUCCESS'"/>
		<ack:AcknowledgementMessage>
			<ack:Acknowledgement><xsl:value-of select="$ACKNOWLEDGEMENT"/></ack:Acknowledgement>
			<xsl:if test="$ENDPOINT_URL != ''">
				<!-- Strip out known patterns of local IP addresses from URL -->
				<xsl:variable name="SAFE_URL" select="regexp:replace($ENDPOINT_URL, '(https*://)\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:*\d{0,4}\b', 'g', '$1(IP-removed)')"/>
				<ack:SubDescription>
					<xsl:value-of select="concat('Endpoint URL ',$SAFE_URL)"/>
				</ack:SubDescription>
			</xsl:if>
			<ack:Description>
				<xsl:value-of select="$DESCRIPTION_TEXT"/>
			</ack:Description>
			<ack:Code>
				<xsl:value-of select="$INFORMATION_CODE"/>
			</ack:Code>
			<ack:MessageOrigin>
				<xsl:value-of select="$OPERATION_CONFIG_NODE_ID"/>
			</ack:MessageOrigin>
			<ack:SubCode>
				<xsl:text>MSG</xsl:text>
			</ack:SubCode>
		</ack:AcknowledgementMessage>
	</xsl:template>
</xsl:stylesheet>
