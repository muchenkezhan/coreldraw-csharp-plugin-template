<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:frmwrk="Corel Framework Data"
                exclude-result-prefixes="frmwrk">
  <xsl:output method="xml" encoding="UTF-8" indent="yes" />

  <frmwrk:uiconfig>
    <frmwrk:compositeNode xPath="/uiConfig/commandBars/commandBarData[@guid='222d8cfe-2c0b-597e-8ff9-12768927c180']" />
    <frmwrk:compositeNode xPath="/uiConfig/frame" />
  </frmwrk:uiconfig>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
