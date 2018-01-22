<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:logcore="http://www.dpdirect.org/Namespace/EnterpriseLogging/Core/V1.0"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" version="1.0"
	exclude-result-prefixes="dp logcore">
	<!--========================================================================
		Purpose:
		Logs statistics and metadata from the current transaction flow.
		
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
	<xsl:variable name="MSG_FORMAT_ID" select="'MSGServicesLogMsg'"/>
	<!-- The version of the text format output msg -->
	<xsl:variable name="MSG_VERSION" select="'1.0'"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- Determine the name of the stats log category (must be unique for each domain) -->
		<xsl:variable name="STATS_LOG_CATEGORY" select="concat(string(dp:variable($DP_SERVICE_DOMAIN_NAME)), $DPDIRECT.LOGCAT_DPDIRECT.STATS_SUFFIX)"/>
		<xsl:variable name="ERROR_CODE" select="string(dp:variable($ERROR_CODE_VAR_NAME))"/>
		<xsl:variable name="OUT_MSG_ROOT_NAME">
			<xsl:call-template name="GetOutputMsgRootName"/>
		</xsl:variable>
		<xsl:choose>
			<!-- Last action in the response flow or an error in the response flow -->
			<xsl:when test="dp:responding() = true()">
				<dp:set-variable name="$STATS_LOG_RES_OUTMSG_ROOT_VAR_NAME" value="$OUT_MSG_ROOT_NAME"/>
			</xsl:when>
			<!-- Error in request flow -->
			<xsl:otherwise>
				<dp:set-variable name="$STATS_LOG_REQ_OUTMSG_ROOT_VAR_NAME" value="$OUT_MSG_ROOT_NAME"/>
			</xsl:otherwise>
		</xsl:choose>
		<!-- Calculate some derived times -->
		<xsl:variable name="START_MILLIS" select="dp:variable(concat($TIMER_START_BASEVAR_NAME,'RequestFlow'))"/>
		<xsl:variable name="ERR_MILLIS">
			<xsl:variable name="ERR_MILLIS_VAR" select="dp:variable(concat($TIMER_ELAPSED_BASEVAR_NAME,'ErrorFlow'))"/>
			<xsl:choose>
				<xsl:when test="string(number($ERR_MILLIS_VAR)) != 'NaN'">
					<xsl:value-of select="number($ERR_MILLIS_VAR)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="0"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="TOTAL_MILLIS" select="number($CURRENT_TIME - $START_MILLIS)"/>
		<xsl:variable name="REQ_MILLIS">
			<xsl:variable name="REQ_MILLIS_VAR" select="dp:variable(concat($TIMER_ELAPSED_BASEVAR_NAME,'RequestFlow'))"/>
			<xsl:choose>
				<xsl:when test="string(number($REQ_MILLIS_VAR)) != 'NaN'">
					<xsl:value-of select="number($REQ_MILLIS_VAR)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="number($TOTAL_MILLIS - $ERR_MILLIS)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="RES_MILLIS">
			<xsl:variable name="RES_MILLIS_VAR" select="dp:variable(concat($TIMER_ELAPSED_BASEVAR_NAME,'ResponseFlow'))"/>
			<xsl:choose>
				<xsl:when test="string(number($RES_MILLIS_VAR)) != 'NaN'">
					<xsl:value-of select="number($RES_MILLIS_VAR)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="0"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="BACKEND_MILLIS" select="number($TOTAL_MILLIS - ($REQ_MILLIS + $RES_MILLIS + $ERR_MILLIS))"/>
		<xsl:variable name="EXTENSION_VARS" select="dp:variable($EXTENSION_VARS_VAR_NAME)"/>
		<xsl:variable name="SERVICE_RES_MSG">
			<xsl:choose>
				<xsl:when test="contains(dp:variable($STATS_LOG_RES_OUTMSG_ROOT_VAR_NAME), '}')">
					<xsl:value-of select="substring-after(dp:variable($STATS_LOG_RES_OUTMSG_ROOT_VAR_NAME), '}')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="dp:variable($STATS_LOG_RES_OUTMSG_ROOT_VAR_NAME)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="PROVIDER_RESPONSE">
			<xsl:choose>
				<xsl:when test="normalize-space($ERROR_CODE) = 'ENTR00007'">
					<xsl:value-of select="'timeout'"/>
				</xsl:when>
				<xsl:when test="(dp:variable($RES_IN_MSG_NAME_VAR_NAME) = 'Input')
					and (dp:variable($REQ_OUT_MSG_ASYNC_VAR_NAME) = 'true')">
					<xsl:value-of select="'noreply'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="dp:variable($RES_IN_MSG_NAME_VAR_NAME)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="SERVICE_PROXY" select="substring-before(substring-after(dp:variable($REQ_WSA_ACTION_VAR_NAME), 'Namespace/'), '/Services')"/>
		<xsl:variable name="SERVICE_RESULT">
			<xsl:choose>
				<xsl:when test="normalize-space($ERROR_CODE) = 'ENTR00007'">
					<xsl:value-of select="'timeout'"/>
				</xsl:when>
				<xsl:when test="normalize-space($ERROR_CODE) = 'ENTR00004'">
					<xsl:value-of select="'timeout'"/>
				</xsl:when>
				<xsl:when test="normalize-space($ERROR_CODE) = 'FRWK00029'">
					<xsl:value-of select="'filtered'"/>
				</xsl:when>
				<xsl:when test="normalize-space($SERVICE_RES_MSG) = 'Fault'">
					<xsl:value-of select="'fault'"/>
				</xsl:when>
				<xsl:when test="normalize-space($ERROR_CODE) != ''">
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
			<xsl:value-of select="dp:variable($SERVICE_NAME_VAR_NAME)"/>
			<xsl:text>,</xsl:text>
			<xsl:text>ServiceResult=</xsl:text>
			<xsl:value-of select="$SERVICE_RESULT"/>
			<xsl:text>,</xsl:text>
			<xsl:text>Username=</xsl:text>
			<xsl:value-of select="dp:variable($REQ_USER_NAME_VAR_NAME)"/>
			<xsl:text>,</xsl:text>
			<xsl:text>ServiceProxy=</xsl:text>
			<xsl:value-of select="$SERVICE_PROXY"/>
			<xsl:text>,</xsl:text>
			<xsl:if test="dp:variable($PROVIDER_VAR_NAME) != ''">
				<xsl:text>ServiceProvider=</xsl:text>
				<xsl:value-of select="dp:variable($PROVIDER_VAR_NAME)"/>
				<xsl:text>,</xsl:text>
			</xsl:if>
			<xsl:if test="$PROVIDER_RESPONSE != ''">
				<xsl:text>ProviderResponse=</xsl:text>
				<xsl:value-of select="$PROVIDER_RESPONSE"/>
				<xsl:text>,</xsl:text>
			</xsl:if>
			<xsl:if test="dp:variable($BACKEND_PROTOCOL_VAR_NAME) != ''">
				<xsl:text>BackendProtocol=</xsl:text>
				<xsl:value-of select="dp:variable($BACKEND_PROTOCOL_VAR_NAME)"/>
				<xsl:text>,</xsl:text>
			</xsl:if>
			<!-- InMsgFt_req -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'ReqMsgFormat'"/>
				<xsl:with-param name="VALUE" select="dp:variable($REQ_IN_MSG_FORMAT_VAR_NAME)"/>
			</xsl:call-template>
			<!-- InMsgSz_req -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'ReqMsgSize'"/>
				<xsl:with-param name="VALUE" select="dp:variable($STATS_LOG_REQ_INMSG_SIZE_VAR_NAME)"/>
			</xsl:call-template>
			<!-- Check if response attributes are required -->
			<xsl:if test="dp:responding() = true()">
				<!-- InMsgNm_res -->
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ResMsgName'"/>
					<xsl:with-param name="VALUE" select="$SERVICE_RES_MSG"/>
				</xsl:call-template>
				<!-- InMsgFt_res -->
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ResMsgFormat'"/>
					<xsl:with-param name="VALUE" select="dp:variable($RES_OUT_MSG_FORMAT_VAR_NAME)"/>
				</xsl:call-template>
				<!-- InMsgSz_res -->
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ResMsgSize'"/>
					<xsl:with-param name="VALUE" select="dp:variable($STATS_LOG_RES_INMSG_SIZE_VAR_NAME)"/>
				</xsl:call-template>
			</xsl:if>
			<!-- msgTypeId -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'msgTypeId'"/>
				<xsl:with-param name="VALUE" select="$MSG_FORMAT_ID"/>
			</xsl:call-template>
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
			<xsl:if test="normalize-space(dp:variable($ERROR_SUBCODE_VAR_NAME)) != ''">
				<!-- ErrSubCode -->
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ErrorSubCode'"/>
					<xsl:with-param name="VALUE" select="dp:variable($ERROR_SUBCODE_VAR_NAME)"/>
				</xsl:call-template>
			</xsl:if>
			<!-- Timing stats -->
			<xsl:apply-templates select="$EXTENSION_VARS" mode="createStatsReport"/>
			<!-- TotalBackEndMillis -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'TotalBackEndMillis'"/>
				<xsl:with-param name="VALUE" select="$BACKEND_MILLIS"/>
			</xsl:call-template>
			<!-- TotalServiceMillis -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'TotalServiceMillis'"/>
				<xsl:with-param name="VALUE" select="$TOTAL_MILLIS"/>
			</xsl:call-template>
			<!-- InMsgRoot_req -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'ReqMsgRoot_In'"/>
				<xsl:with-param name="VALUE" select="dp:variable($STATS_LOG_REQ_INMSG_ROOT_VAR_NAME)"/>
			</xsl:call-template>
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'ReqMsgFormat_In'"/>
				<xsl:with-param name="VALUE" select="dp:variable($REQ_IN_MSG_FORMAT_VAR_NAME)"/>
			</xsl:call-template>
			<!-- OutMsgRoot_req -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'ReqMsgRoot_Out'"/>
				<xsl:with-param name="VALUE" select="dp:variable($STATS_LOG_REQ_OUTMSG_ROOT_VAR_NAME)"/>
			</xsl:call-template>
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY" select="'ReqMsgFormat_Out'"/>
				<xsl:with-param name="VALUE" select="dp:variable($REQ_OUT_MSG_FORMAT_VAR_NAME)"/>
			</xsl:call-template>
			<!-- Check if response attributes are required -->
			<xsl:if test="dp:responding() = true()">
				<!-- InMsgRoot_res -->
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ResMsgRoot_In'"/>
					<xsl:with-param name="VALUE" select="dp:variable($STATS_LOG_RES_INMSG_ROOT_VAR_NAME)"/>
				</xsl:call-template>
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ResMsgFormat_In'"/>
					<xsl:with-param name="VALUE" select="dp:variable($RES_IN_MSG_FORMAT_VAR_NAME)"/>
				</xsl:call-template>
				<!-- OutMsgRoot_res -->
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ResMsgRoot_Out'"/>
					<xsl:with-param name="VALUE" select="dp:variable($STATS_LOG_RES_OUTMSG_ROOT_VAR_NAME)"/>
				</xsl:call-template>
				<xsl:call-template name="FormatLogAttribute">
					<xsl:with-param name="KEY" select="'ResMsgFormat_Out'"/>
					<xsl:with-param name="VALUE" select="dp:variable($RES_OUT_MSG_FORMAT_VAR_NAME)"/>
				</xsl:call-template>
			</xsl:if>
			<!-- Message Identifiers -->
