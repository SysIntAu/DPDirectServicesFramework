<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx"
    xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" version="1.0">
    
    
    <xsl:template match="/">
        
        <!-- make sure the right number of elements exist -->
        
        <xsl:variable name="RadiusUserName" select="string(/json:object/json:string[@name='username'])"/>
        <dp:set-variable name="'var://context/service/RadiusUserName'" value="$RadiusUserName"/>
        <xsl:variable name="RadiusPassword"
            select="concat(/json:object/json:string[@name='password'], string(/json:object/*[@name='otp']))"/>
        <dp:set-variable name="'var://context/service/RadiusPassword'" value="$RadiusPassword"/>
        
    </xsl:template>
</xsl:stylesheet>