<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
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
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="URL_IN" select="dp:variable('var://service/URL-in')"/>
	<xsl:variable name="SEARCH_PARAMS" select="concat(substring-after($URL_IN,'/search?'), '&amp;')"/>
	<xsl:variable name="PARTY_ID_TYPE" select="substring-before(substring-after($SEARCH_PARAMS,'PartyIdentifierType='), '&amp;')"/>
	<xsl:variable name="PARTY_ID_VALUE" select="substring-before(substring-after($SEARCH_PARAMS,'PartyIdentifierValue='), '&amp;')"/>
	<xsl:variable name="PARTY_ROLE_ID_TYPE" select="substring-before(substring-after($SEARCH_PARAMS,'PartyRoleIdentifierType='), '&amp;')"/>
	<xsl:variable name="PARTY_ROLE_ID_VALUE" select="substring-before(substring-after($SEARCH_PARAMS,'PartyRoleIdentifierValue='), '&amp;')"/>
	<xsl:variable name="BUSINESS_SERVICE_ID_TYPE" select="substring-before(substring-after($SEARCH_PARAMS,'BusinessSystemIdentifierType='), '&amp;')"/>
	<xsl:variable name="BUSINESS_SERVICE_ID_VALUE" select="substring-before(substring-after($SEARCH_PARAMS,'BusinessSystemIdentifierValue='), '&amp;')"/>
	<!-- Optional PartyIdentifierRequest flags -->
	<xsl:variable name="INCLUDE_PARTY_ROLE_ID_FLAG" select="substring-before(substring-after($SEARCH_PARAMS,'IncludePartyRoleIdentifiersFlag='), '&amp;')"/>
	<xsl:variable name="INCLUDE_PARTY_ALTERNATE_ID_FLAG" select="substring-before(substring-after($SEARCH_PARAMS,'IncludePartyAlternateIdentifiersFlag='), '&amp;')"/>
	<!-- Optional flags -->
	<xsl:variable name="APPLY_ROV_FILTER_FLAG" select="substring-before(substring-after($SEARCH_PARAMS,'ApplyROVFilterFlag='), '&amp;')"/>
	<xsl:variable name="RETRIEVE_SINGLE_ID_SUMMARY_FLAG" select="substring-before(substring-after($SEARCH_PARAMS,'RetrieveSingleIdentifierSummaryFlag='), '&amp;')"/>
	<xsl:variable name="RETRIEVE_BUSINESS_ID_FLAG" select="substring-before(substring-after($SEARCH_PARAMS,'RetrieveBusinessIdsFlag='), '&amp;')"/>
	<xsl:variable name="UNCONSOLIDATED_NAME_FLAG" select="substring-before(substring-after($SEARCH_PARAMS,'UnconsolidatedNameFlag='), '&amp;')"/>
	<!-- logging vars -->
	<xsl:variable name="WSA_MSGID" select="normalize-space(dp:generate-uuid())"/>
	<xsl:variable name="POLICY_LOCATION" select="normalize-space(dp:variable($OPERATION_CONFIG_NODE_ID_VAR_NAME))"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="contains ($URL_IN, '/search?')">
				<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
					<xsl:call-template name="GenerateSOAPHeader"/>
					<soapenv:Body>
						<pty:RetrieveConsolidatedPartySummaryRequest xmlns:ecore="http://www.dpdirect.org/Namespace/Enterprise/Core/V1.0"
							xmlns:ptycore="http://www.dpdirect.org/Namespace/Party/Core/V1.0"
							xmlns:pty="http://www.dpdirect.org/Namespace/Party/Service/V9.0">			
							<ptycore:PartyIdentifierRequest>
								<xsl:choose>
									<xsl:when test="normalize-space($PARTY_ID_VALUE) != ''">
										<ptycore:PartyIdentifier>
											<ptycore:Identifier><xsl:value-of select="$PARTY_ID_VALUE"/></ptycore:Identifier>
											<ptycore:IdentifierType><xsl:value-of select="$PARTY_ID_TYPE"/></ptycore:IdentifierType>
										</ptycore:PartyIdentifier>
									</xsl:when>
									<xsl:when test="normalize-space($PARTY_ROLE_ID_VALUE) != ''">
										<ptycore:PartyRoleIdentifier>
											<ptycore:RoleIdentifier><xsl:value-of select="$PARTY_ROLE_ID_VALUE"/></ptycore:RoleIdentifier>
											<ptycore:RoleIdentifierType><xsl:value-of select="$PARTY_ROLE_ID_TYPE"/></ptycore:RoleIdentifierType>
										</ptycore:PartyRoleIdentifier>
									</xsl:when>
									<xsl:when test="normalize-space($BUSINESS_SERVICE_ID_VALUE) != ''">
										<bccore:BusinessServiceIdentifier xmlns:bccore="http://www.dpdirect.org/Namespace/BusinessContext/Core/V1.0">
											<bccore:BusinessServiceIdValue><xsl:value-of select="$BUSINESS_SERVICE_ID_VALUE"/></bccore:BusinessServiceIdValue>
											<bccore:BusinessServiceIdType><xsl:value-of select="$BUSINESS_SERVICE_ID_TYPE"/></bccore:BusinessServiceIdType>
										</bccore:BusinessServiceIdentifier>
									</xsl:when>
									<xsl:otherwise>
										<!-- Reject to error flow -->
										<xsl:call-template name="RejectToErrorFlow">
											<xsl:with-param name="MSG">
												<xsl:text>Missing mandatory parameters.</xsl:text>
											</xsl:with-param>
										</xsl:call-template>
									</xsl:otherwise>
								</xsl:choose>
								<xsl:if test="normalize-space($INCLUDE_PARTY_ROLE_ID_FLAG) != ''">
									<ptycore:IncludePartyRoleIdentifiersFlag><xsl:value-of select="$INCLUDE_PARTY_ROLE_ID_FLAG"/></ptycore:IncludePartyRoleIdentifiersFlag>
								</xsl:if>
								<xsl:if test="normalize-space($INCLUDE_PARTY_ALTERNATE_ID_FLAG) != ''">
									<ptycore:IncludePartyAlternateIdentifiersFlag><xsl:value-of select="$INCLUDE_PARTY_ALTERNATE_ID_FLAG"/></ptycore:IncludePartyAlternateIdentifiersFlag>
								</xsl:if>
							</ptycore:PartyIdentifierRequest>
							<xsl:if test="normalize-space($APPLY_ROV_FILTER_FLAG) != ''">
								<ptycore:ApplyROVFilterFlag><xsl:value-of select="$APPLY_ROV_FILTER_FLAG"/></ptycore:ApplyROVFilterFlag>
							</xsl:if>
							<xsl:if test="normalize-space($RETRIEVE_SINGLE_ID_SUMMARY_FLAG) != ''">
								<ptycore:RetrieveSingleIdentifierSummaryFlag><xsl:value-of select="$RETRIEVE_SINGLE_ID_SUMMARY_FLAG"/></ptycore:RetrieveSingleIdentifierSummaryFlag>
							</xsl:if>
							<xsl:if test="normalize-space($RETRIEVE_BUSINESS_ID_FLAG) != ''">
								<ptycore:RetrieveBusinessIdsFlag><xsl:value-of select="$RETRIEVE_BUSINESS_ID_FLAG"/></ptycore:RetrieveBusinessIdsFlag>
							</xsl:if>
							<xsl:if test="normalize-space($UNCONSOLIDATED_NAME_FLAG) != ''">
								<ptycore:UnconsolidatedNameFlag><xsl:value-of select="$UNCONSOLIDATED_NAME_FLAG"/></ptycore:UnconsolidatedNameFlag>
							</xsl:if>	
						</pty:RetrieveConsolidatedPartySummaryRequest>
					</soapenv:Body>
				</soapenv:Envelope>
				<!-- SET outbound URI and http method -->
				<dp:set-variable name="'var://service/protocol-method'" value="'POST'"/>
				<dp:set-variable name="'var://service/URI'" value="''"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Reject to error flow -->
				<xsl:call-template name="RejectToErrorFlow">
					<xsl:with-param name="MSG">
						<xsl:text>Missing mandatory parameters.</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>