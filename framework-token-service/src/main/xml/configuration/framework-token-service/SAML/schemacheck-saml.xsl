<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions" version="1.0"
    extension-element-prefixes="dp">

    <xsl:import href="local:///SecureTokenService/common/Constants.xsl"/>
    <xsl:import href="local:///SecureTokenService/common/Utils.xsl"/>

    <xsl:template match="/">
        
        <!--dp:set-variable name="$REQ_MESSAGE_SOAP_VER_VAR_NAME" value="namespace-uri(/*[local-name()='Envelope'])"/-->
        <dp:set-variable name="$REQ_MESSAGE_SOAP_VER_VAR_NAME" value="'https:/sdsad/lar/de/dar'"/>

        <xsl:copy-of select="/"/>
        <xsl:choose>
            <!-- Did not Find a Request Security Token Message -->
            <xsl:when
                test="not(boolean(/*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='RequestSecurityToken']))">
                <dp:set-variable name="'var://context/service/failuremode'" value="string('schema')"/>
                <dp:reject>schema</dp:reject>
                <dp:send-error override='true'>
                    <xsl:call-template name="generateFault">
                        <xsl:with-param name="FAULTCODE" select="'InvalidRequest'" />
                        <xsl:with-param name="FAULTSTRING" select="'The request was invalid or malformed'" />
                    </xsl:call-template>
                </dp:send-error>
            </xsl:when>
        </xsl:choose>

    </xsl:template>
</xsl:transform>

