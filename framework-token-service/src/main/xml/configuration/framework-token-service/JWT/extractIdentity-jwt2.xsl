<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
    xmlns:otps-wst="http://www.rsasecurity.com/rsalabs/otps/schemas/2005/09/otps-wst#"
    xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" version="1.0"
    exclude-result-prefixes="otps-wst wsse soap">

    <xsl:template match="/">

        <xsl:variable name="RadiusUserName" select="string(/soap:Envelope/soap:Header[1]/wsse:Security[1]/wsse:UsernameToken[1]/wsse:Username[1])"/>
        <dp:set-variable name="'var://context/service/RadiusUserName'" value="$RadiusUserName"/>
        <xsl:variable name="RadiusPassword"
            select="concat(/soap:Envelope/soap:Header[1]/wsse:Security[1]/wsse:UsernameToken[1]/wsse:Password[1], string(/soap:Envelope/soap:Header[1]/wsse:Security[1]/otps-wst:OTPToken[1]/otps-wst:OTP[1]))"/>
        <dp:set-variable name="'var://context/service/RadiusPassword'" value="$RadiusPassword"/>
        
    </xsl:template>
</xsl:stylesheet>