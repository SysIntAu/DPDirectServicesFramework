<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" exclude-result-prefixes="dp exslt
	saml xsi" version="1.0">
	<xsl:include href="local:///SecureTokenService/common/Utils.xsl"/>
	<xsl:variable name="USER_ID" select="dp:variable('var://context/WSM/identity/authenticated-user')"/>
	<xsl:variable name="GROUP_ATTRIBUTE">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_GROUP_ATTRIBUTE_NAME"/>
		</xsl:call-template>
	</xsl:variable>
	<!-- Look up the user's group membership-->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="not($USER_ID = '')">
				<xsl:message dp:type="multistep" dp:priority="info">
					<xsl:text>For user: </xsl:text>
					<xsl:value-of select="$USER_ID"/>
					<xsl:text>, querying LDAP for group membership. </xsl:text>
				</xsl:message>
				<xsl:variable name="RESULTS">
					<xsl:call-template name="getMsgGroupsForUser">
						<xsl:with-param name="USERID" select="$USER_ID"/>
					</xsl:call-template>
				</xsl:variable>
				<!-- get all group memberships which start with the Mobile Group Prefix-->
				<xsl:variable name="EXT_GRPS"
					select="exslt:node-set($RESULTS)/LDAP-search-results/result/attribute-value[@name=$GROUP_ATTRIBUTE]"/>
				<xsl:variable name="LDAP_ERROR"
					select="normalize-space(exslt:node-set($RESULTS)/LDAP-search-error/error)"/>
				<xsl:variable name="EXT_GRP_RESULT">
					<result>
						<xsl:copy-of select="exslt:node-set($EXT_GRPS)"/>
					</result>
				</xsl:variable>
				<dp:set-variable name="'var://context/service/aaagrps'" value="$EXT_GRP_RESULT"/>
				<xsl:choose>
					<!-- set the failure mode for LDAP error-->
					<xsl:when test="$LDAP_ERROR != ''">
						<dp:set-variable name="'var://context/service/failuremode'" value="'authenticate error'"/>
						<declined/>
					</xsl:when>
					<!-- set the failure mode and decline the authorisation if the user does not have any mobile group memberships-->
					<xsl:when test="count($EXT_GRPS) = 0">
						<dp:set-variable name="'var://context/service/failuremode'" value="'authenticate nomsg_grps'"/>
						<declined/>
					</xsl:when>
					<!-- otherwise build the attribute statement and assign to a variable-->
					<xsl:otherwise>
						<xsl:variable name="GROUP_ATTRIBUTE_STATEMENT">
							<saml:Attribute name="group">
								<xsl:for-each select="$EXT_GRPS">
									<saml:AttributeValue>
										<xsl:value-of select="."/>
									</saml:AttributeValue>
								</xsl:for-each>
							</saml:Attribute>
						</xsl:variable>
						<dp:set-variable name="'var://context/service/failuremode'" value="''"/>
						<dp:set-variable name="'var://context/service/groupattributes'" value="$GROUP_ATTRIBUTE_STATEMENT"/>
						<approved>
							<xsl:text>The subject [</xsl:text>
							<xsl:value-of select="$USER_ID"/>
							<xsl:text>] has mobile group memberships</xsl:text>
						</approved>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<dp:set-variable name="'var://context/service/failuremode'" value="'authenticate'"/>
				<declined/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
