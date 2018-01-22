<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx">
    <xsl:output indent="yes" encoding="UTF-8" omit-xml-declaration="yes"/>
    <xsl:strip-space elements="*"/>

    <!-- Array -->
    <xsl:template match="*[*[2]][name(*[1])=name(*[2])]">
        <json:object name="{name()}">
            <json:array name="{name(*[1])}">
                <xsl:apply-templates/>
            </json:array>
        </json:object>
    </xsl:template>

    <!-- Array member -->
    <xsl:template match="*[parent::*[ name(*[1])=name(*[2]) ]] | /">
        <json:object>
            <xsl:apply-templates/>
        </json:object>
    </xsl:template>
    
    <xsl:template match="*[*[@arraymember]]">
        <json:array name="{name()}">
            <xsl:apply-templates/>
        </json:array>
    </xsl:template>
<!--
    <xsl:template match="@arraymember" priority="1">
        <xsl:choose>
            <xsl:when test="number(.) = number(.)">
                <json:number>
                    <xsl:value-of select="."/>
                </json:number>             
            </xsl:when>
            <xsl:otherwise>
                <json:string>
                    <xsl:value-of select="."/>
                </json:string>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->

    <!-- Object -->
    <xsl:template match="*">
        <json:object name="{name()}">
            <xsl:apply-templates/>
        </json:object>
    </xsl:template>

    <!-- String -->
    <xsl:template match="*[not(*)]">
        <xsl:choose>
            <xsl:when test="@arraymember">
                <xsl:choose>
                    <xsl:when test="number(.) = number(.)">
                        <json:number>
                            <xsl:value-of select="."/>
                        </json:number>
                    </xsl:when>
                    <xsl:otherwise>
                        <json:string>
                            <xsl:value-of select="."/>
                        </json:string>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="number(.) = number(.)">
                        <json:number name="{name()}">
                            <xsl:value-of select="."/>
                        </json:number>
                    </xsl:when>
                    <xsl:otherwise>
                        <json:string name="{name()}">
                            <xsl:value-of select="."/>
                        </json:string>
                    </xsl:otherwise>
                </xsl:choose>


            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
