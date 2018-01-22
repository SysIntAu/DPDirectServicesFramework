<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:xop="http://www.w3.org/2004/08/xop/include"
	xmlns:dpconfig="http://www.datapower.com/param/config"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:ecore="http://www.dpdirect.org/Namespace/Enterprise/Core/V1.0"
	xmlns:eim="http://www.dpdirect.org/Namespace/Enterprise/InformationMessages/V1.0"
	xmlns:errcore="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0"
	xmlns:eam="http://www.dpdirect.org/Namespace/Enterprise/AcknowledgementMessage/V1.0"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:dp="http://www.datapower.com/extensions" 
	extension-element-prefixes="dp date regexp" version="1.0" 
	exclude-result-prefixes="dp date regexp xop dpconfig wsse scm wsse ecore eim eam">
	<!--========================================================================
		Purpose:
		A collection of common utility templates
		
		History:
		2016-10-23	v1.0	N.A.		Initial Version.
		2016-02-14	v1.1	Tim Goodwill		Update RejectToErrorFlow template.
		2016-01-28	v1.2	Tim Goodwill		Framework-only templates extracted to FrameworkUtils.xsl
		2016-03-20	v2.0	Tim Goodwill		Init MSG instance
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Constants.xsl"/>
<!-- -->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="PROPERTIES_DOC"
		select="document('local:///Json_RestAPI/config/Json_RestAPI-Properties.xml')"/>
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
	</xsl:template>
	<!-- Gets a UTC representation of the current dateTime e.g. '2016-07-28T10:10:10Z' -->
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
	<!-- Gets a UTC representation of the current dateTime e.g. '2016-07-28T10:10:10Z' -->
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
		E.g. '2016-06-28T10:10:10.100+10:00' -->
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
	<!-- Template to generate SOAP Header -->
	<xsl:template name="GenerateSOAPHeader">
		<soapenv:Header xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
			<!-- Generate the wsse:Security header -->
			<xsl:variable name="USER_NAME" select="normalize-space(dp:variable($REQ_USER_NAME_VAR_NAME))"/>
			<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
				<wsse:UsernameToken>
					<wsse:Username><xsl:value-of select="$USER_NAME"/></wsse:Username>
				</wsse:UsernameToken>
			</wsse:Security>
			<!-- Generate an ApplicationContext header  -->
			<xsl:variable name="WSA_MSGID" select="normalize-space(dp:generate-uuid())"/>
			<xsl:variable name="POLICY_LOCATION" select="normalize-space(dp:variable($OPERATION_CONFIG_NODE_ID_VAR_NAME))"/>
			<ctx:ApplicationContext
				xmlns:ctx="http://www.dpdirect.org/Namespace/ApplicationContext/Core/V1.0">
				<ctx:SessionContext>
					<ctx:UserName><xsl:value-of select="$USER_NAME"/></ctx:UserName>
					<ctx:SessionId><xsl:value-of select="$WSA_MSGID"/></ctx:SessionId>
					<ctx:CreationTime><xsl:value-of select="date:date-time()"/></ctx:CreationTime>
				</ctx:SessionContext>
				<ctx:InvocationContext>
					<ctx:Call>
						<ctx:BranchIndex>1</ctx:BranchIndex>
						<ctx:CallerName>MSG</ctx:CallerName>
						<ctx:CallerLocation><xsl:value-of select="$POLICY_LOCATION"/></ctx:CallerLocation>
					</ctx:Call>
				</ctx:InvocationContext>
			</ctx:ApplicationContext>
		</soapenv:Header>
	</xsl:template>
	<!-- Template to generate acknowledement message -->
	<xsl:template name="GenerateAcknowledgementMsg">
		<xsl:param name="ENDPOINT_URL"/>
		<xsl:param name="INFORMATION_CODE" select="'FRWK00027'"/>
		<xsl:param name="DESCRIPTION_TEXT" select="'Request operation completed successfully'"/>
		<xsl:param name="ACKNOWLEDGEMENT" select="'SUCCESS'"/>
		<eam:AcknowledgementMessage
			xmlns:ecore="http://www.dpdirect.org/Namespace/Enterprise/Core/V1.0"
			xmlns:eim="http://www.dpdirect.org/Namespace/Enterprise/InformationMessages/V1.0"
			xmlns:errcore="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0"
			xmlns:eam="http://www.dpdirect.org/Namespace/Enterprise/AcknowledgementMessage/V1.0">
			<eim:Informations>
				<eim:Information>
					<xsl:if test="$ENDPOINT_URL != ''">
						<!-- Strip out known patterns of local IP addresses from URL -->
						<xsl:variable name="SAFE_URL" select="regexp:replace($ENDPOINT_URL, '(https*://)\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:*\d{0,4}\b', 'g', '$1(IP-removed)')"/>
						<errcore:SubDescription>
							<xsl:value-of select="concat('Endpoint URL ',$SAFE_URL)"/>
						</errcore:SubDescription>
					</xsl:if>
					<errcore:Description>
						<xsl:value-of select="$DESCRIPTION_TEXT"/>
					</errcore:Description>
					<errcore:InformationCode>
						<xsl:value-of select="$INFORMATION_CODE"/>
					</errcore:InformationCode>
					<errcore:MessageOrigin>
						<xsl:value-of select="$OPERATION_CONFIG_NODE_ID"/>
					</errcore:MessageOrigin>
					<errcore:SubCode>
						<xsl:text>MSG</xsl:text>
					</errcore:SubCode>
				</eim:Information>
			</eim:Informations>
			<ecore:Acknowledgement><xsl:value-of select="$ACKNOWLEDGEMENT"/></ecore:Acknowledgement>
		</eam:AcknowledgementMessage>
	</xsl:template>
</xsl:stylesheet>
