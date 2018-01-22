<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	extension-element-prefixes="dp regexp"
	version="1.0" exclude-result-prefixes="dp regexp wsa saml wsse">
	<!--========================================================================
		History:
		2016-03-06	v1.0	N.A.		Initial Version.
		2016-07-17	v1.0	Tim Goodwill		Add notification support.
		2016-09-11	v1.0	Tim Goodwill		HTTP/S timeout msg and response code addl dtl.
		2016-03-20	v2.0	Tim Goodwill		Init MSG instance
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="PROXY_NAME" select="normalize-space(dp:variable($DP_SERVICE_PROCESSOR_NAME))"/>
	<xsl:variable name="USER_NAME" select="normalize-space(/*[local-name() =
		'Envelope']/*[local-name() = 'Header']/wsse:security/wsse:UsernameToken/wsse:Username)"/>
	<xsl:variable name="WSU_TIMESTAMP" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsse:security/*[local-name() = 'Timestamp'])"/>
	<xsl:variable name="SOAP_NAMESPACE" select="normalize-space(namespace-uri(/*[local-name() = 'Envelope'][1]))"/>
	<xsl:variable name="WSA_ACTION" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsa:Action[1])"/>
	<xsl:variable name="WSA_TO" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsa:To[normalize-space(.) != $WSA_ANONYMOUS_DESTINATION])"/>
	<xsl:variable name="WSA_FROM" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsa:From[normalize-space(.) != $WSA_ANONYMOUS_DESTINATION])"/>
	<xsl:variable name="WSA_MSG_ID" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsa:MessageID[1])"/>
	<xsl:variable name="REQUEST_TRANSACTION_ID" select="normalize-space((/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1])//*[local-name() = 'TransactionId'][1])"/>
	<xsl:variable name="INPUT_PORT"
		select="normalize-space(substring-after(dp:variable($DP_SERVICE_LOCAL_SERVICE_ADDRESS),':'))"/>
	<!-- Message meta-data structure -->
	<xsl:variable name="INPUT_MSG_SIZE" select="string(dp:get-metadata()/metadata/input-message-size)"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- Start the counter -->
		<dp:set-variable name="$TIMER_START_VAR_NAME" value="string(dp:time-value())"/>
		<!-- The DP transaction rule type ('request'|'response'|'error') -->
		<xsl:variable name="TX_RULE_TYPE" select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
		<xsl:if test="$TX_RULE_TYPE != 'error'">
			<dp:set-variable name="$FLOW_DIRECTION_VAR_NAME" value="string($TX_RULE_TYPE)"/>
		</xsl:if>
		<xsl:variable name="MSG_ROOT_LOCAL_NAME" select="local-name(/*[local-name() = 'Envelope'][1]/*[local-name() = 'Body'][1]/*[1])"/>
		<xsl:variable name="INPUT_MSG_ROOT_NAME">
			<xsl:text>{</xsl:text>
			<xsl:value-of select="normalize-space(namespace-uri(/*[local-name() =
				'Envelope'][1]/*[local-name() = 'Body'][1]/*[1]))"/>
			<xsl:text>}</xsl:text>
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
		<!-- Store the request timestamp -->
		<dp:set-variable name="$REQ_WSU_TIMESTAMP_VAR_NAME" value="$WSU_TIMESTAMP"/>
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
		<dp:set-variable name="$TRANSACTION_ID_VAR_NAME" value="$REQUEST_TRANSACTION_ID"/>
		<!-- Store the request WSAddressing from the SOAP header for logging -->
		<dp:set-variable name="$REQ_WSA_MSG_ID_VAR_NAME" value="string($WSA_MSG_ID)"/>
		<dp:set-variable name="$REQ_WSA_TO_VAR_NAME" value="string($WSA_TO)"/>
		<!-- Store the WSA Action -->
		<dp:set-variable name="$REQ_WSA_ACTION_VAR_NAME" value="string($WSA_ACTION)"/>
		<!-- Store the request user name -->
		<dp:set-variable name="$REQ_USER_NAME_VAR_NAME" value="string($USER_NAME)"/>
		<!-- Store the request message size -->
		<dp:set-variable name="$STATS_LOG_REQ_SIZE_VAR_NAME" value="string($INPUT_MSG_SIZE)"/>
		<!-- Store the request message payload qualified name value -->
		<dp:set-variable name="$STATS_LOG_REQ_ROOT_VAR_NAME" value="string($INPUT_MSG_ROOT_NAME)"/>
		<!-- Store the Service Identifier value -->
		<dp:set-variable name="$SERVICE_IDENTIFIER_VAR_NAME" value="string($INPUT_MSG_ROOT_NAME)"/>
		<!-- Store the Service Name value -->
		<dp:set-variable name="$SERVICE_NAME_VAR_NAME" value="string($SERVICE_NAME)"/>
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
