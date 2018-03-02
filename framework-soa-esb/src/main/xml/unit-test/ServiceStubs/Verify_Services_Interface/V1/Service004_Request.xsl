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
	xmlns:test="http://www.dpdirect.org/Namespace/Verify/Service/V1.0"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" exclude-result-prefixes=""
	version="1.0">
	<xs:annotation xmlns:xs="http://www.w3.org/2004/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>N.A.</dc:creator>
			<dc:date>2016-03-01</dc:date>
			<dc:title>Service004 Request Generation</dc:title>
			<dc:subject>Creates a Service004 SOAP request message.</dc:subject>
			<dc:contributor>N.A.</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--
	=================================================================
		History:
		2016-03-01	v0.1	N.A.		Initial Version.
	=================================================================
	-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///ondisk/ESB_Services/framework/Constants.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="REQ_SOAP_ENV" select="dp:variable($REQ_SOAP_ENV_VAR_NAME)"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
			<soap:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">
				<wsa:To>http://www.w3.org/2005/08/addressing/anonymous</wsa:To>
				<wsa:ReplyTo>
					<wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address>
				</wsa:ReplyTo>
				<wsa:MessageID>298347293847234</wsa:MessageID>
				<wsa:Action>http://www.dpdirect.org/Namespace/Verify/Services/Interface/V1/Verify_PortType_V1/Service004</wsa:Action>
				<!-- Insert original  request "wsse:Security" element -->
				<xsl:copy-of select="($REQ_SOAP_ENV//wsse:Security)[1]"/>
			</soap:Header>
			<soap:Body>
				<test:Service004Request xmlns:test="http://www.dpdirect.org/Namespace/Verify/Service/V1.0">
					<test:RequestId>Service004</test:RequestId>
				</test:Service004Request>
			</soap:Body>
		</soap:Envelope>
	</xsl:template>
</xsl:stylesheet>
