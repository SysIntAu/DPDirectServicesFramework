<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512/"
	xmlns:exslt="http://exslt.org/common"
	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp date regexp"
	exclude-result-prefixes="dp date regexp" version="1.0">
	<!--========================================================================
		Purpose:
		A collection of common utility templates.
		
		History:
		2016-03-25	v1.0	Chris Sherlock		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Constants.xsl"/>
	
	<xsl:variable name="PROPERTIES_DOC"
	    select="document('local:///SecureTokenService/config/SecureTokenService-Properties.xml')"/>
    
    <xsl:variable name="SECURITY_PROPERTIES_DOC"
        select="document('local:///security/SecureTokenService-SecurityProperties.xml')"/>
    <!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="SERVICE_LOG_CATEGORY"
		select="concat(string(dp:variable($DP_SERVICE_DOMAIN_NAME)), $DPDIRECT.LOGCAT_DPDIRECT.SERVICE_SUFFIX)"/>
	
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
    
    <xsl:template name="GetDPDirectSecurityProperty">
        <xsl:param name="KEY"/>
        <xsl:param name="LOG_ERROR_WHEN_NULL" select="'true'"/>
        <!-- Do property lookup -->
        <xsl:variable name="PROP_VALUE" select="normalize-space(($SECURITY_PROPERTIES_DOC/PropertiesList/Property[@key =
            $KEY]/@value)[1])"/>
        <xsl:if test="($PROP_VALUE = '') and ($LOG_ERROR_WHEN_NULL = 'true')">
            <xsl:call-template name="WriteSysLogErrorMsg">
                <xsl:with-param name="MSG">
                    <xsl:text>No entry in security properties file for configuration property '</xsl:text>
                    <xsl:value-of select="$KEY"/>
                    <xsl:text>'</xsl:text>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:value-of select="$PROP_VALUE"/>
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
		<xsl:variable name="REQ_WSA_MSG_ID"
			select="normalize-space(dp:variable($REQ_WSA_MSG_ID_VAR_NAME))"/>
		<xsl:variable name="RES_WSA_MSG_ID"
			select="normalize-space(dp:variable($RES_WSA_MSG_ID_VAR_NAME))"/>
		<xsl:variable name="TX_DIRECTION"
			select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
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
		<xsl:value-of
			select="concat(substring($DATE_TIME,1,19),'.',substring($TIME_MILLIS,string-length($TIME_MILLIS)
			- 2,3),substring($DATE_TIME,20))"
		/>
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

	<!-- JWT Utilities for Generating JSON, signing and verifying tokens -->
	
	<!-- Extract Components of JWT -->
	
	<xsl:template name="getJwtHeader">
		<xsl:param name="TOKEN"/>
		<xsl:value-of select="substring-before($TOKEN, '.')"/>
	</xsl:template>

	<xsl:template name="getJwtClaims">
		<xsl:param name="TOKEN"/>
		<xsl:value-of select="substring-before(substring-after($TOKEN, '.'),'.')"/>
	</xsl:template>

	<xsl:template name="getJwtSignature">
		<xsl:param name="TOKEN"/>
		<xsl:value-of select="substring-after(substring-after($TOKEN, '.'),'.')"/>
	</xsl:template>

