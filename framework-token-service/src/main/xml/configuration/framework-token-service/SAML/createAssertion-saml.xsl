<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:dp="http://www.datapower.com/extensions" xmlns:date="http://exslt.org/dates-and-times"
	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" extension-element-prefixes="dp date"
	exclude-result-prefixes="dp  soap ds wsse wsu date" version="1.0">
	<!--========================================================================
		Purpose:
		Creates A SAML Assertion
		
		History:
		2016-03-25  v1.0    Chris Sherlock  Initial Version.
		========================================================================-->
	<xsl:import href="local:///SecureTokenService/common/Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<!-- Adding zero duration results in UTC (re:timezone) which is consitent for the wsu:Timestamp values -->
	<xsl:variable name="CURRENT_TIME" select="date:add(date:date-time(), 'PT0S')"/>
	<xsl:variable name="TIMESTAMP_ID" select="concat('Timestamp-',dp:generate-uuid())"/>
	<xsl:variable name="SEC_TOKEN_ID" select="concat('SecToken-',dp:generate-uuid())"/>
	<xsl:variable name="SAML_ASSERTION_ID" select="concat('SamlAssertion-',dp:generate-uuid())"/>
	<xsl:variable name="SIGN_METHOD_ALGO" select="'http://www.w3.org/2000/09/xmldsig#rsa-sha1'"/>

	<xsl:variable name="SIGNING_KEY">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_TOKEN_SIGNING_KEY"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="SIGN_KEY_ID" select="concat('name:', $SIGNING_KEY)"/>
	<xsl:variable name="SIGN_CERT_ID" select="concat('name:', $SIGNING_KEY)"/>

	<xsl:variable name="C14N_ALGO" select="'http://www.w3.org/2001/10/xml-exc-c14n#'"/>
	<xsl:variable name="DIGEST_ALGO" select="'http://www.w3.org/2000/09/xmldsig#sha1'"/>
	<!-- Default timestamp duration (5 minutes) -->
	<xsl:variable name="TS_DURATION" select="'PT8H'"/>
	<xsl:variable name="SIGN_CERT_TEXT" select="dp:base64-cert($SIGN_CERT_ID)"/>
	<xsl:variable name="SIGN_CERT_DN" select="dp:get-cert-subject(concat('cert:',$SIGN_CERT_TEXT))"/>
	<xsl:variable name="SIGN_CERT_SERIAL"
		select="dp:get-cert-serial(concat('cert:',$SIGN_CERT_TEXT))"/>
	<!-- Some Useful Information when Creating a SAML Token :-) -->
	<xsl:variable name="AUTHENTICATED_USER"
		select="dp:variable('var://context/WSM/identity/authenticated-user')"/>
	<!-- The attribute statement is generated in the Authorise Step of the AAA Action -->
	<xsl:variable name="SAML_ATTRIBUTE_STATEMENT"
		select="dp:variable('var://context/service/groupattributes')"/>
	<xsl:variable name="IP_ADDRESS" select="dp:variable('var://service/transaction-client')"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!-- Create the SAML Assertion -->
	<xsl:variable name="SAML_ASSERTION_NODE">
		<xsl:call-template name="NewSaml2Assertion">
			<xsl:with-param name="ID" select="$SAML_ASSERTION_ID"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="SIGNATURE">
		<xsl:call-template name="NewSignature">
			<xsl:with-param name="ID" select="$SAML_ASSERTION_NODE"/>
		</xsl:call-template>
	</xsl:variable>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<xsl:template match="/">
		<!--Add the Signature to the Assertion-->
		<dp:set-variable name="'var://context/service/generatedAssertion'"
			value="$SAML_ASSERTION_NODE"/>
		<xsl:apply-templates select="$SAML_ASSERTION_NODE" mode="sig"/>
	</xsl:template>
	<!-- Identity Transform -->
	<xsl:template match="@*|node()" mode="sig">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="sig"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="saml:Issuer" mode="sig">
		<dp:set-variable name="'var://context/service/generatedSignature'" value="$SIGNATURE"/>
		<xsl:copy-of select="."/>
		<xsl:copy-of select="$SIGNATURE"/> </xsl:template>
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Named template to generate a new SAML2 Assertion -->
	<xsl:template name="NewSaml2Assertion">
		<xsl:param name="ID"/>
		<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="{$ID}"
			IssueInstant="{$CURRENT_TIME}" Version="2.0">
			<saml:Issuer>urn:api.dpdirect.org</saml:Issuer>
			<saml:Subject>
				<saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">
					<xsl:value-of select="$AUTHENTICATED_USER"/>
				</saml:NameID>
				<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
					<saml:SubjectConfirmationData NotBefore="{$CURRENT_TIME}"
						NotOnOrAfter="{date:add($CURRENT_TIME, $TS_DURATION)}"/>
				</saml:SubjectConfirmation>
			</saml:Subject>
			<saml:Conditions NotBefore="{$CURRENT_TIME}"
				NotOnOrAfter="{date:add($CURRENT_TIME, $TS_DURATION)}"/>
			<saml:AuthnStatement AuthnInstant="{$CURRENT_TIME}"
				SessionNotOnOrAfter="{date:add($CURRENT_TIME, $TS_DURATION)}">
				<saml:SubjectLocality Address="{$IP_ADDRESS}"/>
				<saml:AuthnContext>
					<saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>
				</saml:AuthnContext>
			</saml:AuthnStatement>
			<saml:AttributeStatement>
				<xsl:copy-of select="$SAML_ATTRIBUTE_STATEMENT"/>
			</saml:AttributeStatement>
		</saml:Assertion>
	</xsl:template>
	<!-- Named template to generate a new SignedInfo Reference element -->
	<xsl:template name="NewReference">
		<xsl:param name="NODE">
			<!-- Initialise the param with an empty node. This prevents a DataPower compilation 
				warning about an illegal cast from string to nodeset when calling dp:exc-c14n-hash() below. -->
			<Empty/>
		</xsl:param>
		<xsl:param name="ID"/>
		<ds:Reference URI="{$ID}">
			<ds:Transforms>
				<ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
				<ds:Transform Algorithm="{$C14N_ALGO}"/>
			</ds:Transforms>
			<ds:DigestMethod Algorithm="{$DIGEST_ALGO}"/>
			<ds:DigestValue>
				<xsl:value-of select="dp:exc-c14n-hash('', $NODE, false(), $DIGEST_ALGO)"/>
			</ds:DigestValue>
		</ds:Reference>
	</xsl:template>
	<!-- Named template to generate a new Signature -->
	<xsl:template name="NewSignature">
		<xsl:param name="ID"/>
		<ds:Signature>
			<xsl:variable name="SIGNED_INFO_NODE">
				<ds:SignedInfo>
					<ds:CanonicalizationMethod Algorithm="{$C14N_ALGO}"/>
					<ds:SignatureMethod Algorithm="{$SIGN_METHOD_ALGO}"/>
					<xsl:call-template name="NewReference">
						<xsl:with-param name="ID" select="concat('#',$SAML_ASSERTION_ID)"/>
						<xsl:with-param name="NODE" select="$SAML_ASSERTION_NODE"/>
					</xsl:call-template>
				</ds:SignedInfo>
			</xsl:variable>
			<xsl:copy-of select="$SIGNED_INFO_NODE"/>
			<ds:SignatureValue>
				<xsl:variable name="SIGNED_INFO_HASH"
					select="dp:exc-c14n-hash('', $SIGNED_INFO_NODE,
					false(), $DIGEST_ALGO)"/>
				<xsl:value-of select="dp:sign($SIGN_METHOD_ALGO, $SIGNED_INFO_HASH, $SIGN_KEY_ID)"/>
			</ds:SignatureValue>
			<ds:KeyInfo>
				<ds:X509Data>
					<ds:X509Certificate>
						<xsl:value-of select="$SIGN_CERT_TEXT"/>
					</ds:X509Certificate>
				</ds:X509Data>
			</ds:KeyInfo>
		</ds:Signature>
	</xsl:template>
</xsl:stylesheet>
