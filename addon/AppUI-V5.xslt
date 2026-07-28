<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:frmwrk="Corel Framework Data"
                exclude-result-prefixes="frmwrk">
  <xsl:output method="xml" encoding="UTF-8" indent="yes" />

  <frmwrk:uiconfig>
    <frmwrk:applicationInfo userConfiguration="true" />
    <frmwrk:compositeNode xPath="/uiConfig/commandBars/commandBarData[@guid='2e26c69d-a190-4eb4-ae3b-6998acbc7a5c']" />
    <frmwrk:compositeNode xPath="/uiConfig/commandBars/commandBarData[@guid='e3d77e95-7fec-5528-8e71-fe021af8bc53']" />
    <frmwrk:compositeNode xPath="/uiConfig/commandBars/commandBarData[@guid='5ae3558c-abb1-54a7-9713-51c44695d6be']" />
    <frmwrk:compositeNode xPath="/uiConfig/commandBars/commandBarData[@guid='a2124024-3c38-5fd8-be36-e17492fe43af']" />
    <frmwrk:compositeNode xPath="/uiConfig/commandBars/commandBarData[@guid='58169f7c-9598-5cc6-827e-5d9453a448bc']" />
    <frmwrk:compositeNode xPath="/uiConfig/commandBars/commandBarData[@guid='338c7975-a442-529b-b04a-2f3d9b5131f5']" />
    <frmwrk:compositeNode xPath="/uiConfig/commandBars/commandBarData[@guid='4ee6b727-0a7c-5830-a31d-4f1352c1117f']" />
    <frmwrk:compositeNode xPath="/uiConfig/commandBars/commandBarData[@guid='222d8cfe-2c0b-597e-8ff9-12768927c180']" />
  </frmwrk:uiconfig>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" />
    </xsl:copy>
  </xsl:template>

  <!-- V5 starts a fresh wrapping text-and-icon toolbar while retiring cached V1-V4 layouts. -->
  <xsl:template match="itemData[@guid='34d0b39f-a08c-428a-bd2f-5d926e220719' or @guid='5efeefce-5f49-5aa2-9a58-7493d1346753' or @guid='5669c782-345a-5076-81ab-1b8ee65b6be2' or @guid='184382d3-8d08-5c9c-943c-af051a2a90d2' or @guid='a56af16b-d419-57db-81fe-ff212a8d25ca' or @guid='4c878025-2ebe-555f-b895-2fe1302cd85c' or @guid='797a4491-15a8-5841-8764-71eaa5287eaf' or @guid='6386c141-3fd9-5d7d-b9d7-55e921ed490c' or @guid='35c9f03d-9941-588c-bfe5-d29f6c86ef26' or @guid='56eb254a-4513-54c2-832f-5b058375664b' or @guid='774d1444-594f-5248-b1ac-af8b8eaacd1b' or @guid='6bf008b8-2784-5cd9-bcdd-87fa1706a36d' or @guid='5c3aa653-45b6-5abd-8d9c-c051bd566e01' or @guid='6066cc80-1e00-504e-a2b4-2cff58662136' or @guid='bd57e1ab-e4b1-5136-99b1-610f07ffc98f' or @guid='96b25403-fef6-5bbf-8b0e-77970bd53e22' or @guid='182c26f9-a172-5f1a-9be4-5e59ede0b6e6' or @guid='7b550782-004a-5943-abc9-10d3c3be11e0' or @guid='9c908778-3945-5db6-98ae-677941bb97ba' or @guid='a50986f8-7c03-52a5-a82e-5dcfc77d3e55' or @guid='9c7f8a0b-557f-5d1b-9e6a-e7419d030ce3' or @guid='33a245a0-d6cc-56a1-a0cf-698951cff13c' or @guid='823c0ea2-6737-5c22-9599-ff0a6d4dc4cb' or @guid='ac50770e-b83a-59c6-b3da-5ea98fdf05de' or @guid='c9518f72-d40a-591f-9717-fd94631fdb70' or @guid='bdf2052d-8e14-59a3-8bc5-5e4815ebf448' or @guid='2e72a46d-1c6e-57c5-8289-129c0b04078c' or @guid='85a6f3ef-444a-5bb6-b4e7-696e03ea6cd2' or @guid='2b8a7cfc-8f0d-5bef-9295-be1703b090f7' or @guid='b7978271-f023-5dbc-a8ad-604706f96075' or @guid='5d0d335b-44b6-5e3d-95d8-2448861befcb' or @guid='82c73520-b965-5b80-97b6-154c7d808ef3' or @guid='c8fa3e27-4a83-547e-ba8b-1dd7caeda8af' or @guid='3d4088da-a47d-5762-aac3-75f63e71d1a3' or @guid='89d68c84-2b22-536f-806d-69b0e9e39c8a' or @guid='929f4ae7-5c38-5c54-a652-b3c62e33890f' or @guid='90b2c98b-09e7-5848-a270-a3caf47b21e4' or @guid='ccb13749-eb3d-5c0d-9b8f-557510543012' or @guid='6d0c913f-09bb-5f85-aae0-b06df2339791' or @guid='b6632cdf-7500-57d6-b563-4665f982e4d9' or @guid='5a193513-2c17-538b-9955-c9987731cc37' or @guid='c13915e5-c769-5d7d-a736-372d9d564f10' or @guid='50085dc1-8afc-5045-9164-04abe4bb203e' or @guid='52174911-1f92-52b4-96a8-12b2132312a5' or @guid='d1523bdf-3970-529c-9774-882725004f18']" />

  <!-- Keep V1 through V4 configuration only as hidden migration records. -->
  <xsl:template match="commandBarData[@guid='2e26c69d-a190-4eb4-ae3b-6998acbc7a5c' or @guid='e3d77e95-7fec-5528-8e71-fe021af8bc53' or @guid='5ae3558c-abb1-54a7-9713-51c44695d6be' or @guid='a2124024-3c38-5fd8-be36-e17492fe43af' or @guid='58169f7c-9598-5cc6-827e-5d9453a448bc' or @guid='338c7975-a442-529b-b04a-2f3d9b5131f5' or @guid='4ee6b727-0a7c-5830-a31d-4f1352c1117f']">
    <xsl:copy>
      <xsl:apply-templates select="@*[name() != 'visible']" />
      <xsl:attribute name="visible">false</xsl:attribute>
      <xsl:apply-templates select="node()" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="toolbar[@guidRef='2e26c69d-a190-4eb4-ae3b-6998acbc7a5c' or @guidRef='e3d77e95-7fec-5528-8e71-fe021af8bc53' or @guidRef='5ae3558c-abb1-54a7-9713-51c44695d6be' or @guidRef='a2124024-3c38-5fd8-be36-e17492fe43af' or @guidRef='58169f7c-9598-5cc6-827e-5d9453a448bc' or @guidRef='338c7975-a442-529b-b04a-2f3d9b5131f5' or @guidRef='4ee6b727-0a7c-5830-a31d-4f1352c1117f']" />

  <!-- Replace incomplete workspace placeholders before adding the full V5 definitions. -->
  <xsl:template match="commandBarData[@guid='222d8cfe-2c0b-597e-8ff9-12768927c180'][not(@nonLocalizableName = 'PCodexDemoToolbarV5')]" priority="2" />
  <xsl:template match="commandBarData[@guid='449396d3-930a-51b5-9584-ddd6e6f831c8'][not(@nonLocalizableName = 'PCodexDemoMoreToolsV5')]" priority="2" />

  <xsl:template match="commandBarData[@guid='222d8cfe-2c0b-597e-8ff9-12768927c180']">
    <xsl:copy>
      <xsl:apply-templates select="@*[name() != 'userCreated']" />
      <xsl:apply-templates select="node()" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="commandBarData[@guid='222d8cfe-2c0b-597e-8ff9-12768927c180']/toolbar">
    <xsl:copy>
      <xsl:apply-templates select="@*[name() != 'nativeToolbar' and name() != 'itemFace' and name() != 'type']" />
      <xsl:attribute name="itemFace">textRightOfImage</xsl:attribute>
      <xsl:apply-templates select="node()" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="uiConfig/items">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" />
      <itemData guid="89d68c84-2b22-536f-806d-69b0e9e39c8a"
                type="wpfhost"
                hostedType="Addons\CorelDrawToolbar\CorelDrawToolbar.dll,CorelDrawToolbar.NativeCommandHost"
                userCaption="" userToolTip="" customizable="false" enable="true" />
      <itemData guid="90b2c98b-09e7-5848-a270-a3caf47b21e4"
                dynamicCategory="ab489730-8791-45d2-a825-b78bbe0d6a5d"
                dynamicCommand="PCodex_CreatePageRectangle"
                userCaption="页面比例矩形"
                userToolTip="按当前参数创建页面比例矩形"
                icon="guid://90b2c98b-09e7-5848-a270-a3caf47b21e4" />
      <itemData guid="ccb13749-eb3d-5c0d-9b8f-557510543012"
                dynamicCategory="ab489730-8791-45d2-a825-b78bbe0d6a5d"
                dynamicCommand="PCodex_CreateArtisticText"
                userCaption="PCodex 艺术字"
                userToolTip="创建当前默认文案的艺术字"
                icon="guid://ccb13749-eb3d-5c0d-9b8f-557510543012" />
      <itemData guid="6d0c913f-09bb-5f85-aae0-b06df2339791"
                dynamicCategory="ab489730-8791-45d2-a825-b78bbe0d6a5d"
                dynamicCommand="PCodex_CreateSample"
                userCaption="PCodex 组合样例"
                userToolTip="创建带默认填充和文案的组合样例"
                icon="guid://6d0c913f-09bb-5f85-aae0-b06df2339791" />
      <itemData guid="b6632cdf-7500-57d6-b563-4665f982e4d9"
                dynamicCategory="ab489730-8791-45d2-a825-b78bbe0d6a5d"
                dynamicCommand="PCodex_DuplicateOffset"
                userCaption="复制并偏移"
                userToolTip="复制当前选区并按默认参数偏移"
                icon="guid://b6632cdf-7500-57d6-b563-4665f982e4d9" />
      <itemData guid="5a193513-2c17-538b-9955-c9987731cc37"
                dynamicCategory="ab489730-8791-45d2-a825-b78bbe0d6a5d"
                dynamicCommand="PCodex_CenterSelection"
                userCaption="居中到页面"
                userToolTip="将当前选区居中到活动页面"
                icon="guid://5a193513-2c17-538b-9955-c9987731cc37" />
      <itemData guid="c13915e5-c769-5d7d-a736-372d9d564f10"
                dynamicCategory="ab489730-8791-45d2-a825-b78bbe0d6a5d"
                dynamicCommand="PCodex_ApplyDemoFill"
                userCaption="应用当前填充"
                userToolTip="将当前填充预设应用到选区"
                icon="guid://c13915e5-c769-5d7d-a736-372d9d564f10" />
      <itemData guid="50085dc1-8afc-5045-9164-04abe4bb203e"
                dynamicCategory="ab489730-8791-45d2-a825-b78bbe0d6a5d"
                dynamicCommand="PCodex_ShowSelectionInfo"
                userCaption="显示选区信息"
                userToolTip="查看当前选区的尺寸和数量"
                icon="guid://50085dc1-8afc-5045-9164-04abe4bb203e" />
      <itemData guid="52174911-1f92-52b4-96a8-12b2132312a5"
                dynamicCategory="ab489730-8791-45d2-a825-b78bbe0d6a5d"
                dynamicCommand="PCodex_OpenSettings"
                userCaption="编辑默认参数"
                userToolTip="打开 PCodex 默认参数窗口"
                icon="guid://52174911-1f92-52b4-96a8-12b2132312a5" />
      <itemData guid="d1523bdf-3970-529c-9774-882725004f18"
                dynamicCategory="ab489730-8791-45d2-a825-b78bbe0d6a5d"
                dynamicCommand="PCodex_ShowAbout"
                userCaption="关于 PCodex Demo"
                userToolTip="查看模板说明"
                icon="guid://d1523bdf-3970-529c-9774-882725004f18" />
      <itemData guid="929f4ae7-5c38-5c54-a652-b3c62e33890f"
                type="flyout"
                flyoutBarRef="449396d3-930a-51b5-9584-ddd6e6f831c8"
                enable="true"
                caption="更多功能"
                userCaption="更多功能"
                toolTip="显示可分离的 PCodex 工具面板"
                userToolTip="显示可分离的 PCodex 工具面板"
                icon="guid://929f4ae7-5c38-5c54-a652-b3c62e33890f" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="uiConfig/commandBars">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" />
      <xsl:if test="not(commandBarData[@guid='222d8cfe-2c0b-597e-8ff9-12768927c180' and @nonLocalizableName='PCodexDemoToolbarV5'])">
        <commandBarData guid="222d8cfe-2c0b-597e-8ff9-12768927c180"
                        nonLocalizableName="PCodexDemoToolbarV5"
                        userCaption="PCodex Demo 工具栏"
                        locked="false" movable="true" canFloat="true" allowDock="true" customizable="true"
                        visible="true" type="toolbar" dock="top">
          <toolbar dock="top" itemFace="textRightOfImage">
            <item guidRef="90b2c98b-09e7-5848-a270-a3caf47b21e4" dock="top" />
            <item guidRef="ccb13749-eb3d-5c0d-9b8f-557510543012" dock="top" />
            <item guidRef="6d0c913f-09bb-5f85-aae0-b06df2339791" dock="top" />
            <item guidRef="52174911-1f92-52b4-96a8-12b2132312a5" dock="top" />
            <item guidRef="929f4ae7-5c38-5c54-a652-b3c62e33890f" dock="top" />
            <item guidRef="89d68c84-2b22-536f-806d-69b0e9e39c8a" dock="top" itemFace="imageOnly" />
          </toolbar>
        </commandBarData>
      </xsl:if>
      <xsl:if test="not(commandBarData[@guid='449396d3-930a-51b5-9584-ddd6e6f831c8' and @nonLocalizableName='PCodexDemoMoreToolsV5'])">
        <commandBarData guid="449396d3-930a-51b5-9584-ddd6e6f831c8"
                        nonLocalizableName="PCodexDemoMoreToolsV5"
                        userCaption="PCodex 更多功能"
                        type="toolbar"
                        userCreated="true"
                        flyout="true">
          <toolbar itemFace="textRightOfImage">
            <item guidRef="b6632cdf-7500-57d6-b563-4665f982e4d9" />
            <item guidRef="5a193513-2c17-538b-9955-c9987731cc37" />
            <item guidRef="c13915e5-c769-5d7d-a736-372d9d564f10" />
            <item guidRef="50085dc1-8afc-5045-9164-04abe4bb203e" />
            <item guidRef="d1523bdf-3970-529c-9774-882725004f18" />
          </toolbar>
        </commandBarData>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="uiConfig/containers/container[@guid='bee85f91-3ad9-dc8d-48b5-d2a87c8b2109']/container[@guid='Framework_MainFrame-layout']/dockHost[@guid='894bf987-2ec1-8f83-41d8-68f6797d0db4']/toolbar[@guidRef='c2b44f69-6dec-444e-a37e-5dbf7ff43dae']">
    <xsl:copy-of select="." />
    <xsl:if test="not(//toolbar[@guidRef='222d8cfe-2c0b-597e-8ff9-12768927c180'])">
      <toolbar guidRef="222d8cfe-2c0b-597e-8ff9-12768927c180" dock="top" collapsed="false" />
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