<!--	<xsl:template name="buildKVPairs">
		<xsl:param name="KEY"/>
		<xsl:param name="VALUE"/>
		<xsl:text>&quot;</xsl:text>
		<xsl:value-of select="$KEY"/>
		<xsl:text>&quot;: </xsl:text>
		<xsl:choose>
			<!-\- no quotes if a number-\->
			<xsl:when test="number($VALUE) = number($VALUE)">
				<xsl:value-of select="$VALUE"/>
			</xsl:when>
			<!-\- <!-\- no quotes if value is an array -\->
			<xsl:when test="substring($VALUE, 1, 1) = '['">
				<xsl:value-of select="$VALUE"/>
			</xsl:when>
			<!-\- value needs to be quoted -\->
			<xsl:otherwise>
				<xsl:text>&quot;</xsl:text>
				<xsl:value-of select="$VALUE"/>
				<xsl:text>&quot;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="buildArray">
		<xsl:param name="ARRAYLIST"/>
		<xsl:apply-templates select="$ARRAYLIST" mode="genArray"/>
	</xsl:template>

	<xsl:template match="/" mode="genArray">
		<xsl:text>[</xsl:text>
		<xsl:for-each select="child::node()/*">

			<xsl:choose>
				<xsl:when test="number(.) = number(.)">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>&quot;</xsl:text>
					<xsl:value-of select="."/>
					<xsl:text>&quot;</xsl:text>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:choose>
				<xsl:when test="not(position() = last())">
					<xsl:text>, </xsl:text>
				</xsl:when>
			</xsl:choose>

		</xsl:for-each>
		<xsl:text>]</xsl:text>
	</xsl:template>
-->
	<!-- Token Crypto -->

	<xsl:template name="signJwtToken">
		<xsl:param name="PAYLOAD"/>
		<xsl:variable name="HMAC_KEY">
			<xsl:call-template name="GetDPDirectSecurityProperty">
				<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_HMAC_SECRET"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of
			select="translate(dp:hmac('http://www.w3.org/2001/04/xmldsig-more#hmac-sha256', $HMAC_KEY, $PAYLOAD),'+/=', '-_')"
		/>
	</xsl:template>

	<xsl:template name="verifyJwtTokenSignature">
		<xsl:param name="PAYLOAD"/>
		<xsl:param name="SIGNATURE"/>

		<xsl:variable name="GENERATED_SIGNATURE">
			<xsl:call-template name="signJwtToken">
				<xsl:with-param name="PAYLOAD" select="$PAYLOAD"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="$SIGNATURE = $GENERATED_SIGNATURE">
				<xsl:text>passed</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>failed</xsl:text>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- Url Encoding -->

	<xsl:template name="base64UrlEncode">
		<xsl:param name="PAYLOAD"/>
		<xsl:value-of select="translate(dp:encode($PAYLOAD, 'base-64'),'+/=', '-_')"/>
	</xsl:template>

	<xsl:template name="base64UrlDecode">
		<xsl:param name="PAYLOAD"/>
		<xsl:variable name="CHARS_TO_PAD">
			<xsl:choose>
				<xsl:when test="string-length($PAYLOAD) mod 4 = 0">
					<xsl:value-of select="0"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="4 - string-length($PAYLOAD) mod 4"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:value-of
			select="dp:decode(concat(translate($PAYLOAD,'-_', '+/'), substring('====', 1, $CHARS_TO_PAD)), 'base-64')"
		/>
	</xsl:template>

	<!-- Get Ldap Groups for a user -->
	<xsl:template name="getMsgGroupsForUser">
		<xsl:param name="USERID"/>
		<xsl:param name="USECACHE"/>
		
		<xsl:variable name="CACHE_ARG">
			<xsl:choose>
				<xsl:when test="$USECACHE = 'true'">
					<xsl:text>&amp;useCache=true</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="GROUP_URL">
			<xsl:call-template name="GetDPDirectProperty">
				<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_LDAP_GROUP_URL"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="FORMATTED_REQUEST" select="concat($GROUP_URL,'?userid=', $USERID, $CACHE_ARG)"/>
		<dp:url-open target="{$FORMATTED_REQUEST}" http-method="get"/>

	</xsl:template>
	
	<!-- Convert jsonx to xml-->
	
	<xsl:template name="JsonxToJson">
		<xsl:param name="JSONX_NODE_SET"/>
		<!--<xsl:copy-of select="string(dp:transform('store:///jsonx2json.xsl',$JSONX_NODE_SET))"/>-->
		<xsl:copy-of select="dp:transform('store:///jsonx2json.xsl',$JSONX_NODE_SET)"/>
	</xsl:template>
	
	
	

</xsl:stylesheet>