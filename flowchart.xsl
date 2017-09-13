<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  
  <!-- Convert S1000D fault isolation procedures to flowcharts via the Graphviz
       DOT language -->

  <!-- Node defaults -->
  <xsl:param name="node-style">solid</xsl:param>
  <xsl:param name="node-font-colour">black</xsl:param>
  <xsl:param name="node-font-family"/>
  <xsl:param name="node-font-size"/>
  <!-- If node-style = filled, this will set the outline colour.
       Otherwise, this sets the colour of all nodes. -->
  <xsl:param name="node-colour"/>

  <!-- Edge defaults -->
  <xsl:param name="edge-style">solid</xsl:param>
  <xsl:param name="edge-font-colour">black</xsl:param>
  <xsl:param name="edge-font-family"/>
  <xsl:param name="edge-font-size"/>
  <xsl:param name="edge-colour"/>

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

  <!-- When true, answers (yes/no/choices) are displayed as their own nodes.

       When false, answers are written as labels on the edge between the step
       and next action. -->
  <xsl:param name="answer-nodes" select="false()"/>

  <!-- Properties of answer nodes if $answer-nodes = true() -->
  <xsl:param name="answer-colour">yellow</xsl:param>
  <xsl:param name="answer-shape">oval</xsl:param>
  <xsl:param name="answer-style" select="$node-style"/>
  <xsl:param name="answer-font-colour" select="$node-font-colour"/>

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

  <!-- When true, answers linking to the closeRqmts element when there are no
       close requirements (noConds) are connected to a 'dummy' catch-all node.

       When false, these answers are not displayed in the graph, edges
       connecting to the 'empty' closeRqmts will be omitted. -->
  <xsl:param name="dummy-noconds-action" select="false()"/>
  <!-- The label for the 'dummy' node described above. -->
  <xsl:param name="dummy-noconds-label">End of procedure</xsl:param>
  
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
      <xsl:apply-templates select="*|text()[normalize-space(.) != '']"/>
    </xsl:variable>
    <xsl:call-template name="wrap-string">
      <xsl:with-param name="str" select="$text"/>
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
    <xsl:param name="font-family" select="$node-font-family"/>
    <xsl:param name="font-size" select="$node-font-size"/>
    <xsl:param name="target"/>
    <xsl:param name="tooltip"/>
    <xsl:param name="edge-label"/>
    <xsl:param name="edge-colour" select="$edge-colour"/>
    <xsl:param name="edge-style" select="$edge-style"/>
    <xsl:param name="edge-font-family" select="$edge-font-family"/>
    <xsl:param name="edge-font-size" select="$edge-font-size"/>
    <xsl:param name="edge-arrow"/>

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
      <xsl:text> shape=</xsl:text>
      <xsl:value-of select="$shape"/>
    </xsl:if>

    <xsl:if test="$colour">
      <xsl:choose>
        <xsl:when test="$node-colour">
          <xsl:text> color=</xsl:text>
          <xsl:value-of select="$node-colour"/>
          <xsl:text> fillcolor=</xsl:text>
          <xsl:value-of select="$colour"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text> </xsl:text>
          <xsl:text>color=</xsl:text>
          <xsl:value-of select="$colour"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <xsl:if test="$font-family">
      <xsl:text> fontname="</xsl:text>
      <xsl:value-of select="$font-family"/>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <xsl:if test="$font-size">
      <xsl:text> fontsize=</xsl:text>
      <xsl:value-of select="$font-size"/>
    </xsl:if>

    <xsl:if test="$style">
      <xsl:text> style="</xsl:text>
      <xsl:value-of select="$style"/>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <xsl:if test="$font-colour">
      <xsl:text> fontcolor=</xsl:text>
      <xsl:value-of select="$font-colour"/>
    </xsl:if>

    <xsl:if test="$tooltip">
      <xsl:text> tooltip="</xsl:text>
      <xsl:value-of select="$tooltip"/>
      <xsl:text>"</xsl:text>
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

    <xsl:if test="$edge-colour">
      <xsl:text> </xsl:text>
      <xsl:text>color=</xsl:text>
      <xsl:value-of select="$edge-colour"/>
    </xsl:if>

    <xsl:if test="$edge-style">
      <xsl:text> style="</xsl:text>
      <xsl:value-of select="$edge-style"/>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <xsl:if test="$edge-font-family">
      <xsl:text> fontname="</xsl:text>
      <xsl:value-of select="$edge-font-family"/>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <xsl:if test="$edge-font-size">
      <xsl:text> fontsize=</xsl:text>
      <xsl:value-of select="$edge-font-size"/>
    </xsl:if>

    <xsl:if test="$edge-arrow">
      <xsl:text> arrowhead="</xsl:text>
      <xsl:value-of select="$edge-arrow"/>
      <xsl:text>"</xsl:text>
    </xsl:if>

    <xsl:text>]</xsl:text>

    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- Graph definition -->
  <xsl:template match="dmodule">
    <xsl:text>digraph "</xsl:text>
    <xsl:apply-templates select="//dmAddressItems/dmTitle"/>
    <xsl:text>" {</xsl:text>
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
      <xsl:with-param name="tooltip">
        <xsl:text>Step </xsl:text>
        <xsl:apply-templates select="." mode="number"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- Yes/No question nodes -->
  <xsl:template match="isolationStepQuestion">
    <xsl:choose>
      <xsl:when test="$answer-nodes">
        <xsl:call-template name="dot-node">
          <xsl:with-param name="label">
            <xsl:apply-templates select="." mode="label"/>
          </xsl:with-param>
          <xsl:with-param name="shape" select="$question-shape"/>
          <xsl:with-param name="colour" select="$question-colour"/>
          <xsl:with-param name="style" select="$question-style"/>
          <xsl:with-param name="font-colour" select="$question-font-colour"/>
        </xsl:call-template>
        <xsl:call-template name="dot-node">
          <xsl:with-param name="target">
            <xsl:apply-templates select="../isolationStepAnswer/yesNoAnswer/yesAnswer" mode="id"/>
          </xsl:with-param>
          <xsl:with-param name="edge-arrow">none</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="dot-node">
          <xsl:with-param name="target">
            <xsl:apply-templates select="../isolationStepAnswer/yesNoAnswer/noAnswer" mode="id"/>
          </xsl:with-param>
          <xsl:with-param name="edge-arrow">none</xsl:with-param>
          <xsl:with-param name="tooltip">
            <xsl:text>Step </xsl:text>
            <xsl:apply-templates select="." mode="number"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="yes" select="../isolationStepAnswer/yesNoAnswer/yesAnswer/@nextActionRefId"/>
        <xsl:variable name="no" select="../isolationStepAnswer/yesNoAnswer/noAnswer/@nextActionRefId"/>
        <xsl:call-template name="dot-node">
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
          <xsl:with-param name="target">
            <xsl:apply-templates select="//*[@id=$no]" mode="id"/>
          </xsl:with-param>
          <xsl:with-param name="edge-label">No</xsl:with-param>
          <xsl:with-param name="tooltip">
            <xsl:text>Step </xsl:text>
            <xsl:apply-templates select="." mode="number"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="yesAnswer|noAnswer">
    <xsl:if test="$answer-nodes">
      <xsl:variable name="id" select="@nextActionRefId"/>
      <xsl:call-template name="dot-node">
        <xsl:with-param name="label">
          <xsl:choose>
            <xsl:when test="self::yesAnswer">Yes</xsl:when>
            <xsl:when test="self::noAnswer">No</xsl:when>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="shape" select="$answer-shape"/>
        <xsl:with-param name="colour" select="$answer-colour"/>
        <xsl:with-param name="style" select="$answer-style"/>
        <xsl:with-param name="font-colour" select="$answer-font-colour"/>
        <xsl:with-param name="target">
          <xsl:apply-templates select="//*[@id=$id]" mode="id"/>
        </xsl:with-param>
        <xsl:with-param name="tooltip">
          <xsl:text>Step </xsl:text>
          <xsl:apply-templates select="." mode="number"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
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
      <xsl:choose>
        <xsl:when test="$answer-nodes">
          <xsl:call-template name="dot-node">
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="target">
              <xsl:apply-templates select="." mode="id"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
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
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="choice">
    <xsl:if test="$answer-nodes">
      <xsl:variable name="id" select="@nextActionRefId"/>
      <xsl:call-template name="dot-node">
        <xsl:with-param name="label">
          <xsl:apply-templates select="." mode="label"/>
        </xsl:with-param>
        <xsl:with-param name="shape" select="$answer-shape"/>
        <xsl:with-param name="colour" select="$answer-colour"/>
        <xsl:with-param name="style" select="$answer-style"/>
        <xsl:with-param name="font-colour" select="$answer-font-colour"/>
        <xsl:with-param name="target">
          <xsl:apply-templates select="//*[@id=$id]" mode="id"/>
        </xsl:with-param>
        <xsl:with-param name="tooltip">
          <xsl:text>Step </xsl:text>
          <xsl:apply-templates select="." mode="number"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Link to the first condition -->
  <xsl:template match="closeRqmts" mode="id">
    <xsl:variable name="target" select="reqCondGroup/*[1]"/>
    <xsl:if test="name($target) != 'noConds' or $dummy-noconds-action">
      <xsl:apply-templates select="$target" mode="id"/>
    </xsl:if>
  </xsl:template>

  <!-- Each close requirement links to the next, except the last which has not
       destination. -->
  <xsl:template match="closeRqmts/reqCondGroup/*">
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
      <xsl:with-param name="tooltip">
        <xsl:text>Step </xsl:text>
        <xsl:apply-templates select="." mode="number"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- If a question links to the closeRqmts and there are none, create a dummy
       action for it to connect to. -->
  <xsl:template match="closeRqmts/reqCondGroup/noConds">
    <xsl:if test="$dummy-noconds-action">
      <xsl:call-template name="dot-node">
        <xsl:with-param name="label" select="$dummy-noconds-label"/>
        <xsl:with-param name="shape" select="$action-shape"/>
        <xsl:with-param name="colour" select="$action-colour"/>
        <xsl:with-param name="style" select="$action-style"/>
        <xsl:with-param name="font-colour" select="$close-font-colour"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Display the dmCode for dmRef elements in nodes -->
  <xsl:template match="dmRef">
    <xsl:apply-templates select="dmRefIdent/dmCode"/>
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

  <!-- Handle references to tools/supplies -->
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

  <!-- Display externalPubCode of externalPubRefs -->
  <xsl:template match="externalPubRef">
    <xsl:value-of select="externalPubRefIdent/externalPubCode"/>
  </xsl:template>

  <!-- Display pmCode of pmRefs -->
  <xsl:template match="pmCode">
    <xsl:value-of select="@modelIdentCode"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@pmIssuer"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@pmNumber"/>
    <xsl:text>-</xsl:text>
    <xsl:value-of select="@pmVolume"/>
  </xsl:template>

  <!-- Handle randomLists in actions -->
  <xsl:template match="randomList">
    <xsl:if test="normalize-space(preceding-sibling::text()) != ''">
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="listItem">
    <xsl:for-each select="para">
      <xsl:apply-templates/>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- Handle additional inline text elements.

       TODO: Use HTML-like labels to better handle some of these elements. -->

  <xsl:template match="emphasis">
    <xsl:text>*</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>*</xsl:text>
  </xsl:template>

  <xsl:template match="inlineSignificantData">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="superScript">
    <xsl:text>^</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="subScript">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:template match="acronym">
    <xsl:apply-templates select="acronymTerm"/>
  </xsl:template>

  <xsl:template match="acronymTerm">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="verbatimText">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="dmTitle">
    <xsl:value-of select="techName"/>
    <xsl:if test="infoName">
      <xsl:text> - </xsl:text>
      <xsl:value-of select="infoName"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="action|
                       isolationStepQuestion|
                       closeRqmts/reqCondGroup/reqCondNoRef|
                       closeRqmts/reqCondGroup/reqCondDm|
                       closeRqmts/reqCondGroup/reqCondPm|
                       closeRqmts/reqCondGroup/reqCondExternalPub" mode="number">
    <xsl:number count="action|
                       isolationStepQuestion|
                       closeRqmts/reqCondGroup/reqCondNoRef|
                       closeRqmts/reqCondGroup/reqCondDm|
                       closeRqmts/reqCondGroup/reqCondPm|
                       closeRqmts/reqCondGroup/reqCondExternalPub"
                from="isolationProcedure" level="any"/>
  </xsl:template>

  <xsl:template match="yesAnswer|noAnswer|choice" mode="number">
    <xsl:apply-templates select="ancestor::isolationStep/isolationStepQuestion" mode="number"/>
    <xsl:text>.</xsl:text>
    <xsl:number count="yesAnswer|noAnswer|choice" level="single"/>
  </xsl:template>

</xsl:stylesheet>
