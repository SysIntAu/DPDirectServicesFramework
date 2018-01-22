<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" exclude-result-prefixes="dp exslt saml xsi" version="1.0">
	<xsl:include href="local:///SecureTokenService/common/Utils.xsl"/>
	<xsl:variable name="UID" select="/request/args/arg[@name='userid']"/>
	<xsl:variable name="SERVER_ADDRESS">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_HOST"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="PORT_NUMBER">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_PORT"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="BIND_DN">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_BIND_DN"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="BIND_PASSWORD">
		<xsl:call-template name="GetDPDirectSecurityProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_BIND_PASSWORD"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="TARGET_DN">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_TARGET_DN_TEMPLATE"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="ATTRIBUTE_NAME">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_GROUP_ATTRIBUTE_NAME"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="SCOPE">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_SEARCH_SCOPE"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="SSL_PROXY_PROFILE" select="'SslClientNoCredentials'"/>
	<xsl:variable name="LDAP_LB_GROUP" select="''"/>
	<!--        <xsl:call-template name="GetDPDirectProperty">
            <xsl:with-param name="KEY" select="''"/>
        </xsl:call-template>
    </xsl:variable>
-->
	<xsl:variable name="LDAP_VERSION">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_VERSION"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="GROUP_ATTRIBUTE">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_GROUP_ATTRIBUTE_NAME"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="GATEWAY_GROUP_PREFIX">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_EXT_GROUP_PREFIX"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="GATEWAY_GROUP_LIST">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_EXT_GROUP_LIST"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="FILTER" select="concat('uid=',$UID)"/>
	<xsl:variable name="BLACKLIST_GROUP">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_BLACKLIST_GROUP"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:template match="/">
		<xsl:variable name="RESULTS" select="dp:ldap-search($SERVER_ADDRESS,                      $PORT_NUMBER,
			$BIND_DN,                      $BIND_PASSWORD,                      $TARGET_DN,                      $ATTRIBUTE_NAME,
			$FILTER,                      $SCOPE,                      $SSL_PROXY_PROFILE,                      $LDAP_LB_GROUP,
			$LDAP_VERSION)"/>
		<!--<xsl:copy-of select="$RESULTS"/>-->
		<xsl:apply-templates select="$RESULTS" mode="results"/>
	</xsl:template>
	<xsl:template match="node()|@*" mode="results">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*" mode="results"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="attribute-value" mode="results">
		<xsl:variable name="GROUP_NAME" select="substring-after(substring-before(text(),','),'=')"/>
		<xsl:variable name="GROUP_PREFIX" select="substring-after(substring-before(text(),'_'),'=')"/>
		<xsl:choose>
			<xsl:when test="contains(concat(',', $GATEWAY_GROUP_LIST, ','), $GROUP_NAME)">
				<attribute-value>
					<xsl:copy-of select="@*"/>
					<xsl:value-of select="(substring-after(substring-before(.,','),'='))"/>
				</attribute-value>
			</xsl:when>
			<xsl:when test="$GROUP_PREFIX = $GATEWAY_GROUP_PREFIX">
				<attribute-value>
					<xsl:copy-of select="@*"/>
					<xsl:value-of select="(substring-after(substring-before(.,','),'='))"/>
				</attribute-value>
			</xsl:when>
		</xsl:choose>
		<!--<xsl:value-of select="(substring-after(substring-before(.,','),'='))-->
	</xsl:template>
</xsl:stylesheet>
