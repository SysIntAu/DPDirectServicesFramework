<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:logcore="http://www.dpdirect.org/Namespace/EnterpriseLogging/Core/V1.0"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" version="1.0"
	exclude-result-prefixes="dp logcore">
	<!--========================================================================
		History:
		2016-03-06	v1.0	N.A.		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<!-- The current system time (milliseconds value) -->
	<xsl:variable name="CURRENT_TIME" select="dp:time-value()"/>
	<!-- The unique identifier of the text format output msg -->
	<xsl:variable name="MSG_FORMAT_ID" select="'STSLogMsg'"/>
	<!-- The version of the text format output msg -->
	<xsl:variable name="MSG_VERSION" select="'1.0'"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- Determine the name of the stats log category (must be unique for each domain) -->
		<xsl:variable name="STATS_LOG_CATEGORY" select="concat(string(dp:variable($DP_SERVICE_DOMAIN_NAME)), $DPDIRECT.LOGCAT_DPDIRECT.STATS_SUFFIX)"/>
		<xsl:variable name="ERROR_CODE" select="string(dp:variable($DP_SERVICE_ERROR_CODE))"/>
		<xsl:variable name="OUT_MSG_ROOT_NAME">
			<xsl:call-template name="GetOutputMsgRootName"/>
		</xsl:variable>
		<xsl:if test="dp:responding() = true()">
			<dp:set-variable name="$STATS_LOG_RES_ROOT_VAR_NAME" value="$OUT_MSG_ROOT_NAME"/>
		</xsl:if>
		<!-- Calculate some derived times -->
		<xsl:variable name="START_TIME_MILLIS" select="dp:variable($TIMER_START_VAR_NAME)"/>
		<xsl:variable name="CURRENT_TIME" select="dp:time-value()"/>
		<xsl:variable name="TOTAL_ELAPSED_MILLIS" select="number($CURRENT_TIME - $START_TIME_MILLIS)"/>
		<!-- Response message -->
		<xsl:variable name="SERVICE_RES_MSG">
			<xsl:choose>
				<xsl:when test="/*[local-name() = 'Envelope']">
					<xsl:value-of select="local-name(/*[local-name() = 'Envelope'][1]/*[local-name() = 'Body'][1]/*[1])"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="local-name(/*[1])"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="SERVICE_RESULT">
			<xsl:choose>
				<xsl:when test="normalize-space($SERVICE_RES_MSG) = 'Fault'">
					<xsl:value-of select="'fault'"/>
				</xsl:when>
				<xsl:when test="$ERROR_CODE = $DP_INTERNAL_FAULT_EVENT_CODE">
					<xsl:value-of select="'error'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'completed'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="STATS_REPORT">
			<xsl:value-of select="'[ServiceStats] '"/>
			<xsl:text>ServiceName=</xsl:text>
			<xsl:value-of select="'SecureTokenService'"/>
			<xsl:text>,</xsl:text>
			<xsl:text>ServiceResult=</xsl:text>
			<xsl:value-of select="$SERVICE_RESULT"/>
			<xsl:text>,</xsl:text>
			<xsl:text>Username=</xsl:text>
			<xsl:value-of select="dp:variable($REQ_USER_NAME_VAR_NAME)"/>
			<xsl:text>,</xsl:text>
			<!-- Check if response attributes are required -->
			<xsl:if test="dp:responding() = true()">
				<!-- InMsgNm_res -->
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ResMsgName'"/>
					<xsl:with-param name="VALUE" select="$SERVICE_RES_MSG"/>
				</xsl:call-template>
			</xsl:if>
			<!-- msgVersion -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'msgVersion'"/>
				<xsl:with-param name="VALUE" select="$MSG_VERSION"/>
			</xsl:call-template>
			<!-- ServiceHost -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'ServiceHost'"/>
				<xsl:with-param name="VALUE" select="dp:variable($DP_SERVICE_LOCAL_SERVICE_ADDRESS)"/>
			</xsl:call-template>
			<!-- Domain -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'Domain'"/>
				<xsl:with-param name="VALUE" select="dp:variable($DP_SERVICE_DOMAIN_NAME)"/>
			</xsl:call-template>
			<!-- Check if there is an error -->
			<xsl:if test="normalize-space($ERROR_CODE) != ''">
				<!-- ErrCode -->
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ErrorCode'"/>
					<xsl:with-param name="VALUE" select="$ERROR_CODE"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="normalize-space(dp:variable($DP_SERVICE_ERROR_SUBCODE)) != ''">
				<!-- ErrSubCode -->
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ErrorSubCode'"/>
					<xsl:with-param name="VALUE" select="dp:variable($DP_SERVICE_ERROR_SUBCODE)"/>
				</xsl:call-template>
			</xsl:if>
			<!-- Check if response attributes are required -->
			<xsl:if test="dp:responding() = true()">
				<!-- OutMsgRoot_res -->
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ResMsgRoot_Out'"/>
					<xsl:with-param name="VALUE" select="$SERVICE_RES_MSG"/>
				</xsl:call-template>
				<xsl:text>,TotalElapsedMillis=</xsl:text>
				<xsl:value-of select="$TOTAL_ELAPSED_MILLIS"/>
			</xsl:if>
			<xsl:if test="dp:variable($REQ_WSA_TO_VAR_NAME) != ''">
				<xsl:text>WSATo=</xsl:text>
				<xsl:value-of select="dp:variable($REQ_WSA_TO_VAR_NAME)"/>
				<xsl:text>,</xsl:text>
			</xsl:if>
			<xsl:if test="dp:variable($REQ_WSA_REPLY_TO_VAR_NAME) != ''">
				<xsl:text>WSAReplyTo=</xsl:text>
				<xsl:value-of select="dp:variable($REQ_WSA_REPLY_TO_VAR_NAME)"/>
				<xsl:text>,</xsl:text>
			</xsl:if>
			<xsl:text>WSAMsgId=</xsl:text>
			<xsl:value-of select="concat('wsaid:', dp:variable($REQ_WSA_MSG_ID_VAR_NAME))"/>
			<xsl:if test="dp:variable($TRANSACTION_ID_VAR_NAME) != ''">
				<xsl:text>,</xsl:text>
				<xsl:text>TransactionId=</xsl:text>
				<xsl:value-of select="dp:variable($TRANSACTION_ID_VAR_NAME)"/>
			</xsl:if>
		</xsl:variable>
		<!-- Invoke the log targets via the dp extensions to the 'xsl:message' instruction -->
		<xsl:message dp:type="{$STATS_LOG_CATEGORY}" dp:priority="{$DP_LOG_LEVEL_NOTICE}">
			<!--<xsl:copy-of select="$STATS_REPORT"/>-->
			<xsl:value-of select="$STATS_REPORT"/>
		</xsl:message>
		<xsl:if test="normalize-space($ERROR_CODE) = ''">
			<!-- Output a 'Success' message to the syslog -->
			<xsl:call-template name="WriteSysLogDebugMsg">
				<xsl:with-param name="MSG" select="'OutboundResponse. Service flow completed without error'"/>
				<xsl:with-param name="LOG_EVENT_KEY" select="$LOG_EVENT_KEY_SUCCESS"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<!-- Modal Identity template -->
	<xsl:template match="node()|@*" mode="createStatsReport">
		<xsl:apply-templates select="@*|node()" mode="createStatsReport"/>
	</xsl:template>
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to format a single log attribute -->
	<xsl:template name="FormatLogAttribute">
		<xsl:param name="KEY"/>
		<xsl:param name="VALUE"/>
		<xsl:value-of select="concat($KEY,'=',$VALUE,',')"/>
	</xsl:template>
	<!-- Template to get the XML Namespace "qualified name" of the output message root element (taken from the current RESULT_DOC context) -->
	<xsl:template name="GetOutputMsgRootName">
		<xsl:choose>
			<xsl:when test="/*[local-name() = 'Envelope']">
				<xsl:text>{</xsl:text>
				<xsl:value-of select="normalize-space(namespace-uri(/*[local-name() =
					'Envelope'][1]/*[local-name() = 'Body'][1]/*[1]))"/>
				<xsl:text>}</xsl:text>
				<xsl:value-of select="local-name(/*[local-name() = 'Envelope'][1]/*[local-name() = 'Body'][1]/*[1])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="normalize-space(namespace-uri(/*[1])) != ''">
					<xsl:text>{</xsl:text>
					<xsl:value-of select="normalize-space(namespace-uri(/*[1]))"/>
					<xsl:text>}</xsl:text>
				</xsl:if>
				<xsl:value-of select="local-name(/*[1])"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
