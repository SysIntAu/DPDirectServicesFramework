<?xml version="1.0" encoding="UTF-8"?>
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
