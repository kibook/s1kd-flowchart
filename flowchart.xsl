<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  
  <!-- Convert S1000D fault isolation procedures to flowcharts via the Graphviz
       DOT language -->

  <!-- Node defaults. Can also be set invidiually for each type of node. -->
  <xsl:param name="node-style">solid</xsl:param>
  <xsl:param name="node-font-colour">black</xsl:param>
  <!-- If node-style = filled, this will set the outline colour.
       Otherwise, this sets the colour of all nodes. -->
  <xsl:param name="node-colour"/>

  <!-- Edge defaults -->
  <xsl:param name="edge-style">solid</xsl:param>
  <xsl:param name="edge-font-colour">black</xsl:param>

  <!-- Action nodes (element <action>) -->
  <xsl:param name="action-colour">red</xsl:param>
  <xsl:param name="action-shape">rectangle</xsl:param>
  <xsl:param name="action-style" select="$node-style"/>
  <xsl:param name="action-font-colour" select="$node-font-colour"/>

  <!-- Question nodes (element <isolationStepQuestion>) -->
  <xsl:param name="question-colour">blue</xsl:param>
  <xsl:param name="question-shape">diamond</xsl:param>
  <xsl:param name="question-style" select="$node-style"/>
  <xsl:param name="question-font-colour" select="$node-font-colour"/>

  <!-- Preliminary action nodes -->
  <xsl:param name="preliminary-colour">green</xsl:param>
  <xsl:param name="preliminary-shape">rectangle</xsl:param>
  <xsl:param name="preliminary-style" select="$node-style"/>
  <xsl:param name="preliminary-font-colour" select="$node-font-colour"/>

  <!-- Requirements after job completion nodes -->
  <xsl:param name="close-colour">violet</xsl:param>
  <xsl:param name="close-shape">rectangle</xsl:param>
  <xsl:param name="close-style" select="$node-style"/>
  <xsl:param name="close-font-colour" select="$node-font-colour"/>

  <!-- Wrap long labels to this many characters -->
  <xsl:param name="word-wrap">30</xsl:param>

  <!-- Splines determine how edges are formed
         true  = curved lines
         line  = only straight lines
         ortho = only 90 degree angles -->
  <xsl:param name="splines">ortho</xsl:param>

  <!-- Use normal or external labels for nodes/edges -->
  <xsl:param name="node-label-type">label</xsl:param>
  <xsl:param name="edge-label-type">xlabel</xsl:param>
  
  <xsl:output method="text"/>

  <!-- Wrap text function -->
  <xsl:template name="wrap-string">
    <xsl:param name="str"/>
    <xsl:param name="wrap-col"/>
    <xsl:param name="break-mark"/>
    <xsl:param name="pos" select="0"/>
    <xsl:choose>
      <xsl:when test="contains( $str, ' ' )">
        <xsl:variable name="first-word" select="substring-before( $str, ' ' )"/>
        <xsl:variable name="pos-now" select="$pos + 1 + string-length( $first-word )"/>
        <xsl:choose>
          <xsl:when test="$pos &gt; 0 and $pos-now &gt;= $wrap-col">
            <xsl:copy-of select="$break-mark"/>
            <xsl:call-template name="wrap-string">
              <xsl:with-param name="str" select="$str"/>
              <xsl:with-param name="wrap-col" select="$wrap-col"/>
              <xsl:with-param name="break-mark" select="$break-mark"/>
              <xsl:with-param name="pos" select="0"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$first-word"/>
            <xsl:text> </xsl:text>
            <xsl:call-template name="wrap-string">
              <xsl:with-param name="str" select="substring-after( $str, ' ' )"/>
              <xsl:with-param name="wrap-col" select="$wrap-col"/>
              <xsl:with-param name="break-mark" select="$break-mark"/>
              <xsl:with-param name="pos" select="$pos-now"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$pos + string-length( $str ) &gt;= $wrap-col">
          <xsl:copy-of select="$break-mark"/>
        </xsl:if>
        <xsl:value-of select="$str"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="*" mode="id">
    <xsl:value-of select="generate-id(.)"/>
  </xsl:template>

  <xsl:template match="*" mode="label">
    <xsl:variable name="text">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:call-template name="wrap-string">
      <xsl:with-param name="str" select="normalize-space($text)"/>
      <xsl:with-param name="wrap-col" select="$word-wrap"/>
      <xsl:with-param name="break-mark"><xsl:text disable-output-escaping="yes">&#10;</xsl:text></xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- A node statement in the DOT language -->
  <xsl:template name="dot-node">
    <xsl:param name="id">
      <xsl:apply-templates select="." mode="id"/>
    </xsl:param>
    <xsl:param name="label"/>
    <xsl:param name="shape"/>
    <xsl:param name="colour"/>
    <xsl:param name="style" select="$node-style"/>
    <xsl:param name="font-colour" select="$node-font-colour"/>
    <xsl:param name="target"/>
    <xsl:param name="edge-label"/>
    <xsl:param name="edge-style" select="$edge-style"/>

    <xsl:text>{</xsl:text>
    <xsl:value-of select="$id"/>

    <xsl:text> [</xsl:text>

    <xsl:if test="$label">
      <xsl:value-of select="$node-label-type"/>
      <xsl:text>="</xsl:text>
      <xsl:value-of select="$label"/>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <xsl:if test="$shape">
      <xsl:text> </xsl:text>
      <xsl:text>shape=</xsl:text>
      <xsl:value-of select="$shape"/>
    </xsl:if>

    <xsl:if test="$colour">
      <xsl:choose>
        <xsl:when test="$node-colour">
          <xsl:text> </xsl:text>
          <xsl:text>color=</xsl:text>
          <xsl:value-of select="$node-colour"/>
          <xsl:text> </xsl:text>
          <xsl:text>fillcolor=</xsl:text>
          <xsl:value-of select="$colour"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text> </xsl:text>
          <xsl:text>color=</xsl:text>
          <xsl:value-of select="$colour"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <xsl:if test="$style">
      <xsl:text> </xsl:text>
      <xsl:text>style=</xsl:text>
      <xsl:value-of select="$style"/>
    </xsl:if>

    <xsl:if test="$font-colour">
      <xsl:text> </xsl:text>
      <xsl:text>fontcolor=</xsl:text>
      <xsl:value-of select="$font-colour"/>
    </xsl:if>

    <xsl:text>]</xsl:text>

    <xsl:text>}</xsl:text>

    <xsl:if test="$target != ''">
      <xsl:text> -> </xsl:text>
      <xsl:value-of select="$target"/>
    </xsl:if>
    
    <xsl:text> [</xsl:text>

    <xsl:if test="$edge-label">
      <xsl:value-of select="$edge-label-type"/>
      <xsl:text>="</xsl:text>
      <xsl:value-of select="$edge-label"/>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <xsl:if test="$edge-style">
      <xsl:text> </xsl:text>
      <xsl:text>style=</xsl:text>
      <xsl:value-of select="$edge-style"/>
    </xsl:if>

    <xsl:text>]</xsl:text>

    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- Graph definition -->
  <xsl:template match="dmodule">
    <xsl:text>digraph g {</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>graph [splines=</xsl:text>
    <xsl:value-of select="$splines"/>
    <xsl:text>]&#10;</xsl:text>
    <xsl:apply-templates select="//isolationProcedure"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- Each preliminary requirement links to the next, except the last which
       links to the first step. -->
  <xsl:template match="preliminaryRqmts/reqCondGroup/*[not(self::noConds)]">
    <xsl:call-template name="dot-node">
      <xsl:with-param name="label">
        <xsl:apply-templates select="reqCond" mode="label"/>
      </xsl:with-param>
      <xsl:with-param name="shape" select="$preliminary-shape"/>
      <xsl:with-param name="colour" select="$preliminary-colour"/>
      <xsl:with-param name="style" select="$preliminary-style"/>
      <xsl:with-param name="font-colour" select="$preliminary-font-colour"/>
      <xsl:with-param name="target">
        <xsl:choose>
          <xsl:when test="position() != last()">
            <xsl:apply-templates select="following-sibling::*" mode="id"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="//isolationMainProcedure/*[1]" mode="id"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- Point to either the action, or the question if there is no action -->
  <xsl:template match="isolationStep" mode="id">
    <xsl:choose>
      <xsl:when test="action">
        <xsl:apply-templates select="action" mode="id"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="isolationStepQuestion" mode="id"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="isolationProcedureEnd" mode="id">
    <xsl:apply-templates select="action" mode="id"/>
  </xsl:template>

  <!-- Action nodes -->
  <xsl:template match="action">
    <xsl:call-template name="dot-node">
      <xsl:with-param name="id">
        <xsl:apply-templates select="." mode="id"/>
      </xsl:with-param>
      <xsl:with-param name="label">
        <xsl:apply-templates select="." mode="label"/>
      </xsl:with-param>
      <xsl:with-param name="shape" select="$action-shape"/>
      <xsl:with-param name="colour" select="$action-colour"/>
      <xsl:with-param name="style" select="$action-style"/>
      <xsl:with-param name="font-colour" select="$action-font-colour"/>
      <xsl:with-param name="target">
        <xsl:choose>
          <xsl:when test="parent::isolationStep">
            <xsl:apply-templates select="../isolationStepQuestion" mode="id"/>
          </xsl:when>
          <xsl:when test="parent::isolationProcedureEnd">
            <xsl:if test="not(//closeRqmts/reqCondGroup/noConds)">
              <xsl:apply-templates select="//closeRqmts" mode="id"/>
            </xsl:if>
          </xsl:when>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- Yes/No question nodes -->
  <xsl:template match="isolationStepQuestion">
    <xsl:variable name="yes" select="../isolationStepAnswer/yesNoAnswer/yesAnswer/@nextActionRefId"/>
    <xsl:variable name="no" select="../isolationStepAnswer/yesNoAnswer/noAnswer/@nextActionRefId"/>
    <xsl:call-template name="dot-node">
      <xsl:with-param name="id">
        <xsl:apply-templates select="." mode="id"/>
      </xsl:with-param>
      <xsl:with-param name="label">
        <xsl:apply-templates select="." mode="label"/>
      </xsl:with-param>
      <xsl:with-param name="shape" select="$question-shape"/>
      <xsl:with-param name="colour" select="$question-colour"/>
      <xsl:with-param name="style" select="$question-style"/>
      <xsl:with-param name="font-colour" select="$question-font-colour"/>
      <xsl:with-param name="target">
        <xsl:apply-templates select="//*[@id=$yes]" mode="id"/>
      </xsl:with-param>
      <xsl:with-param name="edge-label">Yes</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="dot-node">
      <xsl:with-param name="id">
        <xsl:apply-templates select="." mode="id"/>
      </xsl:with-param>
      <xsl:with-param name="target">
        <xsl:apply-templates select="//*[@id=$no]" mode="id"/>
      </xsl:with-param>
      <xsl:with-param name="edge-label">No</xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- Multiple choice question nodes -->
  <xsl:template match="isolationStepQuestion[following-sibling::isolationStepAnswer/listOfChoices]">
    <xsl:variable name="id">
      <xsl:apply-templates select="." mode="id"/>
    </xsl:variable>
    <xsl:call-template name="dot-node">
      <xsl:with-param name="id" select="$id"/>
      <xsl:with-param name="label">
        <xsl:apply-templates select="." mode="label"/>
      </xsl:with-param>
      <xsl:with-param name="shape" select="$question-shape"/>
      <xsl:with-param name="colour" select="$question-colour"/>
      <xsl:with-param name="style" select="$question-style"/>
      <xsl:with-param name="font-colour" select="$question-font-colour"/>
    </xsl:call-template>
    <xsl:for-each select="following-sibling::isolationStepAnswer/listOfChoices/choice">
      <xsl:variable name="next" select="@nextActionRefId"/>
      <xsl:call-template name="dot-node">
        <xsl:with-param name="id" select="$id"/>
        <xsl:with-param name="target">
          <xsl:apply-templates select="//*[@id=$next]" mode="id"/>
        </xsl:with-param>
        <xsl:with-param name="edge-label">
          <xsl:apply-templates select="." mode="label"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- Link to the first condition -->
  <xsl:template match="closeRqmts" mode="id">
    <xsl:apply-templates select="reqCondGroup/*[1]" mode="id"/>
  </xsl:template>

  <!-- Each close requirement links to the next, except the last which has not
       destination. -->
  <xsl:template match="closeRqmts/reqCondGroup/*[not(self::noConds)]">
    <xsl:call-template name="dot-node">
      <xsl:with-param name="label">
        <xsl:apply-templates select="reqCond" mode="label"/>
      </xsl:with-param>
      <xsl:with-param name="shape" select="$close-shape"/>
      <xsl:with-param name="colour" select="$close-colour"/>
      <xsl:with-param name="style" select="$close-style"/>
      <xsl:with-param name="font-colour" select="$close-font-colour"/>
      <xsl:with-param name="target">
        <xsl:if test="position() != last()">
          <xsl:apply-templates select="following-sibling::*" mode="id"/>
        </xsl:if>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="dmCode">
    <xsl:value-of select="@modelIdentCode"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@systemDiffCode"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@systemCode"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@subSystemCode"/>
    <xsl:value-of select="@subSubSystemCode"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@assyCode"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@disassyCode"/>
    <xsl:value-of select="@disassyCodeVariant"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@infoCode"/>
    <xsl:value-of select="@infoCodeVariant"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@itemLocationCode"/>
    <xsl:if test="@learnCode">
      <xsl:text>-</xsl:text>
      <xsl:value-of select="@learnCode"/>
      <xsl:value-of select="@learnEventCode"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="internalRef">
    <xsl:variable name="target-id" select="@internalRefId"/>
    <xsl:variable name="target" select="//*[@id=$target-id]"/>
    <xsl:choose>
      <xsl:when test="$target/shortName">
        <xsl:value-of select="$target/shortName"/>
      </xsl:when>
      <xsl:when test="$target/name">
        <xsl:value-of select="$target/name"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="externalPubRef">
    <xsl:value-of select="externalPubRefIdent/externalPubCode"/>
  </xsl:template>

</xsl:stylesheet>
