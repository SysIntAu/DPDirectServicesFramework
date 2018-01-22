<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:dpquery="http://www.datapower.com/param/query"  
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	extension-element-prefixes="dp date"
	exclude-result-prefixes="dp date"
	version="1.0">
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///Json_RestAPI/framework/Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:variable name="URL_IN" select="dp:variable('var://service/URL-in')"/>
		<xsl:choose>
			<xsl:when test="contains ($URL_IN, '/ServiceRequest/rest/OnshoreStatus/search?')">
				<xsl:variable name="SEARCH_PARAMS" select="concat(substring-after($URL_IN,'ServiceRequest/rest/OnshoreStatus/search?'), '&amp;')"/>
				<xsl:variable name="PARTY_SYSTEM_IDENTIFIER_TYPE" select="substring-before(substring-after($SEARCH_PARAMS,'PartySystemIdentifierType='), '&amp;')"/>
				<xsl:variable name="PARTY_SYSTEM_IDENTIFIER_VALUE" select="substring-before(substring-after($SEARCH_PARAMS,'PartySystemIdentifierValue='), '&amp;')"/>
				<xsl:variable name="STATUS_DATE_VALUE" select="substring-before(substring-after($SEARCH_PARAMS,'StatusDate='), '&amp;')"/>
				<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
					<xsl:call-template name="GenerateSOAPHeader"/>
					<soapenv:Body>
						<pty:RetrieveOnshoreStatusRequest xmlns:ecore="http://www.dpdirect.org/Namespace/Enterprise/Core/V1.0"
							xmlns:ptycore="http://www.dpdirect.org/Namespace/Party/Core/V1.0"
							xmlns:pty="http://www.dpdirect.org/Namespace/Party/Service/V1.0"
							xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
							xsi:schemaLocation="http://www.dpdirect.org/Namespace/Party/Service/V1.0 ../XSD/RetrieveOnshoreStatusRequest.xsd">
							<ptycore:PartySystemIdentifier>
								<ptycore:PartySystemIdentifierValue><xsl:value-of select="$PARTY_SYSTEM_IDENTIFIER_VALUE"/></ptycore:PartySystemIdentifierValue>
								<ptycore:PartySystemIdentifierType><xsl:value-of select="$PARTY_SYSTEM_IDENTIFIER_TYPE"/></ptycore:PartySystemIdentifierType>
							</ptycore:PartySystemIdentifier>
							<ecore:StatusDate>
								<xsl:choose>
									<xsl:when test="normalize-space($STATUS_DATE_VALUE) != ''">
										<xsl:value-of select="$STATUS_DATE_VALUE"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:variable name="DATE_STRING">
											<xsl:call-template name="GetCurrentDateAsYYYYMMDD"/>
										</xsl:variable>
										<xsl:value-of select="substring($DATE_STRING, 1, 4)"/>
										<xsl:value-of select="'-'"/>
										<xsl:value-of select="substring($DATE_STRING, 5, 2)"/>
										<xsl:value-of select="'-'"/>
										<xsl:value-of select="substring($DATE_STRING, 7, 2)"/>
									</xsl:otherwise>
								</xsl:choose>
							</ecore:StatusDate>
						</pty:RetrieveOnshoreStatusRequest>
					</soapenv:Body>
				</soapenv:Envelope>
				<!-- SET outbound URI and http method -->
				<dp:set-variable name="'var://service/protocol-method'" value="'POST'"/>
				<dp:set-variable name="'var://service/URI'" value="'/ServiceRequest'"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Reject to error flow -->
				<xsl:call-template name="RejectToErrorFlow">
					<xsl:with-param name="MSG">
						<xsl:text>Service unavailable</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
</xsl:stylesheet>