<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512/" version="1.0">


    <xsl:template match="/">
        <xsl:variable name="TOKEN_NOT_BEFORE"
            select="/saml:Assertion/saml:AuthnStatement/@AuthnInstant"/>
        <xsl:variable name="TOKEN_NOT_AFTER"
            select="/saml:Assertion/saml:AuthnStatement[1]/@SessionNotOnOrAfter"/>
        <soap:Envelope>
            <soap:Body>
                <wst:RequestSecurityTokenResponseCollection>
                    <wst:RequestSecurityTokenResponse>
                        <wst:TokenType>urn:oasis:names:tc:SAML:2.0:assertion</wst:TokenType>
                        <wst:RequestedSecurityToken>
                            <xsl:copy>
                                <xsl:apply-templates select="@*|node()"/>
                            </xsl:copy>
                        </wst:RequestedSecurityToken>
                        <wsp:AppliesTo xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy"/>
                        <wst:Lifetime>
                            <wst:Created>
                                <xsl:value-of select="$TOKEN_NOT_BEFORE"/>
                            </wst:Created>
                            <wst:Expires>
                                <xsl:value-of select="$TOKEN_NOT_AFTER"/>
                            </wst:Expires>
                        </wst:Lifetime>
                    </wst:RequestSecurityTokenResponse>
                </wst:RequestSecurityTokenResponseCollection>
            </soap:Body>
        </soap:Envelope>
    </xsl:template>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
