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
	xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" version="1.0" exclude-result-prefixes="dp soapenv">
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///framework-soa-esb/framework/Constants.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="soapenv:Envelope/soapenv:Body">
				<xsl:copy-of select="/soapenv:Envelope/soapenv:Body/*"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="/*"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
