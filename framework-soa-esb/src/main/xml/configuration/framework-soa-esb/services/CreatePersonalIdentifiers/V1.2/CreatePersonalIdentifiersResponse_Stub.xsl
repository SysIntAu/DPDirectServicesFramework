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
	xmlns:biocore="http://www.dpdirect.org/Namespace/Identity/Core/V1.0"
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
	<xsl:template match="bioapp:VerifyRequest">
		<bioapp:VerifyResponse
			xmlns="http://www.dpdirect.org/Namespace/Identity/Core/V1.0"
			xmlns:ns4="http://www.dpdirect.org/Namespace/Enterprise/WarningMessages/V1.0"
			xmlns:ns3="http://www.dpdirect.org/Namespace/Enterprise/InformationMessages/V1.0"
			xmlns:ns2="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0"
			xmlns:ns5="http://www.dpdirect.org/Namespace/Enterprise/AcknowledgementMessage/V1.0"
			xmlns:bioapp="http://www.dpdirect.org/Namespace/BiometricApplicant/Services/V1.2">
			<ns3:Information>
				<ns3:Information>
					<ns2:Code>INFO00000</ns2:Code>
					<ns2:Description>Enrolment Started</ns2:Description>
					<ns2:SubCode>Sys1</ns2:SubCode>
					<ns2:SubDescription>Enrolment Started</ns2:SubDescription>
					<ns2:MessageOrigin>www.dpdirect.org</ns2:MessageOrigin>
					<ns2:Location>Sys1</ns2:Location>
				</ns3:Information>
			</ns3:Information>
			<ns5:Acknowledgement>SUCCESS</ns5:Acknowledgement>
			<VisaApplicationCentreLodgementNumber><xsl:value-of select="//biocore:VisaApplicationCentreLodgementNumber"/></VisaApplicationCentreLodgementNumber>
		</bioapp:VerifyResponse>
	</xsl:template>
	<!-- Modified Identity template to traverse without copying -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
