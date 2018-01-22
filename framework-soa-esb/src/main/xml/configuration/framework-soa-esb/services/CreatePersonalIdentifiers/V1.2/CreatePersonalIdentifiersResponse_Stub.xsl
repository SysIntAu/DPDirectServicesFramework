<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:biocore="http://www.dpdirect.org/Namespace/Biometrics/Core/V1.0"
	xmlns:bioapp="http://www.dpdirect.org/Namespace/BiometricApplicant/Services/V1.2"
	version="1.0">
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="bioapp:CreatePersonalIdentifiersRequest">
		<bioapp:CreatePersonalIdentifiersResponse
			xmlns="http://www.dpdirect.org/Namespace/Biometrics/Core/V1.0"
			xmlns:ns4="http://www.dpdirect.org/Namespace/Enterprise/WarningMessages/V1.0"
			xmlns:ns3="http://www.dpdirect.org/Namespace/Enterprise/InformationMessages/V1.0"
			xmlns:ns2="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0"
			xmlns:ns5="http://www.dpdirect.org/Namespace/Enterprise/AcknowledgementMessage/V1.0"
			xmlns:bioapp="http://www.dpdirect.org/Namespace/BiometricApplicant/Services/V1.2">
			<ns3:Informations>
				<ns3:Information>
					<ns2:SubCode>BAMS</ns2:SubCode>
					<ns2:Description>Enrolment Started</ns2:Description>
					<ns2:InformationCode>INFO00000</ns2:InformationCode>
					<ns2:MessageOrigin>www.dpdirect.org</ns2:MessageOrigin>
					<ns2:SubCode>BAMS</ns2:SubCode>
				</ns3:Information>
			</ns3:Informations>
			<ns5:Acknowledgement>SUCCESS</ns5:Acknowledgement>
			<VisaApplicationCentreLodgementNumber><xsl:value-of select="//biocore:VisaApplicationCentreLodgementNumber"/></VisaApplicationCentreLodgementNumber>
		</bioapp:CreatePersonalIdentifiersResponse>
	</xsl:template>
	<!-- Modified Identity template to traverse without copying -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
