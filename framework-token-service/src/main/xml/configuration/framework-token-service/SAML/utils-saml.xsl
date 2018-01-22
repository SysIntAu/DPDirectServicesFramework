<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:dp="http://www.datapower.com/extensions" 
	extension-element-prefixes="dp date regexp"
	exclude-result-prefixes="dp date regexp"
	version="1.0">
	<!--========================================================================
		Purpose:
		A collection of common utility templates.
		
		History:
		2016-03-25	v1.0	Chris Sherlock		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Constants.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="SERVICE_LOG_CATEGORY" select="concat(string(dp:variable($DP_SERVICE_DOMAIN_NAME)), $DPDIRECT.LOGCAT_DPDIRECT.SERVICE_SUFFIX)"/>
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
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
	<xsl:template name="NewLogMessage">
		<xsl:param name="MSG"/>
		<xsl:param name="KEY_VALUES"/>
		<xsl:variable name="REQ_WSA_MSG_ID" select="normalize-space(dp:variable($REQ_WSA_MSG_ID_VAR_NAME))"/>
		<xsl:variable name="RES_WSA_MSG_ID" select="normalize-space(dp:variable($RES_WSA_MSG_ID_VAR_NAME))"/>
		<xsl:variable name="TX_DIRECTION" select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
		<xsl:text>Timestamp=</xsl:text>
		<xsl:call-template name="GetCurrentDateTimeWithMillis"/>
		<xsl:if test="$DP_SERVICE_TRANSACTION_RULE_NAME != ''">
			<xsl:text>,TxRuleName=</xsl:text>
			<xsl:value-of select="$DP_SERVICE_TRANSACTION_RULE_NAME"/>
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
			<xsl:value-of select="'SecureTokenService'"/>
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
		<xsl:if test="$RES_WSA_MSG_ID != ''">
			<xsl:text>,ResponseWSAMsgId=</xsl:text>
			<xsl:value-of select="$RES_WSA_MSG_ID"/>
		</xsl:if>
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
	<xsl:template name="generateFault">
		<xsl:param name="FAULTCODE"/>
		<xsl:param name="FAULTSTRING"/>
		<soap:Envelope>
			<soap:Body>
				<soap:Fault>
					<faultcode>
						<xsl:value-of select="string($FAULTCODE)"/>
					</faultcode>
					<faultstring>
						<xsl:value-of select="string($FAULTSTRING)"/>
					</faultstring>
				</soap:Fault>
			</soap:Body>
		</soap:Envelope>
	</xsl:template>
</xsl:stylesheet>
