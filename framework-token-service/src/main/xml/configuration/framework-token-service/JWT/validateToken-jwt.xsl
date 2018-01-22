<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx"
	xmlns:date="http://exslt.org/dates-and-times" version="1.0" xmlns:dp="http://www.datapower.com/extensions"
	xmlns:exslt="http://exslt.org/common" exclude-result-prefixes="dp date json">
	<xsl:import href="local:///SecureTokenService/common/Utils.xsl"/>
	<!-- prior to this style sheet, the token has been decoded.
        Here we test the signature -->
	<xsl:variable name="JWT_HEADER" select="dp:variable('var://context/service/JWT_HEADER')"/>
	<xsl:variable name="JWT_CLAIMS" select="dp:variable('var://context/service/JWT_CLAIMS')"/>
	<xsl:variable name="JWT_SIGNATURE" select="dp:variable('var://context/service/JWT_SIGNATURE')"/>
	<xsl:variable name="CURRENT_TIMESTAMP" select="date:seconds()"/>
	<xsl:variable name="GROUP_ATTRIBUTE">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_GROUP_ATTRIBUTE_NAME"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:template match="/">
		<xsl:variable name="JWT_PAYLOAD" select="concat($JWT_HEADER, '.', $JWT_CLAIMS)"/>
		<xsl:variable name="JWT_VALIDATION_RESULT">
			<xsl:call-template name="verifyJwtTokenSignature">
				<xsl:with-param name="PAYLOAD" select="$JWT_PAYLOAD"/>
				<xsl:with-param name="SIGNATURE" select="$JWT_SIGNATURE"/>
			</xsl:call-template>
		</xsl:variable>
		<!-- audience -->
		<xsl:variable name="IP_ADDRESS" select="dp:variable('var://service/transaction-client')"/>
		<xsl:variable name="STS_HOST_ALIAS" select="dp:variable($DP_SERVICE_DOMAIN_NAME)"/>
		<xsl:variable name="STS_BASE_ADDR" select="concat('https://', $STS_HOST_ALIAS)"/>
		<!-- Is the STS a resource specified in the 'audience' claim -->
		<xsl:variable name="JWT_AUDIENCE">
			<xsl:for-each select="/json:object/json:array[@name='aud']/json:string">
				<xsl:if test="normalize-space($STS_BASE_ADDR) = normalize-space(.)">
					<xsl:value-of select="."/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<!-- time bounds -->
		<xsl:variable name="TOKEN_START_TIMESTAMP" select="json:object/json:number[@name='nbf']"/>
		<xsl:variable name="TOKEN_EXPIRY_TIMESTAMP" select="json:object/json:number[@name='exp']"/>
		<!-- make sure the claims match what's in LDAP. I know, this sounds ridiculous, we're not
            	trusting our own claims, but we don't have an invalidate binding.
           	 LDAP results are being cached and will only go off box after TTL has passed -->
		<xsl:variable name="USER_ID" select="json:object/json:string[@name='sub']"/>
		<xsl:variable name="RESULTS">
			<xsl:call-template name="getMsgGroupsForUser">
				<xsl:with-param name="USERID" select="$USER_ID"/>
				<xsl:with-param name="USECACHE" select="true"/>
			</xsl:call-template>
		</xsl:variable>
		<!-- get all group memberships which start with the Mobile Group Prefix-->
		<xsl:variable name="EXT_GRPS" select="exslt:node-set($RESULTS)/LDAP-search-results/result/attribute-value[@name=$GROUP_ATTRIBUTE]"/>
		<!-- List all asserted groups which are not present-->
		<xsl:variable name="ASSERTED_GROUPS_NOT_PRESENT">
			<xsl:for-each select="json:object/json:array[@name=concat($JWT_TOKEN_NS,'-groups')]/json:string">
				<xsl:if test="not($EXT_GRPS/node() = .)">
					<xsl:value-of select="."/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="EXT_GRP_RESULT">
			<result>
				<xsl:copy-of select="exslt:node-set($EXT_GRPS)"/>
			</result>
		</xsl:variable>
		<xsl:variable name="VALIDITY_STATUS">
			<xsl:choose>
				<xsl:when test="$JWT_AUDIENCE = ''">INVALID</xsl:when>
				<xsl:when test="$JWT_VALIDATION_RESULT='failed'">INVALID</xsl:when>
				<!-- we haven't allowed for skew because the same device is generating and validating claims -->
				<xsl:when test="$CURRENT_TIMESTAMP >= $TOKEN_EXPIRY_TIMESTAMP">INVALID</xsl:when>
				<xsl:when test="not($CURRENT_TIMESTAMP > $TOKEN_START_TIMESTAMP)">INVALID</xsl:when>
				<xsl:when test="not($ASSERTED_GROUPS_NOT_PRESENT = '')">INVALID</xsl:when>
				<xsl:otherwise>VALID</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="STATUS_CODE">
			<xsl:choose>
				<xsl:when test="$JWT_VALIDATION_RESULT='failed'">token_invalid</xsl:when>
				<!-- we haven't allowed for skew because the same device is generating and validating claims -->
				<xsl:when test="$CURRENT_TIMESTAMP >= $TOKEN_EXPIRY_TIMESTAMP">token_expired</xsl:when>
				<xsl:when test="not($CURRENT_TIMESTAMP > $TOKEN_START_TIMESTAMP)">token_invalid</xsl:when>
				<!--<xsl:when test="not($ASSERTED_GROUPS_NOT_PRESENT = '')">invalid_claims</xsl:when>-->
				<xsl:when test="not($ASSERTED_GROUPS_NOT_PRESENT = '')">token_invalid</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<tokenstatus>
			<status>
				<xsl:value-of select="$VALIDITY_STATUS"/>
			</status>
			<xsl:choose>
				<xsl:when test="$VALIDITY_STATUS = 'VALID'">
					<tokenclaims>
						<xsl:apply-templates mode="jsonx2xml"/>
					</tokenclaims>
				</xsl:when>
				<xsl:otherwise>
					<code>
						<xsl:value-of select="$STATUS_CODE"/>
					</code>
				</xsl:otherwise>
			</xsl:choose>
		</tokenstatus>
	</xsl:template>
	<xsl:template match="/json:object" mode="jsonx2xml">
		<xsl:apply-templates mode="jsonx2xml"/>
	</xsl:template>
	<xsl:template match="json:array[@name]" mode="jsonx2xml">
		<xsl:element name="{@name}">
			<xsl:apply-templates mode="jsonx2xml"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="json:object" mode="jsonx2xml">
		<xsl:element name="{../@name}">
			<xsl:apply-templates mode="jsonx2xml"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="json:string[not(@name)]" mode="jsonx2xml">
		<xsl:element name="{../@name}">
			<xsl:attribute name="arraymember"/>
			<xsl:value-of select="normalize-space(.)"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="json:string[@name]" mode="jsonx2xml">
		<xsl:element name="{@name}">
			<xsl:value-of select="normalize-space(.)"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="json:number[@name]" mode="jsonx2xml">
		<xsl:element name="{@name}">
			<xsl:value-of select="normalize-space(.)"/>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