<!--			<xsl:variable name="MSG_IDENTIFIERS">
				<xsl:call-template name="GetMsgIdentifiers"/>
			</xsl:variable>
			<xsl:for-each select="$MSG_IDENTIFIERS//logcore:Identifier">
				<xsl:if test="normalize-space(.) != ''">
					<xsl:call-template name="FormatLogAttribute">
						<xsl:with-param name="KEY" select="concat('Id_',@type,'_',@appliesTo)"/>
						<xsl:with-param name="VALUE" select="normalize-space(.)"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:for-each>-->
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
			<xsl:if test="dp:variable($REQ_WSA_RELATES_TO_VAR_NAME) != ''">
				<xsl:text>,</xsl:text>
				<xsl:text>WSARelatesTo=</xsl:text>
				<xsl:value-of select="dp:variable($REQ_WSA_RELATES_TO_VAR_NAME)"/>
			</xsl:if>
			<xsl:if test="dp:variable($TRANSACTION_ID_VAR_NAME) != ''">
				<xsl:text>,</xsl:text>
				<xsl:text>TransactionId=</xsl:text>
				<xsl:value-of select="dp:variable($TRANSACTION_ID_VAR_NAME)"/>
			</xsl:if>
		</xsl:variable>
		<dp:set-variable name="$STATS_REPORT_VAR_NAME" value="$STATS_REPORT"/>
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
	<!-- Template to handle 'variable' elements -->
	<xsl:template match="variable" mode="createStatsReport">
		<xsl:if test="starts-with(normalize-space(.),'var://local/timerElapsed/')">
			<xsl:variable name="VAR_NAME"
				select="concat('var://context/ESB_Services/',substring-after(.,'var://local/'))"/>
			<xsl:variable name="ELAPSED_MILLIS" select="dp:variable($VAR_NAME)"/>
			<xsl:variable name="IN_STEP_NAME"
				select="normalize-space(translate(substring-after(.,'var://local/timerElapsed/'),'/','_'))"/>
			<!-- Generate the log attribute -->
			<xsl:call-template name="FormatLogAttribute">
				<xsl:with-param name="KEY">
					<xsl:choose>
						<!-- Translate names as required -->
						<xsl:when test="$IN_STEP_NAME = 'RequestFlow'">
							<xsl:value-of select="'TotalRequestMillis'"/>
						</xsl:when>
						<xsl:when test="$IN_STEP_NAME = 'ResponseFlow'">
							<xsl:value-of select="'TotalResponseMillis'"/>
						</xsl:when>
						<xsl:when test="$IN_STEP_NAME = 'ErrorFlow'">
							<xsl:value-of select="'TotalErrorMillis'"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat($IN_STEP_NAME,'_Ms')"/>
						</xsl:otherwise>		
					</xsl:choose>
				</xsl:with-param>
				<xsl:with-param name="VALUE" select="$ELAPSED_MILLIS"/>
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
			<xsl:when test="dp:variable($RESULT_DOC_CONTEXT_NAME)/*[1]">
				<xsl:if test="normalize-space(namespace-uri(dp:variable($RESULT_DOC_CONTEXT_NAME)/*[local-name() =
					'Envelope'][1]/*[local-name() = 'Body'][1]/*[1]))      != ''">
					<xsl:text>{</xsl:text>
					<xsl:value-of
						select="normalize-space(namespace-uri(dp:variable($RESULT_DOC_CONTEXT_NAME)/*[local-name() =
						'Envelope'][1]/*[local-name() = 'Body'][1]/*[1]))"/>
					<xsl:text>}</xsl:text>
				</xsl:if>
				<xsl:value-of select="local-name(dp:variable($RESULT_DOC_CONTEXT_NAME)/*[local-name() =
					'Envelope'][1]/*[local-name() = 'Body'][1]/*[1])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="''"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
