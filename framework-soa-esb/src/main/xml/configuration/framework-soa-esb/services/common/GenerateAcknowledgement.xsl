<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:ecore="http://www.dpdirect.org/Namespace/Enterprise/Core/V1.0"
	xmlns:eim="http://www.dpdirect.org/Namespace/Enterprise/InformationMessages/V1.0"
	xmlns:errcore="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0"
	xmlns:eam="http://www.dpdirect.org/Namespace/Enterprise/AcknowledgementMessage/V1.0"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" version="1.0"
	exclude-result-prefixes="dp ecore eim eam">
	<xs:annotation xmlns:xs="http://www.w3.org/2001/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>Tim Goodwill</dc:creator>
			<dc:date>2016-08-12</dc:date>
			<dc:title>Generate an acknowledgement for an async mq put</dc:title>
			<dc:subject>Generate an acknowledgement for an async mq put where MQ has accepted the message</dc:subject>
			<dc:contributor>Tim Goodwill</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--========================================================================
		History:
		2016-08-12	v1.0	Tim Goodwill		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///ESB_Services/framework/Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="ROUTING_URL" select="dp:variable($DP_SERVICE_ROUTING_URL)"/>
	<!-- WS Addressing -->
	<xsl:variable name="RES_WSA_TO" select="normalize-space(dp:variable($RES_WSA_TO_VAR_NAME))"/>
	<xsl:variable name="REQ_WSA_REPLY_TO" select="normalize-space(dp:variable($REQ_WSA_REPLY_TO_VAR_NAME))"/>
	<xsl:variable name="REQ_WSA_FAULT_TO" select="normalize-space(dp:variable($REQ_WSA_FAULT_TO_VAR_NAME))"/>
	<!-- Fault handling -->
	<xsl:variable name="SOAP_FAULT" select="/soapenv:Envelope/soapenv:Body/soapenv:Fault"/>
	<xsl:variable name="ASYNC_SOAP_FAULT_HANDLED" 
		select="boolean($SOAP_FAULT//errcore:EnterpriseErrors
		and (($REQ_WSA_FAULT_TO != '') or ($REQ_WSA_REPLY_TO != ''))
		and ($RES_WSA_TO = ''))"/>
	<xsl:variable name="ASYNC_SOAP_FAULT_NOT_HANDLED" 
		select="boolean($SOAP_FAULT/*
		and (($REQ_WSA_FAULT_TO != '') or ($REQ_WSA_REPLY_TO != ''))
		and ($RES_WSA_TO != ''))"/>
	<xsl:variable name="SYNCHRONOUS_ERROR" select="boolean($SOAP_FAULT/* 
		and ($REQ_WSA_FAULT_TO = '') and ($REQ_WSA_REPLY_TO = '')
		and ($RES_WSA_TO = ''))"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Standard identity template -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="$ASYNC_SOAP_FAULT_NOT_HANDLED or $SYNCHRONOUS_ERROR">
				<!-- Async SOAP Fault (FaultTo or ReplyTo) has not been handled by a WS Proxy endpoint -->
				<xsl:variable name="PROVIDER_NAME" select="dp:variable($PROVIDER_VAR_NAME)"/>
				<xsl:choose>
					<!-- Preserve some Enterprise Error details -->
					<xsl:when test="$SOAP_FAULT//errcore:EnterpriseErrors">
						<xsl:variable name="ERROR_CODE">
							<xsl:choose>
								<xsl:when test="$SOAP_FAULT//errcore:EnterpriseErrors[1]/*[1]/*[1]/errcore:ErrorCode">
									<xsl:value-of select="$SOAP_FAULT//errcore:EnterpriseErrors[1]/*[1]/*[1]/errcore:ErrorCode[1]"/>
								</xsl:when>
								<xsl:otherwise>
									<!-- 'FRWK00026' is a general code to indicate SOAP Fault received from sub-service call or back end system -->
									<xsl:value-of select="'FRWK00026'"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- Reject to error flow -->
						<xsl:call-template name="RejectToErrorFlow">
							<xsl:with-param name="ERROR_CODE" 
								select="normalize-space(//errcore:ErrorCode)"/>
							<xsl:with-param name="MSG" 
								select="normalize-space($SOAP_FAULT//errcore:EnterpriseErrors[1]/*[1]/*[1]/errcore:Description[1])"/>
							<xsl:with-param name="PROVIDER_NAME"
								select="$PROVIDER_NAME"/>
							<xsl:with-param name="ORIGINATOR_NAME"
								select="normalize-space($SOAP_FAULT//errcore:EnterpriseErrors[1]/*[1]/*[1]/errcore:SubCode[1])"/>
							<xsl:with-param name="ORIGINATOR_LOC"
								select="normalize-space($SOAP_FAULT//errcore:EnterpriseErrors[1]/*[1]/*[1]/errcore:MessageOrigin[1])"/>
							<xsl:with-param name="ADD_DETAILS"
								select="concat($SOAP_FAULT//errcore:EnterpriseErrors[1]/*[1]/*[1]/errcore:Description[1],';&#x020;',
								$SOAP_FAULT//errcore:EnterpriseErrors[1]/*[1]/*[1]/errcore:SubDescription[1])"/>
							<xsl:with-param name="ERROR_OVERRIDE" select="'true'"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<!-- Reject to error flow -->
						<xsl:call-template name="RejectToErrorFlow">
							<!-- 'FRWK00026' is a general code to indicate SOAP Fault received from sub-service call or back end system -->
							<xsl:with-param name="ERROR_CODE" select="'FRWK00026'"/>
							<xsl:with-param name="ADD_DETAILS" select="concat('[response-fault-metadata
								provider=', $PROVIDER_NAME, 'faultstring=', $SOAP_FAULT//faultstring, '&#x020;;detail=',
								$SOAP_FAULT//detail,']')"/>
						</xsl:call-template> 
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$ASYNC_SOAP_FAULT_HANDLED">
				<xsl:copy-of select="."/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="GenerateAcknowledgementMsg">
					<xsl:with-param name="ENDPOINT_URL" select="$ROUTING_URL"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
