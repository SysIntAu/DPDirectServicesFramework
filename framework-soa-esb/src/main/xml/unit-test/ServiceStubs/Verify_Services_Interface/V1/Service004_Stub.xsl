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
	xmlns:test="http://www.dpdirect.org/Namespace/Verify/Service/V1.0" exclude-result-prefixes="" version="1.0">
	<xs:annotation xmlns:xs="http://www.w3.org/2004/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>N.A.</dc:creator>
			<dc:date>2016-12-06</dc:date>
			<dc:title>Service004 Verification Stub</dc:title>
			<dc:subject>Provides verification services for the "Verify_Services_Interface.wsdl#Service004"
				operation.</dc:subject>
			<dc:contributor>N.A.</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--
	=================================================================
		History:
		2016-12-06	v0.1	N.A.		Initial Version.
	=================================================================
	-->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--============== Global Variable Declarations =================-->
	<!--<xsl:variable/>-->
	<!--============== Stylesheet Parameter Declarations ============-->
	<!--<xsl:param/>-->
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<test:Service004Response>
			<test:RequestId>
				<xsl:value-of select="test:Service004Request/test:RequestId"/>
			</test:RequestId>
			<test:ResponseId>123</test:ResponseId>
		</test:Service004Response>
	</xsl:template>
</xsl:stylesheet>
