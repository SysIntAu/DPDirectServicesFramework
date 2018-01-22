<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:dp="http://www.datapower.com/extensions" xmlns:date="http://exslt.org/dates-and-times"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" extension-element-prefixes="dp">

    <xsl:template name="getJwtHeader">
        <xsl:param name="TOKEN"/>
        <xsl:value-of select="substring-before($TOKEN, '.')"/>
    </xsl:template>

    <xsl:template name="getJwtClaims">
        <xsl:param name="TOKEN"/>
        <xsl:value-of select="substring-before(substring-after($TOKEN, '.'),'.')"/>
    </xsl:template>

    <xsl:template name="getJwtSignature">
        <xsl:param name="TOKEN"/>
        <xsl:value-of select="substring-after(substring-after($TOKEN, '.'),'.')"/>
    </xsl:template>

    <xsl:template name="buildKVPairs">
        <xsl:param name="KEY"/>
        <xsl:param name="VALUE"/>
        <xsl:text>&quot;</xsl:text>
        <xsl:value-of select="$KEY"/>
        <xsl:text>&quot;: </xsl:text>
        <xsl:choose>
            <!-- no quotes if a number-->
            <xsl:when test="number($VALUE) = number($VALUE)">
                <xsl:value-of select="$VALUE"/>
            </xsl:when>
            <!-- <!-\- no quotes if value is an array -->
            <xsl:when test="substring($VALUE, 1, 1) = '['">
                <xsl:value-of select="$VALUE"/>
            </xsl:when>
            <!-- value needs to be quoted -->
            <xsl:otherwise>
                <xsl:text>&quot;</xsl:text>
                <xsl:value-of select="$VALUE"/>
                <xsl:text>&quot;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="buildArray">
        <xsl:param name="ARRAYLIST"/>
        <xsl:apply-templates select="$ARRAYLIST" mode="genArray"/>
    </xsl:template>

    <xsl:template match="/" mode="genArray">
        <xsl:text>[</xsl:text>
        <xsl:for-each select="child::node()/*">

            <xsl:choose>
                <xsl:when test="number(.) = number(.)">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>&quot;</xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text>&quot;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:choose>
                <xsl:when test="not(position() = last())">
                    <xsl:text>, </xsl:text>
                </xsl:when>
            </xsl:choose>

        </xsl:for-each>
        <xsl:text>]</xsl:text>
    </xsl:template>

    <xsl:template name="signToken">
        <xsl:param name="PAYLOAD"/>
        <xsl:value-of
            select="translate(dp:hmac('http://www.w3.org/2001/04/xmldsig-more#hmac-sha256', 'key:c2VjcmV0', $PAYLOAD),'+/=', '-_')"
        />
    </xsl:template>

    <xsl:template name="verifyToken">
        <xsl:param name="PAYLOAD"/>
        <xsl:param name="SIGNATURE"/>

        <xsl:variable name="GENERATED_SIGNATURE">
            <xsl:call-template name="signToken">
                <xsl:with-param name="PAYLOAD" select="$PAYLOAD"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$SIGNATURE = $GENERATED_SIGNATURE">
                <xsl:text>passed</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>failed</xsl:text>
            </xsl:otherwise>
        </xsl:choose>


    </xsl:template>



    <xsl:template name="base64UrlEncode">
        <xsl:param name="PAYLOAD"/>
        <xsl:value-of select="translate(dp:encode($PAYLOAD, 'base-64'),'+/=', '-_')"/>
    </xsl:template>


    <xsl:template name="base64UrlDecode">
        <xsl:param name="PAYLOAD"/>
        <xsl:variable name="CHARS_TO_PAD">
            <xsl:choose>
                <xsl:when test="string-length($PAYLOAD) mod 4 = 0">
                    <xsl:value-of select="0"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="4 - string-length($PAYLOAD) mod 4"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:value-of
            select="dp:decode(concat(translate($PAYLOAD,'-_', '+/'), substring('====', 1, $CHARS_TO_PAD)), 'base-64')"
        />
    </xsl:template>


</xsl:stylesheet>
